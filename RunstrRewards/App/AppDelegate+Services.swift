import UIKit
import UserNotifications
import HealthKit

extension AppDelegate {
    
    // MARK: - Core Services Setup
    
    func setupCoreServices() {
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
    func setupPostAuthenticationServices() {
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
    
    func setupHealthKitBackgroundDelivery() {
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
                    
                    // Set up enhanced observer to detect new workouts with ZERO delay
                    HealthKitService.shared.observeWorkouts { [weak self] newWorkouts in
                        if !newWorkouts.isEmpty {
                            print("🚀 AppDelegate: IMMEDIATE detection of \(newWorkouts.count) new workouts!")
                            
                            // Process workouts with ZERO delay - don't wait for anything
                            Task {
                                await self?.processNewWorkoutsInstantly(newWorkouts)
                            }
                            
                            // Send workout completion notifications INSTANTLY
                            for workout in newWorkouts {
                                self?.sendInstantWorkoutNotification(for: workout)
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
    
    func setupNetworkNotifications() {
        // Setup network change notifications to handle connectivity changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NetworkStatusChanged"),
            object: nil,
            queue: .main
        ) { _ in
            print("AppDelegate: Network status changed - updating sync strategies")
        }
    }
    
    func sendWorkoutCompletionNotification(for workout: HealthKitWorkout) {
        // Check if user wants workout completion notifications
        let workoutNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        guard workoutNotificationsEnabled else { return }
        
        // Get user's teams for team-branded notifications
        Task {
            await sendTeamBrandedWorkoutNotification(for: workout)
        }
    }
    
    func sendTeamBrandedWorkoutNotification(for workout: HealthKitWorkout) async {
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
                
                let request = UNNotificationRequest(
                    identifier: "workout_\(workout.id)_team_\(team.id)",
                    content: content,
                    trigger: nil // Immediate delivery
                )
                
                try await UNUserNotificationCenter.current().add(request)
                print("AppDelegate: Sent team-branded workout notification for team: \(team.name)")
            }
        } catch {
            print("AppDelegate: Failed to send team-branded workout notification: \(error)")
        }
    }
    
    private func calculateWorkoutPoints(_ workout: HealthKitWorkout) -> Int {
        // Simple point calculation based on duration and type
        let baseDuration = Int(workout.duration / 60) // minutes
        let multiplier: Int
        
        switch workout.activityType {
        case .running:
            multiplier = 3
        case .cycling:
            multiplier = 2
        case .swimming:
            multiplier = 4
        case .walking:
            multiplier = 1
        default:
            multiplier = 2
        }
        
        return max(baseDuration * multiplier, 10)
    }
}