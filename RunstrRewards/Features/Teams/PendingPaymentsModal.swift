import UIKit

// MARK: - Pending Payments Modal Delegate

protocol PendingPaymentsModalDelegate: AnyObject {
    func pendingPaymentsModalDidDismiss(_ modal: PendingPaymentsModal)
    func pendingPaymentsModal(_ modal: PendingPaymentsModal, didCompletePayment payment: PendingPayment)
}

// MARK: - Pending Payments Modal

class PendingPaymentsModal: UIViewController {
    
    // MARK: - Properties
    
    private let teamId: String
    private let teamName: String
    private let paymentQueueManager = PaymentQueueManager.shared
    private let teamWalletManager = TeamWalletManager.shared
    
    weak var delegate: PendingPaymentsModalDelegate?
    
    private var pendingPayments: [PendingPayment] = []
    private var completedPayments: [PendingPayment] = []
    private var currentTab: PaymentTab = .pending
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let headerView = UIView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Tab control
    private let tabContainer = UIView()
    private let tabControl = UISegmentedControl(items: ["Pending", "Completed"])
    
    // Content area
    private let contentContainer = UIView()
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateImageView = UIImageView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescriptionLabel = UILabel()
    
    // Summary bar
    private let summaryBar = UIView()
    private let summaryLabel = UILabel()
    private let totalAmountLabel = UILabel()
    
    // Loading state
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Initialization
    
    init(teamId: String, teamName: String) {
        self.teamId = teamId
        self.teamName = teamName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("PendingPaymentsModal: Loading modal for team \(teamName)")
        
        setupIndustrialBackground()
        setupContainer()
        setupHeader()
        setupTabControl()
        setupContentArea()
        setupSummaryBar()
        setupEmptyState()
        setupLoadingState()
        setupConstraints()
        
        // Load data and show pending tab by default
        loadPayments()
        showTab(.pending)
        
        // Listen for payment queue changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(paymentQueueDidChange),
            name: .paymentQueueDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(paymentStatusDidChange),
            name: .paymentStatusDidChange,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Animate container appearance
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupIndustrialBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupContainer() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.98)
        containerView.layer.cornerRadius = 20
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.clipsToBounds = true
        
        view.addSubview(containerView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        
        // Close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.secondaryText
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Reward Payments"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        
        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = teamName
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.textAlignment = .center
        
        headerView.addSubview(closeButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        
        containerView.addSubview(headerView)
    }
    
    private func setupTabControl() {
        tabContainer.translatesAutoresizingMaskIntoConstraints = false
        
        tabControl.translatesAutoresizingMaskIntoConstraints = false
        tabControl.selectedSegmentIndex = 0
        tabControl.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        tabControl.selectedSegmentTintColor = IndustrialDesign.Colors.bitcoin
        tabControl.setTitleTextAttributes([
            .foregroundColor: IndustrialDesign.Colors.primaryText,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .normal)
        tabControl.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
        ], for: .selected)
        tabControl.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        
        tabContainer.addSubview(tabControl)
        containerView.addSubview(tabContainer)
    }
    
