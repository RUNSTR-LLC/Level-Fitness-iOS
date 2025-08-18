import UIKit

class TeamsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header components
    private let headerView = UIView()
    private let backButton = UIButton(type: .custom)
    private let titleLabel = UILabel()
    private let createTeamButton = UIButton(type: .custom)
    
    // Search section
    private let searchSection = UIView()
    private let searchBar = UIView()
    private let searchInput = UITextField()
    private let searchIcon = UIImageView()
    private let activityFilter = UIScrollView()
    private var filterChips: [UIButton] = []
    
    // Teams list
    private let teamsList = UIView()
    private var teamCards: [TeamCard] = []
    
    // Activity filter options
    private let activities = ["All", "Running", "Cycling", "Walking", "Gym", "Swimming", "Yoga"]
    private var selectedActivity = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏗️ RunstrRewards: Loading Teams page...")
        
        // Keep navigation bar hidden since we have custom header
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupSearchSection()
        setupTeamsList()
        setupConstraints()
        loadRealTeams()
        print("🏗️ RunstrRewards: Teams page loaded successfully!")
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
        
        // Add rotating gear background element
        let gear = RotatingGearView(size: 150)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 25),
            gear.widthAnchor.constraint(equalToConstant: 150),
            gear.heightAnchor.constraint(equalToConstant: 150)
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
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 59, width: view.frame.width, height: 1)
        headerView.layer.addSublayer(borderLayer)
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Teams"
        titleLabel.font = IndustrialDesign.Typography.navTitleFont
        titleLabel.textAlignment = .center
        
        // Create team button
        createTeamButton.translatesAutoresizingMaskIntoConstraints = false
        createTeamButton.setImage(UIImage(systemName: "plus"), for: .normal)
        createTeamButton.tintColor = IndustrialDesign.Colors.secondaryText
        createTeamButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        createTeamButton.layer.cornerRadius = 8
        createTeamButton.layer.borderWidth = 1
        createTeamButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        createTeamButton.addTarget(self, action: #selector(createTeamTapped), for: .touchUpInside)
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(createTeamButton)
        contentView.addSubview(headerView)
        
        // Add gradient to title
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.titleLabel)
        }
    }
    
    private func setupSearchSection() {
        searchSection.translatesAutoresizingMaskIntoConstraints = false
        searchSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 79, width: view.frame.width, height: 1)
        searchSection.layer.addSublayer(borderLayer)
        
        setupSearchBar()
        setupActivityFilter()
        
        contentView.addSubview(searchSection)
    }
    
    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        searchBar.layer.cornerRadius = 10
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Search icon
        searchIcon.translatesAutoresizingMaskIntoConstraints = false
        searchIcon.image = UIImage(systemName: "magnifyingglass")
        searchIcon.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Search input
        searchInput.translatesAutoresizingMaskIntoConstraints = false
        searchInput.placeholder = "Search teams..."
        searchInput.font = UIFont.systemFont(ofSize: 16)
        searchInput.textColor = IndustrialDesign.Colors.primaryText
        searchInput.backgroundColor = UIColor.clear
        searchInput.borderStyle = .none
        
        // Placeholder color
        if let placeholder = searchInput.placeholder {
            searchInput.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: IndustrialDesign.Colors.secondaryText]
            )
        }
        
        searchBar.addSubview(searchIcon)
        searchBar.addSubview(searchInput)
        searchSection.addSubview(searchBar)
    }
    
    private func setupActivityFilter() {
        activityFilter.translatesAutoresizingMaskIntoConstraints = false
        activityFilter.showsHorizontalScrollIndicator = false
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        
        for (index, activity) in activities.enumerated() {
            let chip = createFilterChip(title: activity, index: index)
            stackView.addArrangedSubview(chip)
            filterChips.append(chip)
        }
        
        // Set first chip as active
        updateFilterChip(at: 0, isActive: true)
        
        activityFilter.addSubview(stackView)
        searchSection.addSubview(activityFilter)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: activityFilter.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: activityFilter.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: activityFilter.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: activityFilter.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: activityFilter.heightAnchor)
        ])
    }
    
    private func createFilterChip(title: String, index: Int) -> UIButton {
        let chip = UIButton(type: .custom)
        chip.setTitle(title.uppercased(), for: .normal)
        chip.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        chip.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        chip.layer.cornerRadius = 20
        chip.layer.borderWidth = 1
        chip.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        chip.configuration = config
        chip.tag = index
        chip.addTarget(self, action: #selector(filterChipTapped(_:)), for: .touchUpInside)
        
        return chip
    }
    
    private func setupTeamsList() {
        teamsList.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamsList)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            // Header elements
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            createTeamButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            createTeamButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            createTeamButton.widthAnchor.constraint(equalToConstant: 40),
            createTeamButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Search section
            searchSection.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            searchSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            searchSection.heightAnchor.constraint(equalToConstant: 80),
            
            // Search bar
            searchBar.topAnchor.constraint(equalTo: searchSection.topAnchor, constant: IndustrialDesign.Spacing.large),
            searchBar.leadingAnchor.constraint(equalTo: searchSection.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            searchBar.trailingAnchor.constraint(equalTo: searchSection.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            searchBar.heightAnchor.constraint(equalToConstant: 48),
            
            // Search bar elements
            searchIcon.leadingAnchor.constraint(equalTo: searchBar.leadingAnchor, constant: 16),
            searchIcon.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            searchIcon.widthAnchor.constraint(equalToConstant: 20),
            searchIcon.heightAnchor.constraint(equalToConstant: 20),
            
            searchInput.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 12),
            searchInput.trailingAnchor.constraint(equalTo: searchBar.trailingAnchor, constant: -16),
            searchInput.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
            
            // Activity filter
            activityFilter.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            activityFilter.leadingAnchor.constraint(equalTo: searchSection.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            activityFilter.trailingAnchor.constraint(equalTo: searchSection.trailingAnchor),
            activityFilter.bottomAnchor.constraint(equalTo: searchSection.bottomAnchor, constant: -IndustrialDesign.Spacing.medium),
            
            // Teams list
            teamsList.topAnchor.constraint(equalTo: searchSection.bottomAnchor, constant: IndustrialDesign.Spacing.large),
            teamsList.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            teamsList.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            teamsList.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -IndustrialDesign.Spacing.xLarge)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadRealTeams() {
        Task {
            do {
                let teams = try await SupabaseService.shared.fetchTeams()
                print("🏗️ RunstrRewards: Fetched \(teams.count) teams from Supabase")
                
                await MainActor.run {
                    displayTeams(teams)
                }
            } catch {
                print("🏗️ RunstrRewards: Error fetching teams: \(error)")
                
                await MainActor.run {
                    showErrorAlert("Failed to load teams: \(error.localizedDescription)")
                    // Fallback to empty state or error handling
                }
            }
        }
    }
    
    private func displayTeams(_ teams: [Team]) {
        // Clear existing team cards
        clearTeamCards()
        
        // Convert Supabase Team objects to TeamData format
        let teamDataArray = teams.map { team in
            TeamData(
                id: team.id,
                name: team.name,
                captain: getCaptainName(for: team.captainId), // TODO: Fetch real captain name
                members: team.memberCount,
                prizePool: formatEarnings(team.totalEarnings),
                activities: getActivitiesForTeam(team.id), // TODO: Fetch real activities from team_activities table
                isJoined: false // TODO: Check if current user is member
            )
        }
        
        var lastCard: UIView? = nil
        
        for teamData in teamDataArray {
            let teamCard = TeamCard(teamData: teamData)
            teamCard.delegate = self
            teamCard.translatesAutoresizingMaskIntoConstraints = false
            teamsList.addSubview(teamCard)
            teamCards.append(teamCard)
            
            NSLayoutConstraint.activate([
                teamCard.leadingAnchor.constraint(equalTo: teamsList.leadingAnchor),
                teamCard.trailingAnchor.constraint(equalTo: teamsList.trailingAnchor)
            ])
            
            if let lastCard = lastCard {
                teamCard.topAnchor.constraint(equalTo: lastCard.bottomAnchor, constant: IndustrialDesign.Spacing.medium).isActive = true
            } else {
                teamCard.topAnchor.constraint(equalTo: teamsList.topAnchor).isActive = true
            }
            
            lastCard = teamCard
        }
        
        if let lastCard = lastCard {
            teamsList.bottomAnchor.constraint(equalTo: lastCard.bottomAnchor).isActive = true
        }
    }
    
    private func clearTeamCards() {
        teamCards.forEach { $0.removeFromSuperview() }
        teamCards.removeAll()
        
        // Remove all constraints from teamsList
        teamsList.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func getCaptainName(for captainId: String) -> String {
        // TODO: Implement real captain name lookup
        // For now, return a formatted username
        return "@captain\(captainId.prefix(4))"
    }
    
    private func formatEarnings(_ earnings: Double) -> String {
        if earnings == 0 {
            return "₿0.00"
        }
        return String(format: "₿%.4f", earnings)
    }
    
    private func getActivitiesForTeam(_ teamId: String) -> [String] {
        // TODO: Implement real activities lookup from team_activities table
        // For now, return default activities based on team
        return ["Running", "Cycling", "Gym"] // Default activities
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Error Loading Teams",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.loadRealTeams()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        print("🏗️ RunstrRewards: Teams back button tapped")
        navigationController?.popViewController(animated: true)
        print("🏗️ RunstrRewards: Successfully navigated back to main dashboard")
    }
    
    @objc private func createTeamTapped() {
        print("🏗️ RUNSTR: Create team tapped")
        
        // DEVELOPMENT MODE: Bypassing subscription check for testing
        // TODO: Re-enable subscription check for production
        let isDevelopmentMode = true
        
        if isDevelopmentMode {
            print("🏗️ RUNSTR: Development mode - bypassing subscription check")
            showTeamCreationWizard()
        } else {
            // Original subscription check flow
            Task {
                let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
                
                await MainActor.run {
                    if subscriptionStatus == .captain {
                        print("🏗️ RUNSTR: Captain subscription active - launching team creation wizard")
                        showTeamCreationWizard()
                    } else {
                        print("🏗️ RUNSTR: Captain subscription required")
                        showCreatorSubscriptionPrompt()
                    }
                }
            }
        }
    }
    
    private func showTeamCreationWizard() {
        print("🏗️ RunstrRewards: Launching team creation wizard")
        
        let teamCreationWizard = TeamCreationWizardViewController()
        teamCreationWizard.onCompletion = { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("🏗️ RunstrRewards: Team created successfully - refreshing teams list")
                    self?.loadRealTeams() // Refresh the teams list
                    
                    // Post notification to refresh main dashboard
                    NotificationCenter.default.post(name: .teamCreated, object: nil)
                } else {
                    print("🏗️ RunstrRewards: Team creation cancelled")
                }
                self?.dismiss(animated: true)
            }
        }
        
        let navigationController = UINavigationController(rootViewController: teamCreationWizard)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    private func showCreatorSubscriptionPrompt() {
        print("🏗️ RunstrRewards: Showing creator subscription prompt")
        
        let alert = UIAlertController(
            title: "Creator Subscription Required",
            message: "To create and manage teams, you need a Creator subscription ($29.99/month). This includes team analytics, leaderboard creation, and event management tools.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Upgrade to Creator", style: .default) { _ in
            self.purchaseCreatorSubscription()
        })
        
        alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func purchaseCreatorSubscription() {
        print("🏗️ RunstrRewards: Initiating Creator subscription purchase")
        
        Task {
            do {
                let success = try await SubscriptionService.shared.purchaseCaptainSubscriptionBool()
                
                await MainActor.run {
                    if success {
                        print("🏗️ RunstrRewards: Creator subscription purchased successfully")
                        let alert = UIAlertController(
                            title: "Welcome to Creator!",
                            message: "You now have access to team creation, analytics, and management tools. Let's create your first team!",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Create Team", style: .default) { _ in
                            self.showTeamCreationWizard()
                        })
                        alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))
                        present(alert, animated: true)
                    } else {
                        print("🏗️ RunstrRewards: Creator subscription purchase failed")
                        let alert = UIAlertController(
                            title: "Purchase Failed",
                            message: "Unable to complete subscription purchase. Please try again.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        present(alert, animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    print("🏗️ RunstrRewards: Creator subscription purchase error: \(error)")
                    let alert = UIAlertController(
                        title: "Purchase Error",
                        message: "An error occurred during purchase: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                }
            }
        }
    }
    
    @objc private func filterChipTapped(_ sender: UIButton) {
        let newIndex = sender.tag
        if newIndex != selectedActivity {
            updateFilterChip(at: selectedActivity, isActive: false)
            updateFilterChip(at: newIndex, isActive: true)
            selectedActivity = newIndex
            
            print("Filter changed to: \(activities[newIndex])")
            // TODO: Filter teams based on selected activity
        }
    }
    
    private func updateFilterChip(at index: Int, isActive: Bool) {
        guard index < filterChips.count else { return }
        let chip = filterChips[index]
        
        if isActive {
            chip.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
            chip.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
            chip.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        } else {
            chip.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
            chip.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            chip.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        }
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        let gradient = CAGradientLayer.logo()
        gradient.frame = label.bounds
        
        let gradientColor = UIColor { _ in
            return UIColor.white
        }
        label.textColor = gradientColor
        
        // Create a mask for the gradient
        let maskLayer = CATextLayer()
        maskLayer.string = label.text
        maskLayer.font = label.font
        maskLayer.fontSize = label.font.pointSize
        maskLayer.frame = label.bounds
        maskLayer.alignmentMode = .center
        maskLayer.foregroundColor = UIColor.black.cgColor
        
        gradient.mask = maskLayer
        label.layer.addSublayer(gradient)
    }
}

// MARK: - TeamCardDelegate

extension TeamsViewController: TeamCardDelegate {
    func teamCardDidTap(_ teamCard: TeamCard, teamData: TeamData) {
        print("🏗️ RunstrRewards: Navigating to team detail for \(teamData.name)")
        
        let teamDetailViewController = TeamDetailViewController(teamData: teamData)
        navigationController?.pushViewController(teamDetailViewController, animated: true)
    }
}

// MARK: - Team Data Model

struct TeamData {
    let id: String
    let name: String
    let captain: String
    let members: Int
    let prizePool: String
    let activities: [String]
    let isJoined: Bool
}

// MARK: - Notifications

extension Notification.Name {
    static let teamCreated = Notification.Name("teamCreated")
}