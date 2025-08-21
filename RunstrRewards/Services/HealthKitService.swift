import Foundation
import HealthKit

class HealthKitService: @unchecked Sendable {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    private let syncQueue = DispatchQueue(label: "com.runstrrewards.healthkit", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let workoutType = HKObjectType.workoutType()
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceWalkingRunningType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceCyclingType = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceWalkingRunningType,
            distanceCyclingType,
            stepCountType
        ]
        
        let typesToWrite: Set<HKSampleType> = [workoutType]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self.isAuthorized = success
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func checkAuthorizationStatus() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        return status == .sharingAuthorized
    }
    
    // MARK: - Workout Data Fetching
    
    func fetchRecentWorkouts(limit: Int = 50) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        // Validate limit
        let safeLimit = min(max(limit, 1), 100) // Limit between 1 and 100
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: safeLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let healthKitWorkouts = workouts.map { workout in
                    HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        workoutType: self.mapWorkoutType(workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
                        source: workout.sourceRevision.source.name,
                        metadata: workout.metadata
                    )
                }
                
                continuation.resume(returning: healthKitWorkouts)
            }
            
            healthStore.execute(workoutQuery)
        }
    }
    
    func fetchWorkoutsSince(_ date: Date, limit: Int = 100) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let healthKitWorkouts = workouts.map { workout in
                    HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        workoutType: self.mapWorkoutType(workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
                        source: workout.sourceRevision.source.name,
                        metadata: workout.metadata
                    )
                }
                
                continuation.resume(returning: healthKitWorkouts)
            }
            
            healthStore.execute(workoutQuery)
        }
    }
    
    func fetchHeartRateData(for workout: HealthKitWorkout) async throws -> [HeartRateData] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let heartRateQuery = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let heartRateSamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let heartRateData = heartRateSamples.map { sample in
                    HeartRateData(
                        timestamp: sample.startDate,
                        beatsPerMinute: Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                    )
                }
                
                continuation.resume(returning: heartRateData)
            }
            
            healthStore.execute(heartRateQuery)
        }
    }
    
    // MARK: - Background Sync
    
    func enableBackgroundDelivery() async throws {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    print("HealthKitService: Background delivery enabled")
                    continuation.resume()
                }
            }
        }
    }
    
    func observeWorkouts(handler: @escaping ([HealthKitWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("HealthKitService: Observer query error: \(error)")
                completionHandler()
                return
            }
            
            Task {
                do {
                    let workouts = try await self?.fetchRecentWorkouts(limit: 10) ?? []
                    await MainActor.run {
                        handler(workouts)
                    }
                    completionHandler()
                } catch {
                    print("HealthKitService: Failed to fetch workouts in observer: \(error)")
                    completionHandler()
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Helper Methods
    
    private func mapWorkoutType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "running"
        case .walking:
            return "walking"
        case .cycling:
            return "cycling"
        case .swimming:
            return "swimming"
        case .tennis:
            return "tennis"
        case .basketball:
            return "basketball"
        case .soccer:
            return "soccer"
        case .baseball:
            return "baseball"
        case .americanFootball:
            return "football"
        case .golf:
            return "golf"
        case .hiking:
            return "hiking"
        case .yoga:
            return "yoga"
        case .functionalStrengthTraining:
            return "strength_training"
        case .traditionalStrengthTraining:
            return "strength_training"
        case .coreTraining:
            return "core_training"
        case .flexibility:
            return "stretching"
        case .highIntensityIntervalTraining:
            return "hiit"
        case .dance:
            return "dance"
        case .boxing:
            return "boxing"
        case .martialArts:
            return "martial_arts"
        case .rowing:
            return "rowing"
        case .elliptical:
            return "elliptical"
        case .stairClimbing:
            return "stairs"
        case .other:
            return "other"
        default:
            return "other"
        }
    }
    
    // Convert HealthKitWorkout to Supabase Workout format
    func convertToSupabaseWorkout(_ healthKitWorkout: HealthKitWorkout, userId: String) -> Workout {
        return Workout(
            id: healthKitWorkout.id,
            userId: userId,
            type: healthKitWorkout.workoutType,
            duration: Int(healthKitWorkout.duration),
            distance: healthKitWorkout.totalDistance > 0 ? healthKitWorkout.totalDistance : nil,
            calories: Int(healthKitWorkout.totalEnergyBurned),
            heartRate: nil, // Will be calculated from heart rate data if needed
            source: "healthkit",
            startedAt: healthKitWorkout.startDate,
            endedAt: healthKitWorkout.endDate,
            syncedAt: Date()
        )
    }
    
    // MARK: - Enhanced Duplicate Detection
    
    func detectDuplicates(in workouts: [HealthKitWorkout]) -> [HealthKitWorkout] {
        var deduplicatedWorkouts: [HealthKitWorkout] = []
        var processedWorkouts: [WorkoutFingerprint] = []
        
        for workout in workouts {
            let fingerprint = createWorkoutFingerprint(workout)
            
            // Check for duplicates
            if let existingIndex = findDuplicate(fingerprint, in: processedWorkouts) {
                let existingFingerprint = processedWorkouts[existingIndex]
                
                // Resolve conflict using source priority
                if shouldReplaceExisting(newFingerprint: fingerprint, existingFingerprint: existingFingerprint) {
                    // Replace existing workout
                    processedWorkouts[existingIndex] = fingerprint
                    if let workoutIndex = deduplicatedWorkouts.firstIndex(where: { $0.id == existingFingerprint.workoutId }) {
                        deduplicatedWorkouts[workoutIndex] = workout
                    }
                    print("HealthKitService: 🔄 Replaced duplicate workout from \(existingFingerprint.source) with \(fingerprint.source)")
                } else {
                    print("HealthKitService: ⚠️ Skipped duplicate workout from \(fingerprint.source), keeping \(existingFingerprint.source)")
                }
            } else {
                // No duplicate found, add workout
                processedWorkouts.append(fingerprint)
                deduplicatedWorkouts.append(workout)
            }
        }
        
        let removedCount = workouts.count - deduplicatedWorkouts.count
        if removedCount > 0 {
            print("HealthKitService: 🧹 Removed \(removedCount) duplicate workouts")
        }
        
        return deduplicatedWorkouts
    }
    
    private func createWorkoutFingerprint(_ workout: HealthKitWorkout) -> WorkoutFingerprint {
        let sourcePriority = getSourcePriority(workout.source)
        
        return WorkoutFingerprint(
            workoutId: workout.id,
            startTime: workout.startDate,
            duration: workout.duration,
            distance: workout.totalDistance,
            calories: workout.totalEnergyBurned,
            workoutType: workout.workoutType,
            source: workout.source,
            sourcePriority: sourcePriority,
            fingerprint: generateFingerprint(workout)
        )
    }
    
    private func generateFingerprint(_ workout: HealthKitWorkout) -> String {
        // Create a unique fingerprint based on key workout characteristics
        let startTimestamp = Int(workout.startDate.timeIntervalSince1970 / 60) * 60 // Round to nearest minute
        let duration = Int(workout.duration / 60) * 60 // Round to nearest minute
        let distance = Int(workout.totalDistance / 100) * 100 // Round to nearest 100m
        let calories = Int(workout.totalEnergyBurned / 10) * 10 // Round to nearest 10 calories
        
        return "\(workout.workoutType)_\(startTimestamp)_\(duration)_\(distance)_\(calories)"
    }
    
    private func getSourcePriority(_ source: String) -> Int {
        let sourceLower = source.lowercased()
        
        // Higher number = higher priority
        if sourceLower.contains("manual") || sourceLower.contains("user") {
            return 100 // Manual entries have highest priority
        } else if sourceLower.contains("apple watch") || sourceLower.contains("watch") {
            return 90 // Apple Watch has high priority
        } else if sourceLower.contains("gps") || sourceLower.contains("outdoor") {
            return 80 // GPS-based workouts
        } else if sourceLower.contains("strava") {
            return 70 // Strava
        } else if sourceLower.contains("garmin") {
            return 75 // Garmin
        } else if sourceLower.contains("polar") {
            return 65 // Polar
        } else if sourceLower.contains("fitbit") {
            return 60 // Fitbit
        } else if sourceLower.contains("indoor") || sourceLower.contains("treadmill") {
            return 50 // Indoor/estimated workouts
        } else {
            return 40 // Unknown sources
        }
    }
    
    private func findDuplicate(_ fingerprint: WorkoutFingerprint, in existing: [WorkoutFingerprint]) -> Int? {
        for (index, existingFingerprint) in existing.enumerated() {
            if isDuplicate(fingerprint, existingFingerprint) {
                return index
            }
        }
        return nil
    }
    
    private func isDuplicate(_ workout1: WorkoutFingerprint, _ workout2: WorkoutFingerprint) -> Bool {
        // Check exact fingerprint match first
        if workout1.fingerprint == workout2.fingerprint {
            return true
        }
        
        // Check for near-duplicate criteria
        let timeDifference = abs(workout1.startTime.timeIntervalSince(workout2.startTime))
        let durationDifference = abs(workout1.duration - workout2.duration)
        let distanceDifference = abs(workout1.distance - workout2.distance)
        
        // Same workout type within time tolerance
        let sameType = workout1.workoutType == workout2.workoutType
        let timeWindow = timeDifference <= 300 // 5 minutes
        let durationSimilar = durationDifference <= 120 // 2 minutes
        let distanceSimilar = distanceDifference <= 100 // 100 meters
        
        return sameType && timeWindow && durationSimilar && distanceSimilar
    }
    
    private func shouldReplaceExisting(newFingerprint: WorkoutFingerprint, existingFingerprint: WorkoutFingerprint) -> Bool {
        // Replace if new workout has higher source priority
        if newFingerprint.sourcePriority > existingFingerprint.sourcePriority {
            return true
        }
        
        // If same priority, prefer more complete data
        if newFingerprint.sourcePriority == existingFingerprint.sourcePriority {
            let newCompleteness = calculateDataCompleteness(newFingerprint)
            let existingCompleteness = calculateDataCompleteness(existingFingerprint)
            return newCompleteness > existingCompleteness
        }
        
        return false
    }
    
    private func calculateDataCompleteness(_ fingerprint: WorkoutFingerprint) -> Int {
        var completeness = 0
        
        if fingerprint.duration > 0 { completeness += 1 }
        if fingerprint.distance > 0 { completeness += 1 }
        if fingerprint.calories > 0 { completeness += 1 }
        
        return completeness
    }
    
    // MARK: - Cross-Platform Detection
    
    func detectCrossPlatformDuplicates(_ healthKitWorkouts: [HealthKitWorkout], _ existingWorkouts: [Workout]) -> [HealthKitWorkout] {
        var filteredWorkouts: [HealthKitWorkout] = []
        
        for healthKitWorkout in healthKitWorkouts {
            let healthKitFingerprint = createWorkoutFingerprint(healthKitWorkout)
            var hasDuplicate = false
            
            for existingWorkout in existingWorkouts {
                let existingFingerprint = createWorkoutFingerprintFromSupabase(existingWorkout)
                
                if isDuplicate(healthKitFingerprint, existingFingerprint) {
                    print("HealthKitService: 🔍 Found cross-platform duplicate: HealthKit vs \(existingWorkout.source)")
                    
                    // Only skip if existing workout has higher or equal priority
                    if healthKitFingerprint.sourcePriority <= existingFingerprint.sourcePriority {
                        hasDuplicate = true
                        break
                    }
                }
            }
            
            if !hasDuplicate {
                filteredWorkouts.append(healthKitWorkout)
            }
        }
        
        let filteredCount = healthKitWorkouts.count - filteredWorkouts.count
        if filteredCount > 0 {
            print("HealthKitService: 🌐 Filtered \(filteredCount) cross-platform duplicates")
        }
        
        return filteredWorkouts
    }
    
    private func createWorkoutFingerprintFromSupabase(_ workout: Workout) -> WorkoutFingerprint {
        let sourcePriority = getSourcePriority(workout.source)
        
        return WorkoutFingerprint(
            workoutId: workout.id,
            startTime: workout.startedAt,
            duration: TimeInterval(workout.duration),
            distance: workout.distance ?? 0,
            calories: Double(workout.calories ?? 0),
            workoutType: workout.type,
            source: workout.source,
            sourcePriority: sourcePriority,
            fingerprint: generateFingerprintFromSupabase(workout)
        )
    }
    
    private func generateFingerprintFromSupabase(_ workout: Workout) -> String {
        let startTimestamp = Int(workout.startedAt.timeIntervalSince1970 / 60) * 60
        let duration = (workout.duration / 60) * 60
        let distance = Int((workout.distance ?? 0) / 100) * 100
        let calories = ((workout.calories ?? 0) / 10) * 10
        
        return "\(workout.type)_\(startTimestamp)_\(duration)_\(distance)_\(calories)"
    }
}

// MARK: - Data Models

struct HealthKitWorkout {
    let id: String
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalDistance: Double // meters
    let totalEnergyBurned: Double // kcal
    let source: String
    let metadata: [String: Any]?
}

struct HeartRateData {
    let timestamp: Date
    let beatsPerMinute: Int
}

struct WorkoutFingerprint {
    let workoutId: String
    let startTime: Date
    let duration: TimeInterval
    let distance: Double
    let calories: Double
    let workoutType: String
    let source: String
    let sourcePriority: Int
    let fingerprint: String
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case notAuthorized
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .notAuthorized:
            return "Health data access not authorized"
        case .queryFailed:
            return "Failed to query health data"
        }
    }
}