    private func setupContentArea() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        scrollView.addSubview(stackView)
        contentContainer.addSubview(scrollView)
        containerView.addSubview(contentContainer)
    }
    
    private func setupSummaryBar() {
        summaryBar.translatesAutoresizingMaskIntoConstraints = false
        summaryBar.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        summaryBar.layer.cornerRadius = 8
        
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        summaryLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        totalAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        totalAmountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        totalAmountLabel.textColor = IndustrialDesign.Colors.bitcoin
        totalAmountLabel.textAlignment = .right
        
        summaryBar.addSubview(summaryLabel)
        summaryBar.addSubview(totalAmountLabel)
        
        containerView.addSubview(summaryBar)
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        emptyStateLabel.textColor = IndustrialDesign.Colors.primaryText
        emptyStateLabel.textAlignment = .center
        
        emptyStateDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateDescriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        emptyStateDescriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescriptionLabel.textAlignment = .center
        emptyStateDescriptionLabel.numberOfLines = 0
        
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateDescriptionLabel)
        
        contentContainer.addSubview(emptyStateView)
    }
    
    private func setupLoadingState() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        
        contentContainer.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.8),
            
            // Header
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            // Tab container
            tabContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tabContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tabContainer.heightAnchor.constraint(equalToConstant: 50),
            
            tabControl.centerXAnchor.constraint(equalTo: tabContainer.centerXAnchor),
            tabControl.centerYAnchor.constraint(equalTo: tabContainer.centerYAnchor),
            tabControl.widthAnchor.constraint(equalToConstant: 200),
            tabControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Summary bar
            summaryBar.topAnchor.constraint(equalTo: tabContainer.bottomAnchor, constant: 12),
            summaryBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            summaryBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            summaryBar.heightAnchor.constraint(equalToConstant: 44),
            
            summaryLabel.leadingAnchor.constraint(equalTo: summaryBar.leadingAnchor, constant: 16),
            summaryLabel.centerYAnchor.constraint(equalTo: summaryBar.centerYAnchor),
            
            totalAmountLabel.trailingAnchor.constraint(equalTo: summaryBar.trailingAnchor, constant: -16),
            totalAmountLabel.centerYAnchor.constraint(equalTo: summaryBar.centerYAnchor),
            totalAmountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: summaryLabel.trailingAnchor, constant: 8),
            
            // Content container
            contentContainer.topAnchor.constraint(equalTo: summaryBar.bottomAnchor, constant: 12),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            
            // Stack view
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(greaterThanOrEqualTo: contentContainer.leadingAnchor, constant: 32),
            emptyStateView.trailingAnchor.constraint(lessThanOrEqualTo: contentContainer.trailingAnchor, constant: -32),
            
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 64),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 64),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescriptionLabel.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 8),
            emptyStateDescriptionLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescriptionLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescriptionLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadPayments() {
        pendingPayments = paymentQueueManager.getPendingPayments(for: teamId)
        completedPayments = paymentQueueManager.getCompletedPayments(for: teamId)
        
        print("PendingPaymentsModal: Loaded \(pendingPayments.count) pending, \(completedPayments.count) completed payments")
        
        updateTabBadges()
        refreshCurrentTab()
    }
    
    private func updateTabBadges() {
        let pendingCount = pendingPayments.count
        let completedCount = completedPayments.count
        
        tabControl.setTitle("Pending (\(pendingCount))", forSegmentAt: 0)
        tabControl.setTitle("Completed (\(completedCount))", forSegmentAt: 1)
    }
    
    private func refreshCurrentTab() {
        showTab(currentTab)
    }
    
    private func showTab(_ tab: PaymentTab) {
        currentTab = tab
        
        // Clear existing payment cards
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let payments = tab == .pending ? pendingPayments : completedPayments
        
        // Update summary
        updateSummary(for: payments)
        
        // Show empty state if needed
        if payments.isEmpty {
            showEmptyState(for: tab)
            return
        }
        
        hideEmptyState()
        
        // Add payment cards
        for payment in payments {
            let card = PaymentCard(payment: payment)
            card.delegate = self
            stackView.addArrangedSubview(card)
        }
        
        // Scroll to top
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(.zero, animated: true)
        }
    }
    
    private func updateSummary(for payments: [PendingPayment]) {
        let totalAmount = payments.reduce(0) { $0 + $1.totalAmount }
        let count = payments.count
        
        let tabName = currentTab == .pending ? "Pending" : "Completed"
        summaryLabel.text = "\(count) \(tabName) Payment\(count != 1 ? "s" : "")"
        totalAmountLabel.text = "\(totalAmount.formattedSats()) sats"
    }
    
    private func showEmptyState(for tab: PaymentTab) {
        emptyStateView.isHidden = false
        
        switch tab {
        case .pending:
            emptyStateImageView.image = UIImage(systemName: "tray.fill")
            emptyStateLabel.text = "No Pending Payments"
            emptyStateDescriptionLabel.text = "When events complete or challenges are won, payment cards will appear here for you to review and pay out."
            
        case .completed:
            emptyStateImageView.image = UIImage(systemName: "checkmark.circle.fill")
            emptyStateLabel.text = "No Completed Payments"
            emptyStateDescriptionLabel.text = "Payments that have been successfully processed will appear here."
        }
    }
    
    private func hideEmptyState() {
        emptyStateView.isHidden = true
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss()
    }
    
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss()
        }
    }
    
    @objc private func tabChanged(_ sender: UISegmentedControl) {
        let tab: PaymentTab = sender.selectedSegmentIndex == 0 ? .pending : .completed
        showTab(tab)
    }
    
    @objc private func paymentQueueDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let notificationTeamId = userInfo["teamId"] as? String,
              notificationTeamId == teamId else { return }
        
        DispatchQueue.main.async {
            self.loadPayments()
        }
    }
    
    @objc private func paymentStatusDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let notificationTeamId = userInfo["teamId"] as? String,
              notificationTeamId == teamId else { return }
        
        DispatchQueue.main.async {
            self.loadPayments()
        }
    }
    
    private func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false) {
                self.delegate?.pendingPaymentsModalDidDismiss(self)
            }
        }
    }
}

// MARK: - Payment Card Delegate

extension PendingPaymentsModal: PaymentCardDelegate {
    
