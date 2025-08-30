import UIKit
import Foundation

// Include the service implementation directly to resolve build issue
// This is a temporary measure until Xcode project configuration is fixed

class TeamWalletPaymentService {
    static let shared = TeamWalletPaymentService()
    weak var delegate: TeamWalletPaymentDelegate?
    
    private init() {}
    
    func showSendBitcoinInterface(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Send Bitcoin", 
            message: "Bitcoin sending functionality", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    func showReceiveBitcoinInterface(for teamData: TeamData, from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Receive Bitcoin", 
            message: "Bitcoin receiving functionality", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}

protocol TeamWalletPaymentDelegate: AnyObject {
    func didStartPayment()
    func didCompletePayment(hash: String, amount: Int)
    func didFailPayment(_ error: Error)
    func didGenerateInvoice(_ invoice: LightningInvoice)
}

class TeamWalletViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var teamWallet: TeamWalletBalance?
    private var pendingDistributions: [PrizeDistribution] = []
    private var isCaptain = false
    
    // Services
    private lazy var dataService: TeamWalletDataService = {
        let service = TeamWalletDataService()
        service.delegate = self
        return service
    }()
    
    private lazy var paymentService: TeamWalletPaymentService = {
        let service = TeamWalletPaymentService.shared
        service.delegate = self
        return service
    }()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Wallet balance section
    private let balanceContainer = UIView()
    private var balanceCard: TeamWalletBalanceView
    
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
        self.balanceCard = TeamWalletBalanceView(teamId: teamData.id)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        
        // Load data
        Task {
            guard let userSession = AuthenticationService.shared.loadSession() else { return }
            await dataService.verifyAccessAndLoadData(for: teamData, userId: userSession.id)
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        setupScrollView()
        setupHeader()
        setupBalanceSection()
        setupActionsSection()
        setupDistributionSection()
        setupTransactionsSection()
        setupLoadingAndErrorStates()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        titleLabel.text = "\(teamData.name) Wallet"
        titleLabel.font = IndustrialDesign.Typography.h2
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        
        [backButton, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview($0)
        }
        
        contentView.addSubview(headerView)
    }
    
    private func setupBalanceSection() {
        balanceContainer.translatesAutoresizingMaskIntoConstraints = false
        balanceCard.translatesAutoresizingMaskIntoConstraints = false
        
        balanceContainer.addSubview(balanceCard)
        contentView.addSubview(balanceContainer)
    }
    
    private func setupActionsSection() {
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure action buttons
        [sendButton, receiveButton, historyButton].forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            button.backgroundColor = IndustrialDesign.Colors.secondaryBlue
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = IndustrialDesign.Typography.buttonText
            button.layer.cornerRadius = 8
            actionsContainer.addSubview(button)
        }
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendBitcoinTapped), for: .touchUpInside)
        
        receiveButton.setTitle("Receive", for: .normal)
        receiveButton.addTarget(self, action: #selector(receiveBitcoinTapped), for: .touchUpInside)
        
        historyButton.setTitle("History", for: .normal)
        historyButton.addTarget(self, action: #selector(viewHistoryTapped), for: .touchUpInside)
        
        contentView.addSubview(actionsContainer)
    }
    
    private func setupDistributionSection() {
        distributionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        distributionTitleLabel.text = "Prize Distribution"
        distributionTitleLabel.font = IndustrialDesign.Typography.h3
        distributionTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        distributionDescriptionLabel.text = "Distribute earned rewards to team members"
        distributionDescriptionLabel.font = IndustrialDesign.Typography.body
        distributionDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        distributionDescriptionLabel.numberOfLines = 0
        
        distributeRewardsButton.setTitle("Distribute Rewards", for: .normal)
        distributeRewardsButton.backgroundColor = IndustrialDesign.Colors.primaryOrange
        distributeRewardsButton.setTitleColor(.white, for: .normal)
        distributeRewardsButton.titleLabel?.font = IndustrialDesign.Typography.buttonText
        distributeRewardsButton.layer.cornerRadius = 8
        distributeRewardsButton.addTarget(self, action: #selector(distributeRewardsTapped), for: .touchUpInside)
        
        [distributionTitleLabel, distributionDescriptionLabel, distributeRewardsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            distributionContainer.addSubview($0)
        }
        
        contentView.addSubview(distributionContainer)
    }
    
    private func setupTransactionsSection() {
        transactionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        transactionsTitleLabel.text = "Recent Transactions"
        transactionsTitleLabel.font = IndustrialDesign.Typography.h3
        transactionsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        transactionsStackView.axis = .vertical
        transactionsStackView.spacing = 8
        transactionsStackView.distribution = .fill
        
        viewAllTransactionsButton.setTitle("View All", for: .normal)
        viewAllTransactionsButton.setTitleColor(IndustrialDesign.Colors.primaryBlue, for: .normal)
        viewAllTransactionsButton.titleLabel?.font = IndustrialDesign.Typography.buttonText
        viewAllTransactionsButton.addTarget(self, action: #selector(viewAllTransactionsTapped), for: .touchUpInside)
        
        [transactionsTitleLabel, transactionsStackView, viewAllTransactionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            transactionsContainer.addSubview($0)
        }
        
        contentView.addSubview(transactionsContainer)
    }
    
    private func setupLoadingAndErrorStates() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.primaryOrange
        loadingIndicator.hidesWhenStopped = true
        
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.font = IndustrialDesign.Typography.body
        errorLabel.textColor = IndustrialDesign.Colors.errorRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        [loadingIndicator, errorLabel].forEach {
            contentView.addSubview($0)
        }
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
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Balance section
            balanceContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            balanceContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            balanceContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            balanceCard.topAnchor.constraint(equalTo: balanceContainer.topAnchor),
            balanceCard.leadingAnchor.constraint(equalTo: balanceContainer.leadingAnchor),
            balanceCard.trailingAnchor.constraint(equalTo: balanceContainer.trailingAnchor),
            balanceCard.bottomAnchor.constraint(equalTo: balanceContainer.bottomAnchor),
            
            // Actions section
            actionsContainer.topAnchor.constraint(equalTo: balanceContainer.bottomAnchor, constant: 20),
            actionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionsContainer.heightAnchor.constraint(equalToConstant: 50),
            
            sendButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            sendButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            sendButton.heightAnchor.constraint(equalToConstant: 40),
            
            receiveButton.centerXAnchor.constraint(equalTo: actionsContainer.centerXAnchor),
            receiveButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            receiveButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            receiveButton.heightAnchor.constraint(equalToConstant: 40),
            
            historyButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            historyButton.centerYAnchor.constraint(equalTo: actionsContainer.centerYAnchor),
            historyButton.widthAnchor.constraint(equalTo: actionsContainer.widthAnchor, multiplier: 0.3),
            historyButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Distribution section
            distributionContainer.topAnchor.constraint(equalTo: actionsContainer.bottomAnchor, constant: 30),
            distributionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            distributionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            distributionTitleLabel.topAnchor.constraint(equalTo: distributionContainer.topAnchor),
            distributionTitleLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor),
            distributionTitleLabel.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor),
            
            distributionDescriptionLabel.topAnchor.constraint(equalTo: distributionTitleLabel.bottomAnchor, constant: 8),
            distributionDescriptionLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor),
            distributionDescriptionLabel.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor),
            
            distributeRewardsButton.topAnchor.constraint(equalTo: distributionDescriptionLabel.bottomAnchor, constant: 16),
            distributeRewardsButton.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor),
            distributeRewardsButton.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor),
            distributeRewardsButton.heightAnchor.constraint(equalToConstant: 48),
            distributeRewardsButton.bottomAnchor.constraint(equalTo: distributionContainer.bottomAnchor),
            
            // Transactions section
            transactionsContainer.topAnchor.constraint(equalTo: distributionContainer.bottomAnchor, constant: 30),
            transactionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            transactionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            transactionsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
            
            transactionsTitleLabel.topAnchor.constraint(equalTo: transactionsContainer.topAnchor),
            transactionsTitleLabel.leadingAnchor.constraint(equalTo: transactionsContainer.leadingAnchor),
            transactionsTitleLabel.trailingAnchor.constraint(equalTo: transactionsContainer.trailingAnchor),
            
            transactionsStackView.topAnchor.constraint(equalTo: transactionsTitleLabel.bottomAnchor, constant: 16),
            transactionsStackView.leadingAnchor.constraint(equalTo: transactionsContainer.leadingAnchor),
            transactionsStackView.trailingAnchor.constraint(equalTo: transactionsContainer.trailingAnchor),
            
            viewAllTransactionsButton.topAnchor.constraint(equalTo: transactionsStackView.bottomAnchor, constant: 16),
            viewAllTransactionsButton.centerXAnchor.constraint(equalTo: transactionsContainer.centerXAnchor),
            viewAllTransactionsButton.bottomAnchor.constraint(equalTo: transactionsContainer.bottomAnchor),
            
            // Loading and error states
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func sendBitcoinTapped() {
        paymentService.showSendBitcoinInterface(from: self)
    }
    
    @objc private func receiveBitcoinTapped() {
        paymentService.showReceiveBitcoinInterface(for: teamData, from: self)
    }
    
    @objc private func viewHistoryTapped() {
        // Navigate to full transaction history
        print("View transaction history - implement navigation")
    }
    
    @objc private func distributeRewardsTapped() {
        Task {
            await dataService.processRewardDistribution(for: teamData.id)
        }
    }
    
    @objc private func viewAllTransactionsTapped() {
        // Navigate to full transaction list
        print("View all transactions - implement navigation")
    }
    
    // MARK: - Helper Methods
    
    private func updateTransactionsList(_ transactions: [TeamTransaction]) {
        // Clear existing views
        transactionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add recent transactions (limit to 5)
        let recentTransactions = Array(transactions.prefix(5))
        
        for transaction in recentTransactions {
            let transactionView = createTransactionView(for: transaction)
            transactionsStackView.addArrangedSubview(transactionView)
        }
        
        if transactions.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No recent transactions"
            emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
            emptyLabel.font = IndustrialDesign.Typography.body
            emptyLabel.textAlignment = .center
            transactionsStackView.addArrangedSubview(emptyLabel)
        }
    }
    
    private func createTransactionView(for transaction: TeamTransaction) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = 8
        
        let typeLabel = UILabel()
        typeLabel.text = transaction.type.capitalized
        typeLabel.font = IndustrialDesign.Typography.h4
        typeLabel.textColor = IndustrialDesign.Colors.primaryText
        
        let amountLabel = UILabel()
        amountLabel.text = "\(transaction.amount > 0 ? "+" : "")\(transaction.amount) sats"
        amountLabel.font = IndustrialDesign.Typography.body
        amountLabel.textColor = transaction.amount > 0 ? IndustrialDesign.Colors.successGreen : IndustrialDesign.Colors.errorRed
        amountLabel.textAlignment = .right
        
        [typeLabel, amountLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            typeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            typeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            amountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            amountLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        return containerView
    }
}

