import UIKit

// MARK: - Payout History Models

struct PayoutHistoryEntry {
    let payoutId: String
    let eventId: String
    let eventName: String
    let teamId: String
    let teamName: String
    let amount: Double
    let distributionMethod: DistributionMethod
    let payoutDate: Date
    let status: PayoutStatus
    let rank: Int?
    let totalParticipants: Int?
    let notes: String?
    let transactionId: String?
}

struct PayoutSummary {
    let totalEarnings: Double
    let payoutCount: Int
    let averagePayout: Double
    let bestPayout: Double
    let lastPayoutDate: Date?
    let favoriteTeam: String?
    let totalEvents: Int
}

enum PayoutHistoryFilter {
    case all
    case thisMonth
    case thisYear
    case byTeam(String)
    case byAmount(min: Double, max: Double)
}

// MARK: - MemberPayoutHistoryViewController

class MemberPayoutHistoryViewController: UIViewController {
    
    // MARK: - Properties
    private var payoutHistory: [PayoutHistoryEntry] = []
    private var filteredHistory: [PayoutHistoryEntry] = []
    private var payoutSummary: PayoutSummary?
    private var currentFilter: PayoutHistoryFilter = .all
    
    private let distributionService = TeamPrizeDistributionService.shared
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header section
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let summaryButton = UIButton(type: .system)
    
    // Summary section (collapsible)
    private let summaryContainer = UIView()
    private let summaryContentView = UIView()
    private let totalEarningsLabel = UILabel()
    private let totalEarningsValueLabel = UILabel()
    private let payoutCountLabel = UILabel()
    private let averagePayoutLabel = UILabel()
    private let bestPayoutLabel = UILabel()
    private let favoriteTeamLabel = UILabel()
    
    // Filter section
    private let filterContainer = UIView()
    private let filterSegmentedControl = UISegmentedControl(items: [
        "All", "This Month", "This Year", "By Team"
    ])
    private let filterResultsLabel = UILabel()
    
    // History list
    private let historyTableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    
    // Loading and error states
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📜 PayoutHistory: Loading payout history interface")
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupSummarySection()
        setupFilterSection()
        setupHistoryTable()
        setupEmptyState()
        setupLoadingAndError()
        setupConstraints()
        
        loadPayoutHistory()
        
