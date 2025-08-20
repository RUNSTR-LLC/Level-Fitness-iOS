import UIKit

// MARK: - Prize Pool Models

struct PrizePoolData {
    let eventId: String
    let eventName: String
    let totalPool: Double
    let contributionSources: [PrizeContribution]
    let distributionPlan: PrizeDistributionPlan?
    let status: PrizePoolStatus
    let participantCount: Int
    let projectedRewards: [ProjectedReward]
    let milestones: [PrizePoolMilestone]
}

struct PrizeContribution {
    let source: ContributionSource
    let amount: Double
    let percentage: Double
    let timestamp: Date
    let description: String
}

struct PrizeDistributionPlan {
    let method: DistributionMethod
    let topPerformerShare: Double    // Percentage for top performers
    let participationShare: Double   // Percentage for all participants
    let minimumPayout: Double        // Minimum payout per person
}

struct ProjectedReward {
    let rank: Int
    let estimatedAmount: Double
    let probability: Double // 0.0 - 1.0, likelihood of achieving this rank
}

struct PrizePoolMilestone {
    let threshold: Double
    let description: String
    let achieved: Bool
    let achievedDate: Date?
    let bonusMultiplier: Double?
}

enum ContributionSource {
    case teamFund
    case eventTickets
    case sponsorship
    case bonus
    case rollover
}

enum PrizePoolStatus {
    case building
    case ready
    case distributed
    case expired
}

// MARK: - PrizePoolTrackerView

class PrizePoolTrackerView: UIView {
    
    // MARK: - Properties
    private var prizePoolData: PrizePoolData?
    private let eventId: String
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header section
    private let headerView = UIView()
    private let eventNameLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    
    // Pool overview section
    private let poolOverviewContainer = UIView()
    private let totalPoolLabel = UILabel()
    private let totalPoolValueLabel = UILabel()
    private let participantCountLabel = UILabel()
    private let perParticipantLabel = UILabel()
    
    // Visual pool representation
    private let poolVisualizationContainer = UIView()
    private let poolProgressBar = UIView()
    private let poolProgressFill = UIView()
    private let poolMilestonesContainer = UIView()
    
    // Contributions breakdown
    private let contributionsContainer = UIView()
    private let contributionsTitleLabel = UILabel()
    private let contributionsChartView = PieChartView()
    private let contributionsDetailContainer = UIView()
    
    // Projected rewards section
    private let rewardsContainer = UIView()
    private let rewardsTitleLabel = UILabel()
    private let rewardsTableView = UITableView()
    
    // Distribution plan section
    private let distributionContainer = UIView()
    private let distributionTitleLabel = UILabel()
    private let distributionMethodLabel = UILabel()
    private let distributionDetailsLabel = UILabel()
    
