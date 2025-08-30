import UIKit

// MARK: - Payment Card Delegate

protocol PaymentCardDelegate: AnyObject {
    func paymentCardDidTapPay(_ card: PaymentCard, payment: PendingPayment)
    func paymentCardDidTapDetails(_ card: PaymentCard, payment: PendingPayment)
}

// MARK: - Payment Card View

class PaymentCard: UIView {
    
    // MARK: - Properties
    
    var payment: PendingPayment {
        didSet {
            updateContent()
        }
    }
    
    weak var delegate: PaymentCardDelegate?
    
    // MARK: - UI Components
    
    private let containerView = UIView()
    private let headerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    
    private let amountContainer = UIView()
    private let totalAmountLabel = UILabel()
    private let totalAmountValueLabel = UILabel()
    
    private let recipientsContainer = UIView()
    private let recipientsTitleLabel = UILabel()
    private let recipientsStackView = UIStackView()
    private let showAllRecipientsButton = UIButton(type: .custom)
    
    private let buttonsContainer = UIView()
    private let payNowButton = UIButton(type: .custom)
    private let detailsButton = UIButton(type: .custom)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private var isExpanded = false
    private let maxVisibleRecipients = 3
    
    // MARK: - Initialization
    
    init(payment: PendingPayment) {
        self.payment = payment
        super.init(frame: .zero)
        setupView()
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        setupContainer()
        setupHeader()
        setupAmountSection()
        setupRecipientsSection()
        setupButtons()
        setupConstraints()
        setupStyling()
    }
    
