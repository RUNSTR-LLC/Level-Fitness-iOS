import Foundation

// MARK: - Event Criteria Data Models

struct EventCriteria: Codable {
    let eventId: String
    let name: String
    let rules: [CriteriaRule]
    let autoEntry: Bool
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case name, rules
        case autoEntry = "auto_entry"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }
}

struct CriteriaRule: Codable {
    let type: RuleType
    let comparisonOperator: ComparisonOperator
    let value: Double
    let unit: String?
    let workoutTypes: [String]?
    
    enum CodingKeys: String, CodingKey {
        case type
        case comparisonOperator = "operator"
        case value, unit
        case workoutTypes = "workout_types"
    }
}

enum RuleType: String, Codable {
    case distance = "distance"
    case duration = "duration"
    case pace = "pace"
    case calories = "calories"
    case heartRate = "heart_rate"
    case workoutType = "workout_type"
    case timeWindow = "time_window"
    case frequency = "frequency"
}

enum ComparisonOperator: String, Codable {
    case greaterThan = "gt"
    case greaterThanOrEqual = "gte"
    case lessThan = "lt"
    case lessThanOrEqual = "lte"
    case equal = "eq"
    case notEqual = "ne"
    case contains = "contains"
    case between = "between"
}

struct EventMatch {
    let eventId: String
    let criteria: EventCriteria
    let matchedRules: [CriteriaRule]
    let progress: Double
    let qualification: EventQualification
}

enum EventQualification {
    case qualified
    case inProgress(progress: Double)
    case notQualified(reason: String)
}

// MARK: - Event Criteria Engine

class EventCriteriaEngine {
    static let shared = EventCriteriaEngine()
    
    private var activeCriteria: [EventCriteria] = []
    private let supabaseService = SupabaseService.shared
    private let notificationService = NotificationService.shared
    
    private init() {}
    
    // MARK: - Setup and Management
    
    func initialize() async {
        await loadActiveCriteria()
        print("EventCriteriaEngine: Initialized with \(activeCriteria.count) active events")
    }
    
    private func loadActiveCriteria() async {
        do {
            // Load active events from Supabase
            let events = try await supabaseService.fetchEvents(status: "active")
            
            // Convert to EventCriteria with default rules
            activeCriteria = events.compactMap { event in
                // Create default criteria based on event properties
                let rules = createDefaultRules(for: event)
                
                return EventCriteria(
                    eventId: event.id,
                    name: event.name,
                    rules: rules,
                    autoEntry: true,
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isActive: event.status == "active"
                )
            }
            
            print("EventCriteriaEngine: Loaded \(activeCriteria.count) active event criteria")
            
        } catch {
            print("EventCriteriaEngine: Failed to load active criteria: \(error)")
        }
    }
    
    private func createDefaultRules(for event: CompetitionEvent) -> [CriteriaRule] {
        var rules: [CriteriaRule] = []
        
        // Create rule based on event type and target value
        switch event.type.lowercased() {
        case "distance":
            rules.append(CriteriaRule(
                type: .distance,
                comparisonOperator: .greaterThanOrEqual,
                value: event.targetValue,
                unit: event.unit,
                workoutTypes: ["running", "cycling", "walking"]
            ))
            
        case "duration":
            rules.append(CriteriaRule(
                type: .duration,
                comparisonOperator: .greaterThanOrEqual,
                value: event.targetValue,
                unit: event.unit,
                workoutTypes: nil
            ))
            
        case "calories":
            rules.append(CriteriaRule(
                type: .calories,
                comparisonOperator: .greaterThanOrEqual,
                value: event.targetValue,
                unit: event.unit,
                workoutTypes: nil
            ))
            
        case "pace":
            rules.append(CriteriaRule(
                type: .pace,
                comparisonOperator: .lessThanOrEqual,
                value: event.targetValue,
                unit: event.unit,
                workoutTypes: ["running"]
            ))
            
        default:
            // General participation rule
            rules.append(CriteriaRule(
                type: .workoutType,
                comparisonOperator: .contains,
                value: 1,
                unit: nil,
                workoutTypes: ["running", "cycling", "walking"]
            ))
        }
        
        // Add time window rule
        rules.append(CriteriaRule(
            type: .timeWindow,
            comparisonOperator: .between,
            value: event.startDate.timeIntervalSince1970,
            unit: "timestamp",
            workoutTypes: nil
        ))
        
        return rules
    }
    
