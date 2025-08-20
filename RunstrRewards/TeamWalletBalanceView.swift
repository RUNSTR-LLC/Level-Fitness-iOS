import UIKit
import Foundation

protocol TeamWalletBalanceViewDelegate: AnyObject {
    func didTapFundWallet(_ view: TeamWalletBalanceView, teamId: String)
    func didTapViewTransactions(_ view: TeamWalletBalanceView, teamId: String)
    func didTapDistributeRewards(_ view: TeamWalletBalanceView, teamId: String)
}

class TeamWalletBalanceView: UIView {
    
    // MARK: - Properties
    private let teamId: String
    private var userRole: TeamRole = .none
    private var currentBalance: Int = 0
    private var teamWallet: TeamWalletBalance?
    private var pendingDistributions: [PrizeDistribution] = []
    private let distributionService = TeamPrizeDistributionService.shared
    weak var delegate: TeamWalletBalanceViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let statusIndicator = UIView()
    
    // Balance section
    private let balanceContainer = UIView()
    private let balanceLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let usdValueLabel = UILabel()
    private let availableBalanceLabel = UILabel()
    private let pendingLabel = UILabel()
    
    // Pending distributions section
    private let pendingContainer = UIView()
    private let pendingTitleLabel = UILabel()
    private let pendingAmountLabel = UILabel()
    private let pendingCountLabel = UILabel()
    private let pendingIndicator = UIView()
    
    // Actions section
    private let actionsContainer = UIView()
    private let fundButton = UIButton(type: .custom)
    private let transactionsButton = UIButton(type: .custom)
    private let distributeButton = UIButton(type: .custom)
    
    // Loading and error states
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    // Industrial design elements
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Initialization
    
    init(teamId: String) {
        self.teamId = teamId
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        loadWalletData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        
        // Update bolt decoration
        boltDecoration.frame = CGRect(
            x: bounds.width - 28,
            y: 12,
            width: 12,
            height: 12
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Container with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 16
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Shadow
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.3
        
        // Header setup
        setupHeader()
        setupBalance()
        setupPendingDistributions()
        setupActions()
        setupLoadingAndError()
        setupBoltDecoration()
        
        addSubview(containerView)
        containerView.addSubview(headerContainer)
        containerView.addSubview(balanceContainer)
        containerView.addSubview(pendingContainer)
        containerView.addSubview(actionsContainer)
        containerView.addSubview(loadingIndicator)
        containerView.addSubview(errorLabel)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupHeader() {
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Team Wallet"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Status indicator
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.backgroundColor = IndustrialDesign.Colors.primaryText
        statusIndicator.layer.cornerRadius = 4
        statusIndicator.layer.borderWidth = 1
        statusIndicator.layer.borderColor = IndustrialDesign.Colors.primaryText.withAlphaComponent(0.3).cgColor
        
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(statusIndicator)
    }
    
    private func setupBalance() {
        balanceContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Balance label
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.text = "PRIZE POOL BALANCE"
        balanceLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        balanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        balanceLabel.letterSpacing = 1.0
        
        // Balance value
        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceValueLabel.text = "₿0.00000000"
        balanceValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        balanceValueLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        balanceValueLabel.numberOfLines = 1
        balanceValueLabel.adjustsFontSizeToFitWidth = true
        balanceValueLabel.minimumScaleFactor = 0.7
        
        // USD value
        usdValueLabel.translatesAutoresizingMaskIntoConstraints = false
        usdValueLabel.text = "≈ $0.00 USD"
        usdValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        usdValueLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Available balance label
        availableBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        availableBalanceLabel.text = "Available: ₿0"
        availableBalanceLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        availableBalanceLabel.textColor = UIColor.systemGreen
        
        // Pending label
        pendingLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingLabel.text = "Pending: ₿0"
        pendingLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        pendingLabel.textColor = UIColor.systemOrange
        
        balanceContainer.addSubview(balanceLabel)
        balanceContainer.addSubview(balanceValueLabel)
        balanceContainer.addSubview(usdValueLabel)
        balanceContainer.addSubview(availableBalanceLabel)
        balanceContainer.addSubview(pendingLabel)
    }
    
    private func setupPendingDistributions() {
        pendingContainer.translatesAutoresizingMaskIntoConstraints = false
        pendingContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        pendingContainer.layer.cornerRadius = 8
        pendingContainer.layer.borderWidth = 1
        pendingContainer.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.3).cgColor
        pendingContainer.isHidden = true // Initially hidden
        
        // Pending title
        pendingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingTitleLabel.text = "PENDING DISTRIBUTIONS"
        pendingTitleLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        pendingTitleLabel.textColor = UIColor.systemOrange
        pendingTitleLabel.letterSpacing = 1.0
        
        // Pending amount
        pendingAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingAmountLabel.text = "₿0"
        pendingAmountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        pendingAmountLabel.textColor = UIColor.systemOrange
        
        // Pending count
        pendingCountLabel.translatesAutoresizingMaskIntoConstraints = false
        pendingCountLabel.text = "0 distributions"
        pendingCountLabel.font = UIFont.systemFont(ofSize: 12)
        pendingCountLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Pending indicator (pulsing dot)
        pendingIndicator.translatesAutoresizingMaskIntoConstraints = false
        pendingIndicator.backgroundColor = UIColor.systemOrange
        pendingIndicator.layer.cornerRadius = 3
        
        // Add pulsing animation
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.3
        pulseAnimation.toValue = 1.0
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pendingIndicator.layer.add(pulseAnimation, forKey: "pulse")
        
        pendingContainer.addSubview(pendingTitleLabel)
        pendingContainer.addSubview(pendingAmountLabel)
        pendingContainer.addSubview(pendingCountLabel)
        pendingContainer.addSubview(pendingIndicator)
    }
    
    private func setupActions() {
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Fund button (captain only)
        setupActionButton(
            fundButton,
            title: "Fund Wallet",
            icon: "plus.circle.fill",
            backgroundColor: UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0),
            action: #selector(fundButtonTapped)
        )
        
        // Transactions button (all members)
        setupActionButton(
            transactionsButton,
            title: "History",
            icon: "list.bullet",
            backgroundColor: UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0),
            action: #selector(transactionsButtonTapped)
        )
        
