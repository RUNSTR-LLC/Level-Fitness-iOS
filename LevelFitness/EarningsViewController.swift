import UIKit

class EarningsViewController: UIViewController {
    
    // MARK: - Properties
    private var walletData = WalletData(
        bitcoinBalance: 0.0042,
        usdBalance: 126.84,
        lastUpdated: Date()
    )
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = EarningsHeaderView()
    private let walletBalanceView = WalletBalanceView()
    private let transactionHistoryView = TransactionHistoryView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💰 LevelFitness: Loading earnings page...")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupWalletBalance()
        setupTransactionHistory()
        setupConstraints()
        configureWithData()
        
        print("💰 LevelFitness: Earnings loaded successfully!")
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
        
        let gear1 = RotatingGearView(size: 200)
        gear1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear1)
        
        let gear2 = RotatingGearView(size: 150)
        gear2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear2)
        
        NSLayoutConstraint.activate([
            gear1.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 30),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200),
            
            gear2.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 80),
            gear2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -40),
            gear2.widthAnchor.constraint(equalToConstant: 150),
            gear2.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        // Gear2 will rotate in opposite direction due to different size (150 vs 200)
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
        headerView.delegate = self
        contentView.addSubview(headerView)
    }
    
    private func setupWalletBalance() {
        walletBalanceView.translatesAutoresizingMaskIntoConstraints = false
        walletBalanceView.delegate = self
        contentView.addSubview(walletBalanceView)
    }
    
    private func setupTransactionHistory() {
        transactionHistoryView.translatesAutoresizingMaskIntoConstraints = false
        transactionHistoryView.delegate = self
        contentView.addSubview(transactionHistoryView)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Wallet Balance
            walletBalanceView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            walletBalanceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            walletBalanceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            walletBalanceView.heightAnchor.constraint(equalToConstant: 220),
            
            // Transaction History
            transactionHistoryView.topAnchor.constraint(equalTo: walletBalanceView.bottomAnchor),
            transactionHistoryView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            transactionHistoryView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            transactionHistoryView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            transactionHistoryView.heightAnchor.constraint(greaterThanOrEqualToConstant: 400)
        ])
    }
    
    private func configureWithData() {
        walletBalanceView.configure(with: walletData)
        transactionHistoryView.loadSampleTransactions()
    }
}

// MARK: - EarningsHeaderViewDelegate

extension EarningsViewController: EarningsHeaderViewDelegate {
    func didTapBackButton() {
        print("💰 LevelFitness: Earnings back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    func didTapSettingsButton() {
        print("💰 LevelFitness: Earnings settings tapped")
        // TODO: Implement earnings settings
    }
}

// MARK: - WalletBalanceViewDelegate

extension EarningsViewController: WalletBalanceViewDelegate {
    func didTapReceiveButton() {
        print("💰 LevelFitness: Receive button tapped")
        // TODO: Implement receive functionality
        showComingSoonAlert(for: "Receive Bitcoin")
    }
    
    func didTapSendButton() {
        print("💰 LevelFitness: Send button tapped")
        // TODO: Implement send functionality
        showComingSoonAlert(for: "Send Bitcoin")
    }
    
    private func showComingSoonAlert(for feature: String) {
        let alert = UIAlertController(
            title: "\(feature)",
            message: "This feature is coming soon! Bitcoin transactions will be available in the next update.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransactionHistoryViewDelegate

extension EarningsViewController: TransactionHistoryViewDelegate {
    func didTapTransaction(_ transaction: TransactionData) {
        print("💰 LevelFitness: Transaction tapped: \(transaction.title)")
        // TODO: Show transaction details
    }
    
    func didTapFilterButton() {
        print("💰 LevelFitness: Filter button tapped")
        // TODO: Implement transaction filtering
    }
}