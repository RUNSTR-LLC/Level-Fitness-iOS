import UIKit

class TeamDetailLeagueViewController: UIViewController {
    
    // MARK: - Properties
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // League header
    private let leagueHeader = UIView()
    private let leagueTitle = UILabel()
    private let leaderboardPeriod = UILabel()
    private let refreshButton = UIButton(type: .custom)
    
    // Creator management section (only visible to team creators)
    private let managementSection = UIView()
    private let managementTitle = UILabel()
    private let createLeagueButton = UIButton(type: .custom)
    private let editLeaderboardButton = UIButton(type: .custom)
    private let viewAnalyticsButton = UIButton(type: .custom)
    
    // Leaderboard container
    private let leaderboardContainer = UIView()
    private var leaderboardItems: [LeaderboardItemView] = []
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescription = UILabel()
    
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        checkCreatorPermissions()
        loadLeaderboardData()
        
        print("🏆 TeamDetailLeague: League view loaded for team \(teamData.name)")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.clear
        
        setupScrollView()
        setupLeagueHeader()
        setupManagementSection()
        setupLeaderboardContainer()
        setupEmptyState()
        
        // Add all components to content view
        [leagueHeader, managementSection, leaderboardContainer, emptyStateView].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupLeagueHeader() {
        leagueHeader.translatesAutoresizingMaskIntoConstraints = false
        leagueHeader.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        leagueHeader.layer.cornerRadius = 12
        leagueHeader.layer.borderWidth = 1
        leagueHeader.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // League title
        leagueTitle.text = "Team Leaderboard"
        leagueTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        leagueTitle.textColor = IndustrialDesign.Colors.primaryText
        leagueTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Period indicator
        leaderboardPeriod.text = "Weekly Rankings"
        leaderboardPeriod.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        leaderboardPeriod.textColor = IndustrialDesign.Colors.secondaryText
        leaderboardPeriod.translatesAutoresizingMaskIntoConstraints = false
        
        // Refresh button
        refreshButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshButton.tintColor = IndustrialDesign.Colors.secondaryText
        refreshButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        refreshButton.layer.cornerRadius = 16
        refreshButton.layer.borderWidth = 1
        refreshButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        
        [leagueTitle, leaderboardPeriod, refreshButton].forEach {
            leagueHeader.addSubview($0)
        }
    }
    
