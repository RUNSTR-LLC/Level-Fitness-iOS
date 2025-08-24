import UIKit

class ProfileHeaderView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Profile section
    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let subscriptionBadge = UILabel()
    private let editProfileButton = UIButton(type: .custom)
    
    // Removed stats row - no longer needed
    
    // Decorative elements
    private let boltDecoration1 = UIView()
    private let boltDecoration2 = UIView()
    
    // MARK: - Properties
    private var currentUsername: String = "User"
    private var currentAvatar: UIImage?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        loadUserProfile()
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
        
        // Shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // Avatar setup - larger size (80x80)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        avatarImageView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Username label
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.textAlignment = .center
        
        // Subscription badge
        subscriptionBadge.translatesAutoresizingMaskIntoConstraints = false
        subscriptionBadge.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        subscriptionBadge.textColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        subscriptionBadge.textAlignment = .center
        subscriptionBadge.text = "FREE"
        subscriptionBadge.letterSpacing = 1
        
        // Edit profile button
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        editProfileButton.setTitle("EDIT", for: .normal)
        editProfileButton.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        editProfileButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        editProfileButton.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        editProfileButton.layer.cornerRadius = 12
        editProfileButton.layer.borderWidth = 1
        editProfileButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        
        // Stats removed - no longer needed
        
        // Bolt decorations
        setupBoltDecoration(boltDecoration1)
        setupBoltDecoration(boltDecoration2)
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(usernameLabel)
        containerView.addSubview(subscriptionBadge)
        containerView.addSubview(editProfileButton)
        containerView.addSubview(boltDecoration1)
        containerView.addSubview(boltDecoration2)
    }
    
    private func setupBoltDecoration(_ bolt: UIView) {
        bolt.translatesAutoresizingMaskIntoConstraints = false
        bolt.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        bolt.layer.cornerRadius = 3
        bolt.layer.borderWidth = 1
        bolt.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Avatar (centered, 80x80)
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Username
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            usernameLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            usernameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            
            // Subscription badge
            subscriptionBadge.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            subscriptionBadge.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Edit profile button (positioned top-right)
            editProfileButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            editProfileButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            editProfileButton.widthAnchor.constraint(equalToConstant: 50),
            editProfileButton.heightAnchor.constraint(equalToConstant: 24),
            
            // Bolt decorations
            boltDecoration1.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            boltDecoration1.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration1.heightAnchor.constraint(equalToConstant: 6),
            
            boltDecoration2.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            boltDecoration2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration2.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration2.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateProfile(username: String, avatar: UIImage?) {
        currentUsername = username
        currentAvatar = avatar
        
        usernameLabel.text = username
        
        if let avatar = avatar {
            avatarImageView.image = avatar
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    func updateSubscriptionStatus(status: SubscriptionStatus, teamCount: Int, monthlyCost: Double) {
        let badgeText: String
        let badgeColor: UIColor
        
        switch status {
        case .captain:
            badgeText = teamCount > 0 ? "CAPTAIN • \(teamCount) TEAMS" : "CAPTAIN"
            badgeColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
        case .user:
            badgeText = teamCount > 0 ? "\(teamCount) TEAM\(teamCount > 1 ? "S" : "")" : "MEMBER"
            badgeColor = IndustrialDesign.Colors.accentText
        case .none:
            badgeText = "FREE"
            badgeColor = IndustrialDesign.Colors.secondaryText
        }
        
        subscriptionBadge.text = badgeText
        subscriptionBadge.textColor = badgeColor
    }
    
    func refreshStats() {
        print("👤 Profile Header: Refreshing profile")
        loadUserProfile()
    }
    
    // MARK: - Private Methods
    
    private func loadUserProfile() {
        // Load user profile data
        if let profileData = AuthenticationService.shared.loadProfileData() {
            currentUsername = profileData.username
            currentAvatar = profileData.profileImage
            
            usernameLabel.text = currentUsername
            if let avatar = currentAvatar {
                avatarImageView.image = avatar
            }
        }
    }
    
    
    // MARK: - Actions
    
    @objc private func editProfileTapped() {
        print("👤 Profile Header: Edit profile tapped")
        
        // Find the view controller
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                let editProfileVC = EditProfileViewController()
                editProfileVC.delegate = self
                viewController.navigationController?.pushViewController(editProfileVC, animated: true)
                break
            }
            responder = responder?.next
        }
    }
}

// MARK: - EditProfileViewControllerDelegate

extension ProfileHeaderView: EditProfileViewControllerDelegate {
    func didUpdateProfile(username: String, avatar: UIImage?) {
        updateProfile(username: username, avatar: avatar)
    }
}

// MARK: - ProfileStatItemView

class ProfileStatItemView: UIView {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private var prefix: String = ""
    private var suffix: String = ""
    
    init(title: String, value: String, prefix: String = "", suffix: String = "") {
        self.prefix = prefix
        self.suffix = suffix
        super.init(frame: .zero)
        
        setupView()
        titleLabel.text = title
        updateValue(value)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.letterSpacing = 1
        
        // Value label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = "\(prefix)\(value)\(suffix.isEmpty ? "" : " \(suffix)")"
    }
    
    func setValueColor(_ color: UIColor) {
        valueLabel.textColor = color
    }
}