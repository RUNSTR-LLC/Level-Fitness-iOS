import UIKit

class TeamWalletSetupStepViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let stepTitleLabel = UILabel()
    private let stepDescriptionLabel = UILabel()
    
    // Wallet setup section
    private let walletSetupSection = UIView()
    private let walletTitleLabel = UILabel()
    private let walletDescriptionLabel = UILabel()
    private let walletStatusContainer = UIView()
    private let walletStatusIcon = UIImageView()
    private let walletStatusLabel = UILabel()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    
    // Benefits section
    private let benefitsSection = UIView()
    private let benefitsTitleLabel = UILabel()
    
    // Team data reference
    private let teamData: TeamCreationData
    
    // Wallet status
    private var isWalletReady = false
    private var walletCreationInProgress = false
    
    init(teamData: TeamCreationData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        
        print("✅ TeamWalletSetup: Step view loaded")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Automatically start wallet creation when step appears
        if !isWalletReady && !walletCreationInProgress {
            initiateWalletCreation()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        // Step header
        stepTitleLabel.text = "Bitcoin Wallet Setup"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stepDescriptionLabel.text = "Setting up your team's Bitcoin wallet to receive and distribute rewards. This is required for all teams."
        stepDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        stepDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        stepDescriptionLabel.numberOfLines = 0
        stepDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        setupWalletSetupSection()
        setupBenefitsSection()
        
        // Add to scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [stepTitleLabel, stepDescriptionLabel, walletSetupSection, benefitsSection].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupWalletSetupSection() {
        walletSetupSection.translatesAutoresizingMaskIntoConstraints = false
        walletSetupSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        walletSetupSection.layer.cornerRadius = 12
        walletSetupSection.layer.borderWidth = 1
        walletSetupSection.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        walletTitleLabel.text = "Team Wallet"
        walletTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        walletTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        walletTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        walletDescriptionLabel.text = "Your team will get its own Bitcoin Lightning wallet for instant, low-cost transactions."
        walletDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        walletDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        walletDescriptionLabel.numberOfLines = 0
        walletDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Wallet status container
        walletStatusContainer.translatesAutoresizingMaskIntoConstraints = false
        walletStatusContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        walletStatusContainer.layer.cornerRadius = 8
        walletStatusContainer.layer.borderWidth = 1
        walletStatusContainer.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        
        // Status icon
        walletStatusIcon.translatesAutoresizingMaskIntoConstraints = false
        walletStatusIcon.contentMode = .scaleAspectFit
        walletStatusIcon.tintColor = UIColor.systemOrange
        
        // Status label
        walletStatusLabel.text = "Preparing wallet setup..."
        walletStatusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        walletStatusLabel.textColor = IndustrialDesign.Colors.primaryText
        walletStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress indicator
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.color = IndustrialDesign.Colors.bitcoin
        progressIndicator.hidesWhenStopped = true
        
        walletStatusContainer.addSubview(walletStatusIcon)
        walletStatusContainer.addSubview(walletStatusLabel)
        walletStatusContainer.addSubview(progressIndicator)
        
        walletSetupSection.addSubview(walletTitleLabel)
        walletSetupSection.addSubview(walletDescriptionLabel)
        walletSetupSection.addSubview(walletStatusContainer)
    }
    
    private func setupBenefitsSection() {
        benefitsSection.translatesAutoresizingMaskIntoConstraints = false
        benefitsSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        benefitsSection.layer.cornerRadius = 12
        benefitsSection.layer.borderWidth = 1
        benefitsSection.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.3).cgColor
        
        benefitsTitleLabel.text = "What you'll get:"
        benefitsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        benefitsTitleLabel.textColor = IndustrialDesign.Colors.bitcoin
        benefitsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let benefits = [
            "⚡ Lightning-fast Bitcoin transactions",
            "🔒 Secure team fund management",
            "🏆 Automatic reward distributions",
            "📊 Complete transaction history",
            "💰 Keep 100% of member subscription revenue"
        ]
        
        var previousView: UIView = benefitsTitleLabel
        
        for benefit in benefits {
            let benefitLabel = UILabel()
            benefitLabel.text = benefit
            benefitLabel.font = UIFont.systemFont(ofSize: 14)
            benefitLabel.textColor = IndustrialDesign.Colors.primaryText
            benefitLabel.numberOfLines = 0
            benefitLabel.translatesAutoresizingMaskIntoConstraints = false
            
            benefitsSection.addSubview(benefitLabel)
            
            NSLayoutConstraint.activate([
                benefitLabel.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 8),
                benefitLabel.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor, constant: 16),
                benefitLabel.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor, constant: -16)
            ])
            
            previousView = benefitLabel
        }
        
        benefitsSection.addSubview(benefitsTitleLabel)
        
        // Set bottom constraint for benefits section
        NSLayoutConstraint.activate([
            benefitsSection.bottomAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 16)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Step header
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            stepDescriptionLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            stepDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stepDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Wallet setup section
            walletSetupSection.topAnchor.constraint(equalTo: stepDescriptionLabel.bottomAnchor, constant: 32),
            walletSetupSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            walletSetupSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            walletTitleLabel.topAnchor.constraint(equalTo: walletSetupSection.topAnchor, constant: 16),
            walletTitleLabel.leadingAnchor.constraint(equalTo: walletSetupSection.leadingAnchor, constant: 16),
            walletTitleLabel.trailingAnchor.constraint(equalTo: walletSetupSection.trailingAnchor, constant: -16),
            
            walletDescriptionLabel.topAnchor.constraint(equalTo: walletTitleLabel.bottomAnchor, constant: 8),
            walletDescriptionLabel.leadingAnchor.constraint(equalTo: walletSetupSection.leadingAnchor, constant: 16),
            walletDescriptionLabel.trailingAnchor.constraint(equalTo: walletSetupSection.trailingAnchor, constant: -16),
            
            walletStatusContainer.topAnchor.constraint(equalTo: walletDescriptionLabel.bottomAnchor, constant: 16),
            walletStatusContainer.leadingAnchor.constraint(equalTo: walletSetupSection.leadingAnchor, constant: 16),
            walletStatusContainer.trailingAnchor.constraint(equalTo: walletSetupSection.trailingAnchor, constant: -16),
            walletStatusContainer.bottomAnchor.constraint(equalTo: walletSetupSection.bottomAnchor, constant: -16),
            walletStatusContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Wallet status container elements
            walletStatusIcon.leadingAnchor.constraint(equalTo: walletStatusContainer.leadingAnchor, constant: 12),
            walletStatusIcon.centerYAnchor.constraint(equalTo: walletStatusContainer.centerYAnchor),
            walletStatusIcon.widthAnchor.constraint(equalToConstant: 24),
            walletStatusIcon.heightAnchor.constraint(equalToConstant: 24),
            
            walletStatusLabel.leadingAnchor.constraint(equalTo: walletStatusIcon.trailingAnchor, constant: 12),
            walletStatusLabel.centerYAnchor.constraint(equalTo: walletStatusContainer.centerYAnchor),
            walletStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressIndicator.leadingAnchor, constant: -8),
            
            progressIndicator.trailingAnchor.constraint(equalTo: walletStatusContainer.trailingAnchor, constant: -12),
            progressIndicator.centerYAnchor.constraint(equalTo: walletStatusContainer.centerYAnchor),
            
            // Benefits section
            benefitsSection.topAnchor.constraint(equalTo: walletSetupSection.bottomAnchor, constant: 16),
            benefitsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            benefitsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            benefitsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            benefitsTitleLabel.topAnchor.constraint(equalTo: benefitsSection.topAnchor, constant: 16),
            benefitsTitleLabel.leadingAnchor.constraint(equalTo: benefitsSection.leadingAnchor, constant: 16),
            benefitsTitleLabel.trailingAnchor.constraint(equalTo: benefitsSection.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - Wallet Creation
    
    private func initiateWalletCreation() {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            showWalletError("Authentication required for wallet creation")
            return
        }
        
        walletCreationInProgress = true
        showWalletCreationProgress()
        
        print("🏗️ TeamWalletSetup: Starting wallet creation for future team")
        
        Task {
            do {
                // Check CoinOS availability first
                try await checkCoinOSAvailability()
                
                // Prepare wallet creation (don't actually create until team is ready)
                await MainActor.run {
                    self.showWalletSuccess()
                    self.isWalletReady = true
                    self.walletCreationInProgress = false
                    
                    // Store wallet readiness in team data
                    self.teamData.isWalletReady = true
                    
                    print("🏗️ TeamWalletSetup: Wallet preparation completed successfully")
                }
                
            } catch {
                print("🏗️ TeamWalletSetup: Wallet preparation failed - \(error)")
                
                await MainActor.run {
                    self.showWalletError("Wallet setup failed: \(error.localizedDescription)")
                    self.walletCreationInProgress = false
                    self.teamData.isWalletReady = false
                }
            }
        }
    }
    
    private func checkCoinOSAvailability() async throws {
        // Test CoinOS connectivity by attempting to get service status
        try await CoinOSService.shared.checkServiceAvailability()
    }
    
    private func showWalletCreationProgress() {
        walletStatusIcon.image = UIImage(systemName: "bitcoinsign.circle")
        walletStatusLabel.text = "Creating your team's Bitcoin wallet..."
        progressIndicator.startAnimating()
        
        walletStatusContainer.layer.borderColor = UIColor.systemOrange.cgColor
        walletStatusIcon.tintColor = UIColor.systemOrange
    }
    
    private func showWalletSuccess() {
        walletStatusIcon.image = UIImage(systemName: "checkmark.circle.fill")
        walletStatusLabel.text = "Bitcoin wallet ready! ⚡"
        progressIndicator.stopAnimating()
        
        walletStatusContainer.layer.borderColor = UIColor.systemGreen.cgColor
        walletStatusIcon.tintColor = UIColor.systemGreen
        
        // Add subtle success animation
        UIView.animate(withDuration: 0.3) {
            self.walletStatusContainer.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.walletStatusContainer.transform = .identity
            }
        }
    }
    
    private func showWalletError(_ message: String) {
        walletStatusIcon.image = UIImage(systemName: "exclamationmark.triangle.fill")
        walletStatusLabel.text = message
        progressIndicator.stopAnimating()
        
        walletStatusContainer.layer.borderColor = UIColor.systemRed.cgColor
        walletStatusIcon.tintColor = UIColor.systemRed
    }
    
    // MARK: - Public Methods for Wizard
    
    func canProceedToNext() -> Bool {
        return isWalletReady && !walletCreationInProgress
    }
    
    func getWalletReadyStatus() -> Bool {
        return isWalletReady
    }
}