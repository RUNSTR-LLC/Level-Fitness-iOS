import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = UIView()
    private let settingsButton = UIButton(type: .custom)
    
    // Logo section
    private let logoSection = UIView()
    private let logoImageView = UIImageView()
    private let logoLabel = UILabel()
    private let taglineLabel = UILabel()
    
    // Navigation grid
    private let navigationGrid = UIView()
    private var navigationCards: [NavigationCard] = []
    
    // Stats bar
    private let statsBar = UIView()
    private let workoutsStat = StatItem(value: "0", label: "Workouts")
    private let earningsStat = StatItem(value: "0.0000", label: "Earned", isBitcoin: true)
    private let streakStat = StatItem(value: "0", label: "Streak")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏭 LevelFitness: Loading industrial UI...")
        
        // Hide navigation bar for main dashboard
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupLogo()
        setupNavigationGrid()
        setupStatsBar()
        setupConstraints()
        
        // Load real user data
        loadRealUserStats()
        
        print("🏭 LevelFitness: Industrial UI loaded successfully!")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh stats when returning to dashboard
        print("🏭 LevelFitness: Refreshing user stats on dashboard return")
        loadRealUserStats()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        print("🏭 Setting up industrial background")
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add rotating gear background elements
        let gear1 = RotatingGearView(size: 200)
        let gear2 = RotatingGearView(size: 300)
        
        gear1.translatesAutoresizingMaskIntoConstraints = false
        gear2.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(gear1)
        view.addSubview(gear2)
        
        NSLayoutConstraint.activate([
            gear1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200),
            
            gear2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            gear2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -100),
            gear2.widthAnchor.constraint(equalToConstant: 300),
            gear2.heightAnchor.constraint(equalToConstant: 300)
        ])
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
    
    private func setupLogo() {
        logoSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo text with gradient - larger and more prominent
        logoLabel.text = "Level Fitness"
        logoLabel.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Tagline
        taglineLabel.text = "compete to earn"
        taglineLabel.font = IndustrialDesign.Typography.taglineFont
        taglineLabel.textColor = IndustrialDesign.Colors.secondaryText
        taglineLabel.textAlignment = .center
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        logoSection.addSubview(logoLabel)
        logoSection.addSubview(taglineLabel)
        contentView.addSubview(logoSection)
        
        // Add gradient to logo text
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.logoLabel)
        }
        
        // Development feature: Triple tap to generate app icons
        #if DEBUG
        let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTripleTap))
        tripleTapGesture.numberOfTapsRequired = 3
        logoSection.addGestureRecognizer(tripleTapGesture)
        logoSection.isUserInteractionEnabled = true
        #endif
    }
    
    private func setupNavigationGrid() {
        navigationGrid.translatesAutoresizingMaskIntoConstraints = false
        
        // Create navigation cards
        let teamsCard = NavigationCard(
            title: "Teams",
            subtitle: "Join & Create",
            iconName: "person.3.fill",
            action: { [weak self] in
                self?.navigateToTeams()
            }
        )
        
        let walletCard = NavigationCard(
            title: "Wallet",
            subtitle: "bitcoin earnings",
            iconName: "bitcoinsign.circle.fill",
            action: { [weak self] in
                self?.navigateToWallet()
            }
        )
        
        // Remove Level League - teams handle their own competitions now
        
        let workoutsCard = NavigationCard(
            title: "Stats",
            subtitle: "sync workouts",
            iconName: "chart.bar.fill",
            action: { [weak self] in
                self?.navigateToWorkouts()
            }
        )
        
        navigationCards = [teamsCard, walletCard, workoutsCard]
        
        for card in navigationCards {
            card.translatesAutoresizingMaskIntoConstraints = false
            navigationGrid.addSubview(card)
        }
        
        contentView.addSubview(navigationGrid)
    }
    
    private func setupStatsBar() {
        statsBar.translatesAutoresizingMaskIntoConstraints = false
        statsBar.backgroundColor = IndustrialDesign.Colors.background
        
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 1)
        statsBar.layer.addSublayer(borderLayer)
        
        workoutsStat.translatesAutoresizingMaskIntoConstraints = false
        earningsStat.translatesAutoresizingMaskIntoConstraints = false
        streakStat.translatesAutoresizingMaskIntoConstraints = false
        
        statsBar.addSubview(workoutsStat)
        statsBar.addSubview(earningsStat)
        statsBar.addSubview(streakStat)
        
        contentView.addSubview(statsBar)
    }
    
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
            
            
            
            // Logo section
            logoSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: IndustrialDesign.Spacing.xxxLarge),
            logoSection.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoSection.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            // Logo text - now at the top
            logoLabel.topAnchor.constraint(equalTo: logoSection.topAnchor),
            logoLabel.centerXAnchor.constraint(equalTo: logoSection.centerXAnchor),
            
            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: IndustrialDesign.Spacing.small),
            taglineLabel.centerXAnchor.constraint(equalTo: logoSection.centerXAnchor),
            taglineLabel.bottomAnchor.constraint(equalTo: logoSection.bottomAnchor),
            
            // Navigation grid
            navigationGrid.topAnchor.constraint(equalTo: logoSection.bottomAnchor, constant: 60),
            navigationGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            navigationGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            navigationGrid.heightAnchor.constraint(equalToConstant: 260),
            
            // Navigation cards - 3 cards layout: Teams (full width), Wallet + Stats (half width each)
            navigationCards[0].topAnchor.constraint(equalTo: navigationGrid.topAnchor),
            navigationCards[0].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[0].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[0].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[1].topAnchor.constraint(equalTo: navigationCards[0].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[1].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[1].trailingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: -10),
            navigationCards[1].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[2].topAnchor.constraint(equalTo: navigationCards[0].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[2].leadingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: 10),
            navigationCards[2].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[2].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            // Stats bar
            statsBar.topAnchor.constraint(equalTo: navigationGrid.bottomAnchor, constant: IndustrialDesign.Spacing.xxxLarge),
            statsBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statsBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            statsBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            statsBar.heightAnchor.constraint(equalToConstant: 100),
            
            // Stats items
            workoutsStat.centerYAnchor.constraint(equalTo: statsBar.centerYAnchor),
            workoutsStat.leadingAnchor.constraint(equalTo: statsBar.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            workoutsStat.widthAnchor.constraint(equalTo: statsBar.widthAnchor, multiplier: 0.25),
            
            earningsStat.centerYAnchor.constraint(equalTo: statsBar.centerYAnchor),
            earningsStat.centerXAnchor.constraint(equalTo: statsBar.centerXAnchor),
            earningsStat.widthAnchor.constraint(equalTo: statsBar.widthAnchor, multiplier: 0.25),
            
            streakStat.centerYAnchor.constraint(equalTo: statsBar.centerYAnchor),
            streakStat.trailingAnchor.constraint(equalTo: statsBar.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            streakStat.widthAnchor.constraint(equalTo: statsBar.widthAnchor, multiplier: 0.25)
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
    
    private func navigateToTeams() {
        print("🏭 LevelFitness: Teams navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ LevelFitness: NavigationController is nil - cannot navigate to Teams")
            return
        }
        
        let teamsViewController = TeamsViewController()
        navigationController.pushViewController(teamsViewController, animated: true)
        
        print("🏭 LevelFitness: Successfully navigated to Teams page")
    }
    
    private func navigateToWallet() {
        print("💰 LevelFitness: Wallet navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ LevelFitness: NavigationController is nil - cannot navigate to Wallet")
            return
        }
        
        let earningsViewController = EarningsViewController()
        navigationController.pushViewController(earningsViewController, animated: true)
        
        print("💰 LevelFitness: Successfully navigated to Wallet page")
    }
    
    private func navigateToWorkouts() {
        print("🏃‍♂️ LevelFitness: Workouts navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ LevelFitness: NavigationController is nil - cannot navigate to Workouts")
            return
        }
        
        let workoutsViewController = WorkoutsViewController()
        navigationController.pushViewController(workoutsViewController, animated: true)
        
        print("🏃‍♂️ LevelFitness: Successfully navigated to Workouts page")
    }
    
    // Level League removed - competitions now handled by individual teams
    
    // MARK: - Development Features
    
    #if DEBUG
    @objc private func handleTripleTap() {
        print("🎨 LevelFitness: Triple tap detected - generating icons and logos...")
        
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
}

