import Foundation
import HealthKit

// MARK: - Progress Models

struct EventProgress {
    let eventId: String
    let userId: String
    let currentValue: Double        // Distance, calories, or duration
    let targetValue: Double         // Target to achieve
    let progressPercentage: Double  // 0.0 to 1.0
    let rank: Int                   // Current leaderboard position
    let totalParticipants: Int      // Total participants
    let lastUpdated: Date
    let recentWorkouts: [ProgressWorkout]
    let isComplete: Bool
}

struct ProgressWorkout {
    let workoutId: String
    let date: Date
    let value: Double               // Distance, calories, or duration contributed
    let workoutType: String
    let points: Int                 // Points earned for this workout
}

struct EventLeaderboardEntry {
    let userId: String
    let username: String
    let totalValue: Double
    let rank: Int
    let points: Int
    let lastActivity: Date
    let isCurrentUser: Bool
    let badgeCount: Int
}

struct EventMetrics {
    let eventId: String
    let totalDistance: Double
    let totalWorkouts: Int
    let averageValue: Double
    let topPerformer: EventLeaderboardEntry?
    let participationRate: Double
    let completionRate: Double
}

enum ProgressUpdateType {
    case newWorkout
    case rankChange
    case goalAchieved
    case eventComplete
}

// MARK: - EventProgressTracker

class EventProgressTracker {
    static let shared = EventProgressTracker()
    
    private var eventProgress: [String: EventProgress] = [:]
    private var leaderboards: [String: [EventLeaderboardEntry]] = [:]
    private var eventMetrics: [String: EventMetrics] = [:]
    private let notificationCenter = NotificationCenter.default
    private var updateTimer: Timer?
    
    private init() {
        startProgressUpdates()
        observeWorkoutChanges()
    }
    
    // MARK: - Setup
    