        // Distribute button (captain only)
        setupActionButton(
            distributeButton,
            title: "Distribute",
            icon: "arrow.down.circle.fill",
            backgroundColor: IndustrialDesign.Colors.cardBackground,
            action: #selector(distributeButtonTapped)
        )
        
        actionsContainer.addSubview(fundButton)
        actionsContainer.addSubview(transactionsButton)
        actionsContainer.addSubview(distributeButton)
    }
    
    private func setupActionButton(
        _ button: UIButton,
        title: String,
        icon: String,
        backgroundColor: UIColor,
        action: Selector
    ) {
        button.translatesAutoresizingMaskIntoConstraints = false
        
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8)
        
        button.configuration = config
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupLoadingAndError() {
        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.primaryText
        loadingIndicator.hidesWhenStopped = true
        
        // Error label
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        errorLabel.textColor = UIColor.systemOrange
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 1
        errorLabel.isHidden = true
    }
    
    private func setupBoltDecoration() {
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 6
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header
            headerContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            headerContainer.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            statusIndicator.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            statusIndicator.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 8),
            statusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Balance
            balanceContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            balanceContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            balanceContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            balanceLabel.topAnchor.constraint(equalTo: balanceContainer.topAnchor),
            balanceLabel.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            
            balanceValueLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 8),
            balanceValueLabel.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            balanceValueLabel.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor),
            
            usdValueLabel.topAnchor.constraint(equalTo: balanceValueLabel.bottomAnchor, constant: 4),
            usdValueLabel.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            
            availableBalanceLabel.topAnchor.constraint(equalTo: usdValueLabel.bottomAnchor, constant: 8),
            availableBalanceLabel.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            
            pendingLabel.topAnchor.constraint(equalTo: usdValueLabel.bottomAnchor, constant: 8),
            pendingLabel.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor),
            pendingLabel.bottomAnchor.constraint(equalTo: balanceContainer.bottomAnchor),
            
            // Pending distributions container
            pendingContainer.topAnchor.constraint(equalTo: balanceContainer.bottomAnchor, constant: 12),
            pendingContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            pendingContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            pendingContainer.heightAnchor.constraint(equalToConstant: 60),
            
            pendingTitleLabel.topAnchor.constraint(equalTo: pendingContainer.topAnchor, constant: 8),
            pendingTitleLabel.leadingAnchor.constraint(equalTo: pendingContainer.leadingAnchor, constant: 12),
            
            pendingIndicator.centerYAnchor.constraint(equalTo: pendingTitleLabel.centerYAnchor),
            pendingIndicator.trailingAnchor.constraint(equalTo: pendingContainer.trailingAnchor, constant: -12),
            pendingIndicator.widthAnchor.constraint(equalToConstant: 6),
            pendingIndicator.heightAnchor.constraint(equalToConstant: 6),
            
            pendingAmountLabel.topAnchor.constraint(equalTo: pendingTitleLabel.bottomAnchor, constant: 4),
            pendingAmountLabel.leadingAnchor.constraint(equalTo: pendingContainer.leadingAnchor, constant: 12),
            
            pendingCountLabel.centerYAnchor.constraint(equalTo: pendingAmountLabel.centerYAnchor),
            pendingCountLabel.trailingAnchor.constraint(equalTo: pendingIndicator.leadingAnchor, constant: -8),
            
            // Actions
            actionsContainer.topAnchor.constraint(equalTo: pendingContainer.bottomAnchor, constant: 12),
            actionsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            actionsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            actionsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            actionsContainer.heightAnchor.constraint(equalToConstant: 64),
            
            // Action buttons
            fundButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            fundButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            fundButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            
            transactionsButton.centerXAnchor.constraint(equalTo: actionsContainer.centerXAnchor),
            transactionsButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            transactionsButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            
            distributeButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            distributeButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            distributeButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            
            // Loading and error
            loadingIndicator.centerXAnchor.constraint(equalTo: balanceContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: balanceContainer.centerYAnchor),
            
            errorLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 4),
            errorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            errorLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadWalletData() {
        showLoadingState()
        
        // Load wallet data from TeamPrizeDistributionService
        if let wallet = distributionService.getTeamWallet(teamId: teamId) {
            teamWallet = wallet
            currentBalance = Int(wallet.totalBalance)
            
            // Load pending distributions
            pendingDistributions = distributionService.getDistributionsForTeam(teamId: teamId)
                .filter { $0.status == .pending || $0.status == .approved || $0.status == .draft }
            
            // Simulate user role (in real app, get from authentication)
            userRole = .captain // For demo purposes
            
            DispatchQueue.main.async {
                self.updateBalanceDisplay(wallet: wallet)
                self.updatePendingDistributions()
                self.updateButtonVisibility()
                self.hideLoadingState()
            }
        } else {
            DispatchQueue.main.async {
                self.showErrorState(error: TeamWalletError.teamWalletNotFound)
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateBalanceDisplay(wallet: TeamWalletBalance) {
        // Total balance
        let totalBtc = wallet.totalBalance / 100_000_000.0
        balanceValueLabel.text = "₿\(String(format: "%.8f", totalBtc))"
        
        // Available balance
        let availableBtc = wallet.availableBalance / 100_000_000.0
        availableBalanceLabel.text = "Available: ₿\(String(format: "%.6f", availableBtc))"
        
        // Pending amount
        let pendingBtc = wallet.pendingDistributions / 100_000_000.0
        pendingLabel.text = "Pending: ₿\(String(format: "%.6f", pendingBtc))"
        
        // Estimate USD value (this would typically come from an exchange rate API)
        let estimatedUSD = wallet.totalBalance * 0.0003 // Rough estimate
        usdValueLabel.text = "≈ $\(String(format: "%.2f", estimatedUSD)) USD"
        
        // Update colors based on available funds
        if wallet.availableBalance > 0 {
            availableBalanceLabel.textColor = UIColor.systemGreen
        } else {
            availableBalanceLabel.textColor = UIColor.systemRed
        }
    }
    
    private func updatePendingDistributions() {
        let hasPendingDistributions = !pendingDistributions.isEmpty
        pendingContainer.isHidden = !hasPendingDistributions
        
        if hasPendingDistributions {
            let totalPendingAmount = pendingDistributions.reduce(0) { $0 + $1.totalPrize }
            let pendingBtc = totalPendingAmount / 100_000_000.0
            
            pendingAmountLabel.text = "₿\(String(format: "%.6f", pendingBtc))"
            
            let count = pendingDistributions.count
            pendingCountLabel.text = count == 1 ? "1 distribution" : "\(count) distributions"
            
            // Update container border color based on urgency
            let hasApprovedDistributions = pendingDistributions.contains { $0.status == .approved }
            let borderColor = hasApprovedDistributions ? UIColor.systemRed : UIColor.systemOrange
            pendingContainer.layer.borderColor = borderColor.withAlphaComponent(0.3).cgColor
            
            // Add tap gesture to view pending distributions
            if pendingContainer.gestureRecognizers?.isEmpty ?? true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pendingDistributionsTapped))
                pendingContainer.addGestureRecognizer(tapGesture)
            }
        }
    }
    
    private func updateButtonVisibility() {
        // Only captains can fund and distribute
        let isCaptain = userRole == .captain
        fundButton.isHidden = !isCaptain
        distributeButton.isHidden = !isCaptain
        
        // All team members can view transactions
        transactionsButton.isHidden = false
        
        // Update layout for visible buttons
        if !isCaptain {
            transactionsButton.centerXAnchor.constraint(equalTo: actionsContainer.centerXAnchor).isActive = true
        }
    }
    
    private func showLoadingState() {
        loadingIndicator.startAnimating()
        balanceContainer.isHidden = true
        actionsContainer.isHidden = true
        errorLabel.isHidden = true
    }
    
    private func hideLoadingState() {
        loadingIndicator.stopAnimating()
        balanceContainer.isHidden = false
        actionsContainer.isHidden = false
        errorLabel.isHidden = true
    }
    
    private func showErrorState(error: Error) {
        loadingIndicator.stopAnimating()
        
        // Hide everything when there's an error to avoid UI overlap
        balanceContainer.isHidden = true
        actionsContainer.isHidden = true
        errorLabel.isHidden = false
        
        // Show a simple error message
        if error.localizedDescription.contains("Authentication required") {
            errorLabel.text = "Wallet not configured"
            errorLabel.textColor = UIColor.systemOrange
        } else {
            errorLabel.text = "Wallet unavailable"
            errorLabel.textColor = UIColor.systemRed
        }
    }
    
    // MARK: - Actions
    
    @objc private func fundButtonTapped() {
        print("TeamWalletBalanceView: Fund wallet tapped for team \(teamId)")
        delegate?.didTapFundWallet(self, teamId: teamId)
    }
    
    @objc private func transactionsButtonTapped() {
        print("TeamWalletBalanceView: View transactions tapped for team \(teamId)")
        delegate?.didTapViewTransactions(self, teamId: teamId)
    }
    
    @objc private func distributeButtonTapped() {
        print("TeamWalletBalanceView: Distribute rewards tapped for team \(teamId)")
        delegate?.didTapDistributeRewards(self, teamId: teamId)
    }
    
    @objc private func pendingDistributionsTapped() {
        print("TeamWalletBalanceView: Pending distributions tapped - \(pendingDistributions.count) pending")
        
        // Show pending distributions alert
        showPendingDistributionsAlert()
    }
    
    private func showPendingDistributionsAlert() {
        let alert = UIAlertController(
            title: "Pending Distributions",
            message: "\(pendingDistributions.count) distribution(s) awaiting action",
            preferredStyle: .alert
        )
        
        // Add details for each pending distribution
        for distribution in pendingDistributions.prefix(3) { // Show first 3
            let status = String(describing: distribution.status).capitalized
            let amount = "₿\(String(format: "%.6f", distribution.totalPrize / 100_000_000.0))"
            let eventName = "Event: \(distribution.eventId)"
            
            alert.message = (alert.message ?? "") + "\n\n\(status): \(amount)\n\(eventName)"
        }
        
        if pendingDistributions.count > 3 {
            alert.message = (alert.message ?? "") + "\n\n... and \(pendingDistributions.count - 3) more"
        }
        
        alert.addAction(UIAlertAction(title: "View All", style: .default) { _ in
            // In a real implementation, navigate to detailed view
            print("Navigate to detailed pending distributions view")
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
        // Present from the view controller containing this view
        if let viewController = self.findViewController() {
            viewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Public Methods
    
    func refreshBalance() {
        loadWalletData()
    }
    
    func updateBalance(_ newBalance: Int) {
        currentBalance = newBalance
        if let wallet = teamWallet {
            let updatedWallet = TeamWalletBalance(
                teamId: wallet.teamId,
                totalBalance: Double(newBalance),
                availableBalance: wallet.availableBalance,
                pendingDistributions: wallet.pendingDistributions,
                lastUpdated: Date(),
                transactions: wallet.transactions
            )
            updateBalanceDisplay(wallet: updatedWallet)
        }
    }
}

// Note: Helper extensions, TeamWalletError, and TeamRole are defined in other files to avoid duplication