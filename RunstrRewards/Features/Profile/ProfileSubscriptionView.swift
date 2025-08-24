import UIKit

protocol ProfileSubscriptionViewDelegate: AnyObject {
    func didTapManageSubscription()
    func didTapTeamSubscription(teamId: String)
}

class ProfileSubscriptionView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileSubscriptionViewDelegate?
    private var currentStatus: SubscriptionStatus = .none
    private var teamCount: Int = 0
    private var monthlyCost: Double = 0
    
    // MARK: - UI Components
    private let containerView = UIView()
    private var gradientLayer: CAGradientLayer?
    private let titleLabel = UILabel()
    private let statusCard = UIView()
    private let statusIcon = UIImageView()
    private let statusLabel = UILabel()
    private let costLabel = UILabel()
    private let manageButton = UIButton(type: .custom)
    private let teamsSection = UIView()
    private let teamsSectionTitle = UILabel()
    private let teamsList = UIStackView()
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = containerView.bounds
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        // Container with industrial styling
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.cornerRadius = IndustrialDesign.Sizing.cardCornerRadius
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "SUBSCRIPTION"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.accentText
        titleLabel.letterSpacing = 1
        
        // Status card
        statusCard.translatesAutoresizingMaskIntoConstraints = false
        statusCard.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        statusCard.layer.cornerRadius = 8
        statusCard.layer.borderWidth = 1
        statusCard.layer.borderColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        
        // Status icon
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.contentMode = .scaleAspectFit
        statusIcon.tintColor = IndustrialDesign.Colors.secondaryText
        statusIcon.image = UIImage(systemName: "person.circle")
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        statusLabel.textColor = IndustrialDesign.Colors.primaryText
        statusLabel.text = "Free Account"
        
        // Cost label
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        costLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        costLabel.textColor = IndustrialDesign.Colors.secondaryText
        costLabel.text = "$0/month"
        
        // Manage button
        manageButton.translatesAutoresizingMaskIntoConstraints = false
        manageButton.setTitle("MANAGE", for: .normal)
        manageButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        manageButton.titleLabel?.letterSpacing = 1
        manageButton.setTitleColor(IndustrialDesign.Colors.accentText, for: .normal)
        manageButton.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0)
        manageButton.layer.cornerRadius = 8
        manageButton.layer.borderWidth = 1
        manageButton.layer.borderColor = IndustrialDesign.Colors.accentText.withAlphaComponent(0.3).cgColor
        manageButton.addTarget(self, action: #selector(manageButtonTapped), for: .touchUpInside)
        
        // Teams section
        teamsSection.translatesAutoresizingMaskIntoConstraints = false
        teamsSection.isHidden = true // Initially hidden
        
        // Teams section title
        teamsSectionTitle.translatesAutoresizingMaskIntoConstraints = false
        teamsSectionTitle.text = "TEAM SUBSCRIPTIONS"
        teamsSectionTitle.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        teamsSectionTitle.textColor = IndustrialDesign.Colors.secondaryText
        teamsSectionTitle.letterSpacing = 1
        
        // Teams list
        teamsList.translatesAutoresizingMaskIntoConstraints = false
        teamsList.axis = .vertical
        teamsList.spacing = 8
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(statusCard)
        statusCard.addSubview(statusIcon)
        statusCard.addSubview(statusLabel)
        statusCard.addSubview(costLabel)
        statusCard.addSubview(manageButton)
        containerView.addSubview(teamsSection)
        teamsSection.addSubview(teamsSectionTitle)
        teamsSection.addSubview(teamsList)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            // Status card
            statusCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statusCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusCard.heightAnchor.constraint(equalToConstant: 70),
            
            // Status icon
            statusIcon.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 16),
            statusIcon.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 28),
            statusIcon.heightAnchor.constraint(equalToConstant: 28),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            
            // Cost label
            costLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            costLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 2),
            
            // Manage button
            manageButton.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -16),
            manageButton.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            manageButton.widthAnchor.constraint(equalToConstant: 80),
            manageButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Teams section
            teamsSection.topAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: 16),
            teamsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            teamsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            teamsSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Teams section title
            teamsSectionTitle.topAnchor.constraint(equalTo: teamsSection.topAnchor),
            teamsSectionTitle.leadingAnchor.constraint(equalTo: teamsSection.leadingAnchor),
            
            // Teams list
            teamsList.topAnchor.constraint(equalTo: teamsSectionTitle.bottomAnchor, constant: 12),
            teamsList.leadingAnchor.constraint(equalTo: teamsSection.leadingAnchor),
            teamsList.trailingAnchor.constraint(equalTo: teamsSection.trailingAnchor),
            teamsList.bottomAnchor.constraint(equalTo: teamsSection.bottomAnchor),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateSubscriptionInfo(status: SubscriptionStatus, teamCount: Int, monthlyCost: Double) {
        currentStatus = status
        self.teamCount = teamCount
        self.monthlyCost = monthlyCost
        
        // Update status display
        switch status {
        case .captain:
            statusIcon.image = UIImage(systemName: "crown.fill")
            statusIcon.tintColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0) // Bitcoin orange
            statusLabel.text = "Captain Account"
            statusLabel.textColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0)
            
            if teamCount > 0 {
                let totalCost = monthlyCost + 19.99
                costLabel.text = "$\(String(format: "%.2f", totalCost))/month"
            } else {
                costLabel.text = "$19.99/month"
            }
            
        case .user:
            statusIcon.image = UIImage(systemName: "person.fill")
            statusIcon.tintColor = IndustrialDesign.Colors.accentText
            statusLabel.text = "Member Account"
            statusLabel.textColor = IndustrialDesign.Colors.primaryText
            costLabel.text = "$\(String(format: "%.2f", monthlyCost))/month"
            
        case .none:
            statusIcon.image = UIImage(systemName: "person.circle")
            statusIcon.tintColor = IndustrialDesign.Colors.secondaryText
            statusLabel.text = "Free Account"
            statusLabel.textColor = IndustrialDesign.Colors.primaryText
            costLabel.text = "$0/month"
        }
        
        // Show/hide teams section
        if teamCount > 0 {
            teamsSection.isHidden = false
            updateTeamsList()
        } else {
            teamsSection.isHidden = true
        }
    }
    
    // MARK: - Private Methods
    
    private func updateTeamsList() {
        // Clear existing team items
        teamsList.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add sample team subscriptions (in real implementation, this would come from data)
        for i in 0..<teamCount {
            let teamItem = createTeamItem(name: "Team \(i + 1)", cost: 1.99)
            teamsList.addArrangedSubview(teamItem)
        }
    }
    
    private func createTeamItem(name: String, cost: Double) -> UIView {
        let item = UIView()
        item.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0)
        item.layer.cornerRadius = 6
        item.layer.borderWidth = 1
        item.layer.borderColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = name
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        
        let costLabel = UILabel()
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        costLabel.text = "$\(String(format: "%.2f", cost))/mo"
        costLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        costLabel.textColor = UIColor(red: 0.97, green: 0.57, blue: 0.1, alpha: 1.0)
        
        item.addSubview(nameLabel)
        item.addSubview(costLabel)
        
        NSLayoutConstraint.activate([
            item.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: item.leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: item.centerYAnchor),
            
            costLabel.trailingAnchor.constraint(equalTo: item.trailingAnchor, constant: -12),
            costLabel.centerYAnchor.constraint(equalTo: item.centerYAnchor)
        ])
        
        return item
    }
    
    // MARK: - Actions
    
    @objc private func manageButtonTapped() {
        print("👤 Subscription: Manage button tapped")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animate button
        UIView.animate(withDuration: 0.1, animations: {
            self.manageButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.manageButton.transform = .identity
            }
        }
        
        delegate?.didTapManageSubscription()
    }
}