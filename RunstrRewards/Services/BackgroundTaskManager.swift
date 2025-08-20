import Foundation
import BackgroundTasks
import HealthKit

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    // Background task identifiers (must match Info.plist)
    private let workoutSyncTaskId = "com.runstr.rewards.workout-sync"
    private let rewardCheckTaskId = "com.runstr.rewards.reward-check"
    private let notificationUpdateTaskId = "com.runstr.rewards.notification-update"
    
    // Background task time management
    private var currentTask: BGTask?
    private let maxBackgroundTime: TimeInterval = 25 // 25 seconds for safety (iOS gives ~30)
    private let emergencyThreshold: TimeInterval = 20 // Start winding down at 20 seconds
    private var taskStartTime: Date?
    private var isTaskExpiring = false
    
    private let healthKitService = HealthKitService.shared
    private let supabaseService = SupabaseService.shared
    private let lightningWalletManager = LightningWalletManager.shared
    private let notificationService = NotificationService.shared
    private let eventCriteriaEngine = EventCriteriaEngine.shared
    private let leaderboardTracker = LeaderboardTracker.shared
    private let notificationIntelligence = NotificationIntelligence.shared
    private let workoutRewardCalculator = WorkoutRewardCalculator.shared
    private let streakTracker = StreakTracker.shared
    // Note: WorkoutSyncQueue.shared accessed directly in methods to avoid compilation order issues
    
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
    
    func registerBackgroundTasks() {
        // Register background tasks (must be called before app finishes launching)
        registerWorkoutSyncTask()
        registerRewardCheckTask()
        registerNotificationUpdateTask()
        
        print("BackgroundTaskManager: Background tasks registered")
    }
    
    func scheduleAllBackgroundTasks() {
        // Schedule initial tasks (can be called after authentication)
        scheduleWorkoutSync()
        scheduleRewardCheck()
        scheduleNotificationUpdate()
        
        Task {
            await eventCriteriaEngine.initialize()
        }
        
        print("BackgroundTaskManager: Background tasks scheduled")
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
        
        // Store task reference and start time
        currentTask = task
        taskStartTime = Date()
        isTaskExpiring = false
        
        // Set up expiration handler with graceful shutdown
        task.expirationHandler = {
            print("⚠️ BackgroundTaskManager: Workout sync task about to expire - initiating graceful shutdown")
            self.isTaskExpiring = true
            self.saveBackgroundTaskState()
            task.setTaskCompleted(success: true) // Mark as successful to preserve progress
        }
        
        // Perform workout sync with time monitoring
        Task {
            let success = await performWorkoutSyncWithTimeManagement()
            if !self.isTaskExpiring {
                task.setTaskCompleted(success: success)
            }
        }
    }
    
    private func handleRewardCheckTask(_ task: BGAppRefreshTask) {
        // Schedule next check
        scheduleRewardCheck()
        
        // Store task reference and start time
        currentTask = task
        taskStartTime = Date()
        isTaskExpiring = false
        
        task.expirationHandler = {
            print("⚠️ BackgroundTaskManager: Reward check task about to expire - saving state")
            self.isTaskExpiring = true
            self.saveBackgroundTaskState()
            task.setTaskCompleted(success: true)
        }
        
        Task {
            let success = await checkAndDistributeRewardsWithTimeManagement()
            if !self.isTaskExpiring {
                task.setTaskCompleted(success: success)
            }
        }
    }
    
    private func handleNotificationUpdateTask(_ task: BGAppRefreshTask) {
        // Schedule next update
        scheduleNotificationUpdate()
        
        // Store task reference and start time
        currentTask = task
        taskStartTime = Date()
        isTaskExpiring = false
        
        task.expirationHandler = {
            print("⚠️ BackgroundTaskManager: Notification update task about to expire")
            self.isTaskExpiring = true
            task.setTaskCompleted(success: true)
        }
        
        Task {
            let success = await updateNotificationsWithTimeManagement()
            if !self.isTaskExpiring {
                task.setTaskCompleted(success: success)
            }
        }
    }
    
    // MARK: - Background Time Management
    
    private func getRemainingBackgroundTime() -> TimeInterval {
        guard let startTime = taskStartTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return maxBackgroundTime - elapsed
    }
    
    private func shouldContinueOperation() -> Bool {
        guard let startTime = taskStartTime else { return true }
        let elapsed = Date().timeIntervalSince(startTime)
        return elapsed < emergencyThreshold && !isTaskExpiring
    }
    
    private func saveBackgroundTaskState() {
        // Save current progress for resumption in next background task
        let state = [
            "lastSyncDate": lastSyncDate.timeIntervalSince1970,
            "taskExpiredAt": Date().timeIntervalSince1970,
            "partialSync": true
        ] as [String: Any]
        
        UserDefaults.standard.set(state, forKey: "background_task_state")
        print("💾 BackgroundTaskManager: Saved task state for resumption")
    }
    
    private func loadBackgroundTaskState() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: "background_task_state")
    }
    
    private func clearBackgroundTaskState() {
        UserDefaults.standard.removeObject(forKey: "background_task_state")
    }
    
    // MARK: - Background Operations with Time Management
    
    @MainActor
    private func performWorkoutSyncWithTimeManagement() async -> Bool {
        print("⏱️ BackgroundTaskManager: Starting time-managed workout sync (\(Int(maxBackgroundTime))s limit)")
        
        // Check if we're resuming from a previous task
        if let savedState = loadBackgroundTaskState() {
            if let savedSyncTime = savedState["lastSyncDate"] as? TimeInterval {
                lastSyncDate = Date(timeIntervalSince1970: savedSyncTime)
                print("🔄 BackgroundTaskManager: Resuming sync from \(lastSyncDate)")
            }
        }
        
        // Use the existing queue system for better reliability
        let success = await performQueueBasedWorkoutSync()
        
        // Clear state if completed successfully
        if success && !isTaskExpiring {
            clearBackgroundTaskState()
        }
        
        return success
    }
    
    @MainActor
    private func performQueueBasedWorkoutSync() async -> Bool {
        print("⚡ BackgroundTaskManager: Starting queue-based workout sync")
        
        do {
            // Check HealthKit authorization
            guard healthKitService.checkAuthorizationStatus() else {
                print("BackgroundTaskManager: HealthKit not authorized")
                return false
            }
            
            // Check remaining time before expensive operations
            guard shouldContinueOperation() else {
                print("⏰ BackgroundTaskManager: Insufficient time remaining - deferring to next task")
                saveBackgroundTaskState()
                return true
            }
            
            // Fetch workouts since last sync (reduced limit for background)
            let limit = shouldContinueOperation() ? 20 : 5 // Smaller batches in background
            let rawWorkouts = try await healthKitService.fetchWorkoutsSince(lastSyncDate, limit: limit)
            print("BackgroundTaskManager: Found \(rawWorkouts.count) raw workouts (limit: \(limit))")
            
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
            
            // Cache team membership to avoid repeated API calls
            let userTeams = try await supabaseService.fetchUserTeams(userId: userId)
            let teamMultiplier = userTeams.isEmpty ? 1.0 : 1.25
            
            // Use WorkoutSyncQueue for reliable background processing
            if !workouts.isEmpty {
                print("📋 BackgroundTaskManager: Queuing \(workouts.count) workouts for sync")
                
                // Convert to Supabase format and queue for processing
                var queuedCount = 0
                for workout in workouts {
                    // Check time before each operation
                    guard shouldContinueOperation() else {
                        print("⏰ BackgroundTaskManager: Time limit approaching - queuing remaining workouts")
                        // Queue the remaining workouts for later processing
                        for remainingWorkout in workouts.dropFirst(queuedCount) {
                            let supabaseWorkout = healthKitService.convertToSupabaseWorkout(remainingWorkout, userId: userId)
                            WorkoutSyncQueue.shared.queueWorkout(supabaseWorkout)
                        }
                        break
                    }
                    
                    let supabaseWorkout = healthKitService.convertToSupabaseWorkout(workout, userId: userId)
                    
                    // Try quick sync first, fall back to queue
                    await WorkoutSyncQueue.shared.quickSync(workout: supabaseWorkout)
                    queuedCount += 1
                    
                    // For background mode, defer complex processing to foreground or next task
                    if shouldContinueOperation() {
                        // Only do lightweight processing in background
                        queueWorkoutForProcessing(supabaseWorkout, userId: userId, teamMultiplier: teamMultiplier)
                    } else {
                        // Queue for later processing
                        queueWorkoutForProcessing(supabaseWorkout, userId: userId, teamMultiplier: teamMultiplier)
                        break
                    }
                }
                
                print("📋 BackgroundTaskManager: Processed \(queuedCount)/\(workouts.count) workouts in background")
            }
            
            // Update last sync date if we completed successfully
            if shouldContinueOperation() {
                lastSyncDate = Date()
                UserDefaults.standard.set(Date(), forKey: "lastWorkoutSyncDate")
                print("✅ BackgroundTaskManager: Background sync completed successfully")
            } else {
                print("⏰ BackgroundTaskManager: Background sync partially completed - will resume in next task")
                saveBackgroundTaskState()
            }
            
            // Trigger queue processing in the background
            await WorkoutSyncQueue.shared.processInBackground()
            
            return true
            
        } catch {
            print("❌ BackgroundTaskManager: Background workout sync failed: \(error)")
            // Save state even on failure so we can retry
            saveBackgroundTaskState()
            return false
        }
    }
    
    private func queueWorkoutForProcessing(_ workout: Workout, userId: String, teamMultiplier: Double) {
        // Store workout processing task for later execution
        let processingTask = [
            "workoutId": workout.id,
            "userId": userId,
            "teamMultiplier": teamMultiplier,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        var pendingTasks = UserDefaults.standard.array(forKey: "pending_workout_processing") as? [[String: Any]] ?? []
        pendingTasks.append(processingTask)
        UserDefaults.standard.set(pendingTasks, forKey: "pending_workout_processing")
        
        print("📝 BackgroundTaskManager: Queued workout \(workout.id) for later processing")
    }
    
    private func checkAndDistributeRewardsWithTimeManagement() async -> Bool {
        print("⚡ BackgroundTaskManager: Starting time-managed reward check")
        
        // Quick check with time limits
        guard shouldContinueOperation() else {
            print("⏰ BackgroundTaskManager: Insufficient time for reward check")
            return true
        }
        
        return await checkAndDistributeRewards()
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
    
    private func updateNotificationsWithTimeManagement() async -> Bool {
        print("⚡ BackgroundTaskManager: Starting time-managed notification update")
        
        guard shouldContinueOperation() else {
            print("⏰ BackgroundTaskManager: Insufficient time for notification update")
            return true
        }
        
        return await updateNotifications()
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
    // Removed calculateWorkoutPoints - now using WorkoutRewardCalculator.shared.calculateReward()
    
    // MARK: - Manual Triggers (for testing)
    
    func triggerWorkoutSync() {
        Task {
            let success = await performWorkoutSyncWithTimeManagement()
            print("BackgroundTaskManager: Manual workout sync completed: \(success)")
        }
    }
    
    func triggerRewardCheck() {
        Task {
            let success = await checkAndDistributeRewardsWithTimeManagement()
            print("BackgroundTaskManager: Manual reward check completed: \(success)")
        }
    }
    
    func triggerNotificationUpdate() {
        Task {
            let success = await updateNotificationsWithTimeManagement()
            print("BackgroundTaskManager: Manual notification update completed: \(success)")
        }
    }
    
    // MARK: - Foreground Processing
    
    func processPendingTasksInForeground() async {
        print("🚀 BackgroundTaskManager: Processing pending tasks in foreground")
        
        // Process any queued workouts that were deferred from background
        await WorkoutSyncQueue.shared.forceSyncAll()
        
        // Process pending workout processing tasks
        await processPendingWorkoutTasks()
        
        // Clear any saved background state since we're now in foreground
        clearBackgroundTaskState()
        
        print("✅ BackgroundTaskManager: Foreground processing completed")
    }
    
    private func processPendingWorkoutTasks() async {
        guard let pendingTasks = UserDefaults.standard.array(forKey: "pending_workout_processing") as? [[String: Any]] else {
            return
        }
        
        guard let userId = AuthenticationService.shared.currentUserId else {
            print("⚠️ BackgroundTaskManager: No user logged in for pending task processing")
            return
        }
        
        print("📋 BackgroundTaskManager: Processing \(pendingTasks.count) pending workout tasks")
        
        var processedCount = 0
        for taskData in pendingTasks {
            guard let workoutId = taskData["workoutId"] as? String,
                  let taskUserId = taskData["userId"] as? String,
                  let teamMultiplier = taskData["teamMultiplier"] as? Double,
                  taskUserId == userId else {
                continue
            }
            
            do {
                // Try to fetch the workout from recent workouts
                let recentWorkouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 50)
                
                if let workout = recentWorkouts.first(where: { $0.id == workoutId }) {
                    await processWorkoutInForeground(workout, userId: userId, teamMultiplier: teamMultiplier)
                    processedCount += 1
                } else {
                    print("⚠️ BackgroundTaskManager: Could not find workout \(workoutId) for processing")
                }
            } catch {
                print("❌ BackgroundTaskManager: Failed to process pending workout \(workoutId): \(error)")
            }
        }
        
        // Clear processed tasks
        UserDefaults.standard.removeObject(forKey: "pending_workout_processing")
        print("✅ BackgroundTaskManager: Processed \(processedCount)/\(pendingTasks.count) pending tasks")
    }
    
    private func processWorkoutInForeground(_ workout: Workout, userId: String, teamMultiplier: Double) async {
        // TODO: Fix type issues - need to convert between Workout and HealthKitWorkout types
        print("🔄 BackgroundTaskManager: Processing workout \(workout.id) in foreground (temporarily disabled)")
        
        // Placeholder implementation until type issues are resolved
        // The original complex processing will be re-enabled after fixing type conversions
    }
    
    // MARK: - Status and Monitoring
    
    func getBackgroundSyncStatus() -> BackgroundSyncStatus {
        let queueStats = WorkoutSyncQueue.shared.getSyncStatistics()
        let savedState = loadBackgroundTaskState()
        let pendingTasks = UserDefaults.standard.array(forKey: "pending_workout_processing") as? [[String: Any]] ?? []
        
        return BackgroundSyncStatus(
            isBackgroundTaskActive: currentTask != nil,
            queuedWorkouts: queueStats.totalQueued,
            pendingProcessingTasks: pendingTasks.count,
            lastSyncTime: lastSyncDate,
            hasPartialSyncState: savedState != nil,
            remainingBackgroundTime: getRemainingBackgroundTime()
        )
    }
}

// MARK: - Background Sync Status

struct BackgroundSyncStatus {
    let isBackgroundTaskActive: Bool
    let queuedWorkouts: Int
    let pendingProcessingTasks: Int
    let lastSyncTime: Date
    let hasPartialSyncState: Bool
    let remainingBackgroundTime: TimeInterval
    
    var needsForegroundProcessing: Bool {
        return queuedWorkouts > 0 || pendingProcessingTasks > 0 || hasPartialSyncState
    }
    
    var statusDescription: String {
        if isBackgroundTaskActive {
            return "Background sync in progress (\(Int(remainingBackgroundTime))s remaining)"
        } else if needsForegroundProcessing {
            return "\(queuedWorkouts + pendingProcessingTasks) tasks pending processing"
        } else {
            return "All synced (last: \(lastSyncTime.formatted(.relative(presentation: .numeric))))"
        }
    }
}