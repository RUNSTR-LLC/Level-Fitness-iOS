import UIKit
import HealthKit
import Foundation

class ProfileWorkoutsTabView: UIView {
    
    // MARK: - UI Components
    private let syncSourcesView = ProfileSyncSourcesView()
    private let workoutHistoryView = ProfileWorkoutHistoryView()
    private let spacing: CGFloat = 24
    
    // MARK: - Properties
    private var isLoadingData = false
    private var liveWorkoutSubscriptionId: String?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // Clean up live Nostr subscription
        if let subscriptionId = liveWorkoutSubscriptionId {
            Nostr1301Service.shared.unsubscribeFromLiveWorkouts(subscriptionId)
            liveWorkoutSubscriptionId = nil
        }
        print("👤 Workouts Tab: View deallocated, Nostr subscription cleaned up")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Configure subviews
        syncSourcesView.translatesAutoresizingMaskIntoConstraints = false
        workoutHistoryView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(syncSourcesView)
        addSubview(workoutHistoryView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Sync sources section
            syncSourcesView.topAnchor.constraint(equalTo: topAnchor),
            syncSourcesView.leadingAnchor.constraint(equalTo: leadingAnchor),
            syncSourcesView.trailingAnchor.constraint(equalTo: trailingAnchor),
            syncSourcesView.heightAnchor.constraint(equalToConstant: 120),
            
            // Workout history section
            workoutHistoryView.topAnchor.constraint(equalTo: syncSourcesView.bottomAnchor, constant: spacing),
            workoutHistoryView.leadingAnchor.constraint(equalTo: leadingAnchor),
            workoutHistoryView.trailingAnchor.constraint(equalTo: trailingAnchor),
            workoutHistoryView.bottomAnchor.constraint(equalTo: bottomAnchor),
            workoutHistoryView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
        ])
    }
    
    private func setupDelegates() {
        syncSourcesView.delegate = self
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        print("👤 Workouts Tab: Refreshing data")
        
        guard !isLoadingData else { return }
        isLoadingData = true
        
        // Load sync source states
        syncSourcesView.loadSyncStates()
        
        // Setup live Nostr subscription if authenticated
        setupLiveNostrSubscription()
        
        // Load workout history
        loadWorkoutHistory()
    }
    
    // MARK: - Private Methods
    
    private func loadWorkoutHistory() {
        Task {
            do {
                var allWorkouts: [HealthKitWorkout] = []
                
                // Fetch HealthKit workouts
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 20)
                allWorkouts.append(contentsOf: healthKitWorkouts)
                
                print("👤 Workouts Tab: Loaded \(healthKitWorkouts.count) HealthKit workouts")
                
                // Fetch Nostr workouts if authenticated
                if NostrAuthenticationService.shared.isNostrAuthenticated,
                   let nostrCredentials = NostrAuthenticationService.shared.currentNostrCredentials {
                    print("👤 Workouts Tab: Syncing Nostr workouts...")
                    
                    Nostr1301Service.shared.syncWorkouts(for: nostrCredentials, since: nil) { nostrResult in
                        DispatchQueue.main.async {
                            switch nostrResult {
                            case .success(let nostrWorkouts):
                                print("👤 Workouts Tab: Loaded \(nostrWorkouts.count) Nostr workouts")
                                allWorkouts.append(contentsOf: nostrWorkouts)
                                
                                // Apply deduplication with all sources
                                let deduplicatedWorkouts = WorkoutDeduplicationService.shared.deduplicateWorkouts(allWorkouts)
                                
                                // Update UI
                                self.workoutHistoryView.updateWorkouts(deduplicatedWorkouts.map { ProfileWorkoutData.fromHealthKitWorkout($0) })
                                self.isLoadingData = false
                                
                                print("👤 Workouts Tab: Final workout count after deduplication: \(deduplicatedWorkouts.count)")
                                
                            case .failure(let error):
                                print("👤 Workouts Tab: Nostr sync failed: \(error)")
                                
                                // Still show HealthKit workouts even if Nostr fails
                                self.workoutHistoryView.updateWorkouts(allWorkouts.map { ProfileWorkoutData.fromHealthKitWorkout($0) })
                                self.isLoadingData = false
                            }
                        }
                    }
                } else {
                    print("👤 Workouts Tab: Nostr not authenticated, using only HealthKit workouts")
                    
                    // No Nostr auth, just use HealthKit workouts
                    self.workoutHistoryView.updateWorkouts(allWorkouts.map { ProfileWorkoutData.fromHealthKitWorkout($0) })
                    self.isLoadingData = false
                }
                
            } catch {
                print("👤 Workouts Tab: Error loading workout history: \(error)")
                await MainActor.run {
                    self.isLoadingData = false
                }
            }
        }
    }
    
    
    private func setupLiveNostrSubscription() {
        guard NostrAuthenticationService.shared.isNostrAuthenticated,
              let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            print("👤 Workouts Tab: Nostr not authenticated, skipping live subscription")
            return
        }
        
        print("👤 Workouts Tab: Setting up live Nostr 1301 workout subscription")
        
        liveWorkoutSubscriptionId = Nostr1301Service.shared.subscribeToLiveWorkouts(for: credentials) { [weak self] (workout: HealthKitWorkout) in
            print("👤 Workouts Tab: Received live workout from Nostr: \(workout.activityType.displayName)")
            
            DispatchQueue.main.async {
                self?.handleNewLiveWorkout(workout)
            }
        }
        
        if liveWorkoutSubscriptionId != nil {
            print("👤 Workouts Tab: Live Nostr subscription established successfully")
        } else {
            print("👤 Workouts Tab: Failed to establish live Nostr subscription")
        }
    }
    
    private func handleNewLiveWorkout(_ workout: HealthKitWorkout) {
        // Convert to display format
        let workoutData = ProfileWorkoutData(
            id: workout.id,
            type: workout.activityType.displayName,
            distance: workout.totalDistance ?? 0.0,
            duration: workout.duration,
            calories: workout.totalEnergyBurned ?? 0.0,
            startedAt: workout.startDate,
            endedAt: workout.endDate,
            source: workout.syncSource.displayName
        )
        
        // Refresh workout history to include new workout
        loadWorkoutHistory()
        
        // Show notification to user
        showNewWorkoutNotification(workoutData)
        
        // Update sync stats
        let currentCount = UserDefaults.standard.integer(forKey: "nostr_1301_workout_count")
        UserDefaults.standard.set(currentCount + 1, forKey: "nostr_1301_workout_count")
        UserDefaults.standard.set(Date(), forKey: "nostr_1301_last_sync")
        
        // Refresh sync source UI
        syncSourcesView.loadSyncStates()
    }
    
    private func showNewWorkoutNotification(_ workout: ProfileWorkoutData) {
        // Find the view controller to show notification
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                let alert = UIAlertController(
                    title: "New Workout Synced",
                    message: "\(workout.type) • \(workout.formattedDuration)",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "View", style: .default) { _ in
                    // Scroll to top of workout history
                    print("👤 Workouts Tab: Scrolling to new workout")
                })
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                
                viewController.present(alert, animated: true)
                break
            }
            responder = responder?.next
        }
    }
    
    private func syncHealthKit() {
        print("👤 Workouts Tab: Starting HealthKit sync")
        
        Task {
            do {
                // Request HealthKit authorization if needed
                let isAuthorized = try await HealthKitService.shared.requestAuthorization()
                
                if isAuthorized {
                    // Sync recent workouts
                    let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    let workouts = try await HealthKitService.shared.fetchWorkoutsSince(sevenDaysAgo, limit: 50)
                    
                    print("👤 Workouts Tab: Synced \(workouts.count) workouts from HealthKit")
                    
                    // Update sync state
                    await MainActor.run {
                        self.syncSourcesView.updateSyncState(for: "HealthKit", isConnected: true, lastSync: Date())
                    }
                    
                    // Reload workout history
                    loadWorkoutHistory()
                    
                } else {
                    print("👤 Workouts Tab: HealthKit authorization denied")
                    await MainActor.run {
                        self.syncSourcesView.updateSyncState(for: "HealthKit", isConnected: false, lastSync: nil)
                    }
                }
            } catch {
                print("👤 Workouts Tab: HealthKit sync error: \(error)")
            }
        }
    }
    
    private func syncNostr() {
        print("👤 Workouts Tab: Starting Nostr sync")
        
        guard NostrAuthenticationService.shared.isNostrAuthenticated,
              let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            showComingSoonAlert(for: "Nostr", message: "Please sign in with your Nostr account first. You can add Nostr authentication in the login screen.")
            return
        }
        
        // Show loading state if needed
        isLoadingData = true
        
        Nostr1301Service.shared.syncWorkouts(for: credentials, since: nil) { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                self?.isLoadingData = false
                
                switch result {
                case .success(let workouts):
                    print("👤 Workouts Tab: Successfully synced \(workouts.count) workouts from Nostr")
                    // Trigger a full reload to get fresh data
                    self?.loadWorkoutHistory()
                    
                case .failure(let error):
                    print("👤 Workouts Tab: Nostr sync failed: \(error)")
                    self?.showComingSoonAlert(for: "Nostr", message: "Sync failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - ProfileSyncSourcesViewDelegate

extension ProfileWorkoutsTabView: ProfileSyncSourcesViewDelegate {
    func didTapSyncSource(_ source: String) {
        print("👤 Workouts Tab: Sync source tapped: \(source)")
        
        switch source {
        case "HealthKit":
            syncHealthKit()
            
        case "Nostr":
            syncNostr()
            
        case "Strava":
            // Show coming soon alert
            showComingSoonAlert(for: "Strava")
            
        case "Garmin":
            // Show coming soon alert
            showComingSoonAlert(for: "Garmin Connect")
            
        case "Google Fit":
            // Show coming soon alert
            showComingSoonAlert(for: "Google Fit")
            
        default:
            break
        }
    }
    
    private func showComingSoonAlert(for source: String) {
        showComingSoonAlert(for: source, message: "\(source) sync will be available soon!")
    }
    
    private func showComingSoonAlert(for source: String, message: String) {
        // Find the view controller
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                let alert = UIAlertController(
                    title: "\(source) Integration",
                    message: message,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(alert, animated: true)
                break
            }
            responder = responder?.next
        }
    }
}

// MARK: - WorkoutData Model

struct ProfileWorkoutData {
    let id: String
    let type: String
    let distance: Double // in meters
    let duration: TimeInterval
    let calories: Double
    let startedAt: Date
    let endedAt: Date
    let source: String
    
    static func fromHealthKitWorkout(_ workout: HealthKitWorkout) -> ProfileWorkoutData {
        return ProfileWorkoutData(
            id: workout.id,
            type: workout.activityType.displayName,
            distance: workout.totalDistance ?? 0.0,
            duration: workout.duration,
            calories: workout.totalEnergyBurned ?? 0.0,
            startedAt: workout.startDate,
            endedAt: workout.endDate,
            source: workout.syncSource.displayName
        )
    }
    
    var formattedDistance: String {
        let km = distance / 1000
        return String(format: "%.2f km", km)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    var formattedCalories: String {
        return String(format: "%.0f cal", calories)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: startedAt)
    }
    
}