import UIKit

protocol EventCardViewDelegate: AnyObject {
    func didTapEventCard(_ event: CompetitionEvent)
    func didTapJoinButton(_ event: CompetitionEvent)
}

class EventCardView: UIView {
    
    // MARK: - Properties
    private let event: CompetitionEvent
    weak var delegate: EventCardViewDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let headerContainer = UIView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let prizeLabel = UILabel()
    private let detailsContainer = UIView()
    private let statsStackView = UIStackView()
    private let joinButton = UIButton(type: .custom)
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(event: CompetitionEvent) {
        self.event = event
        super.init(frame: .zero)
        setupView()
        setupConstraints()
        configureWithData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupView() {
        backgroundColor = UIColor.clear
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Add gradient background
        DispatchQueue.main.async {
            self.setupContainerGradient()
        }
        
        // Header container
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 2
        
        // Date label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        dateLabel.textColor = IndustrialDesign.Colors.secondaryText
        dateLabel.numberOfLines = 1
        
        // Prize label
        prizeLabel.translatesAutoresizingMaskIntoConstraints = false
        prizeLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        prizeLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        prizeLabel.textAlignment = .right
        prizeLabel.numberOfLines = 1
        
        // Details container
        detailsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Stats stack view
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.axis = .horizontal
        statsStackView.distribution = .fillEqually
        statsStackView.spacing = 16
        statsStackView.alignment = .center
        
        // Join button
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        joinButton.layer.cornerRadius = 6
        joinButton.addTarget(self, action: #selector(joinButtonTapped), for: .touchUpInside)
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 4
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(headerContainer)
        containerView.addSubview(detailsContainer)
        containerView.addSubview(joinButton)
        containerView.addSubview(boltDecoration)
        
        headerContainer.addSubview(titleLabel)
        headerContainer.addSubview(dateLabel)
        headerContainer.addSubview(prizeLabel)
        detailsContainer.addSubview(statsStackView)
        
        // Add tap gesture to container (excluding join button)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        containerView.addGestureRecognizer(tapGesture)
        
        setupHoverEffects()
        createStatViews()
    }
    
    private func createStatViews() {
        // Create three stat views
        let goalStat = createStatView(value: event.goalValue, label: getGoalLabel())
        let participantsStat = createStatView(value: event.formattedParticipants, label: "REGISTERED")
        let feeStat = createStatView(value: event.formattedEntryFee, label: "ENTRY FEE")
        
        statsStackView.addArrangedSubview(goalStat)
        statsStackView.addArrangedSubview(participantsStat)
        statsStackView.addArrangedSubview(feeStat)
    }
    
    private func createStatView(value: String, label: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        valueLabel.textColor = IndustrialDesign.Colors.primaryText
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 1
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = label
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = IndustrialDesign.Colors.secondaryText
        titleLabel.textAlignment = .center
        titleLabel.letterSpacing = 0.5
        titleLabel.numberOfLines = 1
        
        container.addSubview(valueLabel)
        container.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: container.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func getGoalLabel() -> String {
        switch event.eventType {
        case .marathon: return "KM GOAL"
        case .speed: return "FORMAT"
        case .elevation: return "ELEVATION"
        case .distance: return "MONTHLY GOAL"
        case .streak: return "STREAK TARGET"
        }
    }
    
    private func setupContainerGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = 12
        
        containerView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Header container
            headerContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            headerContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: prizeLabel.leadingAnchor, constant: -16),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: prizeLabel.leadingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            
            // Prize label
            prizeLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            prizeLabel.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            
            // Details container
            detailsContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 16),
            detailsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            detailsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Stats stack view
            statsStackView.topAnchor.constraint(equalTo: detailsContainer.topAnchor),
            statsStackView.leadingAnchor.constraint(equalTo: detailsContainer.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: detailsContainer.trailingAnchor),
            statsStackView.bottomAnchor.constraint(equalTo: detailsContainer.bottomAnchor),
            
            // Join button
            joinButton.topAnchor.constraint(equalTo: detailsContainer.bottomAnchor, constant: 16),
            joinButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            joinButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            joinButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            joinButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration.widthAnchor.constraint(equalToConstant: 8),
            boltDecoration.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    private func configureWithData() {
        titleLabel.text = event.title
        dateLabel.text = event.formattedDateRange
        prizeLabel.text = event.formattedPrizePool
        
        // Configure join button based on registration status
        if event.isRegistered {
            joinButton.setTitle("REGISTERED", for: .normal)
            joinButton.backgroundColor = UIColor.clear
            joinButton.layer.borderWidth = 1
            joinButton.layer.borderColor = IndustrialDesign.Colors.secondaryText.cgColor
            joinButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        } else {
            joinButton.setTitle("JOIN EVENT", for: .normal)
            joinButton.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
            joinButton.layer.borderWidth = 1
            joinButton.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
            joinButton.setTitleColor(IndustrialDesign.Colors.primaryText, for: .normal)
        }
        
        joinButton.titleLabel?.letterSpacing = 0.5
    }
    
    private func setupHoverEffects() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        longPressGesture.minimumPressDuration = 0
        containerView.addGestureRecognizer(longPressGesture)
        
        // Join button hover
        let buttonPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(joinButtonPressed(_:)))
        buttonPressGesture.minimumPressDuration = 0
        joinButton.addGestureRecognizer(buttonPressGesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update gradient frame
        if let gradientLayer = containerView.layer.sublayers?.first(where: { $0 is CAGradientLayer }) as? CAGradientLayer {
            gradientLayer.frame = containerView.bounds
        }
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        // Tap feedback animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        delegate?.didTapEventCard(event)
        print("🏆 RunstrRewards: Event card tapped: \(event.title)")
    }
    
    @objc private func joinButtonTapped() {
        // Button tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.joinButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.joinButton.transform = .identity
            }
        }
        
        delegate?.didTapJoinButton(event)
        print("🏆 RunstrRewards: Join button tapped for event: \(event.title)")
    }
    
    @objc private func cardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.2) { [self] in
                self.transform = CGAffineTransform(translationX: 0, y: -4)
                self.containerView.layer.borderColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 8)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 24
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) { [self] in
                self.transform = .identity
                self.containerView.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
                self.layer.shadowOpacity = 0
            }
        default:
            break
        }
    }
    
    @objc private func joinButtonPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.1) {
                self.joinButton.alpha = 0.7
                self.joinButton.transform = CGAffineTransform(translationX: 0, y: -2)
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) {
                self.joinButton.alpha = 1.0
                self.joinButton.transform = .identity
            }
        default:
            break
        }
    }
}