    private func setupContainer() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.9)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Add subtle shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        containerView.layer.shadowOpacity = 0.1
        
        addSubview(containerView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = payment.type.iconColor
        iconImageView.image = UIImage(systemName: payment.type.icon)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        // Description
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 2
        
        // Status badge
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.layer.cornerRadius = 8
        statusBadge.backgroundColor = payment.status.color.withAlphaComponent(0.2)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        statusLabel.textColor = payment.status.color
        statusLabel.textAlignment = .center
        
        statusBadge.addSubview(statusLabel)
        
        headerView.addSubview(iconImageView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(descriptionLabel)
        headerView.addSubview(statusBadge)
        
        containerView.addSubview(headerView)
    }
    
    private func setupAmountSection() {
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        totalAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        totalAmountLabel.text = "Total:"
        totalAmountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        totalAmountLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        totalAmountValueLabel.translatesAutoresizingMaskIntoConstraints = false
        totalAmountValueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        totalAmountValueLabel.textColor = IndustrialDesign.Colors.bitcoin
        
        amountContainer.addSubview(totalAmountLabel)
        amountContainer.addSubview(totalAmountValueLabel)
        containerView.addSubview(amountContainer)
    }
    
    private func setupRecipientsSection() {
        recipientsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        recipientsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        recipientsTitleLabel.text = payment.recipients.count == 1 ? "Recipient:" : "Recipients:"
        recipientsTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        recipientsTitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        recipientsStackView.translatesAutoresizingMaskIntoConstraints = false
        recipientsStackView.axis = .vertical
        recipientsStackView.spacing = 6
        recipientsStackView.alignment = .fill
        recipientsStackView.distribution = .fill
        
        showAllRecipientsButton.translatesAutoresizingMaskIntoConstraints = false
        showAllRecipientsButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        showAllRecipientsButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        showAllRecipientsButton.addTarget(self, action: #selector(toggleExpanded), for: .touchUpInside)
        
        recipientsContainer.addSubview(recipientsTitleLabel)
        recipientsContainer.addSubview(recipientsStackView)
        recipientsContainer.addSubview(showAllRecipientsButton)
        containerView.addSubview(recipientsContainer)
    }
    
    private func setupButtons() {
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Pay Now button
        payNowButton.translatesAutoresizingMaskIntoConstraints = false
        payNowButton.setTitle("Pay Now", for: .normal)
        payNowButton.setTitleColor(.white, for: .normal)
        payNowButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        payNowButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        payNowButton.layer.cornerRadius = 8
        payNowButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        
        // Details button
        detailsButton.translatesAutoresizingMaskIntoConstraints = false
        detailsButton.setTitle("Details", for: .normal)
        detailsButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        detailsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        detailsButton.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        detailsButton.layer.cornerRadius = 8
        detailsButton.layer.borderWidth = 1
        detailsButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        detailsButton.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        
        buttonsContainer.addSubview(payNowButton)
        buttonsContainer.addSubview(detailsButton)
        payNowButton.addSubview(loadingIndicator)
        
        containerView.addSubview(buttonsContainer)
    }
    
    private func setupStyling() {
        // Add subtle animations on touch
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        tapGesture.cancelsTouchesInView = false
        containerView.addGestureRecognizer(tapGesture)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: headerView.topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: -8),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            
            // Status badge
            statusBadge.topAnchor.constraint(equalTo: headerView.topAnchor),
            statusBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 80),
            statusBadge.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            
            // Amount section
            amountContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            amountContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            amountContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            totalAmountLabel.topAnchor.constraint(equalTo: amountContainer.topAnchor),
            totalAmountLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            totalAmountLabel.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor),
            
            totalAmountValueLabel.centerYAnchor.constraint(equalTo: totalAmountLabel.centerYAnchor),
            totalAmountValueLabel.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor),
            
            // Recipients section
            recipientsContainer.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 16),
            recipientsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            recipientsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            recipientsTitleLabel.topAnchor.constraint(equalTo: recipientsContainer.topAnchor),
            recipientsTitleLabel.leadingAnchor.constraint(equalTo: recipientsContainer.leadingAnchor),
            recipientsTitleLabel.trailingAnchor.constraint(equalTo: recipientsContainer.trailingAnchor),
            
            recipientsStackView.topAnchor.constraint(equalTo: recipientsTitleLabel.bottomAnchor, constant: 8),
            recipientsStackView.leadingAnchor.constraint(equalTo: recipientsContainer.leadingAnchor),
            recipientsStackView.trailingAnchor.constraint(equalTo: recipientsContainer.trailingAnchor),
            
            showAllRecipientsButton.topAnchor.constraint(equalTo: recipientsStackView.bottomAnchor, constant: 8),
            showAllRecipientsButton.leadingAnchor.constraint(equalTo: recipientsContainer.leadingAnchor),
            showAllRecipientsButton.bottomAnchor.constraint(equalTo: recipientsContainer.bottomAnchor),
            
            // Buttons
            buttonsContainer.topAnchor.constraint(equalTo: recipientsContainer.bottomAnchor, constant: 16),
            buttonsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            buttonsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            buttonsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 44),
            
            payNowButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            payNowButton.leadingAnchor.constraint(equalTo: buttonsContainer.leadingAnchor),
            payNowButton.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor),
            payNowButton.widthAnchor.constraint(equalTo: buttonsContainer.widthAnchor, multiplier: 0.65),
            
            detailsButton.topAnchor.constraint(equalTo: buttonsContainer.topAnchor),
            detailsButton.trailingAnchor.constraint(equalTo: buttonsContainer.trailingAnchor),
            detailsButton.bottomAnchor.constraint(equalTo: buttonsContainer.bottomAnchor),
            detailsButton.leadingAnchor.constraint(equalTo: payNowButton.trailingAnchor, constant: 12),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: payNowButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: payNowButton.centerYAnchor)
        ])
    }
    
    // MARK: - Content Updates
    
    private func updateContent() {
        titleLabel.text = payment.title
        descriptionLabel.text = payment.description
        statusLabel.text = payment.status.displayName.uppercased()
        statusBadge.backgroundColor = payment.status.color.withAlphaComponent(0.2)
        statusLabel.textColor = payment.status.color
        
        totalAmountValueLabel.text = "\(payment.totalAmount.formattedSats()) sats"
        
        iconImageView.image = UIImage(systemName: payment.type.icon)
        iconImageView.tintColor = payment.type.iconColor
        
        updateRecipientsList()
        updateButtonStates()
    }
    
    private func updateRecipientsList() {
        // Clear existing recipient views
        recipientsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let recipientsToShow = isExpanded ? payment.recipients : Array(payment.recipients.prefix(maxVisibleRecipients))
        
        for recipient in recipientsToShow {
            let recipientView = createRecipientView(recipient)
            recipientsStackView.addArrangedSubview(recipientView)
        }
        
        // Show/hide expand button
        let hasMoreRecipients = payment.recipients.count > maxVisibleRecipients
        showAllRecipientsButton.isHidden = !hasMoreRecipients
        
        if hasMoreRecipients {
            let remainingCount = payment.recipients.count - maxVisibleRecipients
            let buttonTitle = isExpanded ? "Show Less" : "Show \(remainingCount) More"
            showAllRecipientsButton.setTitle(buttonTitle, for: .normal)
        }
    }
    
    private func createRecipientView(_ recipient: PaymentRecipient) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        
        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        amountLabel.textColor = IndustrialDesign.Colors.bitcoin
        amountLabel.textAlignment = .right
        
        // Format the display text
        var displayText = recipient.username
        if let position = recipient.position {
            let emoji = position == 1 ? "🥇" : position == 2 ? "🥈" : position == 3 ? "🥉" : "🏆"
            displayText = "\(emoji) \(recipient.username)"
        }
        
        nameLabel.text = displayText
        amountLabel.text = "\(recipient.amount.formattedSats()) sats"
        
        view.addSubview(nameLabel)
        view.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: view.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            amountLabel.topAnchor.constraint(equalTo: view.topAnchor),
            amountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            amountLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return view
    }
    
    private func updateButtonStates() {
        switch payment.status {
        case .pending:
            payNowButton.isEnabled = true
            payNowButton.backgroundColor = IndustrialDesign.Colors.bitcoin
            payNowButton.setTitle("Pay Now", for: .normal)
            
        case .processing:
            payNowButton.isEnabled = false
            payNowButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.6)
            payNowButton.setTitle("Processing...", for: .normal)
            
        case .completed:
            payNowButton.isEnabled = false
            payNowButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.6)
            payNowButton.setTitle("Completed", for: .normal)
            
        case .failed:
            payNowButton.isEnabled = true
            payNowButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
            payNowButton.setTitle("Retry", for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func payButtonTapped() {
        delegate?.paymentCardDidTapPay(self, payment: payment)
    }
    
    @objc private func detailsButtonTapped() {
        delegate?.paymentCardDidTapDetails(self, payment: payment)
    }
    
    @objc private func toggleExpanded() {
        isExpanded.toggle()
        updateRecipientsList()
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }
    
    @objc private func cardTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
    
    // MARK: - Public Methods
    
    func setProcessing(_ isProcessing: Bool) {
        if isProcessing {
            loadingIndicator.startAnimating()
            payNowButton.setTitle("", for: .normal)
            payNowButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            updateButtonStates()
        }
    }
}

// MARK: - Int Extensions for Formatting

extension Int {
    func formattedSats() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}