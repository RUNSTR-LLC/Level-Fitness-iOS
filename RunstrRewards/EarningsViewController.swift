import UIKit

class EarningsViewController: UIViewController {
    
    // MARK: - Properties
    private var walletData = WalletData(
        bitcoinBalance: 0.0000,
        usdBalance: 0.00,
        lastUpdated: Date()
    )
    private let lightningWalletManager = LightningWalletManager.shared
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = EarningsHeaderView()
    private let walletBalanceView = WalletBalanceView()
    private let transactionHistoryView = TransactionHistoryView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💰 RunstrRewards: Loading earnings page...")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupWalletBalance()
        setupTransactionHistory()
        setupConstraints()
        configureWithData()
        
        print("💰 RunstrRewards: Earnings loaded successfully!")
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
        loadRealEarningsData()
        loadLightningWalletBalance()
    }
    
    private func loadRealEarningsData() {
        Task {
            do {
                print("💰 RunstrRewards: Starting real earnings data load...")
                
                // Check user session first
                guard let userSession = AuthenticationService.shared.loadSession() else {
                    print("💰 RunstrRewards: No user session found for earnings")
                    await MainActor.run {
                        self.showErrorAlert("Please sign in again to access your wallet")
                        self.navigateToLogin()
                    }
                    return
                }
                
                print("💰 RunstrRewards: User session found: \(userSession.id)")
                
                // First ensure user has their own wallet
                _ = try await lightningWalletManager.getWalletBalance()
                
                // Fetch real Lightning transactions from user's CoinOS wallet
                let coinOSTransactions = try await CoinOSService.shared.listTransactions(limit: 100)
                
                await MainActor.run {
                    // Convert CoinOS transactions to TransactionData format
                    let transactionDataArray = coinOSTransactions.map { transaction in
                        let isEarning = transaction.amount > 0
                        let displayTitle = getTransactionTitle(transaction)
                        
                        return TransactionData(
                            id: transaction.id,
                            title: displayTitle,
                            source: "Lightning Network",
                            date: transaction.createdAt,
                            bitcoinAmount: Double(abs(transaction.amount)) / 100_000_000.0, // Convert sats to BTC
                            usdAmount: Double(abs(transaction.amount)) * 0.0005, // Approximate sats to USD (1 sat ≈ $0.0005)
                            type: isEarning ? .earning : .expense,
                            icon: getTransactionIcon(for: transaction.type)
                        )
                    }
                    
                    // Load real transaction history from user's wallet
                    transactionHistoryView.loadRealTransactions(transactionDataArray)
                    
                    print("💰 RunstrRewards: Loaded \(coinOSTransactions.count) real CoinOS Lightning transactions for current user")
                }
            } catch {
                await MainActor.run {
                    // Check if it's a UUID error and provide a more user-friendly message
                    if let errorDescription = (error as NSError).userInfo["NSLocalizedDescription"] as? String,
                       errorDescription.contains("invalid input syntax for type uuid") {
                        print("💰 RunstrRewards: UUID format error detected, attempting to fix...")
                        
                        // Clear the session and prompt user to sign in again
                        AuthenticationService.shared.clearSession()
                        
                        let alert = UIAlertController(
                            title: "Session Error",
                            message: "Your session data needs to be refreshed. Please sign in again.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Sign In", style: .default) { _ in
                            self.navigateToLogin()
                        })
                        self.present(alert, animated: true)
                    } else {
                        self.handleWalletError(error, context: "loadEarningsData")
                    }
                }
            }
        }
    }
    
    private func getTransactionTitle(_ transaction: CoinOSTransaction) -> String {
        if !transaction.memo.isEmpty {
            // Parse memo for meaningful titles
            if transaction.memo.contains("Geyser") {
                return "Geyser Donation"
            } else if transaction.memo.contains("SN:") {
                return "Stacker News"
            } else if transaction.memo.contains("Wavlake") {
                return "Wavlake Payment"
            } else if transaction.memo.contains("zap") {
                return "Lightning Zap"
            } else {
                return transaction.memo
            }
        }
        
        // Default titles based on amount
        if transaction.amount > 0 {
            return "Lightning Payment Received"
        } else {
            return "Lightning Payment Sent"
        }
    }
    
    private func getTransactionIcon(for type: String) -> TransactionIcon {
        switch type.lowercased() {
        case "reward", "earning", "lightning":
            return .star
        case "challenge":
            return .challenge
        case "event":
            return .event
        case "subscription":
            return .subscription
        case "withdrawal":
            return .withdrawal
        default:
            return .star
        }
    }
    
    private func loadLightningWalletBalance() {
        Task {
            do {
                print("💰 RunstrRewards: Loading Lightning wallet balance...")
                
                // Check user session first
                guard let userSession = AuthenticationService.shared.loadSession() else {
                    print("💰 RunstrRewards: No user session found for wallet balance")
                    await MainActor.run {
                        self.showErrorAlert("Please sign in again to access your wallet")
                    }
                    return
                }
                
                print("💰 RunstrRewards: Loading wallet balance for user: \(userSession.id)")
                let balance = try await lightningWalletManager.getWalletBalance()
                
                await MainActor.run {
                    // Convert satoshis to Bitcoin (1 BTC = 100,000,000 sats)
                    let bitcoinBalance = Double(balance.lightning) / 100_000_000
                    
                    // Update wallet data with real Lightning balance
                    walletData = WalletData(
                        bitcoinBalance: bitcoinBalance,
                        usdBalance: bitcoinBalance * 43000, // Approximate BTC price
                        lastUpdated: Date()
                    )
                    
                    // Refresh the wallet balance view with real data
                    walletBalanceView.configure(with: walletData)
                    
                    print("💰 RunstrRewards: Lightning balance loaded - \(balance.lightning) sats")
                }
            } catch {
                await MainActor.run {
                    self.handleWalletError(error, context: "loadLightningBalance", showAlert: false)
                    print("💰 RunstrRewards: Using mock data - Lightning wallet not configured")
                }
            }
        }
    }
    
    private func showEarningsErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error Loading Earnings",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadRealEarningsData()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - EarningsHeaderViewDelegate