        print("📜 PayoutHistory: Interface loaded successfully")
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add decorative gear
        let gear = RotatingGearView(size: 80)
        gear.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gear)
        
        NSLayoutConstraint.activate([
            gear.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            gear.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 10),
            gear.widthAnchor.constraint(equalToConstant: 80),
            gear.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.95)
        headerView.layer.cornerRadius = 12
        headerView.layer.borderWidth = 1
        headerView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "Payout History"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        summaryButton.setTitle("📊 Summary", for: .normal)
        summaryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        summaryButton.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        summaryButton.addTarget(self, action: #selector(summaryButtonTapped), for: .touchUpInside)
        summaryButton.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(summaryButton)
        contentView.addSubview(headerView)
    }
    
    private func setupSummarySection() {
        summaryContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        summaryContainer.layer.cornerRadius = 12
        summaryContainer.layer.borderWidth = 1
        summaryContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        summaryContainer.isHidden = true // Initially hidden
        summaryContainer.translatesAutoresizingMaskIntoConstraints = false
        
        summaryContentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Total earnings
        totalEarningsLabel.text = "TOTAL EARNINGS"
        totalEarningsLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        totalEarningsLabel.textColor = IndustrialDesign.Colors.secondaryText
        totalEarningsLabel.letterSpacing = 1.0
        totalEarningsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        totalEarningsValueLabel.text = "₿0.00000000"
        totalEarningsValueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        totalEarningsValueLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        totalEarningsValueLabel.adjustsFontSizeToFitWidth = true
        totalEarningsValueLabel.minimumScaleFactor = 0.8
        totalEarningsValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Stats
        payoutCountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        payoutCountLabel.textColor = IndustrialDesign.Colors.primaryText
        payoutCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        averagePayoutLabel.font = UIFont.systemFont(ofSize: 14)
        averagePayoutLabel.textColor = IndustrialDesign.Colors.secondaryText
        averagePayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bestPayoutLabel.font = UIFont.systemFont(ofSize: 14)
        bestPayoutLabel.textColor = IndustrialDesign.Colors.secondaryText
        bestPayoutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        favoriteTeamLabel.font = UIFont.systemFont(ofSize: 14)
        favoriteTeamLabel.textColor = IndustrialDesign.Colors.secondaryText
        favoriteTeamLabel.translatesAutoresizingMaskIntoConstraints = false
        
        summaryContentView.addSubview(totalEarningsLabel)
        summaryContentView.addSubview(totalEarningsValueLabel)
        summaryContentView.addSubview(payoutCountLabel)
        summaryContentView.addSubview(averagePayoutLabel)
        summaryContentView.addSubview(bestPayoutLabel)
        summaryContentView.addSubview(favoriteTeamLabel)
        
        summaryContainer.addSubview(summaryContentView)
        contentView.addSubview(summaryContainer)
    }
    
    private func setupFilterSection() {
        filterContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        filterContainer.layer.cornerRadius = 12
        filterContainer.layer.borderWidth = 1
        filterContainer.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        filterContainer.translatesAutoresizingMaskIntoConstraints = false
        
        filterSegmentedControl.selectedSegmentIndex = 0
        filterSegmentedControl.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        filterSegmentedControl.selectedSegmentTintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        filterSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        filterSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        filterSegmentedControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        filterSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        filterResultsLabel.font = UIFont.systemFont(ofSize: 12)
        filterResultsLabel.textColor = IndustrialDesign.Colors.secondaryText
        filterResultsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        filterContainer.addSubview(filterSegmentedControl)
        filterContainer.addSubview(filterResultsLabel)
        contentView.addSubview(filterContainer)
    }
    
    private func setupHistoryTable() {
        historyTableView.backgroundColor = .clear
        historyTableView.separatorStyle = .none
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.register(PayoutHistoryCell.self, forCellReuseIdentifier: "PayoutHistoryCell")
        historyTableView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(historyTableView)
    }
    
    private func setupEmptyState() {
        emptyStateView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        emptyStateView.layer.cornerRadius = 12
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateLabel.text = "No payout history yet\n\nStart participating in team events to earn Bitcoin rewards!"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        contentView.addSubview(emptyStateView)
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
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: spacing),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: spacing),
            
            summaryButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            summaryButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -spacing),
            
            // Summary section
            summaryContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: spacing),
            summaryContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            summaryContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            summaryContainer.heightAnchor.constraint(equalToConstant: 180),
            
            summaryContentView.topAnchor.constraint(equalTo: summaryContainer.topAnchor, constant: spacing),
            summaryContentView.leadingAnchor.constraint(equalTo: summaryContainer.leadingAnchor, constant: spacing),
            summaryContentView.trailingAnchor.constraint(equalTo: summaryContainer.trailingAnchor, constant: -spacing),
            summaryContentView.bottomAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: -spacing),
            
            totalEarningsLabel.topAnchor.constraint(equalTo: summaryContentView.topAnchor),
            totalEarningsLabel.leadingAnchor.constraint(equalTo: summaryContentView.leadingAnchor),
            
            totalEarningsValueLabel.topAnchor.constraint(equalTo: totalEarningsLabel.bottomAnchor, constant: 8),
            totalEarningsValueLabel.leadingAnchor.constraint(equalTo: summaryContentView.leadingAnchor),
            totalEarningsValueLabel.trailingAnchor.constraint(equalTo: summaryContentView.trailingAnchor),
            
            payoutCountLabel.topAnchor.constraint(equalTo: totalEarningsValueLabel.bottomAnchor, constant: 16),
            payoutCountLabel.leadingAnchor.constraint(equalTo: summaryContentView.leadingAnchor),
            
            averagePayoutLabel.topAnchor.constraint(equalTo: payoutCountLabel.bottomAnchor, constant: 4),
            averagePayoutLabel.leadingAnchor.constraint(equalTo: summaryContentView.leadingAnchor),
            
            bestPayoutLabel.centerYAnchor.constraint(equalTo: payoutCountLabel.centerYAnchor),
            bestPayoutLabel.trailingAnchor.constraint(equalTo: summaryContentView.trailingAnchor),
            
            favoriteTeamLabel.centerYAnchor.constraint(equalTo: averagePayoutLabel.centerYAnchor),
            favoriteTeamLabel.trailingAnchor.constraint(equalTo: summaryContentView.trailingAnchor),
            
            // Filter section
            filterContainer.topAnchor.constraint(equalTo: summaryContainer.bottomAnchor, constant: spacing),
            filterContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            filterContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            filterContainer.heightAnchor.constraint(equalToConstant: 80),
            
            filterSegmentedControl.topAnchor.constraint(equalTo: filterContainer.topAnchor, constant: spacing),
            filterSegmentedControl.leadingAnchor.constraint(equalTo: filterContainer.leadingAnchor, constant: spacing),
            filterSegmentedControl.trailingAnchor.constraint(equalTo: filterContainer.trailingAnchor, constant: -spacing),
            filterSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            filterResultsLabel.topAnchor.constraint(equalTo: filterSegmentedControl.bottomAnchor, constant: 8),
            filterResultsLabel.centerXAnchor.constraint(equalTo: filterContainer.centerXAnchor),
            
            // History table
            historyTableView.topAnchor.constraint(equalTo: filterContainer.bottomAnchor, constant: spacing),
            historyTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: spacing),
            historyTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -spacing),
            historyTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -spacing),
            historyTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: historyTableView.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: historyTableView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: historyTableView.widthAnchor, multiplier: 0.8),
            emptyStateView.heightAnchor.constraint(equalToConstant: 120),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            
            // Loading and error
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadPayoutHistory() {
        showLoadingState()
        
        // Simulate loading payout history
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.payoutHistory = self.createMockPayoutHistory()
            self.payoutSummary = self.calculateSummary()
            self.applyCurrentFilter()
            self.updateSummaryDisplay()
            self.hideLoadingState()
        }
    }
    
    private func createMockPayoutHistory() -> [PayoutHistoryEntry] {
        let currentDate = Date()
        
        return [
            PayoutHistoryEntry(
                payoutId: "payout_1",
                eventId: "event_1",
                eventName: "November Marathon Challenge",
                teamId: "team_1",
                teamName: "Lightning Runners",
                amount: 5000, // 5000 sats
                distributionMethod: .performance,
                payoutDate: currentDate.addingTimeInterval(-7 * 24 * 3600),
                status: .completed,
                rank: 3,
                totalParticipants: 25,
                notes: "Top 3 finish - great performance!",
                transactionId: "tx_abc123"
            ),
            PayoutHistoryEntry(
                payoutId: "payout_2",
                eventId: "event_2",
                eventName: "Halloween Sprint Week",
                teamId: "team_1",
                teamName: "Lightning Runners",
                amount: 2500,
                distributionMethod: .equal,
                payoutDate: currentDate.addingTimeInterval(-14 * 24 * 3600),
                status: .completed,
                rank: nil,
                totalParticipants: 15,
                notes: "Equal distribution among all participants",
                transactionId: "tx_def456"
            ),
            PayoutHistoryEntry(
                payoutId: "payout_3",
                eventId: "event_3",
                eventName: "October Distance Challenge",
                teamId: "team_2",
                teamName: "Crypto Cyclists",
                amount: 7500,
                distributionMethod: .topPerformers,
                payoutDate: currentDate.addingTimeInterval(-30 * 24 * 3600),
                status: .completed,
                rank: 1,
                totalParticipants: 40,
                notes: "First place winner! 🏆",
                transactionId: "tx_ghi789"
            ),
            PayoutHistoryEntry(
                payoutId: "payout_4",
                eventId: "event_4",
                eventName: "September Strength Challenge",
                teamId: "team_2",
                teamName: "Crypto Cyclists",
                amount: 1000,
                distributionMethod: .hybrid,
                payoutDate: currentDate.addingTimeInterval(-60 * 24 * 3600),
                status: .completed,
                rank: 8,
                totalParticipants: 20,
                notes: "Hybrid distribution method",
                transactionId: "tx_jkl012"
            ),
            PayoutHistoryEntry(
                payoutId: "payout_5",
                eventId: "event_5",
                eventName: "August Summer Series",
                teamId: "team_1",
                teamName: "Lightning Runners",
                amount: 3000,
                distributionMethod: .performance,
                payoutDate: currentDate.addingTimeInterval(-90 * 24 * 3600),
                status: .completed,
                rank: 5,
                totalParticipants: 30,
                notes: "Solid mid-pack finish",
                transactionId: "tx_mno345"
            )
        ]
    }
    
    private func calculateSummary() -> PayoutSummary {
        let totalEarnings = payoutHistory.reduce(0) { $0 + $1.amount }
        let payoutCount = payoutHistory.count
        let averagePayout = payoutCount > 0 ? totalEarnings / Double(payoutCount) : 0
        let bestPayout = payoutHistory.map { $0.amount }.max() ?? 0
        let lastPayoutDate = payoutHistory.max(by: { $0.payoutDate < $1.payoutDate })?.payoutDate
        
        // Find most common team
        let teamCounts = Dictionary(grouping: payoutHistory, by: { $0.teamId })
        let favoriteTeam = teamCounts.max(by: { $0.value.count < $1.value.count })?.value.first?.teamName
        
        let totalEvents = Set(payoutHistory.map { $0.eventId }).count
        
        return PayoutSummary(
            totalEarnings: totalEarnings,
            payoutCount: payoutCount,
            averagePayout: averagePayout,
            bestPayout: bestPayout,
            lastPayoutDate: lastPayoutDate,
            favoriteTeam: favoriteTeam,
            totalEvents: totalEvents
        )
    }
    
    // MARK: - Filtering
    
    private func applyCurrentFilter() {
        switch currentFilter {
        case .all:
            filteredHistory = payoutHistory
            filterResultsLabel.text = "Showing \(filteredHistory.count) payouts"
            
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filteredHistory = payoutHistory.filter { $0.payoutDate >= monthAgo }
            filterResultsLabel.text = "Showing \(filteredHistory.count) payouts this month"
            
        case .thisYear:
            let yearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            filteredHistory = payoutHistory.filter { $0.payoutDate >= yearAgo }
            filterResultsLabel.text = "Showing \(filteredHistory.count) payouts this year"
            
        case .byTeam(let teamId):
            filteredHistory = payoutHistory.filter { $0.teamId == teamId }
            filterResultsLabel.text = "Showing \(filteredHistory.count) payouts for team"
            
        case .byAmount(let min, let max):
            filteredHistory = payoutHistory.filter { $0.amount >= min && $0.amount <= max }
            filterResultsLabel.text = "Showing \(filteredHistory.count) payouts in range"
        }
        
        // Sort by date (newest first)
        filteredHistory.sort { $0.payoutDate > $1.payoutDate }
        
        updateTableDisplay()
    }
    
    private func updateTableDisplay() {
        if filteredHistory.isEmpty {
            historyTableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            historyTableView.isHidden = false
            emptyStateView.isHidden = true
            historyTableView.reloadData()
        }
    }
    
    // MARK: - UI Updates
    
    private func updateSummaryDisplay() {
        guard let summary = payoutSummary else { return }
        
        // Total earnings
        let totalBtc = summary.totalEarnings / 100_000_000.0
        totalEarningsValueLabel.text = "₿\(String(format: "%.8f", totalBtc))"
        
        // Stats
        payoutCountLabel.text = "Total Payouts: \(summary.payoutCount)"
        
        let avgBtc = summary.averagePayout / 100_000_000.0
        averagePayoutLabel.text = "Average: ₿\(String(format: "%.6f", avgBtc))"
        
        let bestBtc = summary.bestPayout / 100_000_000.0
        bestPayoutLabel.text = "Best: ₿\(String(format: "%.6f", bestBtc))"
        
        favoriteTeamLabel.text = summary.favoriteTeam ?? "No favorite team"
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
    
    // MARK: - Actions
    
    @objc private func summaryButtonTapped() {
        let isHidden = summaryContainer.isHidden
        
        UIView.animate(withDuration: 0.3) {
            self.summaryContainer.isHidden = !isHidden
            self.summaryButton.setTitle(isHidden ? "📊 Hide" : "📊 Summary", for: .normal)
        }
        
        print("📜 PayoutHistory: Summary toggled: \(isHidden ? "shown" : "hidden")")
    }
    
    @objc private func filterChanged() {
        switch filterSegmentedControl.selectedSegmentIndex {
        case 0:
            currentFilter = .all
        case 1:
            currentFilter = .thisMonth
        case 2:
            currentFilter = .thisYear
        case 3:
            showTeamFilterOptions()
        default:
            currentFilter = .all
        }
        
        applyCurrentFilter()
        print("📜 PayoutHistory: Filter changed to: \(currentFilter)")
    }
    
    private func showTeamFilterOptions() {
        // Create unique teams using dictionary to deduplicate
        var uniqueTeams: [String: String] = [:]
        for payout in payoutHistory {
            uniqueTeams[payout.teamId] = payout.teamName
        }
        
        let alert = UIAlertController(title: "Filter by Team", message: "Select a team to filter by", preferredStyle: .actionSheet)
        
        for (teamId, teamName) in uniqueTeams {
            alert.addAction(UIAlertAction(title: teamName, style: .default) { _ in
                self.currentFilter = .byTeam(teamId)
                self.applyCurrentFilter()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.filterSegmentedControl.selectedSegmentIndex = 0
            self.currentFilter = .all
            self.applyCurrentFilter()
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MemberPayoutHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PayoutHistoryCell", for: indexPath) as? PayoutHistoryCell else {
            return UITableViewCell()
        }
        
        let payout = filteredHistory[indexPath.row]
        cell.configure(with: payout)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let payout = filteredHistory[indexPath.row]
        showPayoutDetails(payout: payout)
    }
    
    private func showPayoutDetails(payout: PayoutHistoryEntry) {
        let amountBtc = payout.amount / 100_000_000.0
        var message = "Event: \(payout.eventName)\nTeam: \(payout.teamName)\nAmount: ₿\(String(format: "%.8f", amountBtc))\nMethod: \(payout.distributionMethod.displayName)\n"
        
        if let rank = payout.rank, let total = payout.totalParticipants {
            message += "Rank: #\(rank) of \(total)\n"
        }
        
        if let notes = payout.notes {
            message += "Notes: \(notes)\n"
        }
        
        if let txId = payout.transactionId {
            message += "Transaction: \(txId)"
        }
        
        let alert = UIAlertController(title: "Payout Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        
        present(alert, animated: true)
    }
}

// MARK: - PayoutHistoryCell

class PayoutHistoryCell: UITableViewCell {
    
    private let containerView = UIView()
    private let eventNameLabel = UILabel()
    private let teamNameLabel = UILabel()
    private let amountLabel = UILabel()
    private let dateLabel = UILabel()
    private let methodLabel = UILabel()
    private let rankLabel = UILabel()
    private let statusIndicator = UIView()
    
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
        
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        containerView.layer.cornerRadius = 10
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        eventNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        eventNameLabel.textColor = IndustrialDesign.Colors.primaryText
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamNameLabel.font = UIFont.systemFont(ofSize: 14)
        teamNameLabel.textColor = IndustrialDesign.Colors.secondaryText
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        amountLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        amountLabel.textAlignment = .right
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        methodLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        methodLabel.textColor = IndustrialDesign.Colors.accentText
        methodLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rankLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        rankLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusIndicator.backgroundColor = UIColor.systemGreen
        statusIndicator.layer.cornerRadius = 3
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(eventNameLabel)
        containerView.addSubview(teamNameLabel)
        containerView.addSubview(amountLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(methodLabel)
        containerView.addSubview(rankLabel)
        containerView.addSubview(statusIndicator)
        
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            statusIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusIndicator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            statusIndicator.widthAnchor.constraint(equalToConstant: 6),
            statusIndicator.heightAnchor.constraint(equalToConstant: 6),
            
            eventNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            eventNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            eventNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),
            
            teamNameLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 2),
            teamNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            
            methodLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            methodLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            
            rankLabel.centerYAnchor.constraint(equalTo: methodLabel.centerYAnchor),
            rankLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 8),
            
            amountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            amountLabel.trailingAnchor.constraint(equalTo: statusIndicator.leadingAnchor, constant: -8),
            amountLabel.widthAnchor.constraint(equalToConstant: 100),
            
            dateLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 2),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dateLabel.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    func configure(with payout: PayoutHistoryEntry) {
        eventNameLabel.text = payout.eventName
        teamNameLabel.text = payout.teamName
        
        let amountBtc = payout.amount / 100_000_000.0
        amountLabel.text = "₿\(String(format: "%.6f", amountBtc))"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: payout.payoutDate)
        
        methodLabel.text = payout.distributionMethod.displayName.uppercased()
        
        if let rank = payout.rank, let total = payout.totalParticipants {
            rankLabel.text = "#\(rank)/\(total)"
        } else {
            rankLabel.text = ""
        }
        
        statusIndicator.backgroundColor = payout.status == .completed ? UIColor.systemGreen : UIColor.systemOrange
    }
}