    private func setupManagementSection() {
        managementSection.translatesAutoresizingMaskIntoConstraints = false
        managementSection.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        managementSection.layer.cornerRadius = 12
        managementSection.layer.borderWidth = 1
        managementSection.layer.borderColor = UIColor(red: 0.27, green: 0.47, blue: 0.87, alpha: 0.5).cgColor // Blue border for creator features
        managementSection.isHidden = true // Will be shown only for creators
        
        // Management title
        managementTitle.text = "Creator Tools"
        managementTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        managementTitle.textColor = UIColor(red: 0.27, green: 0.47, blue: 0.87, alpha: 1.0) // Blue text
        managementTitle.translatesAutoresizingMaskIntoConstraints = false
        
        // Create league button (prominent bitcoin orange)
        createLeagueButton.setTitle("Create Monthly League", for: .normal)
        createLeagueButton.setTitleColor(.white, for: .normal)
        createLeagueButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        createLeagueButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        createLeagueButton.layer.cornerRadius = 8
        createLeagueButton.layer.borderWidth = 1
        createLeagueButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        createLeagueButton.translatesAutoresizingMaskIntoConstraints = false
        createLeagueButton.addTarget(self, action: #selector(createLeagueTapped), for: .touchUpInside)
        
        // Edit leaderboard button
        editLeaderboardButton.setTitle("Edit Leaderboard", for: .normal)
        editLeaderboardButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        editLeaderboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        editLeaderboardButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        editLeaderboardButton.layer.cornerRadius = 8
        editLeaderboardButton.layer.borderWidth = 1
        editLeaderboardButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        editLeaderboardButton.translatesAutoresizingMaskIntoConstraints = false
        editLeaderboardButton.addTarget(self, action: #selector(editLeaderboardTapped), for: .touchUpInside)
        
        // View analytics button
        viewAnalyticsButton.setTitle("View Analytics", for: .normal)
        viewAnalyticsButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        viewAnalyticsButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        viewAnalyticsButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        viewAnalyticsButton.layer.cornerRadius = 8
        viewAnalyticsButton.layer.borderWidth = 1
        viewAnalyticsButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        viewAnalyticsButton.translatesAutoresizingMaskIntoConstraints = false
        viewAnalyticsButton.addTarget(self, action: #selector(viewAnalyticsTapped), for: .touchUpInside)
        
        [managementTitle, createLeagueButton, editLeaderboardButton, viewAnalyticsButton].forEach {
            managementSection.addSubview($0)
        }
    }
    
    private func setupLeaderboardContainer() {
        leaderboardContainer.translatesAutoresizingMaskIntoConstraints = false
        leaderboardContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        leaderboardContainer.layer.cornerRadius = 12
        leaderboardContainer.layer.borderWidth = 1
        leaderboardContainer.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        emptyStateView.layer.cornerRadius = 12
        emptyStateView.layer.borderWidth = 1
        emptyStateView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        emptyStateView.isHidden = true
        
        emptyStateLabel.text = "No Rankings Yet"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        emptyStateLabel.textColor = IndustrialDesign.Colors.primaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateDescription.text = "Team members need to complete workouts to appear on the leaderboard. Rankings will update automatically as members sync their HealthKit data."
        emptyStateDescription.font = UIFont.systemFont(ofSize: 14)
        emptyStateDescription.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescription.textAlignment = .center
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.translatesAutoresizingMaskIntoConstraints = false
        
        [emptyStateLabel, emptyStateDescription].forEach {
            emptyStateView.addSubview($0)
        }
    }
    
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
            
            // League header
            leagueHeader.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            leagueHeader.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leagueHeader.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            leagueTitle.topAnchor.constraint(equalTo: leagueHeader.topAnchor, constant: 16),
            leagueTitle.leadingAnchor.constraint(equalTo: leagueHeader.leadingAnchor, constant: 16),
            
            leaderboardPeriod.topAnchor.constraint(equalTo: leagueTitle.bottomAnchor, constant: 4),
            leaderboardPeriod.leadingAnchor.constraint(equalTo: leagueHeader.leadingAnchor, constant: 16),
            leaderboardPeriod.bottomAnchor.constraint(equalTo: leagueHeader.bottomAnchor, constant: -16),
            
            refreshButton.trailingAnchor.constraint(equalTo: leagueHeader.trailingAnchor, constant: -16),
            refreshButton.centerYAnchor.constraint(equalTo: leagueHeader.centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 32),
            refreshButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Management section
            managementSection.topAnchor.constraint(equalTo: leagueHeader.bottomAnchor, constant: 16),
            managementSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            managementSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            managementTitle.topAnchor.constraint(equalTo: managementSection.topAnchor, constant: 16),
            managementTitle.leadingAnchor.constraint(equalTo: managementSection.leadingAnchor, constant: 16),
            managementTitle.trailingAnchor.constraint(equalTo: managementSection.trailingAnchor, constant: -16),
            
            // Create league button - full width, prominent
            createLeagueButton.topAnchor.constraint(equalTo: managementTitle.bottomAnchor, constant: 12),
            createLeagueButton.leadingAnchor.constraint(equalTo: managementSection.leadingAnchor, constant: 16),
            createLeagueButton.trailingAnchor.constraint(equalTo: managementSection.trailingAnchor, constant: -16),
            createLeagueButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Second row: Edit and Analytics buttons
            editLeaderboardButton.topAnchor.constraint(equalTo: createLeagueButton.bottomAnchor, constant: 12),
            editLeaderboardButton.leadingAnchor.constraint(equalTo: managementSection.leadingAnchor, constant: 16),
            editLeaderboardButton.trailingAnchor.constraint(equalTo: managementSection.centerXAnchor, constant: -6),
            editLeaderboardButton.heightAnchor.constraint(equalToConstant: 36),
            
            viewAnalyticsButton.topAnchor.constraint(equalTo: createLeagueButton.bottomAnchor, constant: 12),
            viewAnalyticsButton.leadingAnchor.constraint(equalTo: managementSection.centerXAnchor, constant: 6),
            viewAnalyticsButton.trailingAnchor.constraint(equalTo: managementSection.trailingAnchor, constant: -16),
            viewAnalyticsButton.heightAnchor.constraint(equalToConstant: 36),
            viewAnalyticsButton.bottomAnchor.constraint(equalTo: managementSection.bottomAnchor, constant: -16),
            
            // Leaderboard container
            leaderboardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leaderboardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            leaderboardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Empty state
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            emptyStateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 40),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 24),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -24),
            