// MARK: - TeamWalletDataDelegate

extension TeamWalletViewController: TeamWalletDataDelegate {
    
    func didUpdateCaptainStatus(_ isCaptain: Bool) {
        self.isCaptain = isCaptain
        
        // Enable/disable captain-only controls
        [sendButton, receiveButton, distributeRewardsButton].forEach {
            $0.isEnabled = isCaptain
            $0.alpha = isCaptain ? 1.0 : 0.5
        }
    }
    
    func didStartLoading() {
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
    }
    
    func didStopLoading() {
        loadingIndicator.stopAnimating()
    }
    
    func didLoadWalletData(balance: TeamWalletBalance, transactions: [TeamTransaction]) {
        teamWallet = balance
        balanceCard.updateBalance(Int(balance.totalBalance))
        updateTransactionsList(transactions)
    }
    
    func didLoadPendingDistributions(_ distributions: [PrizeDistribution]) {
        pendingDistributions = distributions
        
        let pendingAmount = distributions.reduce(0.0) { $0 + $1.totalPrize }
        if pendingAmount > 0 {
            distributionDescriptionLabel.text = "Pending distributions: \(pendingAmount) sats"
            distributeRewardsButton.setTitle("Distribute \(pendingAmount) sats", for: .normal)
        }
    }
    
