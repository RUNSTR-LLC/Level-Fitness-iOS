import Foundation
import HealthKit

class AntiCheatService {
    static let shared = AntiCheatService()
    
    private init() {}
    
    struct ValidationResult {
        let isValid: Bool
        let confidence: Double
        let issues: [ValidationIssue]
        let requiresManualReview: Bool
    }
    
    struct ValidationIssue {
        enum IssueType {
            case impossibleSpeed
            case impossiblePace
            case heartRateMismatch
            case suddenImprovement
            case duplicatePattern
            case impossibleDuration
            case impossibleDistance
            case suspiciousGPS
        }
        
        let type: IssueType
        let severity: Severity
        let description: String
        let evidence: String
        
        enum Severity: Int {
            case low = 1
            case medium = 2
            case high = 3
            case critical = 4
        }
    }
    
    struct PhysiologicalLimits {
        static let maxRunningSpeedKmh = 44.72
        static let maxCyclingSpeedKmh = 133.78
        static let maxSwimmingSpeedKmh = 9.0
        static let maxWalkingSpeedKmh = 15.0
        
        static let minHeartRateResting = 40
        static let maxHeartRateAbsolute = 220
        
        static let maxWorkoutDurationHours = 24.0
        static let maxRunningDistanceKm = 300.0
        static let maxCyclingDistanceKm = 1200.0
        static let maxSwimmingDistanceKm = 50.0
        
        static let maxDailyWorkouts = 10
        static let maxWeeklyImprovementPercent = 20.0
    }
    
    func validateWorkout(_ workout: HKWorkout) async -> ValidationResult {
        var issues: [ValidationIssue] = []
        var confidence = 1.0
        
        issues.append(contentsOf: validateSpeed(workout))
        issues.append(contentsOf: validateDuration(workout))
        issues.append(contentsOf: validateDistance(workout))
        issues.append(contentsOf: await validateHeartRate(workout))
        issues.append(contentsOf: await validateHistoricalProgress(workout))
        issues.append(contentsOf: validateGPSData(workout))
        
        let criticalIssues = issues.filter { $0.severity == .critical }
        let highSeverityCount = issues.filter { $0.severity == .high }.count
        let mediumSeverityCount = issues.filter { $0.severity == .medium }.count
        
        if !criticalIssues.isEmpty {
            confidence = 0.1
        } else {
            confidence -= Double(highSeverityCount) * 0.25
            confidence -= Double(mediumSeverityCount) * 0.1
            confidence = max(0.0, confidence)
        }
        
        let isValid = criticalIssues.isEmpty && highSeverityCount < 2
        let requiresManualReview = !criticalIssues.isEmpty || highSeverityCount >= 2 || mediumSeverityCount >= 3
        
        return ValidationResult(
            isValid: isValid,
            confidence: confidence,
            issues: issues,
            requiresManualReview: requiresManualReview
        )
    }
    
    private func validateSpeed(_ workout: HKWorkout) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        guard let distance = workout.totalDistance?.doubleValue(for: .meter()),
              distance > 0 else {
            return issues
        }
        
        let duration = workout.duration
        guard duration > 0 else {
            return issues
        }
        
        let speedKmh = (distance / 1000.0) / (duration / 3600.0)
        var maxSpeed: Double = 0
        var activityName = ""
        
        switch workout.workoutActivityType {
        case .running:
            maxSpeed = PhysiologicalLimits.maxRunningSpeedKmh
            activityName = "running"
        case .cycling:
            maxSpeed = PhysiologicalLimits.maxCyclingSpeedKmh
            activityName = "cycling"
        case .swimming:
            maxSpeed = PhysiologicalLimits.maxSwimmingSpeedKmh
            activityName = "swimming"
        case .walking:
            maxSpeed = PhysiologicalLimits.maxWalkingSpeedKmh
            activityName = "walking"
        default:
            return issues
        }
        