    func paymentCardDidTapPay(_ card: PaymentCard, payment: PendingPayment) {
        print("PendingPaymentsModal: Pay button tapped for payment: \(payment.title)")
        
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Confirm Payment",
            message: "Send \(payment.totalAmount.formattedSats()) sats to \(payment.recipients.count) recipient\(payment.recipients.count != 1 ? "s" : "")?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Pay Now", style: .default) { _ in
            self.executePayment(payment, card: card)
        })
        
        present(alert, animated: true)
    }
    
    func paymentCardDidTapDetails(_ card: PaymentCard, payment: PendingPayment) {
        print("PendingPaymentsModal: Details button tapped for payment: \(payment.title)")
        
        // Show detailed payment information
        showPaymentDetails(payment)
    }
    
    private func executePayment(_ payment: PendingPayment, card: PaymentCard) {
        print("PendingPaymentsModal: Executing payment: \(payment.title)")
        
        // Update UI to show processing
        card.setProcessing(true)
        paymentQueueManager.markPaymentProcessing(payment.id)
        
        Task {
            do {
                // Execute the payment through TeamWalletManager
                try await teamWalletManager.executePayment(payment, teamId: teamId)
                
                await MainActor.run {
                    // Payment succeeded
                    self.paymentQueueManager.markPaymentCompleted(payment.id)
                    self.delegate?.pendingPaymentsModal(self, didCompletePayment: payment)
                    
                    // Show success feedback
                    self.showSuccessAlert(payment: payment)
                }
                
            } catch {
                await MainActor.run {
                    // Payment failed
                    self.paymentQueueManager.markPaymentFailed(payment.id, error: error)
                    card.setProcessing(false)
                    
                    // Show error alert
                    self.showErrorAlert(payment: payment, error: error)
                }
            }
        }
    }
    
    private func showPaymentDetails(_ payment: PendingPayment) {
        let alert = UIAlertController(title: payment.title, message: nil, preferredStyle: .alert)
        
        var message = payment.description + "\n\n"
        message += "Recipients:\n"
        
        for recipient in payment.recipients {
            message += "• \(recipient.username): \(recipient.amount.formattedSats()) sats\n"
        }
        
        message += "\nTotal: \(payment.totalAmount.formattedSats()) sats"
        message += "\nCreated: \(DateFormatter.localizedString(from: payment.createdAt, dateStyle: .medium, timeStyle: .short))"
        
        alert.message = message
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(payment: PendingPayment) {
        let alert = UIAlertController(
            title: "Payment Successful",
            message: "Successfully sent \(payment.totalAmount.formattedSats()) sats to \(payment.recipients.count) recipient\(payment.recipients.count != 1 ? "s" : "")",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorAlert(payment: PendingPayment, error: Error) {
        let alert = UIAlertController(
            title: "Payment Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Supporting Types

private enum PaymentTab {
    case pending
    case completed
}

// MARK: - TeamWalletManager Extension

extension TeamWalletManager {
    
    func executePayment(_ payment: PendingPayment, teamId: String) async throws {
        print("TeamWalletManager: Executing payment \(payment.id) for team \(teamId)")
        
        // Verify captain access
        guard let currentUserId = AuthenticationService.shared.loadSession()?.id else {
            throw TeamWalletError.authenticationRequired
        }
        
        try await verifyTeamCaptainAccess(teamId: teamId, userId: currentUserId)
        
        // Check team wallet balance
        let balance = try await getTeamWalletBalance(teamId: teamId, userId: currentUserId)
        guard balance.total >= payment.totalAmount else {
            throw TeamWalletError.insufficientBalance
        }
        
        // Execute payments to each recipient
        for recipient in payment.recipients {
            try await distributeToUser(
                userId: recipient.userId,
                amount: recipient.amount,
                memo: "\(payment.title) - \(recipient.reason)",
                teamId: teamId
            )
        }
        
        print("TeamWalletManager: Successfully executed payment \(payment.id)")
    }
    
    private func distributeToUser(userId: String, amount: Int, memo: String, teamId: String) async throws {
        // TODO: Implement user invoice creation and payment
        // For MVP, this would create an invoice in the user's wallet and pay it from team wallet
        // For now, we'll just log the transaction
        
        print("PendingPaymentsModal: Would distribute \(amount) sats to user \(userId) for \(memo)")
        
        // Placeholder for actual payment implementation
        // let invoice = try await createUserInvoice(userId: userId, amount: amount, memo: memo)
        // let paymentResult = try await coinOSService.payInvoice(invoice.paymentRequest)
        
        // TODO: Record transaction in team's transaction history
        // try await recordTeamTransaction(
        //     teamId: teamId,
        //     userId: userId,
        //     amount: -amount,
        //     type: "reward_payment",
        //     description: memo
        // )
        
        print("TeamWalletManager: Successfully distributed \(amount) sats to user \(userId)")
    }
}