extension EarningsViewController: EarningsHeaderViewDelegate {
    func didTapBackButton() {
        print("💰 RunstrRewards: Earnings back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - WalletBalanceViewDelegate

extension EarningsViewController: WalletBalanceViewDelegate {
    func didTapReceiveButton() {
        print("💰 RunstrRewards: Receive button tapped")
        showReceiveInvoiceDialog()
    }
    
    func didTapSendButton() {
        print("💰 RunstrRewards: Send button tapped")
        showSendPaymentDialog()
    }
    
    private func showReceiveInvoiceDialog() {
        let alert = UIAlertController(
            title: "Receive Bitcoin ⚡",
            message: "Enter amount in satoshis to generate Lightning invoice",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Amount (sats)"
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Memo (optional)"
        }
        
        let generateAction = UIAlertAction(title: "Generate Invoice", style: .default) { [weak self] _ in
            guard let amountText = alert.textFields?[0].text,
                  let amount = Int(amountText),
                  amount > 0 else {
                self?.showErrorAlert("Please enter a valid amount")
                return
            }
            
            let memo = alert.textFields?[1].text ?? ""
            self?.generateLightningInvoice(amount: amount, memo: memo)
        }
        
        alert.addAction(generateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSendPaymentDialog() {
        let alert = UIAlertController(
            title: "Send Bitcoin ⚡",
            message: "Paste Lightning invoice to send payment",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "Lightning invoice (lnbc...)"
            textField.autocapitalizationType = .none
        }
        
        let sendAction = UIAlertAction(title: "Send Payment", style: .default) { [weak self] _ in
            guard let invoice = alert.textFields?[0].text,
                  !invoice.isEmpty,
                  invoice.lowercased().hasPrefix("lnbc") else {
                self?.showErrorAlert("Please enter a valid Lightning invoice")
                return
            }
            
            self?.sendLightningPayment(invoice: invoice)
        }
        
        // Add debug action to test individual wallet creation
        let debugAction = UIAlertAction(title: "🔧 Reset & Create Individual Wallet", style: .destructive) { [weak self] _ in
            self?.testIndividualWalletCreation()
        }
        
        alert.addAction(sendAction)
        alert.addAction(debugAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func generateLightningInvoice(amount: Int, memo: String) {
        Task {
            do {
                print("💰 RunstrRewards: Generating Lightning invoice for \(amount) sats")
                let invoice = try await lightningWalletManager.createInvoice(amount: amount, memo: memo)
                
                await MainActor.run {
                    self.showInvoiceResult(invoice)
                }
            } catch {
                await MainActor.run {
                    self.handleWalletError(error, context: "generateLightningInvoice")
                }
            }
        }
    }
    
    private func sendLightningPayment(invoice: String) {
        Task {
            do {
                print("💰 RunstrRewards: Sending Lightning payment")
                let result = try await lightningWalletManager.payInvoice(invoice)
                
                await MainActor.run {
                    if result.success {
                        self.showSuccessAlert("Payment sent successfully! ⚡")
                        self.loadLightningWalletBalance() // Refresh balance
                        self.loadRealEarningsData() // Refresh transactions
                    } else {
                        self.showErrorAlert("Payment failed")
                    }
                }
            } catch {
                await MainActor.run {
                    self.handleWalletError(error, context: "sendLightningPayment")
                }
            }
        }
    }
    
    private func showInvoiceResult(_ invoice: LightningInvoice) {
        let alert = UIAlertController(
            title: "Lightning Invoice Generated ⚡",
            message: "Share this invoice to receive \(invoice.amount) sats",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Copy Invoice", style: .default) { _ in
            UIPasteboard.general.string = invoice.paymentRequest
            print("💰 RunstrRewards: Invoice copied to clipboard")
        })
        
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            let activityVC = UIActivityViewController(
                activityItems: [invoice.paymentRequest],
                applicationActivities: nil
            )
            self?.present(activityVC, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
    
    private func testIndividualWalletCreation() {
        Task {
            do {
                print("💰 RunstrRewards: Testing individual wallet creation...")
                
                // Clear existing credentials
                lightningWalletManager.clearExistingWallet()
                
                // Create new individual wallet
                let balance = try await lightningWalletManager.getWalletBalance()
                
                await MainActor.run {
                    self.showSuccessAlert("Individual wallet created successfully! Balance: \(balance.lightning) sats ⚡")
                    self.loadLightningWalletBalance() // Refresh display
                    self.loadRealEarningsData() // Refresh transactions
                }
                
            } catch {
                await MainActor.run {
                    print("💰 RunstrRewards: Individual wallet creation failed: \(error)")
                    if let coinOSError = error as? CoinOSError {
                        switch coinOSError {
                        case .apiError(let code):
                            self.showErrorAlert("CoinOS API Error: \(code)")
                        case .notAuthenticated:
                            self.showErrorAlert("Authentication failed")
                        default:
                            self.showErrorAlert("Wallet creation failed: \(coinOSError.localizedDescription)")
                        }
                    } else {
                        self.showErrorAlert("Failed to create individual wallet: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - TransactionHistoryViewDelegate

extension EarningsViewController: TransactionHistoryViewDelegate {
    func didTapTransaction(_ transaction: TransactionData) {
        print("💰 RunstrRewards: Transaction tapped: \(transaction.title)")
        // TODO: Show transaction details
    }
    
    func didTapFilterButton() {
        print("💰 RunstrRewards: Filter button tapped")
        // TODO: Implement transaction filtering
    }
    
    private func navigateToLogin() {
        // Navigate back to login screen
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let loginViewController = LoginViewController()
            
            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                window.rootViewController = loginViewController
            }, completion: nil)
            
            window.makeKeyAndVisible()
        }
    }
    
    private func handleWalletError(_ error: Error, context: String, showAlert: Bool = true) {
        print("💰 RunstrRewards: Error in \(context): \(error)")
        
        guard showAlert else { return }
        
        var message = error.localizedDescription
        
        // Handle specific CoinOS errors with user-friendly messages
        if let coinOSError = error as? CoinOSError {
            switch coinOSError {
            case .notAuthenticated:
                message = "Please sign in to your wallet again."
                navigateToLogin()
                return
            case .apiError(let code) where code == 500:
                message = "Insufficient funds. Please add Bitcoin to your wallet first."
            case .apiError(let code):
                message = "Service temporarily unavailable (Error \(code)). Please try again."
            case .walletCreationFailed:
                message = "Failed to create wallet. Please try again or contact support."
            default:
                break
            }
        } else if let walletError = error as? LightningWalletError {
            switch walletError {
            case .authenticationRequired:
                message = "Wallet authentication required. Please sign in again."
                navigateToLogin()
                return
            case .invoiceCreationFailed:
                message = "Failed to create invoice. Please check your connection and try again."
            case .paymentFailed:
                message = "Payment failed. Please check the invoice and your balance."
            default:
                break
            }
        }
        
        showErrorAlert(message)
    }
}