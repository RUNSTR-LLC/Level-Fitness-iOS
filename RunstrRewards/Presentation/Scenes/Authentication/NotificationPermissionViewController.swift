import UIKit
import UserNotifications

class NotificationPermissionViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Main content
    private let iconView = UIImageView()
    private let mainTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    // Benefits section
    private let benefitsContainer = UIView()
    private let benefitsTitle = UILabel()
    private var benefitViews: [NotificationBenefitView] = []
    
    // Action buttons
    private let enableButton = UIButton(type: .custom)
    private let skipButton = UIButton(type: .custom)
    
    // Loading indicator
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Completion handler
    var onCompletion: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 NotificationPermission: Loading notification permission view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupMainContent()
        setupBenefitsSection()
        setupActionButtons()
        setupConstraints()
        checkCurrentPermissionStatus()
        
        print("📱 NotificationPermission: View loaded successfully")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add rotating gear
        let gear = RotatingGearView(size: 100)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 50),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 30),
            gear.widthAnchor.constraint(equalToConstant: 100),
            gear.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Back button
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupMainContent() {
        // Icon
        iconView.image = UIImage(systemName: "bell.fill")
        iconView.tintColor = UIColor.systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Main title
        mainTitleLabel.text = "Stay Updated with Your Teams"
        mainTitleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        mainTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        mainTitleLabel.textAlignment = .center
        mainTitleLabel.numberOfLines = 0
        mainTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = "Get notified about team competitions, Bitcoin rewards, and important updates. You can customize these settings anytime."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(iconView)
        contentView.addSubview(mainTitleLabel)
        contentView.addSubview(descriptionLabel)
    }
    
    private func setupBenefitsSection() {
        benefitsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        benefitsTitle.text = "What You'll Be Notified About"
        benefitsTitle.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        benefitsTitle.textColor = IndustrialDesign.Colors.primaryText
        benefitsTitle.textAlignment = .center
        benefitsTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Add benefitsTitle to container FIRST
        benefitsContainer.addSubview(benefitsTitle)
        
        // Create benefit items
        let benefits = [
            ("figure.run", "Workout Completion", "Get instant confirmation when workouts are detected and synced"),
            ("trophy.fill", "Competition Results", "Get notified when competitions end and rankings are updated"),
            ("bitcoinsign.circle.fill", "Bitcoin Rewards", "Instant alerts when you earn Bitcoin for your workouts"),
            ("message.fill", "Team Chat", "New messages and announcements from your teams"),
            ("calendar.badge.plus", "New Events", "Be the first to know about upcoming team events and challenges"),
            ("person.3.fill", "Team Updates", "Important updates from team captains and new member activity")
        ]
        
        var lastBenefitView: UIView = benefitsTitle
        
        for benefit in benefits {
            let benefitView = NotificationBenefitView(
                iconName: benefit.0,
                title: benefit.1,
                description: benefit.2
            )
            benefitView.translatesAutoresizingMaskIntoConstraints = false
            benefitViews.append(benefitView)
            benefitsContainer.addSubview(benefitView)
            
            NSLayoutConstraint.activate([
                benefitView.topAnchor.constraint(equalTo: lastBenefitView.bottomAnchor, constant: 20),
                benefitView.leadingAnchor.constraint(equalTo: benefitsContainer.leadingAnchor),
                benefitView.trailingAnchor.constraint(equalTo: benefitsContainer.trailingAnchor)
            ])
            
            lastBenefitView = benefitView
        }
        
        contentView.addSubview(benefitsContainer)
        
        // Set bottom constraint for container
        if let lastView = benefitViews.last {
            benefitsContainer.bottomAnchor.constraint(equalTo: lastView.bottomAnchor).isActive = true
        }
    }
    
    private func setupActionButtons() {
        // Enable notifications button
        enableButton.setTitle("Enable Notifications", for: .normal)
        enableButton.setTitleColor(.white, for: .normal)
        enableButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        enableButton.backgroundColor = UIColor.systemBlue
        enableButton.layer.cornerRadius = 12
        enableButton.layer.borderWidth = 1
        enableButton.layer.borderColor = UIColor.systemBlue.cgColor
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        enableButton.addTarget(self, action: #selector(enableNotificationsTapped), for: .touchUpInside)
        
        // Skip button
        skipButton.setTitle("Skip for Now", for: .normal)
        skipButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        skipButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        skipButton.layer.cornerRadius = 12
        skipButton.layer.borderWidth = 1
        skipButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(enableButton)
        contentView.addSubview(skipButton)
        contentView.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Main content
            iconView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 40),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 80),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            
            mainTitleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            mainTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            mainTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            descriptionLabel.topAnchor.constraint(equalTo: mainTitleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            // Benefits section
            benefitsContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            benefitsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            benefitsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            
            benefitsTitle.topAnchor.constraint(equalTo: benefitsContainer.topAnchor),
            benefitsTitle.leadingAnchor.constraint(equalTo: benefitsContainer.leadingAnchor),
            benefitsTitle.trailingAnchor.constraint(equalTo: benefitsContainer.trailingAnchor),
            
            // Action buttons
            enableButton.topAnchor.constraint(equalTo: benefitsContainer.bottomAnchor, constant: 40),
            enableButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            enableButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            enableButton.heightAnchor.constraint(equalToConstant: 56),
            
            skipButton.topAnchor.constraint(equalTo: enableButton.bottomAnchor, constant: 16),
            skipButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            skipButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            skipButton.heightAnchor.constraint(equalToConstant: 48),
            skipButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: enableButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: enableButton.centerYAnchor)
        ])
    }
    
    // MARK: - Permission Management
    
    private func checkCurrentPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.updateUIForPermissionStatus(settings.authorizationStatus)
            }
        }
    }
    
    private func updateUIForPermissionStatus(_ status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .ephemeral, .provisional:
            enableButton.setTitle("Notifications Enabled ✓", for: .normal)
            enableButton.backgroundColor = UIColor.systemGreen
            enableButton.layer.borderColor = UIColor.systemGreen.cgColor
            enableButton.isEnabled = false
            
            skipButton.setTitle("Continue", for: .normal)
            
        case .denied:
            enableButton.setTitle("Enable in Settings", for: .normal)
            enableButton.backgroundColor = UIColor.systemOrange
            enableButton.layer.borderColor = UIColor.systemOrange.cgColor
            
        case .notDetermined:
            enableButton.setTitle("Enable Notifications", for: .normal)
            enableButton.backgroundColor = UIColor.systemBlue
            enableButton.layer.borderColor = UIColor.systemBlue.cgColor
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("📱 NotificationPermission: Back button tapped")
        onCompletion?(false)
    }
    
    @objc private func enableNotificationsTapped() {
        print("📱 NotificationPermission: Enable notifications button tapped")
        
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    self?.requestNotificationPermission()
                case .denied:
                    self?.openNotificationSettings()
                case .authorized, .ephemeral, .provisional:
                    self?.handlePermissionGranted()
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func skipButtonTapped() {
        print("📱 NotificationPermission: Skip button tapped")
        onCompletion?(false)
    }
    
    private func requestNotificationPermission() {
        setLoadingState(true)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.setLoadingState(false)
                
                if let error = error {
                    print("📱 NotificationPermission: Error requesting permission: \(error)")
                    self?.showErrorAlert(error)
                    return
                }
                
                if granted {
                    print("📱 NotificationPermission: Permission granted")
                    self?.handlePermissionGranted()
                } else {
                    print("📱 NotificationPermission: Permission denied")
                    self?.updateUIForPermissionStatus(.denied)
                }
            }
        }
    }
    
    private func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    private func handlePermissionGranted() {
        updateUIForPermissionStatus(.authorized)
        
        // Brief delay to show success state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.onCompletion?(true)
        }
    }
    
    private func setLoadingState(_ loading: Bool) {
        enableButton.isEnabled = !loading
        skipButton.isEnabled = !loading
        
        if loading {
            loadingIndicator.startAnimating()
            enableButton.setTitle("", for: .normal)
        } else {
            loadingIndicator.stopAnimating()
            checkCurrentPermissionStatus()
        }
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Notification Error",
            message: "Could not enable notifications: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - NotificationBenefitView

class NotificationBenefitView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    init(iconName: String, title: String, description: String) {
        super.init(frame: .zero)
        setupViews(iconName: iconName, title: title, description: description)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(iconName: String, title: String, description: String) {
        // Icon
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = UIColor.systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}