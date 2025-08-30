import UIKit

class LotteryComingSoonViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let headerTitleLabel = UILabel()
    
    // Main content
    private let logoSection = UIView()
    private let mainTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Coming Soon section
    private let comingSoonContainer = UIView()
    private let comingSoonIconView = UIImageView()
    private let comingSoonLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    // Decorative elements
    private let boltDecoration1 = UIView()
    private let boltDecoration2 = UIView()
    private let boltDecoration3 = UIView()
    private let boltDecoration4 = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎰 Lottery: Loading lottery coming soon page...")
        
        // Set basic background first
        view.backgroundColor = IndustrialDesign.Colors.background
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Setup in correct order to avoid nil references
        setupScrollView()
        setupHeader()
        setupLogoSection()
        setupComingSoonSection()
        setupDecorations()
        setupConstraints()
        
        // Add background decorations after main content is set up
        DispatchQueue.main.async { [weak self] in
            self?.addBackgroundDecorations()
        }
        
        print("🎰 Lottery: Coming soon page loaded successfully!")
    }
    
    // MARK: - Setup Methods
    
    private func addBackgroundDecorations() {
        // Safely add grid pattern
        if let _ = NSClassFromString("RunstrRewards.GridPatternView") {
            let gridView = GridPatternView()
            gridView.translatesAutoresizingMaskIntoConstraints = false
            gridView.alpha = 0.5
            view.insertSubview(gridView, at: 0)
            
            NSLayoutConstraint.activate([
                gridView.topAnchor.constraint(equalTo: view.topAnchor),
                gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        // Safely add rotating gears
        if let _ = NSClassFromString("RunstrRewards.RotatingGearView") {
            let gear1 = RotatingGearView(size: 150)
            gear1.translatesAutoresizingMaskIntoConstraints = false
            gear1.alpha = 0.3
            view.insertSubview(gear1, at: 1)
            
            let gear2 = RotatingGearView(size: 100)
            gear2.translatesAutoresizingMaskIntoConstraints = false
            gear2.alpha = 0.2
            view.insertSubview(gear2, at: 1)
            
            NSLayoutConstraint.activate([
                gear1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
                gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
                gear1.widthAnchor.constraint(equalToConstant: 150),
                gear1.heightAnchor.constraint(equalToConstant: 150),
                
                gear2.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 50),
                gear2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
                gear2.widthAnchor.constraint(equalToConstant: 100),
                gear2.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Header title
        headerTitleLabel.text = ""
        headerTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        headerTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(headerTitleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupLogoSection() {
        logoSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Main title - RUNSTR REWARDS
        mainTitleLabel.text = "RUNSTR REWARDS"
        mainTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply gradient to title
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.mainTitleLabel)
        }
        
        // Subtitle - Lottery
        subtitleLabel.text = "LOTTERY"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        logoSection.addSubview(mainTitleLabel)
        logoSection.addSubview(subtitleLabel)
        contentView.addSubview(logoSection)
    }
    
    private func setupComingSoonSection() {
        // Container with industrial styling
        comingSoonContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        comingSoonContainer.layer.cornerRadius = 16
        comingSoonContainer.layer.borderWidth = 2
        comingSoonContainer.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        comingSoonContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        comingSoonIconView.image = UIImage(systemName: "clock.fill")
        comingSoonIconView.tintColor = IndustrialDesign.Colors.accentText
        comingSoonIconView.contentMode = .scaleAspectFit
        comingSoonIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Coming Soon label
        comingSoonLabel.text = "COMING SOON"
        comingSoonLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        comingSoonLabel.textColor = IndustrialDesign.Colors.primaryText
        comingSoonLabel.textAlignment = .center
        comingSoonLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = "All active members will be automatically enrolled in the RUNSTR REWARDS LOTTERY for a chance to win additional rewards."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        comingSoonContainer.addSubview(comingSoonIconView)
        comingSoonContainer.addSubview(comingSoonLabel)
        comingSoonContainer.addSubview(descriptionLabel)
        contentView.addSubview(comingSoonContainer)
    }
    
    private func setupDecorations() {
        // Setup bolt decorations
        let bolts = [boltDecoration1, boltDecoration2, boltDecoration3, boltDecoration4]
        
        for bolt in bolts {
            bolt.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
            bolt.layer.cornerRadius = 6
            bolt.layer.borderWidth = 1
            bolt.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
            bolt.translatesAutoresizingMaskIntoConstraints = false
            
            // Add inner shadow effect
            let innerShadow = CALayer()
            innerShadow.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
            innerShadow.cornerRadius = 6
            innerShadow.backgroundColor = UIColor.black.cgColor
            innerShadow.shadowColor = UIColor.black.cgColor
            innerShadow.shadowOffset = CGSize(width: 0, height: 1)
            innerShadow.shadowOpacity = 0.8
            innerShadow.shadowRadius = 1
            bolt.layer.addSublayer(innerShadow)
            
            comingSoonContainer.addSubview(bolt)
        }
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            headerTitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Logo section
            logoSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 60),
            logoSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            logoSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            mainTitleLabel.topAnchor.constraint(equalTo: logoSection.topAnchor),
            mainTitleLabel.leadingAnchor.constraint(equalTo: logoSection.leadingAnchor),
            mainTitleLabel.trailingAnchor.constraint(equalTo: logoSection.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: logoSection.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: logoSection.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: logoSection.bottomAnchor),
            
            // Coming Soon container
            comingSoonContainer.topAnchor.constraint(equalTo: logoSection.bottomAnchor, constant: 80),
            comingSoonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            comingSoonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            comingSoonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -80),
            
            // Coming Soon content
            comingSoonIconView.topAnchor.constraint(equalTo: comingSoonContainer.topAnchor, constant: 40),
            comingSoonIconView.centerXAnchor.constraint(equalTo: comingSoonContainer.centerXAnchor),
            comingSoonIconView.widthAnchor.constraint(equalToConstant: 60),
            comingSoonIconView.heightAnchor.constraint(equalToConstant: 60),
            
            comingSoonLabel.topAnchor.constraint(equalTo: comingSoonIconView.bottomAnchor, constant: 20),
            comingSoonLabel.leadingAnchor.constraint(equalTo: comingSoonContainer.leadingAnchor, constant: 32),
            comingSoonLabel.trailingAnchor.constraint(equalTo: comingSoonContainer.trailingAnchor, constant: -32),
            
            descriptionLabel.topAnchor.constraint(equalTo: comingSoonLabel.bottomAnchor, constant: 32),
            descriptionLabel.leadingAnchor.constraint(equalTo: comingSoonContainer.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: comingSoonContainer.trailingAnchor, constant: -32),
            descriptionLabel.bottomAnchor.constraint(equalTo: comingSoonContainer.bottomAnchor, constant: -40),
            
            // Bolt decorations
            boltDecoration1.topAnchor.constraint(equalTo: comingSoonContainer.topAnchor, constant: 12),
            boltDecoration1.leadingAnchor.constraint(equalTo: comingSoonContainer.leadingAnchor, constant: 12),
            boltDecoration1.widthAnchor.constraint(equalToConstant: 12),
            boltDecoration1.heightAnchor.constraint(equalToConstant: 12),
            
            boltDecoration2.topAnchor.constraint(equalTo: comingSoonContainer.topAnchor, constant: 12),
            boltDecoration2.trailingAnchor.constraint(equalTo: comingSoonContainer.trailingAnchor, constant: -12),
            boltDecoration2.widthAnchor.constraint(equalToConstant: 12),
            boltDecoration2.heightAnchor.constraint(equalToConstant: 12),
            
            boltDecoration3.bottomAnchor.constraint(equalTo: comingSoonContainer.bottomAnchor, constant: -12),
            boltDecoration3.leadingAnchor.constraint(equalTo: comingSoonContainer.leadingAnchor, constant: 12),
            boltDecoration3.widthAnchor.constraint(equalToConstant: 12),
            boltDecoration3.heightAnchor.constraint(equalToConstant: 12),
            
            boltDecoration4.bottomAnchor.constraint(equalTo: comingSoonContainer.bottomAnchor, constant: -12),
            boltDecoration4.trailingAnchor.constraint(equalTo: comingSoonContainer.trailingAnchor, constant: -12),
            boltDecoration4.widthAnchor.constraint(equalToConstant: 12),
            boltDecoration4.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        // Simply use a gradient-like color instead of complex layer masking
        // This avoids the overlapping text issue
        label.textColor = UIColor.white
    }
    
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🎰 Lottery: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
}