            emptyStateDescription.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 12),
            emptyStateDescription.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 24),
            emptyStateDescription.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -24)
        ])
        
        // Dynamic constraint based on management section visibility
        updateLeaderboardTopConstraint()
    }
    
    private func updateLeaderboardTopConstraint() {
        leaderboardContainer.topAnchor.constraint(
            equalTo: managementSection.isHidden ? leagueHeader.bottomAnchor : managementSection.bottomAnchor,
            constant: 16
        ).isActive = true
        
        emptyStateView.topAnchor.constraint(
            equalTo: managementSection.isHidden ? leagueHeader.bottomAnchor : managementSection.bottomAnchor,
            constant: 16
        ).isActive = true
    }
    
    // MARK: - Creator Permissions
    
    private func checkCreatorPermissions() {
        Task {
            let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
            
            await MainActor.run {
                let isCreator = (subscriptionStatus == .captain)
                managementSection.isHidden = !isCreator
                
                if isCreator {
                    print("🏆 TeamDetailLeague: Creator tools enabled")
                } else {
                    print("🏆 TeamDetailLeague: Standard member view")
                }
                
                updateLeaderboardTopConstraint()
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadLeaderboardData() {
        print("🏆 TeamDetailLeague: Loading real leaderboard data for team \(teamData.id)")
        
        Task {
            do {
                // Fetch real team leaderboard data
                let leaderboardMembers = try await SupabaseService.shared.fetchTeamLeaderboard(
                    teamId: teamData.id,
                    type: "distance",  // Could be configurable based on team settings
                    period: "weekly"
                )
                
                // Convert to LeaderboardUser format for display
                let leaderboardUsers = leaderboardMembers.map { member in
                    LeaderboardUser(
                        id: member.userId,
                        username: member.username,
                        rank: member.rank,
                        distance: member.totalDistance / 1000.0, // Convert to km
                        workouts: member.workoutCount,
                        points: member.totalPoints
                    )
                }
                
                await MainActor.run {
                    print("🏆 TeamDetailLeague: Loaded \(leaderboardUsers.count) team members for leaderboard")
                    self.displayLeaderboard(leaderboardUsers)
                }
                
            } catch {
                print("🏆 TeamDetailLeague: Error loading leaderboard data: \(error)")
                
                await MainActor.run {
                    // Show empty state if no data can be loaded
                    self.displayLeaderboard([])
                }
            }
        }
    }
    
    private func displayLeaderboard(_ users: [LeaderboardUser]) {
        // Clear existing items
        leaderboardItems.forEach { $0.removeFromSuperview() }
        leaderboardItems.removeAll()
        
        if users.isEmpty {
            leaderboardContainer.isHidden = true
            emptyStateView.isHidden = false
            return
        }
        
        leaderboardContainer.isHidden = false
        emptyStateView.isHidden = true
        
        var previousItem: UIView? = nil
        
        for user in users {
            let itemView = LeaderboardItemView(user: user)
            itemView.translatesAutoresizingMaskIntoConstraints = false
            leaderboardContainer.addSubview(itemView)
            leaderboardItems.append(itemView)
            
            NSLayoutConstraint.activate([
                itemView.leadingAnchor.constraint(equalTo: leaderboardContainer.leadingAnchor, constant: 16),
                itemView.trailingAnchor.constraint(equalTo: leaderboardContainer.trailingAnchor, constant: -16),
                itemView.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            if let previousItem = previousItem {
                itemView.topAnchor.constraint(equalTo: previousItem.bottomAnchor, constant: 8).isActive = true
            } else {
                itemView.topAnchor.constraint(equalTo: leaderboardContainer.topAnchor, constant: 16).isActive = true
            }
            
            previousItem = itemView
        }
        
        if let lastItem = previousItem {
            leaderboardContainer.bottomAnchor.constraint(equalTo: lastItem.bottomAnchor, constant: 16).isActive = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func refreshTapped() {
        print("🏆 TeamDetailLeague: Refreshing leaderboard")
        
        // Add refresh animation
        refreshButton.isEnabled = false
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1.0
        refreshButton.layer.add(rotation, forKey: "rotationAnimation")
        
        // Reload real data from server
        loadLeaderboardData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.refreshButton.isEnabled = true
            self.refreshButton.layer.removeAnimation(forKey: "rotationAnimation")
            print("🏆 TeamDetailLeague: Leaderboard refreshed")
        }
    }
    
    @objc private func editLeaderboardTapped() {
        print("🏆 TeamDetailLeague: Edit leaderboard tapped")
        
        let alert = UIAlertController(
            title: "Edit Leaderboard",
            message: "Leaderboard editing wizard coming soon. You'll be able to change ranking methods, periods, and add custom competitions.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func createLeagueTapped() {
        print("🏆 TeamDetailLeague: Create league tapped")
        
        // Get team wallet balance (placeholder - will integrate with actual wallet service)
        let teamWalletBalance = 500000 // 0.005 BTC = 500,000 sats
        
        let leagueWizard = LeagueCreationWizardViewController(teamData: teamData, teamWalletBalance: teamWalletBalance)
        leagueWizard.onCompletion = { [weak self] (success: Bool, league: TeamLeague?) in
            leagueWizard.dismiss(animated: true) {
                if success, let createdLeague = league {
                    print("🏆 TeamDetailLeague: League created successfully: \(createdLeague.name)")
                    
                    // Show success message
                    let successAlert = UIAlertController(
                        title: "League Created! 🏆",
                        message: "Your monthly league '\(createdLeague.name)' is now active and members can start competing for Bitcoin prizes!",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "Great!", style: .default))
                    self?.present(successAlert, animated: true)
                    
                    // Refresh the leaderboard to show new league data
                    self?.loadLeaderboardData()
                } else {
                    print("🏆 TeamDetailLeague: League creation cancelled or failed")
                }
            }
        }
        
        present(leagueWizard, animated: true)
    }
    
    @objc private func viewAnalyticsTapped() {
        print("🏆 TeamDetailLeague: View analytics tapped")
        
        let alert = UIAlertController(
            title: "Team Analytics",
            message: "Analytics dashboard coming soon. You'll see member engagement, workout trends, and revenue insights.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// LeaderboardUser data model is defined in LeagueView.swift to avoid duplication