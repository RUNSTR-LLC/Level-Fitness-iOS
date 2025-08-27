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
    
    // Captain-only UI elements
    private var eventsCreateButton: UIButton?
    private var announcementButton: UIButton?
    
    // Event management
    private var createdEvents: [EventCreationData] = []
    
    // Constraint references for dynamic layout management
    private var teamMembersTopConstraint: NSLayoutConstraint?
    private var teamMembersToSubscriptionConstraint: NSLayoutConstraint?
    private var teamMembersToAboutConstraint: NSLayoutConstraint?
    private var aboutSectionHeightConstraint: NSLayoutConstraint?
    
    // Singleton for event persistence (temporary solution)
    private static var sharedEvents: [String: [EventCreationData]] = [:] // teamId -> events
    private var eventsContainer: UIView?
    private var eventsEmptyLabel: UILabel?
    private var eventsTitleLabel: UILabel?
    
    // Challenge management
    private var challengesContainer: UIView?
    private var challengesEmptyLabel: UILabel?
    // Placeholder for challenges - will use proper Event model when integrated
    private var activeChallenges: [String] = [] // Using String IDs as placeholder
    
    // Removed: tabNavigation and tabContentView (simplified to single scroll layout)
    
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
        print("🏗️ RunstrRewards: Loading team detail for \(teamData.name)")
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupAboutSection()
        setupSubscriptionStatusView()
        setupSimpleComponents()
        setupConstraints()
        setupAboutSectionHeightConstraint()
        setupSimpleConstraints()
        configureWithData()
        loadTeamData()
        loadPersistedEvents()
        setupNotificationListeners()
        
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
        aboutSection.delegate = self
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
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
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
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            // About section
            aboutSection.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            aboutSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            aboutSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Subscription status view
            subscriptionStatusView.topAnchor.constraint(equalTo: aboutSection.bottomAnchor, constant: 16),
            subscriptionStatusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subscriptionStatusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
            
            // Note: Additional constraints for stats, members, leaderboard, events are set up in setupSimpleConstraints()
        ])
    }
    
    private func configureWithData() {
        headerView.configure(teamName: teamData.name, memberCount: teamData.members)
        headerView.setTeamId(teamData.id)
        
        // Show loading state for about section
        aboutSection.showLoading()
        
        // Let team ownership check determine captain status properly
        print("🏗️ TeamDetailMain: Waiting for team ownership check to determine UI state")
        
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
        
        // Add challenges section
        createChallengesSection()
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
        self.eventsTitleLabel = titleLabel
        
        // Captain-only plus button for creating events
        let createButton = UIButton(type: .custom)
        createButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        createButton.tintColor = IndustrialDesign.Colors.bitcoin
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createEventTapped), for: .touchUpInside)
        createButton.isHidden = true // Hidden by default, shown for captains
        eventsCreateButton = createButton
        
        // Captain-only announcement button
        let announcementBtn = UIButton(type: .custom)
        announcementBtn.setImage(UIImage(systemName: "megaphone.fill"), for: .normal)
        announcementBtn.tintColor = IndustrialDesign.Colors.bitcoin
        announcementBtn.translatesAutoresizingMaskIntoConstraints = false
        announcementBtn.addTarget(self, action: #selector(announcementTapped), for: .touchUpInside)
        announcementBtn.isHidden = true // Hidden by default, shown for captains
        announcementButton = announcementBtn
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No events yet"
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.eventsEmptyLabel = emptyLabel
        
        eventsContainer.addSubview(titleLabel)
        eventsContainer.addSubview(createButton)
        eventsContainer.addSubview(announcementBtn)
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
            
            announcementBtn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            announcementBtn.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -12),
            announcementBtn.widthAnchor.constraint(equalToConstant: 24),
            announcementBtn.heightAnchor.constraint(equalToConstant: 24),
            
            emptyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: eventsContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: eventsContainer.bottomAnchor, constant: -16)
        ])
    }
    
    private func createChallengesSection() {
        let challengesContainer = UIView()
        challengesContainer.translatesAutoresizingMaskIntoConstraints = false
        challengesContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        challengesContainer.layer.cornerRadius = 12
        challengesContainer.layer.borderWidth = 1
        challengesContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        self.challengesContainer = challengesContainer
        
        let titleLabel = UILabel()
        titleLabel.text = "Challenges"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create challenge button (for team members, not captains)
        let createChallengeButton = UIButton(type: .system)
        createChallengeButton.setImage(UIImage(systemName: "plus"), for: .normal)
        createChallengeButton.tintColor = IndustrialDesign.Colors.bitcoin
        createChallengeButton.translatesAutoresizingMaskIntoConstraints = false
        createChallengeButton.addTarget(self, action: #selector(createChallengeButtonTapped), for: .touchUpInside)
        
        let emptyLabel = UILabel()
        emptyLabel.text = "No active challenges"
        emptyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.challengesEmptyLabel = emptyLabel
        
        challengesContainer.addSubview(titleLabel)
        challengesContainer.addSubview(createChallengeButton)
        challengesContainer.addSubview(emptyLabel)
        contentView.addSubview(challengesContainer)
        
        // Store reference for constraints
        challengesContainer.tag = 102 // Different tag from events (101)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: challengesContainer.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: challengesContainer.leadingAnchor, constant: 16),
            
            createChallengeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            createChallengeButton.trailingAnchor.constraint(equalTo: challengesContainer.trailingAnchor, constant: -16),
            createChallengeButton.widthAnchor.constraint(equalToConstant: 24),
            createChallengeButton.heightAnchor.constraint(equalToConstant: 24),
            
            emptyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: challengesContainer.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: challengesContainer.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func createChallengeButtonTapped() {
        print("🏆 Challenge: Create challenge button tapped")
        
        let challengeModal = ChallengeCreationModal(teamData: teamData)
        challengeModal.onCompletion = { [weak self] success in
            if success {
                self?.showAlert(title: "Success!", message: "Challenge created successfully!")
                // TODO: Refresh challenges list or update UI as needed
            }
        }
        
        present(challengeModal, animated: true)
    }
    
    private func setupAboutSectionHeightConstraint() {
        // Create height constraint for aboutSection (dynamic based on captain status)
        aboutSectionHeightConstraint = aboutSection.heightAnchor.constraint(equalToConstant: 140)
        aboutSectionHeightConstraint?.isActive = true
    }
    
    private func updateAboutSectionHeight(isCaptain: Bool) {
        // Need more height when captain to accommodate the manage wallet button positioned below statsRow
        aboutSectionHeightConstraint?.constant = isCaptain ? 200 : 140
        view.layoutIfNeeded()
    }
    
    private func setupSimpleConstraints() {
        let leaderboardContainer = contentView.viewWithTag(100)!
        let eventsContainer = contentView.viewWithTag(101)!
        let challengesContainer = contentView.viewWithTag(102)!
        
        // Create both possible constraints but don't activate yet
        teamMembersToSubscriptionConstraint = teamMembersView.topAnchor.constraint(equalTo: subscriptionStatusView.bottomAnchor, constant: 16)
        teamMembersToAboutConstraint = teamMembersView.topAnchor.constraint(equalTo: aboutSection.bottomAnchor, constant: 16)
        
        // Activate the subscription constraint by default (for non-captains)
        teamMembersTopConstraint = teamMembersToSubscriptionConstraint
        
        NSLayoutConstraint.activate([
            // Team members positioning - will be managed dynamically
            teamMembersTopConstraint!,
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
            
            // Challenges below events
            challengesContainer.topAnchor.constraint(equalTo: eventsContainer.bottomAnchor, constant: 16),
            challengesContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            challengesContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            challengesContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            challengesContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
    
    private func loadRealTeamAboutData() async {
        do {
            // Fetch the full team details from Supabase
            let teams = try await TeamDataService.shared.fetchTeams()
            let currentTeam = teams.first { $0.id == teamData.id }
            
            // Calculate average weekly KM from team workouts
            // Check team wallet status
            let walletConfigured = await checkTeamWalletStatus()
            
            await MainActor.run {
                let description = currentTeam?.description
                let prizePool = currentTeam != nil ? formatBitcoinAmount(currentTeam!.totalEarnings) : teamData.prizePool
                
                aboutSection.configure(
                    description: description,
                    prizePool: prizePool,
                    walletConfigured: walletConfigured,
                    isCaptain: isCaptain
                )
            }
        } catch {
            print("🏗️ RunstrRewards: Error loading real team data: \(error)")
            await MainActor.run {
                // Fallback to existing data
                aboutSection.configure(
                    description: "This team doesn't have a description yet.",
                    prizePool: teamData.prizePool,
                    walletConfigured: false,
                    isCaptain: false
                )
            }
        }
    }
    
    private func checkTeamWalletStatus() async -> Bool {
        do {
            // Try to get team wallet balance - if successful, wallet is configured
            _ = try await TransactionDataService.shared.getTeamWalletBalance(teamId: teamData.id)
            print("🏗️ RunstrRewards: Team wallet is configured for team \(teamData.id)")
            return true
        } catch {
            print("🏗️ RunstrRewards: Team wallet not configured for team \(teamData.id): \(error)")
            return false
        }
    }
    
    private func calculateAverageWeeklyKm() async throws -> Double {
        do {
            // Fetch last 4 weeks of team workouts to calculate average
            let workouts = try await WorkoutDataService.shared.fetchTeamWorkouts(teamId: teamData.id, period: "monthly")
            
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
            let members = try await TeamDataService.shared.fetchTeamMembers(teamId: teamData.id)
            print("🏗️ TeamDetailMain: Fetched \(members.count) members for team \(teamData.id)")
            print("🏗️ TeamDetailMain: User ID = \(userSession.id)")
            
            // Debug each member
            for member in members {
                print("🏗️ TeamDetailMain: Member: \(member.profile.id), Role: \(member.role)")
            }
            
            let isTeamOwner = members.contains { $0.profile.id.lowercased() == userSession.id.lowercased() && $0.role == "captain" }
            
            await MainActor.run {
                self.isCaptain = isTeamOwner // Store captain status
                print("🏗️ TeamDetailViewController: Captain status determined: \(isTeamOwner) for user \(userSession.id) on team \(self.teamData.id)")
                self.updateAboutSectionHeight(isCaptain: isTeamOwner) // Update height for captain UI
                
                if isTeamOwner {
                    // Switch to captain layout constraints
                    teamMembersTopConstraint?.isActive = false
                    teamMembersTopConstraint = teamMembersToAboutConstraint
                    teamMembersTopConstraint?.isActive = true
                    
                    // Hide subscription view for team owners - they don't need to subscribe to their own team
                    subscriptionStatusView.isHidden = true
                    subscriptionStatusView.removeFromSuperview()
                    
                    // Show captain badge in header and hide subscribe button
                    headerView.showCaptainBadge(true)
                    
                    // Show captain-only buttons
                    eventsCreateButton?.isHidden = false
                    announcementButton?.isHidden = false
                    
                    print("🏗️ TeamDetailMain: User IS team captain - showing captain badge, hiding subscribe button, showing create buttons")
                } else {
                    // Ensure we're using the subscription constraint for regular members
                    teamMembersTopConstraint?.isActive = false
                    teamMembersTopConstraint = teamMembersToSubscriptionConstraint
                    teamMembersTopConstraint?.isActive = true
                    
                    // Show subscription view for regular members
                    subscriptionStatusView.configure(teamId: teamData.id)
                    subscriptionStatusView.isHidden = false
                    
                    // Hide captain badge and show subscribe button
                    headerView.showCaptainBadge(false)
                    
                    // Hide captain-only buttons
                    eventsCreateButton?.isHidden = true
                    announcementButton?.isHidden = true
                    
                    print("🏗️ TeamDetailMain: User is NOT team captain - hiding captain badge, showing subscribe button, hiding create buttons")
                }
            }
        } catch {
            print("🏗️ TeamDetailMain: Error checking team ownership: \(error)")
            
            // DO NOT assume captain status - user must be properly authenticated
            print("🏗️ TeamDetailMain: Could not verify team ownership - defaulting to member view")
            await MainActor.run {
                self.isCaptain = false // Default to non-captain for safety
                print("🏗️ TeamDetailViewController: Defaulting to non-captain status (could not verify ownership)")
                self.updateAboutSectionHeight(isCaptain: false) // Update height for member UI
                
                // Show subscription UI for non-captains
                subscriptionStatusView.configure(teamId: teamData.id)
                subscriptionStatusView.isHidden = false
                headerView.showCaptainBadge(false)
                
                // Hide captain-only buttons
                eventsCreateButton?.isHidden = true
                announcementButton?.isHidden = true
                
                print("🏗️ TeamDetailMain: Non-captain view applied - subscribe button shown, captain features hidden")
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
                let members = try await TeamDataService.shared.fetchTeamMembers(teamId: teamData.id)
                
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
                let activities = try await TeamDataService.shared.fetchTeamActivity(teamId: teamData.id, limit: 20)
                
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
    
    @objc private func announcementTapped() {
        print("🏗️ TeamDetail: Announcement button tapped")
        
        guard isCaptain else {
            print("🏗️ TeamDetail: User is not captain, ignoring announcement tap")
            return
        }
        
        let announcementVC = CaptainAnnouncementViewController(teamData: teamData)
        announcementVC.modalPresentationStyle = .pageSheet
        
        if #available(iOS 15.0, *) {
            if let sheet = announcementVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        
        present(announcementVC, animated: true)
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
              let eventsEmptyLabel = eventsEmptyLabel,
              let eventsTitleLabel = eventsTitleLabel else { return }
        
        // Remove existing height constraints
        eventsContainer.constraints.filter { $0.firstAttribute == .height }.forEach {
            eventsContainer.removeConstraint($0)
        }
        
        if createdEvents.isEmpty {
            eventsEmptyLabel.isHidden = false
            // Set minimum height for empty state
            eventsContainer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        } else {
            eventsEmptyLabel.isHidden = true
            
            // Remove existing event cards
            eventsContainer.subviews.forEach { subview in
                if subview.tag >= 999 { // Tag for event cards
                    subview.removeFromSuperview()
                }
            }
            
            // Add event cards with proper constraints
            var previousView: UIView?
            let cardHeight: CGFloat = 60
            let cardSpacing: CGFloat = 12
            let titleBottomSpacing: CGFloat = 16 // Space between title and first card
            let bottomPadding: CGFloat = 16
            
            for (index, event) in createdEvents.enumerated() {
                let eventCard = createEventCard(for: event)
                eventCard.tag = 999 + index
                eventsContainer.addSubview(eventCard)
                
                let topConstraint: NSLayoutConstraint
                if index == 0 {
                    // First card positioned below title label
                    topConstraint = eventCard.topAnchor.constraint(equalTo: eventsTitleLabel.bottomAnchor, constant: titleBottomSpacing)
                } else if let prevView = previousView {
                    // Subsequent cards positioned below previous card
                    topConstraint = eventCard.topAnchor.constraint(equalTo: prevView.bottomAnchor, constant: cardSpacing)
                } else {
                    // Fallback to title label
                    topConstraint = eventCard.topAnchor.constraint(equalTo: eventsTitleLabel.bottomAnchor, constant: titleBottomSpacing)
                }
                
                NSLayoutConstraint.activate([
                    topConstraint,
                    eventCard.leadingAnchor.constraint(equalTo: eventsContainer.leadingAnchor, constant: 16),
                    eventCard.trailingAnchor.constraint(equalTo: eventsContainer.trailingAnchor, constant: -16),
                    eventCard.heightAnchor.constraint(equalToConstant: cardHeight)
                ])
                
                previousView = eventCard
            }
            
            // Calculate and set container height to fit all content
            // Title takes about 50pt including button space and margins
            let titleSectionHeight: CGFloat = 50
            let totalHeight = titleSectionHeight + titleBottomSpacing + CGFloat(createdEvents.count) * cardHeight + CGFloat(max(0, createdEvents.count - 1)) * cardSpacing + bottomPadding
            eventsContainer.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
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

// MARK: - TeamDetailAboutSectionDelegate

extension TeamDetailViewController: TeamDetailAboutSectionDelegate {
    func didTapManageWallet() {
        print("🏗️ TeamDetailViewController: Manage wallet button tapped")
        print("🏗️ TeamDetailViewController: Current captain status: \(isCaptain)")
        print("🏗️ TeamDetailViewController: Team ID: \(teamData.id)")
        
        guard let userSession = AuthenticationService.shared.loadSession() else {
            print("🏗️ TeamDetailViewController: ❌ No user session found for wallet access")
            return
        }
        
        print("🏗️ TeamDetailViewController: User session ID: \(userSession.id)")
        
        guard isCaptain else {
            print("🏗️ TeamDetailViewController: ❌ User is not captain according to local flag, denying wallet access")
            return
        }
        
        print("🏗️ TeamDetailViewController: ✅ Captain access confirmed, opening wallet")
        let walletViewController = TeamWalletViewController(teamData: teamData)
        navigationController?.pushViewController(walletViewController, animated: true)
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
        
        // Verify user is actually the captain before attempting deletion
        guard isCaptain else {
            print("🏗️ RUNSTR: Delete blocked - user is not team captain")
            showErrorAlert("Only the team captain can delete this team.")
            return
        }
        
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Deleting Team", message: "Please wait...", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        Task {
            do {
                // Ensure we have a valid Supabase session before attempting deletion
                guard let userSession = AuthenticationService.shared.loadSession() else {
                    throw NSError(domain: "TeamDeletion", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please sign in again to delete teams."])
                }
                
                // Verify user ID matches captain ID
                guard userSession.id == teamData.captainId else {
                    throw NSError(domain: "TeamDeletion", code: 1004, userInfo: [NSLocalizedDescriptionKey: "You are not authorized to delete this team. Only the team captain can delete it."])
                }
                
                // Restore Supabase session if we have valid tokens
                if userSession.accessToken != "temp_token" && userSession.refreshToken != "temp_refresh_token" {
                    do {
                        try await AuthDataService.shared.restoreSession(accessToken: userSession.accessToken, refreshToken: userSession.refreshToken)
                        print("🏗️ RUNSTR: Successfully restored Supabase session for team deletion")
                    } catch {
                        print("🏗️ RUNSTR: Failed to restore Supabase session: \(error)")
                        throw NSError(domain: "TeamDeletion", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please sign in again to delete teams."])
                    }
                }
                
                // Verify we have a valid Supabase session
                let currentSupabaseUser = try await AuthDataService.shared.getCurrentUser()
                if currentSupabaseUser == nil {
                    throw NSError(domain: "TeamDeletion", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please sign in again to delete teams."])
                }
                
                // Delete team from Supabase
                try await TeamDataService.shared.deleteTeam(teamId: teamData.id)
                
                // CRITICAL: Verify the team was actually deleted
                let verificationResult = try? await TeamDataService.shared.getTeam(teamData.id)
                if verificationResult != nil {
                    // Team still exists - deletion failed
                    throw NSError(domain: "TeamDeletion", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Team deletion failed. The team still exists in the database. You may not have permission to delete this team."])
                }
                
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
                            // Post notification to refresh teams list
                            NotificationCenter.default.post(name: .teamDeleted, object: nil)
                            
                            // Navigate back to teams list
                            self.navigationController?.popViewController(animated: true)
                        })
                        
                        self.present(successAlert, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    loadingAlert.dismiss(animated: true) {
                        print("🏗️ RUNSTR: Failed to delete team: \(error)")
                        
                        let errorMessage: String
                        let errorTitle: String
                        
                        // Check if this is an authentication error
                        if let nsError = error as NSError? {
                            switch nsError.code {
                            case 1001, 1002, 1003:
                                errorTitle = "Authentication Required"
                                errorMessage = nsError.localizedDescription
                            case 1004:
                                errorTitle = "Not Authorized"
                                errorMessage = nsError.localizedDescription
                            case 1005:
                                errorTitle = "Deletion Failed"
                                errorMessage = nsError.localizedDescription
                            default:
                                errorTitle = "Delete Failed"
                                errorMessage = nsError.localizedDescription
                            }
                        } else if error.localizedDescription.contains("refresh_token_already_used") {
                            errorTitle = "Session Expired"
                            errorMessage = "Your login session has expired. Please sign out and sign back in to delete teams."
                        } else {
                            errorTitle = "Delete Failed"
                            errorMessage = "Unable to delete the team. Please try again."
                        }
                        
                        let errorAlert = UIAlertController(
                            title: errorTitle,
                            message: errorMessage,
                            preferredStyle: .alert
                        )
                        
                        // Add sign out option for authentication errors
                        if errorTitle == "Authentication Required" || errorTitle == "Session Expired" {
                            errorAlert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
                                Task {
                                    await AuthenticationService.shared.signOut()
                                    await MainActor.run {
                                        // Navigate to login screen
                                        if let window = UIApplication.shared.connectedScenes
                                            .compactMap({ $0 as? UIWindowScene })
                                            .first?.windows.first {
                                            let loginVC = LoginViewController()
                                            window.rootViewController = loginVC
                                        }
                                    }
                                }
                            })
                        }
                        
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
            self.performLeaveTeam()
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
                let members = try await TeamDataService.shared.fetchTeamMembers(teamId: teamData.id)
                
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
            self.shareTeamInvitationLink()
        })
        
        alert.addAction(UIAlertAction(title: "Show QR Code", style: .default) { _ in
            self.showTeamQRCode()
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
    
    // MARK: - Team Invitation & QR Code Features
    
    private func shareTeamInvitationLink() {
        print("🏗️ RunstrRewards: Generating team invitation link for team: \(teamData.name)")
        
        // Generate team invitation URL
        let teamInviteURL = "https://runstrrewards.app/join/\(teamData.id)"
        let shareText = "Join my RunstrRewards team '\(teamData.name)'! Compete in fitness challenges and earn Bitcoin rewards. \(teamInviteURL)"
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true) {
            print("🏗️ RunstrRewards: Team invitation link shared successfully")
        }
    }
    
    private func showTeamQRCode() {
        print("🏗️ RunstrRewards: Generating QR code for team: \(teamData.name)")
        
        let teamInviteURL = "https://runstrrewards.app/join/\(teamData.id)"
        
        // Generate QR code
        guard let qrImage = generateQRCode(from: teamInviteURL) else {
            showErrorAlert("Failed to generate QR code")
            return
        }
        
        // Create QR code display view controller
        let qrViewController = QRCodeDisplayViewController(
            qrImage: qrImage,
            teamName: teamData.name,
            teamId: teamData.id
        )
        
        present(qrViewController, animated: true) {
            print("🏗️ RunstrRewards: QR code displayed successfully")
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        guard let output = filter.outputImage?.transformed(by: transform) else { return nil }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Leave Team Functionality
    
    private func performLeaveTeam() {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            showErrorAlert("Please sign in to leave the team")
            return
        }
        
        Task {
            do {
                print("🏗️ RunstrRewards: Starting leave team process for user \(userSession.id) from team \(teamData.id)")
                
                // Cancel any active team subscription first
                let isSubscribed = SubscriptionService.shared.isSubscribedToTeam(teamData.id)
                if isSubscribed {
                    print("🏗️ RunstrRewards: Cancelling team subscription before leaving")
                    try await SubscriptionService.shared.unsubscribeFromTeam(teamData.id)
                }
                
                // Remove user from team members
                try await SupabaseService.shared.removeUserFromTeam(userId: userSession.id, teamId: teamData.id)
                
                await MainActor.run {
                    print("🏗️ RunstrRewards: Successfully left team \(self.teamData.name)")
                    
                    // Show success message
                    let successAlert = UIAlertController(
                        title: "Left Team",
                        message: "You have successfully left \(self.teamData.name). You will no longer receive team notifications or be able to participate in team competitions.",
                        preferredStyle: .alert
                    )
                    
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        // Navigate back to teams list
                        self.navigationController?.popViewController(animated: true)
                    })
                    
                    self.present(successAlert, animated: true)
                }
                
            } catch {
                await MainActor.run {
                    print("🏗️ RunstrRewards: Failed to leave team: \(error)")
                    self.showErrorAlert("Failed to leave team: \(error.localizedDescription)")
                }
            }
        }
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
    
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(announcementSentSuccessfully),
            name: .announcementSent,
            object: nil
        )
    }
    
    @objc private func announcementSentSuccessfully(_ notification: Notification) {
        guard let title = notification.userInfo?["title"] as? String else { return }
        
        let alert = UIAlertController(
            title: "Announcement Sent! 📢",
            message: "'\(title)' has been sent to all team members.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Great!", style: .default))
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
        // Convert Bitcoin amount to sats (1 BTC = 100,000,000 sats)
        // Note: Return just the number, StatItem will add "sats" suffix
        let satsAmount = Int(amount * 100_000_000)
        
        if satsAmount == 0 {
            return "0"
        } else if satsAmount < 1000 {
            return "\(satsAmount)"
        } else if satsAmount < 1_000_000 {
            let kSats = Double(satsAmount) / 1000.0
            return String(format: "%.1fk", kSats)
        } else {
            let mSats = Double(satsAmount) / 1_000_000.0
            return String(format: "%.1fM", mSats)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

