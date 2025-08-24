import UIKit

class TeamWalletFundingViewController: UIViewController {
    
    // MARK: - Properties
    private let teamId: String
    private let teamName: String
    private var selectedAmount: Int = 0
    private var customAmount: Int = 0
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerContainer = UIView()
    private let closeButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Amount selection
    private let amountContainer = UIView()
    private let amountTitleLabel = UILabel()
    private let quickAmountButtons: [UIButton] = []
    private var quickAmountButtonsStackView = UIStackView()
    
    // Custom amount
    private let customContainer = UIView()
    private let customTitleLabel = UILabel()
    private let customAmountField = UITextField()
    private let satsLabel = UILabel()
    
    // QR Code and Invoice
    private let invoiceContainer = UIView()
    private let qrCodeImageView = UIImageView()
    private let invoiceLabel = UILabel()
    private let copyButton = UIButton(type: .custom)
    
    // Actions
    private let actionsContainer = UIView()
    private let generateButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    
    // Quick amount options (in satoshis)
    private let quickAmounts = [10000, 50000, 100000, 500000, 1000000] // 10k, 50k, 100k, 500k, 1M sats
    
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
        print("TeamWalletFunding: Initializing funding interface for team \(teamId)")
        
        setupView()
        setupConstraints()
        setupQuickAmountButtons()
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.clear
        scrollView.showsVerticalScrollIndicator = false
        
        // Content view with industrial styling
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        contentView.layer.cornerRadius = 20
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        // Gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 20
        contentView.layer.insertSublayer(gradient, at: 0)
        
