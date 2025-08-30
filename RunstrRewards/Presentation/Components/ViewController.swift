import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = UIView()
    
    // Profile section (top position)
    private let profileSectionView = ProfileSectionView()
    
    // Wallet balance section
    private let walletSectionView = WalletSectionView()
    
    // Navigation grid
    private let navigationGrid = UIView()
    private var navigationCards: [NavigationCard] = []
    private var teamsCard: NavigationCard?  // Keep reference to update with team info
    
    // Notification toggles section
    private let notificationTogglesView = NotificationTogglesView()
    
    // Services
    private lazy var dataService: MainDashboardDataService = {
        let service = MainDashboardDataService.shared
        service.delegate = self
        return service
    }()
    
    private let navigationService = MainDashboardNavigationService.shared
    
    // User's active team
    private var userActiveTeam: TeamData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏭 RUNSTR Rewards: Loading industrial UI...")
        
        // Hide navigation bar for main dashboard
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupProfileSection()
        setupWalletSection()
        setupNavigationGrid()
        setupNotificationToggles()
        setupConstraints()
        
        // Load real user data
        dataService.loadRealUserStats()
        
        // Migrate profile data if needed (one-time operation for existing users)
        Task {
            await AuthenticationService.shared.migrateProfileToSupabaseIfNeeded()
        }
        
        // Listen for team creation notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTeamCreated),
            name: .teamCreated,
            object: nil
        )
        
        print("🏭 RUNSTR Rewards: Industrial UI loaded successfully!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh stats when returning to dashboard (but skip wallet balance to prevent duplicates)
        print("🏭 RUNSTR Rewards: Refreshing user stats on dashboard return")
        
        // Refresh profile section to show any profile updates
        profileSectionView.refreshProfile()
        
        // Update notification badge count
        updateNotificationBadge()
        
        Task {
            await dataService.loadUserTeam() // Only reload team data, not wallet balance
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        print("🏭 Setting up industrial background")
        view.backgroundColor = IndustrialDesign.Colors.background
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
    }
    
    private func setupProfileSection() {
        profileSectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileSectionView)
    }
    
    private func setupWalletSection() {
        walletSectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(walletSectionView)
        
        // Setup wallet delegate
        walletSectionView.delegate = self
    }
    
    private func setupNavigationGrid() {
        navigationGrid.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(navigationGrid)
        
        // Create navigation cards
        createNavigationCards()
    }
    
    private func createNavigationCards() {
        // Teams card
        let teamsCard = NavigationCard(
            title: "My Teams",
            subtitle: "Join team competitions",
            iconName: "person.3",
            action: { [weak self] in
                self?.navigationService.navigateToTeamsOrTeamDetail(userActiveTeam: self?.userActiveTeam, from: self!)
            }
        )
        self.teamsCard = teamsCard
        
        // Workouts card
        let workoutsCard = NavigationCard(
            title: "Workouts",
            subtitle: "Track your fitness",
            iconName: "figure.run",
            action: { [weak self] in
                self?.navigationService.navigateToWorkouts(from: self!)
            }
        )
        
        // Profile card
        let profileCard = NavigationCard(
            title: "Profile",
            subtitle: "Manage account",
            iconName: "person.circle",
            action: { [weak self] in
                self?.navigationService.navigateToProfile(from: self!)
            }
        )
        
        // Notifications card
        let notificationsCard = NavigationCard(
            title: "Notifications",
            subtitle: "Stay updated",
            iconName: "bell",
            action: { [weak self] in
                self?.navigationService.navigateToNotifications(from: self!)
            }
        )
        
        navigationCards = [teamsCard, workoutsCard, profileCard, notificationsCard]
        
        // Add cards to grid
        for card in navigationCards {
            card.translatesAutoresizingMaskIntoConstraints = false
            navigationGrid.addSubview(card)
        }
    }
    
    private func setupNotificationToggles() {
        notificationTogglesView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(notificationTogglesView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Profile section
            profileSectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            profileSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Wallet section
            walletSectionView.topAnchor.constraint(equalTo: profileSectionView.bottomAnchor, constant: 16),
            walletSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            walletSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Navigation grid
            navigationGrid.topAnchor.constraint(equalTo: walletSectionView.bottomAnchor, constant: 20),
            navigationGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            navigationGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            navigationGrid.heightAnchor.constraint(equalToConstant: 200),
            
            // Notification toggles
            notificationTogglesView.topAnchor.constraint(equalTo: navigationGrid.bottomAnchor, constant: 20),
            notificationTogglesView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            notificationTogglesView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            notificationTogglesView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Navigation cards grid layout
        for (index, card) in navigationCards.enumerated() {
            let row = index / 2
            let col = index % 2
            
            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: navigationGrid.topAnchor, constant: CGFloat(row * 100)),
                card.leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor, constant: CGFloat(col * 170)),
                card.widthAnchor.constraint(equalToConstant: 160),
                card.heightAnchor.constraint(equalToConstant: 80)
            ])
        }
    }
    
    // MARK: - Notification Methods
    
    @objc private func handleTeamCreated() {
        Task {
            await dataService.loadUserTeam()
        }
    }
    
    private func updateNotificationBadge() {
        Task {
            guard let userId = AuthenticationService.shared.currentUserId else { return }
            do {
                let unreadCount = try await NotificationInboxService.shared.getUnreadCount(for: userId)
                await MainActor.run {
                    // Find notifications card and update badge
                    for card in navigationCards {
                        if card.title == "Notifications" {
                            card.setBadgeCount(unreadCount)
                        }
                    }
                }
            } catch {
                print("Failed to update notification badge: \(error)")
            }
        }
    }
    
    // MARK: - Triple Tap Gesture
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

