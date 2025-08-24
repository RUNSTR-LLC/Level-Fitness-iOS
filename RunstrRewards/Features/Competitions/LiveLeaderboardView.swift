import UIKit
import Combine

class LiveLeaderboardView: UIView {
    
    // MARK: - UI Components
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let lastUpdatedLabel = UILabel()
    private let refreshButton = UIButton(type: .system)
    private let connectionStatusIndicator = UIView()
    
    // Leaderboard content
    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    
    // Live update indicator
    private let liveIndicator = UIView()
    private let liveLabel = UILabel()
    private let pulseAnimation = UIView()
    
    // Properties
    private var eventId: String?
    private var leaderboardEntries: [EventLeaderboardEntry] = []
    private var cancellables = Set<AnyCancellable>()
    private let realtimeService = RealtimeLeaderboardService.shared
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        observeRealtimeUpdates()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        observeRealtimeUpdates()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.95)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        
        setupHeaderView()
        setupTableView()
        setupEmptyState()
        setupLiveIndicator()
    }
    
    private func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.text = "Live Leaderboard"
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Last updated
        lastUpdatedLabel.font = UIFont.systemFont(ofSize: 12)
        lastUpdatedLabel.textColor = IndustrialDesign.Colors.secondaryText
        lastUpdatedLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Refresh button
        refreshButton.setTitle("⟳", for: .normal)
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        refreshButton.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Connection status
        connectionStatusIndicator.backgroundColor = UIColor.systemGreen
        connectionStatusIndicator.layer.cornerRadius = 4
        connectionStatusIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(lastUpdatedLabel)
        headerView.addSubview(refreshButton)
        headerView.addSubview(connectionStatusIndicator)
        addSubview(headerView)
    }
    
    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: "LeaderboardCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tableView)
    }
    
    private func setupEmptyState() {
        emptyStateView.backgroundColor = .clear
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateLabel.text = "No participants yet\nBe the first to join!"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        addSubview(emptyStateView)
    }
    
    private func setupLiveIndicator() {
        liveIndicator.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.9)
        liveIndicator.layer.cornerRadius = 12
        liveIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Live label
        liveLabel.text = "● LIVE"
        liveLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        liveLabel.textColor = UIColor.systemRed
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Pulse animation view
        pulseAnimation.backgroundColor = UIColor.systemRed
        pulseAnimation.layer.cornerRadius = 4
        pulseAnimation.alpha = 0.7
        pulseAnimation.translatesAutoresizingMaskIntoConstraints = false
        
        liveIndicator.addSubview(pulseAnimation)
        liveIndicator.addSubview(liveLabel)
        addSubview(liveIndicator)
        
        startPulseAnimation()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            lastUpdatedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            lastUpdatedLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            refreshButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            refreshButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.heightAnchor.constraint(equalToConstant: 30),
            
            connectionStatusIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            connectionStatusIndicator.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -12),
            connectionStatusIndicator.widthAnchor.constraint(equalToConstant: 8),
            connectionStatusIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8),
            emptyStateView.heightAnchor.constraint(equalToConstant: 100),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            
            // Live indicator
            liveIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            liveIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            liveIndicator.widthAnchor.constraint(equalToConstant: 60),
            liveIndicator.heightAnchor.constraint(equalToConstant: 24),
            
            pulseAnimation.leadingAnchor.constraint(equalTo: liveIndicator.leadingAnchor, constant: 8),
            pulseAnimation.centerYAnchor.constraint(equalTo: liveIndicator.centerYAnchor),
            pulseAnimation.widthAnchor.constraint(equalToConstant: 8),
            pulseAnimation.heightAnchor.constraint(equalToConstant: 8),
            
            liveLabel.leadingAnchor.constraint(equalTo: pulseAnimation.trailingAnchor, constant: 6),
            liveLabel.centerYAnchor.constraint(equalTo: liveIndicator.centerYAnchor)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(eventId: String, eventData: EventData) {
        self.eventId = eventId
        titleLabel.text = "\(eventData.name) - Leaderboard"
        
        // Start real-time updates
        realtimeService.startLiveTracking(for: eventData)
        
        // Load initial data
        loadLeaderboardData()
        
        print("🔴 LiveLeaderboard: Configured for event: \(eventData.name)")
    }
    
    func stopLiveUpdates() {
        guard let eventId = eventId else { return }
        
        // Stop real-time service
        if let eventData = getCurrentEventData(eventId: eventId) {
            realtimeService.stopLiveTracking(for: eventData)
        }
        
        // Hide live indicator
        liveIndicator.isHidden = true
        
        print("🔴 LiveLeaderboard: Stopped live updates")
    }
    
    // MARK: - Data Loading
    
    private func loadLeaderboardData() {
        guard let eventId = eventId else { return }
        
        // Get leaderboard from EventProgressTracker
        let entries = EventProgressTracker.shared.getLeaderboard(eventId: eventId)
        
        DispatchQueue.main.async {
            self.leaderboardEntries = entries
            self.updateUI()
            self.updateLastUpdatedLabel()
        }
    }
    
    private func updateUI() {
        if leaderboardEntries.isEmpty {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        } else {
            tableView.isHidden = false
            emptyStateView.isHidden = true
            
            // Animate table reload for smooth updates
            UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.tableView.reloadData()
            })
        }
    }
    
    private func updateLastUpdatedLabel() {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        lastUpdatedLabel.text = "Updated: \(formatter.string(from: Date()))"
    }
    
    // MARK: - Real-time Updates
    
    private func observeRealtimeUpdates() {
        // Observe connection status changes
        realtimeService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateConnectionStatus(status)
            }
            .store(in: &cancellables)
        
        // Listen for leaderboard updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRealtimeUpdate),
            name: NSNotification.Name("RealtimeLeaderboardUpdate"),
            object: nil
        )
    }
    
    @objc private func handleRealtimeUpdate(_ notification: Notification) {
        guard let update = notification.userInfo?["update"] as? LiveLeaderboardUpdate,
              update.eventId == eventId else {
            return
        }
        
        DispatchQueue.main.async {
            // Convert LeaderboardEntry to EventLeaderboardEntry
            self.leaderboardEntries = update.affectedEntries.map { entry in
                EventLeaderboardEntry(
                    userId: entry.userId,
                    username: entry.username,
                    totalValue: Double(entry.points), // Use points as totalValue
                    rank: entry.rank,
                    points: entry.points,
                    lastActivity: Date(), // Use current time as default
                    isCurrentUser: false, // This would need real user identification
                    badgeCount: 0 // Default badge count
                )
            }
            self.updateUI()
            self.updateLastUpdatedLabel()
            self.showUpdateAnimation(for: update.updateType)
        }
        
        print("🔴 LiveLeaderboard: Received real-time update: \(update.updateType)")
    }
    
    private func updateConnectionStatus(_ status: ConnectionStatus) {
        switch status {
        case .connected:
            connectionStatusIndicator.backgroundColor = UIColor.systemGreen
            liveIndicator.isHidden = false
        case .connecting:
            connectionStatusIndicator.backgroundColor = UIColor.systemOrange
            liveIndicator.isHidden = false
        case .disconnected:
            connectionStatusIndicator.backgroundColor = UIColor.systemRed
            liveIndicator.isHidden = true
        case .error:
            connectionStatusIndicator.backgroundColor = UIColor.systemRed
            liveIndicator.isHidden = true
        }
    }
    
    // MARK: - Animations
    
    private func startPulseAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
            self.pulseAnimation.alpha = 0.3
        })
    }
    
    private func showUpdateAnimation(for updateType: LeaderboardUpdateType) {
        switch updateType {
        case .positionChange:
            // Flash the leaderboard briefly
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.alpha = 0.7
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.tableView.alpha = 1.0
                }
            }
            
        case .newEntry, .userJoined:
            // Bounce animation
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
                self.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.transform = .identity
                }
            }
            
        case .eventComplete:
            // Celebration animation
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1.0, options: [], animations: {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    @objc private func refreshTapped() {
        // Animate refresh button
        UIView.animate(withDuration: 0.3, animations: {
            self.refreshButton.transform = CGAffineTransform(rotationAngle: .pi)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.refreshButton.transform = .identity
            }
        }
        
        // Force update from real-time service
        if let eventId = eventId {
            realtimeService.forceUpdate(for: eventId)
        }
        
        print("🔴 LiveLeaderboard: Manual refresh triggered")
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentEventData(eventId: String) -> EventData? {
        // In a real implementation, this would fetch from a data service
        // For now, return a mock EventData
        return EventData(
            id: eventId,
            name: "Current Event",
            type: .challenge,
            status: .active,
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 3600),
            participants: leaderboardEntries.count,
            prizePool: 5000,
            entryFee: 100
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopLiveUpdates()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension LiveLeaderboardView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return leaderboardEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as? LeaderboardCell else {
            return UITableViewCell()
        }
        
        let entry = leaderboardEntries[indexPath.row]
        cell.configure(with: entry, isLive: true)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let entry = leaderboardEntries[indexPath.row]
        
        // Show user profile or detailed stats
        showUserDetails(for: entry)
    }
    
    private func showUserDetails(for entry: EventLeaderboardEntry) {
        // In a real implementation, this would show user profile
        print("🔴 LiveLeaderboard: Show details for user: \(entry.username)")
        
        // For now, just animate the selection
        if let cell = tableView.cellForRow(at: IndexPath(row: entry.rank - 1, section: 0)) {
            UIView.animate(withDuration: 0.15, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.15) {
                    cell.transform = .identity
                }
            }
        }
    }
}

