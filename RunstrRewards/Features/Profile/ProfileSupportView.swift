import UIKit

protocol ProfileSupportViewDelegate: AnyObject {
    func didTapPrivacyPolicy()
    func didTapTermsOfService()
    func didTapHelp()
    func didTapContactSupport()
}

class ProfileSupportView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileSupportViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private var gradientLayer: CAGradientLayer?
    private let titleLabel = UILabel()
    private let supportItemsStack = UIStackView()
    private let boltDecoration = UIView()
    
    // Support items
    private let privacyPolicyItem = ProfileSupportItemView(
        title: "Privacy Policy",
        subtitle: "How we protect your data",
        icon: "doc.text.fill"
    )
    
    private let termsOfServiceItem = ProfileSupportItemView(
        title: "Terms of Service",
        subtitle: "App terms and conditions",
        icon: "doc.fill"
    )
    
    private let helpItem = ProfileSupportItemView(
        title: "Help & Support",
        subtitle: "FAQ and troubleshooting",
        icon: "questionmark.circle.fill"
    )
    
    private let contactItem = ProfileSupportItemView(
        title: "Contact Support",
        subtitle: "Get direct help",
        icon: "envelope.fill"
    )
    
    private let versionItem = ProfileSupportItemView(
        title: "App Version",
        subtitle: "1.0.0 (Build 1)",
        icon: "info.circle.fill"
    )
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        // Container with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SUPPORT & LEGAL"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.accentText
        titleLabel.letterSpacing = 1
        
        // Support items stack
        supportItemsStack.translatesAutoresizingMaskIntoConstraints = false
        supportItemsStack.axis = .vertical
        supportItemsStack.spacing = 0
        supportItemsStack.distribution = .equalSpacing
        
        // Configure individual items
        privacyPolicyItem.translatesAutoresizingMaskIntoConstraints = false
        termsOfServiceItem.translatesAutoresizingMaskIntoConstraints = false
        helpItem.translatesAutoresizingMaskIntoConstraints = false
        contactItem.translatesAutoresizingMaskIntoConstraints = false
        versionItem.translatesAutoresizingMaskIntoConstraints = false
        
        // Make version item non-interactive
        versionItem.isUserInteractionEnabled = false
        versionItem.alpha = 0.6
        
        // Add items to stack with separators
        supportItemsStack.addArrangedSubview(helpItem)
        supportItemsStack.addArrangedSubview(createSeparator())
        supportItemsStack.addArrangedSubview(contactItem)
        supportItemsStack.addArrangedSubview(createSeparator())
        supportItemsStack.addArrangedSubview(privacyPolicyItem)
        supportItemsStack.addArrangedSubview(createSeparator())
        supportItemsStack.addArrangedSubview(termsOfServiceItem)
        supportItemsStack.addArrangedSubview(createSeparator())
        supportItemsStack.addArrangedSubview(versionItem)
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(supportItemsStack)
        containerView.addSubview(boltDecoration)
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Support items stack
            supportItemsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            supportItemsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            supportItemsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            supportItemsStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    private func setupActions() {
        helpItem.addTarget(self, action: #selector(helpItemTapped), for: .touchUpInside)
        contactItem.addTarget(self, action: #selector(contactItemTapped), for: .touchUpInside)
        privacyPolicyItem.addTarget(self, action: #selector(privacyPolicyItemTapped), for: .touchUpInside)
        termsOfServiceItem.addTarget(self, action: #selector(termsOfServiceItemTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func helpItemTapped() {
        print("👤 Support: Help item tapped")
        addHapticFeedback()
        delegate?.didTapHelp()
    }
    
    @objc private func contactItemTapped() {
        print("👤 Support: Contact item tapped")
        addHapticFeedback()
        delegate?.didTapContactSupport()
    }
    
    @objc private func privacyPolicyItemTapped() {
        print("👤 Support: Privacy policy item tapped")
        addHapticFeedback()
        delegate?.didTapPrivacyPolicy()
    }
    
    @objc private func termsOfServiceItemTapped() {
        print("👤 Support: Terms of service item tapped")
        addHapticFeedback()
        delegate?.didTapTermsOfService()
    }
    
    private func addHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - SupportItemView

class ProfileSupportItemView: UIButton {
    
    private let iconImageView = UIImageView()
    private let supportTitleLabel = UILabel()
    private let supportSubtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    init(title: String, subtitle: String, icon: String) {
        super.init(frame: .zero)
        setupView(title: title, subtitle: subtitle, icon: icon)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView(title: String, subtitle: String, icon: String) {
        backgroundColor = UIColor.clear
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = IndustrialDesign.Colors.accentText
        iconImageView.contentMode = .scaleAspectFit
        
        // Title
        supportTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        supportTitleLabel.text = title
        supportTitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        supportTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        // Subtitle
        supportSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        supportSubtitleLabel.text = subtitle
        supportSubtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        supportSubtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Chevron (only show for interactive items)
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = IndustrialDesign.Colors.secondaryText
        chevronImageView.contentMode = .scaleAspectFit
        
        // Hide chevron for version item
        if title == "App Version" {
            chevronImageView.isHidden = true
        }
        
        addSubview(iconImageView)
        addSubview(supportTitleLabel)
        addSubview(supportSubtitleLabel)
        addSubview(chevronImageView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Title
            supportTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            supportTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            supportTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -16),
            
            // Subtitle
            supportSubtitleLabel.leadingAnchor.constraint(equalTo: supportTitleLabel.leadingAnchor),
            supportSubtitleLabel.topAnchor.constraint(equalTo: supportTitleLabel.bottomAnchor, constant: 2),
            supportSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -16),
            
            // Chevron
            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.6 : 1.0
            }
        }
    }
}