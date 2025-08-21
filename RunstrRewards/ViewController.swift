import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = UIView()
    private let settingsButton = UIButton(type: .custom)
    
    // Wallet balance section (replaces logo)
    private let walletSection = UIView()
    private let walletBalanceLabel = UILabel()
    
    // Navigation grid
    private let navigationGrid = UIView()
    private var navigationCards: [NavigationCard] = []
    private var teamsCard: NavigationCard?  // Keep reference to update with team info
    
    // Stats bar removed - stats now integrated into navigation cards
    
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
        setupWalletSection()
        setupNavigationGrid()
        // setupStatsBar() removed
        setupConstraints()
        
        // Load real user data
        loadRealUserStats()
        
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
        
        // Refresh stats when returning to dashboard
        print("🏭 RUNSTR Rewards: Refreshing user stats on dashboard return")
        loadRealUserStats()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        print("🏭 Setting up industrial background")
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Removed grid pattern background to improve startup performance
        
        // Removed invisible rotating gears to improve startup performance
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
        
        // Settings button
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = IndustrialDesign.Colors.primaryText
        settingsButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        settingsButton.layer.cornerRadius = 20
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        headerView.addSubview(settingsButton)
        contentView.addSubview(headerView)
    }
    
    private func setupWalletSection() {
        walletSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Wallet balance display - don't set initial text to avoid overlap
        walletBalanceLabel.text = "" // Start empty, will be filled when wallet loads
        walletBalanceLabel.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        walletBalanceLabel.textAlignment = .center
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        walletSection.addSubview(walletBalanceLabel)
        contentView.addSubview(walletSection)
        
        // Add gradient to balance text
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.walletBalanceLabel)
        }
        
        // Make it tappable to navigate to wallet
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(walletSectionTapped))
        walletSection.addGestureRecognizer(tapGesture)
        walletSection.isUserInteractionEnabled = true
        
        // Development feature: Triple tap to generate app icons
        #if DEBUG
        let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tripleTapGesture.numberOfTapsRequired = 3
        walletSection.addGestureRecognizer(tripleTapGesture)
        #endif
    }
    
    private func setupNavigationGrid() {
        navigationGrid.translatesAutoresizingMaskIntoConstraints = false
        
        // Create navigation cards - 3 cards (Teams, Lottery, and Profile)
        let teamsCard = NavigationCard(
            title: "Teams",
            subtitle: "Join & Create",
            iconName: "person.3.fill",
            action: { [weak self] in
                self?.navigateToTeamsOrTeamDetail()
            }
        )
        self.teamsCard = teamsCard  // Store reference to update later
        
        // Lottery card - new feature
        let lotteryCard = NavigationCard(
            title: "RUNSTR REWARDS",
            subtitle: "Lottery",
            iconName: "ticket.fill",
            action: { [weak self] in
                print("🎰 RunstrRewards: Lottery card tapped")
                self?.navigateToLottery()
            }
        )
        
        let profileCard = NavigationCard(
            title: "Profile",
            subtitle: "your stats",
            iconName: "person.fill",
            action: { [weak self] in
                self?.navigateToProfile()
            }
        )
        
        navigationCards = [teamsCard, lotteryCard, profileCard]
        
        for card in navigationCards {
            card.translatesAutoresizingMaskIntoConstraints = false
            navigationGrid.addSubview(card)
        }
        
        contentView.addSubview(navigationGrid)
    }
    
    // setupStatsBar method removed - stats no longer displayed at bottom
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: IndustrialDesign.Spacing.xLarge),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            headerView.heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.avatarSize),
            
            // Settings button
            settingsButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Wallet section
            walletSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: IndustrialDesign.Spacing.xxxLarge),
            walletSection.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            walletSection.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            walletSection.heightAnchor.constraint(equalToConstant: 60),
            
            // Wallet balance text - centered in section
            walletBalanceLabel.centerXAnchor.constraint(equalTo: walletSection.centerXAnchor),
            walletBalanceLabel.centerYAnchor.constraint(equalTo: walletSection.centerYAnchor),
            
            // Navigation grid
            navigationGrid.topAnchor.constraint(equalTo: walletSection.bottomAnchor, constant: 60),
            navigationGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            navigationGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            navigationGrid.heightAnchor.constraint(equalToConstant: 460), // Increased for 3 cards
            
            // Navigation cards - 3 cards layout: Teams, Lottery, Profile (all full width)
            navigationCards[0].topAnchor.constraint(equalTo: navigationGrid.topAnchor),
            navigationCards[0].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[0].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[0].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[1].topAnchor.constraint(equalTo: navigationCards[0].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[1].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[1].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[1].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[2].topAnchor.constraint(equalTo: navigationCards[1].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[2].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[2].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[2].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            // Navigation grid is now the bottom element
            navigationGrid.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -IndustrialDesign.Spacing.xxxLarge)
        ])
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        let gradient = CAGradientLayer.logo()
        gradient.frame = label.bounds
        
        let gradientColor = UIColor { _ in
            return UIColor.white
        }
        label.textColor = gradientColor
        
        // Create a mask for the gradient
        let maskLayer = CATextLayer()
        maskLayer.string = label.text
        maskLayer.font = label.font
        maskLayer.fontSize = label.font.pointSize
        maskLayer.frame = label.bounds
        maskLayer.alignmentMode = .center
        maskLayer.foregroundColor = UIColor.black.cgColor
        
        gradient.mask = maskLayer
        label.layer.addSublayer(gradient)
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToTeamsOrTeamDetail() {
        if let activeTeam = userActiveTeam {
            // User has a team - show options to access team or discover new teams
            print("🏭 RUNSTR: User has team - showing navigation options")
            showTeamNavigationOptions(currentTeam: activeTeam)
        } else {
            // No team, go to teams list
            navigateToTeams()
        }
    }
    
    private func showTeamNavigationOptions(currentTeam: TeamData) {
        let actionSheet = UIAlertController(
            title: "Team Options",
            message: "Choose where you'd like to go",
            preferredStyle: .actionSheet
        )
        
        // Access current team
        actionSheet.addAction(UIAlertAction(title: "My Team: \(currentTeam.name)", style: .default) { _ in
            print("🏭 RUNSTR: Navigating to current team: \(currentTeam.name)")
            let teamDetailVC = TeamDetailViewController(teamData: currentTeam)
            self.navigationController?.pushViewController(teamDetailVC, animated: true)
        })
        
        // Discover more teams
        actionSheet.addAction(UIAlertAction(title: "Discover More Teams", style: .default) { _ in
            print("🏭 RUNSTR: Navigating to teams discovery")
            self.navigateToTeams()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true)
    }
    
    private func navigateToTeams() {
        print("🏭 RUNSTR: Teams navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ RUNSTR: NavigationController is nil - cannot navigate to Teams")
            return
        }
        
        let teamsViewController = TeamsViewController()
        navigationController.pushViewController(teamsViewController, animated: true)
        
        print("🏭 RunstrRewards: Successfully navigated to Teams page")
    }
    
    private func navigateToWallet() {
        print("💰 RunstrRewards: Wallet navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ RunstrRewards: NavigationController is nil - cannot navigate to Wallet")
            return
        }
        
        let earningsViewController = EarningsViewController()
        navigationController.pushViewController(earningsViewController, animated: true)
        
        print("💰 RunstrRewards: Successfully navigated to Wallet page")
    }
    
    private func navigateToProfile() {
        print("👤 RunstrRewards: Profile navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ RunstrRewards: NavigationController is nil - cannot navigate to Profile")
            return
        }
        
        // Navigate to WorkoutsViewController which contains user stats/profile info
        let workoutsViewController = WorkoutsViewController()
        navigationController.pushViewController(workoutsViewController, animated: true)
        
        print("👤 RunstrRewards: Successfully navigated to Profile/Workouts page")
    }
    
    private func navigateToLottery() {
        print("🎰 RunstrRewards: Lottery navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ RunstrRewards: NavigationController is nil - cannot navigate to Lottery")
            return
        }
        
        let lotteryViewController = LotteryComingSoonViewController()
        navigationController.pushViewController(lotteryViewController, animated: true)
        
        print("🎰 RunstrRewards: Successfully navigated to Lottery Coming Soon page")
    }
    
    private func navigateToWorkouts() {
        print("🏃‍♂️ RunstrRewards: Workouts navigation requested")
        navigateToProfile() // Redirect to profile method
    }
    
    @objc private func settingsButtonTapped() {
        print("⚙️ RunstrRewards: Settings navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ RunstrRewards: NavigationController is nil - cannot navigate to Settings")
            return
        }
        
        let settingsViewController = SettingsViewController()
        navigationController.pushViewController(settingsViewController, animated: true)
        
        print("⚙️ RunstrRewards: Successfully navigated to Settings page")
    }
    
    @objc private func walletSectionTapped() {
        print("💰 RunstrRewards: Wallet section tapped")
        navigateToWallet()
    }
    
    // Level League removed - competitions now handled by individual teams
    
    // MARK: - Development Features
    
    #if DEBUG
    @objc private func handleTripleTap() {
        print("🎨 RunstrRewards: Triple tap detected - generating icons and logos...")
        
        let alert = UIAlertController(
            title: "Generate Icons & Logos",
            message: "This will generate app icons and logo assets. Choose what to generate:",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "App Icons Only", style: .default) { _ in
            IconGenerator.generateAppIcons()
            
            let successAlert = UIAlertController(
                title: "App Icons Generated!",
                message: "App icons have been saved to Documents folder. Check the console for file paths.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Logo Assets Only", style: .default) { _ in
            IconGenerator.generateLogoAssets()
            
            let successAlert = UIAlertController(
                title: "Logo Assets Generated!",
                message: "Logo assets have been saved to Documents folder. Copy them to Assets.xcassets to fix logo display.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Both", style: .default) { _ in
            IconGenerator.generateAppIcons()
            IconGenerator.generateLogoAssets()
            
            let successAlert = UIAlertController(
                title: "All Assets Generated!",
                message: "App icons and logo assets have been saved to Documents folder. Check the console for file paths.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        
        present(alert, animated: true)
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Real Data Loading

extension ViewController {
    
    private func loadRealUserStats() {
        Task {
            await loadUserTeam()
            await loadWalletBalance()
        }
    }
    
    private func loadUserTeam() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 RUNSTR: No user session found for team loading")
                return
            }
            
            // Fetch user's teams from Supabase
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: userSession.id)
            
            if let firstTeam = teams.first {
                await MainActor.run {
                    self.userActiveTeam = TeamData(
                        id: firstTeam.id,
                        name: firstTeam.name,
                        captain: firstTeam.captainId,
                        captainId: firstTeam.captainId,
                        members: firstTeam.memberCount,
                        prizePool: String(format: "%.0f", firstTeam.totalEarnings),
                        activities: ["Running"],
                        isJoined: true
                    )
                    
                    // Update the Teams card to show the user's team
                    self.teamsCard?.updateTitle(firstTeam.name)
                    self.teamsCard?.updateSubtitle("Your Team")
                    self.teamsCard?.showBadge(true)
                    
                    print("🏭 RUNSTR: User is member of team: \(firstTeam.name)")
                }
            } else {
                await MainActor.run {
                    self.userActiveTeam = nil
                    self.teamsCard?.updateTitle("Teams")
                    self.teamsCard?.updateSubtitle("Join & Create")
                    self.teamsCard?.showBadge(false)
                    
                    print("🏭 RUNSTR: User has no teams")
                }
            }
        } catch {
            print("🏭 RUNSTR: Failed to load user team: \(error)")
        }
    }
    
    private func loadWalletBalance() async {
        // Check if user is authenticated before trying Lightning wallet
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("🏭 RunstrRewards: No user session found for wallet balance - showing default")
            await MainActor.run {
                walletBalanceLabel.text = "0 sats"
            }
            return
        }
        
        // Show loading state
        await MainActor.run {
            walletBalanceLabel.text = "Loading..."
            walletBalanceLabel.alpha = 0.5
        }
        
        // Try to get real Lightning wallet balance
        do {
            print("🏭 RunstrRewards: Loading real Lightning wallet balance for user: \(userSession.id)")
            let lightningWalletManager = LightningWalletManager.shared
            let balance = try await lightningWalletManager.getWalletBalance()
            
            await MainActor.run {
                // Use real Lightning balance (in sats)
                let totalSats = balance.lightning
                
                print("🏭 RunstrRewards: Raw Lightning balance: \(totalSats) sats")
                
                // Format as clean sats display
                let formattedBalance: String
                if totalSats == 0 {
                    formattedBalance = "0 sats"
                } else {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.groupingSeparator = ","
                    let formattedSats = formatter.string(from: NSNumber(value: totalSats)) ?? "\(totalSats)"
                    formattedBalance = "\(formattedSats) sats"
                }
                
                print("🏭 RunstrRewards: Setting wallet balance text to: '\(formattedBalance)'")
                walletBalanceLabel.text = formattedBalance
                walletBalanceLabel.alpha = 1.0 // Restore full opacity
                
                // Force layout update to ensure text changes are visible
                walletBalanceLabel.setNeedsLayout()
                walletBalanceLabel.layoutIfNeeded()
                walletSection.setNeedsLayout()
                walletSection.layoutIfNeeded()
                
                print("🏭 RunstrRewards: Wallet balance updated and layout refreshed")
            }
            
        } catch {
            print("🏭 RunstrRewards: Failed to load Lightning wallet balance: \(error)")
            
            await MainActor.run {
                walletBalanceLabel.text = "0 sats"
                walletBalanceLabel.alpha = 1.0 // Restore full opacity even on error
            }
        }
    }
    
    // Stats loading methods removed since stats bar is no longer displayed
    /*
    private func loadWorkoutStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 RunstrRewards: No user session found for workout stats")
                // ✅ Try to load HealthKit data as fallback
                await loadHealthKitWorkoutStats()
                return
            }
            
            // Fetch user's workouts from Supabase
            let workouts = try await SupabaseService.shared.fetchWorkouts(userId: userSession.id, limit: 1000)
            print("🏭 RunstrRewards: Fetched \(workouts.count) workouts from Supabase")
            
            await MainActor.run {
                let totalWorkouts = workouts.count
                workoutsStat.updateValue(totalWorkouts > 0 ? "\(totalWorkouts)" : "0")
                print("🏭 RunstrRewards: Updated workout stats: \(totalWorkouts) workouts")
            }
            
            // ✅ If no Supabase workouts but HealthKit is available, try HealthKit fallback
            if workouts.isEmpty {
                print("🏭 RunstrRewards: No Supabase workouts found, trying HealthKit fallback...")
                await loadHealthKitWorkoutStats()
            }
            
        } catch {
            print("🏭 RunstrRewards: Error loading Supabase workouts: \(error)")
            await MainActor.run {
                self.handleError(error, context: "loadWorkoutStats", showAlert: false)
            }
            // ✅ Try HealthKit as fallback on error
            await loadHealthKitWorkoutStats()
        }
    }
    
    // ✅ NEW: Fallback method to load HealthKit workout count directly
    private func loadHealthKitWorkoutStats() async {
        guard HealthKitService.shared.checkAuthorizationStatus() else {
            await MainActor.run {
                workoutsStat.updateValue("0")
            }
            return
        }
        
        do {
            // Fetch last 30 days of HealthKit workouts
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 200)
            
            await MainActor.run {
                let totalWorkouts = healthKitWorkouts.count
                workoutsStat.updateValue("\(totalWorkouts)")
                print("🏭 RunstrRewards: Updated workout stats from HealthKit: \(totalWorkouts) workouts")
            }
        } catch {
            print("🏭 RunstrRewards: Error loading HealthKit workouts: \(error)")
            await MainActor.run {
                workoutsStat.updateValue("0")
            }
        }
    }
    
    private func loadEarningsStats() async {
        // Check if user is authenticated before trying Lightning wallet
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("🏭 RunstrRewards: No user session found for Lightning wallet - using fallback")
            await loadHealthKitEarningsStats()
            return
        }
        
        // First try to get real Lightning wallet balance
        do {
            print("🏭 RunstrRewards: Loading real Lightning wallet balance for user: \(userSession.id)")
            let lightningWalletManager = LightningWalletManager.shared
            let balance = try await lightningWalletManager.getWalletBalance()
            
            await MainActor.run {
                // Use real Lightning balance (in sats)
                let totalSats = balance.lightning
                
                // Format as sats (clean integer display)
                let formattedEarnings: String
                if totalSats == 0 {
                    formattedEarnings = "0"
                } else {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.groupingSeparator = ","
                    formattedEarnings = formatter.string(from: NSNumber(value: totalSats)) ?? "\(totalSats)"
                }
                
                earningsStat.updateValue(formattedEarnings)
                print("🏭 RunstrRewards: Updated earnings stats with real Lightning balance: \(formattedEarnings) sats")
            }
            
        } catch {
            print("🏭 RunstrRewards: Failed to load Lightning wallet balance: \(error)")
            
            // Fallback: Try Supabase transactions if Lightning wallet fails
            do {
                guard let userSession = AuthenticationService.shared.loadSession() else {
                    print("🏭 RunstrRewards: No user session found for earnings fallback")
                    await loadHealthKitEarningsStats()
                    return
                }
                
                let transactions = try await SupabaseService.shared.fetchTransactions(userId: userSession.id, limit: 1000)
                print("🏭 RunstrRewards: Fetched \(transactions.count) transactions from Supabase as fallback")
                
                await MainActor.run {
                    let totalEarningsSats = transactions
                        .filter { $0.type == "earning" || $0.type == "reward" }
                        .reduce(0) { $0 + $1.amount }
                    
                    let formattedEarnings: String
                    if totalEarningsSats == 0 {
                        formattedEarnings = "0"
                    } else {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        formatter.groupingSeparator = ","
                        formattedEarnings = formatter.string(from: NSNumber(value: totalEarningsSats)) ?? "\(totalEarningsSats)"
                    }
                    
                    earningsStat.updateValue(formattedEarnings)
                    print("🏭 RunstrRewards: Updated earnings stats from Supabase fallback: \(formattedEarnings) sats")
                }
                
                if transactions.isEmpty {
                    await loadHealthKitEarningsStats()
                }
                
            } catch {
                print("🏭 RunstrRewards: Supabase fallback also failed: \(error)")
                await MainActor.run {
                    self.handleError(error, context: "loadEarningsStats", showAlert: false)
                }
                await loadHealthKitEarningsStats()
            }
        }
    }
    
    // ✅ NEW: Calculate estimated earnings from HealthKit workouts
    private func loadHealthKitEarningsStats() async {
        guard HealthKitService.shared.checkAuthorizationStatus() else {
            await MainActor.run {
                earningsStat.updateValue("0")
            }
            return
        }
        
        do {
            // Fetch last 30 days of HealthKit workouts
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(thirtyDaysAgo, limit: 200)
            
            await MainActor.run {
                // Calculate estimated earnings using WorkoutRewardCalculator
                var totalEstimatedSats = 0
                for workout in healthKitWorkouts {
                    let workoutReward = WorkoutRewardCalculator.shared.calculateReward(for: workout)
                    totalEstimatedSats += workoutReward.satsAmount
                }
                
                // Format as sats
                let formattedEarnings: String
                if totalEstimatedSats == 0 {
                    formattedEarnings = "0"
                } else {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.groupingSeparator = ","
                    formattedEarnings = formatter.string(from: NSNumber(value: totalEstimatedSats)) ?? "\(totalEstimatedSats)"
                }
                
                earningsStat.updateValue(formattedEarnings)
                print("🏭 RunstrRewards: Updated earnings stats from HealthKit: \(formattedEarnings) sats (\(totalEstimatedSats) total)")
            }
        } catch {
            print("🏭 RunstrRewards: Error calculating HealthKit earnings: \(error)")
            await MainActor.run {
                earningsStat.updateValue("0")
            }
        }
    }
    
    private func loadStreakStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 RunstrRewards: No user session found for streak stats")
                // ✅ Try to calculate streak from HealthKit workouts as fallback
                await loadHealthKitStreakStats()
                return
            }
            
            // Fetch user's recent workouts to calculate streak
            let workouts = try await SupabaseService.shared.fetchWorkouts(userId: userSession.id, limit: 100)
            print("🏭 RunstrRewards: Fetched \(workouts.count) workouts for streak calculation")
            
            await MainActor.run {
                let currentStreak = calculateCurrentStreak(from: workouts)
                streakStat.updateValue("\(currentStreak)")
                print("🏭 RunstrRewards: Updated streak stats: \(currentStreak) day streak")
            }
            
            // ✅ If no Supabase workouts, try HealthKit calculation
            if workouts.isEmpty {
                print("🏭 RunstrRewards: No Supabase workouts found, calculating streak from HealthKit...")
                await loadHealthKitStreakStats()
            }
            
        } catch {
            print("🏭 RunstrRewards: Error loading Supabase workouts for streak: \(error)")
            await MainActor.run {
                self.handleError(error, context: "loadStreakStats", showAlert: false)
            }
            // ✅ Try HealthKit as fallback on error
            await loadHealthKitStreakStats()
        }
    }
    
    // ✅ NEW: Calculate streak from HealthKit workouts
    private func loadHealthKitStreakStats() async {
        guard HealthKitService.shared.checkAuthorizationStatus() else {
            await MainActor.run {
                streakStat.updateValue("0")
            }
            return
        }
        
        do {
            // Fetch last 100 days of HealthKit workouts for streak calculation
            let hundredDaysAgo = Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date()
            let healthKitWorkouts = try await HealthKitService.shared.fetchWorkoutsSince(hundredDaysAgo, limit: 500)
            
            await MainActor.run {
                let currentStreak = calculateCurrentStreakFromHealthKit(from: healthKitWorkouts)
                streakStat.updateValue("\(currentStreak)")
                print("🏭 RunstrRewards: Updated streak stats from HealthKit: \(currentStreak) day streak")
            }
        } catch {
            print("🏭 RunstrRewards: Error calculating HealthKit streak: \(error)")
            await MainActor.run {
                streakStat.updateValue("0")
            }
        }
    }
    
    private func calculateCurrentStreak(from workouts: [Workout]) -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        // Sort workouts by date (most recent first)
        let sortedWorkouts = workouts.sorted { $0.startedAt > $1.startedAt }
        
        // Check if there's a workout today or yesterday (allow for time zones)
        let hasRecentWorkout = sortedWorkouts.contains { workout in
            let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: workout.startedAt), to: checkDate).day ?? 0
            return daysDifference >= 0 && daysDifference <= 1
        }
        
        if !hasRecentWorkout {
            return 0 // Streak is broken if no recent workout
        }
        
        // Count consecutive days with workouts
        while true {
            let hasWorkoutOnDate = sortedWorkouts.contains { workout in
                calendar.isDate(workout.startedAt, inSameDayAs: checkDate)
            }
            
            if hasWorkoutOnDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    // ✅ NEW: Calculate streak from HealthKit workouts
    private func calculateCurrentStreakFromHealthKit(from workouts: [HealthKitWorkout]) -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: now)
        
        // Sort workouts by date (most recent first)
        let sortedWorkouts = workouts.sorted { $0.startDate > $1.startDate }
        
        // Check if there's a workout today or yesterday (allow for time zones)
        let hasRecentWorkout = sortedWorkouts.contains { workout in
            let daysDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: workout.startDate), to: checkDate).day ?? 0
            return daysDifference >= 0 && daysDifference <= 1
        }
        
        if !hasRecentWorkout {
            return 0 // Streak is broken if no recent workout
        }
        
        // Count consecutive days with workouts
        while true {
            let hasWorkoutOnDate = sortedWorkouts.contains { workout in
                calendar.isDate(workout.startDate, inSameDayAs: checkDate)
            }
            
            if hasWorkoutOnDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    */
    
    func refreshUserStats() {
        // Public method to refresh stats when returning to main dashboard
        loadRealUserStats()
    }
    
    @objc private func handleTeamCreated() {
        print("🏭 RUNSTR: Team creation notification received - refreshing user team data")
        Task {
            await loadUserTeam()
        }
    }
}