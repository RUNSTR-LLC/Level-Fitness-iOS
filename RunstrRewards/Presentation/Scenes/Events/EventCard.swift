import UIKit

struct EventCardData {
    let title: String
    let date: String
    let prize: String
    let participants: String
    let entry: String
    let description: String
    let eventId: String? // Add eventId for navigation
}

protocol EventCardDelegate: AnyObject {
    func eventCardDidTap(_ card: EventCard, eventId: String?)
}

class EventCard: UIView {
    
    // MARK: - Properties
    weak var delegate: EventCardDelegate?
    private let eventData: EventCardData
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let boltDecoration = UIView()
    private var gradientLayer: CAGradientLayer?
    
    // Header section
    private let headerSection = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let prizeLabel = UILabel()
    
    // Info section
    private let infoSection = UIView()
    private let participantsLabel = UILabel()
    private let entryLabel = UILabel()
    
    // MARK: - Initialization
    init(eventData: EventCardData) {
        self.eventData = eventData
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
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 1
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.numberOfLines = 1
        
        // Prize label
        prizeLabel.translatesAutoresizingMaskIntoConstraints = false
        prizeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        prizeLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.1, alpha: 1.0) // Bitcoin orange
        
        headerSection.addSubview(titleLabel)
        headerSection.addSubview(dateLabel)
        headerSection.addSubview(prizeLabel)
        
        // Info section
        infoSection.translatesAutoresizingMaskIntoConstraints = false
        
        // Participants label
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        participantsLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        participantsLabel.textColor = IndustrialDesign.Colors.secondaryText
        
        // Entry label
        entryLabel.translatesAutoresizingMaskIntoConstraints = false
        entryLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        entryLabel.textColor = IndustrialDesign.Colors.secondaryText
        entryLabel.textAlignment = .right
        
        infoSection.addSubview(participantsLabel)
        infoSection.addSubview(entryLabel)
        
        containerView.addSubview(headerSection)
        containerView.addSubview(infoSection)
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
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: headerSection.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: prizeLabel.leadingAnchor, constant: -IndustrialDesign.Spacing.medium),
            dateLabel.bottomAnchor.constraint(equalTo: headerSection.bottomAnchor),
            
            prizeLabel.centerYAnchor.constraint(equalTo: headerSection.centerYAnchor),
            prizeLabel.trailingAnchor.constraint(equalTo: headerSection.trailingAnchor),
            
            // Info section
            infoSection.topAnchor.constraint(equalTo: headerSection.bottomAnchor, constant: IndustrialDesign.Spacing.medium),
            infoSection.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: IndustrialDesign.Spacing.large),
            infoSection.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -IndustrialDesign.Spacing.large),
            infoSection.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -IndustrialDesign.Spacing.large),
            infoSection.heightAnchor.constraint(equalToConstant: 20),
            
            // Info labels
            participantsLabel.leadingAnchor.constraint(equalTo: infoSection.leadingAnchor),
            participantsLabel.centerYAnchor.constraint(equalTo: infoSection.centerYAnchor),
            
            entryLabel.trailingAnchor.constraint(equalTo: infoSection.trailingAnchor),
            entryLabel.centerYAnchor.constraint(equalTo: infoSection.centerYAnchor)
        ])
    }
    
    private func setupInteractions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    private func updateContent() {
        titleLabel.text = eventData.title
        dateLabel.text = eventData.date.uppercased()
        prizeLabel.text = eventData.prize
        participantsLabel.text = eventData.participants
        entryLabel.text = eventData.entry
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        print("🏗️ RunstrRewards: Event card tapped: \(eventData.title)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Animation
        animateTap()
        
        // Notify delegate of tap
        delegate?.eventCardDidTap(self, eventId: eventData.eventId)
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