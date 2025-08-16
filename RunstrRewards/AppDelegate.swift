import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
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
        
        // Defer these until after authentication:
        // - Background task manager
        // - HealthKit setup
        // These will be initialized in setupPostAuthenticationServices()
    }
    
    // Call this after user successfully authenticates
    public func setupPostAuthenticationServices() {
        // Setup background task manager
        BackgroundTaskManager.shared.setupBackgroundTasks()
        print("AppDelegate: Background task manager initialized")
        
        // Setup HealthKit background delivery for automatic workout sync
        setupHealthKitBackgroundDelivery()
        
        // Setup network change notifications
        setupNetworkNotifications()
    }
    
    private func setupHealthKitBackgroundDelivery() {
        Task {
            do {
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
                            // Trigger immediate background sync for new workouts
                            BackgroundTaskManager.shared.triggerWorkoutSync()
                            
                            // Send workout completion notifications
                            for workout in newWorkouts {
                                self?.sendWorkoutCompletionNotification(for: workout)
                            }
                        }
                    }
                    print("AppDelegate: HealthKit workout observer started")
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
        
        // Calculate estimated reward
        let estimatedPoints = calculateWorkoutPoints(workout)
        let estimatedSats = estimatedPoints * 10
        
        // Send notification
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
    
    private func calculateWorkoutPoints(_ workout: HealthKitWorkout) -> Int {
        var points = 10 // Base points
        
        // Duration bonus (1 point per 5 minutes)
        let minutes = Int(workout.duration / 60)
        points += minutes / 5
        
        // Distance bonus for cardio workouts
        if workout.workoutType == "running" || workout.workoutType == "cycling" {
            let kilometers = workout.totalDistance / 1000
            points += Int(kilometers)
        }
        
        // Calorie bonus (1 point per 50 calories)
        let calories = Int(workout.totalEnergyBurned)
        points += calories / 50
        
        return min(points, 100) // Cap at 100 points
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
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationService.shared.setDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error)")
    }
}