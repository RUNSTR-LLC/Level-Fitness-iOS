import UIKit

class EventManagementCell: UITableViewCell {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let eventNameLabel = UILabel()
    private let eventTypeLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()
    private let participantsLabel = UILabel()
    private let prizePoolLabel = UILabel()
    private let datesLabel = UILabel()
    private let participantsIcon = UIImageView()
    private let prizeIcon = UIImageView()
    private let calendarIcon = UIImageView()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container view
        containerView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(red: 0.17, green: 0.17, blue: 0.17, alpha: 1.0).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Event name
        eventNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        eventNameLabel.textColor = IndustrialDesign.Colors.primaryText
        eventNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Event type
        eventTypeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        eventTypeLabel.textColor = IndustrialDesign.Colors.accentText
        eventTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Status badge
        statusBadge.layer.cornerRadius = 8
        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Icons
        participantsIcon.image = UIImage(systemName: "person.3.fill")
        participantsIcon.tintColor = IndustrialDesign.Colors.secondaryText
        participantsIcon.contentMode = .scaleAspectFit
        participantsIcon.translatesAutoresizingMaskIntoConstraints = false
        
        prizeIcon.image = UIImage(systemName: "bitcoinsign.circle.fill")
        prizeIcon.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        prizeIcon.contentMode = .scaleAspectFit
        prizeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        calendarIcon.image = UIImage(systemName: "calendar.circle.fill")
        calendarIcon.tintColor = IndustrialDesign.Colors.secondaryText
        calendarIcon.contentMode = .scaleAspectFit
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Info labels
        participantsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        participantsLabel.textColor = IndustrialDesign.Colors.secondaryText
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        prizePoolLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        prizePoolLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        prizePoolLabel.translatesAutoresizingMaskIntoConstraints = false
        
        datesLabel.font = UIFont.systemFont(ofSize: 11)
        datesLabel.textColor = IndustrialDesign.Colors.secondaryText
        datesLabel.numberOfLines = 2
        datesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add bolt decoration
        let boltImageView = UIImageView(image: UIImage(systemName: "bolt.fill"))
        boltImageView.tintColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 0.3)
        boltImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        statusBadge.addSubview(statusLabel)
        
        containerView.addSubview(eventNameLabel)
        containerView.addSubview(eventTypeLabel)
        containerView.addSubview(statusBadge)
        containerView.addSubview(participantsIcon)
        containerView.addSubview(participantsLabel)
        containerView.addSubview(prizeIcon)
        containerView.addSubview(prizePoolLabel)
        containerView.addSubview(calendarIcon)
        containerView.addSubview(datesLabel)
        containerView.addSubview(boltImageView)
        
        contentView.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            boltImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            boltImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            boltImageView.widthAnchor.constraint(equalToConstant: 10),
            boltImageView.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container view
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Event name
            eventNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            eventNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            eventNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -12),
            
            // Event type
            eventTypeLabel.topAnchor.constraint(equalTo: eventNameLabel.bottomAnchor, constant: 2),
            eventTypeLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            // Status badge
            statusBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            statusBadge.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            statusBadge.widthAnchor.constraint(equalToConstant: 70),
            statusBadge.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            
            // Bottom row - participants
            participantsIcon.topAnchor.constraint(equalTo: eventTypeLabel.bottomAnchor, constant: 12),
            participantsIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            participantsIcon.widthAnchor.constraint(equalToConstant: 14),
            participantsIcon.heightAnchor.constraint(equalToConstant: 14),
            
            participantsLabel.centerYAnchor.constraint(equalTo: participantsIcon.centerYAnchor),
            participantsLabel.leadingAnchor.constraint(equalTo: participantsIcon.trailingAnchor, constant: 6),
            
            // Prize pool
            prizeIcon.centerYAnchor.constraint(equalTo: participantsIcon.centerYAnchor),
            prizeIcon.leadingAnchor.constraint(equalTo: participantsLabel.trailingAnchor, constant: 16),
            prizeIcon.widthAnchor.constraint(equalToConstant: 14),
            prizeIcon.heightAnchor.constraint(equalToConstant: 14),
            
            prizePoolLabel.centerYAnchor.constraint(equalTo: prizeIcon.centerYAnchor),
            prizePoolLabel.leadingAnchor.constraint(equalTo: prizeIcon.trailingAnchor, constant: 6),
            
            // Calendar/dates
            calendarIcon.centerYAnchor.constraint(equalTo: participantsIcon.centerYAnchor),
            calendarIcon.trailingAnchor.constraint(equalTo: datesLabel.leadingAnchor, constant: -6),
            calendarIcon.widthAnchor.constraint(equalToConstant: 14),
            calendarIcon.heightAnchor.constraint(equalToConstant: 14),
            
            datesLabel.centerYAnchor.constraint(equalTo: participantsIcon.centerYAnchor),
            datesLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            datesLabel.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with event: CompetitionEvent) {
        eventNameLabel.text = event.name
        eventTypeLabel.text = event.type.uppercased()
        
        // Configure status badge
        statusLabel.text = event.status.uppercased()
        statusBadge.backgroundColor = statusColor(for: event.status)
        
        // Configure participants
        participantsLabel.text = "\(event.participantCount)"
        
        // Configure prize pool
        if event.prizePool > 0 {
            prizePoolLabel.text = "\(event.prizePool)"
        } else {
            prizePoolLabel.text = "Free"
            prizePoolLabel.textColor = IndustrialDesign.Colors.secondaryText
        }
        
        // Configure dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        let startDateString = dateFormatter.string(from: event.startDate)
        let endDateString = dateFormatter.string(from: event.endDate)
        datesLabel.text = "\(startDateString) -\\n\(endDateString)"
        
        // Add hover effect for interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }
    
    @objc private func cellTapped() {
        // Animate tap feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.containerView.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
                self.containerView.alpha = 1.0
            }
        }
    }
    
    // MARK: - Cell Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        eventNameLabel.text = nil
        eventTypeLabel.text = nil
        statusLabel.text = nil
        participantsLabel.text = nil
        prizePoolLabel.text = nil
        datesLabel.text = nil
        
        // Reset prize pool label color
        prizePoolLabel.textColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0)
        
        // Remove gesture recognizers
        containerView.gestureRecognizers?.forEach { gesture in
            containerView.removeGestureRecognizer(gesture)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.containerView.alpha = highlighted ? 0.7 : 1.0
            if highlighted {
                self.containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            } else {
                self.containerView.transform = .identity
            }
        }
    }
    
    private func statusColor(for status: String) -> UIColor {
        switch status.lowercased() {
        case "active":
            return .systemGreen
        case "completed":
            return .systemBlue
        case "upcoming":
            return .systemOrange
        default:
            return .systemGray
        }
    }
}