    // MARK: - Workout Evaluation
    
    func evaluateWorkout(_ workout: HealthKitWorkout, userId: String) async -> [EventMatch] {
        var matches: [EventMatch] = []
        
        for criteria in activeCriteria {
            // Check if event is currently active
            let now = Date()
            guard criteria.isActive && 
                  now >= criteria.startDate && 
                  now <= criteria.endDate else {
                continue
            }
            
            let match = evaluateWorkoutAgainstCriteria(workout, criteria: criteria)
            
            if case .qualified = match.qualification {
                matches.append(match)
                
                // Auto-enter user if criteria allows
                if criteria.autoEntry {
                    await autoEnterUserInEvent(userId: userId, eventId: criteria.eventId, workout: workout)
                }
            } else if case .inProgress = match.qualification {
                matches.append(match)
                await updateEventProgress(userId: userId, eventId: criteria.eventId, progress: match.progress)
            }
        }
        
        return matches
    }
    
    private func evaluateWorkoutAgainstCriteria(_ workout: HealthKitWorkout, criteria: EventCriteria) -> EventMatch {
        var matchedRules: [CriteriaRule] = []
        var totalProgress: Double = 0
        var qualificationMet = true
        var failureReason = ""
        
        for rule in criteria.rules {
            let ruleResult = evaluateRule(rule, against: workout)
            
            if ruleResult.passes {
                matchedRules.append(rule)
                totalProgress += ruleResult.progress
            } else {
                qualificationMet = false
                if failureReason.isEmpty {
                    failureReason = ruleResult.reason
                }
            }
        }
        
        let averageProgress = criteria.rules.isEmpty ? 0 : totalProgress / Double(criteria.rules.count)
        
        let qualification: EventQualification
        if qualificationMet && !matchedRules.isEmpty {
            qualification = .qualified
        } else if averageProgress > 0 {
            qualification = .inProgress(progress: averageProgress)
        } else {
            qualification = .notQualified(reason: failureReason)
        }
        
        return EventMatch(
            eventId: criteria.eventId,
            criteria: criteria,
            matchedRules: matchedRules,
            progress: averageProgress,
            qualification: qualification
        )
    }
    
    private func evaluateRule(_ rule: CriteriaRule, against workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        switch rule.type {
        case .distance:
            return evaluateDistanceRule(rule, workout: workout)
        case .duration:
            return evaluateDurationRule(rule, workout: workout)
        case .pace:
            return evaluatePaceRule(rule, workout: workout)
        case .calories:
            return evaluateCaloriesRule(rule, workout: workout)
        case .workoutType:
            return evaluateWorkoutTypeRule(rule, workout: workout)
        case .timeWindow:
            return evaluateTimeWindowRule(rule, workout: workout)
        case .heartRate:
            return (passes: true, progress: 1.0, reason: "Heart rate evaluation not implemented")
        case .frequency:
            return (passes: true, progress: 1.0, reason: "Frequency evaluation requires user history")
        }
    }
    
    // MARK: - Individual Rule Evaluators
    
    private func evaluateDistanceRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutDistance = workout.totalDistance // meters
        var targetDistance = rule.value
        
        // Convert units if necessary
        if let unit = rule.unit {
            switch unit.lowercased() {
            case "km", "kilometers":
                targetDistance = rule.value * 1000 // convert km to meters
            case "mi", "miles":
                targetDistance = rule.value * 1609.34 // convert miles to meters
            default:
                break // assume meters
            }
        }
        
        let passes = compareValues(workoutDistance, targetDistance, rule.comparisonOperator)
        let progress = min(workoutDistance / targetDistance, 1.0)
        let reason = passes ? "" : "Distance \(workoutDistance/1000)km < required \(targetDistance/1000)km"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateDurationRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutDuration = workout.duration // seconds
        var targetDuration = rule.value
        
        // Convert units if necessary
        if let unit = rule.unit {
            switch unit.lowercased() {
            case "min", "minutes":
                targetDuration = rule.value * 60 // convert minutes to seconds
            case "hr", "hours":
                targetDuration = rule.value * 3600 // convert hours to seconds
            default:
                break // assume seconds
            }
        }
        
        let passes = compareValues(workoutDuration, targetDuration, rule.comparisonOperator)
        let progress = min(workoutDuration / targetDuration, 1.0)
        let reason = passes ? "" : "Duration \(Int(workoutDuration/60))min < required \(Int(targetDuration/60))min"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluatePaceRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        guard workout.totalDistance > 0 && workout.duration > 0 else {
            return (passes: false, progress: 0, reason: "Insufficient data for pace calculation")
        }
        