    private func startProgressUpdates() {
        // Update progress every 30 seconds during active events
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateActiveEventProgress()
        }
    }
    
    private func observeWorkoutChanges() {
        notificationCenter.addObserver(
            self,
            selector: #selector(workoutAdded),
            name: NSNotification.Name("WorkoutAdded"),
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(workoutSyncCompleted),
            name: NSNotification.Name("WorkoutSyncCompleted"),
            object: nil
        )
    }
    
    // MARK: - Event Registration
    
    func startTracking(event: EventData, participants: [String]) {
        print("📊 Progress: Starting tracking for event '\(event.name)' with \(participants.count) participants")
        
        // Initialize progress for all participants
        for userId in participants {
            let progress = EventProgress(
                eventId: event.id,
                userId: userId,
                currentValue: 0.0,
                targetValue: getTargetValue(for: event),
                progressPercentage: 0.0,
                rank: participants.count, // Start at bottom
                totalParticipants: participants.count,
                lastUpdated: Date(),
                recentWorkouts: [],
                isComplete: false
            )
            
            eventProgress["\(event.id)_\(userId)"] = progress
        }
        
        // Initialize empty leaderboard
        leaderboards[event.id] = participants.enumerated().map { index, userId in
            EventLeaderboardEntry(
                userId: userId,
                username: getUserDisplayName(userId: userId),
                totalValue: 0.0,
                rank: index + 1,
                points: 0,
                lastActivity: Date(),
                isCurrentUser: userId == getCurrentUserId(),
                badgeCount: 0
            )
        }
        
        // Initialize metrics
        eventMetrics[event.id] = EventMetrics(
            eventId: event.id,
            totalDistance: 0.0,
            totalWorkouts: 0,
            averageValue: 0.0,
            topPerformer: nil,
            participationRate: 0.0,
            completionRate: 0.0
        )
        
        // Initial update
        updateEventLeaderboard(eventId: event.id)
    }
    
    func stopTracking(eventId: String) {
        // Remove progress tracking for this event
        eventProgress = eventProgress.filter { !$0.key.hasPrefix("\(eventId)_") }
        leaderboards.removeValue(forKey: eventId)
        eventMetrics.removeValue(forKey: eventId)
        
        print("📊 Progress: Stopped tracking for event: \(eventId)")
    }
    
    // MARK: - Progress Updates
    
    func updateUserProgress(eventId: String, userId: String, newWorkout: HealthKitWorkout) {
        let progressKey = "\(eventId)_\(userId)"
        guard let progress = eventProgress[progressKey] else {
            print("📊 Progress: No progress tracking found for user \(userId) in event \(eventId)")
            return
        }
        
        // Convert workout to progress value based on event type
        let workoutValue = getWorkoutValue(workout: newWorkout, eventId: eventId)
        let points = calculatePoints(for: newWorkout, in: eventId)
        
        // Create progress workout entry
        let progressWorkout = ProgressWorkout(
            workoutId: newWorkout.id,
            date: newWorkout.startDate,
            value: workoutValue,
            workoutType: newWorkout.workoutType,
            points: points
        )
        
        // Update progress
        let newCurrentValue = progress.currentValue + workoutValue
        let newProgressPercentage = min(newCurrentValue / progress.targetValue, 1.0)
        let isComplete = newProgressPercentage >= 1.0
        
        var recentWorkouts = progress.recentWorkouts
        recentWorkouts.append(progressWorkout)
        
        // Keep only the last 10 workouts
        if recentWorkouts.count > 10 {
            recentWorkouts = Array(recentWorkouts.suffix(10))
        }
        
        // Update progress object
        let updatedProgress = EventProgress(
            eventId: eventId,
            userId: userId,
            currentValue: newCurrentValue,
            targetValue: progress.targetValue,
            progressPercentage: newProgressPercentage,
            rank: progress.rank, // Will be updated in leaderboard update
            totalParticipants: progress.totalParticipants,
            lastUpdated: Date(),
            recentWorkouts: recentWorkouts,
            isComplete: isComplete
        )
        
        eventProgress[progressKey] = updatedProgress
        
        // Update leaderboard and rankings
        updateEventLeaderboard(eventId: eventId)
        
        // Send progress notifications
        sendProgressUpdate(
            eventId: eventId,
            userId: userId,
            type: .newWorkout,
            progress: updatedProgress
        )
        
        if isComplete && !progress.isComplete {
            sendProgressUpdate(
                eventId: eventId,
                userId: userId,
                type: .goalAchieved,
                progress: updatedProgress
            )
        }
        
        print("📊 Progress: Updated progress for user \(userId) in event \(eventId): \(String(format: "%.1f", newProgressPercentage * 100))%")
    }
    
    private func updateEventLeaderboard(eventId: String) {
        // Get all progress entries for this event
        let eventProgressEntries = eventProgress.filter { $0.key.hasPrefix("\(eventId)_") }
        
        // Sort by current value (descending)
        let sortedEntries = eventProgressEntries.sorted { $0.value.currentValue > $1.value.currentValue }
        
        // Update leaderboard entries
        var updatedLeaderboard: [EventLeaderboardEntry] = []
        var updatedProgress: [String: EventProgress] = [:]
        
        for (index, (progressKey, progress)) in sortedEntries.enumerated() {
            let rank = index + 1
            let totalPoints = progress.recentWorkouts.reduce(0) { $0 + $1.points }
            
            // Update leaderboard entry
            let leaderboardEntry = EventLeaderboardEntry(
                userId: progress.userId,
                username: getUserDisplayName(userId: progress.userId),
                totalValue: progress.currentValue,
                rank: rank,
                points: totalPoints,
                lastActivity: progress.lastUpdated,
                isCurrentUser: progress.userId == getCurrentUserId(),
                badgeCount: getBadgeCount(for: progress.userId)
            )
            updatedLeaderboard.append(leaderboardEntry)
            
            // Update progress with new rank
            if progress.rank != rank {
                let updatedProgressEntry = EventProgress(
                    eventId: progress.eventId,
                    userId: progress.userId,
                    currentValue: progress.currentValue,
                    targetValue: progress.targetValue,
                    progressPercentage: progress.progressPercentage,
                    rank: rank,
                    totalParticipants: progress.totalParticipants,
                    lastUpdated: progress.lastUpdated,
                    recentWorkouts: progress.recentWorkouts,
                    isComplete: progress.isComplete
                )
                updatedProgress[progressKey] = updatedProgressEntry
                
                // Send rank change notification
                sendProgressUpdate(
                    eventId: eventId,
                    userId: progress.userId,
                    type: .rankChange,
                    progress: updatedProgressEntry
                )
            }
        }
        
        // Update stored data
        leaderboards[eventId] = updatedLeaderboard
        for (key, progress) in updatedProgress {
            eventProgress[key] = progress
        }
        
        // Update event metrics
        updateEventMetrics(eventId: eventId)
        
        print("📊 Progress: Updated leaderboard for event \(eventId) with \(updatedLeaderboard.count) entries")
    }
    
    private func updateEventMetrics(eventId: String) {
        let eventProgressEntries = eventProgress.filter { $0.key.hasPrefix("\(eventId)_") }
        let leaderboard = leaderboards[eventId] ?? []
        
        let totalDistance = eventProgressEntries.values.reduce(0) { $0 + $1.currentValue }
        let totalWorkouts = eventProgressEntries.values.reduce(0) { $0 + $1.recentWorkouts.count }
        let averageValue = totalDistance / Double(eventProgressEntries.count)
        let topPerformer = leaderboard.first
        let participationRate = Double(eventProgressEntries.values.filter { !$0.recentWorkouts.isEmpty }.count) / Double(eventProgressEntries.count)
        let completionRate = Double(eventProgressEntries.values.filter { $0.isComplete }.count) / Double(eventProgressEntries.count)
        
        let metrics = EventMetrics(
            eventId: eventId,
            totalDistance: totalDistance,
            totalWorkouts: totalWorkouts,
            averageValue: averageValue,
            topPerformer: topPerformer,
            participationRate: participationRate,
            completionRate: completionRate
        )
        
        eventMetrics[eventId] = metrics
    }
    
    // MARK: - Background Updates
    
    @objc private func workoutAdded(_ notification: Notification) {
        guard let userId = notification.userInfo?["userId"] as? String else {
            return
        }
        
        // Check for HealthKitWorkout first (from HealthKit observer)
        if let healthKitWorkout = notification.userInfo?["workout"] as? HealthKitWorkout {
            processWorkoutForEvents(healthKitWorkout, userId: userId)
        }
        // Check for Workout (from WorkoutSyncQueue)
        else if let workout = notification.userInfo?["workout"] as? Workout {
            let healthKitWorkout = convertWorkoutToHealthKitWorkout(workout)
            processWorkoutForEvents(healthKitWorkout, userId: userId)
        }
        else {
            print("EventProgressTracker: ⚠️ WorkoutAdded notification missing expected workout object")
            return
        }
    }
    
    private func processWorkoutForEvents(_ workout: HealthKitWorkout, userId: String) {
        // Update progress for all events this user is participating in
        let userEventKeys = eventProgress.keys.filter { $0.hasSuffix("_\(userId)") }
        
        for key in userEventKeys {
            let eventId = String(key.dropLast("_\(userId)".count))
            updateUserProgress(eventId: eventId, userId: userId, newWorkout: workout)
        }
    }
    
    private func convertWorkoutToHealthKitWorkout(_ workout: Workout) -> HealthKitWorkout {
        let activityType = getHKWorkoutActivityType(from: workout.type)
        let endDate = workout.endedAt ?? workout.startedAt.addingTimeInterval(TimeInterval(workout.duration))
        
        return HealthKitWorkout(
            id: workout.id,
            activityType: activityType,
            startDate: workout.startedAt,
            endDate: endDate,
            duration: TimeInterval(workout.duration),
            totalDistance: workout.distance,
            totalEnergyBurned: workout.calories != nil ? Double(workout.calories!) : nil,
            syncSource: .healthKit, // Default sync source
            metadata: nil
        )
    }
    
    private func getHKWorkoutActivityType(from typeString: String) -> HKWorkoutActivityType {
        switch typeString.lowercased() {
        case "running", "run":
            return .running
        case "cycling", "bike", "biking":
            return .cycling
        case "swimming", "swim":
            return .swimming
        case "walking", "walk":
            return .walking
        case "yoga":
            return .yoga
        case "hiit", "high intensity":
            return .highIntensityIntervalTraining
        case "strength", "weights":
            return .traditionalStrengthTraining
        case "core":
            return .coreTraining
        case "functional":
            return .functionalStrengthTraining
        default:
            return .other
        }
    }
    
    @objc private func workoutSyncCompleted() {
        updateActiveEventProgress()
    }
    
    private func updateActiveEventProgress() {
        // Update progress for all active events
        let activeEventIds = Set(eventProgress.keys.compactMap { key in
            let components = key.components(separatedBy: "_")
            return components.count >= 2 ? components[0] : nil
        })
        
        for eventId in activeEventIds {
            updateEventLeaderboard(eventId: eventId)
        }
    }
    
    // MARK: - Data Access
    
    func getProgress(eventId: String, userId: String) -> EventProgress? {
        return eventProgress["\(eventId)_\(userId)"]
    }
    
    func getLeaderboard(eventId: String) -> [EventLeaderboardEntry] {
        return leaderboards[eventId] ?? []
    }
    
    func getEventMetrics(eventId: String) -> EventMetrics? {
        return eventMetrics[eventId]
    }
    
    func getUserRank(eventId: String, userId: String) -> Int? {
        return getProgress(eventId: eventId, userId: userId)?.rank
    }
    
    // MARK: - Event Completion
    
    func completeEvent(eventId: String, eventName: String, teamId: String, prizePool: Int = 0) {
        print("📊 EventProgressTracker: Completing event \(eventName)")
        
        guard let leaderboard = leaderboards[eventId], !leaderboard.isEmpty else {
            print("📊 EventProgressTracker: No participants found for event \(eventId)")
            return
        }
        
        // Create payment for top performers (top 3)
        let topPerformers = Array(leaderboard.prefix(3))
        let winners: [(userId: String, username: String, position: Int, amount: Int)] = topPerformers.enumerated().compactMap { index, entry in
            let position = index + 1
            let amount = calculatePrizeAmount(for: position, totalPrize: prizePool)
            
            guard amount > 0 else { return nil }
            
            return (entry.userId, entry.username, position, amount)
        }
        
        if !winners.isEmpty && prizePool > 0 {
            let payment = PendingPayment.forEvent(
                teamId: teamId,
                eventName: eventName,
                eventId: eventId,
                endDate: Date(),
                winners: winners
            )
            
            PaymentQueueManager.shared.addPendingPayment(payment)
            print("📊 EventProgressTracker: Created payment for \(winners.count) winners, total: \(prizePool) sats")
        }
        
        // Send completion notification
        sendEventCompletionNotification(eventId: eventId, eventName: eventName, leaderboard: leaderboard)
        
        // Clean up tracking data (optional - keep for history)
        // eventProgress.removeAll { $0.key.hasPrefix("\(eventId)_") }
        // leaderboards.removeValue(forKey: eventId)
        // eventMetrics.removeValue(forKey: eventId)
    }
    
    private func calculatePrizeAmount(for position: Int, totalPrize: Int) -> Int {
        guard totalPrize > 0 else { return 0 }
        
        switch position {
        case 1: return Int(Double(totalPrize) * 0.5)  // 50% for 1st place
        case 2: return Int(Double(totalPrize) * 0.3)  // 30% for 2nd place
        case 3: return Int(Double(totalPrize) * 0.2)  // 20% for 3rd place
        default: return 0
        }
    }
    
    private func sendEventCompletionNotification(eventId: String, eventName: String, leaderboard: [EventLeaderboardEntry]) {
        let notification = Notification(
            name: NSNotification.Name("EventCompleted"),
            object: nil,
            userInfo: [
                "eventId": eventId,
                "eventName": eventName,
                "leaderboard": leaderboard,
                "timestamp": Date()
            ]
        )
        
        notificationCenter.post(notification)
        print("📊 EventProgressTracker: Posted event completion notification for \(eventName)")
    }
    
    // MARK: - Helper Methods
    
    private func getTargetValue(for event: EventData) -> Double {
        // In a real implementation, this would be based on event configuration
        switch event.type {
        case .marathon:
            return 42195.0 // Full marathon distance in meters
        case .sprint:
            return 5000.0  // 5km sprint
        case .challenge:
            return 100000.0 // 100km challenge
        default:
            return 10000.0 // Default 10km
        }
    }
    
    private func getWorkoutValue(workout: HealthKitWorkout, eventId: String) -> Double {
        // For distance-based events, return distance in meters
        // For time-based events, return duration in seconds
        // For calorie-based events, return calories burned
        
        // Default to distance for now
        return workout.totalDistance ?? 0.0
    }
    
    private func calculatePoints(for workout: HealthKitWorkout, in eventId: String) -> Int {
        // Base points calculation
        var points = 100 // Base points for completing a workout
        
        // Distance bonus (1 point per 100m)
        points += Int((workout.totalDistance ?? 0.0) / 100)
        
        // Duration bonus (1 point per minute)
        points += Int(workout.duration / 60)
        
        // Calories bonus (1 point per 10 calories)
        points += Int((workout.totalEnergyBurned ?? 0.0) / 10)
        
        return points
    }
    
    private func getCurrentUserId() -> String {
        // In a real implementation, this would come from authentication
        return "current_user"
    }
    
    private func getUserDisplayName(userId: String) -> String {
        // In a real implementation, this would fetch from user service
        return "User \(userId.prefix(8))"
    }
    
    private func getBadgeCount(for userId: String) -> Int {
        // In a real implementation, this would fetch user's badge count
        return Int.random(in: 0...5)
    }
    
    // MARK: - Notifications
    
    private func sendProgressUpdate(eventId: String, userId: String, type: ProgressUpdateType, progress: EventProgress) {
        let notification = Notification(
            name: NSNotification.Name("EventProgressUpdated"),
            object: nil,
            userInfo: [
                "eventId": eventId,
                "userId": userId,
                "updateType": type,
                "progress": progress
            ]
        )
        
        notificationCenter.post(notification)
        
        // Send push notification for significant updates
        if userId == getCurrentUserId() {
            switch type {
            case .rankChange:
                sendPushNotification(
                    title: "Rank Update",
                    body: "You're now ranked #\(progress.rank) in the event!",
                    eventId: eventId
                )
            case .goalAchieved:
                sendPushNotification(
                    title: "Goal Achieved! 🏆",
                    body: "Congratulations! You've completed the event challenge!",
                    eventId: eventId
                )
            default:
                break
            }
        }
    }
    
    private func sendPushNotification(title: String, body: String, eventId: String) {
        // In a real implementation, this would send a push notification
        print("📊 Push: \(title) - \(body)")
    }
    
    deinit {
        updateTimer?.invalidate()
        notificationCenter.removeObserver(self)
    }
}