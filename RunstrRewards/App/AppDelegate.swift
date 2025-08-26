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
    
    // MARK: - Core Services Setup
    
    private func setupCoreServices() {
        // Initialize only essential services needed before authentication
        
        // Clear any temporary token sessions from previous app versions
        AuthenticationService.shared.clearTemporaryTokenSessions()
        print("AppDelegate: Cleared any temporary token sessions")
        
        // Start network monitoring (lightweight, needed for auth)
        let _ = NetworkMonitorService.shared
        print("AppDelegate: Network monitoring initialized")
        
        // Initialize offline data service (lightweight)
        let _ = OfflineDataService.shared
        print("AppDelegate: Offline data service initialized")
        
        // Initialize error handling service (lightweight)
        let _ = ErrorHandlingService.shared
        print("AppDelegate: Error handling service initialized")
        
        // Register background tasks now (required before app finishes launching)
        BackgroundTaskManager.shared.registerBackgroundTasks()
        print("AppDelegate: Background tasks registered")
        
        // Defer these until after authentication:
        // - Background task scheduling
        // - HealthKit setup
        // These will be initialized in setupPostAuthenticationServices()
    }
    
    // Call this after user successfully authenticates
    public func setupPostAuthenticationServices() {
        // Schedule background tasks (registration was done during app launch)
        BackgroundTaskManager.shared.scheduleAllBackgroundTasks()
        print("AppDelegate: Background tasks scheduled")
        
        // Setup HealthKit background delivery for automatic workout sync
        setupHealthKitBackgroundDelivery()
        
        // Setup network change notifications
        setupNetworkNotifications()
        
        // Validate StoreKit configuration
        validateStoreKitSetup()
    }
    
    private func validateStoreKitSetup() {
        Task {
            let isValid = await SubscriptionService.shared.validateStoreKitConfiguration()
            if isValid {
                print("AppDelegate: ✅ StoreKit configuration validated successfully")
            } else {
                print("AppDelegate: ❌ StoreKit configuration validation failed - subscription features may not work")
            }
        }
    }
    
    private func setupHealthKitBackgroundDelivery() {
        Task {
            do {
                // Wrap in error handling to prevent crashes
                guard HKHealthStore.isHealthDataAvailable() else {
                    print("AppDelegate: HealthKit not available on this device")
                    return
                }
                
                // Check if HealthKit is authorized first
                if HealthKitService.shared.checkAuthorizationStatus() {
                    // Enable background delivery for workout updates
                    try await HealthKitService.shared.enableBackgroundDelivery()
                    print("AppDelegate: HealthKit background delivery enabled")
                    
                    // Enable workout completion notifications by default for new users
                    let hasSetWorkoutNotificationPreference = UserDefaults.standard.object(forKey: "notifications.workout_completed") != nil
                    if !hasSetWorkoutNotificationPreference {
                        UserDefaults.standard.set(true, forKey: "notifications.workout_completed")
                        print("AppDelegate: Enabled workout completion notifications by default")
                    }
                    
                    // Set up observer to detect new workouts immediately
                    HealthKitService.shared.observeWorkouts { [weak self] newWorkouts in
                        if !newWorkouts.isEmpty {
                            print("AppDelegate: Detected \(newWorkouts.count) new workouts, triggering immediate sync")
                            
                            // Process workouts immediately for real-time sync
                            Task {
                                await self?.processNewWorkoutsImmediately(newWorkouts)
                            }
                            
                            // Send workout completion notifications
                            for workout in newWorkouts {
                                self?.sendWorkoutCompletionNotification(for: workout)
                            }
                        }
                    }
                    print("AppDelegate: HealthKit workout observer started")
                    
                    // Initialize EventCriteriaEngine to load active events
                    Task {
                        await EventCriteriaEngine.shared.initialize()
                    }
                    
                } else {
                    print("AppDelegate: HealthKit not authorized, skipping background delivery setup")
                }
            } catch {
                print("AppDelegate: Failed to setup HealthKit background delivery: \(error)")
            }
        }
    }
    
    private func sendWorkoutCompletionNotification(for workout: HealthKitWorkout) {
        // Check if user wants workout completion notifications
        let workoutNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        guard workoutNotificationsEnabled else { return }
        
        // Get user's teams for team-branded notifications
        Task {
            await sendTeamBrandedWorkoutNotification(for: workout)
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
    
    // MARK: - Immediate Workout Processing
    
    private func processNewWorkoutsImmediately(_ healthKitWorkouts: [HealthKitWorkout]) async {
        guard let userId = AuthenticationService.shared.currentUserId else {
            print("AppDelegate: No user logged in for immediate sync")
            return
        }
        
        print("🚀 AppDelegate: Processing \(healthKitWorkouts.count) new workouts immediately")
        
        for workout in healthKitWorkouts {
            do {
                // Convert to Supabase workout format
                let supabaseWorkout = HealthKitService.shared.convertToSupabaseWorkout(workout, userId: userId)
                
                // Process immediately with rewards and team updates
                try await WorkoutDataService.shared.processWorkoutForRewards(supabaseWorkout)
                
                // Process workout for events and challenges immediately  
                await processWorkoutForEventsImmediately(workout, userId: userId)
                
                // Update team leaderboards immediately
                await updateTeamLeaderboardsForWorkout(userId: userId, workout: supabaseWorkout)
                
                print("🎯 AppDelegate: ✅ Immediately synced workout \(workout.id) with team updates")
                
            } catch {
                print("AppDelegate: ❌ Failed to immediately sync workout \(workout.id): \(error)")
                
                // Fallback to background sync if immediate sync fails
                BackgroundTaskManager.shared.triggerWorkoutSync()
            }
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
    
    private func processWorkoutForEventsImmediately(_ workout: HealthKitWorkout, userId: String) async {
        print("🎯 AppDelegate: Processing workout for events immediately")
        
        // Use EventCriteriaEngine to check workout against all active events
        await EventCriteriaEngine.shared.processWorkoutForEvents(workout, userId: userId)
        
        print("🎯 AppDelegate: Immediate event processing completed for workout \(workout.id)")
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
        // Process any pending sync tasks when app comes to foreground
        Task {
            await BackgroundTaskManager.shared.processPendingTasksInForeground()
        }
        print("AppDelegate: Processing pending tasks in foreground")
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationService.shared.setDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error)")
    }
}