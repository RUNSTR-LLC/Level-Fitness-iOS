import Foundation
import BackgroundTasks
import HealthKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    // Background task identifiers (must match Info.plist)
    private let workoutSyncTaskId = "com.runstr.rewards.workout-sync"
    private let rewardCheckTaskId = "com.runstr.rewards.reward-check"
    private let notificationUpdateTaskId = "com.runstr.rewards.notification-update"
    
    private let healthKitService = HealthKitService.shared
    private let supabaseService = SupabaseService.shared
    private let lightningWalletManager = LightningWalletManager.shared
    private let notificationService = NotificationService.shared
    private let eventCriteriaEngine = EventCriteriaEngine.shared
    private let leaderboardTracker = LeaderboardTracker.shared
    private let notificationIntelligence = NotificationIntelligence.shared
    
    private var lastSyncDate: Date {
        get {
            UserDefaults.standard.object(forKey: "lastWorkoutSyncDate") as? Date ?? Date().addingTimeInterval(-86400)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "lastWorkoutSyncDate")
        }
    }
    
    private init() {}
    
    // MARK: - Setup
    
    func setupBackgroundTasks() {
        // Register background tasks
        registerWorkoutSyncTask()
        registerRewardCheckTask()
        registerNotificationUpdateTask()
        
        // Schedule initial tasks
        scheduleWorkoutSync()
        scheduleRewardCheck()
        scheduleNotificationUpdate()
        
        Task {
            await eventCriteriaEngine.initialize()
        }
        
        print("BackgroundTaskManager: Background tasks registered and scheduled")
    }
    
    // MARK: - Task Registration
    
    private func registerWorkoutSyncTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: workoutSyncTaskId,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGProcessingTask else { return }
            self?.handleWorkoutSyncTask(task)
        }
    }
    
    private func registerRewardCheckTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: rewardCheckTaskId,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleRewardCheckTask(task)
        }
    }
    
    private func registerNotificationUpdateTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: notificationUpdateTaskId,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleNotificationUpdateTask(task)
        }
    }
    
    // MARK: - Task Scheduling
    
    func scheduleWorkoutSync() {
        let request = BGProcessingTaskRequest(identifier: workoutSyncTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        // Schedule to run every 2 hours
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 3600)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundTaskManager: Workout sync scheduled")
        } catch {
            print("BackgroundTaskManager: Failed to schedule workout sync: \(error)")
        }
    }
    
    func scheduleRewardCheck() {
        let request = BGAppRefreshTaskRequest(identifier: rewardCheckTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundTaskManager: Reward check scheduled")
        } catch {
            print("BackgroundTaskManager: Failed to schedule reward check: \(error)")
        }
    }
    
    func scheduleNotificationUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: notificationUpdateTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 3600) // 4 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("BackgroundTaskManager: Notification update scheduled")
        } catch {
            print("BackgroundTaskManager: Failed to schedule notification update: \(error)")
        }
    }
    
    // MARK: - Task Handlers
    
    private func handleWorkoutSyncTask(_ task: BGProcessingTask) {
        // Schedule next sync
        scheduleWorkoutSync()
        
        // Set up expiration handler
        task.expirationHandler = {
            print("BackgroundTaskManager: Workout sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform workout sync
        Task {
            let success = await performWorkoutSync()
            task.setTaskCompleted(success: success)
        }
    }
    
    private func handleRewardCheckTask(_ task: BGAppRefreshTask) {
        // Schedule next check
        scheduleRewardCheck()
        
        task.expirationHandler = {
            print("BackgroundTaskManager: Reward check task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            let success = await checkAndDistributeRewards()
            task.setTaskCompleted(success: success)
        }
    }
    
    private func handleNotificationUpdateTask(_ task: BGAppRefreshTask) {
        // Schedule next update
        scheduleNotificationUpdate()
        
        task.expirationHandler = {
            print("BackgroundTaskManager: Notification update task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            let success = await updateNotifications()
            task.setTaskCompleted(success: success)
        }
    }
    
    // MARK: - Background Operations
    
    @MainActor
    private func performWorkoutSync() async -> Bool {
        print("BackgroundTaskManager: Starting workout sync")
        
        do {
            // Check HealthKit authorization
            guard healthKitService.checkAuthorizationStatus() else {
                print("BackgroundTaskManager: HealthKit not authorized")
                return false
            }
            
            // Fetch workouts since last sync
            let rawWorkouts = try await healthKitService.fetchWorkoutsSince(lastSyncDate, limit: 50)
            print("BackgroundTaskManager: Found \(rawWorkouts.count) raw workouts")
            
            // Apply duplicate detection
            let deduplicatedWorkouts = healthKitService.detectDuplicates(in: rawWorkouts)
            print("BackgroundTaskManager: After deduplication: \(deduplicatedWorkouts.count) workouts")
            
            guard !deduplicatedWorkouts.isEmpty else {
                lastSyncDate = Date()
                return true
            }
            
            // Get current user ID
            guard let userId = AuthenticationService.shared.currentUserId else {
                print("BackgroundTaskManager: No user logged in")
                return false
            }
            
            // Check for cross-platform duplicates against existing Supabase workouts
            let existingWorkouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 100)
            let workouts = healthKitService.detectCrossPlatformDuplicates(deduplicatedWorkouts, existingWorkouts)
            print("BackgroundTaskManager: After cross-platform deduplication: \(workouts.count) workouts")
            
            guard !workouts.isEmpty else {
                lastSyncDate = Date()
                return true
            }
            
            // Process and sync each workout
            var syncedCount = 0
            for workout in workouts {
                do {
                    // Convert to Supabase format
                    let supabaseWorkout = healthKitService.convertToSupabaseWorkout(workout, userId: userId)
                    
                    // Sync to Supabase
                    try await supabaseService.syncWorkout(supabaseWorkout)
                    syncedCount += 1
                    
                    // Process workout for event matching
                    await eventCriteriaEngine.processWorkoutForEvents(workout, userId: userId)
                    
                    // Calculate and distribute rewards
                    let points = calculateWorkoutPoints(workout)
                    if points > 0 {
                        try await lightningWalletManager.distributeWorkoutReward(
                            userId: userId,
                            workoutType: workout.workoutType,
                            points: points
                        )
                        
                        // Send reward notification with intelligent filtering
                        let rewardAmount = points * 10 // 10 sats per point
                        if let candidate = notificationIntelligence.createWorkoutRewardNotification(
                            amount: rewardAmount,
                            workoutType: workout.workoutType,
                            userId: userId
                        ) {
                            if notificationIntelligence.shouldSendNotification(candidate, userId: userId) {
                                notificationService.scheduleWorkoutRewardNotification(
                                    amount: rewardAmount,
                                    workoutType: workout.workoutType
                                )
                            }
                        } else {
                            // Fallback to basic notification
                            notificationService.scheduleWorkoutRewardNotification(
                                amount: rewardAmount,
                                workoutType: workout.workoutType
                            )
                        }
                    }
                    
                } catch {
                    print("BackgroundTaskManager: Failed to sync workout \(workout.id): \(error)")
                }
            }
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(Date(), forKey: "lastWorkoutSyncDate")
            
            print("BackgroundTaskManager: Synced \(syncedCount)/\(workouts.count) workouts")
            
            // Track leaderboard position changes
            if syncedCount > 0 {
                let positionChanges = await leaderboardTracker.trackUserPositions(userId: userId)
                await leaderboardTracker.processPositionChanges(positionChanges)
                print("BackgroundTaskManager: Processed \(positionChanges.count) leaderboard position changes")
            }
            
            // Update badge with any new notifications
            await MainActor.run {
                if syncedCount > 0 {
                    NotificationService.shared.updateBadgeCount(syncedCount)
                }
            }
            
            return syncedCount > 0
            
        } catch {
            print("BackgroundTaskManager: Workout sync failed: \(error)")
            return false
        }
    }
    
    private func checkAndDistributeRewards() async -> Bool {
        print("BackgroundTaskManager: Checking for pending rewards")
        
        do {
            guard let userId = AuthenticationService.shared.currentUserId else {
                return false
            }
            
            // Check for completed challenges
            let challenges = try await supabaseService.fetchChallenges()
            var rewardsDistributed = 0
            
            for challenge in challenges {
                // Check if user completed challenge
                // This would involve checking challenge_participants table
                // For now, we'll simulate the check
                print("BackgroundTaskManager: Checking challenge \(challenge.id)")
            }
            
            // Check weekly leaderboard rewards
            let leaderboard = try await supabaseService.fetchWeeklyLeaderboard()
            if let userEntry = leaderboard.first(where: { $0.userId == userId }) {
                if userEntry.rank <= 10 {
                    // Top 10 get bonus rewards
                    let bonusAmount = (11 - userEntry.rank) * 100 // More sats for higher rank
                    
                    try await lightningWalletManager.distributeWorkoutReward(
                        userId: userId,
                        workoutType: "leaderboard_bonus",
                        points: bonusAmount / 10
                    )
                    
                    rewardsDistributed += 1
                    print("BackgroundTaskManager: Distributed leaderboard bonus: \(bonusAmount) sats")
                }
            }
            
            return rewardsDistributed > 0
            
        } catch {
            print("BackgroundTaskManager: Reward check failed: \(error)")
            return false
        }
    }
    
    private func updateNotifications() async -> Bool {
        print("BackgroundTaskManager: Updating notifications")
        
        do {
            guard let userId = AuthenticationService.shared.currentUserId else {
                return false
            }
            
            // Check for upcoming events
            let events = try await supabaseService.fetchEvents(status: "upcoming")
            for event in events {
                let startDate = event.startDate
                let reminderDate = startDate.addingTimeInterval(-3600) // 1 hour before
                
                if reminderDate > Date() && reminderDate < Date().addingTimeInterval(86400) {
                    // Event starts within next 24 hours
                    notificationService.scheduleEventReminder(
                        eventName: event.name,
                        eventId: event.id,
                        reminderDate: reminderDate
                    )
                }
            }
            
            // Check streak status
            // This would check user_streaks table
            // For now, simulate streak check
            let currentStreak = 5 // Simulated
            let lastWorkoutDate = Date().addingTimeInterval(-86400) // Yesterday
            
            if Calendar.current.isDateInToday(lastWorkoutDate) == false {
                // User hasn't worked out today
                notificationService.scheduleStreakReminder(currentStreak: currentStreak)
            }
            
            // Schedule weekly summary for Sunday
            if Calendar.current.component(.weekday, from: Date()) == 7 {
                // It's Saturday, schedule summary for tomorrow
                let workouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 100)
                let weeklyWorkouts = workouts.filter { workout in
                    workout.startedAt >= Date().addingTimeInterval(-7 * 86400)
                }.count
                
                let transactions = try await supabaseService.fetchTransactions(userId: userId, limit: 100)
                let weeklyEarnings = transactions
                    .filter { $0.createdAt >= Date().addingTimeInterval(-7 * 86400) }
                    .reduce(0) { $0 + $1.amount }
                
                let leaderboard = try await supabaseService.fetchWeeklyLeaderboard()
                let rank = leaderboard.firstIndex(where: { $0.userId == userId }) ?? 999
                
                notificationService.scheduleWeeklySummary(
                    workouts: weeklyWorkouts,
                    earnings: weeklyEarnings,
                    rank: rank + 1
                )
            }
            
            return true
            
        } catch {
            print("BackgroundTaskManager: Notification update failed: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateWorkoutPoints(_ workout: HealthKitWorkout) -> Int {
        var points = 0
        
        // Base points for workout completion
        points += 10
        
        // Duration bonus (1 point per 5 minutes)
        let minutes = Int(workout.duration / 60)
        points += minutes / 5
        
        // Distance bonus (1 point per km for running/cycling)
        if workout.workoutType == "running" || workout.workoutType == "cycling" {
            let kilometers = workout.totalDistance / 1000
            points += Int(kilometers)
        }
        
        // Calorie bonus (1 point per 50 calories)
        let calories = Int(workout.totalEnergyBurned)
        points += calories / 50
        
        // Workout type multipliers
        switch workout.workoutType {
        case "hiit":
            points = Int(Double(points) * 1.5) // HIIT gets 50% bonus
        case "strength_training":
            points = Int(Double(points) * 1.3) // Strength gets 30% bonus
        case "running":
            points = Int(Double(points) * 1.2) // Running gets 20% bonus
        default:
            break
        }
        
        // Cap at 100 points per workout to prevent abuse
        return min(points, 100)
    }
    
    // MARK: - Manual Triggers (for testing)
    
    func triggerWorkoutSync() {
        Task {
            let success = await performWorkoutSync()
            print("BackgroundTaskManager: Manual workout sync completed: \(success)")
        }
    }
    
    func triggerRewardCheck() {
        Task {
            let success = await checkAndDistributeRewards()
            print("BackgroundTaskManager: Manual reward check completed: \(success)")
        }
    }
    
    func triggerNotificationUpdate() {
        Task {
            let success = await updateNotifications()
            print("BackgroundTaskManager: Manual notification update completed: \(success)")
        }
    }
}