import UIKit

class TeamDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var currentTab: TabType = .league
    private var isCaptain = false
    
    enum TabType: String, CaseIterable {
        case league = "League"
        case events = "Events"
    }
    
    // MARK: - Child Controllers
    private let headerController: TeamDetailHeaderViewController
    private let eventsController: TeamDetailEventsController
    private let membersController: TeamDetailMembersController
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let tabNavigation = UISegmentedControl(items: TabType.allCases.map { $0.rawValue })
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        self.headerController = TeamDetailHeaderViewController(teamData: teamData)
        self.eventsController = TeamDetailEventsController(teamData: teamData, isCaptain: false)
        self.membersController = TeamDetailMembersController(teamData: teamData)
        
        super.init(nibName: nil, bundle: nil)
        
        setupDelegates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏗️ TeamDetailViewController: Loading team detail for \(teamData.name)")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupChildControllers()
        setupViews()
        setupConstraints()
        checkCaptainStatus()
        
        print("🏗️ TeamDetailViewController: Team detail loaded successfully!")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupChildControllers() {
        addChild(headerController)
        addChild(eventsController)
        addChild(membersController)
        
        headerController.didMove(toParent: self)
        eventsController.didMove(toParent: self)
        membersController.didMove(toParent: self)
        
        // Initially hide events and members controllers
        eventsController.view.isHidden = true
        membersController.view.isHidden = true
    }
    
    private func setupViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add child controller views
        [headerController.view, tabNavigation, eventsController.view, membersController.view].forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0!)
        }
        
        // Configure tab navigation
        tabNavigation.selectedSegmentIndex = 0
        tabNavigation.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        tabNavigation.backgroundColor = IndustrialDesign.Colors.surface
        tabNavigation.selectedSegmentTintColor = IndustrialDesign.Colors.accent
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header controller
            headerController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Tab navigation
            tabNavigation.topAnchor.constraint(equalTo: headerController.view.bottomAnchor, constant: 20),
            tabNavigation.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            tabNavigation.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            tabNavigation.heightAnchor.constraint(equalToConstant: 40),
            
            // Events controller
            eventsController.view.topAnchor.constraint(equalTo: tabNavigation.bottomAnchor, constant: 20),
            eventsController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            eventsController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            eventsController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Members controller
            membersController.view.topAnchor.constraint(equalTo: tabNavigation.bottomAnchor, constant: 20),
            membersController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            membersController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            membersController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setupDelegates() {
        headerController.delegate = self
        eventsController.delegate = self
        membersController.delegate = self
    }
    
    private func checkCaptainStatus() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                let teamDetails = try await TeamDataService.shared.fetchTeamDetails(teamId: teamData.id)
                await MainActor.run {
                    self.isCaptain = (teamDetails.captainId == userId)
                    self.eventsController.updateCaptainStatus(self.isCaptain)
                }
            } catch {
                print("TeamDetailViewController: Failed to check captain status: \(error)")
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func tabChanged() {
        let selectedTab = TabType.allCases[tabNavigation.selectedSegmentIndex]
        currentTab = selectedTab
        
        switch selectedTab {
        case .league:
            eventsController.view.isHidden = true
            membersController.view.isHidden = false
        case .events:
            eventsController.view.isHidden = false
            membersController.view.isHidden = true
        }
    }
    
    // MARK: - Navigation
    
    private func presentEventCreation() {
        let eventCreationVC = EventCreationWizardViewController(teamData: teamData)
        let navVC = UINavigationController(rootViewController: eventCreationVC)
        present(navVC, animated: true)
    }
    
    private func presentTeamWallet() {
        let walletVC = TeamWalletViewController(teamData: teamData)
        navigationController?.pushViewController(walletVC, animated: true)
    }
    
    private func handleSubscription() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                try await TeamDataService.shared.subscribeToTeam(userId: userId, teamId: teamData.id)
                
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .teamSubscriptionChanged,
                        object: nil,
                        userInfo: ["teamId": teamData.id, "subscribed": true]
                    )
                }
                
                print("✅ TeamDetailViewController: Successfully subscribed to team")
            } catch {
                print("❌ TeamDetailViewController: Failed to subscribe: \(error)")
                // Show error alert
                await MainActor.run {
                    showErrorAlert(title: "Subscription Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleUnsubscription() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                try await TeamDataService.shared.unsubscribeFromTeam(userId: userId, teamId: teamData.id)
                
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .teamSubscriptionChanged,
                        object: nil,
                        userInfo: ["teamId": teamData.id, "subscribed": false]
                    )
                }
                
                print("✅ TeamDetailViewController: Successfully unsubscribed from team")
            } catch {
                print("❌ TeamDetailViewController: Failed to unsubscribe: \(error)")
                await MainActor.run {
                    showErrorAlert(title: "Unsubscription Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TeamDetailHeaderDelegate

extension TeamDetailViewController: TeamDetailHeaderDelegate {
    func headerDidRequestSubscription() {
        handleSubscription()
    }
    
    func headerDidRequestUnsubscribe() {
        handleUnsubscription()
    }
    
    func headerDidRequestWallet() {
        presentTeamWallet()
    }
}

// MARK: - TeamDetailEventsDelegate

extension TeamDetailViewController: TeamDetailEventsDelegate {
    func eventsDidRequestCreateEvent() {
        presentEventCreation()
    }
    
    func eventsDidRequestEventDetails(_ eventId: String) {
        // Navigate to event details
        print("TeamDetailViewController: Navigate to event \(eventId)")
    }
}

// MARK: - TeamDetailMembersDelegate

extension TeamDetailViewController: TeamDetailMembersDelegate {
    func membersDidRequestMemberProfile(_ memberId: String) {
        // Navigate to member profile
        print("TeamDetailViewController: Navigate to member \(memberId)")
    }
    
    func membersDidRequestLeaderboard() {
        // Navigate to leaderboard
        let leaderboardVC = UIViewController()
        leaderboardVC.title = "Leaderboard"
        leaderboardVC.view.backgroundColor = IndustrialDesign.Colors.background
        
        let leaderboardView = LiveLeaderboardView()
        leaderboardView.translatesAutoresizingMaskIntoConstraints = false
        leaderboardVC.view.addSubview(leaderboardView)
        
        NSLayoutConstraint.activate([
            leaderboardView.topAnchor.constraint(equalTo: leaderboardVC.view.safeAreaLayoutGuide.topAnchor),
            leaderboardView.leadingAnchor.constraint(equalTo: leaderboardVC.view.leadingAnchor),
            leaderboardView.trailingAnchor.constraint(equalTo: leaderboardVC.view.trailingAnchor),
            leaderboardView.bottomAnchor.constraint(equalTo: leaderboardVC.view.bottomAnchor)
        ])
        
        navigationController?.pushViewController(leaderboardVC, animated: true)
    }
}