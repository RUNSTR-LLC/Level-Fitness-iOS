import UIKit
import CoreImage

class PaymentInstructionsViewController: UIViewController {
    
    // MARK: - Properties
    private let challengeId: String
    private let stakeAmount: Int
    private let paymentInstructions: PaymentInstructions
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton(type: .custom)
    
    // Amount section
    private let amountContainer = UIView()
    private let amountLabel = UILabel()
    private let bitcoinSymbolLabel = UILabel()
    private let usdEquivalentLabel = UILabel()
    
    // Payment instructions section
    private let instructionsContainer = UIView()
    private let instructionsTitleLabel = UILabel()
    private let instructionsTextLabel = UILabel()
    
    // Lightning address section
    private let addressContainer = UIView()
    private let addressTitleLabel = UILabel()
    private let addressLabel = UILabel()
    private let copyAddressButton = UIButton(type: .custom)
    
    // Memo section
    private let memoContainer = UIView()
    private let memoTitleLabel = UILabel()
    private let memoLabel = UILabel()
    private let copyMemoButton = UIButton(type: .custom)
    
    // QR Code section
    private let qrContainer = UIView()
    private let qrTitleLabel = UILabel()
    private let qrImageView = UIImageView()
    
    // Action buttons
    private let buttonContainer = UIView()
    private let confirmPaymentButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .custom)
    
    // Loading indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Completion handler
    var onPaymentConfirmed: (() -> Void)?
    var onCancelled: (() -> Void)?
    
    // MARK: - Initialization
    
    init(challengeId: String, stakeAmount: Int) {
        self.challengeId = challengeId
        self.stakeAmount = stakeAmount
        self.paymentInstructions = P2PChallengeService.shared.getPaymentInstructions(
            challengeId: challengeId,
            userId: AuthenticationService.shared.currentUserId ?? ""
        )
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💰 PaymentInstructions: Loading payment UI for \(stakeAmount) sats")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupAmountSection()
        setupInstructionsSection()
        setupAddressSection()
        setupMemoSection()
        setupQRCodeSection()
        setupActionButtons()
        setupLoadingIndicator()
        setupConstraints()
        
        generateQRCode()
        
        print("💰 PaymentInstructions: UI setup complete")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Animate in
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let containerView = UIView()
        containerView.backgroundColor = IndustrialDesign.Colors.background
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        containerView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85),
            
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        
        titleLabel.text = "Payment Required"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Send Bitcoin to confirm your challenge stake"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = IndustrialDesign.Colors.secondaryText
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(closeButton)
        contentView.addSubview(headerView)
    }
    
    private func setupAmountSection() {
        amountContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        amountContainer.layer.cornerRadius = 12
        amountContainer.layer.borderWidth = 1
        amountContainer.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        amountContainer.translatesAutoresizingMaskIntoConstraints = false
        
        bitcoinSymbolLabel.text = "₿"
        bitcoinSymbolLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        bitcoinSymbolLabel.textColor = IndustrialDesign.Colors.bitcoin
        bitcoinSymbolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountLabel.text = "\(stakeAmount.formatted()) sats"
        amountLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        amountLabel.textColor = IndustrialDesign.Colors.primaryText
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate approximate USD equivalent (mock calculation)
        let usdAmount = Double(stakeAmount) * 0.0001 // Rough estimate
        usdEquivalentLabel.text = "≈ $\(String(format: "%.2f", usdAmount))"
        usdEquivalentLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        usdEquivalentLabel.textColor = IndustrialDesign.Colors.secondaryText
        usdEquivalentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountContainer.addSubview(bitcoinSymbolLabel)
        amountContainer.addSubview(amountLabel)
        amountContainer.addSubview(usdEquivalentLabel)
        contentView.addSubview(amountContainer)
    }
    
    private func setupInstructionsSection() {
        instructionsContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        instructionsContainer.layer.cornerRadius = 12
        instructionsContainer.layer.borderWidth = 1
        instructionsContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        instructionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsTitleLabel.text = "Instructions"
        instructionsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        instructionsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        instructionsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsTextLabel.text = paymentInstructions.instructions
        instructionsTextLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        instructionsTextLabel.textColor = IndustrialDesign.Colors.secondaryText
        instructionsTextLabel.numberOfLines = 0
        instructionsTextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsContainer.addSubview(instructionsTitleLabel)
        instructionsContainer.addSubview(instructionsTextLabel)
        contentView.addSubview(instructionsContainer)
    }
    
    private func setupAddressSection() {
        addressContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        addressContainer.layer.cornerRadius = 12
        addressContainer.layer.borderWidth = 1
        addressContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        addressContainer.translatesAutoresizingMaskIntoConstraints = false
        
        addressTitleLabel.text = "Lightning Address"
        addressTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        addressTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        addressTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addressLabel.text = paymentInstructions.lightningAddress
        addressLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        addressLabel.textColor = IndustrialDesign.Colors.bitcoin
        addressLabel.numberOfLines = 0
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        copyAddressButton.setTitle("Copy", for: .normal)
        copyAddressButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        copyAddressButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        copyAddressButton.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.1)
        copyAddressButton.layer.cornerRadius = 8
        copyAddressButton.layer.borderWidth = 1
        copyAddressButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        copyAddressButton.translatesAutoresizingMaskIntoConstraints = false
        copyAddressButton.addTarget(self, action: #selector(copyAddressTapped), for: .touchUpInside)
        
        addressContainer.addSubview(addressTitleLabel)
        addressContainer.addSubview(addressLabel)
        addressContainer.addSubview(copyAddressButton)
        contentView.addSubview(addressContainer)
    }
    
    private func setupMemoSection() {
        memoContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        memoContainer.layer.cornerRadius = 12
        memoContainer.layer.borderWidth = 1
        memoContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        memoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        memoTitleLabel.text = "Payment Memo (Required)"
        memoTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        memoTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        memoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        memoLabel.text = paymentInstructions.memo
        memoLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        memoLabel.textColor = IndustrialDesign.Colors.bitcoin
        memoLabel.numberOfLines = 0
        memoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        copyMemoButton.setTitle("Copy", for: .normal)
        copyMemoButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        copyMemoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        copyMemoButton.backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.1)
        copyMemoButton.layer.cornerRadius = 8
        copyMemoButton.layer.borderWidth = 1
        copyMemoButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        copyMemoButton.translatesAutoresizingMaskIntoConstraints = false
        copyMemoButton.addTarget(self, action: #selector(copyMemoTapped), for: .touchUpInside)
        
        memoContainer.addSubview(memoTitleLabel)
        memoContainer.addSubview(memoLabel)
        memoContainer.addSubview(copyMemoButton)
        contentView.addSubview(memoContainer)
    }
    
    private func setupQRCodeSection() {
        qrContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        qrContainer.layer.cornerRadius = 12
        qrContainer.layer.borderWidth = 1
        qrContainer.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        qrContainer.translatesAutoresizingMaskIntoConstraints = false
        
        qrTitleLabel.text = "QR Code"
        qrTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        qrTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        qrTitleLabel.textAlignment = .center
        qrTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        qrImageView.backgroundColor = UIColor.white
        qrImageView.layer.cornerRadius = 12
        qrImageView.contentMode = .scaleAspectFit
        qrImageView.translatesAutoresizingMaskIntoConstraints = false
        
        qrContainer.addSubview(qrTitleLabel)
        qrContainer.addSubview(qrImageView)
        contentView.addSubview(qrContainer)
    }
    
    private func setupActionButtons() {
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        
        confirmPaymentButton.setTitle("I've Sent Payment", for: .normal)
        confirmPaymentButton.setTitleColor(.white, for: .normal)
        confirmPaymentButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        confirmPaymentButton.layer.cornerRadius = 8
        confirmPaymentButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        confirmPaymentButton.translatesAutoresizingMaskIntoConstraints = false
        confirmPaymentButton.addTarget(self, action: #selector(confirmPaymentTapped), for: .touchUpInside)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        cancelButton.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        buttonContainer.addSubview(confirmPaymentButton)
        buttonContainer.addSubview(cancelButton)
        contentView.addSubview(buttonContainer)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Content view
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
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Amount section
            amountContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            amountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            amountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            amountContainer.heightAnchor.constraint(equalToConstant: 100),
            
            bitcoinSymbolLabel.leadingAnchor.constraint(equalTo: amountContainer.leadingAnchor, constant: 20),
            bitcoinSymbolLabel.centerYAnchor.constraint(equalTo: amountContainer.centerYAnchor),
            
            amountLabel.leadingAnchor.constraint(equalTo: bitcoinSymbolLabel.trailingAnchor, constant: 12),
            amountLabel.centerYAnchor.constraint(equalTo: amountContainer.centerYAnchor, constant: -8),
            
            usdEquivalentLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            usdEquivalentLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            
            // Instructions section
            instructionsContainer.topAnchor.constraint(equalTo: amountContainer.bottomAnchor, constant: 16),
            instructionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            instructionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            instructionsTitleLabel.topAnchor.constraint(equalTo: instructionsContainer.topAnchor, constant: 16),
            instructionsTitleLabel.leadingAnchor.constraint(equalTo: instructionsContainer.leadingAnchor, constant: 16),
            instructionsTitleLabel.trailingAnchor.constraint(equalTo: instructionsContainer.trailingAnchor, constant: -16),
            
            instructionsTextLabel.topAnchor.constraint(equalTo: instructionsTitleLabel.bottomAnchor, constant: 8),
            instructionsTextLabel.leadingAnchor.constraint(equalTo: instructionsContainer.leadingAnchor, constant: 16),
            instructionsTextLabel.trailingAnchor.constraint(equalTo: instructionsContainer.trailingAnchor, constant: -16),
            instructionsTextLabel.bottomAnchor.constraint(equalTo: instructionsContainer.bottomAnchor, constant: -16),
            
            // Address section
            addressContainer.topAnchor.constraint(equalTo: instructionsContainer.bottomAnchor, constant: 16),
            addressContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addressContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            addressTitleLabel.topAnchor.constraint(equalTo: addressContainer.topAnchor, constant: 16),
            addressTitleLabel.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 16),
            addressTitleLabel.trailingAnchor.constraint(equalTo: copyAddressButton.leadingAnchor, constant: -8),
            
            addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 8),
            addressLabel.leadingAnchor.constraint(equalTo: addressContainer.leadingAnchor, constant: 16),
            addressLabel.trailingAnchor.constraint(equalTo: copyAddressButton.leadingAnchor, constant: -8),
            addressLabel.bottomAnchor.constraint(equalTo: addressContainer.bottomAnchor, constant: -16),
            
            copyAddressButton.centerYAnchor.constraint(equalTo: addressContainer.centerYAnchor),
            copyAddressButton.trailingAnchor.constraint(equalTo: addressContainer.trailingAnchor, constant: -16),
            copyAddressButton.widthAnchor.constraint(equalToConstant: 60),
            copyAddressButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Memo section
            memoContainer.topAnchor.constraint(equalTo: addressContainer.bottomAnchor, constant: 16),
            memoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            memoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            memoTitleLabel.topAnchor.constraint(equalTo: memoContainer.topAnchor, constant: 16),
            memoTitleLabel.leadingAnchor.constraint(equalTo: memoContainer.leadingAnchor, constant: 16),
            memoTitleLabel.trailingAnchor.constraint(equalTo: copyMemoButton.leadingAnchor, constant: -8),
            
            memoLabel.topAnchor.constraint(equalTo: memoTitleLabel.bottomAnchor, constant: 8),
            memoLabel.leadingAnchor.constraint(equalTo: memoContainer.leadingAnchor, constant: 16),
            memoLabel.trailingAnchor.constraint(equalTo: copyMemoButton.leadingAnchor, constant: -8),
            memoLabel.bottomAnchor.constraint(equalTo: memoContainer.bottomAnchor, constant: -16),
            
            copyMemoButton.centerYAnchor.constraint(equalTo: memoContainer.centerYAnchor),
            copyMemoButton.trailingAnchor.constraint(equalTo: memoContainer.trailingAnchor, constant: -16),
            copyMemoButton.widthAnchor.constraint(equalToConstant: 60),
            copyMemoButton.heightAnchor.constraint(equalToConstant: 32),
            
            // QR Code section
            qrContainer.topAnchor.constraint(equalTo: memoContainer.bottomAnchor, constant: 16),
            qrContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            qrContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            qrTitleLabel.topAnchor.constraint(equalTo: qrContainer.topAnchor, constant: 16),
            qrTitleLabel.leadingAnchor.constraint(equalTo: qrContainer.leadingAnchor, constant: 16),
            qrTitleLabel.trailingAnchor.constraint(equalTo: qrContainer.trailingAnchor, constant: -16),
            
            qrImageView.topAnchor.constraint(equalTo: qrTitleLabel.bottomAnchor, constant: 16),
            qrImageView.centerXAnchor.constraint(equalTo: qrContainer.centerXAnchor),
            qrImageView.widthAnchor.constraint(equalToConstant: 200),
            qrImageView.heightAnchor.constraint(equalToConstant: 200),
            qrImageView.bottomAnchor.constraint(equalTo: qrContainer.bottomAnchor, constant: -16),
            
            // Action buttons
            buttonContainer.topAnchor.constraint(equalTo: qrContainer.bottomAnchor, constant: 20),
            buttonContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            buttonContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            buttonContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 80),
            
            confirmPaymentButton.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 20),
            confirmPaymentButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            confirmPaymentButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.leadingAnchor.constraint(equalTo: confirmPaymentButton.trailingAnchor, constant: 12),
            cancelButton.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -20),
            cancelButton.centerYAnchor.constraint(equalTo: buttonContainer.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 80),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - QR Code Generation
    
    private func generateQRCode() {
        let paymentString = "lightning:\(paymentInstructions.lightningAddress)?amount=\(stakeAmount)&memo=\(paymentInstructions.memo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            if let qrImage = self?.generateQRImage(from: paymentString) {
                DispatchQueue.main.async {
                    self?.qrImageView.image = qrImage
                }
            }
        }
    }
    
    private func generateQRImage(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        print("💰 PaymentInstructions: Close button tapped")
        dismissModal()
    }
    
    @objc private func copyAddressTapped() {
        UIPasteboard.general.string = paymentInstructions.lightningAddress
        showCopyConfirmation(for: "Lightning address copied!")
    }
    
    @objc private func copyMemoTapped() {
        UIPasteboard.general.string = paymentInstructions.memo
        showCopyConfirmation(for: "Payment memo copied!")
    }
    
    @objc private func confirmPaymentTapped() {
        print("💰 PaymentInstructions: User confirmed payment for challenge \(challengeId)")
        
        loadingIndicator.startAnimating()
        confirmPaymentButton.isEnabled = false
        
        Task {
            do {
                guard let userId = AuthenticationService.shared.currentUserId else {
                    throw PaymentError.notAuthenticated
                }
                
                try await P2PChallengeService.shared.markPaid(challengeId: challengeId, userId: userId)
                
                await MainActor.run {
                    print("💰 PaymentInstructions: Payment confirmation successful")
                    loadingIndicator.stopAnimating()
                    dismissModal()
                    onPaymentConfirmed?()
                }
            } catch {
                print("❌ PaymentInstructions: Payment confirmation failed: \(error)")
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    confirmPaymentButton.isEnabled = true
                    showErrorAlert("Payment confirmation failed. Please try again.")
                }
            }
        }
    }
    
    @objc private func cancelButtonTapped() {
        print("💰 PaymentInstructions: Cancel button tapped")
        dismissModal()
        onCancelled?()
    }
    
    // MARK: - Helper Methods
    
    private func dismissModal() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    private func showCopyConfirmation(for message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Payment Errors

enum PaymentError: Error, LocalizedError {
    case notAuthenticated
    case paymentFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to confirm payment"
        case .paymentFailed:
            return "Payment confirmation failed"
        }
    }
}

// MARK: - Int Extension

private extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}