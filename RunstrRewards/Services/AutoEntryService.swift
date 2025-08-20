import Foundation
import HealthKit

// MARK: - Event Qualification Models

struct EventQualificationCriteria {
    let eventId: String
    let minDistance: Double?         // meters
    let minDuration: TimeInterval?   // seconds
    let minCalories: Double?         // kilocalories
    let requiredWorkoutTypes: [String]?
    let minWeeklyFrequency: Int?     // workouts per week
    let qualificationPeriod: TimeInterval? // seconds before event start
}

struct UserEventEntry {
    let userId: String
    let eventId: String
    let qualificationDate: Date
    let qualifyingWorkouts: [String] // workout IDs
    let autoEntered: Bool
    let entryStatus: EntryStatus
}

enum EntryStatus {
    case qualified
    case entered
    case disqualified
    case withdrawn
}

enum QualificationResult {
    case qualified(workouts: [HealthKitWorkout])
    case notQualified(reason: String)
    case alreadyEntered
}

// MARK: - AutoEntryService

class AutoEntryService {
    static let shared = AutoEntryService()
    
    private var qualificationCriteria: [String: EventQualificationCriteria] = [:]
    private var userEntries: [String: UserEventEntry] = [:]
    private let notificationCenter = NotificationCenter.default
    
    private init() {
        setupDefaultCriteria()
        observeWorkoutSync()
    }
    
    // MARK: - Setup
    
    private func setupDefaultCriteria() {
        // Default qualification criteria for common event types
        let marathonCriteria = EventQualificationCriteria(
            eventId: "default_marathon",
            minDistance: 21097.5, // Half marathon minimum
            minDuration: 3600, // 1 hour
            minCalories: 800,
            requiredWorkoutTypes: ["Running", "Cycling"],
            minWeeklyFrequency: 3,
            qualificationPeriod: 30 * 24 * 3600 // 30 days
        )
        
        let sprintCriteria = EventQualificationCriteria(
            eventId: "default_sprint",
            minDistance: 1000, // 1km minimum
            minDuration: 300, // 5 minutes
            minCalories: 100,
            requiredWorkoutTypes: ["Running", "Cycling", "Swimming"],
            minWeeklyFrequency: 2,
            qualificationPeriod: 7 * 24 * 3600 // 7 days
        )
        
        let challengeCriteria = EventQualificationCriteria(
            eventId: "default_challenge",
            minDistance: 5000, // 5km minimum
            minDuration: 1800, // 30 minutes
            minCalories: 300,
            requiredWorkoutTypes: nil, // Any workout type
            minWeeklyFrequency: 1,
            qualificationPeriod: 14 * 24 * 3600 // 14 days
        )
        
        qualificationCriteria["marathon"] = marathonCriteria
        qualificationCriteria["sprint"] = sprintCriteria
        qualificationCriteria["challenge"] = challengeCriteria
    }
    
    private func observeWorkoutSync() {
        notificationCenter.addObserver(
            self,
            selector: #selector(workoutSyncCompleted),
            name: NSNotification.Name("WorkoutSyncCompleted"),
            object: nil
        )
    }
    
    // MARK: - Event Registration
    
    func registerEvent(_ event: EventData, criteria: EventQualificationCriteria) {
        qualificationCriteria[event.id] = criteria
        print("🎯 AutoEntry: Registered event '\(event.name)' with qualification criteria")
        
        // Check existing users for qualification
        checkAllUsersForQualification(eventId: event.id)
    }
    
    func unregisterEvent(eventId: String) {
        qualificationCriteria.removeValue(forKey: eventId)
        // Remove user entries for this event
        userEntries = userEntries.filter { $0.value.eventId != eventId }
        print("🎯 AutoEntry: Unregistered event: \(eventId)")
    }
    
    // MARK: - Qualification Checking
    