// MARK: - LeaderboardCell

class LeaderboardCell: UITableViewCell {
    
    private let rankLabel = UILabel()
    private let usernameLabel = UILabel()
    private let scoreLabel = UILabel()
    private let pointsLabel = UILabel()
    private let badgeCountLabel = UILabel()
    private let lastActivityLabel = UILabel()
    private let currentUserIndicator = UIView()
    private let liveUpdateIndicator = UIView()
    
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
        
        // Rank label
        rankLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        rankLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        rankLabel.textAlignment = .center
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Username label
        usernameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Score label
        scoreLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        scoreLabel.textColor = IndustrialDesign.Colors.primaryText
        scoreLabel.textAlignment = .right
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Points label
        pointsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        pointsLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        pointsLabel.textAlignment = .right
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Badge count label
        badgeCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        badgeCountLabel.textColor = .white
        badgeCountLabel.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        badgeCountLabel.textAlignment = .center
        badgeCountLabel.layer.cornerRadius = 8
        badgeCountLabel.layer.masksToBounds = true
        badgeCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Last activity label
        lastActivityLabel.font = UIFont.systemFont(ofSize: 10)
        lastActivityLabel.textColor = IndustrialDesign.Colors.secondaryText
        lastActivityLabel.textAlignment = .right
        lastActivityLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Current user indicator
        currentUserIndicator.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        currentUserIndicator.layer.cornerRadius = 2
        currentUserIndicator.isHidden = true
        currentUserIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Live update indicator
        liveUpdateIndicator.backgroundColor = UIColor.systemGreen
        liveUpdateIndicator.layer.cornerRadius = 3
        liveUpdateIndicator.isHidden = true
        liveUpdateIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(rankLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(scoreLabel)
        contentView.addSubview(pointsLabel)
        contentView.addSubview(badgeCountLabel)
        contentView.addSubview(lastActivityLabel)
        contentView.addSubview(currentUserIndicator)
        contentView.addSubview(liveUpdateIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Rank label
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 40),
            
            // Current user indicator
            currentUserIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            currentUserIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentUserIndicator.widthAnchor.constraint(equalToConstant: 4),
            currentUserIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            // Username label
            usernameLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 16),
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            
            // Badge count
            badgeCountLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            badgeCountLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            badgeCountLabel.widthAnchor.constraint(equalToConstant: 20),
            badgeCountLabel.heightAnchor.constraint(equalToConstant: 16),
            
