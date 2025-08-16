import UIKit

protocol TeamDetailHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapSettingsButton()
    func didTapSubscribeButton()
}

class TeamDetailHeaderView: UIView {
    
    // MARK: - Properties
    weak var delegate: TeamDetailHeaderViewDelegate?
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .custom)
    private let teamNameLabel = UILabel()
    private let memberCountLabel = UILabel()
    private let captainBadge = UIView()
    private let captainBadgeLabel = UILabel()
    private let subscribeButton = UIButton(type: .custom)
    private let settingsButton = UIButton(type: .custom)
    
    // Subscription state
    private var isSubscribed = false
    private var isLoading = false
    private var isCaptain = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        borderLayer.frame = CGRect(x: 0, y: 79, width: UIScreen.main.bounds.width, height: 1)
        layer.addSublayer(borderLayer)
        
        // Back button
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Team name
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        teamNameLabel.font = IndustrialDesign.Typography.navTitleFont
        teamNameLabel.textAlignment = .center
        
        // Member count
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        memberCountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        memberCountLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Captain badge
        captainBadge.translatesAutoresizingMaskIntoConstraints = false
        captainBadge.backgroundColor = IndustrialDesign.Colors.bitcoin
        captainBadge.layer.cornerRadius = 8
        captainBadge.layer.borderWidth = 1
        captainBadge.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        captainBadge.isHidden = true // Hidden by default
        
        captainBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        captainBadgeLabel.text = "CAPTAIN"
        captainBadgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        captainBadgeLabel.textColor = .white
        captainBadgeLabel.textAlignment = .center
        
        captainBadge.addSubview(captainBadgeLabel)
        memberCountLabel.textAlignment = .center
        
        // Subscribe button
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        subscribeButton.setTitle("Join", for: .normal)
        subscribeButton.setTitleColor(.white, for: .normal)
        subscribeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        subscribeButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        subscribeButton.layer.cornerRadius = 16
        subscribeButton.layer.borderWidth = 1
        subscribeButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        subscribeButton.addTarget(self, action: #selector(subscribeButtonTapped), for: .touchUpInside)
        
        // Settings button
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        settingsButton.tintColor = IndustrialDesign.Colors.secondaryText
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        
        addSubview(backButton)
        addSubview(teamNameLabel)
        addSubview(memberCountLabel)
        addSubview(captainBadge)
        addSubview(subscribeButton)
        addSubview(settingsButton)
        
        // Add gradient to team name
        DispatchQueue.main.async {
            self.applyGradientToLabel(self.teamNameLabel)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: IndustrialDesign.Spacing.large),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Team name - constrained to avoid overlap with buttons
            teamNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            teamNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            teamNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            teamNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: subscribeButton.leadingAnchor, constant: -12),
            
            memberCountLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            memberCountLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            memberCountLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            memberCountLabel.trailingAnchor.constraint(lessThanOrEqualTo: subscribeButton.leadingAnchor, constant: -12),
            
            // Captain badge (positioned above member count when shown)
            captainBadge.centerXAnchor.constraint(equalTo: centerXAnchor),
            captainBadge.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 2),
            captainBadge.widthAnchor.constraint(equalToConstant: 70),
            captainBadge.heightAnchor.constraint(equalToConstant: 16),
            
            captainBadgeLabel.centerXAnchor.constraint(equalTo: captainBadge.centerXAnchor),
            captainBadgeLabel.centerYAnchor.constraint(equalTo: captainBadge.centerYAnchor),
            
            subscribeButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            subscribeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            subscribeButton.widthAnchor.constraint(equalToConstant: 55),
            subscribeButton.heightAnchor.constraint(equalToConstant: 26),
            
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(teamName: String, memberCount: Int) {
        teamNameLabel.text = teamName
        memberCountLabel.text = "\(memberCount) MEMBERS"
    }
    
    func showCaptainBadge(_ show: Bool) {
        isCaptain = show
        captainBadge.isHidden = !show
        
        // Hide subscribe button for captains
        if show {
            subscribeButton.isHidden = true
        } else {
            subscribeButton.isHidden = false
        }
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        delegate?.didTapBackButton()
    }
    
    @objc private func settingsButtonTapped() {
        delegate?.didTapSettingsButton()
    }
    
    @objc private func subscribeButtonTapped() {
        print("🏗️ TeamDetailHeader: Subscribe button tapped")
        delegate?.didTapSubscribeButton()
    }
    
    // MARK: - Subscription State Management
    
    func updateSubscriptionState(isSubscribed: Bool, isLoading: Bool = false) {
        self.isSubscribed = isSubscribed
        self.isLoading = isLoading
        
        UIView.animate(withDuration: 0.3) {
            if isLoading {
                self.subscribeButton.setTitle("Joining...", for: .normal)
                self.subscribeButton.isEnabled = false
                self.subscribeButton.alpha = 0.6
            } else if isSubscribed {
                self.subscribeButton.setTitle("Joined", for: .normal)
                self.subscribeButton.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
                self.subscribeButton.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
                self.subscribeButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
                self.subscribeButton.isEnabled = true
                self.subscribeButton.alpha = 1.0
            } else {
                self.subscribeButton.setTitle("Join", for: .normal)
                self.subscribeButton.backgroundColor = IndustrialDesign.Colors.bitcoin
                self.subscribeButton.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
                self.subscribeButton.setTitleColor(.white, for: .normal)
                self.subscribeButton.isEnabled = true
                self.subscribeButton.alpha = 1.0
            }
        }
    }
    
    func setTeamId(_ teamId: String) {
        // Check current subscription status
        Task {
            let isCurrentlySubscribed = SubscriptionService.shared.isSubscribedToTeam(teamId)
            
            await MainActor.run {
                self.updateSubscriptionState(isSubscribed: isCurrentlySubscribed)
            }
        }
    }
    
    private func applyGradientToLabel(_ label: UILabel) {
        let gradient = CAGradientLayer.logo()
        gradient.frame = label.bounds
        
        let gradientColor = UIColor { _ in
            return UIColor.white
        }
        label.textColor = gradientColor
        
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