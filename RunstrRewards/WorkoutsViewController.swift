import UIKit
import HealthKit

enum WorkoutTab {
    case sync
    case stats 
    
    var title: String {
        switch self {
        case .sync: return "SYNC"
        case .stats: return "STATS"
        }
    }
}

protocol WorkoutsHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapSyncButton()
}

class WorkoutsViewController: UIViewController {
    
    // MARK: - Properties
    private var currentTab: WorkoutTab = .sync
    private var healthKitWorkouts: [HealthKitWorkout] = []
    private var isSyncing = false
    private var isLoadingInitialData = false
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let pageTitleLabel = UILabel()
    private let syncButton = UIButton(type: .custom)
    private let tabNavigationView = WorkoutTabNavigationView()
    private let contentContainerView = UIView()
    
    // Tab Content Views
    private let syncView = WorkoutSyncView()
    private let statsView = WorkoutStatsView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏃‍♂️ RunstrRewards: Loading workouts page...")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupHeader()
        setupTabNavigation()
        setupContentArea()
        setupConstraints()
        
        // Load sync sources UI
        syncView.loadSyncSources()
        
        switchToTab(.sync)
        
        // Check HealthKit authorization on load
        checkHealthKitAuthorization()
        
        // Setup background sync observer
        setupBackgroundSync()
        