        setupHeader()
        setupAmountSelection()
        setupCustomAmount()
        setupInvoiceSection()
        setupActions()
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerContainer)
        contentView.addSubview(amountContainer)
        contentView.addSubview(customContainer)
        contentView.addSubview(invoiceContainer)
        contentView.addSubview(actionsContainer)
    }
    
    private func setupHeader() {
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Close button
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.secondaryText
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Fund Team Wallet"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Subtitle
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Add Bitcoin to \(teamName)'s prize pool"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        
        headerContainer.addSubview(closeButton)
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(subtitleLabel)
    }
    
    private func setupAmountSelection() {
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        amountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        amountTitleLabel.text = "SELECT AMOUNT"
        amountTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        amountTitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        amountTitleLabel.letterSpacing = 1.0
        
        // Quick amount buttons stack view
        quickAmountButtonsStackView.translatesAutoresizingMaskIntoConstraints = false
        quickAmountButtonsStackView.axis = .horizontal
        quickAmountButtonsStackView.distribution = .fillEqually
        quickAmountButtonsStackView.spacing = 12
        
        amountContainer.addSubview(amountTitleLabel)
        amountContainer.addSubview(quickAmountButtonsStackView)
    }
    
    private func setupCustomAmount() {
        customContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        customTitleLabel.text = "CUSTOM AMOUNT"
        customTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        customTitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        customTitleLabel.letterSpacing = 1.0
        
        // Amount field container
        let fieldContainer = UIView()
        fieldContainer.translatesAutoresizingMaskIntoConstraints = false
        fieldContainer.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        fieldContainer.layer.cornerRadius = 12
        fieldContainer.layer.borderWidth = 1
        fieldContainer.layer.borderColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
        
        // Amount field
        customAmountField.translatesAutoresizingMaskIntoConstraints = false
        customAmountField.placeholder = "Enter amount"
        customAmountField.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        customAmountField.textColor = IndustrialDesign.Colors.primaryText
        customAmountField.backgroundColor = UIColor.clear
        customAmountField.borderStyle = .none
        customAmountField.keyboardType = .numberPad
        customAmountField.textAlignment = .center
        customAmountField.addTarget(self, action: #selector(customAmountChanged), for: .editingChanged)
        
        // Sats label
        satsLabel.translatesAutoresizingMaskIntoConstraints = false
        satsLabel.text = "sats"
        satsLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        satsLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        fieldContainer.addSubview(customAmountField)
        fieldContainer.addSubview(satsLabel)
        customContainer.addSubview(customTitleLabel)
        customContainer.addSubview(fieldContainer)
        
        // Field container constraints
        NSLayoutConstraint.activate([
            customAmountField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            customAmountField.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            
            satsLabel.leadingAnchor.constraint(equalTo: customAmountField.trailingAnchor, constant: 8),
            satsLabel.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor, constant: -16),
            satsLabel.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
            
            fieldContainer.topAnchor.constraint(equalTo: customTitleLabel.bottomAnchor, constant: 12),
            fieldContainer.leadingAnchor.constraint(equalTo: customContainer.leadingAnchor),
            fieldContainer.trailingAnchor.constraint(equalTo: customContainer.trailingAnchor),
            fieldContainer.bottomAnchor.constraint(equalTo: customContainer.bottomAnchor),
            fieldContainer.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupInvoiceSection() {
        invoiceContainer.translatesAutoresizingMaskIntoConstraints = false
        invoiceContainer.isHidden = true
        
        // QR Code
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeImageView.backgroundColor = UIColor.white
        qrCodeImageView.layer.cornerRadius = 12
        qrCodeImageView.contentMode = .scaleAspectFit
        
        // Invoice label
        invoiceLabel.translatesAutoresizingMaskIntoConstraints = false
        invoiceLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        invoiceLabel.textColor = IndustrialDesign.Colors.secondaryText
        invoiceLabel.numberOfLines = 0
        invoiceLabel.textAlignment = .center
        
        // Copy button
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        var copyConfig = UIButton.Configuration.filled()
        copyConfig.title = "Copy Invoice"
        copyConfig.image = UIImage(systemName: "doc.on.doc")
        copyConfig.baseBackgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        copyConfig.baseForegroundColor = .white
        copyButton.configuration = copyConfig
        copyButton.layer.cornerRadius = 8
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        
        invoiceContainer.addSubview(qrCodeImageView)
        invoiceContainer.addSubview(invoiceLabel)
        invoiceContainer.addSubview(copyButton)
    }
    
    private func setupActions() {
        actionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Generate button
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        var generateConfig = UIButton.Configuration.filled()
        generateConfig.title = "Generate Invoice"
        generateConfig.baseBackgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        generateConfig.baseForegroundColor = .white
        generateConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return outgoing
        }
        generateButton.configuration = generateConfig
        generateButton.layer.cornerRadius = 12
        generateButton.addTarget(self, action: #selector(generateButtonTapped), for: .touchUpInside)
        
        // Cancel button
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        var cancelConfig = UIButton.Configuration.plain()
        cancelConfig.title = "Cancel"
        cancelConfig.baseForegroundColor = IndustrialDesign.Colors.secondaryText
        cancelButton.configuration = cancelConfig
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        actionsContainer.addSubview(generateButton)
        actionsContainer.addSubview(cancelButton)
    }
    
    private func setupQuickAmountButtons() {
        for amount in quickAmounts {
            let button = createQuickAmountButton(amount: amount)
            quickAmountButtonsStackView.addArrangedSubview(button)
        }
    }
    
    private func createQuickAmountButton(amount: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Format amount for display
        let formattedAmount = formatSatsAmount(amount)
        
        var config = UIButton.Configuration.plain()
        config.title = formattedAmount
        config.baseForegroundColor = IndustrialDesign.Colors.primaryText
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }
        
        button.configuration = config
        button.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0).cgColor
        
        button.tag = amount
        button.addTarget(self, action: #selector(quickAmountButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func formatSatsAmount(_ amount: Int) -> String {
        if amount >= 1000000 {
            return "\(amount / 1000000)M"
        } else if amount >= 1000 {
            return "\(amount / 1000)K"
        } else {
            return "\(amount)"
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
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            // Header
            headerContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            closeButton.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            
            // Amount selection
            amountContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 32),
            amountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            amountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            amountTitleLabel.topAnchor.constraint(equalTo: amountContainer.topAnchor),
            amountTitleLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            
            quickAmountButtonsStackView.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 12),
            quickAmountButtonsStackView.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor),
            quickAmountButtonsStackView.trailingAnchor.constraint(equalTo: amountContainer.trailingAnchor),
            quickAmountButtonsStackView.bottomAnchor.constraint(equalTo: amountContainer.bottomAnchor),
            quickAmountButtonsStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // Custom amount
            customContainer.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 24),
            customContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            customContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            customTitleLabel.topAnchor.constraint(equalTo: customContainer.topAnchor),
            customTitleLabel.leadingAnchor.constraint(equalTo: customContainer.leadingAnchor),
            
            // Invoice section
            invoiceContainer.topAnchor.constraint(equalTo: customContainer.bottomAnchor, constant: 24),
            invoiceContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            invoiceContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            qrCodeImageView.topAnchor.constraint(equalTo: invoiceContainer.topAnchor),
            qrCodeImageView.centerXAnchor.constraint(equalTo: invoiceContainer.centerXAnchor),
            qrCodeImageView.widthAnchor.constraint(equalToConstant: 200),
            qrCodeImageView.heightAnchor.constraint(equalToConstant: 200),
            
            invoiceLabel.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 16),
            invoiceLabel.leadingAnchor.constraint(equalTo: invoiceContainer.leadingAnchor),
            invoiceLabel.trailingAnchor.constraint(equalTo: invoiceContainer.trailingAnchor),
            
            copyButton.topAnchor.constraint(equalTo: invoiceLabel.bottomAnchor, constant: 16),
            copyButton.centerXAnchor.constraint(equalTo: invoiceContainer.centerXAnchor),
            copyButton.bottomAnchor.constraint(equalTo: invoiceContainer.bottomAnchor),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            copyButton.widthAnchor.constraint(equalToConstant: 160),
            
            // Actions
            actionsContainer.topAnchor.constraint(equalTo: invoiceContainer.bottomAnchor, constant: 24),
            actionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            
            generateButton.topAnchor.constraint(equalTo: actionsContainer.topAnchor),
            generateButton.leadingAnchor.constraint(equalTo: actionsContainer.leadingAnchor),
            generateButton.trailingAnchor.constraint(equalTo: actionsContainer.trailingAnchor),
            generateButton.heightAnchor.constraint(equalToConstant: 52),
            
            cancelButton.topAnchor.constraint(equalTo: generateButton.bottomAnchor, constant: 8),
            cancelButton.centerXAnchor.constraint(equalTo: actionsContainer.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: actionsContainer.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func quickAmountButtonTapped(_ sender: UIButton) {
        selectedAmount = sender.tag
        customAmount = 0
        customAmountField.text = ""
        
        // Update button states
        updateQuickAmountButtonStates()
        updateGenerateButtonState()
        
        print("TeamWalletFunding: Selected quick amount: \(selectedAmount) sats")
    }
    
    @objc private func customAmountChanged() {
        guard let text = customAmountField.text, !text.isEmpty,
              let amount = Int(text), amount > 0 else {
            customAmount = 0
            selectedAmount = 0
            updateGenerateButtonState()
            return
        }
        
        customAmount = amount
        selectedAmount = 0 // Clear quick selection
        updateQuickAmountButtonStates()
        updateGenerateButtonState()
        
        print("TeamWalletFunding: Custom amount entered: \(customAmount) sats")
    }
    
    @objc private func generateButtonTapped() {
        let amount = selectedAmount > 0 ? selectedAmount : customAmount
        
        Task {
            do {
                await MainActor.run {
                    generateButton.isEnabled = false
                    generateButton.configuration?.title = "Generating..."
                }
                
                let invoice = try await TeamWalletManager.shared.fundTeamWallet(
                    teamId: teamId,
                    amount: amount,
                    memo: "Team wallet funding"
                )
                
                await MainActor.run {
                    showInvoice(invoice)
                }
                
            } catch {
                await MainActor.run {
                    showError(error)
                    generateButton.isEnabled = true
                    generateButton.configuration?.title = "Generate Invoice"
                }
            }
        }
    }
    
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = invoiceLabel.text
        
        // Show feedback
        let originalTitle = copyButton.configuration?.title
        copyButton.configuration?.title = "Copied!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.copyButton.configuration?.title = originalTitle
        }
    }
    
    @objc private func closeButtonTapped() {
        onCompletion?(false)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        onCompletion?(false)
        dismiss(animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func updateQuickAmountButtonStates() {
        for case let button as UIButton in quickAmountButtonsStackView.arrangedSubviews {
            let isSelected = button.tag == selectedAmount
            button.backgroundColor = isSelected 
                ? UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
                : UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
            button.configuration?.baseForegroundColor = isSelected ? .white : IndustrialDesign.Colors.primaryText
        }
    }
    
    private func updateGenerateButtonState() {
        let hasAmount = selectedAmount > 0 || customAmount > 0
        generateButton.isEnabled = hasAmount
        generateButton.alpha = hasAmount ? 1.0 : 0.6
    }
    
    private func showInvoice(_ invoice: LightningInvoice) {
        invoiceLabel.text = invoice.paymentRequest
        
        // Generate QR code
        if let qrImage = generateQRCode(from: invoice.paymentRequest) {
            qrCodeImageView.image = qrImage
        }
        
        // Show invoice section and hide generation button
        invoiceContainer.isHidden = false
        generateButton.isHidden = true
        
        print("TeamWalletFunding: Invoice generated successfully")
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Failed to Generate Invoice",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}