import UIKit

enum ProfileTab {
    case workouts
    case account
    
    var title: String {
        switch self {
        case .workouts: return "WORKOUTS"
        case .account: return "ACCOUNT"
        }
    }
}

protocol ProfileViewControllerDelegate: AnyObject {
    func didRequestSignOut()
}

class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: ProfileViewControllerDelegate?
    private var currentTab: ProfileTab = .workouts
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = ProfileHeaderView()
    
    // Tab navigation
    private let tabNavigationView = ProfileTabNavigationView()
    
    // Tab content containers
    private let workoutsTabView = ProfileWorkoutsTabView()
    private let accountTabView = ProfileAccountTabView()
    
    // Back button
    private let backButton = UIButton(type: .custom)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("👤 Profile: Loading profile view controller")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupBackButton()
        setupHeader()
        setupTabNavigation()
        setupTabContent()
        setupConstraints()
        
        // Load initial data
        loadProfileData()
        
        // Start with workouts tab
        switchToTab(.workouts)
        
        print("👤 Profile: Profile view controller loaded successfully")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProfileData()
        headerView.refreshStats()
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        gridView.isUserInteractionEnabled = false
        view.addSubview(gridView)
        
        // Add rotating gears for industrial feel
        let gear1 = RotatingGearView(size: 200)
        gear1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear1)
        
        let gear2 = RotatingGearView(size: 150)
        gear2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear2)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            gear1.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            gear1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50),
            gear1.widthAnchor.constraint(equalToConstant: 200),
            gear1.heightAnchor.constraint(equalToConstant: 200),
            
            gear2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 50),
            gear2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -50),
            gear2.widthAnchor.constraint(equalToConstant: 150),
            gear2.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupBackButton() {
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.primaryText
        backButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        view.addSubview(backButton)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
    }
    
    private func setupTabNavigation() {
        tabNavigationView.translatesAutoresizingMaskIntoConstraints = false
        tabNavigationView.delegate = self
        contentView.addSubview(tabNavigationView)
    }
    
    private func setupTabContent() {
        workoutsTabView.translatesAutoresizingMaskIntoConstraints = false
        workoutsTabView.alpha = 1
        contentView.addSubview(workoutsTabView)
        
        accountTabView.translatesAutoresizingMaskIntoConstraints = false
        accountTabView.alpha = 0
        accountTabView.delegate = self
        contentView.addSubview(accountTabView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Back button (floating)
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 70),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            headerView.heightAnchor.constraint(equalToConstant: 200),
            
            // Tab navigation
            tabNavigationView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            tabNavigationView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            tabNavigationView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            tabNavigationView.heightAnchor.constraint(equalToConstant: 48),
            
            // Tab content views
            workoutsTabView.topAnchor.constraint(equalTo: tabNavigationView.bottomAnchor, constant: 24),
            workoutsTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            workoutsTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            workoutsTabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            accountTabView.topAnchor.constraint(equalTo: tabNavigationView.bottomAnchor, constant: 24),
            accountTabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            accountTabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            accountTabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadProfileData() {
        print("👤 Profile: Loading profile data")
        
        // Load user profile data
        if let profileData = AuthenticationService.shared.loadProfileData() {
            headerView.updateProfile(
                username: profileData.username,
                avatar: profileData.profileImage
            )
        } else if let userSession = AuthenticationService.shared.loadSession() {
            headerView.updateProfile(
                username: userSession.email ?? "User",
                avatar: nil
            )
        }
        
        // Load subscription status
        Task {
            let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
            let teamCount = SubscriptionService.shared.getActiveTeamSubscriptionCount()
            let totalMonthlyCost = SubscriptionService.shared.getTotalMonthlyTeamCost()
            
            await MainActor.run {
                headerView.updateSubscriptionStatus(
                    status: subscriptionStatus.subscriptionStatus,
                    teamCount: teamCount,
                    monthlyCost: totalMonthlyCost
                )
                
                // Update account tab with subscription info
                accountTabView.updateSubscriptionInfo(
                    status: subscriptionStatus.subscriptionStatus,
                    teamCount: teamCount,
                    monthlyCost: totalMonthlyCost
                )
            }
        }
    }
    
    // MARK: - Tab Management
    
    private func switchToTab(_ tab: ProfileTab) {
        guard tab != currentTab else { return }
        
        print("👤 Profile: Switching to \(tab.title) tab")
        
        let fadeOutView = currentTab == .workouts ? workoutsTabView : accountTabView
        let fadeInView = tab == .workouts ? workoutsTabView : accountTabView
        
        UIView.animate(withDuration: 0.3, animations: {
            fadeOutView.alpha = 0
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                fadeInView.alpha = 1
            }
        }
        
        currentTab = tab
        tabNavigationView.selectTab(tab)
        
        // Load tab-specific data if needed
        if tab == .workouts {
            workoutsTabView.refreshData()
        } else {
            accountTabView.refreshData()
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("👤 Profile: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ProfileTabNavigationViewDelegate

extension ProfileViewController: ProfileTabNavigationViewDelegate {
    func didSelectTab(_ tab: ProfileTab) {
        switchToTab(tab)
    }
}

// MARK: - ProfileAccountTabViewDelegate

extension ProfileViewController: ProfileAccountTabViewDelegate {
    func didTapSignOut() {
        print("👤 Profile: Sign out requested")
        
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            Task {
                await AuthenticationService.shared.signOut()
                await MainActor.run {
                    // Navigate to login screen by replacing the root view controller
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let loginVC = LoginViewController()
                        let navigationController = UINavigationController(rootViewController: loginVC)
                        
                        // Configure navigation bar appearance
                        let appearance = UINavigationBarAppearance()
                        appearance.configureWithOpaqueBackground()
                        appearance.backgroundColor = IndustrialDesign.Colors.background
                        appearance.titleTextAttributes = [
                            .foregroundColor: IndustrialDesign.Colors.primaryText,
                            .font: IndustrialDesign.Typography.navTitleFont
                        ]
                        appearance.shadowColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
                        
                        navigationController.navigationBar.standardAppearance = appearance
                        navigationController.navigationBar.scrollEdgeAppearance = appearance
                        navigationController.navigationBar.compactAppearance = appearance
                        navigationController.navigationBar.tintColor = IndustrialDesign.Colors.primaryText
                        
                        // Animate the transition
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                            window.rootViewController = navigationController
                        }, completion: nil)
                    }
                }
            }
        })
        
        present(alert, animated: true)
    }
    
    func didTapSubscriptionManagement() {
        print("👤 Profile: Subscription management tapped")
        // Subscription management coming soon
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "Subscription management will be available in a future update.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapPrivacyPolicy() {
        print("👤 Profile: Privacy policy tapped")
        // Reuse existing privacy policy display logic
        showPrivacyPolicy()
    }
    
    func didTapTermsOfService() {
        print("👤 Profile: Terms of service tapped")
        // Reuse existing terms display logic
        showTermsOfService()
    }
    
    func didTapHelp() {
        print("👤 Profile: Help tapped")
        let helpVC = HelpSupportViewController()
        navigationController?.pushViewController(helpVC, animated: true)
    }
}

// MARK: - Support Methods (from SettingsViewController)

extension ProfileViewController {
    private func showPrivacyPolicy() {
        let privacyPolicyHTML = """
        <h1>Privacy Policy</h1>
        <p><em>Last updated: January 2025</em></p>
        
        <div class="section">
            <h2>Information We Collect</h2>
            <p>RunstrRewards collects fitness and health data to provide rewards and competition features.</p>
        </div>
        
        <div class="section">
            <h2>Contact Us</h2>
            <p>Questions about this Privacy Policy? Contact us at:</p>
            <div class="highlight">
                Email: <a href="mailto:dakota.brown@runstr.club">dakota.brown@runstr.club</a><br>
                Support available 24/7
            </div>
        </div>
        """
        
        let webVC = WebViewController(title: "Privacy Policy", htmlContent: privacyPolicyHTML)
        navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showTermsOfService() {
        let termsHTML = """
        <h1>Terms of Service</h1>
        <p><em>Last updated: January 2025</em></p>
        
        <div class="section">
            <h2>Acceptance of Terms</h2>
            <p>By using RunstrRewards, you agree to these Terms of Service.</p>
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
}