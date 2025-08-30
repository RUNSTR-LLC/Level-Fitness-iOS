import UIKit
import UserNotifications
import HealthKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Setup crash reporting and error handling first
        setupCrashProtection()
        
        // Initialize core services
        setupCoreServices()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Check if user is already authenticated
        let rootViewController: UIViewController
        if let existingSession = AuthenticationService.shared.loadSession() {
            print("AppDelegate: Found existing session for user: \(existingSession.email ?? "Unknown")")
            // User is already authenticated, go straight to main app
            rootViewController = ViewController()
            // Setup post-authentication services for existing session
            DispatchQueue.main.async { [weak self] in
                self?.setupPostAuthenticationServices()
            }
        } else {
            print("AppDelegate: No existing session, showing login")
            // User needs to authenticate (either never signed in or invalid tokens were cleared)
            rootViewController = LoginViewController()
        }
        
        let navigationController = UINavigationController(rootViewController: rootViewController)
        
        // Configure navigation bar appearance for industrial theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = IndustrialDesign.Colors.background
        appearance.titleTextAttributes = [
            .foregroundColor: IndustrialDesign.Colors.primaryText,
            .font: IndustrialDesign.Typography.navTitleFont
        ]
        appearance.shadowColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = IndustrialDesign.Colors.primaryText
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    // MARK: - Crash Protection
    
    private func setupCrashProtection() {
        // Setup global exception handler
        NSSetUncaughtExceptionHandler { exception in
            print("CRITICAL: Uncaught exception: \(exception)")
            print("Stack trace: \(exception.callStackSymbols)")
            
            // Save crash info for later reporting
            let crashInfo = [
                "exception": exception.description,
                "stack_trace": exception.callStackSymbols.joined(separator: "\n"),
                "timestamp": Date().timeIntervalSince1970
            ] as [String : Any]
            
            UserDefaults.standard.set(crashInfo, forKey: "last_crash_info")
            UserDefaults.standard.synchronize()
        }
        
        // Check for previous crash on startup
        if let crashInfo = UserDefaults.standard.dictionary(forKey: "last_crash_info") {
            print("WARNING: App previously crashed. Info: \(crashInfo["exception"] ?? "Unknown")")
            
            // Report crash to analytics/logging service
            ErrorHandlingService.shared.logCrashInfo(crashInfo)
            
            // Clear crash info
            UserDefaults.standard.removeObject(forKey: "last_crash_info")
        }
    }
    
    // MARK: - Core Services Setup (Moved to Extension)
    
    private func sendWorkoutCompletionNotification(for workout: HealthKitWorkout) {
        // Check if user wants workout completion notifications
        let workoutNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        guard workoutNotificationsEnabled else { return }
        
        // Get user's teams for team-branded notifications
        Task { [weak self] in
            await self?.sendTeamBrandedWorkoutNotification(for: workout)
        }
    }
    
    private func sendTeamBrandedWorkoutNotification(for workout: HealthKitWorkout) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        // Calculate estimated reward
        let estimatedPoints = calculateWorkoutPoints(workout)
        let estimatedSats = estimatedPoints * 10
        
        do {
            // Fetch user's teams to include in notification
            let userTeams = try await SupabaseService.shared.fetchUserTeams(userId: userId)
            
            // Send notification for each team the user is part of
            for team in userTeams {
                let content = UNMutableNotificationContent()
                content.title = "\(team.name): Workout Synced! 💪"
                content.body = "Your \(workout.workoutType) has been synced! +\(estimatedSats) sats earned ⚡"
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "WORKOUT_COMPLETION"
                content.userInfo = [
                    "type": "workout_completed",
                    "team_id": team.id,
                    "team_name": team.name,
                    "workout_type": workout.workoutType,
                    "estimated_sats": estimatedSats,
                    "duration": workout.duration
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "workout_completed_\(team.id)_\(workout.id)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("AppDelegate: Failed to schedule team-branded workout notification for \(team.name): \(error)")
                    } else {
                        print("AppDelegate: Team-branded workout notification scheduled for \(team.name)")
                    }
                }
            }
            
            // If user has no teams, send generic notification
            if userTeams.isEmpty {
                let content = UNMutableNotificationContent()
                content.title = "Workout Detected! 💪"
                content.body = "Nice \(workout.workoutType)! You've earned approximately \(estimatedSats) sats ⚡"
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "WORKOUT_COMPLETION"
                content.userInfo = [
                    "type": "workout_completed",
                    "workout_type": workout.workoutType,
                    "estimated_sats": estimatedSats,
                    "duration": workout.duration
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "workout_completed_\(workout.id)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("AppDelegate: Failed to schedule workout completion notification: \(error)")
                    } else {
                        print("AppDelegate: Workout completion notification scheduled for \(workout.workoutType)")
                    }
                }
            }
            
        } catch {
            print("AppDelegate: Failed to fetch user teams for workout notification: \(error)")
            // Fallback to generic notification
            let content = UNMutableNotificationContent()
            content.title = "Workout Detected! 💪"
            content.body = "Nice \(workout.workoutType)! You've earned approximately \(estimatedSats) sats ⚡"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "WORKOUT_COMPLETION"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "workout_completed_\(workout.id)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { _ in }
        }
    }
    
    private func calculateWorkoutPoints(_ workout: HealthKitWorkout) -> Int {
        var points = 10 // Base points
        
        // Duration bonus (1 point per 5 minutes)
        let minutes = Int(workout.duration / 60)
        points += minutes / 5
        
        // Distance bonus for cardio workouts
        if workout.workoutType == "running" || workout.workoutType == "cycling" {
            let kilometers = (workout.totalDistance ?? 0.0) / 1000
            points += Int(kilometers)
        }
        
        // Calorie bonus (1 point per 50 calories)
        let calories = Int(workout.totalEnergyBurned ?? 0.0)
        points += calories / 50
        
        return min(points, 100) // Cap at 100 points
    }
    
    // MARK: - Performance Optimization
    
    private actor AsyncSemaphore {
        private var value: Int
        private var waiters: [CheckedContinuation<Void, Never>] = []
        
        init(value: Int) {
            self.value = value
        }
        
        func wait() async {
            if value > 0 {
                value -= 1
                return
            }
            
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
        
        func signal() {
            if waiters.isEmpty {
                value += 1
            } else {
                let waiter = waiters.removeFirst()
                waiter.resume()
            }
        }
    }
    
    private func calculateOptimalBatchSize(for workoutCount: Int) -> Int {
        // Base batch size on device capabilities and system load
        let processorCount = ProcessInfo.processInfo.processorCount
        let memoryPressure = ProcessInfo.processInfo.thermalState
        
        var baseBatchSize: Int
        
        // Adjust based on thermal state (device heat/performance)
        switch memoryPressure {
        case .nominal:
            baseBatchSize = max(processorCount, 4) // At least 4, up to processor count
        case .fair:
            baseBatchSize = max(processorCount / 2, 2) // Reduce load
        case .serious, .critical:
            baseBatchSize = 1 // Process one at a time to avoid overheating
        @unknown default:
            baseBatchSize = 3 // Conservative default
        }
        
        // Cap batch size based on total workouts (don't over-batch small datasets)
        let finalBatchSize = min(baseBatchSize, max(workoutCount / 2, 1))
        
        Logger.shared.logPerformance("Optimal batch size: \(finalBatchSize) (processors: \(processorCount), thermal: \(memoryPressure.rawValue))")
        return finalBatchSize
    }
    
    // MARK: - INSTANT Workout Processing (Zero Delay)
    
    private func processNewWorkoutsInstantly(_ healthKitWorkouts: [HealthKitWorkout]) async {
        guard let userId = AuthenticationService.shared.currentUserId else {
            print("AppDelegate: No user logged in for immediate sync")
            return
        }
        
        Logger.shared.logPerformance("SMART BATCHED processing", items: healthKitWorkouts.count)
        
        // Process workouts in adaptive batches based on device capabilities
        let batchSize = calculateOptimalBatchSize(for: healthKitWorkouts.count)
        let batches = healthKitWorkouts.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            print("📦 AppDelegate: Processing batch \(batchIndex + 1)/\(batches.count) (\(batch.count) workouts)")
            
            // Add resource-aware processing with throttling
            await processWorkoutBatchWithThrottling(batch, batchIndex: batchIndex, totalBatches: batches.count, userId: userId)
        }
        
        print("🎉 AppDelegate: All \(healthKitWorkouts.count) workouts processed successfully!")
    }
    
    private func processWorkoutBatchWithThrottling(_ batch: [HealthKitWorkout], batchIndex: Int, totalBatches: Int, userId: String) async {
        let semaphore = AsyncSemaphore(value: min(batch.count, 3)) // Limit concurrent tasks
        
        await withTaskGroup(of: Void.self) { group in
            for workout in batch {
                group.addTask { [weak self] in
                    await semaphore.wait() // Wait for available slot
                    defer { semaphore.signal() } // Release slot when done
                    
                    await self?.processSingleWorkoutInstantly(workout, userId: userId)
                }
            }
            
            // Wait for all workouts in this batch to complete
            await group.waitForAll()
            
            print("✅ AppDelegate: Batch \(batchIndex + 1)/\(totalBatches) completed")
        }
    }
    
    private func processSingleWorkoutInstantly(_ workout: HealthKitWorkout, userId: String) async {
        do {
            let startTime = Date()
            
            // Convert to Supabase workout format
            let supabaseWorkout = HealthKitService.shared.convertToSupabaseWorkout(workout, userId: userId)
            
            // Process ALL operations in parallel for maximum speed
            async let rewardsTask: Void = WorkoutDataService.shared.processWorkoutForRewards(supabaseWorkout)
            async let eventsTask: Void = processWorkoutForEventsInstantly(workout, userId: userId)
            async let leaderboardTask: Void = updateTeamLeaderboardsForWorkout(userId: userId, workout: supabaseWorkout)
            
            // Wait for all operations to complete
            try await rewardsTask
            await eventsTask
            await leaderboardTask
            
            let processingTime = Date().timeIntervalSince(startTime)
            print("⚡ AppDelegate: ✅ INSTANT sync completed for workout \(workout.id) in \(String(format: "%.2f", processingTime))s")
            
            // Mark successful sync (removes from retry queue if it was there)
            await WorkoutSyncRetryManager.shared.recordSuccessfulSync(workoutId: workout.id)
            
        } catch {
            print("AppDelegate: ❌ Failed instant sync for workout \(workout.id): \(error)")
            
            // Record failure for intelligent retry with exponential backoff
            await WorkoutSyncRetryManager.shared.recordFailedSync(
                workout: workout,
                userId: userId,
                error: error,
                source: "InstantSync"
            )
            
            // Still try to send notification even if sync fails
            sendInstantWorkoutNotification(for: workout)
        }
    }
    
    private func updateTeamLeaderboardsForWorkout(userId: String, workout: Workout) async {
        print("🏆 AppDelegate: Tracking user positions after immediate workout sync")
        
        // Track all leaderboard positions for user after workout
        let positionChanges = await LeaderboardTracker.shared.trackUserPositions(userId: userId)
        
        print("🏆 AppDelegate: Found \(positionChanges.count) leaderboard position changes")
        
        // Process any position change notifications
        if !positionChanges.isEmpty {
            await LeaderboardTracker.shared.processPositionChanges(positionChanges)
        }
    }
    
    private func processWorkoutForEventsInstantly(_ workout: HealthKitWorkout, userId: String) async {
        print("⚡ AppDelegate: INSTANT event processing for workout \(workout.id)")
        
        // Use EventCriteriaEngine to check workout against all active events
        await EventCriteriaEngine.shared.processWorkoutForEvents(workout, userId: userId)
        
        print("⚡ AppDelegate: INSTANT event processing completed for workout \(workout.id)")
    }
    
    private func sendInstantWorkoutNotification(for workout: HealthKitWorkout) {
        print("🔔 AppDelegate: Sending INSTANT workout notification")
        
        // Check if user wants workout completion notifications
        let workoutNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        guard workoutNotificationsEnabled else { 
            print("🔔 AppDelegate: Workout notifications disabled by user")
            return 
        }
        
        // Get user's teams for team-branded notifications
        Task { [weak self] in
            await self?.sendInstantTeamBrandedWorkoutNotification(for: workout)
        }
    }
    
    private func sendInstantTeamBrandedWorkoutNotification(for workout: HealthKitWorkout) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        let notificationStartTime = Date()
        
        // Calculate estimated reward
        let estimatedPoints = calculateWorkoutPoints(workout)
        let estimatedSats = estimatedPoints * 10
        
        do {
            // Fetch user's teams to include in notification
            let userTeams = try await SupabaseService.shared.fetchUserTeams(userId: userId)
            
            // Send notification for each team the user is part of
            for team in userTeams {
                let content = UNMutableNotificationContent()
                content.title = "🚀 \(team.name): Workout Synced!"
                content.body = "Your \(workout.workoutType) is now live! +\(estimatedSats) sats earned ⚡"
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "WORKOUT_COMPLETION"
                content.userInfo = [
                    "type": "workout_completed",
                    "team_id": team.id,
                    "team_name": team.name,
                    "workout_type": workout.workoutType,
                    "estimated_sats": estimatedSats,
                    "duration": workout.duration,
                    "sync_time": Date().timeIntervalSince1970
                ]
                
                // Send immediately - NO delay
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "instant_workout_\(team.id)_\(workout.id)",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    let notificationTime = Date().timeIntervalSince(notificationStartTime)
                    print("🔔 AppDelegate: ✅ INSTANT notification sent for \(team.name) in \(String(format: "%.3f", notificationTime))s")
                } catch {
                    print("🔔 AppDelegate: ❌ Failed to send instant notification for \(team.name): \(error)")
                }
            }
            
            // If user has no teams, send generic instant notification
            if userTeams.isEmpty {
                let content = UNMutableNotificationContent()
                content.title = "🚀 Workout Synced!"
                content.body = "Your \(workout.workoutType) is live! Earned ~\(estimatedSats) sats ⚡"
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "WORKOUT_COMPLETION"
                content.userInfo = [
                    "type": "workout_completed",
                    "workout_type": workout.workoutType,
                    "estimated_sats": estimatedSats,
                    "duration": workout.duration,
                    "sync_time": Date().timeIntervalSince1970
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "instant_workout_\(workout.id)",
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    let notificationTime = Date().timeIntervalSince(notificationStartTime)
                    print("🔔 AppDelegate: ✅ Generic INSTANT notification sent in \(String(format: "%.3f", notificationTime))s")
                } catch {
                    print("🔔 AppDelegate: ❌ Failed to send generic instant notification: \(error)")
                }
            }
            
        } catch {
            print("🔔 AppDelegate: ❌ Failed to fetch user teams for instant notification: \(error)")
            
            // Fallback to immediate generic notification
            let content = UNMutableNotificationContent()
            content.title = "🚀 Workout Detected!"
            content.body = "Your \(workout.workoutType) is syncing now! ~\(estimatedSats) sats ⚡"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "WORKOUT_COMPLETION"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "instant_fallback_\(workout.id)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                print("🔔 AppDelegate: ✅ Fallback instant notification sent")
            } catch {
                print("🔔 AppDelegate: ❌ Failed to send fallback notification: \(error)")
            }
        }
    }
    
    private func setupNetworkNotifications() {
        NotificationCenter.default.addObserver(
            forName: .connectionRestored,
            object: nil,
            queue: .main
        ) { notification in
            print("AppDelegate: Network connection restored")
            // Could show a brief success message to user
        }
        
        NotificationCenter.default.addObserver(
            forName: .connectionLost,
            object: nil,
            queue: .main
        ) { notification in
            print("AppDelegate: Network connection lost - app in offline mode")
            // Could show offline indicator in UI
        }
    }
    
    // MARK: - Background Tasks
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Reschedule background tasks when app enters background
        BackgroundTaskManager.shared.scheduleWorkoutSync()
        BackgroundTaskManager.shared.scheduleRewardCheck()
        BackgroundTaskManager.shared.scheduleNotificationUpdate()
        print("AppDelegate: Background tasks rescheduled")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("🚀 AppDelegate: App entering foreground - triggering IMMEDIATE workout check")
        
        // FORCE check for any new workouts that might have been missed
        Task { [weak self] in
            await self?.forceImmediateWorkoutCheck()
            await BackgroundTaskManager.shared.processPendingTasksInForeground()
        }
    }
    
    private func forceImmediateWorkoutCheck() async {
        print("🔥 AppDelegate: FORCE checking for missed workouts")
        
        await HealthKitService.shared.forceWorkoutCheck { [weak self] newWorkouts in
            if !newWorkouts.isEmpty {
                print("🔥 AppDelegate: Force check found \(newWorkouts.count) missed workouts!")
                
                Task { [weak self] in
                    await self?.processNewWorkoutsInstantly(newWorkouts)
                }
                
                for workout in newWorkouts {
                    self?.sendInstantWorkoutNotification(for: workout)
                }
            } else {
                print("🔥 AppDelegate: Force check - no missed workouts found")
            }
        }
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationService.shared.setDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error)")
    }
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}