import UIKit

class EventPresetSelectionViewController: UIViewController {
    
    // MARK: - Properties
    private let eventData: EventCreationData
    private let teamData: TeamData
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Title section
    private let stepTitleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Preset cards container
    private let presetContainer = UIView()
    private var presetCards: [PresetCard] = []
    
    // MARK: - Initialization
    
    init(eventData: EventCreationData, teamData: TeamData) {
        self.eventData = eventData
        self.teamData = teamData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🏃 EventPresetSelection: Loading preset selection step")
        
        setupScrollView()
        setupContent()
        setupConstraints()
        
        print("🏃 EventPresetSelection: Preset selection step loaded")
    }
    
    // MARK: - Setup Methods
    
    private func setupScrollView() {
        view.backgroundColor = .clear
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupContent() {
        setupTitleSection()
        setupPresetCards()
    }
    
    private func setupTitleSection() {
        stepTitleLabel.text = "Choose Distance"
        stepTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        stepTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        stepTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel.text = "Select the running distance for your event"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = IndustrialDesign.Colors.secondaryText
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stepTitleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupPresetCards() {
        presetContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(presetContainer)
        
        // Create preset cards
        for preset in RunningPreset.allCases {
            let card = PresetCard(preset: preset)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.addTarget(self, action: #selector(presetSelected(_:)), for: .touchUpInside)
            presetCards.append(card)
            presetContainer.addSubview(card)
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title section
            stepTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            stepTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stepTitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: stepTitleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Preset container
            presetContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            presetContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            presetContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            presetContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            presetContainer.heightAnchor.constraint(equalToConstant: 240)
        ])
        
        // Layout preset cards vertically
        layoutPresetCards()
    }
    
    private func layoutPresetCards() {
        guard !presetCards.isEmpty else { return }
        
        let cardHeight: CGFloat = 70
        let spacing: CGFloat = 12
        
        for (index, card) in presetCards.enumerated() {
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: presetContainer.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: presetContainer.trailingAnchor),
                card.heightAnchor.constraint(equalToConstant: cardHeight),
                card.topAnchor.constraint(equalTo: presetContainer.topAnchor, constant: CGFloat(index) * (cardHeight + spacing))
            ])
        }
    }
    
    // MARK: - Actions
    
    @objc private func presetSelected(_ card: PresetCard) {
        print("🏃 EventPresetSelection: Preset selected: \(card.preset.displayName)")
        
        // Update event data with preset values
        eventData.selectedPreset = card.preset
        eventData.eventName = card.preset.displayName
        eventData.eventType = .challenge
        eventData.selectedMetrics = card.preset.metrics
        eventData.targetValue = card.preset.distance
        eventData.targetUnit = card.preset.unit
        
        // Visual feedback
        selectPreset(card)
        
        // Notify parent that selection was made
        if let parent = parent as? EventCreationWizardViewController {
            // Let the wizard know to proceed to next step
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                parent.presetSelectionCompleted()
            }
        }
    }
    
    private func selectPreset(_ selectedCard: PresetCard) {
        // Deselect all cards
        for card in presetCards {
            card.isSelected = false
        }
        
        // Select the chosen card
        selectedCard.isSelected = true
    }
}

// MARK: - PresetCard

class PresetCard: UIButton {
    
    let preset: RunningPreset
    private let customTitleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let iconImageView = UIImageView()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    init(preset: RunningPreset) {
        self.preset = preset
        super.init(frame: .zero)
        setupCard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCard() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        
        // Icon
        iconImageView.image = UIImage(systemName: "figure.run")
        iconImageView.tintColor = IndustrialDesign.Colors.bitcoin
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        customTitleLabel.text = preset.displayName
        customTitleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        customTitleLabel.textColor = IndustrialDesign.Colors.primaryText
        customTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Distance
        distanceLabel.text = "\(preset.distance) \(preset.unit)"
        distanceLabel.font = UIFont.systemFont(ofSize: 14)
        distanceLabel.textColor = IndustrialDesign.Colors.secondaryText
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(iconImageView)
        addSubview(customTitleLabel)
        addSubview(distanceLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            customTitleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            customTitleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            customTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
            
            distanceLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            distanceLabel.topAnchor.constraint(equalTo: customTitleLabel.bottomAnchor, constant: 4),
            distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
        
        updateAppearance()
        
        // Add tap animation
        addTarget(self, action: #selector(cardTapped), for: .touchDown)
        addTarget(self, action: #selector(cardReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func updateAppearance() {
        if isSelected {
            backgroundColor = IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.2)
            layer.borderColor = IndustrialDesign.Colors.bitcoin.cgColor
            layer.borderWidth = 2
        } else {
            backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
            layer.borderWidth = 1
        }
    }
    
    @objc private func cardTapped() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func cardReleased() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform.identity
        }
    }
}