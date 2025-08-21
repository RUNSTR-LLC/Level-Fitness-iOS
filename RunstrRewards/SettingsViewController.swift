import UIKit
import StoreKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    
    // Profile section
    private let profileSection = UIView()
    private let profileCard = UIView()
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let subscriptionStatusLabel = UILabel()
    private let editProfileButton = UIButton(type: .custom)
    
    // Settings sections
    private let accountSection = UIView()
    private let notificationsSection = UIView()
    private let supportSection = UIView()
    
    private var settingSectionViews: [SettingSectionView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("⚙️ Settings: Loading settings view")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupProfileSection()
        setupSettingSections()
        setupConstraints()
        loadUserData()
        
        print("⚙️ Settings: Settings view loaded successfully")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserData()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isUserInteractionEnabled = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure scroll view touch handling for better scrolling from interactive elements
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        
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
        titleLabel.text = "Settings"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
    }
    
    private func setupProfileSection() {
        profileSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile card
        profileCard.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        profileCard.layer.cornerRadius = 12
        profileCard.layer.borderWidth = 1
        profileCard.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        profileCard.translatesAutoresizingMaskIntoConstraints = false
        
        // Profile image
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = IndustrialDesign.Colors.secondaryText
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Username
        usernameLabel.text = "Loading..."
        usernameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subscription status
        subscriptionStatusLabel.text = "Free Account"
        subscriptionStatusLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subscriptionStatusLabel.textColor = IndustrialDesign.Colors.secondaryText
        subscriptionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Edit profile button
        editProfileButton.setTitle("Edit Profile", for: .normal)
        editProfileButton.setTitleColor(IndustrialDesign.Colors.bitcoin, for: .normal)
        editProfileButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editProfileButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        editProfileButton.layer.cornerRadius = 8
        editProfileButton.layer.borderWidth = 1
        editProfileButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        
        profileCard.addSubview(profileImageView)
        profileCard.addSubview(usernameLabel)
        profileCard.addSubview(subscriptionStatusLabel)
        profileCard.addSubview(editProfileButton)
        profileSection.addSubview(profileCard)
        contentView.addSubview(profileSection)
    }
    
    private func setupSettingSections() {
        // Account section
        let accountItems = [
            SettingItem(title: "Subscription Status", subtitle: "Manage your subscriptions", icon: "creditcard.fill", action: { [weak self] in
                self?.manageSubscriptions()
            }),
            SettingItem(title: "Sign Out", subtitle: "Sign out of your account", icon: "rectangle.portrait.and.arrow.right.fill", action: { [weak self] in
                self?.signOut()
            }, isDestructive: false)
        ]
        
        accountSection.translatesAutoresizingMaskIntoConstraints = false
        let accountSectionView = SettingSectionView(title: "Account", items: accountItems)
        accountSection.addSubview(accountSectionView)
        settingSectionViews.append(accountSectionView)
        contentView.addSubview(accountSection)
        
        // Notifications section
        let notificationItems = [
            SettingItem(title: "Push Notifications", subtitle: "Competition updates, rewards", icon: "bell.fill", action: { [weak self] in
                self?.configureNotifications()
            }),
            SettingItem(title: "Team Notifications", subtitle: "Chat messages, events", icon: "person.3.fill", action: { [weak self] in
                self?.configureTeamNotifications()
            })
        ]
        
        notificationsSection.translatesAutoresizingMaskIntoConstraints = false
        let notificationSectionView = SettingSectionView(title: "Notifications", items: notificationItems)
        notificationsSection.addSubview(notificationSectionView)
        settingSectionViews.append(notificationSectionView)
        contentView.addSubview(notificationsSection)
        
        // Support section
        let supportItems = [
            SettingItem(title: "Help & Support", subtitle: "FAQ, contact support", icon: "questionmark.circle.fill", action: { [weak self] in
                self?.showHelp()
            }),
            SettingItem(title: "Privacy Policy", subtitle: "How we protect your data", icon: "doc.text.fill", action: { [weak self] in
                self?.showPrivacyPolicy()
            }),
            SettingItem(title: "Terms of Service", subtitle: "App terms and conditions", icon: "doc.fill", action: { [weak self] in
                self?.showTermsOfService()
            }),
            SettingItem(title: "App Version", subtitle: "1.0.0 (Build 1)", icon: "info.circle.fill", action: nil)
        ]
        
        supportSection.translatesAutoresizingMaskIntoConstraints = false
        let supportSectionView = SettingSectionView(title: "Support", items: supportItems)
        supportSection.addSubview(supportSectionView)
        settingSectionViews.append(supportSectionView)
        contentView.addSubview(supportSection)
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
            
            // Profile section
            profileSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            profileSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            profileSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            profileCard.topAnchor.constraint(equalTo: profileSection.topAnchor),
            profileCard.leadingAnchor.constraint(equalTo: profileSection.leadingAnchor),
            profileCard.trailingAnchor.constraint(equalTo: profileSection.trailingAnchor),
            profileCard.bottomAnchor.constraint(equalTo: profileSection.bottomAnchor),
            profileCard.heightAnchor.constraint(equalToConstant: 100),
            
            profileImageView.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 20),
            profileImageView.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            usernameLabel.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 20),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: editProfileButton.leadingAnchor, constant: -12),
            
            subscriptionStatusLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            subscriptionStatusLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            subscriptionStatusLabel.trailingAnchor.constraint(lessThanOrEqualTo: editProfileButton.leadingAnchor, constant: -12),
            
            editProfileButton.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -20),
            editProfileButton.centerYAnchor.constraint(equalTo: profileCard.centerYAnchor),
            editProfileButton.widthAnchor.constraint(equalToConstant: 80),
            editProfileButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Settings sections
            accountSection.topAnchor.constraint(equalTo: profileSection.bottomAnchor, constant: 32),
            accountSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            accountSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            notificationsSection.topAnchor.constraint(equalTo: accountSection.bottomAnchor, constant: 32),
            notificationsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            notificationsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            supportSection.topAnchor.constraint(equalTo: notificationsSection.bottomAnchor, constant: 32),
            supportSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            supportSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            supportSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
        
        // Layout setting section views
        for (index, sectionView) in settingSectionViews.enumerated() {
            let containerView: UIView
            switch index {
            case 0: containerView = accountSection
            case 1: containerView = notificationsSection
            case 2: containerView = supportSection
            default: continue
            }
            
            sectionView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                sectionView.topAnchor.constraint(equalTo: containerView.topAnchor),
                sectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                sectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                sectionView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
    }
    
    // MARK: - Data Loading
    
    private func loadUserData() {
        // Load profile data from AuthenticationService
        if let profileData = AuthenticationService.shared.loadProfileData() {
            usernameLabel.text = profileData.username
            profileImageView.image = profileData.profileImage ?? UIImage(systemName: "person.circle.fill")
        } else if let userSession = AuthenticationService.shared.loadSession() {
            // Fallback to session data
            usernameLabel.text = userSession.email ?? "User"
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        } else {
            usernameLabel.text = "Guest"
            profileImageView.image = UIImage(systemName: "person.circle.fill")
        }
        
        // Ensure profile image is circular
        profileImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Load subscription status and team information
        Task {
            let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
            let teamCount = SubscriptionService.shared.getActiveTeamSubscriptionCount()
            let totalMonthlyCost = SubscriptionService.shared.getTotalMonthlyTeamCost()
            
            await MainActor.run {
                // Update subscription status with team info
                let statusText: String
                switch subscriptionStatus {
                case .captain:
                    if teamCount > 0 {
                        statusText = "Captain • \(teamCount) team subscriptions ($\(String(format: "%.2f", totalMonthlyCost + 19.99))/mo)"
                    } else {
                        statusText = "Captain ($19.99/mo)"
                    }
                case .user:
                    statusText = "\(teamCount) team subscriptions ($\(String(format: "%.2f", totalMonthlyCost))/mo)"
                case .none:
                    statusText = "Free"
                }
                
                subscriptionStatusLabel.text = statusText
                subscriptionStatusLabel.textColor = subscriptionStatus.badgeColor
            }
        }
    }
    
    private func checkCaptainStatus() async -> String {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("⚙️ Settings: No user session for captain check")
            return ""
        }
        
        do {
            // First get the user's teams 
            let userTeams = try await SupabaseService.shared.fetchUserTeams(userId: userSession.id)
            print("⚙️ Settings: User is member of \(userTeams.count) teams")
            
            // Now check which teams user is captain of
            var captainedTeams: [String] = []
            
            for team in userTeams {
                let members = try await SupabaseService.shared.fetchTeamMembers(teamId: team.id)
                let isCaptain = members.contains { $0.profile.id == userSession.id && $0.role == "captain" }
                
                if isCaptain {
                    captainedTeams.append(team.name)
                    print("⚙️ Settings: User is captain of team: \(team.name)")
                } else {
                    print("⚙️ Settings: User is NOT captain of team: \(team.name)")
                }
            }
            
            if captainedTeams.isEmpty {
                return ""
            } else if captainedTeams.count == 1 {
                return captainedTeams.first ?? ""
            } else {
                return "\(captainedTeams.count) Teams"
            }
        } catch {
            print("⚙️ Settings: Error checking captain status: \(error)")
            return ""
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("⚙️ Settings: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func editProfileTapped() {
        print("⚙️ Settings: Edit profile tapped")
        
        let profileSetupVC = UserProfileSetupViewController()
        
        // Pre-populate with existing profile data
        if let existingProfile = AuthenticationService.shared.loadProfileData() {
            profileSetupVC.configureForEditing(with: existingProfile)
            print("⚙️ Settings: Configured profile setup for editing with existing data")
        } else {
            print("⚙️ Settings: No existing profile data found, creating new profile")
        }
        
        profileSetupVC.onCompletion = { [weak self] profile in
            // Save profile data using AuthenticationService
            AuthenticationService.shared.saveProfileData(profile)
            
            DispatchQueue.main.async {
                self?.loadUserData()
                self?.dismiss(animated: true)
            }
        }
        
        let navigationController = UINavigationController(rootViewController: profileSetupVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    // MARK: - Setting Actions
    
    private func manageSubscriptions() {
        print("⚙️ Settings: Manage subscriptions tapped")
        
        Task {
            await SubscriptionService.shared.openManageSubscriptions()
        }
    }
    
    private func showAccountInfo() {
        print("⚙️ Settings: Account information tapped")
        
        guard let userSession = AuthenticationService.shared.loadSession() else {
            showAlert(title: "Not Signed In", message: "Please sign in to view account information.")
            return
        }
        
        let message = """
        User ID: \(userSession.id)
        Email: \(userSession.email ?? "Not provided")
        
        For security reasons, we don't display sensitive account information in the app. To modify your account settings, please contact support.
        """
        
        showAlert(title: "Account Information", message: message)
    }
    
    private func signOut() {
        print("⚙️ Settings: Sign out tapped")
        
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out? You'll need to sign in again to access your teams and earnings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            Task {
                await AuthenticationService.shared.signOut()
                
                await MainActor.run {
                    // Navigate back to login by resetting the root view controller
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                       let window = appDelegate.window {
                        let loginViewController = LoginViewController()
                        let navigationController = UINavigationController(rootViewController: loginViewController)
                        window.rootViewController = navigationController
                        window.makeKeyAndVisible()
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    private func configureNotifications() {
        print("⚙️ Settings: Configure notifications tapped")
        
        // Check current notification permission status
        Task {
            let status = await NotificationService.shared.getNotificationPermissionStatus()
            
            await MainActor.run {
                switch status {
                case .notDetermined:
                    self.showNotificationPermissionFlow()
                case .denied:
                    self.showNotificationSettingsAlert()
                case .authorized, .ephemeral, .provisional:
                    self.showNotificationTypesSettings()
                @unknown default:
                    self.showNotificationSettingsAlert()
                }
            }
        }
    }
    
    private func showNotificationPermissionFlow() {
        let notificationPermissionVC = NotificationPermissionViewController()
        notificationPermissionVC.onCompletion = { [weak self] success in
            DispatchQueue.main.async {
                self?.dismiss(animated: true) {
                    if success {
                        self?.showAlert(title: "Notifications Enabled", message: "You'll now receive updates about your teams and competitions.")
                    }
                }
            }
        }
        
        let navigationController = UINavigationController(rootViewController: notificationPermissionVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func showNotificationSettingsAlert() {
        let alert = UIAlertController(
            title: "Notification Settings",
            message: "Notifications are currently disabled. You can enable them in your device settings to stay updated with your teams.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            NotificationService.shared.openNotificationSettings()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showNotificationTypesSettings() {
        let alert = UIAlertController(
            title: "Notification Types",
            message: "Choose what types of notifications you'd like to receive:",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Workout Completed", style: .default) { _ in
            self.toggleNotificationType("workout_completed")
        })
        
        alert.addAction(UIAlertAction(title: "Competition Results", style: .default) { _ in
            self.toggleNotificationType("competition_results")
        })
        
        alert.addAction(UIAlertAction(title: "Bitcoin Rewards", style: .default) { _ in
            self.toggleNotificationType("bitcoin_rewards")
        })
        
        alert.addAction(UIAlertAction(title: "Team Messages", style: .default) { _ in
            self.toggleNotificationType("team_messages")
        })
        
        alert.addAction(UIAlertAction(title: "Open Device Settings", style: .default) { _ in
            NotificationService.shared.openNotificationSettings()
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func configureTeamNotifications() {
        print("⚙️ Settings: Configure team notifications tapped")
        
        let alert = UIAlertController(
            title: "Team Notifications",
            message: "Choose which team activities you'd like to be notified about:",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "New Team Messages", style: .default) { _ in
            self.toggleNotificationType("team_messages")
        })
        
        alert.addAction(UIAlertAction(title: "Team Challenges", style: .default) { _ in
            self.toggleNotificationType("team_challenges")
        })
        
        alert.addAction(UIAlertAction(title: "Team Achievements", style: .default) { _ in
            self.toggleNotificationType("team_achievements")
        })
        
        alert.addAction(UIAlertAction(title: "Leaderboard Updates", style: .default) { _ in
            self.toggleNotificationType("leaderboard_updates")
        })
        
        alert.addAction(UIAlertAction(title: "Done", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func toggleNotificationType(_ type: String) {
        let currentSetting = UserDefaults.standard.bool(forKey: "notification_\(type)")
        let newSetting = !currentSetting
        
        UserDefaults.standard.set(newSetting, forKey: "notification_\(type)")
        
        let status = newSetting ? "enabled" : "disabled"
        let message = "Notifications for \(type.replacingOccurrences(of: "_", with: " ")) have been \(status)."
        
        showAlert(title: "Notification Updated", message: message)
        
        print("⚙️ Settings: Notification type \(type) set to \(newSetting)")
    }
    
    
    private func showHelp() {
        print("⚙️ Settings: Help & support tapped")
        let helpSupportVC = HelpSupportViewController()
        navigationController?.pushViewController(helpSupportVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        print("⚙️ Settings: Privacy policy tapped")
        
        let privacyPolicyHTML = """
        <h1>Privacy Policy</h1>
        <p><em>Last updated: January 2025</em></p>
        
        <div class="section">
            <h2>Information We Collect</h2>
            <p>RunstrRewards collects the following types of information:</p>
            <ul>
                <li><strong>Health Data:</strong> Workout information from HealthKit (with your permission)</li>
                <li><strong>Account Information:</strong> Email address and profile details</li>
                <li><strong>Usage Data:</strong> How you use the app to improve our services</li>
                <li><strong>Bitcoin Wallet Data:</strong> Wallet addresses for reward payments</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>How We Use Your Information</h2>
            <p>We use your information to:</p>
            <ul>
                <li>Calculate and distribute Bitcoin rewards for your workouts</li>
                <li>Enable team competitions and leaderboards</li>
                <li>Verify workout authenticity and prevent fraud</li>
                <li>Send notifications about rewards and team activities</li>
                <li>Improve our app and services</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Data Sharing</h2>
            <p>We do not sell your personal information. We may share data in these limited circumstances:</p>
            <ul>
                <li><strong>Team Members:</strong> Workout stats for team competitions (if you join a team)</li>
                <li><strong>Service Providers:</strong> CoinOS for Bitcoin payments, Supabase for data storage</li>
                <li><strong>Legal Requirements:</strong> When required by law or to protect our users</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Data Security</h2>
            <p>We protect your data with:</p>
            <ul>
                <li>End-to-end encryption for sensitive information</li>
                <li>Secure data transmission using HTTPS</li>
                <li>Regular security audits and updates</li>
                <li>Limited access to personal data by our team</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Your Rights</h2>
            <p>You have the right to:</p>
            <ul>
                <li>Access your personal data</li>
                <li>Correct inaccurate information</li>
                <li>Delete your account and data</li>
                <li>Opt out of non-essential communications</li>
                <li>Control health data sharing through iOS Settings</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Contact Us</h2>
            <p>Questions about this Privacy Policy? Contact us at:</p>
            <div class="highlight">
                Email: <a href="mailto:dakota.brown@runstr.club">dakota.brown@runstr.club</a><br>
                Address: RunstrRewards Privacy Team<br>
                Support available 24/7
            </div>
        </div>
        """
        
        let webVC = WebViewController(title: "Privacy Policy", htmlContent: privacyPolicyHTML)
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showBackgroundSyncStatus() {
        print("⚙️ Settings: Background sync status tapped")
        
        let lastSyncDate = UserDefaults.standard.object(forKey: "lastWorkoutSyncDate") as? Date
        let lastSyncText = lastSyncDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never"
        
        let healthKitAuthorized = HealthKitService.shared.checkAuthorizationStatus()
        let healthKitStatus = healthKitAuthorized ? "✅ Authorized" : "❌ Not Authorized"
        
        let workoutNotificationsEnabled = UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        let notificationStatus = workoutNotificationsEnabled ? "✅ Enabled" : "❌ Disabled"
        
        let backgroundAppRefreshEnabled = UIApplication.shared.backgroundRefreshStatus
        let backgroundRefreshStatus: String
        switch backgroundAppRefreshEnabled {
        case .available:
            backgroundRefreshStatus = "✅ Available"
        case .denied:
            backgroundRefreshStatus = "❌ Denied"
        case .restricted:
            backgroundRefreshStatus = "⚠️ Restricted"
        @unknown default:
            backgroundRefreshStatus = "❓ Unknown"
        }
        
        let statusMessage = """
        📊 Background Sync Health Check
        
        HealthKit Authorization: \(healthKitStatus)
        Last Workout Sync: \(lastSyncText)
        Workout Notifications: \(notificationStatus)
        Background App Refresh: \(backgroundRefreshStatus)
        
        💡 For best results:
        • Keep HealthKit authorized
        • Enable Background App Refresh in Settings
        • Allow workout completion notifications
        """
        
        let alert = UIAlertController(
            title: "Background Sync Status",
            message: statusMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Manual Sync Now", style: .default) { _ in
            self.triggerManualSync()
        })
        
        alert.addAction(UIAlertAction(title: "Open iOS Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func triggerManualSync() {
        print("⚙️ Settings: Manual sync triggered")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(
            title: "Syncing Workouts",
            message: "Checking for new workouts...",
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)
        
        // Trigger manual sync
        BackgroundTaskManager.shared.triggerWorkoutSync()
        
        // Dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            loadingAlert.dismiss(animated: true) {
                self.showAlert(title: "Sync Complete", message: "Manual workout sync has been triggered. Check your workout stats for any new activity.")
            }
        }
    }
    
    private func showTermsOfService() {
        print("⚙️ Settings: Terms of service tapped")
        
        let termsHTML = """
        <h1>Terms of Service</h1>
        <p><em>Last updated: January 2025</em></p>
        
        <div class="section">
            <h2>Acceptance of Terms</h2>
            <p>By using RunstrRewards, you agree to these Terms of Service. If you don't agree, please don't use our app.</p>
        </div>
        
        <div class="section">
            <h2>Description of Service</h2>
            <p>RunstrRewards is a fitness rewards platform that:</p>
            <ul>
                <li>Connects to your existing fitness apps and devices</li>
                <li>Calculates Bitcoin rewards based on your workout activity</li>
                <li>Enables team competitions and challenges</li>
                <li>Provides a social platform for fitness communities</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>User Responsibilities</h2>
            <p>You agree to:</p>
            <ul>
                <li>Provide accurate workout data</li>
                <li>Not attempt to cheat or manipulate the rewards system</li>
                <li>Respect other users and maintain appropriate conduct</li>
                <li>Keep your account secure and confidential</li>
                <li>Comply with all applicable laws and regulations</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Bitcoin Rewards</h2>
            <div class="highlight">
                <p><strong>Important:</strong> Bitcoin rewards have real monetary value and are subject to market fluctuations.</p>
            </div>
            <ul>
                <li>Rewards are calculated based on verified workout data</li>
                <li>Minimum payout thresholds may apply</li>
                <li>We reserve the right to investigate suspicious activity</li>
                <li>Fraudulent activity will result in account suspension</li>
                <li>Rewards may be delayed due to technical issues</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Team and Competition Rules</h2>
            <p>When participating in teams:</p>
            <ul>
                <li>Follow team-specific rules set by team captains</li>
                <li>Maintain respectful communication in team chats</li>
                <li>Report inappropriate behavior to moderators</li>
                <li>Understand that team data may be visible to other members</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Subscription and Payments</h2>
            <p>For paid features:</p>
            <ul>
                <li>Subscriptions are processed through the App Store</li>
                <li>Cancellation policies follow App Store guidelines</li>
                <li>Refunds are handled by Apple, not RunstrRewards</li>
                <li>Subscription benefits end when payment stops</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Prohibited Activities</h2>
            <p>You may not:</p>
            <ul>
                <li>Create fake workout data or use cheating devices</li>
                <li>Harass, threaten, or spam other users</li>
                <li>Attempt to hack or compromise our systems</li>
                <li>Violate any laws or regulations</li>
                <li>Create multiple accounts to circumvent rules</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Limitation of Liability</h2>
            <p>RunstrRewards is not liable for:</p>
            <ul>
                <li>Fluctuations in Bitcoin value</li>
                <li>Technical issues with third-party fitness apps</li>
                <li>Temporary service interruptions</li>
                <li>User-generated content or team interactions</li>
            </ul>
        </div>
        
        <div class="section">
            <h2>Changes to Terms</h2>
            <p>We may update these terms occasionally. Continued use of the app after changes constitutes acceptance of the new terms.</p>
        </div>
        
        <div class="section">
            <h2>Contact Information</h2>
            <p>Questions about these Terms?</p>
            <div class="highlight">
                Email: <a href="mailto:legal@level.fitness">legal@level.fitness</a><br>
                Support: <a href="mailto:dakota.brown@runstr.club">dakota.brown@runstr.club</a>
            </div>
        </div>
        """
        
        let webVC = WebViewController(title: "Terms of Service", htmlContent: termsHTML)
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Supporting Classes

struct SettingItem {
    let title: String
    let subtitle: String
    let icon: String
    let action: (() -> Void)?
    let isDestructive: Bool
    
    init(title: String, subtitle: String, icon: String, action: (() -> Void)?, isDestructive: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.isDestructive = isDestructive
    }
}

class SettingSectionView: UIView {
    
    private let titleLabel = UILabel()
    private let stackView = UIStackView()
    private let items: [SettingItem]
    
    init(title: String, items: [SettingItem]) {
        self.items = items
        super.init(frame: .zero)
        
        setupViews(title: title)
        setupConstraints()
        createItemViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews(title: String) {
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        stackView.layer.cornerRadius = 12
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = true
        
        addSubview(titleLabel)
        addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func createItemViews() {
        for (index, item) in items.enumerated() {
            let itemView = SettingItemView(item: item)
            stackView.addArrangedSubview(itemView)
            
            // Add separator (except for last item)
            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(separator)
            }
        }
    }
}

class SettingItemView: UIView {
    
    private let item: SettingItem
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView()
    
    init(item: SettingItem) {
        self.item = item
        super.init(frame: .zero)
        
        setupViews()
        setupConstraints()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        iconImageView.image = UIImage(systemName: item.icon)
        iconImageView.tintColor = (item.title == "Sign Out") ? IndustrialDesign.Colors.bitcoin : (item.isDestructive ? UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) : IndustrialDesign.Colors.secondaryText)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = item.title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = (item.title == "Sign Out") ? IndustrialDesign.Colors.bitcoin : (item.isDestructive ? UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) : IndustrialDesign.Colors.primaryText)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        if item.action != nil {
            chevronImageView.image = UIImage(systemName: "chevron.right")
            chevronImageView.tintColor = IndustrialDesign.Colors.secondaryText
            chevronImageView.contentMode = .scaleAspectFit
            chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        if item.action != nil {
            addSubview(chevronImageView)
        }
    }
    
    private func setupConstraints() {
        var constraints = [
            heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ]
        
        if item.action != nil {
            constraints.append(contentsOf: [
                chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                chevronImageView.widthAnchor.constraint(equalToConstant: 12),
                chevronImageView.heightAnchor.constraint(equalToConstant: 12),
                
                titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -16),
                subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronImageView.leadingAnchor, constant: -16)
            ])
        } else {
            constraints.append(contentsOf: [
                titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
                subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupTapGesture() {
        guard item.action != nil else { 
            return 
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
        
        // Configure tap gesture to work well with scroll view
        tapGesture.cancelsTouchesInView = false
        tapGesture.delaysTouchesEnded = false
        
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Add hover effect
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0
        longPress.cancelsTouchesInView = false
        longPress.delaysTouchesEnded = false
        longPress.require(toFail: tapGesture)  // Let tap gesture fire first
        addGestureRecognizer(longPress)
        
    }
    
    @objc private func itemTapped() {
        item.action?()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.1) {
                self.backgroundColor = .clear
            }
        default:
            break
        }
    }
}