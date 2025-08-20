import UIKit
import HealthKit

class EventProgressView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let headerView = UIView()
    private let eventTitleLabel = UILabel()
    private let timeRemainingLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    
    // Progress section
    private let progressSection = UIView()
    private let progressTitleLabel = UILabel()
    private let progressBar = UIView()
    private let progressFill = UIView()
    private let progressPercentageLabel = UILabel()
    private let currentValueLabel = UILabel()
    private let targetValueLabel = UILabel()
    
    // Ranking section
    private let rankingSection = UIView()
    private let rankTitleLabel = UILabel()
    private let rankNumberLabel = UILabel()
    private let rankChangeIndicator = UIImageView()
    private let totalParticipantsLabel = UILabel()
    
    // Recent activity section
    private let activitySection = UIView()
    private let activityTitleLabel = UILabel()
    private let activityTableView = UITableView()
    
    // Achievement indicators
    private let achievementContainer = UIView()
    private var achievementBadges: [UIView] = []
    
    // MARK: - Properties
    private var eventProgress: EventProgress?
    private var recentActivities: [ProgressWorkout] = []
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        observeProgressUpdates()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        observeProgressUpdates()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Container view
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        setupHeaderSection()
        setupProgressSection()
        setupRankingSection()
        setupActivitySection()
        setupAchievementSection()
        
        addSubview(containerView)
    }
    
    private func setupHeaderSection() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Event title
        eventTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        eventTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        eventTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Time remaining
        timeRemainingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeRemainingLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Status badge
        statusBadge.layer.cornerRadius = 10
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statusBadge.addSubview(statusLabel)
        headerView.addSubview(eventTitleLabel)
        headerView.addSubview(timeRemainingLabel)
        headerView.addSubview(statusBadge)
        containerView.addSubview(headerView)
    }
    
    private func setupProgressSection() {
        progressSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress title
        progressTitleLabel.text = "Your Progress"
        progressTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        progressTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        progressTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress bar
        progressBar.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        progressBar.layer.cornerRadius = 8
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        
        progressFill.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        progressFill.layer.cornerRadius = 8
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress labels
        progressPercentageLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        progressPercentageLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        progressPercentageLabel.textAlignment = .center
        progressPercentageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        currentValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        currentValueLabel.textColor = IndustrialDesign.Colors.primaryText
        currentValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        targetValueLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        targetValueLabel.textColor = IndustrialDesign.Colors.secondaryText
        targetValueLabel.textAlignment = .right
        targetValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        progressBar.addSubview(progressFill)
        progressSection.addSubview(progressTitleLabel)
        progressSection.addSubview(progressBar)
        progressSection.addSubview(progressPercentageLabel)
        progressSection.addSubview(currentValueLabel)
        progressSection.addSubview(targetValueLabel)
        containerView.addSubview(progressSection)
    }
    
    private func setupRankingSection() {
        rankingSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Rank title
        rankTitleLabel.text = "Current Ranking"
        rankTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        rankTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        rankTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Rank number
        rankNumberLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        rankNumberLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        rankNumberLabel.textAlignment = .center
        rankNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Rank change indicator
        rankChangeIndicator.contentMode = .scaleAspectFit
        rankChangeIndicator.tintColor = UIColor.systemGreen
        rankChangeIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Total participants
        totalParticipantsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        totalParticipantsLabel.textColor = IndustrialDesign.Colors.secondaryText
        totalParticipantsLabel.textAlignment = .center
        totalParticipantsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rankingSection.addSubview(rankTitleLabel)
        rankingSection.addSubview(rankNumberLabel)
        rankingSection.addSubview(rankChangeIndicator)
        rankingSection.addSubview(totalParticipantsLabel)
        containerView.addSubview(rankingSection)
    }
    
    private func setupActivitySection() {
        activitySection.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity title
        activityTitleLabel.text = "Recent Activity"
        activityTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        activityTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        activityTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Activity table view
        activityTableView.backgroundColor = .clear
        activityTableView.separatorStyle = .none
        activityTableView.isScrollEnabled = false
        activityTableView.delegate = self
        activityTableView.dataSource = self
        activityTableView.register(ActivityCell.self, forCellReuseIdentifier: "ActivityCell")
        activityTableView.translatesAutoresizingMaskIntoConstraints = false
        
        activitySection.addSubview(activityTitleLabel)
        activitySection.addSubview(activityTableView)
        containerView.addSubview(activitySection)
    }
    
    private func setupAchievementSection() {
        achievementContainer.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(achievementContainer)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header section
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            eventTitleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            eventTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            eventTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -12),
            
            timeRemainingLabel.topAnchor.constraint(equalTo: eventTitleLabel.bottomAnchor, constant: 4),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            
            statusBadge.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            statusBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            statusBadge.widthAnchor.constraint(equalToConstant: 80),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            
            // Progress section
            progressSection.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            progressSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            progressSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            progressSection.heightAnchor.constraint(equalToConstant: 120),
            
            progressTitleLabel.topAnchor.constraint(equalTo: progressSection.topAnchor),
            progressTitleLabel.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
            
            progressPercentageLabel.topAnchor.constraint(equalTo: progressTitleLabel.bottomAnchor, constant: 8),
            progressPercentageLabel.centerXAnchor.constraint(equalTo: progressSection.centerXAnchor),
            
            progressBar.topAnchor.constraint(equalTo: progressPercentageLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 16),
            
            progressFill.topAnchor.constraint(equalTo: progressBar.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressBar.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressBar.bottomAnchor),
            progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: 0.0), // Will be updated dynamically
            
            currentValueLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            currentValueLabel.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
            
            targetValueLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            targetValueLabel.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
            
            // Ranking section
            rankingSection.topAnchor.constraint(equalTo: progressSection.bottomAnchor, constant: 20),
            rankingSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            rankingSection.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.4),
            rankingSection.heightAnchor.constraint(equalToConstant: 100),
            
            rankTitleLabel.topAnchor.constraint(equalTo: rankingSection.topAnchor),
            rankTitleLabel.centerXAnchor.constraint(equalTo: rankingSection.centerXAnchor),
            
            rankNumberLabel.topAnchor.constraint(equalTo: rankTitleLabel.bottomAnchor, constant: 8),
            rankNumberLabel.centerXAnchor.constraint(equalTo: rankingSection.centerXAnchor),
            
            rankChangeIndicator.centerYAnchor.constraint(equalTo: rankNumberLabel.centerYAnchor),
            rankChangeIndicator.leadingAnchor.constraint(equalTo: rankNumberLabel.trailingAnchor, constant: 8),
            rankChangeIndicator.widthAnchor.constraint(equalToConstant: 16),
            rankChangeIndicator.heightAnchor.constraint(equalToConstant: 16),
            
            totalParticipantsLabel.topAnchor.constraint(equalTo: rankNumberLabel.bottomAnchor, constant: 4),
            totalParticipantsLabel.centerXAnchor.constraint(equalTo: rankingSection.centerXAnchor),
            
            // Activity section
            activitySection.topAnchor.constraint(equalTo: progressSection.bottomAnchor, constant: 20),
            activitySection.leadingAnchor.constraint(equalTo: rankingSection.trailingAnchor, constant: 16),
            activitySection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            activitySection.heightAnchor.constraint(equalToConstant: 120),
            
            activityTitleLabel.topAnchor.constraint(equalTo: activitySection.topAnchor),
            activityTitleLabel.leadingAnchor.constraint(equalTo: activitySection.leadingAnchor),
            
            activityTableView.topAnchor.constraint(equalTo: activityTitleLabel.bottomAnchor, constant: 8),
            activityTableView.leadingAnchor.constraint(equalTo: activitySection.leadingAnchor),
            activityTableView.trailingAnchor.constraint(equalTo: activitySection.trailingAnchor),
            activityTableView.bottomAnchor.constraint(equalTo: activitySection.bottomAnchor),
            
            // Achievement section
            achievementContainer.topAnchor.constraint(equalTo: rankingSection.bottomAnchor, constant: 20),
            achievementContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            achievementContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            achievementContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            achievementContainer.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Data Updates
    
    func configure(with progress: EventProgress, eventData: EventData) {
        self.eventProgress = progress
        self.recentActivities = Array(progress.recentWorkouts.prefix(3)) // Show last 3 activities
        
        // Update header
        eventTitleLabel.text = eventData.name
        updateTimeRemaining(endDate: eventData.endDate)
        updateStatus(status: eventData.status)
        
        // Update progress
        updateProgressDisplay(progress: progress)
        
        // Update ranking
        updateRankingDisplay(progress: progress)
        
        // Update activity
        activityTableView.reloadData()
        
        // Update achievements
        updateAchievements(progress: progress)
        
        print("📊 ProgressView: Configured with progress: \(String(format: "%.1f", progress.progressPercentage * 100))%")
    }
    
    private func updateTimeRemaining(endDate: Date) {
        let now = Date()
        let timeInterval = endDate.timeIntervalSince(now)
        
        if timeInterval > 0 {
            let days = Int(timeInterval) / 86400
            let hours = (Int(timeInterval) % 86400) / 3600
            
            if days > 0 {
                timeRemainingLabel.text = "\(days)d \(hours)h remaining"
            } else {
                let minutes = (Int(timeInterval) % 3600) / 60
                timeRemainingLabel.text = "\(hours)h \(minutes)m remaining"
            }
        } else {
            timeRemainingLabel.text = "Event ended"
        }
    }
    
    private func updateStatus(status: EventStatus) {
        statusLabel.text = status.displayName
        statusBadge.backgroundColor = status.color
    }
    
    private func updateProgressDisplay(progress: EventProgress) {
        let percentage = progress.progressPercentage * 100
        progressPercentageLabel.text = "\(Int(percentage))%"
        
        // Format values based on type (distance, calories, etc.)
        currentValueLabel.text = formatValue(progress.currentValue, label: "Current")
        targetValueLabel.text = formatValue(progress.targetValue, label: "Target")
        
        // Animate progress bar fill
        progressFill.widthAnchor.constraint(equalTo: progressBar.widthAnchor, multiplier: progress.progressPercentage).isActive = true
        
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseOut], animations: {
            self.layoutIfNeeded()
        })
    }
    
    private func updateRankingDisplay(progress: EventProgress) {
        rankNumberLabel.text = "#\(progress.rank)"
        totalParticipantsLabel.text = "of \(progress.totalParticipants)"
        
        // Show rank change indicator (simplified - would need previous rank to show actual change)
        rankChangeIndicator.image = UIImage(systemName: "arrow.up")
        rankChangeIndicator.tintColor = UIColor.systemGreen
    }
    
    private func updateAchievements(progress: EventProgress) {
        // Clear existing badges
        achievementBadges.forEach { $0.removeFromSuperview() }
        achievementBadges.removeAll()
        
        // Add achievement badges based on progress
        var achievements: [String] = []
        
        if progress.progressPercentage >= 0.25 {
            achievements.append("25%")
        }
        if progress.progressPercentage >= 0.5 {
            achievements.append("50%")
        }
        if progress.progressPercentage >= 0.75 {
            achievements.append("75%")
        }
        if progress.isComplete {
            achievements.append("🏆")
        }
        
        for (index, achievement) in achievements.enumerated() {
            let badge = createAchievementBadge(text: achievement)
            badge.translatesAutoresizingMaskIntoConstraints = false
            achievementContainer.addSubview(badge)
            achievementBadges.append(badge)
            
            NSLayoutConstraint.activate([
                badge.centerYAnchor.constraint(equalTo: achievementContainer.centerYAnchor),
                badge.leadingAnchor.constraint(equalTo: achievementContainer.leadingAnchor, constant: CGFloat(index * 60)),
                badge.widthAnchor.constraint(equalToConstant: 50),
                badge.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    private func createAchievementBadge(text: String) -> UIView {
        let badge = UIView()
        badge.backgroundColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.8)
        badge.layer.cornerRadius = 25
        badge.layer.borderWidth = 2
        badge.layer.borderColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0).cgColor
        
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        badge.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: badge.centerYAnchor)
        ])
        
        return badge
    }
    
    // MARK: - Real-time Updates
    
    private func observeProgressUpdates() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("EventProgressUpdated"),
            object: nil
        )
    }
    
    @objc private func handleProgressUpdate(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let progress = notification.userInfo?["progress"] as? EventProgress,
              progress.eventId == eventProgress?.eventId else {
            return
        }
        
        DispatchQueue.main.async {
            // Update progress display with animation
            self.updateProgressDisplay(progress: progress)
            self.updateRankingDisplay(progress: progress)
            self.eventProgress = progress
            
            print("📊 ProgressView: Updated from real-time notification")
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatValue(_ value: Double, label: String) -> String {
        if value >= 1000 {
            return "\(label): \(String(format: "%.1f", value / 1000))km"
        } else {
            return "\(label): \(Int(value))m"
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension EventProgressView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentActivities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as? ActivityCell else {
            return UITableViewCell()
        }
        
        let activity = recentActivities[indexPath.row]
        cell.configure(with: activity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
}

// MARK: - ActivityCell

class ActivityCell: UITableViewCell {
    
    private let workoutTypeIcon = UIImageView()
    private let valueLabel = UILabel()
    private let pointsLabel = UILabel()
    private let dateLabel = UILabel()
    
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
        
        workoutTypeIcon.contentMode = .scaleAspectFit
        workoutTypeIcon.tintColor = IndustrialDesign.Colors.primaryText
        workoutTypeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pointsLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        pointsLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        pointsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        dateLabel.font = UIFont.systemFont(ofSize: 10)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.textAlignment = .right
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(workoutTypeIcon)
        contentView.addSubview(valueLabel)
        contentView.addSubview(pointsLabel)
        contentView.addSubview(dateLabel)
        
        NSLayoutConstraint.activate([
            workoutTypeIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            workoutTypeIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            workoutTypeIcon.widthAnchor.constraint(equalToConstant: 16),
            workoutTypeIcon.heightAnchor.constraint(equalToConstant: 16),
            
            valueLabel.leadingAnchor.constraint(equalTo: workoutTypeIcon.trailingAnchor, constant: 8),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            pointsLabel.leadingAnchor.constraint(equalTo: valueLabel.trailingAnchor, constant: 8),
            pointsLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with activity: ProgressWorkout) {
        workoutTypeIcon.image = getWorkoutTypeIcon(activity.workoutType)
        valueLabel.text = formatActivityValue(activity.value)
        pointsLabel.text = "+\(activity.points)"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: activity.date)
    }
    
    private func getWorkoutTypeIcon(_ type: String) -> UIImage? {
        switch type.lowercased() {
        case "running":
            return UIImage(systemName: "figure.run")
        case "cycling":
            return UIImage(systemName: "bicycle")
        case "swimming":
            return UIImage(systemName: "figure.pool.swim")
        case "walking":
            return UIImage(systemName: "figure.walk")
        default:
            return UIImage(systemName: "figure.mixed.cardio")
        }
    }
    
    private func formatActivityValue(_ value: Double) -> String {
        if value >= 1000 {
            return "\(String(format: "%.1f", value / 1000))km"
        } else {
            return "\(Int(value))m"
        }
    }
}