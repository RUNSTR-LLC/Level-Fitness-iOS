import UIKit

enum SyncSourceType {
    case healthKit
    case garmin
    case googleFit
    
    var displayName: String {
        switch self {
        case .healthKit: return "HealthKit"
        case .garmin: return "Garmin"
        case .googleFit: return "Google Fit"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .healthKit: return "heart.fill"
        case .garmin: return "location.fill"
        case .googleFit: return "plus.circle.fill"
        }
    }
    
    var connectedColor: UIColor {
        return UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // #f7931a - Bitcoin orange
    }
    
    var disconnectedColor: UIColor {
        return IndustrialDesign.Colors.secondaryText
    }
}

struct SyncSourceData {
    let id: String
    let type: SyncSourceType
    let isConnected: Bool
    let lastSync: Date?
    let workoutCount: Int
    let isComingSoon: Bool
    
    var statusText: String {
        if isComingSoon {
            return "Coming Soon"
        }
        return isConnected ? "Connected" : "Not Connected"
    }
    
    var statusColor: UIColor {
        if isComingSoon {
            return UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // Gray for coming soon
        }
        return isConnected ? type.connectedColor : type.disconnectedColor
    }
}

protocol WorkoutSyncSourceCardDelegate: AnyObject {
    func didTapSyncSource(_ source: SyncSourceData)
}

class WorkoutSyncSourceCard: UIView {
    
    // MARK: - Properties
    private let sourceData: SyncSourceData
    weak var delegate: WorkoutSyncSourceCardDelegate?
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconContainer = UIView()
    private let iconImageView = UIImageView()
    private let infoContainer = UIView()
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let boltDecoration = UIView()
    
    // MARK: - Initialization
    
    init(sourceData: SyncSourceData) {
        self.sourceData = sourceData
        super.init(frame: .zero)
        setupCard()
        setupConstraints()
        configureWithData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupCard() {
        backgroundColor = UIColor.clear
        
        // Container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.5)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        
        // Icon container
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        iconContainer.layer.cornerRadius = 16
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0).cgColor
        
        // Icon image
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
        
        // Info container
        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Name label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = IndustrialDesign.Colors.primaryText
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byTruncatingTail
        
        // Bolt decoration
        boltDecoration.translatesAutoresizingMaskIntoConstraints = false
        boltDecoration.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0)
        boltDecoration.layer.cornerRadius = 2
        boltDecoration.layer.borderWidth = 1
        boltDecoration.layer.borderColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0).cgColor
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(iconContainer)
        containerView.addSubview(infoContainer)
        containerView.addSubview(boltDecoration)
        
        iconContainer.addSubview(iconImageView)
        infoContainer.addSubview(nameLabel)
        infoContainer.addSubview(statusLabel)
        
        setupHoverEffects()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 70),
            
            // Icon container
            iconContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 32),
            iconContainer.heightAnchor.constraint(equalToConstant: 32),
            
            // Icon image
            iconImageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),
            
            // Info container
            infoContainer.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            infoContainer.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            infoContainer.trailingAnchor.constraint(lessThanOrEqualTo: boltDecoration.leadingAnchor, constant: -8),
            
            // Name label
            nameLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            
            // Status label
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
            
            // Bolt decoration
            boltDecoration.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            boltDecoration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            boltDecoration.widthAnchor.constraint(equalToConstant: 4),
            boltDecoration.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    private func configureWithData() {
        nameLabel.text = sourceData.type.displayName
        statusLabel.text = sourceData.statusText
        statusLabel.textColor = sourceData.statusColor
        iconImageView.image = UIImage(systemName: sourceData.type.systemIcon)
        
        // Update icon and border colors based on connection status
        if sourceData.isComingSoon {
            iconImageView.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            containerView.layer.borderColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.3).cgColor
            containerView.backgroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.05)
        } else if sourceData.isConnected {
            iconImageView.tintColor = sourceData.type.connectedColor
            containerView.layer.borderColor = sourceData.type.connectedColor.withAlphaComponent(0.3).cgColor
            containerView.backgroundColor = sourceData.type.connectedColor.withAlphaComponent(0.05)
        } else {
            iconImageView.tintColor = IndustrialDesign.Colors.secondaryText
            containerView.layer.borderColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
            containerView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.5)
        }
    }
    
    private func setupHoverEffects() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        addGestureRecognizer(tapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(cardPressed(_:)))
        addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Actions
    
    @objc private func cardTapped() {
        // Don't allow tapping coming soon sources
        if sourceData.isComingSoon {
            // Show subtle feedback that it's not available yet
            UIView.animate(withDuration: 0.1, animations: {
                self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                }
            }
            print("🏃‍♂️ LevelFitness: Coming soon source tapped: \(sourceData.type.displayName)")
            return
        }
        
        // Animation for tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
        
        delegate?.didTapSyncSource(sourceData)
        print("🏃‍♂️ LevelFitness: Sync source tapped: \(sourceData.type.displayName)")
    }
    
    @objc private func cardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.2) { [self] in
                self.transform = CGAffineTransform(translationX: 0, y: -2)
                self.containerView.layer.borderColor = sourceData.isConnected ? 
                    sourceData.type.connectedColor.cgColor : 
                    UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0).cgColor
                self.layer.shadowColor = UIColor.black.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 4)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 8
            }
        case .ended, .cancelled:
            UIView.animate(withDuration: 0.2) { [self] in
                self.transform = .identity
                self.containerView.layer.borderColor = sourceData.isConnected ?
                    sourceData.type.connectedColor.withAlphaComponent(0.3).cgColor :
                    UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
                self.layer.shadowOpacity = 0
            }
        default:
            break
        }
    }
}