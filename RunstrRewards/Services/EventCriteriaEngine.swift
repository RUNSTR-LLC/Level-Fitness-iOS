import Foundation
import HealthKit

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
        setupNotificationObservers()
        print("EventCriteriaEngine: Initialized with \(activeCriteria.count) active events")
    }
    
    private func setupNotificationObservers() {
        // Listen to WorkoutAdded notifications from WorkoutSyncQueue
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWorkoutAdded),
            name: NSNotification.Name("WorkoutAdded"),
            object: nil
        )
        
        print("🎯 EventCriteriaEngine: Set up notification observers for WorkoutAdded")
    }
    
    @objc private func handleWorkoutAdded(_ notification: Notification) {
        guard let userId = notification.userInfo?["userId"] as? String else {
            print("🎯 EventCriteriaEngine: WorkoutAdded notification missing userId")
            return
        }
        
        Task {
            // Check for HealthKitWorkout first (from HealthKit observer)
            if let healthKitWorkout = notification.userInfo?["workout"] as? HealthKitWorkout {
                print("🎯 EventCriteriaEngine: Processing HealthKitWorkout from notification")
                await self.processWorkoutForEvents(healthKitWorkout, userId: userId)
            }
            // Check for Workout (from WorkoutSyncQueue)  
            else if let workout = notification.userInfo?["workout"] as? Workout {
                print("🎯 EventCriteriaEngine: Processing Workout from notification, converting to HealthKitWorkout")
                let healthKitWorkout = self.convertWorkoutToHealthKitWorkout(workout)
                await self.processWorkoutForEvents(healthKitWorkout, userId: userId)
            }
            else {
                print("🎯 EventCriteriaEngine: ⚠️ WorkoutAdded notification missing expected workout object")
            }
        }
    }
    
    private func convertWorkoutToHealthKitWorkout(_ workout: Workout) -> HealthKitWorkout {
        return HealthKitWorkout(
            id: workout.id,
            activityType: HKWorkoutActivityType.running, // Default to running, could be enhanced based on workout.type
            startDate: workout.startedAt,
            endDate: workout.endedAt ?? workout.startedAt.addingTimeInterval(TimeInterval(workout.duration)),
            duration: TimeInterval(workout.duration),
            totalDistance: workout.distance,
            totalEnergyBurned: workout.calories.map { Double($0) },
            syncSource: WorkoutSyncSource(rawValue: workout.source) ?? .healthKit,
            metadata: [:]
        )
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
        let now = Date()
        
        print("🎯 EventCriteriaEngine: Evaluating workout against \(activeCriteria.count) active criteria")
        
        for criteria in activeCriteria {
            print("🎯 Checking event: '\(criteria.name)' (Active: \(criteria.isActive), Auto-entry: \(criteria.autoEntry))")
            
            // Check if event is currently active
            guard criteria.isActive else {
                print("🎯 Event '\(criteria.name)' is not active - skipping")
                continue
            }
            
            guard now >= criteria.startDate else {
                print("🎯 Event '\(criteria.name)' hasn't started yet - skipping")
                continue
            }
            
            guard now <= criteria.endDate else {
                print("🎯 Event '\(criteria.name)' has ended - skipping")
                continue
            }
            
            print("🎯 Event '\(criteria.name)' is active and within time window - evaluating")
            
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
        let workoutDistance = workout.totalDistance ?? 0.0 // meters
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
        
        let reason: String
        if passes {
            reason = ""
        } else {
            let workoutKm = String(format: "%.1f", workoutDistance/1000)
            let targetKm = String(format: "%.1f", targetDistance/1000)
            reason = "Distance \(workoutKm)km < required \(targetKm)km"
        }
        
        print("🎯 EventCriteriaEngine: Distance rule evaluation:")
        print("🎯   - Workout distance: \(String(format: "%.1f", workoutDistance/1000))km (\(Int(workoutDistance))m)")
        print("🎯   - Target distance: \(String(format: "%.1f", targetDistance/1000))km (\(Int(targetDistance))m)")
        print("🎯   - Rule unit: \(rule.unit ?? "meters")")
        print("🎯   - Rule value: \(rule.value)")
        print("🎯   - Comparison: \(rule.comparisonOperator.rawValue)")
        print("🎯   - Passes: \(passes) | Progress: \(String(format: "%.1f", progress * 100))%")
        if !reason.isEmpty {
            print("🎯   - Reason: \(reason)")
        }
        
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
        guard (workout.totalDistance ?? 0.0) > 0 && workout.duration > 0 else {
            return (passes: false, progress: 0, reason: "Insufficient data for pace calculation")
        }
        
        // Calculate pace in minutes per kilometer
        let paceMinutesPerKm = (workout.duration / 60) / ((workout.totalDistance ?? 0.0) / 1000)
        let targetPace = rule.value
        
        let passes = compareValues(paceMinutesPerKm, targetPace, rule.comparisonOperator)
        let progress = rule.comparisonOperator == .lessThanOrEqual ? min(targetPace / paceMinutesPerKm, 1.0) : min(paceMinutesPerKm / targetPace, 1.0)
        let reason = passes ? "" : "Pace \(String(format: "%.2f", paceMinutesPerKm)) min/km vs target \(String(format: "%.2f", targetPace)) min/km"
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateCaloriesRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutCalories = workout.totalEnergyBurned ?? 0.0
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
        
        // Check for exact match or compatible workout types
        let workoutTypeLower = workout.workoutType.lowercased()
        let passes = allowedTypes.contains { allowedType in
            let allowedLower = allowedType.lowercased()
            
            // Direct match
            if workoutTypeLower == allowedLower {
                return true
            }
            
            // Handle similar workout types
            switch (workoutTypeLower, allowedLower) {
            case ("running", "run"), ("run", "running"):
                return true
            case ("cycling", "bike"), ("bike", "cycling"), ("biking", "cycling"):
                return true
            case ("walking", "walk"), ("walk", "walking"):
                return true
            case ("strength training", "strength"), ("strength", "strength training"):
                return true
            default:
                return false
            }
        }
        
        let progress = passes ? 1.0 : 0.0
        let reason = passes ? "" : "Workout type '\(workout.workoutType)' not compatible with allowed types: \(allowedTypes.joined(separator: ", "))"
        
        print("🎯 EventCriteriaEngine: Workout type rule - Type: '\(workout.workoutType)', Allowed: \(allowedTypes), Passes: \(passes)")
        
        return (passes: passes, progress: progress, reason: reason)
    }
    
    private func evaluateTimeWindowRule(_ rule: CriteriaRule, workout: HealthKitWorkout) -> (passes: Bool, progress: Double, reason: String) {
        let workoutTime = workout.startDate.timeIntervalSince1970
        let windowStart = rule.value
        
        // Get current time for validation
        let now = Date().timeIntervalSince1970
        
        // Check if workout occurred after event start and before now
        let passes = workoutTime >= windowStart && workoutTime <= now
        let progress = passes ? 1.0 : 0.0
        
        let reason: String
        if passes {
            reason = ""
        } else if workoutTime < windowStart {
            reason = "Workout occurred before event started"
        } else {
            reason = "Workout timestamp invalid"
        }
        
        let workoutDate = Date(timeIntervalSince1970: workoutTime).formatted(.dateTime.month(.abbreviated).day().hour().minute())
        let startDate = Date(timeIntervalSince1970: windowStart).formatted(.dateTime.month(.abbreviated).day().hour().minute())
        
        print("🎯 EventCriteriaEngine: Time window rule - Workout: \(workoutDate), Event start: \(startDate), Passes: \(passes)")
        
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
            
            print("🎯 EventCriteriaEngine: ✅ Auto-entered user \(userId) in event \(eventId)")
            
            // Get event details for enhanced notification
            let events = try await supabaseService.fetchEvents(status: "active")
            if let event = events.first(where: { $0.id == eventId }) {
                await MainActor.run {
                    notificationService.scheduleEventCompletionNotification(
                        eventName: event.name,
                        achievement: "Qualified!"
                    )
                }
                
                print("🎯 EventCriteriaEngine: Sent event completion notification for \(event.name)")
            }
            
        } catch {
            print("❌ EventCriteriaEngine: Failed to auto-enter user in event: \(error)")
        }
    }
    
    private func updateEventProgress(userId: String, eventId: String, progress: Double) async {
        // Update participant progress (placeholder for future database implementation)
        let progressPercent = Int(progress * 100)
        
        print("🎯 EventCriteriaEngine: Progress for user \(userId) in event \(eventId): \(progressPercent)%")
        
        // Send progress notification if significant milestone
        if progressPercent >= 25 && progressPercent % 25 == 0 {
            await sendProgressNotification(userId: userId, eventId: eventId, progress: progressPercent)
        }
    }
    
    private func sendProgressNotification(userId: String, eventId: String, progress: Int) async {
        do {
            // Get event details for notification
            let events = try await supabaseService.fetchEvents(status: "active")
            guard let event = events.first(where: { $0.id == eventId }) else {
                print("❌ EventCriteriaEngine: Event not found for progress notification")
                return
            }
            
            await MainActor.run {
                notificationService.scheduleEventProgressNotification(
                    eventName: event.name,
                    progress: progress,
                    targetDescription: "completion"
                )
            }
            
            print("🎯 EventCriteriaEngine: Sent progress notification for \(progress)% completion in \(event.name)")
            
        } catch {
            print("❌ EventCriteriaEngine: Failed to send progress notification: \(error)")
        }
    }
    
    // MARK: - Public Interface
    
    func refreshActiveCriteria() async {
        await loadActiveCriteria()
    }
    
    func getActiveCriteria() -> [EventCriteria] {
        return activeCriteria
    }
    
    func processWorkoutForEvents(_ workout: HealthKitWorkout, userId: String) async {
        print("\n🎯 ===== EventCriteriaEngine: Processing Workout =====")
        print("🎯 User: \(userId)")
        print("🎯 Workout ID: \(workout.id)")
        print("🎯 Type: \(workout.workoutType)")
        print("🎯 Distance: \(String(format: "%.1f", (workout.totalDistance ?? 0)/1000))km (\(Int(workout.totalDistance ?? 0))m)")
        print("🎯 Duration: \(Int(workout.duration/60))min \(Int(workout.duration.truncatingRemainder(dividingBy: 60)))sec")
        print("🎯 Start Date: \(workout.startDate)")
        print("🎯 Active Events: \(activeCriteria.count)")
        print("🎯 ================================================")
        
        let matches = await evaluateWorkout(workout, userId: userId)
        
        print("🎯 ===== Evaluation Results =====")
        print("🎯 Found \(matches.count) event matches")
        
        for (index, match) in matches.enumerated() {
            print("🎯 Event \(index + 1): '\(match.criteria.name)' (ID: \(match.eventId))")
            switch match.qualification {
            case .qualified:
                print("🎯   ✅ QUALIFIED - User qualified for event!")
                print("🎯   📋 Matched rules: \(match.matchedRules.count)/\(match.criteria.rules.count)")
                print("🎯   📊 Progress: \(String(format: "%.1f", match.progress * 100))%")
                
            case .inProgress(let progress):
                print("🎯   🔄 IN PROGRESS - \(Int(progress * 100))% complete")
                print("🎯   📋 Matched rules: \(match.matchedRules.count)/\(match.criteria.rules.count)")
                
            case .notQualified(let reason):
                print("🎯   ❌ NOT QUALIFIED - \(reason)")
                print("🎯   📋 Matched rules: \(match.matchedRules.count)/\(match.criteria.rules.count)")
            }
        }
        
        if matches.isEmpty {
            print("🎯 ❓ No matching events found for this workout")
        }
        
        print("🎯 ============= End Processing ============\n")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}