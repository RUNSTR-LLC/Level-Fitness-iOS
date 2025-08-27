import UIKit

class TeamWalletViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private let teamWalletManager = TeamWalletManager.shared
    private let prizeDistributionService = TeamPrizeDistributionService.shared
    private var teamWallet: TeamWalletBalance?
    private var pendingDistributions: [PrizeDistribution] = []
    private var isCaptain = false
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Wallet balance section
    private let balanceContainer = UIView()
    private var balanceCard = TeamWalletBalanceView(teamId: "")
    
    // Quick actions section
    private let actionsContainer = UIView()
    private let sendButton = UIButton(type: .custom)
    private let receiveButton = UIButton(type: .custom)
    private let historyButton = UIButton(type: .custom)
    
    // Prize distribution section
    private let distributionContainer = UIView()
    private let distributionTitleLabel = UILabel()
    private let distributionDescriptionLabel = UILabel()
    private let distributeRewardsButton = UIButton(type: .custom)
    
    // Recent transactions section
    private let transactionsContainer = UIView()
    private let transactionsTitleLabel = UILabel()
    private let transactionsStackView = UIStackView()
    private let viewAllTransactionsButton = UIButton(type: .custom)
    
    // Loading and error states
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏗️ TeamWalletViewController: Loading team wallet for \(teamData.name)")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupBalanceSection()
        setupActionsSection()
        setupDistributionSection()
        setupTransactionsSection()
        setupLoadingAndErrorStates() // Must add views to hierarchy first
        setupConstraints() // Then set up constraints
        
        // Verify captain access and load data
        Task {
            await verifyAccessAndLoadData()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let gear = RotatingGearView(size: 120)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 60),
            gear.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
            gear.widthAnchor.constraint(equalToConstant: 120),
            gear.heightAnchor.constraint(equalToConstant: 120)
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
        headerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "\(teamData.name) Wallet"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupBalanceSection() {
        balanceContainer.translatesAutoresizingMaskIntoConstraints = false
        balanceContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        balanceContainer.layer.cornerRadius = 12
        balanceContainer.layer.borderWidth = 1
        balanceContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Initialize wallet balance view with team ID
        balanceCard = TeamWalletBalanceView(teamId: teamData.id)
        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        balanceCard.delegate = self
        
        balanceContainer.addSubview(balanceCard)
        contentView.addSubview(balanceContainer)
    }
    
    private func setupActionsSection() {
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Send Bitcoin button
        sendButton.setTitle("Send Bitcoin", for: .normal)
        sendButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        sendButton.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        sendButton.layer.cornerRadius = 12
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendBitcoinTapped), for: .touchUpInside)
        
        // Receive Bitcoin button
        receiveButton.setTitle("Receive Bitcoin", for: .normal)
        receiveButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        receiveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        receiveButton.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        receiveButton.layer.cornerRadius = 12
        receiveButton.layer.borderWidth = 1
        receiveButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        receiveButton.addTarget(self, action: #selector(receiveBitcoinTapped), for: .touchUpInside)
        
        // Transaction history button
        historyButton.setTitle("Transaction History", for: .normal)
        historyButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        historyButton.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        historyButton.layer.cornerRadius = 12
        historyButton.layer.borderWidth = 1
        historyButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.addTarget(self, action: #selector(transactionHistoryTapped), for: .touchUpInside)
        
        actionsContainer.addSubview(sendButton)
        actionsContainer.addSubview(receiveButton)
        actionsContainer.addSubview(historyButton)
        contentView.addSubview(actionsContainer)
    }
    
    private func setupDistributionSection() {
        distributionContainer.translatesAutoresizingMaskIntoConstraints = false
        distributionContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        distributionContainer.layer.cornerRadius = 12
        distributionContainer.layer.borderWidth = 1
        distributionContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Title
        distributionTitleLabel.text = "Prize Distribution"
        distributionTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        distributionTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        distributionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        distributionDescriptionLabel.text = "Distribute Bitcoin rewards to team members for competitions and achievements."
        distributionDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        distributionDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        distributionDescriptionLabel.numberOfLines = 0
        distributionDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Distribute rewards button
        distributeRewardsButton.setTitle("Distribute Rewards", for: .normal)
        distributeRewardsButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        distributeRewardsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        distributeRewardsButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        distributeRewardsButton.layer.cornerRadius = 10
        distributeRewardsButton.translatesAutoresizingMaskIntoConstraints = false
        distributeRewardsButton.addTarget(self, action: #selector(distributeRewardsTapped), for: .touchUpInside)
        
        distributionContainer.addSubview(distributionTitleLabel)
        distributionContainer.addSubview(distributionDescriptionLabel)
        distributionContainer.addSubview(distributeRewardsButton)
        contentView.addSubview(distributionContainer)
    }
    
    private func setupTransactionsSection() {
        transactionsContainer.translatesAutoresizingMaskIntoConstraints = false
        transactionsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        transactionsContainer.layer.cornerRadius = 12
        transactionsContainer.layer.borderWidth = 1
        transactionsContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Title
        transactionsTitleLabel.text = "Recent Transactions"
        transactionsTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        transactionsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        transactionsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view for transaction items
        transactionsStackView.axis = .vertical
        transactionsStackView.spacing = 12
        transactionsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // View all transactions button
        viewAllTransactionsButton.setTitle("View All Transactions", for: .normal)
        viewAllTransactionsButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        viewAllTransactionsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        viewAllTransactionsButton.translatesAutoresizingMaskIntoConstraints = false
        viewAllTransactionsButton.addTarget(self, action: #selector(viewAllTransactionsTapped), for: .touchUpInside)
        
        transactionsContainer.addSubview(transactionsTitleLabel)
        transactionsContainer.addSubview(transactionsStackView)
        transactionsContainer.addSubview(viewAllTransactionsButton)
        contentView.addSubview(transactionsContainer)
    }
    
    private func setupLoadingAndErrorStates() {
        loadingIndicator.color = IndustrialDesign.Colors.primaryText
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        errorLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        errorLabel.textColor = UIColor.systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.isHidden = true
        
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(errorLabel)
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
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -24),
            
            // Balance section
            balanceContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            balanceContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            balanceContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            balanceContainer.heightAnchor.constraint(equalToConstant: 200),
            
            balanceCard.topAnchor.constraint(equalTo: balanceContainer.topAnchor),
            balanceCard.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            balanceCard.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor),
            balanceCard.bottomAnchor.constraint(equalTo: balanceContainer.bottomAnchor),
            
            // Actions section
            actionsContainer.topAnchor.constraint(equalTo: balanceContainer.bottomAnchor, constant: 24),
            actionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionsContainer.heightAnchor.constraint(equalToConstant: 120),
            
            sendButton.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            sendButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            sendButton.trailingAnchor.constraint(equalTo: actionsContainer.centerXAnchor, constant: -6),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            
            receiveButton.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            receiveButton.leadingAnchor.constraint(equalTo: actionsContainer.centerXAnchor, constant: 6),
            receiveButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            receiveButton.heightAnchor.constraint(equalToConstant: 50),
            
            historyButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 12),
            historyButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            historyButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            historyButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Distribution section
            distributionContainer.topAnchor.constraint(equalTo: actionsContainer.bottomAnchor, constant: 24),
            distributionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            distributionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            distributionContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 140),
            
            distributionTitleLabel.topAnchor.constraint(equalTo: distributionContainer.topAnchor, constant: 16),
            distributionTitleLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            distributionTitleLabel.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor, constant: -16),
            
            distributionDescriptionLabel.topAnchor.constraint(equalTo: distributionTitleLabel.bottomAnchor, constant: 8),
            distributionDescriptionLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            distributionDescriptionLabel.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor, constant: -16),
            
            distributeRewardsButton.topAnchor.constraint(equalTo: distributionDescriptionLabel.bottomAnchor, constant: 16),
            distributeRewardsButton.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            distributeRewardsButton.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor, constant: -16),
            distributeRewardsButton.heightAnchor.constraint(equalToConstant: 48),
            distributeRewardsButton.bottomAnchor.constraint(equalTo: distributionContainer.bottomAnchor, constant: -16),
            
            // Transactions section
            transactionsContainer.topAnchor.constraint(equalTo: distributionContainer.bottomAnchor, constant: 24),
            transactionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            transactionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            transactionsContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            transactionsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            transactionsTitleLabel.topAnchor.constraint(equalTo: transactionsContainer.topAnchor, constant: 16),
            transactionsTitleLabel.leadingAnchor.constraint(equalTo: transactionsContainer.leadingAnchor, constant: 16),
            transactionsTitleLabel.trailingAnchor.constraint(equalTo: transactionsContainer.trailingAnchor, constant: -16),
            
            transactionsStackView.topAnchor.constraint(equalTo: transactionsTitleLabel.bottomAnchor, constant: 16),
            transactionsStackView.leadingAnchor.constraint(equalTo: transactionsContainer.leadingAnchor, constant: 16),
            transactionsStackView.trailingAnchor.constraint(equalTo: transactionsContainer.trailingAnchor, constant: -16),
            
            viewAllTransactionsButton.topAnchor.constraint(equalTo: transactionsStackView.bottomAnchor, constant: 16),
            viewAllTransactionsButton.centerXAnchor.constraint(equalTo: transactionsContainer.centerXAnchor),
            viewAllTransactionsButton.bottomAnchor.constraint(equalTo: transactionsContainer.bottomAnchor, constant: -16),
            
            // Loading and error states
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 40),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40)
        ])
    }
    
    // MARK: - Data Loading
    
    private func verifyAccessAndLoadData() async {
        print("🏗️ TeamWalletViewController: Starting wallet access verification for team: \(teamData.name) (ID: \(teamData.id))")
        
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("🏗️ TeamWalletViewController: ❌ No authentication session found")
            await showError("Authentication required")
            return
        }
        
        print("🏗️ TeamWalletViewController: User session found: \(userSession.id)")
        
        do {
            // Verify user is team captain
            print("🏗️ TeamWalletViewController: Verifying captain access...")
            let hasAccess = try await teamWalletManager.verifyTeamCaptainAccess(teamId: teamData.id, userId: userSession.id)
            print("🏗️ TeamWalletViewController: Captain access verification result: \(hasAccess)")
            
            if !hasAccess {
                print("🏗️ TeamWalletViewController: ❌ Captain verification failed for user \(userSession.id) on team \(teamData.id)")
                await showError("Access denied: Only team captains can manage the team wallet. If you are the team captain, please check your team settings.")
                return
            }
            
            await MainActor.run {
                self.isCaptain = true
                self.loadingIndicator.startAnimating()
                self.hideError()
            }
            
            // Load wallet data
            await loadWalletData()
            
        } catch {
            await MainActor.run {
                ErrorHandlingService.shared.handleError(error, context: "Team Wallet Access Verification", in: self)
            }
        }
    }
    
    private func loadWalletData() async {
        do {
            // Load team wallet balance
            let walletBalance = try await TransactionDataService.shared.getTeamWalletBalance(teamId: teamData.id)
            
            // Load recent transactions (limit to 5 for preview)
            let recentTransactions = try await TransactionDataService.shared.getTeamTransactions(teamId: teamData.id, limit: 5)
            
            // Load pending distributions
            let distributions = try await prizeDistributionService.getPendingDistributions(teamId: teamData.id)
            
            await MainActor.run {
                // Create TeamWalletBalance from the Int value
                let teamWalletBalance = TeamWalletBalance(
                    teamId: teamData.id,
                    totalBalance: Double(walletBalance),
                    availableBalance: Double(walletBalance),
                    pendingDistributions: 0.0,
                    lastUpdated: Date(),
                    transactions: recentTransactions
                )
                self.teamWallet = teamWalletBalance
                self.pendingDistributions = distributions
                self.updateUI(with: teamWalletBalance, transactions: recentTransactions)
                self.loadingIndicator.stopAnimating()
            }
            
        } catch {
            await showError("Failed to load wallet data: \(error.localizedDescription)")
        }
    }
    
    private func updateUI(with walletBalance: TeamWalletBalance, transactions: [TeamTransaction]) {
        // Update balance card
        balanceCard.updateBalance(Int(walletBalance.totalBalance))
        
        // Update transactions list
        updateTransactionsList(transactions)
        
        // Update distribution button state
        updateDistributionButton()
    }
    
    private func updateTransactionsList(_ transactions: [TeamTransaction]) {
        // Clear existing transaction views
        transactionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if transactions.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No transactions yet"
            emptyLabel.font = UIFont.systemFont(ofSize: 14)
            emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
            emptyLabel.textAlignment = .center
            transactionsStackView.addArrangedSubview(emptyLabel)
        } else {
            for transaction in transactions {
                let transactionView = createTransactionView(for: transaction)
                transactionsStackView.addArrangedSubview(transactionView)
            }
        }
    }
    
    private func createTransactionView(for transaction: TeamTransaction) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = transaction.description
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let amountLabel = UILabel()
        let amountText = transaction.type == .prizeReceived ? "+\(transaction.amount) sats" : "-\(transaction.amount) sats"
        amountLabel.text = amountText
        amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        amountLabel.textColor = transaction.type == .prizeReceived ? UIColor.systemGreen : UIColor.systemOrange
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let dateLabel = UILabel()
        dateLabel.text = formatDate(transaction.timestamp)
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(amountLabel)
        container.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
    }
    
    private func updateDistributionButton() {
        let hasPendingDistributions = !pendingDistributions.isEmpty
        let buttonTitle = hasPendingDistributions ? "Complete Pending Distributions" : "Distribute Rewards"
        distributeRewardsButton.setTitle(buttonTitle, for: .normal)
        
        if hasPendingDistributions {
            distributeRewardsButton.backgroundColor = UIColor.systemOrange
        } else {
            distributeRewardsButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @MainActor
    private func showError(_ message: String) {
        loadingIndicator.stopAnimating()
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    @MainActor
    private func hideError() {
        errorLabel.isHidden = true
    }
    
    // MARK: - Actions
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendBitcoinTapped() {
        print("🏗️ TeamWalletViewController: Send Bitcoin tapped")
        showSendBitcoinInterface()
    }
    
    private func showSendBitcoinInterface() {
        guard let wallet = teamWallet, wallet.totalBalance > 0 else {
            showErrorAlert("Insufficient balance to send Bitcoin")
            return
        }
        
        let alert = UIAlertController(
            title: "Send Bitcoin",
            message: "Enter Lightning invoice or Bitcoin address",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Lightning invoice or Bitcoin address"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Amount (sats)"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            guard let invoiceField = alert.textFields?[0],
                  let amountField = alert.textFields?[1],
                  let invoice = invoiceField.text, !invoice.isEmpty,
                  let amountText = amountField.text, let amount = Int(amountText) else {
                self.showErrorAlert("Please enter valid invoice and amount")
                return
            }
            
            if amount > Int(wallet.totalBalance) {
                self.showErrorAlert("Amount exceeds available balance")
                return
            }
            
            Task {
                await self.processBitcoinPayment(invoice: invoice, amount: amount)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func processBitcoinPayment(invoice: String, amount: Int) async {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            await MainActor.run {
                self.showDetailedErrorAlert(
                    title: "Authentication Required",
                    message: "Please log in to send Bitcoin payments.",
                    actionTitle: "OK"
                )
            }
            return
        }
        
        // Show progress alert
        let progressAlert = await MainActor.run {
            let alert = self.showProgressAlert(
                title: "Sending Bitcoin",
                message: "Processing Lightning Network payment..."
            )
            self.present(alert, animated: true)
            return alert
        }
        
        do {
            // Load team wallet credentials
            guard let credentials = teamWalletManager.loadTeamWalletCredentials(teamId: teamData.id) else {
                await MainActor.run {
                    progressAlert.dismiss(animated: true) {
                        self.showDetailedErrorAlert(
                            title: "Wallet Not Available",
                            message: "Team wallet credentials not found. Please contact team captain to set up the wallet.",
                            actionTitle: "OK"
                        )
                    }
                }
                return
            }
            
            // Update progress
            await MainActor.run {
                progressAlert.message = "Authenticating with wallet..."
            }
            
            // Authenticate with team wallet
            let authResponse = try await CoinOSService.shared.loginUser(
                username: credentials.username,
                password: credentials.password
            )
            CoinOSService.shared.setAuthToken(authResponse.token)
            
            // Update progress
            await MainActor.run {
                progressAlert.message = "Executing Lightning payment..."
            }
            
            // Process payment
            let paymentResult = try await CoinOSService.shared.payInvoice(invoice)
            
            if paymentResult.success {
                // Update progress
                await MainActor.run {
                    progressAlert.message = "Recording transaction..."
                }
                
                // Record transaction
                try await TransactionDataService.shared.recordTeamTransaction(
                    teamId: teamData.id,
                    userId: userSession.id,
                    amount: -amount, // Negative for outgoing payment
                    type: "manual_send",
                    description: "Manual Bitcoin payment"
                )
                
                await MainActor.run {
                    progressAlert.dismiss(animated: true) {
                        self.showSuccessAlert("Bitcoin sent successfully! ⚡️\n\nTransaction ID: \(paymentResult.paymentHash.prefix(10))...")
                        // Reload wallet data to show updated balance
                        Task {
                            await self.loadWalletData()
                        }
                    }
                }
            } else {
                await MainActor.run {
                    progressAlert.dismiss(animated: true) {
                        self.showDetailedErrorAlert(
                            title: "Payment Failed",
                            message: "The Lightning Network payment could not be completed. This might be due to routing issues or invalid invoice. Please try again or contact support.",
                            actionTitle: "Retry"
                        ) {
                            Task {
                                await self.processBitcoinPayment(invoice: invoice, amount: amount)
                            }
                        }
                    }
                }
            }
            
        } catch {
            await MainActor.run {
                progressAlert.dismiss(animated: true) {
                    let errorMessage: String
                    if error.localizedDescription.contains("CoinOS") {
                        errorMessage = "Wallet service error: \(error.localizedDescription)"
                    } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                        errorMessage = "Network connection error. Please check your internet connection and try again."
                    } else {
                        errorMessage = "Payment processing failed: \(error.localizedDescription)"
                    }
                    
                    self.showDetailedErrorAlert(
                        title: "Payment Error",
                        message: errorMessage,
                        actionTitle: "Retry"
                    ) {
                        Task {
                            await self.processBitcoinPayment(invoice: invoice, amount: amount)
                        }
                    }
                }
            }
        }
    }
    
    @objc private func receiveBitcoinTapped() {
        print("🏗️ TeamWalletViewController: Receive Bitcoin tapped")
        showReceiveBitcoinInterface()
    }
    
    private func showReceiveBitcoinInterface() {
        let alert = UIAlertController(
            title: "Receive Bitcoin",
            message: "Enter amount to receive (sats)",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Amount (sats)"
            textField.keyboardType = .numberPad
            textField.text = "10000" // Default amount
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Memo (optional)"
            textField.text = "Team wallet funding"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Create Invoice", style: .default) { _ in
            guard let amountField = alert.textFields?[0],
                  let memoField = alert.textFields?[1],
                  let amountText = amountField.text, let amount = Int(amountText) else {
                self.showErrorAlert("Please enter valid amount")
                return
            }
            
            let memo = memoField.text ?? "Team wallet funding"
            
            Task {
                await self.createReceiveInvoice(amount: amount, memo: memo)
            }
        })
        
        present(alert, animated: true)
    }
    
    private func createReceiveInvoice(amount: Int, memo: String) async {
        do {
            // Load team wallet credentials
            guard let credentials = teamWalletManager.loadTeamWalletCredentials(teamId: teamData.id) else {
                await MainActor.run {
                    self.showErrorAlert("Team wallet not available")
                }
                return
            }
            
            await MainActor.run {
                self.loadingIndicator.startAnimating()
            }
            
            // Authenticate with team wallet
            let authResponse = try await CoinOSService.shared.loginUser(
                username: credentials.username,
                password: credentials.password
            )
            CoinOSService.shared.setAuthToken(authResponse.token)
            
            // Create invoice
            let invoice = try await CoinOSService.shared.addInvoice(amount: amount, memo: memo)
            
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showInvoiceDetails(invoice: invoice)
            }
            
        } catch {
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.showErrorAlert("Failed to create invoice: \(error.localizedDescription)")
            }
        }
    }
    
    private func showInvoiceDetails(invoice: LightningInvoice) {
        let alert = UIAlertController(
            title: "Lightning Invoice Created",
            message: "Invoice for \(invoice.amount) sats has been created. Share this invoice to receive payment.",
            preferredStyle: .alert
        )
        
        // Add copy invoice action
        alert.addAction(UIAlertAction(title: "Copy Invoice", style: .default) { _ in
            UIPasteboard.general.string = invoice.paymentRequest
            
            let copyAlert = UIAlertController(
                title: "Copied!",
                message: "Invoice copied to clipboard",
                preferredStyle: .alert
            )
            copyAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(copyAlert, animated: true)
        })
        
        // Add show QR code action (placeholder for now)
        alert.addAction(UIAlertAction(title: "Show QR Code", style: .default) { _ in
            // TODO: Implement QR code display
            let qrAlert = UIAlertController(
                title: "QR Code",
                message: "QR code functionality coming soon. For now, use 'Copy Invoice' to share the payment request.",
                preferredStyle: .alert
            )
            qrAlert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(qrAlert, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func transactionHistoryTapped() {
        print("🏗️ TeamWalletViewController: Transaction history tapped")
        
        let alert = UIAlertController(
            title: "Transaction History",
            message: "Full transaction history view coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func distributeRewardsTapped() {
        print("🏗️ TeamWalletViewController: Distribute rewards tapped")
        
        guard let wallet = teamWallet else {
            showDetailedErrorAlert(
                title: "Wallet Not Available",
                message: "Wallet data is not loaded. Please wait for the wallet to load or try refreshing the page.",
                actionTitle: "Refresh"
            ) {
                Task {
                    await self.loadWalletData()
                }
            }
            return
        }
        
        if wallet.totalBalance <= 0 {
            showDetailedErrorAlert(
                title: "Insufficient Balance",
                message: "The team wallet doesn't have enough Bitcoin to distribute rewards. Please fund the wallet first using the 'Receive Bitcoin' option.",
                actionTitle: "Fund Wallet"
            ) {
                self.receiveBitcoinTapped()
            }
            return
        }
        
        // Show prize distribution interface
        // For now, create a dummy event data since the constructor requires it
        let dummyEvent = EventData(
            id: "temp-event",
            name: "Team Rewards Distribution",
            type: .challenge,
            status: .active,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            participants: 0,
            prizePool: wallet.totalBalance,
            entryFee: 0.0
        )
        
        let distributionVC = PrizeDistributionViewController(
            teamData: teamData,
            eventData: dummyEvent
        )
        
        let navigationController = UINavigationController(rootViewController: distributionVC)
        navigationController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        present(navigationController, animated: true)
    }
    
    @objc private func viewAllTransactionsTapped() {
        print("🏗️ TeamWalletViewController: View all transactions tapped")
        
        let alert = UIAlertController(
            title: "All Transactions",
            message: "Complete transaction history view coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showDetailedErrorAlert(
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        if let actionTitle = actionTitle, let action = action {
            alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in
                action()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showProgressAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            loadingIndicator.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
        ])
        
        return alert
    }
}

// MARK: - TeamWalletBalanceViewDelegate

extension TeamWalletViewController: TeamWalletBalanceViewDelegate {
    func didTapFundWallet(_ view: TeamWalletBalanceView, teamId: String) {
        receiveBitcoinTapped()
    }
    
    func didTapViewTransactions(_ view: TeamWalletBalanceView, teamId: String) {
        transactionHistoryTapped()
    }
    
    func didTapDistributeRewards(_ view: TeamWalletBalanceView, teamId: String) {
        distributeRewardsTapped()
    }
}