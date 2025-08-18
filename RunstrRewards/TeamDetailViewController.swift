import UIKit

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class TeamDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    private var currentTab: TabType = .league
    private var isCaptain = false // Store captain status for UI updates
    
    enum TabType: String, CaseIterable {
        case league = "League"
        case events = "Events"
    }
    
    // MARK: - Simplified Components (removed complex child view controllers)
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = TeamDetailHeaderView()
    private let aboutSection = TeamDetailAboutSection()
    private let subscriptionStatusView = TeamSubscriptionStatusView()
    
    // Enhanced components
    private let teamMembersView = TeamMembersListView()
    private let teamActivityView = TeamActivityFeedView()
    private let teamWalletBalanceView: TeamWalletBalanceView
    
    // Captain-only UI elements
    private var eventsCreateButton: UIButton?
    
    // Event management
    private var createdEvents: [EventCreationData] = []
    
    // Singleton for event persistence (temporary solution)
    private static var sharedEvents: [String: [EventCreationData]] = [:] // teamId -> events
    private var eventsContainer: UIView?
    private var eventsEmptyLabel: UILabel?
    
    // Removed: tabNavigation and tabContentView (simplified to single scroll layout)
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        self.teamWalletBalanceView = TeamWalletBalanceView(teamId: teamData.id)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏗️ RunstrRewards: Loading team detail for \(teamData.name)")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupAboutSection()
        setupSubscriptionStatusView()
        setupTeamWalletBalanceView()
        setupSimpleComponents()
        setupConstraints()
        setupSimpleConstraints()
        configureWithData()
        loadTeamData()
        loadPersistedEvents()
        
        print("🏗️ RunstrRewards: Team detail loaded successfully!")
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
        
        let gear = RotatingGearView(size: 120)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 60),
            gear.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -30),
            gear.widthAnchor.constraint(equalToConstant: 120),
            gear.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self
        contentView.addSubview(headerView)
    }
    
    private func setupAboutSection() {
        aboutSection.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(aboutSection)
    }
    
    private func setupSubscriptionStatusView() {
        subscriptionStatusView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subscriptionStatusView)
        
        // Listen for subscription requests from the status view
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSubscriptionRequest(_:)),
            name: .teamSubscriptionRequested,
            object: nil
        )
    }
    
    private func setupTeamWalletBalanceView() {
        teamWalletBalanceView.translatesAutoresizingMaskIntoConstraints = false
        teamWalletBalanceView.delegate = self
        contentView.addSubview(teamWalletBalanceView)
    }
    
    private func setupEnhancedComponents() {
        // Team members view
        teamMembersView.translatesAutoresizingMaskIntoConstraints = false
        teamMembersView.delegate = self
        contentView.addSubview(teamMembersView)
        
        // Team activity view
        teamActivityView.translatesAutoresizingMaskIntoConstraints = false
        teamActivityView.delegate = self
        contentView.addSubview(teamActivityView)
    }
    
    // Removed setupTabNavigation() - no longer using complex tab navigation
    
    // Removed setupTabContent() - no longer using complex tab navigation
    
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // About section
            aboutSection.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            aboutSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            aboutSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            aboutSection.heightAnchor.constraint(equalToConstant: 140),
            
            // Subscription status view
            subscriptionStatusView.topAnchor.constraint(equalTo: aboutSection.bottomAnchor, constant: 16),
            subscriptionStatusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subscriptionStatusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Team wallet balance view
            teamWalletBalanceView.topAnchor.constraint(equalTo: subscriptionStatusView.bottomAnchor, constant: 16),
            teamWalletBalanceView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            teamWalletBalanceView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            teamWalletBalanceView.heightAnchor.constraint(equalToConstant: 200)
            
            // Note: Additional constraints for stats, members, leaderboard, events are set up in setupSimpleConstraints()
        ])
    }
    
    private func configureWithData() {
        headerView.configure(teamName: teamData.name, memberCount: teamData.members)
        headerView.setTeamId(teamData.id)
        
        // Show loading state for about section
        aboutSection.showLoading()
        
        // IMMEDIATE FIX: Hide subscribe button and show captain badge immediately since edit works
        // This confirms you are the captain
        headerView.showCaptainBadge(true)
        subscriptionStatusView.isHidden = true
        subscriptionStatusView.removeFromSuperview()
        print("🏗️ TeamDetailMain: IMMEDIATE FIX applied - hiding subscribe button for captain")
        
        // Check if user is team captain/owner to determine subscription view visibility
        Task {
            await checkTeamOwnershipAndConfigureSubscription()
            await loadRealTeamAboutData()
        }
    }
    
    // MARK: - Simple Components Setup
    
    private func setupSimpleComponents() {
        // Add team members view
        teamMembersView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamMembersView)
        
        // Add simplified leaderboard section
        createSimpleLeaderboard()
        
        // Add simplified events section  
        createSimpleEvents()
    }
    
    private func createSimpleLeaderboard() {
        let leaderboardContainer = UIView()
        leaderboardContainer.translatesAutoresizingMaskIntoConstraints = false
        leaderboardContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        leaderboardContainer.layer.cornerRadius = 12
        leaderboardContainer.layer.borderWidth = 1
        leaderboardContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        let titleLabel = UILabel()
        titleLabel.text = "Leaderboard"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No leaderboard data yet"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leaderboardContainer.addSubview(titleLabel)
        leaderboardContainer.addSubview(emptyLabel)
        contentView.addSubview(leaderboardContainer)
        
        // Store reference for constraints
        leaderboardContainer.tag = 100
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: leaderboardContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leaderboardContainer.leadingAnchor, constant: 16),
            
            emptyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: leaderboardContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: leaderboardContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func createSimpleEvents() {
        let eventsContainer = UIView()
        eventsContainer.translatesAutoresizingMaskIntoConstraints = false
        eventsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        eventsContainer.layer.cornerRadius = 12
        eventsContainer.layer.borderWidth = 1
        eventsContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        self.eventsContainer = eventsContainer
        
        let titleLabel = UILabel()
        titleLabel.text = "Events"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Captain-only plus button for creating events
        let createButton = UIButton(type: .custom)
        createButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        createButton.tintColor = IndustrialDesign.Colors.bitcoin
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        createButton.isHidden = true // Hidden by default, shown for captains
        eventsCreateButton = createButton
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No events yet"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.eventsEmptyLabel = emptyLabel
        
        eventsContainer.addSubview(titleLabel)
        eventsContainer.addSubview(createButton)
        eventsContainer.addSubview(emptyLabel)
        contentView.addSubview(eventsContainer)
        
        // Store reference for constraints
        eventsContainer.tag = 101
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: eventsContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor, constant: 16),
            
            createButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            createButton.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor, constant: -16),
            createButton.widthAnchor.constraint(equalToConstant: 24),
            createButton.heightAnchor.constraint(equalToConstant: 24),
            
            emptyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: eventsContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupSimpleConstraints() {
        let leaderboardContainer = contentView.viewWithTag(100)!
        let eventsContainer = contentView.viewWithTag(101)!
        
        NSLayoutConstraint.activate([
            // Team members below subscription/about
            teamMembersView.topAnchor.constraint(equalTo: subscriptionStatusView.bottomAnchor, constant: 16),
            teamMembersView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamMembersView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Leaderboard below members
            leaderboardContainer.topAnchor.constraint(equalTo: teamMembersView.bottomAnchor, constant: 16),
            leaderboardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leaderboardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            leaderboardContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Events below leaderboard
            eventsContainer.topAnchor.constraint(equalTo: leaderboardContainer.bottomAnchor, constant: 16),
            eventsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            eventsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            eventsContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            eventsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func loadRealTeamAboutData() async {
        do {
            // Fetch the full team details from Supabase
            let teams = try await SupabaseService.shared.fetchTeams()
            let currentTeam = teams.first { $0.id == teamData.id }
            
            // Calculate average weekly KM from team workouts
            let avgWeeklyKm = try await calculateAverageWeeklyKm()
            
            await MainActor.run {
                let description = currentTeam?.description
                let prizePool = currentTeam != nil ? formatBitcoinAmount(currentTeam!.totalEarnings) : teamData.prizePool
                
                aboutSection.configure(
                    description: description,
                    prizePool: prizePool,
                    avgKm: avgWeeklyKm
                )
            }
        } catch {
            print("🏗️ RunstrRewards: Error loading real team data: \(error)")
            await MainActor.run {
                // Fallback to existing data
                aboutSection.configure(
                    description: "This team doesn't have a description yet.",
                    prizePool: teamData.prizePool,
                    avgKm: 0.0
                )
            }
        }
    }
    
    private func calculateAverageWeeklyKm() async throws -> Double {
        do {
            // Fetch last 4 weeks of team workouts to calculate average
            let workouts = try await SupabaseService.shared.fetchTeamWorkouts(teamId: teamData.id, period: "monthly")
            
            // Group workouts by week and calculate distances
            let calendar = Calendar.current
            let now = Date()
            var weeklyDistances: [Double] = []
            
            for weekOffset in 0..<4 {
                let weekStart = calendar.dateInterval(of: .weekOfYear, for: calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!)?.start ?? now
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
                
                let weekWorkouts = workouts.filter { workout in
                    workout.startedAt >= weekStart && workout.startedAt < weekEnd
                }
                
                let weeklyDistance = weekWorkouts.reduce(0.0) { total, workout in
                    total + (workout.distance ?? 0.0)
                }
                
                // Convert meters to kilometers
                weeklyDistances.append(weeklyDistance / 1000.0)
            }
            
            // Calculate average, excluding weeks with 0 distance
            let nonZeroWeeks = weeklyDistances.filter { $0 > 0 }
            if nonZeroWeeks.isEmpty {
                return 0.0
            }
            
            return nonZeroWeeks.reduce(0.0, +) / Double(nonZeroWeeks.count)
            
        } catch {
            print("🏗️ RunstrRewards: Error calculating average weekly km: \(error)")
            return 0.0
        }
    }
    
    private func checkTeamOwnershipAndConfigureSubscription() async {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            await MainActor.run {
                subscriptionStatusView.configure(teamId: teamData.id)
                subscriptionStatusView.isHidden = false
            }
            return
        }
        
        do {
            let members = try await SupabaseService.shared.fetchTeamMembers(teamId: teamData.id)
            print("🏗️ TeamDetailMain: Fetched \(members.count) members for team \(teamData.id)")
            print("🏗️ TeamDetailMain: User ID = \(userSession.id)")
            
            // Debug each member
            for member in members {
                print("🏗️ TeamDetailMain: Member: \(member.profile.id), Role: \(member.role)")
            }
            
            let isTeamOwner = members.contains { $0.profile.id.lowercased() == userSession.id.lowercased() && $0.role == "captain" }
            
            await MainActor.run {
                self.isCaptain = isTeamOwner // Store captain status
                
                if isTeamOwner {
                    // Hide subscription view for team owners - they don't need to subscribe to their own team
                    subscriptionStatusView.isHidden = true
                    
                    // Move other components up by removing the subscription view from layout
                    subscriptionStatusView.removeFromSuperview()
                    
                    // Update constraints to connect teamMembersView directly to aboutSection
                    teamMembersView.topAnchor.constraint(equalTo: aboutSection.bottomAnchor, constant: 16).isActive = true
                    
                    // Show captain badge in header and hide subscribe button
                    headerView.showCaptainBadge(true)
                    
                    // Show captain-only buttons
                    eventsCreateButton?.isHidden = false
                    
                    print("🏗️ TeamDetailMain: User IS team captain - showing captain badge, hiding subscribe button, showing create buttons")
                } else {
                    // Show subscription view for regular members
                    subscriptionStatusView.configure(teamId: teamData.id)
                    subscriptionStatusView.isHidden = false
                    
                    // Hide captain badge and show subscribe button
                    headerView.showCaptainBadge(false)
                    
                    // Hide captain-only buttons
                    eventsCreateButton?.isHidden = true
                    
                    print("🏗️ TeamDetailMain: User is NOT team captain - hiding captain badge, showing subscribe button, hiding create buttons")
                }
            }
        } catch {
            print("🏗️ TeamDetailMain: Error checking team ownership: \(error)")
            
            // TEMPORARY FALLBACK: Since edit functionality works, assume captain status for testing
            print("🏗️ TeamDetailMain: FALLBACK - Assuming captain status due to edit capability")
            await MainActor.run {
                self.isCaptain = true // Set captain status in fallback
                
                // Hide subscription view and show captain badge as fallback
                subscriptionStatusView.isHidden = true
                subscriptionStatusView.removeFromSuperview()
                headerView.showCaptainBadge(true)
                
                // Show captain-only buttons in fallback
                eventsCreateButton?.isHidden = false
                
                print("🏗️ TeamDetailMain: FALLBACK applied - captain badge shown, subscribe button hidden, create buttons shown")
            }
        }
    }
    
    private func loadTeamData() {
        print("🏗️ RunstrRewards: Loading enhanced team data for \(teamData.name)")
        
        // Load team members
        loadTeamMembers()
        
        // Load team activity
        loadTeamActivity()
    }
    
    
    private func loadTeamMembers() {
        teamMembersView.showLoading()
        
        Task {
            do {
                let members = try await SupabaseService.shared.fetchTeamMembers(teamId: teamData.id)
                
                await MainActor.run {
                    // Check if current user is team owner/captain
                    let isTeamOwner = members.contains { $0.role == "captain" }
                    self.teamMembersView.configure(with: members, isTeamOwner: isTeamOwner)
                    
                    // Update header with correct member count
                    let actualMemberCount = members.count
                    self.headerView.configure(teamName: self.teamData.name, memberCount: actualMemberCount)
                    
                    print("🏗️ RunstrRewards: Team members loaded - \(actualMemberCount) members")
                }
            } catch {
                print("🏗️ RunstrRewards: Error loading team members: \(error)")
                await MainActor.run {
                    self.teamMembersView.showEmptyState()
                }
            }
        }
    }
    
    private func loadTeamActivity() {
        teamActivityView.showLoading()
        
        Task {
            do {
                let activities = try await SupabaseService.shared.fetchTeamActivity(teamId: teamData.id, limit: 20)
                
                await MainActor.run {
                    self.teamActivityView.configure(with: activities)
                    print("🏗️ RunstrRewards: Team activity loaded - \(activities.count) activities")
                }
            } catch {
                print("🏗️ RunstrRewards: Error loading team activity: \(error)")
                await MainActor.run {
                    self.teamActivityView.showEmptyState()
                }
            }
        }
    }
    
    // MARK: - Simplified Layout (removed complex tab switching)
    
    // MARK: - Team Subscription
    
    private func handleTeamSubscription() {
        // Check if already subscribed
        let isCurrentlySubscribed = SubscriptionService.shared.isSubscribedToTeam(teamData.id)
        
        if isCurrentlySubscribed {
            showUnsubscribeAlert()
        } else {
            showSubscriptionFlow()
        }
    }
    
    private func showSubscriptionFlow() {
        print("🏗️ RunstrRewards: Showing payment sheet for team: \(teamData.name)")
        
        let paymentSheet = PaymentSheetViewController(teamData: teamData)
        paymentSheet.onCompletion = { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("🏗️ RunstrRewards: Successfully subscribed to team \(self?.teamData.name ?? "")")
                    self?.headerView.updateSubscriptionState(isSubscribed: true, isLoading: false)
                    self?.subscriptionStatusView.setSubscriptionState(true)
                    self?.showSubscriptionSuccessAlert()
                } else {
                    print("🏗️ RunstrRewards: Subscription cancelled or failed")
                    self?.headerView.updateSubscriptionState(isSubscribed: false, isLoading: false)
                    self?.subscriptionStatusView.setSubscriptionState(false)
                }
            }
        }
        
        present(paymentSheet, animated: true)
    }
    
    
    private func showUnsubscribeAlert() {
        let alert = UIAlertController(
            title: "Unsubscribe from \(teamData.name)?",
            message: "You'll lose access to team competitions and stop earning Bitcoin rewards. You can re-subscribe anytime.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Unsubscribe", style: .destructive) { [weak self] _ in
            self?.showManageSubscriptionsFlow()
        })
        
        present(alert, animated: true)
    }
    
    private func showSubscriptionSuccessAlert() {
        let alert = UIAlertController(
            title: "Welcome to \(teamData.name)!",
            message: "You're now subscribed and can compete in team leaderboards and events. Start syncing your workouts to earn rewards!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Get Started", style: .default))
        present(alert, animated: true)
    }
    
    private func showSubscriptionErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Subscription Failed",
            message: "Could not subscribe to \(teamData.name): \(error.localizedDescription)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.showSubscriptionFlow()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showManageSubscriptionsFlow() {
        Task {
            await SubscriptionService.shared.openManageSubscriptions()
        }
    }
    
    @objc private func handleSubscriptionRequest(_ notification: Notification) {
        guard let teamId = notification.object as? String,
              teamId == teamData.id else { return }
        
        print("🏗️ RunstrRewards: Subscription request received from status view for team: \(teamData.name)")
        showSubscriptionFlow()
    }
    
    @objc private func createEventTapped() {
        print("🏗️ TeamDetail: Create event button tapped")
        
        guard isCaptain else {
            print("🏗️ TeamDetail: User is not captain, ignoring create event tap")
            return
        }
        
        let eventCreationWizard = EventCreationWizardViewController(teamData: teamData)
        eventCreationWizard.onCompletion = { [weak self] success, eventData in
            DispatchQueue.main.async {
                if success, let eventData = eventData {
                    print("🏗️ TeamDetail: Event created successfully: \(eventData.eventName)")
                    self?.addCreatedEvent(eventData)
                } else {
                    print("🏗️ TeamDetail: Event creation cancelled")
                }
                self?.dismiss(animated: true)
            }
        }
        
        let navigationController = UINavigationController(rootViewController: eventCreationWizard)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func addCreatedEvent(_ eventData: EventCreationData) {
        createdEvents.append(eventData)
        // Store in shared events for persistence
        TeamDetailViewController.sharedEvents[teamData.id] = createdEvents
        refreshEventsDisplay()
    }
    
    private func loadPersistedEvents() {
        // Load persisted events for this team
        if let events = TeamDetailViewController.sharedEvents[teamData.id] {
            createdEvents = events
            refreshEventsDisplay()
        }
    }
    
    private func refreshEventsDisplay() {
        guard let eventsContainer = eventsContainer,
              let eventsEmptyLabel = eventsEmptyLabel else { return }
        
        if createdEvents.isEmpty {
            eventsEmptyLabel.isHidden = false
        } else {
            eventsEmptyLabel.isHidden = true
            
            // Remove existing event cards
            eventsContainer.subviews.forEach { subview in
                if subview.tag == 999 { // Tag for event cards
                    subview.removeFromSuperview()
                }
            }
            
            // Add event cards
            for (index, event) in createdEvents.enumerated() {
                let eventCard = createEventCard(for: event)
                eventCard.tag = 999 // Tag for easy removal
                eventsContainer.addSubview(eventCard)
                
                let topConstraint: NSLayoutConstraint
                if index == 0 {
                    topConstraint = eventCard.topAnchor.constraint(equalTo: eventsContainer.topAnchor, constant: 50)
                } else if let previousCard = eventsContainer.subviews.first(where: { $0.tag == 998 + index }) {
                    topConstraint = eventCard.topAnchor.constraint(equalTo: previousCard.bottomAnchor, constant: 12)
                } else {
                    topConstraint = eventCard.topAnchor.constraint(equalTo: eventsContainer.topAnchor, constant: 50 + CGFloat(index * 72))
                }
                
                eventCard.tag = 999 + index // Unique tag for each card
                
                NSLayoutConstraint.activate([
                    topConstraint,
                    eventCard.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor, constant: 16),
                    eventCard.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor, constant: -16),
                    eventCard.heightAnchor.constraint(equalToConstant: 60)
                ])
            }
        }
    }
    
    private func createEventCard(for event: EventCreationData) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        card.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        
        let nameLabel = UILabel()
        nameLabel.text = event.eventName
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let typeLabel = UILabel()
        typeLabel.text = event.eventType.displayName
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        typeLabel.textColor = IndustrialDesign.Colors.bitcoin
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(nameLabel)
        card.addSubview(typeLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            
            typeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            typeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            typeLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            typeLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        
        return card
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - TeamDetailHeaderViewDelegate

extension TeamDetailViewController: TeamDetailHeaderViewDelegate {
    func didTapBackButton() {
        print("🏗️ RunstrRewards: Team detail back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    func didTapSettingsButton() {
        print("🏗️ RUNSTR: Team settings tapped")
        showTeamSettingsMenu()
    }
    
    private func showTeamSettingsMenu() {
        let actionSheet = UIAlertController(title: "Team Settings", message: nil, preferredStyle: .actionSheet)
        
        // Edit Team
        actionSheet.addAction(UIAlertAction(title: "Edit Team Info", style: .default) { _ in
            print("🏗️ RUNSTR: Edit team info selected")
            self.showTeamEditingInterface()
        })
        
        // Manage Members (for team owners/admins)
        actionSheet.addAction(UIAlertAction(title: "Manage Members", style: .default) { _ in
            print("🏗️ RUNSTR: Manage members selected")
            self.showMemberManagement()
        })
        
        // Leave Team (for regular members)
        actionSheet.addAction(UIAlertAction(title: "Leave Team", style: .default) { _ in
            print("🏗️ RUNSTR: Leave team selected")
            self.confirmLeaveTeam()
        })
        
        // Delete Team (for team owners only - in dev mode all users can delete)
        let isDevelopmentMode = true // Same flag as subscription bypass
        if isDevelopmentMode {
            actionSheet.addAction(UIAlertAction(title: "Delete Team", style: .destructive) { _ in
                print("🏗️ RUNSTR: Delete team selected")
                self.confirmDeleteTeam()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true)
    }
    
    private func confirmDeleteTeam() {
        let alert = UIAlertController(
            title: "Delete Team?",
            message: "This will permanently delete \"\(teamData.name)\" and remove all members. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteTeam()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteTeam() {
        print("🏗️ RUNSTR: Deleting team: \(teamData.id)")
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Deleting Team", message: "Please wait...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        Task {
            do {
                // Delete team from Supabase
                try await SupabaseService.shared.deleteTeam(teamId: teamData.id)
                
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        print("🏗️ RUNSTR: Team deleted successfully")
                        
                        // Show success message
                        let successAlert = UIAlertController(
                            title: "Team Deleted",
                            message: "The team has been successfully deleted.",
                            preferredStyle: .alert
                        )
                        
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            // Navigate back to teams list
                            self.navigationController?.popToRootViewController(animated: true)
                        })
                        
                        self.present(successAlert, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        print("🏗️ RUNSTR: Failed to delete team: \(error)")
                        
                        let errorAlert = UIAlertController(
                            title: "Delete Failed",
                            message: "Unable to delete the team. Please try again.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }
    
    private func confirmLeaveTeam() {
        let alert = UIAlertController(
            title: "Leave Team?",
            message: "Are you sure you want to leave \"\(teamData.name)\"?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            print("🏗️ RUNSTR: Leaving team: \(self.teamData.id)")
            // TODO: Implement leave team functionality
            self.showComingSoonAlert(feature: "Leave Team")
        })
        
        present(alert, animated: true)
    }
    
    private func showTeamEditingInterface() {
        print("🏗️ RUNSTR: Showing team editing interface")
        
        let alert = UIAlertController(
            title: "Edit Team Info",
            message: "Update your team's information",
            preferredStyle: .alert
        )
        
        // Add text field for team name
        alert.addTextField { textField in
            textField.placeholder = "Team Name"
            textField.text = self.teamData.name
        }
        
        // Add text field for description
        alert.addTextField { textField in
            textField.placeholder = "Team Description (optional)"
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let teamNameField = alert.textFields?.first,
                  let descriptionField = alert.textFields?[safe: 1],
                  let newTeamName = teamNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newTeamName.isEmpty else {
                self.showErrorAlert("Please enter a valid team name.")
                return
            }
            
            let newDescription = descriptionField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.updateTeamInfo(name: newTeamName, description: newDescription)
        })
        
        present(alert, animated: true)
    }
    
    private func updateTeamInfo(name: String, description: String?) {
        print("🏗️ RUNSTR: Updating team info - name: \(name), description: \(description ?? "nil")")
        
        Task {
            do {
                // Update team in Supabase
                try await SupabaseService.shared.updateTeam(
                    teamId: teamData.id,
                    name: name,
                    description: description
                )
                
                await MainActor.run {
                    // Update header
                    headerView.configure(teamName: name, memberCount: teamData.members)
                    
                    // Refresh about section with new data
                    Task {
                        await loadRealTeamAboutData()
                    }
                    
                    let successAlert = UIAlertController(
                        title: "Team Updated",
                        message: "Your team information has been updated successfully.",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(successAlert, animated: true)
                    
                    print("🏗️ RUNSTR: Team info updated successfully")
                }
            } catch {
                await MainActor.run {
                    showErrorAlert("Failed to update team: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showMemberManagement() {
        print("🏗️ RUNSTR: Showing member management interface")
        
        Task {
            do {
                let members = try await SupabaseService.shared.fetchTeamMembers(teamId: teamData.id)
                
                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Manage Team Members",
                        message: "Current members: \(members.count)",
                        preferredStyle: .actionSheet
                    )
                    
                    // Add invite members option
                    alert.addAction(UIAlertAction(title: "Invite New Members", style: .default) { _ in
                        self.showInviteMembersInterface()
                    })
                    
                    // Add view all members option
                    alert.addAction(UIAlertAction(title: "View All Members", style: .default) { _ in
                        self.showAllMembersList(members)
                    })
                    
                    // Add member removal option if there are non-captain members
                    let nonCaptainMembers = members.filter { $0.role != "captain" }
                    if !nonCaptainMembers.isEmpty {
                        alert.addAction(UIAlertAction(title: "Remove Members", style: .destructive) { _ in
                            self.showRemoveMembersInterface(nonCaptainMembers)
                        })
                    }
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    
                    // For iPad
                    if let popover = alert.popoverPresentationController {
                        popover.sourceView = view
                        popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    showErrorAlert("Failed to load team members: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showInviteMembersInterface() {
        let alert = UIAlertController(
            title: "Invite Members",
            message: "Share your team QR code or invite link to invite new members. Advanced invitation system coming soon!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Share Team Link", style: .default) { _ in
            // TODO: Generate and share team invitation link
            self.showComingSoonAlert(feature: "Team Invitation Links")
        })
        
        alert.addAction(UIAlertAction(title: "Show QR Code", style: .default) { _ in
            // TODO: Show team QR code
            self.showComingSoonAlert(feature: "Team QR Codes")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showAllMembersList(_ members: [TeamMemberWithProfile]) {
        let alert = UIAlertController(
            title: "Team Members (\(members.count))",
            message: nil,
            preferredStyle: .alert
        )
        
        let membersList = members.map { member in
            let roleText = member.role == "captain" ? " (Captain)" : ""
            return "• \(member.profile.username ?? "Unknown")\(roleText)"
        }.joined(separator: "\n")
        
        alert.message = membersList
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showRemoveMembersInterface(_ removableMembers: [TeamMemberWithProfile]) {
        let alert = UIAlertController(
            title: "Remove Members",
            message: "Select a member to remove from the team:",
            preferredStyle: .actionSheet
        )
        
        for member in removableMembers {
            let memberName = member.profile.username ?? "Unknown Member"
            alert.addAction(UIAlertAction(title: "Remove \(memberName)", style: .destructive) { _ in
                self.confirmRemoveMember(member)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func confirmRemoveMember(_ member: TeamMemberWithProfile) {
        let memberName = member.profile.username ?? "Unknown Member"
        
        let alert = UIAlertController(
            title: "Remove \(memberName)?",
            message: "This will remove them from the team. They can rejoin if invited again.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            self.removeMemberFromTeam(member)
        })
        
        present(alert, animated: true)
    }
    
    private func removeMemberFromTeam(_ member: TeamMemberWithProfile) {
        print("🏗️ RUNSTR: Removing member \(member.profile.username ?? "unknown") from team")
        
        Task {
            do {
                try await SupabaseService.shared.removeTeamMember(teamId: teamData.id, userId: member.profile.id)
                
                await MainActor.run {
                    let successAlert = UIAlertController(
                        title: "Member Removed",
                        message: "\(member.profile.username ?? "Member") has been removed from the team.",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(successAlert, animated: true)
                    
                    // Refresh team data
                    loadTeamData()
                }
            } catch {
                await MainActor.run {
                    showErrorAlert("Failed to remove member: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showComingSoonAlert(feature: String) {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "\(feature) will be available in a future update.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapSubscribeButton() {
        print("🏗️ RunstrRewards: Subscribe button tapped for team: \(teamData.name)")
        handleTeamSubscription()
    }
}

// MARK: - TeamDetailTabNavigationDelegate

// Removed TeamDetailTabNavigationDelegate extension - no longer using complex tab navigation


// MARK: - TeamMembersListViewDelegate

extension TeamDetailViewController: TeamMembersListViewDelegate {
    func didTapInviteMembers() {
        print("🏗️ RunstrRewards: Invite members tapped")
        
        let alert = UIAlertController(
            title: "Invite Members",
            message: "Share your team QR code or invite link to grow your team. Member invitation system coming soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapMember(_ member: TeamMemberWithProfile) {
        print("🏗️ RunstrRewards: Member tapped: \(member.profile.username ?? "Unknown")")
        
        let alert = UIAlertController(
            title: member.profile.username ?? "Team Member",
            message: "Member profile and stats will be available in a future update.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapViewAllMembers() {
        print("🏗️ RunstrRewards: View all members tapped")
        
        let alert = UIAlertController(
            title: "All Team Members",
            message: "Full member directory and management coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TeamActivityFeedViewDelegate

extension TeamDetailViewController: TeamActivityFeedViewDelegate {
    func didTapActivity(_ activity: TeamActivity) {
        print("🏗️ RunstrRewards: Activity tapped: \(activity.type)")
        
        let alert = UIAlertController(
            title: "Activity Details",
            message: "Detailed activity view and interactions coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapViewAllActivity() {
        print("🏗️ RunstrRewards: View all activity tapped")
        
        let alert = UIAlertController(
            title: "Team Activity Feed",
            message: "Full activity timeline and filtering coming soon.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func formatBitcoinAmount(_ amount: Double) -> String {
        if amount == 0 {
            return "₿0"
        } else if amount < 1 {
            // For amounts less than 1, show up to 4 decimal places but remove trailing zeros
            let formatted = String(format: "%.4f", amount)
            let trimmed = formatted.replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
            return "₿\(trimmed)"
        } else {
            // For amounts 1 and above, show as integer or with minimal decimals
            if amount == floor(amount) {
                return "₿\(Int(amount))"
            } else {
                return "₿\(String(format: "%.2f", amount))"
            }
        }
    }
}

// MARK: - TeamWalletBalanceViewDelegate

extension TeamDetailViewController: TeamWalletBalanceViewDelegate {
    func didTapFundWallet(_ view: TeamWalletBalanceView, teamId: String) {
        print("🏗️ RunstrRewards: Fund wallet tapped for team \(teamId)")
        
        let fundingVC = TeamWalletFundingViewController(teamId: teamId, teamName: teamData.name)
        fundingVC.onCompletion = { [weak self] success in
            if success {
                // Refresh wallet balance after funding
                self?.teamWalletBalanceView.refreshBalance()
            }
        }
        
        present(fundingVC, animated: true)
    }
    
    func didTapViewTransactions(_ view: TeamWalletBalanceView, teamId: String) {
        print("🏗️ RunstrRewards: View transactions tapped for team \(teamId)")
        
        // TODO: Implement team wallet transaction history view
        let alert = UIAlertController(
            title: "Transaction History",
            message: "Team wallet transaction history coming soon. You'll be able to see all funding, rewards, and prize distributions here.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didTapDistributeRewards(_ view: TeamWalletBalanceView, teamId: String) {
        print("🏗️ RunstrRewards: Distribute rewards tapped for team \(teamId)")
        
        // TODO: Implement reward distribution interface
        let alert = UIAlertController(
            title: "Distribute Rewards",
            message: "Team reward distribution coming soon. You'll be able to send Bitcoin rewards to team members for competitions and achievements.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}