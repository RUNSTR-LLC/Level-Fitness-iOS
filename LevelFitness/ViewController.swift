import UIKit

class ViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = UIView()
    private let userAvatarButton = UIButton(type: .custom)
    private let usernameLabel = UILabel()
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
    private let workoutsStat = StatItem(value: "142", label: "Workouts")
    private let earningsStat = StatItem(value: "0.0042", label: "Earned", isBitcoin: true)
    private let streakStat = StatItem(value: "7", label: "Streak")
    
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
        print("🏭 LevelFitness: Industrial UI loaded successfully!")
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
        
        // User avatar
        userAvatarButton.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        userAvatarButton.setTitle("JD", for: .normal)
        userAvatarButton.titleLabel?.font = IndustrialDesign.Typography.navTitleFont
        userAvatarButton.layer.cornerRadius = IndustrialDesign.Sizing.avatarSize / 2
        userAvatarButton.layer.borderWidth = 2
        userAvatarButton.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        userAvatarButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Username
        usernameLabel.text = "steelrunner"
        usernameLabel.font = IndustrialDesign.Typography.usernameFont
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(userAvatarButton)
        headerView.addSubview(usernameLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupLogo() {
        logoSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Logo image
        logoImageView.image = UIImage(named: "LevelFitnessLogo")
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subtle glow effect to logo image
        logoImageView.layer.shadowColor = UIColor.white.cgColor
        logoImageView.layer.shadowOffset = CGSize.zero
        logoImageView.layer.shadowOpacity = 0.1
        logoImageView.layer.shadowRadius = 4
        logoImageView.layer.masksToBounds = false
        
        // Logo text with gradient
        logoLabel.text = "Level Fitness"
        logoLabel.font = IndustrialDesign.Typography.logoFont
        logoLabel.textAlignment = .center
        logoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Tagline
        taglineLabel.text = "sync to earn"
        taglineLabel.font = IndustrialDesign.Typography.taglineFont
        taglineLabel.textColor = IndustrialDesign.Colors.secondaryText
        taglineLabel.textAlignment = .center
        taglineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        logoSection.addSubview(logoImageView)
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
        
        let earningsCard = NavigationCard(
            title: "Rewards",
            subtitle: "track earnings",
            iconName: "star.fill",
            action: { [weak self] in
                self?.navigateToEarnings()
            }
        )
        
        let competitionsCard = NavigationCard(
            title: "League",
            subtitle: "Compete",
            iconName: "trophy.fill",
            action: { [weak self] in
                self?.navigateToCompetitions()
            }
        )
        
        let workoutsCard = NavigationCard(
            title: "Stats",
            subtitle: "sync workouts",
            iconName: "chart.bar.fill",
            action: { [weak self] in
                self?.navigateToWorkouts()
            }
        )
        
        navigationCards = [teamsCard, earningsCard, competitionsCard, workoutsCard]
        
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
            
            // Header elements
            userAvatarButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            userAvatarButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            userAvatarButton.widthAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.avatarSize),
            userAvatarButton.heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.avatarSize),
            
            usernameLabel.leadingAnchor.constraint(equalTo: userAvatarButton.trailingAnchor, constant: IndustrialDesign.Spacing.medium),
            usernameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            
            // Logo section
            logoSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: IndustrialDesign.Spacing.xxxLarge),
            logoSection.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoSection.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            
            // Logo image positioned above text
            logoImageView.topAnchor.constraint(equalTo: logoSection.topAnchor),
            logoImageView.centerXAnchor.constraint(equalTo: logoSection.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 64),
            logoImageView.heightAnchor.constraint(equalToConstant: 64),
            
            logoLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            logoLabel.centerXAnchor.constraint(equalTo: logoSection.centerXAnchor),
            
            taglineLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: IndustrialDesign.Spacing.small),
            taglineLabel.centerXAnchor.constraint(equalTo: logoSection.centerXAnchor),
            taglineLabel.bottomAnchor.constraint(equalTo: logoSection.bottomAnchor),
            
            // Navigation grid
            navigationGrid.topAnchor.constraint(equalTo: logoSection.bottomAnchor, constant: 60),
            navigationGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            navigationGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            navigationGrid.heightAnchor.constraint(equalToConstant: 300),
            
            // Navigation cards - 2x2 grid
            navigationCards[0].topAnchor.constraint(equalTo: navigationGrid.topAnchor),
            navigationCards[0].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[0].trailingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: -10),
            navigationCards[0].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[1].topAnchor.constraint(equalTo: navigationGrid.topAnchor),
            navigationCards[1].leadingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: 10),
            navigationCards[1].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[1].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[2].topAnchor.constraint(equalTo: navigationCards[0].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[2].leadingAnchor.constraint(equalTo: navigationGrid.leadingAnchor),
            navigationCards[2].trailingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: -10),
            navigationCards[2].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
            navigationCards[3].topAnchor.constraint(equalTo: navigationCards[1].bottomAnchor, constant: IndustrialDesign.Spacing.large),
            navigationCards[3].leadingAnchor.constraint(equalTo: navigationGrid.centerXAnchor, constant: 10),
            navigationCards[3].trailingAnchor.constraint(equalTo: navigationGrid.trailingAnchor),
            navigationCards[3].heightAnchor.constraint(equalToConstant: IndustrialDesign.Sizing.cardMinHeight),
            
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
    
    private func navigateToEarnings() {
        print("💰 LevelFitness: Earnings navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ LevelFitness: NavigationController is nil - cannot navigate to Earnings")
            return
        }
        
        let earningsViewController = EarningsViewController()
        navigationController.pushViewController(earningsViewController, animated: true)
        
        print("💰 LevelFitness: Successfully navigated to Earnings page")
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
    
    private func navigateToCompetitions() {
        print("🏆 LevelFitness: Competitions navigation requested")
        
        guard let navigationController = navigationController else {
            print("❌ LevelFitness: NavigationController is nil - cannot navigate to Competitions")
            return
        }
        
        let competitionsViewController = CompetitionsViewController()
        navigationController.pushViewController(competitionsViewController, animated: true)
        
        print("🏆 LevelFitness: Successfully navigated to Competitions page")
    }
    
    // MARK: - Development Features
    
    #if DEBUG
    @objc private func handleTripleTap() {
        print("🎨 LevelFitness: Triple tap detected - generating app icons...")
        
        let alert = UIAlertController(
            title: "Generate App Icons",
            message: "This will generate app icons and save them to the Documents folder. Continue?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Generate", style: .default) { _ in
            IconGenerator.generateAppIcons()
            
            let successAlert = UIAlertController(
                title: "Icons Generated!",
                message: "App icons have been generated and saved to the Documents folder. Check the console for file paths.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(successAlert, animated: true)
        })
        
        present(alert, animated: true)
    }
    #endif
}