    func didStartDistribution() {
        distributeRewardsButton.isEnabled = false
        distributeRewardsButton.setTitle("Distributing...", for: .normal)
    }
    
    func didCompleteDistribution(_ result: DistributionResult) {
        distributeRewardsButton.isEnabled = true
        distributeRewardsButton.setTitle("Distribute Rewards", for: .normal)
        
        // Show success message
        let alert = UIAlertController(
            title: "Distribution Complete",
            message: "Successfully distributed \(result.totalAmount) sats to \(result.recipientCount) members",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didFailDistribution(_ error: String) {
        distributeRewardsButton.isEnabled = true
        distributeRewardsButton.setTitle("Distribute Rewards", for: .normal)
        
        showError(error)
    }
    
    func didFailWithError(_ message: String) {
        showError(message)
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

// MARK: - TeamWalletPaymentDelegate

extension TeamWalletViewController: TeamWalletPaymentDelegate {
    
    func didStartPayment() {
        loadingIndicator.startAnimating()
    }
    
    func didCompletePayment(hash: String, amount: Int) {
        loadingIndicator.stopAnimating()
        
        let alert = UIAlertController(
            title: "Payment Sent",
            message: "Successfully sent \(amount) sats",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Reload wallet data
        Task {
            await dataService.loadWalletData(for: teamData.id)
        }
    }
    
    func didFailPayment(_ error: Error) {
        loadingIndicator.stopAnimating()
        showError(error.localizedDescription)
    }
    
    func didGenerateInvoice(_ invoice: LightningInvoice) {
        print("Invoice generated: \(invoice.paymentRequest)")
    }
}