import UIKit

class NavigationCard: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    private let tapAction: () -> Void
    private let badgeView = UIView()
    private let badgeLabel = UILabel()
    
    // MARK: - Initialization
    init(title: String, subtitle: String, iconName: String, action: @escaping () -> Void) {
        self.tapAction = action
        super.init(frame: .zero)
        
        setupCard()
        setupContent(title: title, subtitle: subtitle, iconName: iconName)
        setupConstraints()
        setupInteractions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        
        // Update bolt decoration position
        boltDecoration.frame = CGRect(
            x: bounds.width - 18,
            y: 10,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupCard() {
        // Container setup with industrial gradient
        containerView.translatesAutoresizingMaskIntoConstraints = false
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
        
        addSubview(containerView)
    }
    
    private func setupContent(title: String, subtitle: String, iconName: String) {
        // Icon setup
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = IndustrialDesign.Colors.accentText
        iconImageView.contentMode = .scaleAspectFit
        
        // Title setup
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = IndustrialDesign.Typography.navTitleFont
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        // Subtitle setup
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = subtitle.uppercased()
        subtitleLabel.font = IndustrialDesign.Typography.navSubtitleFont
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 1
        
        // Industrial bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add inner shadow to bolt
        let innerShadow = CALayer()
        innerShadow.frame = CGRect(x: 0, y: 0, width: IndustrialDesign.Sizing.boltSize, height: IndustrialDesign.Sizing.boltSize)
        innerShadow.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        innerShadow.backgroundColor = UIColor.black.cgColor
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 1)
        innerShadow.shadowOpacity = 0.8
        innerShadow.shadowRadius = 1
        boltDecoration.layer.addSublayer(innerShadow)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills the entire view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon positioning (smaller and positioned horizontally)
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.regular),
            iconImageView.widthAnchor.constraint(equalToConstant: 32), // Reduced from 48
            iconImageView.heightAnchor.constraint(equalToConstant: 32), // Reduced from 48
            
            // Title positioning (horizontal layout next to icon)
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: IndustrialDesign.Spacing.regular),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: IndustrialDesign.Spacing.medium),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            
            // Subtitle positioning (below title)
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: IndustrialDesign.Spacing.tiny),
            subtitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: IndustrialDesign.Spacing.medium),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.regular)
        ])
    }
    
    private func setupInteractions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    // MARK: - Interaction Methods
    
    @objc private func cardTapped() {
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animation
        animateTap {
            self.tapAction()
        }
    }
    
    private func animateTap(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = .identity
            }) { _ in
                completion()
            }
        }
    }
    
    // MARK: - Touch Handling for Hover Effects
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        animateToHoverState()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateToNormalState()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateToNormalState()
    }
    
    private func animateToHoverState() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Lift effect
            self.containerView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -2)
            
            // Border color change
            self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorderHover.cgColor
            
            // Enhanced shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
            self.containerView.layer.shadowRadius = 16
            self.containerView.layer.shadowOpacity = 0.4
            
            // Icon color change
            self.iconImageView.tintColor = IndustrialDesign.Colors.primaryText
        }
    }
    
    private func animateToNormalState() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Reset transform
            self.containerView.transform = .identity
            
            // Reset border color
            self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
            
            // Reset shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.containerView.layer.shadowRadius = 8
            self.containerView.layer.shadowOpacity = 0.3
            
            // Reset icon color
            self.iconImageView.tintColor = IndustrialDesign.Colors.accentText
        }
    }
    
    // MARK: - Public Methods
    
    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func updateSubtitle(_ subtitle: String) {
        subtitleLabel.text = subtitle
    }
    
    func showBadge(_ show: Bool) {
        if show {
            setupBadge()
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }
    
    func updateBadgeText(_ text: String) {
        setupBadge()
        badgeLabel.text = text
    }
    
    private func setupBadge() {
        if badgeView.superview == nil {
            badgeView.translatesAutoresizingMaskIntoConstraints = false
            badgeView.backgroundColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
            badgeView.layer.cornerRadius = 6
            containerView.addSubview(badgeView)
            
            badgeLabel.text = "Active"
            badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            badgeLabel.textColor = UIColor.black // Black text on orange background for contrast
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            badgeView.addSubview(badgeLabel)
            
            NSLayoutConstraint.activate([
                badgeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                badgeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
                badgeView.heightAnchor.constraint(equalToConstant: 12),
                
                badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
                badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
                badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor, constant: 4),
                badgeLabel.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: -4)
            ])
        }
    }
}