    // Loading and error states
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    
    init(eventId: String) {
        self.eventId = eventId
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        loadPrizePoolData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 0.95)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        setupScrollView()
        setupHeader()
        setupPoolOverview()
        setupVisualization()
        setupContributions()
        setupProjectedRewards()
        setupDistributionPlan()
        setupLoadingAndError()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        eventNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        eventNameLabel.textColor = IndustrialDesign.Colors.primaryText
        eventNameLabel.numberOfLines = 2
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusBadge.layer.cornerRadius = 8
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusBadge.addSubview(statusLabel)
        headerView.addSubview(eventNameLabel)
        headerView.addSubview(statusBadge)
        contentView.addSubview(headerView)
    }
    
    private func setupPoolOverview() {
        poolOverviewContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        poolOverviewContainer.layer.cornerRadius = 12
        poolOverviewContainer.layer.borderWidth = 1
        poolOverviewContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        poolOverviewContainer.translatesAutoresizingMaskIntoConstraints = false
        
        totalPoolLabel.text = "TOTAL PRIZE POOL"
        totalPoolLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        totalPoolLabel.textColor = IndustrialDesign.Colors.secondaryText
        totalPoolLabel.letterSpacing = 1.0
        totalPoolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalPoolValueLabel.text = "₿0.00000000"
        totalPoolValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 28, weight: .bold)
        totalPoolValueLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        totalPoolValueLabel.adjustsFontSizeToFitWidth = true
        totalPoolValueLabel.minimumScaleFactor = 0.8
        totalPoolValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        participantCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        participantCountLabel.textColor = IndustrialDesign.Colors.primaryText
        participantCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        perParticipantLabel.font = UIFont.systemFont(ofSize: 12)
        perParticipantLabel.textColor = IndustrialDesign.Colors.secondaryText
        perParticipantLabel.translatesAutoresizingMaskIntoConstraints = false
        
        poolOverviewContainer.addSubview(totalPoolLabel)
        poolOverviewContainer.addSubview(totalPoolValueLabel)
        poolOverviewContainer.addSubview(participantCountLabel)
        poolOverviewContainer.addSubview(perParticipantLabel)
        contentView.addSubview(poolOverviewContainer)
    }
    
    private func setupVisualization() {
        poolVisualizationContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        poolVisualizationContainer.layer.cornerRadius = 12
        poolVisualizationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress bar for milestones
        poolProgressBar.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        poolProgressBar.layer.cornerRadius = 6
        poolProgressBar.translatesAutoresizingMaskIntoConstraints = false
        
        poolProgressFill.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        poolProgressFill.layer.cornerRadius = 6
        poolProgressFill.translatesAutoresizingMaskIntoConstraints = false
        
        poolMilestonesContainer.translatesAutoresizingMaskIntoConstraints = false
        
        poolProgressBar.addSubview(poolProgressFill)
        poolVisualizationContainer.addSubview(poolProgressBar)
        poolVisualizationContainer.addSubview(poolMilestonesContainer)
        contentView.addSubview(poolVisualizationContainer)
    }
    
    private func setupContributions() {
        contributionsContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        contributionsContainer.layer.cornerRadius = 12
        contributionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        contributionsTitleLabel.text = "Prize Pool Sources"
        contributionsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        contributionsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        contributionsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contributionsChartView.translatesAutoresizingMaskIntoConstraints = false
        contributionsDetailContainer.translatesAutoresizingMaskIntoConstraints = false
        
        contributionsContainer.addSubview(contributionsTitleLabel)
        contributionsContainer.addSubview(contributionsChartView)
        contributionsContainer.addSubview(contributionsDetailContainer)
        contentView.addSubview(contributionsContainer)
    }
    
    private func setupProjectedRewards() {
        rewardsContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        rewardsContainer.layer.cornerRadius = 12
        rewardsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        rewardsTitleLabel.text = "Projected Rewards"
        rewardsTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        rewardsTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        rewardsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rewardsTableView.backgroundColor = .clear
        rewardsTableView.separatorStyle = .none
        rewardsTableView.isScrollEnabled = false
        rewardsTableView.delegate = self
        rewardsTableView.dataSource = self
        rewardsTableView.register(ProjectedRewardCell.self, forCellReuseIdentifier: "ProjectedRewardCell")
        rewardsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        rewardsContainer.addSubview(rewardsTitleLabel)
        rewardsContainer.addSubview(rewardsTableView)
        contentView.addSubview(rewardsContainer)
    }
    
    private func setupDistributionPlan() {
        distributionContainer.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        distributionContainer.layer.cornerRadius = 12
        distributionContainer.translatesAutoresizingMaskIntoConstraints = false
        
        distributionTitleLabel.text = "Distribution Plan"
        distributionTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        distributionTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        distributionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        distributionMethodLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        distributionMethodLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        distributionMethodLabel.translatesAutoresizingMaskIntoConstraints = false
        
        distributionDetailsLabel.font = UIFont.systemFont(ofSize: 12)
        distributionDetailsLabel.textColor = IndustrialDesign.Colors.secondaryText
        distributionDetailsLabel.numberOfLines = 0
        distributionDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        distributionContainer.addSubview(distributionTitleLabel)
        distributionContainer.addSubview(distributionMethodLabel)
        distributionContainer.addSubview(distributionDetailsLabel)
        contentView.addSubview(distributionContainer)
    }
    
    private func setupLoadingAndError() {
        loadingIndicator.color = IndustrialDesign.Colors.primaryText
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.textColor = UIColor.systemRed
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(errorLabel)
    }
    
    private func setupConstraints() {
        let spacing: CGFloat = 16
        
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            eventNameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            eventNameLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            eventNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -12),
            
            statusBadge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            statusBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 80),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            
            // Pool overview
            poolOverviewContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: spacing),
            poolOverviewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            poolOverviewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            poolOverviewContainer.heightAnchor.constraint(equalToConstant: 120),
            
            totalPoolLabel.topAnchor.constraint(equalTo: poolOverviewContainer.topAnchor, constant: 16),
            totalPoolLabel.leadingAnchor.constraint(equalTo: poolOverviewContainer.leadingAnchor, constant: 16),
            
            totalPoolValueLabel.topAnchor.constraint(equalTo: totalPoolLabel.bottomAnchor, constant: 8),
            totalPoolValueLabel.leadingAnchor.constraint(equalTo: poolOverviewContainer.leadingAnchor, constant: 16),
            totalPoolValueLabel.trailingAnchor.constraint(equalTo: poolOverviewContainer.trailingAnchor, constant: -16),
            
            participantCountLabel.topAnchor.constraint(equalTo: totalPoolValueLabel.bottomAnchor, constant: 8),
            participantCountLabel.leadingAnchor.constraint(equalTo: poolOverviewContainer.leadingAnchor, constant: 16),
            
            perParticipantLabel.centerYAnchor.constraint(equalTo: participantCountLabel.centerYAnchor),
            perParticipantLabel.trailingAnchor.constraint(equalTo: poolOverviewContainer.trailingAnchor, constant: -16),
            
            // Visualization
            poolVisualizationContainer.topAnchor.constraint(equalTo: poolOverviewContainer.bottomAnchor, constant: spacing),
            poolVisualizationContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            poolVisualizationContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            poolVisualizationContainer.heightAnchor.constraint(equalToConstant: 80),
            
            poolProgressBar.centerYAnchor.constraint(equalTo: poolVisualizationContainer.centerYAnchor),
            poolProgressBar.leadingAnchor.constraint(equalTo: poolVisualizationContainer.leadingAnchor, constant: 16),
            poolProgressBar.trailingAnchor.constraint(equalTo: poolVisualizationContainer.trailingAnchor, constant: -16),
            poolProgressBar.heightAnchor.constraint(equalToConstant: 12),
            
            poolProgressFill.leadingAnchor.constraint(equalTo: poolProgressBar.leadingAnchor),
            poolProgressFill.topAnchor.constraint(equalTo: poolProgressBar.topAnchor),
            poolProgressFill.bottomAnchor.constraint(equalTo: poolProgressBar.bottomAnchor),
            poolProgressFill.widthAnchor.constraint(equalTo: poolProgressBar.widthAnchor, multiplier: 0.0), // Will be updated
            
            // Contributions
            contributionsContainer.topAnchor.constraint(equalTo: poolVisualizationContainer.bottomAnchor, constant: spacing),
            contributionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            contributionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            contributionsContainer.heightAnchor.constraint(equalToConstant: 200),
            
            contributionsTitleLabel.topAnchor.constraint(equalTo: contributionsContainer.topAnchor, constant: 16),
            contributionsTitleLabel.leadingAnchor.constraint(equalTo: contributionsContainer.leadingAnchor, constant: 16),
            
            contributionsChartView.topAnchor.constraint(equalTo: contributionsTitleLabel.bottomAnchor, constant: 12),
            contributionsChartView.leadingAnchor.constraint(equalTo: contributionsContainer.leadingAnchor, constant: 16),
            contributionsChartView.widthAnchor.constraint(equalToConstant: 100),
            contributionsChartView.heightAnchor.constraint(equalToConstant: 100),
            
            contributionsDetailContainer.topAnchor.constraint(equalTo: contributionsTitleLabel.bottomAnchor, constant: 12),
            contributionsDetailContainer.leadingAnchor.constraint(equalTo: contributionsChartView.trailingAnchor, constant: 16),
            contributionsDetailContainer.trailingAnchor.constraint(equalTo: contributionsContainer.trailingAnchor, constant: -16),
            contributionsDetailContainer.heightAnchor.constraint(equalToConstant: 100),
            
            // Projected rewards
            rewardsContainer.topAnchor.constraint(equalTo: contributionsContainer.bottomAnchor, constant: spacing),
            rewardsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            rewardsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            rewardsContainer.heightAnchor.constraint(equalToConstant: 180),
            
            rewardsTitleLabel.topAnchor.constraint(equalTo: rewardsContainer.topAnchor, constant: 16),
            rewardsTitleLabel.leadingAnchor.constraint(equalTo: rewardsContainer.leadingAnchor, constant: 16),
            
            rewardsTableView.topAnchor.constraint(equalTo: rewardsTitleLabel.bottomAnchor, constant: 12),
            rewardsTableView.leadingAnchor.constraint(equalTo: rewardsContainer.leadingAnchor),
            rewardsTableView.trailingAnchor.constraint(equalTo: rewardsContainer.trailingAnchor),
            rewardsTableView.bottomAnchor.constraint(equalTo: rewardsContainer.bottomAnchor, constant: -16),
            
            // Distribution plan
            distributionContainer.topAnchor.constraint(equalTo: rewardsContainer.bottomAnchor, constant: spacing),
            distributionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            distributionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            distributionContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
            distributionContainer.heightAnchor.constraint(equalToConstant: 100),
            
            distributionTitleLabel.topAnchor.constraint(equalTo: distributionContainer.topAnchor, constant: 16),
            distributionTitleLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            
            distributionMethodLabel.topAnchor.constraint(equalTo: distributionTitleLabel.bottomAnchor, constant: 8),
            distributionMethodLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            
            distributionDetailsLabel.topAnchor.constraint(equalTo: distributionMethodLabel.bottomAnchor, constant: 4),
            distributionDetailsLabel.leadingAnchor.constraint(equalTo: distributionContainer.leadingAnchor, constant: 16),
            distributionDetailsLabel.trailingAnchor.constraint(equalTo: distributionContainer.trailingAnchor, constant: -16),
            
            // Loading and error
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadPrizePoolData() {
        showLoadingState()
        
        // Simulate loading prize pool data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.prizePoolData = self.createMockPrizePoolData()
            self.updateUI()
            self.hideLoadingState()
        }
    }
    
    private func createMockPrizePoolData() -> PrizePoolData {
        let contributions = [
            PrizeContribution(
                source: .teamFund,
                amount: 15000,
                percentage: 60.0,
                timestamp: Date().addingTimeInterval(-7 * 24 * 3600),
                description: "Team wallet contribution"
            ),
            PrizeContribution(
                source: .eventTickets,
                amount: 7500,
                percentage: 30.0,
                timestamp: Date().addingTimeInterval(-3 * 24 * 3600),
                description: "Event entry fees"
            ),
            PrizeContribution(
                source: .sponsorship,
                amount: 2500,
                percentage: 10.0,
                timestamp: Date().addingTimeInterval(-1 * 24 * 3600),
                description: "Sponsor contribution"
            )
        ]
        
        let distributionPlan = PrizeDistributionPlan(
            method: .performance,
            topPerformerShare: 60.0,
            participationShare: 40.0,
            minimumPayout: 100
        )
        
        let projectedRewards = [
            ProjectedReward(rank: 1, estimatedAmount: 8000, probability: 0.15),
            ProjectedReward(rank: 2, estimatedAmount: 5000, probability: 0.20),
            ProjectedReward(rank: 3, estimatedAmount: 3000, probability: 0.25),
            ProjectedReward(rank: 10, estimatedAmount: 1000, probability: 0.65),
            ProjectedReward(rank: 20, estimatedAmount: 500, probability: 0.85)
        ]
        
        let milestones = [
            PrizePoolMilestone(
                threshold: 10000,
                description: "Minimum pool achieved",
                achieved: true,
                achievedDate: Date().addingTimeInterval(-5 * 24 * 3600),
                bonusMultiplier: nil
            ),
            PrizePoolMilestone(
                threshold: 25000,
                description: "Target pool reached - 10% bonus",
                achieved: true,
                achievedDate: Date().addingTimeInterval(-1 * 24 * 3600),
                bonusMultiplier: 1.1
            ),
            PrizePoolMilestone(
                threshold: 50000,
                description: "Stretch goal - 25% bonus",
                achieved: false,
                achievedDate: nil,
                bonusMultiplier: 1.25
            )
        ]
        
        return PrizePoolData(
            eventId: eventId,
            eventName: "December Distance Challenge",
            totalPool: 25000,
            contributionSources: contributions,
            distributionPlan: distributionPlan,
            status: .ready,
            participantCount: 47,
            projectedRewards: projectedRewards,
            milestones: milestones
        )
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        guard let data = prizePoolData else { return }
        
        // Update header
        eventNameLabel.text = data.eventName
        statusLabel.text = data.status.displayName
        statusBadge.backgroundColor = data.status.color
        
        // Update pool overview
        let poolBtc = data.totalPool / 100_000_000.0
        totalPoolValueLabel.text = "₿\(String(format: "%.8f", poolBtc))"
        
        participantCountLabel.text = "\(data.participantCount) participants"
        
        let perParticipantAmount = data.totalPool / Double(data.participantCount)
        let perParticipantBtc = perParticipantAmount / 100_000_000.0
        perParticipantLabel.text = "≈₿\(String(format: "%.6f", perParticipantBtc)) each"
        
        // Update visualization
        updatePoolVisualization(data: data)
        
        // Update contributions
        updateContributionsDisplay(data: data)
        
        // Update distribution plan
        if let plan = data.distributionPlan {
            distributionMethodLabel.text = plan.method.displayName
            distributionDetailsLabel.text = "Top performers: \(Int(plan.topPerformerShare))% • All participants: \(Int(plan.participationShare))% • Minimum: ₿\(String(format: "%.6f", plan.minimumPayout / 100_000_000.0))"
        }
        
        // Reload rewards table
        rewardsTableView.reloadData()
    }
    
    private func updatePoolVisualization(data: PrizePoolData) {
        // Find the current milestone progress
        let achievedMilestones = data.milestones.filter { $0.achieved }
        let nextMilestone = data.milestones.first { !$0.achieved }
        
        if let next = nextMilestone {
            let progress = data.totalPool / next.threshold
            
            // Update progress bar
            poolProgressFill.widthAnchor.constraint(equalTo: poolProgressBar.widthAnchor, multiplier: min(progress, 1.0)).isActive = true
            
            UIView.animate(withDuration: 0.5) {
                self.layoutIfNeeded()
            }
        }
        
        // Update milestones display
        updateMilestonesDisplay(milestones: data.milestones, currentAmount: data.totalPool)
    }
    
    private func updateMilestonesDisplay(milestones: [PrizePoolMilestone], currentAmount: Double) {
        // Clear existing milestone views
        poolMilestonesContainer.subviews.forEach { $0.removeFromSuperview() }
        
        for (index, milestone) in milestones.enumerated() {
            let milestoneView = createMilestoneIndicator(
                milestone: milestone,
                isAchieved: milestone.achieved,
                position: CGFloat(index) / CGFloat(milestones.count - 1)
            )
            
            poolMilestonesContainer.addSubview(milestoneView)
        }
    }
    
    private func createMilestoneIndicator(milestone: PrizePoolMilestone, isAchieved: Bool, position: CGFloat) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let indicator = UIView()
        indicator.backgroundColor = isAchieved ? UIColor.systemGreen : UIColor.systemGray
        indicator.layer.cornerRadius = 6
        indicator.layer.borderWidth = 2
        indicator.layer.borderColor = UIColor.white.cgColor
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "₿\(String(format: "%.0f", milestone.threshold / 100_000_000.0))"
        label.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        label.textColor = IndustrialDesign.Colors.secondaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(indicator)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 40),
            container.heightAnchor.constraint(equalToConstant: 30),
            
            indicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: container.topAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 12),
            indicator.heightAnchor.constraint(equalToConstant: 12),
            
            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        // Position the milestone on the progress bar
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: poolMilestonesContainer.leadingAnchor, constant: position * (poolMilestonesContainer.frame.width - 40) + 20),
            container.centerYAnchor.constraint(equalTo: poolMilestonesContainer.centerYAnchor)
        ])
        
        return container
    }
    
    private func updateContributionsDisplay(data: PrizePoolData) {
        // Update pie chart
        let chartData = data.contributionSources.map { contribution in
            PieChartData(
                value: contribution.percentage,
                color: contribution.source.color,
                label: contribution.source.displayName
            )
        }
        contributionsChartView.updateData(chartData)
        
        // Update details list
        contributionsDetailContainer.subviews.forEach { $0.removeFromSuperview() }
        
        var previousView: UIView = contributionsDetailContainer
        
        for (index, contribution) in data.contributionSources.enumerated() {
            let detailView = createContributionDetailView(contribution: contribution)
            contributionsDetailContainer.addSubview(detailView)
            
            NSLayoutConstraint.activate([
                detailView.topAnchor.constraint(equalTo: index == 0 ? contributionsDetailContainer.topAnchor : previousView.bottomAnchor, constant: index == 0 ? 0 : 8),
                detailView.leadingAnchor.constraint(equalTo: contributionsDetailContainer.leadingAnchor),
                detailView.trailingAnchor.constraint(equalTo: contributionsDetailContainer.trailingAnchor),
                detailView.heightAnchor.constraint(equalToConstant: 20)
            ])
            
            previousView = detailView
        }
    }
    
    private func createContributionDetailView(contribution: PrizeContribution) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let colorIndicator = UIView()
        colorIndicator.backgroundColor = contribution.source.color
        colorIndicator.layer.cornerRadius = 4
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = contribution.source.displayName
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let amountLabel = UILabel()
        let amountBtc = contribution.amount / 100_000_000.0
        amountLabel.text = "₿\(String(format: "%.6f", amountBtc))"
        amountLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        amountLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(colorIndicator)
        container.addSubview(nameLabel)
        container.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            colorIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 8),
            colorIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            amountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            amountLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
        
        return container
    }
    
    private func showLoadingState() {
        loadingIndicator.startAnimating()
        contentView.alpha = 0.5
        errorLabel.isHidden = true
    }
    
    private func hideLoadingState() {
        loadingIndicator.stopAnimating()
        contentView.alpha = 1.0
        errorLabel.isHidden = true
    }
    
    private func showErrorState(_ message: String) {
        loadingIndicator.stopAnimating()
        contentView.alpha = 0.5
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension PrizePoolTrackerView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prizePoolData?.projectedRewards.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectedRewardCell", for: indexPath) as? ProjectedRewardCell,
              let reward = prizePoolData?.projectedRewards[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.configure(with: reward)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
}

// MARK: - Extensions

extension PrizePoolStatus {
    var displayName: String {
        switch self {
        case .building: return "Building"
        case .ready: return "Ready"
        case .distributed: return "Distributed"
        case .expired: return "Expired"
        }
    }
    
    var color: UIColor {
        switch self {
        case .building: return UIColor.systemOrange
        case .ready: return UIColor.systemGreen
        case .distributed: return UIColor.systemBlue
        case .expired: return UIColor.systemGray
        }
    }
}

extension ContributionSource {
    var displayName: String {
        switch self {
        case .teamFund: return "Team Fund"
        case .eventTickets: return "Entry Fees"
        case .sponsorship: return "Sponsorship"
        case .bonus: return "Bonus"
        case .rollover: return "Rollover"
        }
    }
    
    var color: UIColor {
        switch self {
        case .teamFund: return UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        case .eventTickets: return UIColor.systemBlue
        case .sponsorship: return UIColor.systemPurple
        case .bonus: return UIColor.systemGreen
        case .rollover: return UIColor.systemTeal
        }
    }
}

extension DistributionMethod {
    var displayName: String {
        switch self {
        case .equal: return "Equal Distribution"
        case .performance: return "Performance Based"
        case .topPerformers: return "Top Performers Only"
        case .hybrid: return "Hybrid Method"
        case .custom: return "Custom Allocation"
        }
    }
}

// MARK: - Supporting Views

class PieChartView: UIView {
    private var chartData: [PieChartData] = []
    
    func updateData(_ data: [PieChartData]) {
        chartData = data
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard !chartData.isEmpty else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        
        var currentAngle: CGFloat = 0
        
        for data in chartData {
            let sliceAngle = CGFloat(data.value / 100.0) * 2 * .pi
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: currentAngle, endAngle: currentAngle + sliceAngle, clockwise: true)
            path.close()
            
            data.color.setFill()
            path.fill()
            
            currentAngle += sliceAngle
        }
    }
}

