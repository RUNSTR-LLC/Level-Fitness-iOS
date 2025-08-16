import UIKit

class TeamSubscriptionStatusView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let statusIconView = UIImageView()
    private let statusLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton(type: .custom)
    
    // MARK: - Properties
    private var isSubscribed = false
    private var teamId: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Container view
        containerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status icon
        statusIconView.contentMode = .scaleAspectFit
        statusIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description label
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = IndustrialDesign.Colors.secondaryText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Action button
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        actionButton.layer.cornerRadius = 8
        actionButton.layer.borderWidth = 1
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        
        containerView.addSubview(statusIconView)
        containerView.addSubview(statusLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(actionButton)
        addSubview(containerView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Status icon
            statusIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusIconView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            statusIconView.widthAnchor.constraint(equalToConstant: 24),
            statusIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: statusIconView.trailingAnchor, constant: 12),
            statusLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -12),
            
            // Description label
            descriptionLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Action button
            actionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            actionButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 80),
            actionButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(teamId: String) {
        self.teamId = teamId
        updateSubscriptionStatus()
    }
    
    private func updateSubscriptionStatus() {
        guard let teamId = teamId else { return }
        
        // DEVELOPMENT MODE: Always show as subscribed for testing
        // TODO: Re-enable subscription check for production
        let isDevelopmentMode = true
        
        if isDevelopmentMode {
            isSubscribed = true
            showSubscribedState()
            
            // Also check subscription tier for additional context
            Task {
                let subscriptionStatus = await SubscriptionService.shared.checkSubscriptionStatus()
                
                await MainActor.run {
                    self.updateForSubscriptionTier(subscriptionStatus)
                }
            }
        }
    }
    
    private func showSubscribedState() {
        statusIconView.image = UIImage(systemName: "checkmark.circle.fill")
        statusIconView.tintColor = IndustrialDesign.Colors.bitcoin
        
        statusLabel.text = "Active Subscription"
        statusLabel.textColor = IndustrialDesign.Colors.bitcoin
        
        descriptionLabel.text = "You're subscribed to this team. Compete in leaderboards, participate in events, and earn Bitcoin rewards."
        
        actionButton.setTitle("Manage", for: .normal)
        actionButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        actionButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        actionButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Add bolt decoration for subscribed teams
        addBoltDecoration()
    }
    
    private func showUnsubscribedState() {
        statusIconView.image = UIImage(systemName: "lock.circle.fill")
        statusIconView.tintColor = IndustrialDesign.Colors.secondaryText
        
        statusLabel.text = "Join Team"
        statusLabel.textColor = IndustrialDesign.Colors.primaryText
        
        descriptionLabel.text = "Join this team to compete and earn Bitcoin rewards for your workouts."
        
        actionButton.setTitle("Join", for: .normal)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        actionButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        
        // Remove bolt decoration
        removeBoltDecoration()
    }
    
    private func updateForSubscriptionTier(_ tier: SubscriptionStatus) {
        switch tier {
        case .creator:
            if isSubscribed {
                descriptionLabel.text = "You're the creator of this team and have full access to all features including analytics and event creation."
                statusLabel.text = "Team Creator"
                statusIconView.image = UIImage(systemName: "crown.fill")
                statusIconView.tintColor = IndustrialDesign.Colors.bitcoin
                statusLabel.textColor = IndustrialDesign.Colors.bitcoin
            }
        case .user:
            // Standard user subscription - keep existing messaging
            break
        case .none:
            if !isSubscribed {
                descriptionLabel.text = "Join this team to compete and start earning Bitcoin rewards for your workouts."
            }
        }
    }
    
    private func addBoltDecoration() {
        // Add bolt decoration to indicate active subscription
        let boltView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltView.tintColor = IndustrialDesign.Colors.bitcoin
        boltView.contentMode = .scaleAspectFit
        boltView.translatesAutoresizingMaskIntoConstraints = false
        boltView.tag = 999 // Tag for removal
        
        containerView.addSubview(boltView)
        
        NSLayoutConstraint.activate([
            boltView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            boltView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            boltView.widthAnchor.constraint(equalToConstant: 16),
            boltView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }
    
    private func removeBoltDecoration() {
        containerView.subviews.first { $0.tag == 999 }?.removeFromSuperview()
    }
    
    // MARK: - Actions
    
    @objc private func actionButtonTapped() {
        guard let teamId = teamId else { return }
        
        if isSubscribed {
            // Navigate to subscription management
            Task {
                await SubscriptionService.shared.openManageSubscriptions()
            }
        } else {
            // Trigger subscription flow
            NotificationCenter.default.post(name: .teamSubscriptionRequested, object: teamId)
        }
    }
    
    // MARK: - Public Methods
    
    func refreshStatus() {
        updateSubscriptionStatus()
    }
    
    func setSubscriptionState(_ subscribed: Bool) {
        isSubscribed = subscribed
        if subscribed {
            showSubscribedState()
        } else {
            showUnsubscribedState()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let teamSubscriptionRequested = Notification.Name("teamSubscriptionRequested")
}