// MARK: - MainDashboardDataDelegate

extension ViewController: MainDashboardDataDelegate {
    
    func didLoadUserTeam(_ team: TeamData?) {
        userActiveTeam = team
        
        if let team = team {
            teamsCard?.updateSubtitle("\(team.members) members")
        } else {
            teamsCard?.updateSubtitle("Find your team")
        }
    }
    
    func didFailToLoadUserTeam(_ error: Error) {
        print("🏭 RUNSTR: Failed to load user team: \(error)")
    }
    
    func didLoadWalletBalance(_ balance: Int) {
        let balanceText = formatBitcoinBalance(balance)
        walletSectionView.updateBalance(balanceText)
    }
    
    func didFailToLoadWalletBalance(_ error: Error) {
        print("🏭 RUNSTR: Failed to load wallet balance: \(error)")
        walletSectionView.updateBalance("₿0.00000000")
    }
    
    private func formatBitcoinBalance(_ sats: Int) -> String {
        let btc = Double(sats) / 100_000_000.0
        return "₿\(String(format: "%.8f", btc))"
    }
    
    func didLoadWorkoutStats(weeklyCount: Int, totalCalories: Int) {
        // Update workouts card with stats
        for card in navigationCards {
            if card.title == "Workouts" {
                card.updateSubtitle("\(weeklyCount) this week")
            }
        }
    }
    
    func didFailToLoadWorkoutStats(_ error: Error) {
        print("🏭 RUNSTR: Failed to load workout stats: \(error)")
    }
    
    func didLoadHealthKitWorkoutStats(weeklyCount: Int, totalCalories: Int) {
        // Fallback stats display
        for card in navigationCards {
            if card.title == "Workouts" {
                card.updateSubtitle("\(weeklyCount) this week")
            }
        }
    }
}

// MARK: - WalletSectionViewDelegate

extension ViewController: WalletSectionViewDelegate {
    func didTapSendButton() {
        // Handle send button tap
        print("🏭 RUNSTR: Send button tapped")
    }
    
    func didTapReceiveButton() {
        // Handle receive button tap
        print("🏭 RUNSTR: Receive button tapped")
    }
    
    func didTapWalletSection() {
        navigationService.navigateToWallet(from: self)
    }
}