struct PieChartData {
    let value: Double
    let color: UIColor
    let label: String
}

class ProjectedRewardCell: UITableViewCell {
    private let rankLabel = UILabel()
    private let amountLabel = UILabel()
    private let probabilityLabel = UILabel()
    private let probabilityBar = UIView()
    private let probabilityFill = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none
        
        rankLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        rankLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        amountLabel.textColor = IndustrialDesign.Colors.primaryText
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        probabilityBar.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        probabilityBar.layer.cornerRadius = 2
        probabilityBar.translatesAutoresizingMaskIntoConstraints = false
        
        probabilityFill.backgroundColor = UIColor.systemGreen
        probabilityFill.layer.cornerRadius = 2
        probabilityFill.translatesAutoresizingMaskIntoConstraints = false
        
        probabilityLabel.font = UIFont.systemFont(ofSize: 10)
        probabilityLabel.textColor = IndustrialDesign.Colors.secondaryText
        probabilityLabel.textAlignment = .right
        probabilityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        probabilityBar.addSubview(probabilityFill)
        contentView.addSubview(rankLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(probabilityBar)
        contentView.addSubview(probabilityLabel)
        
        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 50),
            
            amountLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            amountLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            amountLabel.widthAnchor.constraint(equalToConstant: 80),
            
            probabilityBar.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 12),
            probabilityBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            probabilityBar.heightAnchor.constraint(equalToConstant: 4),
            probabilityBar.trailingAnchor.constraint(equalTo: probabilityLabel.leadingAnchor, constant: -8),
            
            probabilityFill.leadingAnchor.constraint(equalTo: probabilityBar.leadingAnchor),
            probabilityFill.topAnchor.constraint(equalTo: probabilityBar.topAnchor),
            probabilityFill.bottomAnchor.constraint(equalTo: probabilityBar.bottomAnchor),
            probabilityFill.widthAnchor.constraint(equalTo: probabilityBar.widthAnchor, multiplier: 0.0), // Will be updated
            
            probabilityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            probabilityLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            probabilityLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with reward: ProjectedReward) {
        rankLabel.text = "#\(reward.rank)"
        
        let amountBtc = reward.estimatedAmount / 100_000_000.0
        amountLabel.text = "₿\(String(format: "%.4f", amountBtc))"
        
        probabilityLabel.text = "\(Int(reward.probability * 100))%"
        
        probabilityFill.widthAnchor.constraint(equalTo: probabilityBar.widthAnchor, multiplier: reward.probability).isActive = true
    }
}