        print("🏃‍♂️ RunstrRewards: Workouts loaded successfully!")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        // Add rotating gears
        let gear1 = RotatingGearView(size: 200)
        gear1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear1)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            gear1.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.clear
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Page title
        pageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageTitleLabel.text = "Workouts"
        pageTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        pageTitleLabel.textAlignment = .center
        
        // Create gradient for title
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.white.cgColor,
            IndustrialDesign.Colors.secondaryText.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        
        pageTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Sync button
        syncButton.translatesAutoresizingMaskIntoConstraints = false
        syncButton.setTitle("SYNC", for: .normal)
        syncButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        syncButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        syncButton.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        syncButton.layer.borderWidth = 1
        syncButton.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        syncButton.layer.cornerRadius = 6
        syncButton.addTarget(self, action: #selector(syncButtonTapped), for: .touchUpInside)
        
        // Add sync icon
        let syncIcon = UIImageView(image: UIImage(systemName: "arrow.clockwise"))
        syncIcon.translatesAutoresizingMaskIntoConstraints = false
        syncIcon.tintColor = IndustrialDesign.Colors.primaryText
        syncIcon.contentMode = .scaleAspectFit
        
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(pageTitleLabel)
        headerView.addSubview(syncButton)
        syncButton.addSubview(syncIcon)
        
        NSLayoutConstraint.activate([
            // Sync icon inside sync button
            syncIcon.leadingAnchor.constraint(equalTo: syncButton.leadingAnchor, constant: 8),
            syncIcon.centerYAnchor.constraint(equalTo: syncButton.centerYAnchor),
            syncIcon.widthAnchor.constraint(equalToConstant: 16),
            syncIcon.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        setupSyncButtonHoverEffects()
    }
    
    private func setupSyncButtonHoverEffects() {
        syncButton.addTarget(self, action: #selector(syncButtonPressed), for: .touchDown)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchUpInside)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchUpOutside)
        syncButton.addTarget(self, action: #selector(syncButtonReleased), for: .touchCancel)
    }
    
    private func setupTabNavigation() {
        tabNavigationView.translatesAutoresizingMaskIntoConstraints = false
        tabNavigationView.delegate = self
        tabNavigationView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        view.addSubview(tabNavigationView)
    }
    
    private func setupContentArea() {
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        // Setup individual views
        syncView.translatesAutoresizingMaskIntoConstraints = false
        statsView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(contentContainerView)
        contentContainerView.addSubview(syncView)
        contentContainerView.addSubview(statsView)
        
        // Hide all views initially
        syncView.isHidden = true
        statsView.isHidden = true
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Back button
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Page title
            pageTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            pageTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Sync button
            syncButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -24),
            syncButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            syncButton.widthAnchor.constraint(equalToConstant: 80),
            syncButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Tab navigation
            tabNavigationView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabNavigationView.heightAnchor.constraint(equalToConstant: 50),
            
            // Content container
            contentContainerView.topAnchor.constraint(equalTo: tabNavigationView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content views - all fill the container
            syncView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            syncView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            syncView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            syncView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            
            statsView.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            statsView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            statsView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            statsView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Tab Management
    
    private func switchToTab(_ tab: WorkoutTab) {
        currentTab = tab
        
        // Hide all views
        syncView.isHidden = true
        statsView.isHidden = true
        
        // Show selected view with real data
        switch tab {
        case .sync:
            syncView.isHidden = false
            syncView.updateWithHealthKitWorkouts(healthKitWorkouts)
        case .stats:
            statsView.isHidden = false
            statsView.updateWithHealthKitWorkouts(healthKitWorkouts)
        }
        
        // Update tab navigation
        tabNavigationView.selectTab(tab)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🏃‍♂️ RunstrRewards: Workouts back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func syncButtonTapped() {
        print("🏃‍♂️ RunstrRewards: Sync button tapped")
        
        guard !isSyncing else { return }
        
        syncWorkouts()
    }
    
    @objc private func syncButtonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.syncButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.syncButton.alpha = 0.8
        }
    }
    
    @objc private func syncButtonReleased() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.syncButton.transform = .identity
            self.syncButton.alpha = 1.0
        }
    }
    
    private func showSyncAnimation() {
        guard let syncIcon = syncButton.subviews.first(where: { $0 is UIImageView }) else { return }
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = 2
        rotation.isRemovedOnCompletion = true
        
        syncIcon.layer.add(rotation, forKey: "syncRotation")
    }
}

// MARK: - HealthKit Integration

extension WorkoutsViewController {
    
    private func checkHealthKitAuthorization() {
        let isAuthorized = HealthKitService.shared.checkAuthorizationStatus()
        print("🏃‍♂️ RunstrRewards: HealthKit authorization status: \(isAuthorized)")
        
        if isAuthorized {
            print("🏃‍♂️ RunstrRewards: HealthKit already authorized")
            // ✅ Sync authorization status with UI
            syncView.updateHealthKitConnectionStatus(connected: true)
            loadInitialWorkouts()
        } else {
            print("🏃‍♂️ RunstrRewards: HealthKit not authorized, requesting permission...")
            // ✅ Ensure UI shows disconnected state
            syncView.updateHealthKitConnectionStatus(connected: false)
            Task {
                await requestHealthKitAuthorization()
            }
        }
    }
    
    private func requestHealthKitAuthorization() async {
        do {
            let authorized = try await HealthKitService.shared.requestAuthorization()
            
            await MainActor.run {
                if authorized {
                    print("🏃‍♂️ RunstrRewards: HealthKit authorization granted")
                    self.loadInitialWorkouts()
                    self.syncView.updateHealthKitConnectionStatus(connected: true)
                } else {
                    print("🏃‍♂️ RunstrRewards: HealthKit authorization denied")
                    self.showHealthKitPermissionAlert()
                }
            }
        } catch {
            await MainActor.run {
                print("🏃‍♂️ RunstrRewards: HealthKit authorization error: \(error)")
                self.showHealthKitError(error)
            }
        }
    }
    
    private func syncWorkouts() {
        guard !isSyncing else { return }
        
        isSyncing = true
        showSyncAnimation()
        
        Task {
            do {
                // Check authorization first
                if !HealthKitService.shared.checkAuthorizationStatus() {
                    await requestHealthKitAuthorization()
                    await MainActor.run {
                        self.isSyncing = false
                    }
                    return
                }
                
                // Fetch last 30 days of workouts from HealthKit for comprehensive sync
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 200)
                print("🏃‍♂️ RunstrRewards: Fetched \(healthKitWorkouts.count) workouts from last 30 days")
                
                // ✅ Add simulator-specific debugging
                #if targetEnvironment(simulator)
                if healthKitWorkouts.isEmpty {
                    print("⚠️ RunstrRewards: SIMULATOR DETECTED - No health data found. This is normal for iOS Simulator.")
                    print("💡 RunstrRewards: To test with data: Health app > Browse > Activity > Add Data")
                }
                #endif
                
                // Sync workouts to Supabase if user is authenticated
                if let userSession = AuthenticationService.shared.loadSession() {
                    for healthKitWorkout in healthKitWorkouts {
                        let supabaseWorkout = HealthKitService.shared.convertToSupabaseWorkout(healthKitWorkout, userId: userSession.id)
                        
                        do {
                            try await SupabaseService.shared.syncWorkout(supabaseWorkout)
                            print("🏃‍♂️ RunstrRewards: Synced workout \(supabaseWorkout.id) to Supabase")
                        } catch {
                            print("🏃‍♂️ RunstrRewards: Failed to sync workout \(supabaseWorkout.id): \(error)")
                        }
                    }
                }
                
                await MainActor.run {
                    self.healthKitWorkouts = healthKitWorkouts
                    self.updateWorkoutViews()
                    self.isSyncing = false
                    
                    // Show success feedback with better messaging
                    if healthKitWorkouts.count > 0 {
                        self.showSyncSuccessToast(count: healthKitWorkouts.count)
                    } else {
                        #if targetEnvironment(simulator)
                        self.showSyncSuccessToast(message: "Sync complete - no data found (Simulator)")
                        #else
                        self.showSyncSuccessToast(message: "Sync complete - no workouts found in last 30 days")
                        #endif
                    }
                }
                
            } catch {
                await MainActor.run {
                    print("🏃‍♂️ RunstrRewards: Sync error: \(error)")
                    self.showSyncError(error)
                    self.isSyncing = false
                }
            }
        }
    }
    
    private func loadInitialWorkouts() {
        guard !isLoadingInitialData else { return }
        
        isLoadingInitialData = true
        showInitialLoadingState()
        
        Task {
            do {
                // Load last 30 days of workouts on initial load
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 200)
                
                await MainActor.run {
                    self.healthKitWorkouts = healthKitWorkouts
                    self.updateWorkoutViews()
                    self.hideInitialLoadingState()
                    self.isLoadingInitialData = false
                    print("🏃‍♂️ RunstrRewards: Loaded \(healthKitWorkouts.count) initial workouts from last 30 days")
                }
            } catch {
                await MainActor.run {
                    print("🏃‍♂️ RunstrRewards: Failed to load initial workouts: \(error)")
                    self.showInitialLoadingError(error)
                    self.hideInitialLoadingState()
                    self.isLoadingInitialData = false
                }
            }
        }
    }
    
    private func showInitialLoadingState() {
        // Update sync button to show loading
        syncButton.setTitle("LOADING", for: .normal)
        syncButton.isEnabled = false
        syncButton.alpha = 0.6
        
        // Show loading in current tab
        if currentTab == .sync {
            syncView.showLoadingState()
        } else if currentTab == .stats {
            statsView.showLoadingState()
        }
    }
    
    private func hideInitialLoadingState() {
        // Restore sync button
        syncButton.setTitle("SYNC", for: .normal)
        syncButton.isEnabled = true
        syncButton.alpha = 1.0
        
        // Hide loading in views
        syncView.hideLoadingState()
        statsView.hideLoadingState()
    }
    
    private func showInitialLoadingError(_ error: Error) {
        let alert = UIAlertController(
            title: "Loading Error",
            message: "Failed to load initial workouts: \(error.localizedDescription)\n\nYou can still use the SYNC button to manually load workouts.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func updateWorkoutViews() {
        // Update sync view with real workout data
        syncView.updateWithHealthKitWorkouts(healthKitWorkouts)
        
        // Update stats view with real data
        statsView.updateWithHealthKitWorkouts(healthKitWorkouts)
    }
    
    private func showHealthKitPermissionAlert() {
        let alert = UIAlertController(
            title: "Health Access Required",
            message: "RunstrRewards needs access to your health data to sync workouts and calculate rewards. You can grant permission in Settings > Privacy & Security > Health.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showHealthKitError(_ error: Error) {
        let alert = UIAlertController(
            title: "HealthKit Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSyncError(_ error: Error) {
        let alert = UIAlertController(
            title: "Sync Error",
            message: "Failed to sync workouts: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSyncSuccessToast(count: Int) {
        let message = "Synced \(count) workouts from last 30 days!"
        showSyncSuccessToast(message: message)
    }
    
    private func showSyncSuccessToast(message: String) {
        // Create a toast notification matching app theme
        let toastLabel = UILabel()
        toastLabel.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.9)
        toastLabel.textColor = IndustrialDesign.Colors.primaryText
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 12
        toastLabel.layer.borderWidth = 1
        toastLabel.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.numberOfLines = 2
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            toastLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.5, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: [], animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    private func setupBackgroundSync() {
        // Enable background delivery for automatic workout sync
        Task {
            do {
                if HealthKitService.shared.checkAuthorizationStatus() {
                    try await HealthKitService.shared.enableBackgroundDelivery()
                    
                    // Setup observer for new workouts
                    HealthKitService.shared.observeWorkouts { [weak self] newWorkouts in
                        guard let self = self else { return }
                        
                        print("🏃‍♂️ RunstrRewards: Detected \(newWorkouts.count) new workouts from background sync")
                        
                        Task {
                            // Auto-sync new workouts to Supabase
                            if let userSession = AuthenticationService.shared.loadSession() {
                                for workout in newWorkouts {
                                    let supabaseWorkout = HealthKitService.shared.convertToSupabaseWorkout(workout, userId: userSession.id)
                                    
                                    do {
                                        try await SupabaseService.shared.syncWorkout(supabaseWorkout)
                                        print("🏃‍♂️ RunstrRewards: Auto-synced workout \(supabaseWorkout.id)")
                                    } catch {
                                        print("🏃‍♂️ RunstrRewards: Failed to auto-sync workout: \(error)")
                                    }
                                }
                            }
                            
                            await MainActor.run {
                                // Update local data and UI
                                self.healthKitWorkouts = newWorkouts + self.healthKitWorkouts
                                self.updateWorkoutViews()
                                
                                // Show subtle notification about new workouts
                                if newWorkouts.count > 0 {
                                    self.showNewWorkoutsNotification(count: newWorkouts.count)
                                }
                            }
                        }
                    }
                }
            } catch {
                print("🏃‍♂️ RunstrRewards: Failed to setup background sync: \(error)")
            }
        }
    }
    
    private func showNewWorkoutsNotification(count: Int) {
        let message = "🏃‍♂️ \(count) new workout\(count > 1 ? "s" : "") synced"
        
        // Create a subtle notification
        let notificationView = UIView()
        notificationView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        notificationView.layer.cornerRadius = 16
        notificationView.alpha = 0.0
        notificationView.translatesAutoresizingMaskIntoConstraints = false
        
        let notificationLabel = UILabel()
        notificationLabel.text = message
        notificationLabel.textColor = UIColor.white
        notificationLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        notificationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        notificationView.addSubview(notificationLabel)
        view.addSubview(notificationView)
        
        NSLayoutConstraint.activate([
            notificationLabel.centerXAnchor.constraint(equalTo: notificationView.centerXAnchor),
            notificationLabel.centerYAnchor.constraint(equalTo: notificationView.centerYAnchor),
            notificationLabel.leadingAnchor.constraint(equalTo: notificationView.leadingAnchor, constant: 12),
            notificationLabel.trailingAnchor.constraint(equalTo: notificationView.trailingAnchor, constant: -12),
            
            notificationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            notificationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            notificationView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Animate notification
        UIView.animate(withDuration: 0.3, animations: {
            notificationView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                notificationView.alpha = 0.0
            }) { _ in
                notificationView.removeFromSuperview()
            }
        }
    }
    
}

// MARK: - WorkoutTabNavigationViewDelegate

extension WorkoutsViewController: WorkoutTabNavigationViewDelegate {
    func didSelectTab(_ tab: WorkoutTab) {
        print("🏃‍♂️ RunstrRewards: Selected tab: \(tab)")
        switchToTab(tab)
    }
}