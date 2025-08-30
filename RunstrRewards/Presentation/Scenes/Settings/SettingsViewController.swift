import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Settings sections
    private let accountSection = UIView()
    private let privacySection = UIView()
    private let supportSection = UIView()
    private let aboutSection = UIView()
    
    private var settingViews: [SettingItemView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("⚙️ Settings: Loading view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupSettingSections()
        setupConstraints()
        loadSettings()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        let backgroundView = IndustrialBackgroundContainer()
        view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .automatic
    }
    
    private func setupHeader() {
        contentView.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Configure title
        titleLabel.text = "Settings"
        titleLabel.font = IndustrialDesign.Typography.headerLarge
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
    }
    
    private func setupSettingSections() {
        let sections = [accountSection, privacySection, supportSection, aboutSection]
        sections.forEach { section in
            contentView.addSubview(section)
            section.translatesAutoresizingMaskIntoConstraints = false
        }
        
        setupAccountSection()
        setupPrivacySection()
        setupSupportSection()
        setupAboutSection()
    }
    
    private func setupAccountSection() {
        let sectionTitle = createSectionTitle("Account")
        accountSection.addSubview(sectionTitle)
        
        let profileSettings = createSettingItem(
            title: "Profile",
            subtitle: "Manage your profile information",
            icon: "person.circle",
            action: { [weak self] in
                self?.navigateToProfile()
            }
        )
        
        let subscriptionSettings = createSettingItem(
            title: "Subscriptions",
            subtitle: "Manage team subscriptions",
            icon: "creditcard",
            action: { [weak self] in
                self?.navigateToSubscriptions()
            }
        )
        
        accountSection.addSubview(profileSettings)
        accountSection.addSubview(subscriptionSettings)
        settingViews.append(contentsOf: [profileSettings, subscriptionSettings])
        
        // Layout
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: accountSection.topAnchor),
            sectionTitle.leadingAnchor.constraint(equalTo: accountSection.leadingAnchor, constant: 20),
            sectionTitle.trailingAnchor.constraint(equalTo: accountSection.trailingAnchor, constant: -20),
            
            profileSettings.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 12),
            profileSettings.leadingAnchor.constraint(equalTo: accountSection.leadingAnchor, constant: 20),
            profileSettings.trailingAnchor.constraint(equalTo: accountSection.trailingAnchor, constant: -20),
            
            subscriptionSettings.topAnchor.constraint(equalTo: profileSettings.bottomAnchor, constant: 8),
            subscriptionSettings.leadingAnchor.constraint(equalTo: accountSection.leadingAnchor, constant: 20),
            subscriptionSettings.trailingAnchor.constraint(equalTo: accountSection.trailingAnchor, constant: -20),
            subscriptionSettings.bottomAnchor.constraint(equalTo: accountSection.bottomAnchor)
        ])
    }
    
    private func setupPrivacySection() {
        let sectionTitle = createSectionTitle("Privacy & Security")
        privacySection.addSubview(sectionTitle)
        
        let privacySettings = createSettingItem(
            title: "Privacy Settings",
            subtitle: "Data collection and usage preferences",
            icon: "lock.shield",
            action: { [weak self] in
                self?.navigateToPrivacySettings()
            }
        )
        
        privacySection.addSubview(privacySettings)
        settingViews.append(privacySettings)
        
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: privacySection.topAnchor),
            sectionTitle.leadingAnchor.constraint(equalTo: privacySection.leadingAnchor, constant: 20),
            sectionTitle.trailingAnchor.constraint(equalTo: privacySection.trailingAnchor, constant: -20),
            
            privacySettings.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 12),
            privacySettings.leadingAnchor.constraint(equalTo: privacySection.leadingAnchor, constant: 20),
            privacySettings.trailingAnchor.constraint(equalTo: privacySection.trailingAnchor, constant: -20),
            privacySettings.bottomAnchor.constraint(equalTo: privacySection.bottomAnchor)
        ])
    }
    
    private func setupSupportSection() {
        let sectionTitle = createSectionTitle("Support")
        supportSection.addSubview(sectionTitle)
        
        let helpSettings = createSettingItem(
            title: "Help & Support",
            subtitle: "Get help and contact support",
            icon: "questionmark.circle",
            action: { [weak self] in
                self?.navigateToHelp()
            }
        )
        
        supportSection.addSubview(helpSettings)
        settingViews.append(helpSettings)
        
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: supportSection.topAnchor),
            sectionTitle.leadingAnchor.constraint(equalTo: supportSection.leadingAnchor, constant: 20),
            sectionTitle.trailingAnchor.constraint(equalTo: supportSection.trailingAnchor, constant: -20),
            
            helpSettings.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 12),
            helpSettings.leadingAnchor.constraint(equalTo: supportSection.leadingAnchor, constant: 20),
            helpSettings.trailingAnchor.constraint(equalTo: supportSection.trailingAnchor, constant: -20),
            helpSettings.bottomAnchor.constraint(equalTo: supportSection.bottomAnchor)
        ])
    }
    
    private func setupAboutSection() {
        let sectionTitle = createSectionTitle("About")
        aboutSection.addSubview(sectionTitle)
        
        let versionLabel = UILabel()
        versionLabel.text = "RunstrRewards v1.0.0"
        versionLabel.font = IndustrialDesign.Typography.bodySmall
        versionLabel.textColor = IndustrialDesign.Colors.secondaryText
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        aboutSection.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            sectionTitle.topAnchor.constraint(equalTo: aboutSection.topAnchor),
            sectionTitle.leadingAnchor.constraint(equalTo: aboutSection.leadingAnchor, constant: 20),
            sectionTitle.trailingAnchor.constraint(equalTo: aboutSection.trailingAnchor, constant: -20),
            
            versionLabel.topAnchor.constraint(equalTo: sectionTitle.bottomAnchor, constant: 12),
            versionLabel.leadingAnchor.constraint(equalTo: aboutSection.leadingAnchor, constant: 20),
            versionLabel.trailingAnchor.constraint(equalTo: aboutSection.trailingAnchor, constant: -20),
            versionLabel.bottomAnchor.constraint(equalTo: aboutSection.bottomAnchor)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            accountSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 30),
            accountSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            accountSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            privacySection.topAnchor.constraint(equalTo: accountSection.bottomAnchor, constant: 30),
            privacySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            privacySection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            supportSection.topAnchor.constraint(equalTo: privacySection.bottomAnchor, constant: 30),
            supportSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            supportSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            aboutSection.topAnchor.constraint(equalTo: supportSection.bottomAnchor, constant: 30),
            aboutSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            aboutSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            aboutSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    // MARK: - Helper Methods
    
    private func createSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = IndustrialDesign.Typography.headerMedium
        label.textColor = IndustrialDesign.Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createSettingItem(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> SettingItemView {
        let settingView = SettingItemView()
        settingView.configure(title: title, subtitle: subtitle, iconName: icon, action: action)
        settingView.translatesAutoresizingMaskIntoConstraints = false
        return settingView
    }
    
    private func loadSettings() {
        // Load any dynamic settings data
    }
    
    // MARK: - Navigation Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func navigateToProfile() {
        print("⚙️ Settings: Navigate to profile")
        // Navigate to profile settings
    }
    
    private func navigateToSubscriptions() {
        print("⚙️ Settings: Navigate to subscriptions")
        // Navigate to subscription management
    }
    
    private func navigateToPrivacySettings() {
        print("⚙️ Settings: Navigate to privacy settings")
        let privacyVC = PrivacySettingsViewController()
        navigationController?.pushViewController(privacyVC, animated: true)
    }
    
    private func navigateToHelp() {
        print("⚙️ Settings: Navigate to help")
        let helpVC = HelpSupportViewController()
        navigationController?.pushViewController(helpVC, animated: true)
    }
}

// MARK: - SettingItemView

class SettingItemView: UIView {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    private var tapAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(chevronImageView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.border.cgColor
        
        iconImageView.tintColor = IndustrialDesign.Colors.accent
        iconImageView.contentMode = .scaleAspectFit
        
        titleLabel.font = IndustrialDesign.Typography.bodyLarge
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        
        subtitleLabel.font = IndustrialDesign.Typography.bodySmall
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 2
        
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = IndustrialDesign.Colors.secondaryText
        chevronImageView.contentMode = .scaleAspectFit
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 70),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -16),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    func configure(title: String, subtitle: String, iconName: String, action: @escaping () -> Void) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconImageView.image = UIImage(systemName: iconName)
        tapAction = action
    }
    
    @objc private func handleTap() {
        tapAction?()
    }
}