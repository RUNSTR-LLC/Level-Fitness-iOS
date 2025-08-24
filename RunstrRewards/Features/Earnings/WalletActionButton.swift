import UIKit

enum WalletActionIcon {
    case receive
    case send
    
    var systemImageName: String {
        switch self {
        case .receive:
            return "plus"
        case .send:
            return "paperplane"
        }
    }
}

class WalletActionButton: UIButton {
    
    // MARK: - Properties
    private let title: String
    private let iconType: WalletActionIcon
    private let iconImageView = UIImageView()
    private let customTitleLabel = UILabel()
    
    // MARK: - Initialization
    
    init(title: String, icon: WalletActionIcon) {
        self.title = title
        self.iconType = icon
        super.init(frame: .zero)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupButton() {
        // Remove default button styling
        setTitle("", for: .normal)
        
        // Setup background and border
        backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
        layer.cornerRadius = 8
        
        // Add gradient background
        DispatchQueue.main.async {
            self.setupGradientBackground()
        }
        
        // Setup icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: iconType.systemImageName)
        iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        iconImageView.contentMode = .scaleAspectFit
        
        // Setup title label
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        customTitleLabel.text = title
        customTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        customTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        customTitleLabel.textAlignment = .center
        customTitleLabel.letterSpacing = 0.5
        
        addSubview(iconImageView)
        addSubview(customTitleLabel)
        
        setupConstraints()
        setupHoverEffects()
    }
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 8
        
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            // Title
            customTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            customTitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            customTitleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func setupHoverEffects() {
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpInside)
        addTarget(self, action: #selector(buttonReleased), for: .touchUpOutside)
        addTarget(self, action: #selector(buttonReleased), for: .touchCancel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient layer frame
        if let gradientLayer = layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
    }
    
    // MARK: - Actions
    
    @objc private func buttonPressed() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.alpha = 0.8
        }
    }
    
    @objc private func buttonReleased() {
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .allowUserInteraction
        ) {
            self.transform = CGAffineTransform.identity
            self.alpha = 1.0
        }
    }
    
    // MARK: - Hover Effects (for simulator/mac)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animateHover(isHovering: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateHover(isHovering: false)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateHover(isHovering: false)
    }
    
    private func animateHover(isHovering: Bool) {
        UIView.animate(withDuration: 0.3) {
            if isHovering {
                self.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
                self.transform = CGAffineTransform(translationX: 0, y: -2)
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 6)
                self.layer.shadowOpacity = 0.5
                self.layer.shadowRadius = 20
            } else {
                self.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
                self.transform = .identity
                self.layer.shadowOpacity = 0
            }
        }
    }
}