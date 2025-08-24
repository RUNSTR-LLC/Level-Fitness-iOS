import UIKit

protocol ProfileSyncSourcesViewDelegate: AnyObject {
    func didTapSyncSource(_ source: String)
}

class ProfileSyncSourcesView: UIView {
    
    // MARK: - Properties
    weak var delegate: ProfileSyncSourcesViewDelegate?
    private var syncSources: [ProfileSyncSourceData] = []
    
    // MARK: - UI Components
    private let containerView = UIView()
    private var gradientLayer: CAGradientLayer?
    private let titleLabel = UILabel()
    private let sourcesGridContainer = UIView()
    private var sourceCards: [String: SyncSourceCard] = [:]
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupSyncSources()
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
        titleLabel.text = "AUTO-SYNC SOURCES"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.accentText
        titleLabel.letterSpacing = 1
        
        // Sources grid container
        sourcesGridContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 3
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(sourcesGridContainer)
        containerView.addSubview(boltDecoration)
    }
    
    private func setupSyncSources() {
        // Define sync sources - only HealthKit and Garmin
        let sources = [
            ProfileSyncSourceData(name: "HealthKit", icon: "heart.fill", isConnected: false, lastSync: nil),
            ProfileSyncSourceData(name: "Garmin", icon: "waveform.path.ecg", isConnected: false, lastSync: nil)
        ]
        
        syncSources = sources
        
        // Create cards in 2x2 grid
        let spacing: CGFloat = 12
        
        for (index, source) in sources.enumerated() {
            let card = SyncSourceCard(source: source)
            card.translatesAutoresizingMaskIntoConstraints = false
            card.addTarget(self, action: #selector(syncSourceTapped(_:)), for: .touchUpInside)
            card.tag = index
            
            sourcesGridContainer.addSubview(card)
            sourceCards[source.name] = card
            
            // Position in grid
            let row = index / 2
            let col = index % 2
            
            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            if col == 0 {
                // Left column
                card.leadingAnchor.constraint(equalTo: sourcesGridContainer.leadingAnchor).isActive = true
                card.trailingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: -spacing/2).isActive = true
            } else {
                // Right column
                card.leadingAnchor.constraint(equalTo: sourcesGridContainer.centerXAnchor, constant: spacing/2).isActive = true
                card.trailingAnchor.constraint(equalTo: sourcesGridContainer.trailingAnchor).isActive = true
            }
            
            if row == 0 {
                // Top row
                card.topAnchor.constraint(equalTo: sourcesGridContainer.topAnchor).isActive = true
            } else {
                // Bottom row
                card.topAnchor.constraint(equalTo: sourcesGridContainer.topAnchor, constant: 60 + spacing).isActive = true
            }
        }
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
            
            // Sources grid
            sourcesGridContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            sourcesGridContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            sourcesGridContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sourcesGridContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            boltDecoration.widthAnchor.constraint(equalToConstant: 6),
            boltDecoration.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    // MARK: - Public Methods
    
    func loadSyncStates() {
        print("👤 Sync Sources: Loading sync states")
        
        // Check HealthKit authorization
        Task {
            let healthKitAuthorized = HealthKitService.shared.checkAuthorizationStatus()
            await MainActor.run {
                if let card = sourceCards["HealthKit"] {
                    card.updateConnectionStatus(healthKitAuthorized, lastSync: healthKitAuthorized ? Date() : nil)
                }
            }
        }
        
        // Other sources remain disconnected for now
    }
    
    func updateSyncState(for source: String, isConnected: Bool, lastSync: Date?) {
        if let card = sourceCards[source] {
            card.updateConnectionStatus(isConnected, lastSync: lastSync)
        }
    }
    
    // MARK: - Actions
    
    @objc private func syncSourceTapped(_ sender: UIButton) {
        guard sender.tag < syncSources.count else { return }
        let source = syncSources[sender.tag]
        
        print("👤 Sync Sources: Tapped \(source.name)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        delegate?.didTapSyncSource(source.name)
    }
}

// MARK: - SyncSourceCard

class SyncSourceCard: UIButton {
    
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let statusIndicator = UIView()
    private var source: ProfileSyncSourceData
    
    init(source: ProfileSyncSourceData) {
        self.source = source
        super.init(frame: .zero)
        setupCard()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCard() {
        backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        
        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: source.icon)
        iconImageView.tintColor = source.isConnected ? IndustrialDesign.Colors.accentText : IndustrialDesign.Colors.secondaryText
        iconImageView.contentMode = .scaleAspectFit
        
        // Name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = source.name
        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        // Status indicator
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.backgroundColor = source.isConnected ? UIColor.white : UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        statusIndicator.layer.cornerRadius = 3
        
        addSubview(iconImageView)
        addSubview(nameLabel)
        addSubview(statusIndicator)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusIndicator.leadingAnchor, constant: -8),
            
            statusIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 6),
            statusIndicator.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func updateConnectionStatus(_ isConnected: Bool, lastSync: Date?) {
        source.isConnected = isConnected
        source.lastSync = lastSync
        
        iconImageView.tintColor = isConnected ? IndustrialDesign.Colors.accentText : IndustrialDesign.Colors.secondaryText
        statusIndicator.backgroundColor = isConnected ? UIColor.white : UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        
        if isConnected {
            layer.borderColor = IndustrialDesign.Colors.accentText.withAlphaComponent(0.3).cgColor
        } else {
            layer.borderColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0).cgColor
        }
    }
}

// MARK: - SyncSourceData Model

struct ProfileSyncSourceData {
    let name: String
    let icon: String
    var isConnected: Bool
    var lastSync: Date?
}