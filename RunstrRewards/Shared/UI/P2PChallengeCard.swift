import UIKit

protocol P2PChallengeCardDelegate: AnyObject {
    func didTapP2PChallengeCard(_ challengeData: P2PChallengeWithParticipants)
    func didTapAcceptChallenge(_ challengeData: P2PChallengeWithParticipants)
    func didTapDeclineChallenge(_ challengeData: P2PChallengeWithParticipants)
}

class P2PChallengeCard: UIView {
    
    // MARK: - Properties
    weak var delegate: P2PChallengeCardDelegate?
    private let challengeData: P2PChallengeWithParticipants
    private let currentUserId: String
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Header section
    private let headerSection = UIView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let stakeLabel = UILabel()
    private let statusLabel = UILabel()
    
    // Participants section
    private let participantsSection = UIView()
    private let challengerCard = UIView()
    private let challengedCard = UIView()
    private let vsLabel = UILabel()
    
    // Progress section (for active challenges)
    private let progressSection = UIView()
    private let challengerProgress = UIProgressView()
    private let challengedProgress = UIProgressView()
    private let timeRemainingLabel = UILabel()
    
    // Action buttons (for pending challenges)
    private let actionButtonsSection = UIView()
    private let acceptButton = UIButton(type: .custom)
    private let declineButton = UIButton(type: .custom)
    
    // MARK: - Initialization
    init(challengeData: P2PChallengeWithParticipants, currentUserId: String) {
        self.challengeData = challengeData
        self.currentUserId = currentUserId
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
        
        // Dynamic border color based on challenge status
        switch challengeData.challenge.status {
        case .pending:
            containerView.layer.borderColor = UIColor.systemOrange.cgColor
        case .active:
            containerView.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        case .completed:
            containerView.layer.borderColor = UIColor.systemGreen.cgColor
        default:
            containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        }
        
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
        
        addSubview(containerView)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupContent() {
        // Header section
        headerSection.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        typeLabel.textColor = IndustrialDesign.Colors.secondaryText
        typeLabel.numberOfLines = 1
        
        stakeLabel.translatesAutoresizingMaskIntoConstraints = false
        stakeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        stakeLabel.textColor = IndustrialDesign.Colors.bitcoin
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 8
        statusLabel.layer.masksToBounds = true
        statusLabel.backgroundColor = UIColor.systemOrange
        statusLabel.textColor = .white
        
        [titleLabel, typeLabel, stakeLabel, statusLabel].forEach {
            headerSection.addSubview($0)
        }
        
        // Participants section
        participantsSection.translatesAutoresizingMaskIntoConstraints = false
        
        setupParticipantCard(challengerCard, participant: challengeData.challenger, isChallenger: true)
        setupParticipantCard(challengedCard, participant: challengeData.challenged, isChallenger: false)
        
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        vsLabel.text = "VS"
        vsLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        vsLabel.textColor = IndustrialDesign.Colors.primaryText
        vsLabel.textAlignment = .center
        
        [challengerCard, vsLabel, challengedCard].forEach {
            participantsSection.addSubview($0)
        }
        
        // Progress section (for active challenges)
        progressSection.translatesAutoresizingMaskIntoConstraints = false
        
        challengerProgress.translatesAutoresizingMaskIntoConstraints = false
        challengerProgress.progressTintColor = IndustrialDesign.Colors.bitcoin
        challengerProgress.trackTintColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        challengerProgress.layer.cornerRadius = 2
        challengerProgress.layer.masksToBounds = true
        
        challengedProgress.translatesAutoresizingMaskIntoConstraints = false
        challengedProgress.progressTintColor = UIColor.systemBlue
        challengedProgress.trackTintColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0)
        challengedProgress.layer.cornerRadius = 2
        challengedProgress.layer.masksToBounds = true
        
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        timeRemainingLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeRemainingLabel.textAlignment = .center
        
        [challengerProgress, challengedProgress, timeRemainingLabel].forEach {
            progressSection.addSubview($0)
        }
        
        // Action buttons section (for pending challenges)
        actionButtonsSection.translatesAutoresizingMaskIntoConstraints = false
        
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.setTitleColor(.black, for: .normal)
        acceptButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        acceptButton.layer.cornerRadius = 6
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        acceptButton.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        declineButton.backgroundColor = .clear
        declineButton.layer.cornerRadius = 6
        declineButton.layer.borderWidth = 1
        declineButton.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        declineButton.addTarget(self, action: #selector(declineButtonTapped), for: .touchUpInside)
        
        [acceptButton, declineButton].forEach {
            actionButtonsSection.addSubview($0)
        }
        
        [headerSection, participantsSection, progressSection, actionButtonsSection].forEach {
            containerView.addSubview($0)
        }
    }
    
    private func setupParticipantCard(_ card: UIView, participant: P2PChallengeParticipant, isChallenger: Bool) {
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.8)
        card.layer.cornerRadius = 8
        card.layer.borderWidth = 1
        
        // Highlight current user
        let isCurrentUser = participant.userId == currentUserId
        if isCurrentUser {
            card.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
        } else {
            card.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        }
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = participant.username
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: isCurrentUser ? .bold : .medium)
        nameLabel.textColor = isCurrentUser ? IndustrialDesign.Colors.bitcoin : IndustrialDesign.Colors.primaryText
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        
        let progressLabel = UILabel()
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.text = participant.displayProgress
        progressLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        progressLabel.textColor = IndustrialDesign.Colors.secondaryText
        progressLabel.textAlignment = .center
        
