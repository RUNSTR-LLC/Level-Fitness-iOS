import UIKit

protocol ChallengeCardDelegate: AnyObject {
    func didTapChallengeCard(_ challengeData: ChallengeData)
}


class ChallengeCard: UIView {
    
    // MARK: - Properties
    weak var delegate: ChallengeCardDelegate?
    private let challengeData: ChallengeData
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Header section
    private let headerSection = UIView()
    private let titleLabel = UILabel()
    private let typeLabel = UILabel()
    private let prizeLabel = UILabel()
    
    // Progress section
    private let progressSection = UIView()
    private let progressBarBackground = UIView()
    private let progressBarFill = UIView()
    private let progressTextLabel = UILabel()
    private let timeLeftLabel = UILabel()
    
    // MARK: - Initialization
    init(challengeData: ChallengeData) {
        self.challengeData = challengeData
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
        
        // Update progress bar width
        let progressWidth = progressBarBackground.frame.width * CGFloat(challengeData.progress)
        progressBarFill.frame = CGRect(
            x: 0,
            y: 0,
            width: progressWidth,
            height: progressBarBackground.frame.height
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
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        // Type label
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        typeLabel.textColor = IndustrialDesign.Colors.secondaryText
        typeLabel.numberOfLines = 1
        
        // Prize label
        prizeLabel.translatesAutoresizingMaskIntoConstraints = false
        prizeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        prizeLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.1, alpha: 1.0) // Bitcoin orange
        
        headerSection.addSubview(titleLabel)
        headerSection.addSubview(typeLabel)
        headerSection.addSubview(prizeLabel)
        
        // Progress section
        progressSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress bar background
        progressBarBackground.translatesAutoresizingMaskIntoConstraints = false
        progressBarBackground.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        progressBarBackground.layer.cornerRadius = 2
        
        // Progress bar fill
        progressBarFill.backgroundColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        progressBarFill.layer.cornerRadius = 2
        
        // Progress text
        progressTextLabel.translatesAutoresizingMaskIntoConstraints = false
        progressTextLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        progressTextLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Time left
        timeLeftLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLeftLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        timeLeftLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeLeftLabel.textAlignment = .right
        
        progressBarBackground.addSubview(progressBarFill)
        progressSection.addSubview(progressBarBackground)
        progressSection.addSubview(progressTextLabel)
        progressSection.addSubview(timeLeftLabel)
        
        containerView.addSubview(headerSection)
        containerView.addSubview(progressSection)
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
            headerSection.heightAnchor.constraint(equalToConstant: 44),
            
            // Header elements
            titleLabel.topAnchor.constraint(equalTo: headerSection.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: prizeLabel.leadingAnchor, constant: -IndustrialDesign.Spacing.medium),
            
            typeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            typeLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            typeLabel.trailingAnchor.constraint(lessThanOrEqualTo: prizeLabel.leadingAnchor, constant: -IndustrialDesign.Spacing.medium),
            typeLabel.bottomAnchor.constraint(equalTo: headerSection.bottomAnchor),
            
            prizeLabel.centerYAnchor.constraint(equalTo: headerSection.centerYAnchor),
            prizeLabel.trailingAnchor.constraint(equalTo: headerSection.trailingAnchor),
            
            // Progress section
            progressSection.topAnchor.constraint(equalTo: headerSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            progressSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
            progressSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            progressSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large),
            progressSection.heightAnchor.constraint(equalToConstant: 32),
            
            // Progress bar
            progressBarBackground.topAnchor.constraint(equalTo: progressSection.topAnchor),
            progressBarBackground.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
            progressBarBackground.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
            progressBarBackground.heightAnchor.constraint(equalToConstant: 4),
            
            // Progress labels
            progressTextLabel.topAnchor.constraint(equalTo: progressBarBackground.bottomAnchor, constant: 8),
            progressTextLabel.leadingAnchor.constraint(equalTo: progressSection.leadingAnchor),
            progressTextLabel.bottomAnchor.constraint(equalTo: progressSection.bottomAnchor),
            
            timeLeftLabel.topAnchor.constraint(equalTo: progressBarBackground.bottomAnchor, constant: 8),
            timeLeftLabel.trailingAnchor.constraint(equalTo: progressSection.trailingAnchor),
            timeLeftLabel.bottomAnchor.constraint(equalTo: progressSection.bottomAnchor)
        ])
    }
    
    private func setupInteractions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func updateContent() {
        titleLabel.text = challengeData.title
        typeLabel.text = challengeData.type.uppercased()
        prizeLabel.text = challengeData.prize
        progressTextLabel.text = challengeData.progressText
        timeLeftLabel.text = challengeData.timeLeft
        
        // Progress will be updated in layoutSubviews
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        print("🏗️ RunstrRewards: Challenge card tapped: \(challengeData.title)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animation
        animateTap()
        
        // Call delegate
        delegate?.didTapChallengeCard(challengeData)
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
            
            // Reset border color
            self.containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
            
            // Reset shadow
            self.containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
            self.containerView.layer.shadowRadius = 8
            self.containerView.layer.shadowOpacity = 0.3
        }
    }
}