        if speedKmh > maxSpeed {
            issues.append(ValidationIssue(
                type: .impossibleSpeed,
                severity: .critical,
                description: "Speed exceeds human limits for \(activityName)",
                evidence: String(format: "%.1f km/h (max: %.1f km/h)", speedKmh, maxSpeed)
            ))
        } else if speedKmh > maxSpeed * 0.9 {
            issues.append(ValidationIssue(
                type: .impossibleSpeed,
                severity: .high,
                description: "Speed approaching world record for \(activityName)",
                evidence: String(format: "%.1f km/h (90%% of max: %.1f km/h)", speedKmh, maxSpeed)
            ))
        }
        
        if workout.workoutActivityType == .running {
            let paceMinPerKm = (duration / 60.0) / (distance / 1000.0)
            if paceMinPerKm < 2.5 {
                issues.append(ValidationIssue(
                    type: .impossiblePace,
                    severity: .critical,
                    description: "Running pace faster than world record",
                    evidence: String(format: "%.1f min/km", paceMinPerKm)
                ))
            }
        }
        
        return issues
    }
    
    private func validateDuration(_ workout: HKWorkout) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        let durationHours = workout.duration / 3600.0
        
        if durationHours > PhysiologicalLimits.maxWorkoutDurationHours {
            issues.append(ValidationIssue(
                type: .impossibleDuration,
                severity: .critical,
                description: "Workout duration exceeds 24 hours",
                evidence: String(format: "%.1f hours", durationHours)
            ))
        } else if durationHours > 12 {
            issues.append(ValidationIssue(
                type: .impossibleDuration,
                severity: .medium,
                description: "Unusually long workout duration",
                evidence: String(format: "%.1f hours", durationHours)
            ))
        }
        
        if durationHours < 0.01 {
            issues.append(ValidationIssue(
                type: .impossibleDuration,
                severity: .high,
                description: "Workout duration too short",
                evidence: String(format: "%.1f seconds", workout.duration)
            ))
        }
        
        return issues
    }
    
    private func validateDistance(_ workout: HKWorkout) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        guard let distance = workout.totalDistance?.doubleValue(for: .meter()),
              distance > 0 else {
            return issues
        }
        
        let distanceKm = distance / 1000.0
        var maxDistance: Double = 0
        var activityName = ""
        
        switch workout.workoutActivityType {
        case .running:
            maxDistance = PhysiologicalLimits.maxRunningDistanceKm
            activityName = "running"
        case .cycling:
            maxDistance = PhysiologicalLimits.maxCyclingDistanceKm
            activityName = "cycling"
        case .swimming:
            maxDistance = PhysiologicalLimits.maxSwimmingDistanceKm
            activityName = "swimming"
        default:
            return issues
        }
        
        if distanceKm > maxDistance {
            issues.append(ValidationIssue(
                type: .impossibleDistance,
                severity: .critical,
                description: "Distance exceeds human limits for \(activityName)",
                evidence: String(format: "%.1f km (max: %.1f km)", distanceKm, maxDistance)
            ))
        } else if distanceKm > maxDistance * 0.8 {
            issues.append(ValidationIssue(
                type: .impossibleDistance,
                severity: .high,
                description: "Distance approaching extreme limits for \(activityName)",
                evidence: String(format: "%.1f km (80%% of max: %.1f km)", distanceKm, maxDistance)
            ))
        }
        
        return issues
    }
    
    private func validateHeartRate(_ workout: HKWorkout) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        var averageHeartRate: Double?
        if #available(iOS 16.0, *) {
            averageHeartRate = workout.statistics(for: HKQuantityType(.heartRate))?
                .averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }
        
        guard let averageHeartRate = averageHeartRate else {
            return issues
        }
        
        if averageHeartRate < Double(PhysiologicalLimits.minHeartRateResting) {
            issues.append(ValidationIssue(
                type: .heartRateMismatch,
                severity: .critical,
                description: "Heart rate below human resting minimum",
                evidence: String(format: "%.0f bpm (min: %d bpm)", averageHeartRate, PhysiologicalLimits.minHeartRateResting)
            ))
        }
        
        if averageHeartRate > Double(PhysiologicalLimits.maxHeartRateAbsolute) {
            issues.append(ValidationIssue(
                type: .heartRateMismatch,
                severity: .critical,
                description: "Heart rate exceeds human maximum",
                evidence: String(format: "%.0f bpm (max: %d bpm)", averageHeartRate, PhysiologicalLimits.maxHeartRateAbsolute)
            ))
        }
        
        let expectedHeartRateRange = getExpectedHeartRateRange(for: workout)
        if averageHeartRate < expectedHeartRateRange.lowerBound || averageHeartRate > expectedHeartRateRange.upperBound {
            issues.append(ValidationIssue(
                type: .heartRateMismatch,
                severity: .medium,
                description: "Heart rate doesn't match workout intensity",
                evidence: String(format: "%.0f bpm (expected: %.0f-%.0f bpm)", averageHeartRate, expectedHeartRateRange.lowerBound, expectedHeartRateRange.upperBound)
            ))
        }
        
        return issues
    }
    
    private func getExpectedHeartRateRange(for workout: HKWorkout) -> ClosedRange<Double> {
        switch workout.workoutActivityType {
        case .running:
            return 120...180
        case .cycling:
            return 100...170
        case .swimming:
            return 110...170
        case .walking:
            return 70...120
        case .highIntensityIntervalTraining:
            return 130...190
        case .yoga:
            return 60...100
        case .coreTraining, .functionalStrengthTraining, .traditionalStrengthTraining:
            return 80...140
        default:
            return 60...180
        }
    }
    
    private func validateHistoricalProgress(_ workout: HKWorkout) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        let healthStore = HKHealthStore()
        let workoutType = HKObjectType.workoutType()
        let endDate = workout.startDate
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let recentWorkouts = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 100, sortDescriptors: nil) { _, samples, _ in
                let workouts = (samples as? [HKWorkout])?.filter { 
                    $0.workoutActivityType == workout.workoutActivityType && 
                    $0.uuid != workout.uuid 
                } ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
        
        if !recentWorkouts.isEmpty {
            let averageDistance = recentWorkouts.compactMap { 
                $0.totalDistance?.doubleValue(for: .meter()) 
            }.reduce(0, +) / Double(recentWorkouts.count)
            
            if let currentDistance = workout.totalDistance?.doubleValue(for: .meter()),
               averageDistance > 0 {
                let improvementPercent = ((currentDistance - averageDistance) / averageDistance) * 100
                
                if improvementPercent > 100 {
                    issues.append(ValidationIssue(
                        type: .suddenImprovement,
                        severity: .critical,
                        description: "Impossible improvement over recent workouts",
                        evidence: String(format: "%.0f%% improvement", improvementPercent)
                    ))
                } else if improvementPercent > 50 {
                    issues.append(ValidationIssue(
                        type: .suddenImprovement,
                        severity: .high,
                        description: "Suspicious improvement over recent workouts",
                        evidence: String(format: "%.0f%% improvement", improvementPercent)
                    ))
                }
            }
            
            let duplicateWorkouts = recentWorkouts.filter { other in
                guard let distance1 = workout.totalDistance?.doubleValue(for: .meter()),
                      let distance2 = other.totalDistance?.doubleValue(for: .meter()) else {
                    return false
                }
                
                let durationDiff = abs(workout.duration - other.duration)
                let distanceDiff = abs(distance1 - distance2)
                
                return durationDiff < 1.0 && distanceDiff < 1.0
            }
            
            if duplicateWorkouts.count >= 3 {
                issues.append(ValidationIssue(
                    type: .duplicatePattern,
                    severity: .high,
                    description: "Multiple identical workouts detected",
                    evidence: "\(duplicateWorkouts.count) identical workouts in 30 days"
                ))
            }
        }
        
        let todayWorkouts = recentWorkouts.filter { 
            Calendar.current.isDateInToday($0.startDate) 
        }
        
        if todayWorkouts.count >= PhysiologicalLimits.maxDailyWorkouts {
            issues.append(ValidationIssue(
                type: .suddenImprovement,
                severity: .medium,
                description: "Excessive daily workout count",
                evidence: "\(todayWorkouts.count + 1) workouts today"
            ))
        }
        
        return issues
    }
    
    private func validateGPSData(_ workout: HKWorkout) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        // GPS validation would require querying HKWorkoutRoute separately
        // For now, we'll do basic validation based on average speed
        if let distance = workout.totalDistance?.doubleValue(for: .meter()),
           distance > 0 {
            let duration = workout.duration
            if duration > 0 {
                let avgSpeedKmh = (distance / 1000.0) / (duration / 3600.0)
                
                // Check for teleportation-like speeds
                if avgSpeedKmh > 200 {
                    issues.append(ValidationIssue(
                        type: .suspiciousGPS,
                        severity: .critical,
                        description: "Average speed suggests GPS manipulation",
                        evidence: String(format: "%.0f km/h average speed", avgSpeedKmh)
                    ))
                }
            }
        }
        
        return issues
    }
    
    func generateCheatReport(for workout: HKWorkout, validation: ValidationResult) -> CheatReport {
        return CheatReport(
            workoutId: workout.uuid.uuidString,
            timestamp: Date(),
            workoutType: workout.workoutActivityType.name,
            duration: workout.duration,
            distance: workout.totalDistance?.doubleValue(for: .meter()),
            isValid: validation.isValid,
            confidence: validation.confidence,
            issues: validation.issues,
            requiresReview: validation.requiresManualReview
        )
    }
}

