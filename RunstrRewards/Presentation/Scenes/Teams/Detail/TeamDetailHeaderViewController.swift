import UIKit

protocol TeamDetailHeaderDelegate: AnyObject {
    func headerDidRequestSubscription()
    func headerDidRequestUnsubscribe()
    func headerDidRequestWallet()
}

class TeamDetailHeaderViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    weak var delegate: TeamDetailHeaderDelegate?
    private var isCaptain = false
    
    // MARK: - UI Components
    private let headerView = TeamDetailHeaderView()
    private let aboutSection = TeamDetailAboutSection()
    private let subscriptionStatusView = TeamSubscriptionStatusView()
    
    // Captain-only UI elements
    private var walletButton: UIButton?
    
    // Constraint references for dynamic layout management
    private var aboutSectionHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        configureWithData()
        setupNotificationListeners()
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        view.backgroundColor = .clear
        
        // Add header components
        [headerView, aboutSection, subscriptionStatusView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Setup delegates
        headerView.delegate = self
        subscriptionStatusView.delegate = self
    }
    
    private func setupConstraints() {
        headerView.setContentCompressionResistancePriority(.required, for: .vertical)
        headerView.setContentHuggingPriority(.required, for: .vertical)
        
        aboutSection.setContentCompressionResistancePriority(.required, for: .vertical)
        aboutSection.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        subscriptionStatusView.setContentCompressionResistancePriority(.required, for: .vertical)
        subscriptionStatusView.setContentHuggingPriority(.required, for: .vertical)
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // About Section
            aboutSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            aboutSection.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aboutSection.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Subscription Status
            subscriptionStatusView.topAnchor.constraint(equalTo: aboutSection.bottomAnchor, constant: 20),
            subscriptionStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subscriptionStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            subscriptionStatusView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        aboutSectionHeightConstraint = aboutSection.heightAnchor.constraint(equalToConstant: 0)
        aboutSectionHeightConstraint?.priority = UILayoutPriority(999)
        aboutSectionHeightConstraint?.isActive = true
    }
    
    private func configureWithData() {
        headerView.configure(teamName: teamData.name, memberCount: teamData.memberCount)
        aboutSection.configure(description: teamData.description, prizePool: String(format: "%.0f", teamData.currentPrizePool))
        
        // Check captain status
        checkCaptainStatus()
        
        // Configure subscription status
        configureSubscriptionStatus()
    }
    
    private func checkCaptainStatus() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        isCaptain = (teamData.captainId == userId)
        
        if isCaptain {
            setupCaptainControls()
        }
    }
    
    private func setupCaptainControls() {
        // Add wallet button for captains
        let walletButton = UIButton(type: .system)
        walletButton.setTitle("Team Wallet", for: .normal)
        walletButton.backgroundColor = IndustrialDesign.Colors.accent
        walletButton.setTitleColor(.white, for: .normal)
        walletButton.layer.cornerRadius = 8
        walletButton.translatesAutoresizingMaskIntoConstraints = false
        
        walletButton.addTarget(self, action: #selector(walletButtonTapped), for: .touchUpInside)
        
        view.addSubview(walletButton)
        self.walletButton = walletButton
        
        NSLayoutConstraint.activate([
            walletButton.topAnchor.constraint(equalTo: subscriptionStatusView.bottomAnchor, constant: 16),
            walletButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            walletButton.widthAnchor.constraint(equalToConstant: 200),
            walletButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func configureSubscriptionStatus() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                let isSubscribed = try await TeamDataService.shared.isUserSubscribedToTeam(
                    userId: userId,
                    teamId: teamData.id
                )
                
                await MainActor.run {
                    subscriptionStatusView.updateSubscriptionStatus(isSubscribed: isSubscribed)
                }
            } catch {
                print("TeamDetailHeader: Failed to check subscription status: \(error)")
            }
        }
    }
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionChange),
            name: .teamSubscriptionChanged,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func walletButtonTapped() {
        delegate?.headerDidRequestWallet()
    }
    
    @objc private func handleSubscriptionChange(_ notification: Notification) {
        guard let teamId = notification.userInfo?["teamId"] as? String,
              teamId == teamData.id else { return }
        
        configureSubscriptionStatus()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TeamDetailHeaderView Delegate

extension TeamDetailHeaderViewController: TeamDetailHeaderViewDelegate {
    func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    func didTapSettingsButton() {
        // Handle settings action
        let settingsAlert = UIAlertController(title: "Team Settings", message: "Choose an option", preferredStyle: .actionSheet)
        settingsAlert.addAction(UIAlertAction(title: "Edit Team", style: .default) { _ in
            // Handle edit team
        })
        settingsAlert.addAction(UIAlertAction(title: "Share Team", style: .default) { _ in
            let shareText = "Check out \(self.teamData.name) on RunstrRewards!"
            let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            self.present(activityVC, animated: true)
        })
        settingsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(settingsAlert, animated: true)
    }
    
    func didTapSubscribeButton() {
        delegate?.headerDidRequestSubscription()
    }
}

// MARK: - TeamSubscriptionStatusView Delegate

extension TeamDetailHeaderViewController: TeamSubscriptionStatusViewDelegate {
    func teamSubscriptionStatusViewDidTapAction(_ view: TeamSubscriptionStatusView) {
        delegate?.headerDidRequestSubscription()
    }
    
    func didUpdateSubscriptionStatus(_ subscribed: Bool, for teamId: String) {
        // Handle subscription status update
        print("Team \(teamId) subscription status updated: \(subscribed)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let teamSubscriptionChanged = Notification.Name("teamSubscriptionChanged")
}