    func checkUserQualification(userId: String, eventId: String, workoutHistory: [HealthKitWorkout]) -> QualificationResult {
        guard let criteria = qualificationCriteria[eventId] else {
            return .notQualified(reason: "Event criteria not found")
        }
        
        // Check if user is already entered
        let userKey = "\(userId)_\(eventId)"
        if let entry = userEntries[userKey], entry.entryStatus == .entered {
            return .alreadyEntered
        }
        
        // Filter workouts within qualification period
        let now = Date()
        let qualificationStart = now.addingTimeInterval(-(criteria.qualificationPeriod ?? 30 * 24 * 3600))
        
        let recentWorkouts = workoutHistory.filter { workout in
            workout.startDate >= qualificationStart && workout.endDate <= now
        }
        
        // Check qualification criteria
        let qualificationCheck = evaluateQualification(
            workouts: recentWorkouts,
            criteria: criteria
        )
        
        switch qualificationCheck {
        case .qualified(let qualifyingWorkouts):
            // Auto-enter the user if qualified
            let entry = UserEventEntry(
                userId: userId,
                eventId: eventId,
                qualificationDate: now,
                qualifyingWorkouts: qualifyingWorkouts.map { $0.id },
                autoEntered: true,
                entryStatus: .qualified
            )
            
            userEntries[userKey] = entry
            
            // Send qualification notification
            sendQualificationNotification(userId: userId, eventId: eventId, workouts: qualifyingWorkouts)
            
            return .qualified(workouts: qualifyingWorkouts)
            
        case .notQualified(let reason):
            return .notQualified(reason: reason)
            
        case .alreadyEntered:
            return .alreadyEntered
        }
    }
    
    private func evaluateQualification(workouts: [HealthKitWorkout], criteria: EventQualificationCriteria) -> QualificationResult {
        var qualifyingWorkouts: [HealthKitWorkout] = []
        
        // Filter by workout types if specified
        var eligibleWorkouts = workouts
        if let requiredTypes = criteria.requiredWorkoutTypes {
            eligibleWorkouts = workouts.filter { workout in
                requiredTypes.contains(workout.workoutType)
            }
        }
        
        // Check weekly frequency
        if let minFrequency = criteria.minWeeklyFrequency {
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
            let weeklyWorkouts = eligibleWorkouts.filter { $0.startDate >= weekAgo }
            
            if weeklyWorkouts.count < minFrequency {
                return .notQualified(reason: "Insufficient weekly frequency: \(weeklyWorkouts.count) < \(minFrequency)")
            }
        }
        
        // Find workouts that meet individual criteria
        for workout in eligibleWorkouts {
            var meetsAllCriteria = true
            
            // Check minimum distance
            if let minDistance = criteria.minDistance {
                if workout.totalDistance < minDistance {
                    meetsAllCriteria = false
                }
            }
            
            // Check minimum duration
            if let minDuration = criteria.minDuration {
                if workout.duration < minDuration {
                    meetsAllCriteria = false
                }
            }
            
            // Check minimum calories
            if let minCalories = criteria.minCalories {
                if workout.totalEnergyBurned < minCalories {
                    meetsAllCriteria = false
                }
            }
            
            if meetsAllCriteria {
                qualifyingWorkouts.append(workout)
            }
        }
        
        // Need at least one qualifying workout
        if qualifyingWorkouts.isEmpty {
            return .notQualified(reason: "No workouts meet the event criteria")
        }
        
        return .qualified(workouts: qualifyingWorkouts)
    }
    
    // MARK: - Background Processing
    
    @objc private func workoutSyncCompleted() {
        print("🎯 AutoEntry: Workout sync completed, checking qualifications")
        
        // Get current user ID (in real app, this would come from authentication)
        let currentUserId = "current_user" // Placeholder
        
        // Check all active events for qualification
        for eventId in qualificationCriteria.keys {
            checkUserForEventQualification(userId: currentUserId, eventId: eventId)
        }
    }
    
