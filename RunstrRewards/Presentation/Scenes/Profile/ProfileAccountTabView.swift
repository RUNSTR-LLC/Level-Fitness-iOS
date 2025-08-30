import UIKit

protocol ProfileAccountTabViewDelegate: AnyObject {
    func didTapSignOut()
    func didTapSubscriptionManagement()
    func didTapPrivacyPolicy()
    func didTapTermsOfService()
    func didTapHelp()
}

class ProfileAccountTabView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileAccountTabViewDelegate?
    private var currentSubscriptionStatus: SubscriptionStatus = .none
    private var teamCount: Int = 0
    private var monthlyCost: Double = 0
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let subscriptionView = ProfileSubscriptionView()
    private let supportView = ProfileSupportView()
    private let signOutButton = UIButton(type: .custom)
    private let spacing: CGFloat = 24
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.indicatorStyle = .white
        scrollView.backgroundColor = UIColor.clear
        
        // Content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor.clear
        
        // Configure subviews
        subscriptionView.translatesAutoresizingMaskIntoConstraints = false
        supportView.translatesAutoresizingMaskIntoConstraints = false
        
        // Sign out button
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("SIGN OUT", for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        signOutButton.titleLabel?.letterSpacing = 1
        signOutButton.setTitleColor(UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0), for: .normal)
        signOutButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        signOutButton.layer.cornerRadius = 12
        signOutButton.layer.borderWidth = 1
        signOutButton.layer.borderColor = UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 0.3).cgColor
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        
        // Add gradient to sign out button
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.12, green: 0.08, blue: 0.08, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.cornerRadius = 12
        gradient.frame = CGRect(x: 0, y: 0, width: 345, height: 48) // Will be updated in layoutSubviews
        signOutButton.layer.insertSublayer(gradient, at: 0)
        
        // Add subviews
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(subscriptionView)
        contentView.addSubview(supportView)
        contentView.addSubview(signOutButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Subscription section
            subscriptionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            subscriptionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subscriptionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subscriptionView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            // Support section
            supportView.topAnchor.constraint(equalTo: subscriptionView.bottomAnchor, constant: spacing),
            supportView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            supportView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            supportView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Sign out button
            signOutButton.topAnchor.constraint(equalTo: supportView.bottomAnchor, constant: spacing * 2),
            signOutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            signOutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 48),
            signOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing)
        ])
    }
    
    private func setupDelegates() {
        subscriptionView.delegate = self
        supportView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update sign out button gradient frame
        if let gradient = signOutButton.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = signOutButton.bounds
        }
    }
    
    // MARK: - Public Methods
    
    func updateSubscriptionInfo(status: SubscriptionStatus, teamCount: Int, monthlyCost: Double) {
        currentSubscriptionStatus = status
        self.teamCount = teamCount
        self.monthlyCost = monthlyCost
        
        subscriptionView.updateSubscriptionInfo(
            status: status,
            teamCount: teamCount,
            monthlyCost: monthlyCost
        )
    }
    
    func refreshData() {
        print("👤 Account Tab: Refreshing data")
        
        // Reload subscription status
        Task {
            let status = await SubscriptionService.shared.checkSubscriptionStatus()
            let teams = SubscriptionService.shared.getActiveTeamSubscriptionCount()
            let cost = SubscriptionService.shared.getTotalMonthlyTeamCost()
            
            await MainActor.run {
                self.updateSubscriptionInfo(status: status.subscriptionStatus, teamCount: teams, monthlyCost: cost)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func signOutTapped() {
        print("👤 Account Tab: Sign out button tapped")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.signOutButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.signOutButton.transform = .identity
            }
        }
        
        delegate?.didTapSignOut()
    }
}

// MARK: - ProfileSubscriptionViewDelegate

extension ProfileAccountTabView: ProfileSubscriptionViewDelegate {
    func didTapManageSubscription() {
        delegate?.didTapSubscriptionManagement()
    }
    
    func didTapTeamSubscription(teamId: String) {
        print("👤 Account Tab: Team subscription tapped: \(teamId)")
        // Navigate to team page if needed
    }
}

// MARK: - ProfileSupportViewDelegate

extension ProfileAccountTabView: ProfileSupportViewDelegate {
    func didTapPrivacyPolicy() {
        delegate?.didTapPrivacyPolicy()
    }
    
    func didTapTermsOfService() {
        delegate?.didTapTermsOfService()
    }
    
    func didTapHelp() {
        delegate?.didTapHelp()
    }
    
    func didTapContactSupport() {
        print("👤 Account Tab: Contact support tapped")
        // Open email client
        if let url = URL(string: "mailto:dakota.brown@runstr.club") {
            UIApplication.shared.open(url)
        }
    }
}