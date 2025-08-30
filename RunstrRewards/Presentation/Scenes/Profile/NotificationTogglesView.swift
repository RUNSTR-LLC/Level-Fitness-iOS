import UIKit

class NotificationTogglesView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let togglesStackView = UIStackView()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Toggle Views
    private let eventToggleView = NotificationToggleItemView(
        title: "Event Notifications",
        subtitle: "Competitions, deadlines, results",
        key: "event_notifications"
    )
    
    private let leagueToggleView = NotificationToggleItemView(
        title: "League Updates",
        subtitle: "Rank changes, position moves",
        key: "league_updates"
    )
    
    private let announcementToggleView = NotificationToggleItemView(
        title: "Team Announcements",
        subtitle: "Captain messages, updates",
        key: "team_announcements"
    )
    
    private let bitcoinToggleView = NotificationToggleItemView(
        title: "Bitcoin Rewards",
        subtitle: "Workout earnings, payouts",
        key: "bitcoin_rewards"
    )
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        loadToggleStates()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
        
        // Update bolt decoration position
        boltDecoration.frame = CGRect(
            x: containerView.bounds.width - 18,
            y: 10,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        // Container setup with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = IndustrialDesign.Colors.cardBackground
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient background
        let gradient = CAGradientLayer.industrial()
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // Title label
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Toggles stack view
        togglesStackView.axis = .vertical
        togglesStackView.spacing = 0
        togglesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Industrial bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add toggle views to stack
        togglesStackView.addArrangedSubview(eventToggleView)
        
        // Add separator
        let separator1 = createSeparator()
        togglesStackView.addArrangedSubview(separator1)
        
        togglesStackView.addArrangedSubview(leagueToggleView)
        
        // Add separator
        let separator2 = createSeparator()
        togglesStackView.addArrangedSubview(separator2)
        
        togglesStackView.addArrangedSubview(announcementToggleView)
        
        // Add separator
        let separator3 = createSeparator()
        togglesStackView.addArrangedSubview(separator3)
        
        togglesStackView.addArrangedSubview(bitcoinToggleView)
        
        // Add subviews
        containerView.addSubview(titleLabel)
        containerView.addSubview(togglesStackView)
        containerView.addSubview(boltDecoration)
        addSubview(containerView)
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = IndustrialDesign.Colors.cardBorder
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills the view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.xLarge),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.xLarge),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            
            // Toggles stack view
            togglesStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            togglesStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            togglesStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            togglesStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadToggleStates() {
        // Load states from UserDefaults using keys that match NotificationService
        eventToggleView.setToggleState(
            UserDefaults.standard.bool(forKey: "notifications.event_reminders")
        )
        
        leagueToggleView.setToggleState(
            UserDefaults.standard.bool(forKey: "notifications.leaderboard_changes")
        )
        
        announcementToggleView.setToggleState(
            UserDefaults.standard.bool(forKey: "notifications.team_announcements")
        )
        
        bitcoinToggleView.setToggleState(
            UserDefaults.standard.bool(forKey: "notifications.workout_rewards")
        )
    }
}

// MARK: - NotificationToggleItemView

class NotificationToggleItemView: UIView {
    
    // MARK: - Properties
    private let title: String
    private let subtitle: String
    private let notificationKey: String
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let toggleSwitch = UISwitch()
    
    // MARK: - Initialization
    init(title: String, subtitle: String, key: String) {
        self.title = title
        self.subtitle = subtitle
        self.notificationKey = key
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Subtitle label
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Toggle switch
        toggleSwitch.onTintColor = IndustrialDesign.Colors.bitcoin
        toggleSwitch.thumbTintColor = IndustrialDesign.Colors.primaryText
        toggleSwitch.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        toggleSwitch.layer.cornerRadius = 16
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(toggleSwitch)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Height constraint
            heightAnchor.constraint(equalToConstant: 60),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggleSwitch.leadingAnchor, constant: -16),
            
            // Subtitle label
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggleSwitch.leadingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            // Toggle switch
            toggleSwitch.centerYAnchor.constraint(equalTo: centerYAnchor),
            toggleSwitch.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    private func setupActions() {
        toggleSwitch.addTarget(self, action: #selector(toggleValueChanged), for: .valueChanged)
    }
    
    // MARK: - Actions
    
    @objc private func toggleValueChanged() {
        let isOn = toggleSwitch.isOn
        print("📱 NotificationToggle: \(notificationKey) set to \(isOn)")
        
        // Update UserDefaults using keys that match NotificationService.shouldShowNotification()
        switch notificationKey {
        case "event_notifications":
            UserDefaults.standard.set(isOn, forKey: "notifications.event_reminders")
        case "league_updates":
            UserDefaults.standard.set(isOn, forKey: "notifications.leaderboard_changes")
        case "team_announcements":
            UserDefaults.standard.set(isOn, forKey: "notifications.team_announcements")
        case "bitcoin_rewards":
            UserDefaults.standard.set(isOn, forKey: "notifications.workout_rewards")
        default:
            break
        }
        
        // Update NotificationIntelligence preferences if user is logged in
        if let userId = AuthenticationService.shared.currentUserId {
            let preferences = NotificationPreferences(
                workoutRewards: UserDefaults.standard.bool(forKey: "notifications.workout_rewards"),
                leaderboardChanges: UserDefaults.standard.bool(forKey: "notifications.leaderboard_changes"),
                eventReminders: UserDefaults.standard.bool(forKey: "notifications.event_reminders"),
                challengeInvites: UserDefaults.standard.bool(forKey: "notifications.challenge_invites"),
                streakReminders: UserDefaults.standard.bool(forKey: "notifications.streak_reminders"),
                weeklySummaries: UserDefaults.standard.bool(forKey: "notifications.weekly_summaries"),
                teamActivity: UserDefaults.standard.bool(forKey: "notifications.team_announcements"),
                achievements: UserDefaults.standard.bool(forKey: "notifications.achievements")
            )
            
            NotificationIntelligence.shared.updateUserPreferences(userId: userId, preferences: preferences)
            print("📱 NotificationToggle: Updated NotificationIntelligence preferences for user \(userId)")
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Public Methods
    
    func setToggleState(_ isOn: Bool) {
        toggleSwitch.isOn = isOn
    }
}