            // Score label
            scoreLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scoreLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            scoreLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // Points label
            pointsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pointsLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 2),
            pointsLabel.widthAnchor.constraint(equalToConstant: 80),
            
            // Last activity label
            lastActivityLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 16),
            lastActivityLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            
            // Live update indicator
            liveUpdateIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            liveUpdateIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            liveUpdateIndicator.widthAnchor.constraint(equalToConstant: 6),
            liveUpdateIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func configure(with entry: EventLeaderboardEntry, isLive: Bool = false) {
        rankLabel.text = "#\(entry.rank)"
        usernameLabel.text = entry.username
        scoreLabel.text = formatScore(entry.totalValue)
        pointsLabel.text = "\(entry.points) pts"
        badgeCountLabel.text = "\(entry.badgeCount)"
        
        // Format last activity time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        lastActivityLabel.text = formatter.localizedString(for: entry.lastActivity, relativeTo: Date())
        
        // Show current user indicator
        currentUserIndicator.isHidden = !entry.isCurrentUser
        
        // Show live update indicator
        liveUpdateIndicator.isHidden = !isLive
        
        // Add special styling for top 3
        if entry.rank <= 3 {
            let colors: [UIColor] = [
                UIColor.systemYellow,    // 1st place - Gold
                UIColor.systemGray,      // 2nd place - Silver  
                UIColor.systemBrown      // 3rd place - Bronze
            ]
            rankLabel.textColor = colors[entry.rank - 1]
            usernameLabel.textColor = colors[entry.rank - 1]
        } else {
            rankLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
            usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        }
        
        // Hide badge count if zero
        badgeCountLabel.isHidden = entry.badgeCount == 0
    }
    
    private func formatScore(_ score: Double) -> String {
        if score >= 1000 {
            return "\(String(format: "%.1f", score / 1000))km"
        } else {
            return "\(Int(score))m"
        }
    }
}