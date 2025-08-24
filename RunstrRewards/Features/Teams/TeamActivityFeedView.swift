import UIKit

protocol TeamActivityFeedViewDelegate: AnyObject {
    func didTapActivity(_ activity: TeamActivity)
    func didTapViewAllActivity()
}

class TeamActivityFeedView: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamActivityFeedViewDelegate?
    private var activities: [TeamActivity] = []
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let viewAllButton = UIButton(type: .custom)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Activity feed container
    private let feedContainer = UIView()
    private var activityViews: [TeamActivityItemView] = []
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescription = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        showEmptyState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Title section
        titleLabel.text = "Recent Activity"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // View all button
        viewAllButton.setTitle("View All", for: .normal)
        viewAllButton.setTitleColor(UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0), for: .normal)
        viewAllButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        viewAllButton.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        
        // Loading indicator
        loadingIndicator.color = IndustrialDesign.Colors.secondaryText
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        
        // Feed container
        feedContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Empty state
        setupEmptyState()
        
        addSubview(titleLabel)
        addSubview(viewAllButton)
        addSubview(loadingIndicator)
        addSubview(feedContainer)
        addSubview(emptyStateView)
        
        // Add bolt decoration
        DispatchQueue.main.async {
            self.addBoltDecoration()
        }
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = false
        
        emptyStateLabel.text = "No Recent Activity"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        emptyStateLabel.textColor = IndustrialDesign.Colors.primaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateDescription.text = "Team activity will appear here as members complete workouts and join challenges"
        emptyStateDescription.font = UIFont.systemFont(ofSize: 14)
        emptyStateDescription.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescription.textAlignment = .center
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateDescription)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title and view all button
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            viewAllButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            viewAllButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            loadingIndicator.centerXAnchor.constraint(equalTo: viewAllButton.centerXAnchor),
            
            // Feed container
            feedContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            feedContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            feedContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            feedContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // Empty state
            emptyStateView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            emptyStateView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            emptyStateView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            emptyStateView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 20),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescription.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 8),
            emptyStateDescription.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescription.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescription.bottomAnchor.constraint(lessThanOrEqualTo: emptyStateView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(with activities: [TeamActivity]) {
        self.activities = activities
        
        if activities.isEmpty {
            showEmptyState()
        } else {
            showActivityData()
            createActivityViews()
        }
        
        updateViewAllButtonVisibility()
    }
    
    func showLoading() {
        viewAllButton.isHidden = true
        loadingIndicator.startAnimating()
        emptyStateView.isHidden = true
        feedContainer.isHidden = true
    }
    
    func hideLoading() {
        viewAllButton.isHidden = false
        loadingIndicator.stopAnimating()
    }
    
    func showEmptyState() {
        emptyStateView.isHidden = false
        feedContainer.isHidden = true
        hideLoading()
        updateViewAllButtonVisibility()
    }
    
    func showActivityData() {
        emptyStateView.isHidden = true
        feedContainer.isHidden = false
        hideLoading()
        updateViewAllButtonVisibility()
    }
    
    // MARK: - Private Methods
    
    private func createActivityViews() {
        // Clear existing activity views
        activityViews.forEach { $0.removeFromSuperview() }
        activityViews.removeAll()
        
        // Show up to 5 most recent activities
        let activitiesToShow = Array(activities.prefix(5))
        var previousView: UIView? = nil
        
        for activity in activitiesToShow {
            let activityView = TeamActivityItemView(activity: activity)
            activityView.translatesAutoresizingMaskIntoConstraints = false
            activityView.delegate = self
            feedContainer.addSubview(activityView)
            activityViews.append(activityView)
            
            NSLayoutConstraint.activate([
                activityView.leadingAnchor.constraint(equalTo: feedContainer.leadingAnchor),
                activityView.trailingAnchor.constraint(equalTo: feedContainer.trailingAnchor),
                activityView.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            if let previous = previousView {
                activityView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 8).isActive = true
            } else {
                activityView.topAnchor.constraint(equalTo: feedContainer.topAnchor).isActive = true
            }
            
            previousView = activityView
        }
        
        // Set container height
        if let lastView = previousView {
            lastView.bottomAnchor.constraint(equalTo: feedContainer.bottomAnchor).isActive = true
        }
    }
    
    private func updateViewAllButtonVisibility() {
        viewAllButton.isHidden = activities.count <= 5
    }
    
    @objc private func viewAllTapped() {
        delegate?.didTapViewAllActivity()
    }
    
    private func addBoltDecoration() {
        // Add a simple circular decoration instead of bolt
        let decoration = UIView()
        decoration.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        decoration.layer.cornerRadius = 6
        decoration.translatesAutoresizingMaskIntoConstraints = false
        addSubview(decoration)
        
        NSLayoutConstraint.activate([
            decoration.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            decoration.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            decoration.widthAnchor.constraint(equalToConstant: 12),
            decoration.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
}

// MARK: - TeamActivityItemViewDelegate

extension TeamActivityFeedView: TeamActivityItemViewDelegate {
    func didTapActivityItem(_ activity: TeamActivity) {
        delegate?.didTapActivity(activity)
    }
}

// MARK: - TeamActivityItemView Component

protocol TeamActivityItemViewDelegate: AnyObject {
    func didTapActivityItem(_ activity: TeamActivity)
}

private class TeamActivityItemView: UIView {
    
    weak var delegate: TeamActivityItemViewDelegate?
    private let activity: TeamActivity
    
    // UI Components
    private let iconView = UIView()
    private let iconLabel = UILabel()
    private let contentContainer = UIView()
    private let usernameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let timeLabel = UILabel()
    private let metricLabel = UILabel()
    
    init(activity: TeamActivity) {
        self.activity = activity
        super.init(frame: .zero)
        setupUI()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor
        
        // Icon view
        iconView.backgroundColor = getIconBackgroundColor()
        iconView.layer.cornerRadius = 16
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        iconLabel.text = getActivityIcon()
        iconLabel.font = UIFont.systemFont(ofSize: 14)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Content container
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Username
        usernameLabel.text = activity.username
        usernameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        usernameLabel.textColor = IndustrialDesign.Colors.primaryText
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        descriptionLabel.text = activity.description
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Time
        timeLabel.text = formatTimeAgo(activity.createdAt)
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Metric (distance/duration if available)
        metricLabel.text = getMetricText()
        metricLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        metricLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        metricLabel.translatesAutoresizingMaskIntoConstraints = false
        metricLabel.isHidden = metricLabel.text?.isEmpty ?? true
        
        iconView.addSubview(iconLabel)
        contentContainer.addSubview(usernameLabel)
        contentContainer.addSubview(descriptionLabel)
        addSubview(iconView)
        addSubview(contentContainer)
        addSubview(timeLabel)
        addSubview(metricLabel)
        
        NSLayoutConstraint.activate([
            // Icon view
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            
            // Content container
            contentContainer.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            contentContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            
            usernameLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            usernameLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            
            // Time label
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // Metric label
            metricLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 4),
            metricLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(activityTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    @objc private func activityTapped() {
        delegate?.didTapActivityItem(activity)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }
    
    private func getActivityIcon() -> String {
        switch activity.type {
        case "workout_completed":
            return "🏃‍♂️"
        case "member_joined":
            return "👋"
        case "challenge_completed":
            return "🏆"
        case "event_won":
            return "🥇"
        default:
            return "📈"
        }
    }
    
    private func getIconBackgroundColor() -> UIColor {
        switch activity.type {
        case "workout_completed":
            return UIColor.systemBlue.withAlphaComponent(0.2)
        case "member_joined":
            return UIColor.systemGreen.withAlphaComponent(0.2)
        case "challenge_completed", "event_won":
            return UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.2)
        default:
            return UIColor.systemGray.withAlphaComponent(0.2)
        }
    }
    
    private func getMetricText() -> String {
        guard activity.type == "workout_completed" else { return "" }
        
        var metrics: [String] = []
        
        if let distance = activity.metadata["distance"] as? Double, distance > 0 {
            let km = distance / 1000.0
            if km >= 1 {
                metrics.append(String(format: "%.1f km", km))
            } else {
                metrics.append(String(format: "%.0f m", distance))
            }
        }
        
        if let duration = activity.metadata["duration"] as? Int, duration > 0 {
            let minutes = duration / 60
            if minutes > 0 {
                metrics.append("\(minutes)min")
            }
        }
        
        return metrics.joined(separator: " • ")
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}