struct CheatReport: Codable {
    let workoutId: String
    let timestamp: Date
    let workoutType: String
    let duration: TimeInterval
    let distance: Double?
    let isValid: Bool
    let confidence: Double
    let issues: [AntiCheatService.ValidationIssue]
    let requiresReview: Bool
    
    var severityScore: Int {
        issues.reduce(0) { $0 + $1.severity.rawValue }
    }
}

extension AntiCheatService.ValidationIssue: Codable {
    enum CodingKeys: String, CodingKey {
        case type, severity, description, evidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeString = try container.decode(String.self, forKey: .type)
        let severityRaw = try container.decode(Int.self, forKey: .severity)
        
        self.type = IssueType(rawValue: typeString) ?? .suspiciousGPS
        self.severity = Severity(rawValue: severityRaw) ?? .low
        self.description = try container.decode(String.self, forKey: .description)
        self.evidence = try container.decode(String.self, forKey: .evidence)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(severity.rawValue, forKey: .severity)
        try container.encode(description, forKey: .description)
        try container.encode(evidence, forKey: .evidence)
    }
}

extension AntiCheatService.ValidationIssue.IssueType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "impossibleSpeed": self = .impossibleSpeed
        case "impossiblePace": self = .impossiblePace
        case "heartRateMismatch": self = .heartRateMismatch
        case "suddenImprovement": self = .suddenImprovement
        case "duplicatePattern": self = .duplicatePattern
        case "impossibleDuration": self = .impossibleDuration
        case "impossibleDistance": self = .impossibleDistance
        case "suspiciousGPS": self = .suspiciousGPS
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .impossibleSpeed: return "impossibleSpeed"
        case .impossiblePace: return "impossiblePace"
        case .heartRateMismatch: return "heartRateMismatch"
        case .suddenImprovement: return "suddenImprovement"
        case .duplicatePattern: return "duplicatePattern"
        case .impossibleDuration: return "impossibleDuration"
        case .impossibleDistance: return "impossibleDistance"
        case .suspiciousGPS: return "suspiciousGPS"
        }
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .yoga: return "Yoga"
        case .highIntensityIntervalTraining: return "HIIT"
        case .coreTraining: return "Core Training"
        case .functionalStrengthTraining: return "Functional Strength"
        case .traditionalStrengthTraining: return "Strength Training"
        default: return "Other"
        }
    }
}