        card.addSubview(nameLabel)
        card.addSubview(progressLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            
            progressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            progressLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            progressLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            progressLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8)
        ])
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
            headerSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32), // Space for bolt
            headerSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            headerSection.heightAnchor.constraint(equalToConstant: 60),
            
            // Header elements
            titleLabel.topAnchor.constraint(equalTo: headerSection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: stakeLabel.leadingAnchor, constant: -8),
            
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            typeLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            typeLabel.trailingAnchor.constraint(lessThanOrEqualTo: stakeLabel.leadingAnchor, constant: -8),
            
            stakeLabel.topAnchor.constraint(equalTo: headerSection.topAnchor),
            stakeLabel.trailingAnchor.constraint(equalTo: headerSection.trailingAnchor),
            
            statusLabel.topAnchor.constraint(equalTo: stakeLabel.bottomAnchor, constant: 4),
            statusLabel.trailingAnchor.constraint(equalTo: headerSection.trailingAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 70),
            statusLabel.heightAnchor.constraint(equalToConstant: 16),
            
            // Participants section
            participantsSection.topAnchor.constraint(equalTo: headerSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            participantsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
            participantsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            participantsSection.heightAnchor.constraint(equalToConstant: 50),
            
            challengerCard.leadingAnchor.constraint(equalTo: participantsSection.leadingAnchor),
            challengerCard.topAnchor.constraint(equalTo: participantsSection.topAnchor),
            challengerCard.bottomAnchor.constraint(equalTo: participantsSection.bottomAnchor),
            challengerCard.widthAnchor.constraint(equalTo: participantsSection.widthAnchor, multiplier: 0.4),
            
            vsLabel.centerXAnchor.constraint(equalTo: participantsSection.centerXAnchor),
            vsLabel.centerYAnchor.constraint(equalTo: participantsSection.centerYAnchor),
            vsLabel.widthAnchor.constraint(equalToConstant: 30),
            
            challengedCard.trailingAnchor.constraint(equalTo: participantsSection.trailingAnchor),
            challengedCard.topAnchor.constraint(equalTo: participantsSection.topAnchor),
            challengedCard.bottomAnchor.constraint(equalTo: participantsSection.bottomAnchor),
            challengedCard.widthAnchor.constraint(equalTo: participantsSection.widthAnchor, multiplier: 0.4),
        ])
        
        // Dynamic constraints based on challenge status
        if challengeData.challenge.status == .active {
            // Show progress section
            NSLayoutConstraint.activate([
                progressSection.topAnchor.constraint(equalTo: participantsSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
                progressSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
                progressSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
                progressSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large),
                progressSection.heightAnchor.constraint(equalToConstant: 40),
                
                challengerProgress.topAnchor.constraint(equalTo: progressSection.topAnchor),
                challengerProgress.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
                challengerProgress.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
                challengerProgress.heightAnchor.constraint(equalToConstant: 6),
                
                challengedProgress.topAnchor.constraint(equalTo: challengerProgress.bottomAnchor, constant: 4),
                challengedProgress.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
                challengedProgress.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
                challengedProgress.heightAnchor.constraint(equalToConstant: 6),
                
                timeRemainingLabel.topAnchor.constraint(equalTo: challengedProgress.bottomAnchor, constant: 8),
                timeRemainingLabel.centerXAnchor.constraint(equalTo: progressSection.centerXAnchor),
                timeRemainingLabel.bottomAnchor.constraint(equalTo: progressSection.bottomAnchor)
            ])
        } else if challengeData.challenge.status == .pending && challengeData.challenged.userId == currentUserId {
            // Show action buttons for the challenged user
            NSLayoutConstraint.activate([
                actionButtonsSection.topAnchor.constraint(equalTo: participantsSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
                actionButtonsSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
                actionButtonsSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
                actionButtonsSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large),
                actionButtonsSection.heightAnchor.constraint(equalToConstant: 35),
                
                acceptButton.leadingAnchor.constraint(equalTo: actionButtonsSection.leadingAnchor),
                acceptButton.topAnchor.constraint(equalTo: actionButtonsSection.topAnchor),
                acceptButton.bottomAnchor.constraint(equalTo: actionButtonsSection.bottomAnchor),
                acceptButton.widthAnchor.constraint(equalTo: actionButtonsSection.widthAnchor, multiplier: 0.48),
                
                declineButton.trailingAnchor.constraint(equalTo: actionButtonsSection.trailingAnchor),
                declineButton.topAnchor.constraint(equalTo: actionButtonsSection.topAnchor),
                declineButton.bottomAnchor.constraint(equalTo: actionButtonsSection.bottomAnchor),
                declineButton.widthAnchor.constraint(equalTo: actionButtonsSection.widthAnchor, multiplier: 0.48)
            ])
        } else {
            // No additional section, close at participants
            participantsSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large).isActive = true
        }
    }
    
    private func setupInteractions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func updateContent() {
        // Header content
        titleLabel.text = challengeData.challenge.challengeType.displayName
        typeLabel.text = challengeData.challenge.challengeType.description.uppercased()
        stakeLabel.text = "\(challengeData.challenge.entryFee * 2) sats" // Total prize pool
        
        // Status
        statusLabel.text = challengeData.challenge.status.displayName.uppercased()
        switch challengeData.challenge.status {
        case .pending:
            statusLabel.backgroundColor = UIColor.systemOrange
        case .active:
            statusLabel.backgroundColor = IndustrialDesign.Colors.bitcoin
        case .completed:
            statusLabel.backgroundColor = UIColor.systemGreen
        default:
            statusLabel.backgroundColor = UIColor.systemGray
        }
        
        // Progress bars (for active challenges)
        if challengeData.challenge.status == .active,
           let challengerProgress = challengeData.challenger.progress,
           let challengedProgress = challengeData.challenged.progress {
            
            let maxValue = max(challengerProgress.currentValue, challengedProgress.currentValue, challengeData.challenge.conditions.targetValue)
            
            if maxValue > 0 {
                self.challengerProgress.setProgress(Float(challengerProgress.currentValue / maxValue), animated: true)
                self.challengedProgress.setProgress(Float(challengedProgress.currentValue / maxValue), animated: true)
            }
        }
        
        // Time remaining
        timeRemainingLabel.text = challengeData.timeRemaining
        
        // Show/hide sections based on status and user
        progressSection.isHidden = challengeData.challenge.status != .active
        actionButtonsSection.isHidden = !(challengeData.challenge.status == .pending && challengeData.challenged.userId == currentUserId)
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        print("🥊 P2PChallengeCard: Card tapped for challenge \(challengeData.challenge.id)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animation
        animateTap()
        
        // Call delegate
        delegate?.didTapP2PChallengeCard(challengeData)
    }
    
    @objc private func acceptButtonTapped() {
        print("✅ P2PChallengeCard: Accept button tapped for challenge \(challengeData.challenge.id)")
        delegate?.didTapAcceptChallenge(challengeData)
    }
    
    @objc private func declineButtonTapped() {
        print("❌ P2PChallengeCard: Decline button tapped for challenge \(challengeData.challenge.id)")
        delegate?.didTapDeclineChallenge(challengeData)
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
        animateToHoverState()
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
            
            // Reset border color based on status
            switch self.challengeData.challenge.status {
            case .pending:
                self.containerView.layer.borderColor = UIColor.systemOrange.cgColor
            case .active:
                self.containerView.layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            case .completed:
                self.containerView.layer.borderColor = UIColor.systemGreen.cgColor
            default:
                self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
            }
            
            // Reset shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.containerView.layer.shadowRadius = 8
            self.containerView.layer.shadowOpacity = 0.3
        }
    }
}