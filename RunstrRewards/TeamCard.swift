import UIKit

protocol TeamCardDelegate: AnyObject {
    func teamCardDidTap(_ teamCard: TeamCard, teamData: TeamData)
}

class TeamCard: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Header section
    private let headerSection = UIView()
    private let teamNameLabel = UILabel()
    private let captainLabel = UILabel()
    private let joinButton = UIButton(type: .custom)
    
    // Stats section
    private let statsSection = UIView()
    private let membersStatItem = StatItem(value: "0", label: "Members")
    private let prizePoolStatItem = StatItem(value: "₿0.00", label: "Prize Pool", isBitcoin: true)
    
    // Activities section
    private let activitiesSection = UIView()
    private var activityBadges: [UILabel] = []
    
    private let teamData: TeamData
    weak var delegate: TeamCardDelegate?
    
    // MARK: - Initialization
    init(teamData: TeamData) {
        self.teamData = teamData
        super.init(frame: .zero)
        
        setupCard()
        setupContent()
        setupConstraints()
        setupInteractions()
        updateContent()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
        
        // Update bolt decoration position
        boltDecoration.frame = CGRect(
            x: 12,
            y: 12,
            width: IndustrialDesign.Sizing.boltSize,
            height: IndustrialDesign.Sizing.boltSize
        )
    }
    
    // MARK: - Setup Methods
    
    private func setupCard() {
        // Container setup with industrial gradient
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        
        // Add gradient background
        let gradient = CAGradientLayer.industrial()
        gradient.cornerRadius = 12
        containerView.layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
        
        // Shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.3
        
        // Industrial bolt decoration
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add inner shadow to bolt
        let innerShadow = CALayer()
        innerShadow.frame = CGRect(x: 0, y: 0, width: IndustrialDesign.Sizing.boltSize, height: IndustrialDesign.Sizing.boltSize)
        innerShadow.cornerRadius = IndustrialDesign.Sizing.boltSize / 2
        innerShadow.backgroundColor = UIColor.black.cgColor
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 1)
        innerShadow.shadowOpacity = 0.8
        innerShadow.shadowRadius = 1
        boltDecoration.layer.addSublayer(innerShadow)
        
        addSubview(containerView)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupContent() {
        // Header section
        headerSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Team name
        teamNameLabel.translatesAutoresizingMaskIntoConstraints = false
        teamNameLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        teamNameLabel.textColor = IndustrialDesign.Colors.primaryText
        teamNameLabel.numberOfLines = 1
        
        // Captain label
        captainLabel.translatesAutoresizingMaskIntoConstraints = false
        captainLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        captainLabel.textColor = IndustrialDesign.Colors.secondaryText
        captainLabel.numberOfLines = 1
        
        // Join button
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        joinButton.configuration = config
        joinButton.layer.cornerRadius = 6
        joinButton.layer.borderWidth = 1
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        headerSection.addSubview(teamNameLabel)
        headerSection.addSubview(captainLabel)
        headerSection.addSubview(joinButton)
        
        // Stats section
        statsSection.translatesAutoresizingMaskIntoConstraints = false
        
        membersStatItem.translatesAutoresizingMaskIntoConstraints = false
        prizePoolStatItem.translatesAutoresizingMaskIntoConstraints = false
        
        statsSection.addSubview(membersStatItem)
        statsSection.addSubview(prizePoolStatItem)
        
        // Activities section
        activitiesSection.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(headerSection)
        containerView.addSubview(statsSection)
        containerView.addSubview(activitiesSection)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container fills the entire view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header section
            headerSection.topAnchor.constraint(equalTo: containerView.topAnchor, constant: IndustrialDesign.Spacing.large),
            headerSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32), // Space for bolt decoration
            headerSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            headerSection.heightAnchor.constraint(equalToConstant: 44),
            
            // Header elements
            teamNameLabel.topAnchor.constraint(equalTo: headerSection.topAnchor),
            teamNameLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            teamNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: joinButton.leadingAnchor, constant: -IndustrialDesign.Spacing.medium),
            
            captainLabel.topAnchor.constraint(equalTo: teamNameLabel.bottomAnchor, constant: 4),
            captainLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            captainLabel.trailingAnchor.constraint(lessThanOrEqualTo: joinButton.leadingAnchor, constant: -IndustrialDesign.Spacing.medium),
            captainLabel.bottomAnchor.constraint(equalTo: headerSection.bottomAnchor),
            
            joinButton.centerYAnchor.constraint(equalTo: headerSection.centerYAnchor),
            joinButton.trailingAnchor.constraint(equalTo: headerSection.trailingAnchor),
            joinButton.heightAnchor.constraint(equalToConstant: 32),
            
            // Stats section
            statsSection.topAnchor.constraint(equalTo: headerSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            statsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
            statsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            statsSection.heightAnchor.constraint(equalToConstant: 44),
            
            // Stats items - evenly distributed
            membersStatItem.leadingAnchor.constraint(equalTo: statsSection.leadingAnchor),
            membersStatItem.centerYAnchor.constraint(equalTo: statsSection.centerYAnchor),
            membersStatItem.widthAnchor.constraint(equalTo: statsSection.widthAnchor, multiplier: 0.5),
            
            prizePoolStatItem.trailingAnchor.constraint(equalTo: statsSection.trailingAnchor),
            prizePoolStatItem.centerYAnchor.constraint(equalTo: statsSection.centerYAnchor),
            prizePoolStatItem.widthAnchor.constraint(equalTo: statsSection.widthAnchor, multiplier: 0.5),
            
            // Activities section
            activitiesSection.topAnchor.constraint(equalTo: statsSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            activitiesSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
            activitiesSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            activitiesSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large),
            activitiesSection.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupInteractions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func updateContent() {
        // Update text content
        teamNameLabel.text = teamData.name
        captainLabel.text = "CAPTAIN: \(teamData.captain)".uppercased()
        
        // Update stats
        membersStatItem.updateValue("\(teamData.members)")
        prizePoolStatItem.updateValue(teamData.prizePool)
        
        // Update join button
        updateJoinButton()
        
        // Create activity badges
        createActivityBadges()
    }
    
    private func updateJoinButton() {
        updateJoinButtonState()
    }
    
    private func updateJoinButtonState() {
        let isSubscribed = SubscriptionService.shared.isSubscribedToTeam(teamData.id)
        
        if isSubscribed {
            joinButton.setTitle("SUBSCRIBED", for: .normal)
            joinButton.backgroundColor = IndustrialDesign.Colors.cardBackground
            joinButton.layer.borderColor = IndustrialDesign.Colors.primaryText.cgColor
            joinButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
            joinButton.isEnabled = true
        } else {
            joinButton.setTitle("SUBSCRIBE", for: .normal)
            joinButton.backgroundColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
            joinButton.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
            joinButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
            joinButton.isEnabled = true
        }
    }
    
    private func createActivityBadges() {
        // Remove existing badges
        activityBadges.forEach { $0.removeFromSuperview() }
        activityBadges.removeAll()
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        
        for activity in teamData.activities {
            let badge = createActivityBadge(text: activity)
            stackView.addArrangedSubview(badge)
            activityBadges.append(badge)
        }
        
        activitiesSection.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: activitiesSection.leadingAnchor),
            stackView.centerYAnchor.constraint(equalTo: activitiesSection.centerYAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: activitiesSection.trailingAnchor)
        ])
    }
    
    private func createActivityBadge(text: String) -> UILabel {
        let badge = UILabel()
        badge.text = text.uppercased()
        badge.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        badge.textColor = IndustrialDesign.Colors.secondaryText
        badge.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.05)
        badge.layer.cornerRadius = 4
        badge.layer.borderWidth = 1
        badge.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1).cgColor
        badge.textAlignment = .center
        badge.clipsToBounds = true
        
        // Add padding
        badge.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0)
        
        // Set intrinsic content size with padding
        let textSize = text.uppercased().size(withAttributes: [.font: UIFont.systemFont(ofSize: 11, weight: .medium)])
        badge.frame = CGRect(x: 0, y: 0, width: textSize.width + 20, height: 20)
        
        return badge
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        print("Team card tapped: \(teamData.name)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animation
        animateTap()
        
        // Notify delegate
        delegate?.teamCardDidTap(self, teamData: teamData)
    }
    
    @objc private func joinButtonTapped() {
        print("Join button tapped for team: \(teamData.name)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Check if already subscribed
        if SubscriptionService.shared.isSubscribedToTeam(teamData.id) {
            print("Already subscribed to team \(teamData.name)")
            return
        }
        
        // Present payment sheet for team subscription
        presentPaymentSheet()
    }
    
    private func presentPaymentSheet() {
        guard let parentViewController = findParentViewController() else {
            print("Could not find parent view controller")
            return
        }
        
        let paymentSheet = PaymentSheetViewController(teamData: teamData)
        paymentSheet.onCompletion = { [weak self] success in
            if success {
                print("✅ Team subscription successful for \(self?.teamData.name ?? "unknown")")
                // Refresh the subscription status
                self?.updateJoinButtonState()
            } else {
                print("❌ Team subscription cancelled or failed")
            }
        }
        
        parentViewController.present(paymentSheet, animated: true)
    }
    
    private func findParentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    private func animateTap() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform.identity.scaledBy(x: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = .identity
            })
        }
    }
    
    // MARK: - Touch Handling for Hover Effects
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // Don't animate if touch is on join button
        if let touch = touches.first {
            let touchPoint = touch.location(in: self)
            let joinButtonFrame = joinButton.convert(joinButton.bounds, to: self)
            if !joinButtonFrame.contains(touchPoint) {
                animateToHoverState()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        animateToNormalState()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        animateToNormalState()
    }
    
    private func animateToHoverState() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Lift effect
            self.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -2)
            
            // Border color change
            self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorderHover.cgColor
            
            // Enhanced shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 8)
            self.containerView.layer.shadowRadius = 16
            self.containerView.layer.shadowOpacity = 0.4
        }
    }
    
    private func animateToNormalState() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Reset transform
            self.transform = .identity
            
            // Reset border color
            self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
            
            // Reset shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.containerView.layer.shadowRadius = 8
            self.containerView.layer.shadowOpacity = 0.3
        }
    }
}