    private func checkAllUsersForQualification(eventId: String) {
        // In a real implementation, this would iterate through all users
        let currentUserId = "current_user" // Placeholder
        checkUserForEventQualification(userId: currentUserId, eventId: eventId)
    }
    
    private func checkUserForEventQualification(userId: String, eventId: String) {
        // Get user's workout history (in real app, this would come from HealthKit service)
        getWorkoutHistory(for: userId) { [weak self] workouts in
            let result = self?.checkUserQualification(
                userId: userId,
                eventId: eventId,
                workoutHistory: workouts
            )
            
            switch result {
            case .qualified(let qualifyingWorkouts):
                print("🎯 AutoEntry: User \(userId) qualified for event \(eventId) with \(qualifyingWorkouts.count) qualifying workouts")
                
            case .notQualified(let reason):
                print("🎯 AutoEntry: User \(userId) not qualified for event \(eventId): \(reason)")
                
            case .alreadyEntered:
                print("🎯 AutoEntry: User \(userId) already entered in event \(eventId)")
                
            case .none:
                break
            }
        }
    }
    
    // MARK: - Data Access
    
    private func getWorkoutHistory(for userId: String, completion: @escaping ([HealthKitWorkout]) -> Void) {
        // In a real implementation, this would fetch from HealthKitManager
        // For now, return empty array
        completion([])
    }
    
    func getUserEntries(for userId: String) -> [UserEventEntry] {
        return userEntries.values.filter { $0.userId == userId }
    }
    
    func getEventEntries(for eventId: String) -> [UserEventEntry] {
        return userEntries.values.filter { $0.eventId == eventId }
    }
    
    func updateEntryStatus(userId: String, eventId: String, status: EntryStatus) {
        let userKey = "\(userId)_\(eventId)"
        if var entry = userEntries[userKey] {
            entry = UserEventEntry(
                userId: entry.userId,
                eventId: entry.eventId,
                qualificationDate: entry.qualificationDate,
                qualifyingWorkouts: entry.qualifyingWorkouts,
                autoEntered: entry.autoEntered,
                entryStatus: status
            )
            userEntries[userKey] = entry
            print("🎯 AutoEntry: Updated entry status for \(userId) in \(eventId): \(status)")
        }
    }
    
    // MARK: - Notifications
    
    private func sendQualificationNotification(userId: String, eventId: String, workouts: [HealthKitWorkout]) {
        let notification = Notification(
            name: NSNotification.Name("UserQualifiedForEvent"),
            object: nil,
            userInfo: [
                "userId": userId,
                "eventId": eventId,
                "qualifyingWorkouts": workouts.map { $0.id }
            ]
        )
        
        notificationCenter.post(notification)
        print("🎯 AutoEntry: Posted qualification notification for user \(userId) in event \(eventId)")
    }
    
    // MARK: - Statistics
    
    func getQualificationStats() -> (totalEvents: Int, totalEntries: Int, autoEntries: Int) {
        let totalEvents = qualificationCriteria.count
        let totalEntries = userEntries.count
        let autoEntries = userEntries.values.filter { $0.autoEntered }.count
        
        return (totalEvents, totalEntries, autoEntries)
    }
}

// MARK: - HealthKitWorkout Extension

extension HealthKitWorkout {
    var isQualifiedFor: (EventQualificationCriteria) -> Bool {
        return { criteria in
            // Check distance requirement
            if let minDistance = criteria.minDistance, self.totalDistance < minDistance {
                return false
            }
            
            // Check duration requirement
            if let minDuration = criteria.minDuration, self.duration < minDuration {
                return false
            }
            
            // Check calories requirement
            if let minCalories = criteria.minCalories, self.totalEnergyBurned < minCalories {
                return false
            }
            
            // Check workout type requirement
            if let requiredTypes = criteria.requiredWorkoutTypes {
                if !requiredTypes.contains(self.workoutType) {
                    return false
                }
            }
            
            return true
        }
    }
}