        // Calculate pace in minutes per kilometer
        let paceMinutesPerKm = (workout.duration / 60) / (workout.totalDistance / 1000)
        let targetPace = rule.value
        
        let passes = compareValues(paceMinutesPerKm, targetPace, rule.comparisonOperator)
        let progress = rule.comparisonOperator == .lessThanOrEqual ? min(targetPace / paceMinutesPerKm, 1.0) : min(paceMinutesPerKm / targetPace, 1.0)
        let reason = passes ? "" : "Pace \(String(format: "%.2f", paceMinutesPerKm)) min/km vs target \(String(format: "%.2f", targetPace)) min/km"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateCaloriesRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutCalories = workout.totalEnergyBurned
        let targetCalories = rule.value
        
        let passes = compareValues(workoutCalories, targetCalories, rule.comparisonOperator)
        let progress = min(workoutCalories / targetCalories, 1.0)
        let reason = passes ? "" : "Calories \(Int(workoutCalories)) < required \(Int(targetCalories))"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateWorkoutTypeRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        guard let allowedTypes = rule.workoutTypes else {
            return (passes: true, progress: 1.0, reason: "")
        }
        
        let passes = allowedTypes.contains(workout.workoutType.lowercased())
        let progress = passes ? 1.0 : 0.0
        let reason = passes ? "" : "Workout type '\(workout.workoutType)' not in allowed types: \(allowedTypes.joined(separator: ", "))"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateTimeWindowRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutTime = workout.startDate.timeIntervalSince1970
        let windowStart = rule.value
        
        // For time windows, we need the end time from the criteria
        // For now, assume it's a current event if workout is recent
        let passes = workoutTime >= windowStart
        let progress = passes ? 1.0 : 0.0
        let reason = passes ? "" : "Workout outside event time window"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    // MARK: - Utility Methods
    
    private func compareValues(_ actual: Double, _ target: Double, _ comparisonOperator: ComparisonOperator) -> Bool {
        switch comparisonOperator {
        case .greaterThan:
            return actual > target
        case .greaterThanOrEqual:
            return actual >= target
        case .lessThan:
            return actual < target
        case .lessThanOrEqual:
            return actual <= target
        case .equal:
            return abs(actual - target) < 0.001 // floating point comparison
        case .notEqual:
            return abs(actual - target) >= 0.001
        case .contains, .between:
            return true // These require special handling based on context
        }
    }
    
    // MARK: - Event Participation Actions
    
    private func autoEnterUserInEvent(userId: String, eventId: String, workout: HealthKitWorkout) async {
        do {
            try await supabaseService.joinEvent(eventId: eventId, userId: userId)
            
            // Send notification about auto-entry
            await MainActor.run {
                notificationService.scheduleWorkoutRewardNotification(
                    amount: 100, // Base reward for event entry
                    workoutType: "Event Auto-Entry: \(workout.workoutType)"
                )
            }
            
            print("EventCriteriaEngine: Auto-entered user \(userId) in event \(eventId)")
            
        } catch {
            print("EventCriteriaEngine: Failed to auto-enter user in event: \(error)")
        }
    }
    
    private func updateEventProgress(userId: String, eventId: String, progress: Double) async {
        // Update participant progress in database
        // This would require extending SupabaseService with progress update method
        print("EventCriteriaEngine: Would update progress for user \(userId) in event \(eventId): \(progress)")
    }
    
    // MARK: - Public Interface
    
    func refreshActiveCriteria() async {
        await loadActiveCriteria()
    }
    
    func getActiveCriteria() -> [EventCriteria] {
        return activeCriteria
    }
    
    func processWorkoutForEvents(_ workout: HealthKitWorkout, userId: String) async {
        let matches = await evaluateWorkout(workout, userId: userId)
        
        for match in matches {
            switch match.qualification {
            case .qualified:
                print("EventCriteriaEngine: ✅ User qualified for event: \(match.criteria.name)")
                
            case .inProgress(let progress):
                print("EventCriteriaEngine: 🔄 User progress in event \(match.criteria.name): \(Int(progress * 100))%")
                
            case .notQualified(let reason):
                print("EventCriteriaEngine: ❌ User not qualified for event \(match.criteria.name): \(reason)")
            }
        }
    }
}