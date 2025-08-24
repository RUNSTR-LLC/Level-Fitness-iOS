import UIKit
import HealthKit

class ProfileWorkoutsTabView: UIView {
    
    // MARK: - UI Components
    private let syncSourcesView = ProfileSyncSourcesView()
    private let workoutHistoryView = ProfileWorkoutHistoryView()
    private let spacing: CGFloat = 24
    
    // MARK: - Properties
    private var isLoadingData = false
    
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
        
        // Load workout history
        loadWorkoutHistory()
    }
    
    // MARK: - Private Methods
    
    private func loadWorkoutHistory() {
        Task {
            do {
                // Fetch last 30 days of workouts
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 20)
                
                print("👤 Workouts Tab: Loaded \(healthKitWorkouts.count) workouts")
                
                // Convert to workout data for display
                let workoutData = healthKitWorkouts.map { workout in
                    return ProfileWorkoutData(
                        id: workout.id,
                        type: workout.workoutType,
                        distance: workout.totalDistance,
                        duration: workout.duration,
                        calories: workout.totalEnergyBurned,
                        startedAt: workout.startDate,
                        endedAt: workout.endDate,
                        source: workout.source,
                        satsEarned: WorkoutRewardCalculator.shared.calculateReward(for: workout).satsAmount
                    )
                }
                
                await MainActor.run {
                    self.workoutHistoryView.updateWorkouts(workoutData)
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
}

// MARK: - ProfileSyncSourcesViewDelegate

extension ProfileWorkoutsTabView: ProfileSyncSourcesViewDelegate {
    func didTapSyncSource(_ source: String) {
        print("👤 Workouts Tab: Sync source tapped: \(source)")
        
        switch source {
        case "HealthKit":
            syncHealthKit()
            
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
        // Find the view controller
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                let alert = UIAlertController(
                    title: "\(source) Integration",
                    message: "\(source) sync will be available soon!",
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
    let satsEarned: Int
    
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
    
    var formattedSats: String {
        return "₿ \(satsEarned) sats"
    }
}