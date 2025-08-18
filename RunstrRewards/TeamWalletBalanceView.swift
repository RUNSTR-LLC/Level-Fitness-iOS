import UIKit

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
        setupActions()
        setupLoadingAndError()
        setupBoltDecoration()
        
        addSubview(containerView)
        containerView.addSubview(headerContainer)
        containerView.addSubview(balanceContainer)
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
        statusIndicator.backgroundColor = UIColor.systemGreen
        statusIndicator.layer.cornerRadius = 4
        statusIndicator.layer.borderWidth = 1
        statusIndicator.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.3).cgColor
        
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
        
        balanceContainer.addSubview(balanceLabel)
        balanceContainer.addSubview(balanceValueLabel)
        balanceContainer.addSubview(usdValueLabel)
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
            backgroundColor: UIColor.systemBlue,
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
        errorLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        errorLabel.textColor = UIColor.systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
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
            usdValueLabel.bottomAnchor.constraint(equalTo: balanceContainer.bottomAnchor),
            
            // Actions
            actionsContainer.topAnchor.constraint(equalTo: balanceContainer.bottomAnchor, constant: 20),
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
            
            errorLabel.topAnchor.constraint(equalTo: balanceContainer.topAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor),
            errorLabel.bottomAnchor.constraint(equalTo: balanceContainer.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadWalletData() {
        showLoadingState()
        
        Task {
            do {
                // Get user role
                userRole = try await TeamWalletAccessController.shared.getUserRoleInTeam(
                    teamId: teamId,
                    userId: AuthenticationService.shared.loadSession()?.id ?? ""
                )
                
                // Get wallet balance
                let balance = try await TeamWalletManager.shared.getTeamWalletBalance(teamId: teamId)
                currentBalance = balance.total
                
                await MainActor.run {
                    updateBalanceDisplay(balance: balance.total)
                    updateButtonVisibility()
                    hideLoadingState()
                }
                
            } catch {
                await MainActor.run {
                    showErrorState(error: error)
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateBalanceDisplay(balance: Int) {
        let btcAmount = Double(balance) / 100_000_000.0
        balanceValueLabel.text = "₿\(String(format: "%.8f", btcAmount))"
        
        // Estimate USD value (this would typically come from an exchange rate API)
        let estimatedUSD = Double(balance) * 0.0003 // Rough estimate
        usdValueLabel.text = "≈ $\(String(format: "%.2f", estimatedUSD)) USD"
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
        balanceContainer.isHidden = true
        actionsContainer.isHidden = true
        errorLabel.isHidden = false
        errorLabel.text = "Failed to load wallet: \(error.localizedDescription)"
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
    
    // MARK: - Public Methods
    
    func refreshBalance() {
        loadWalletData()
    }
    
    func updateBalance(_ newBalance: Int) {
        currentBalance = newBalance
        updateBalanceDisplay(balance: newBalance)
    }
}