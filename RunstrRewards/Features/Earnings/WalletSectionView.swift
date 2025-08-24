import UIKit

protocol WalletSectionViewDelegate: AnyObject {
    func didTapSendButton()
    func didTapReceiveButton()
    func didTapWalletSection()
}

class WalletSectionView: UIView {
    
    // MARK: - Properties
    weak var delegate: WalletSectionViewDelegate?
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let walletBalanceLabel = UILabel()
    private let buttonsStackView = UIStackView()
    private let sendButton = UIButton(type: .custom)
    private let receiveButton = UIButton(type: .custom)
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupInteractions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
        
        // Update bolt decoration position
        boltDecoration.frame = CGRect(
            x: containerView.bounds.width - 18,
            y: 10,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        // Container setup with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient background
        let gradient = CAGradientLayer.industrial()
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // Wallet balance label
        walletBalanceLabel.text = "0 sats"
        walletBalanceLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        walletBalanceLabel.textAlignment = .center
        walletBalanceLabel.translatesAutoresizingMaskIntoConstraints = false
        walletBalanceLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Setup buttons stack view
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 12
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Send button
        sendButton.setTitle("Send", for: .normal)
        sendButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        sendButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        sendButton.layer.cornerRadius = 8
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Receive button
        receiveButton.setTitle("Receive", for: .normal)
        receiveButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        receiveButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        receiveButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        receiveButton.layer.cornerRadius = 8
        receiveButton.layer.borderWidth = 1
        receiveButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        receiveButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Industrial bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add components to stack view
        buttonsStackView.addArrangedSubview(sendButton)
        buttonsStackView.addArrangedSubview(receiveButton)
        
        // Add subviews
        containerView.addSubview(walletBalanceLabel)
        containerView.addSubview(buttonsStackView)
        containerView.addSubview(boltDecoration)
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Wallet balance label
            walletBalanceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            walletBalanceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            walletBalanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            walletBalanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            walletBalanceLabel.heightAnchor.constraint(equalToConstant: 40), // Fixed height to prevent overlap
            
            // Buttons stack view
            buttonsStackView.topAnchor.constraint(equalTo: walletBalanceLabel.bottomAnchor, constant: 8),
            buttonsStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonsStackView.widthAnchor.constraint(equalToConstant: 200),
            buttonsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            // Button heights
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            receiveButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupInteractions() {
        // Button actions
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        receiveButton.addTarget(self, action: #selector(receiveButtonTapped), for: .touchUpInside)
        
        // Wallet section tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(walletSectionTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Button hover effects
        addButtonHoverEffect(sendButton)
        addButtonHoverEffect(receiveButton)
    }
    
    private func addButtonHoverEffect(_ button: UIButton) {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleButtonPress(_:)))
        longPress.minimumPressDuration = 0
        longPress.cancelsTouchesInView = false
        button.addGestureRecognizer(longPress)
    }
    
    // MARK: - Actions
    
    @objc private func sendButtonTapped() {
        print("💰 WalletSectionView: Send button tapped")
        delegate?.didTapSendButton()
    }
    
    @objc private func receiveButtonTapped() {
        print("💰 WalletSectionView: Receive button tapped")
        delegate?.didTapReceiveButton()
    }
    
    @objc private func walletSectionTapped() {
        print("💰 WalletSectionView: Wallet section tapped")
        delegate?.didTapWalletSection()
    }
    
    @objc private func handleButtonPress(_ gesture: UILongPressGestureRecognizer) {
        guard let button = gesture.view as? UIButton else { return }
        
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                button.alpha = 0.8
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.1) {
                button.transform = .identity
                button.alpha = 1.0
            }
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    
    func updateBalance(_ balanceText: String) {
        walletBalanceLabel.text = balanceText
        
        // Apply gradient to balance text
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.walletBalanceLabel)
        }
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        // Remove any existing gradient layers to prevent stacking
        label.layer.sublayers?.removeAll { $0 is CAGradientLayer }
        
        // Use simple white text instead of complex gradient masking to prevent duplicate text rendering
        label.textColor = UIColor.white
    }
}