// MARK: - Real Data Loading

extension ViewController {
    
    private func loadRealUserStats() {
        Task {
            await loadWorkoutStats()
            await loadEarningsStats()
            await loadStreakStats()
        }
    }
    
    private func loadWorkoutStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 LevelFitness: No user session found for workout stats")
                return
            }
            
            // Fetch user's workouts from Supabase
            let workouts = try await SupabaseService.shared.fetchWorkouts(userId: userSession.id, limit: 1000)
            
            
            await MainActor.run {
                let totalWorkouts = workouts.count
                workoutsStat.updateValue(totalWorkouts > 0 ? "\(totalWorkouts)" : "0")
                print("🏭 LevelFitness: Updated workout stats: \(totalWorkouts) workouts")
            }
            
        } catch {
            await MainActor.run {
                self.handleError(error, context: "loadWorkoutStats", showAlert: false)
                workoutsStat.updateValue("0")
            }
        }
    }
    
    private func loadEarningsStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 LevelFitness: No user session found for earnings stats")
                return
            }
            
            // Fetch user's transactions from Supabase
            let transactions = try await SupabaseService.shared.fetchTransactions(userId: userSession.id, limit: 1000)
            
            
            await MainActor.run {
                // Calculate total earnings (positive amounts)
                let totalEarningsSats = transactions
                    .filter { $0.type == "earning" || $0.type == "reward" }
                    .reduce(0) { $0 + $1.amount }
                
                let totalEarningsBTC = Double(totalEarningsSats) / 100_000_000.0
                let formattedEarnings = String(format: "%.6f", totalEarningsBTC)
                
                earningsStat.updateValue(formattedEarnings)
                print("🏭 LevelFitness: Updated earnings stats: ₿\(formattedEarnings)")
            }
            
        } catch {
            await MainActor.run {
                self.handleError(error, context: "loadEarningsStats", showAlert: false)
                earningsStat.updateValue("0.0000")
            }
        }
    }
    
    private func loadStreakStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 LevelFitness: No user session found for streak stats")
                return
            }
            
            // Fetch user's recent workouts to calculate streak
            let workouts = try await SupabaseService.shared.fetchWorkouts(userId: userSession.id, limit: 100)
            
            await MainActor.run {
                let currentStreak = calculateCurrentStreak(from: workouts)
                streakStat.updateValue("\(currentStreak)")
                print("🏭 LevelFitness: Updated streak stats: \(currentStreak) day streak")
            }
            
        } catch {
            await MainActor.run {
                self.handleError(error, context: "loadStreakStats", showAlert: false)
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
    
    func refreshUserStats() {
        // Public method to refresh stats when returning to main dashboard
        loadRealUserStats()
    }
}