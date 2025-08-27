import UIKit

// MARK: - Constants

private struct NotificationCellConstants {
    static let baseHeight: CGFloat = 80
    static let challengeHeight: CGFloat = 110
    static let cornerRadius: CGFloat = 12
    static let unreadIndicatorRadius: CGFloat = 4
    static let unreadIndicatorSize: CGFloat = 8
    static let buttonWidth: CGFloat = 70
    static let buttonHeight: CGFloat = 24
    static let buttonCornerRadius: CGFloat = 6
    static let actionContainerHeight: CGFloat = 32
    static let actionContainerCornerRadius: CGFloat = 8
    static let iconSize: CGFloat = 24
    static let padding: CGFloat = 16
    static let smallPadding: CGFloat = 8
    static let minimumPadding: CGFloat = 4
}

// MARK: - Protocol for Notification Cell Actions

protocol NotificationCellDelegate: AnyObject {
    func notificationCell(_ cell: UIView, didAcceptNotification notification: NotificationItem)
    func notificationCell(_ cell: UIView, didDeclineNotification notification: NotificationItem)
    func notificationCell(_ cell: UIView, didTapNotification notification: NotificationItem)
}

// MARK: - Base Notification Cell

class BaseNotificationCell: UIView {
    
    // MARK: - Properties
    weak var delegate: NotificationCellDelegate?
    private(set) var notification: NotificationItem?
    private(set) var notificationId: String?
    
    // MARK: - UI Components
    protected let containerView = UIView()
    protected let iconView = UIImageView()
    protected let titleLabel = UILabel()
    protected let bodyLabel = UILabel()
    protected let timeLabel = UILabel()
    protected let unreadIndicator = UIView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBaseUI()
        setupBaseConstraints()
        setupTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupBaseUI() {
        // Container
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.6)
        containerView.layer.cornerRadius = NotificationCellConstants.cornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = .button
        
        // Icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = IndustrialDesign.Colors.bitcoin
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Body
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = IndustrialDesign.Colors.secondaryText
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Time
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Unread indicator
        unreadIndicator.backgroundColor = IndustrialDesign.Colors.bitcoin
        unreadIndicator.layer.cornerRadius = NotificationCellConstants.unreadIndicatorRadius
        unreadIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to hierarchy
        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(bodyLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(unreadIndicator)
    }
    
    private func setupBaseConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: NotificationCellConstants.baseHeight),
            
            // Icon
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: NotificationCellConstants.padding),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: NotificationCellConstants.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: NotificationCellConstants.iconSize),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: NotificationCellConstants.smallPadding + NotificationCellConstants.minimumPadding),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: NotificationCellConstants.smallPadding + NotificationCellConstants.minimumPadding),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -NotificationCellConstants.smallPadding),
            
            // Body
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: NotificationCellConstants.minimumPadding),
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -NotificationCellConstants.smallPadding - NotificationCellConstants.minimumPadding),
            
            // Time
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: NotificationCellConstants.smallPadding + NotificationCellConstants.minimumPadding),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -NotificationCellConstants.padding),
            
            // Unread indicator
            unreadIndicator.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),
            unreadIndicator.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -NotificationCellConstants.smallPadding),
            unreadIndicator.widthAnchor.constraint(equalToConstant: NotificationCellConstants.unreadIndicatorSize),
            unreadIndicator.heightAnchor.constraint(equalToConstant: NotificationCellConstants.unreadIndicatorSize)
        ])
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func cellTapped() {
        guard let notification = notification else { return }
        delegate?.notificationCell(self, didTapNotification: notification)
    }
    
    // MARK: - Configuration
    
    func configure(with notification: NotificationItem) {
        self.notification = notification
        self.notificationId = notification.id
        
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        timeLabel.text = notification.timeAgo
        iconView.image = getIconForNotificationType(notification.type)
        
        // Update read status
        updateReadStatus(isRead: notification.read)
        
        // Configure accessibility
        setupAccessibility(for: notification)
    }
    
    private func setupAccessibility(for notification: NotificationItem) {
        let readStatus = notification.read ? "read" : "unread"
        let body = notification.body ?? ""
        
        accessibilityLabel = "\(notification.title). \(body). \(notification.timeAgo). \(readStatus)"
        accessibilityHint = notification.read ? 
            "Tap to view details. Swipe left to delete." :
            "Tap to view details and mark as read. Swipe left to delete."
    }
    
    private func updateReadStatus(isRead: Bool) {
        containerView.backgroundColor = isRead ? 
            UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.6) :
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
        
        containerView.layer.borderWidth = isRead ? 0 : 1
        containerView.layer.borderColor = isRead ? UIColor.clear.cgColor : IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.3).cgColor
        
        unreadIndicator.isHidden = isRead
    }
    
    private func getIconForNotificationType(_ type: String) -> UIImage? {
        switch type {
        case "challenge_request":
            return UIImage(systemName: "bolt.circle.fill")
        case "challenge_accepted":
            return UIImage(systemName: "checkmark.circle.fill")
        case "challenge_declined":
            return UIImage(systemName: "xmark.circle.fill")
        case "team_announcement":
            return UIImage(systemName: "megaphone.fill")
        case "event_invite", "event_started":
            return UIImage(systemName: "calendar.circle.fill")
        case "result_announcement":
            return UIImage(systemName: "trophy.circle.fill")
        case "payment_received":
            return UIImage(systemName: "bitcoinsign.circle.fill")
        default:
            return UIImage(systemName: "bell.circle.fill")
        }
    }
}

// MARK: - Challenge Request Cell

class ChallengeRequestCell: BaseNotificationCell {
    
    // MARK: - UI Components
    private let actionButtonsContainer = UIView()
    private let acceptButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)
    private let stakeLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .small)
    private var isProcessing = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChallengeUI()
        setupChallengeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupChallengeUI() {
        // Action buttons container
        actionButtonsContainer.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        actionButtonsContainer.layer.cornerRadius = NotificationCellConstants.actionContainerCornerRadius
        actionButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Accept button
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        acceptButton.layer.cornerRadius = NotificationCellConstants.buttonCornerRadius
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        acceptButton.accessibilityLabel = "Accept challenge"
        acceptButton.accessibilityHint = "Double tap to accept this challenge"
        
        // Decline button
        declineButton.setTitle("Decline", for: .normal)
        declineButton.backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.6)
        declineButton.setTitleColor(IndustrialDesign.Colors.secondaryText, for: .normal)
        declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        declineButton.layer.cornerRadius = NotificationCellConstants.buttonCornerRadius
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        declineButton.accessibilityLabel = "Decline challenge"
        declineButton.accessibilityHint = "Double tap to decline this challenge"
        
        // Stake label
        stakeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        stakeLabel.textColor = IndustrialDesign.Colors.bitcoin
        stakeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        
        // Add to hierarchy
        containerView.addSubview(actionButtonsContainer)
        actionButtonsContainer.addSubview(acceptButton)
        actionButtonsContainer.addSubview(declineButton)
        actionButtonsContainer.addSubview(stakeLabel)
        actionButtonsContainer.addSubview(loadingIndicator)
    }
    
    private func setupChallengeConstraints() {
        NSLayoutConstraint.activate([
            // Action buttons container - positioned below the main content
            actionButtonsContainer.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            actionButtonsContainer.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actionButtonsContainer.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            actionButtonsContainer.heightAnchor.constraint(equalToConstant: NotificationCellConstants.actionContainerHeight),
            actionButtonsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            // Accept button
            acceptButton.leadingAnchor.constraint(equalTo: actionButtonsContainer.leadingAnchor, constant: 8),
            acceptButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            acceptButton.widthAnchor.constraint(equalToConstant: NotificationCellConstants.buttonWidth),
            acceptButton.heightAnchor.constraint(equalToConstant: NotificationCellConstants.buttonHeight),
            
            // Decline button
            declineButton.leadingAnchor.constraint(equalTo: acceptButton.trailingAnchor, constant: NotificationCellConstants.smallPadding),
            declineButton.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            declineButton.widthAnchor.constraint(equalToConstant: NotificationCellConstants.buttonWidth),
            declineButton.heightAnchor.constraint(equalToConstant: NotificationCellConstants.buttonHeight),
            
            // Stake label
            stakeLabel.trailingAnchor.constraint(equalTo: loadingIndicator.leadingAnchor, constant: -8),
            stakeLabel.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor),
            
            // Loading indicator
            loadingIndicator.trailingAnchor.constraint(equalTo: actionButtonsContainer.trailingAnchor, constant: -8),
            loadingIndicator.centerYAnchor.constraint(equalTo: actionButtonsContainer.centerYAnchor)
        ])
        
        // Update container height for challenge cell
        containerView.heightAnchor.constraint(equalToConstant: NotificationCellConstants.challengeHeight).isActive = true
    }
    
    @objc private func acceptTapped() {
        guard let notification = notification, !isProcessing else { return }
        
        // Show confirmation dialog
        showConfirmationAlert(
            title: "Accept Challenge", 
            message: "Are you sure you want to accept this challenge?",
            confirmAction: {
                self.setProcessingState(true)
                self.delegate?.notificationCell(self, didAcceptNotification: notification)
            }
        )
    }
    
    @objc private func declineTapped() {
        guard let notification = notification, !isProcessing else { return }
        
        // Show confirmation dialog
        showConfirmationAlert(
            title: "Decline Challenge", 
            message: "Are you sure you want to decline this challenge?",
            confirmAction: {
                self.setProcessingState(true)
                self.delegate?.notificationCell(self, didDeclineNotification: notification)
            }
        )
    }
    
    private func setProcessingState(_ processing: Bool) {
        isProcessing = processing
        acceptButton.isEnabled = !processing
        declineButton.isEnabled = !processing
        
        if processing {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    private func showConfirmationAlert(title: String, message: String, confirmAction: @escaping () -> Void) {
        // Find the view controller to present the alert
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
                    confirmAction()
                })
                viewController.present(alert, animated: true)
                return
            }
            responder = responder?.next
        }
        
        // If we can't find a view controller, just execute the action
        confirmAction()
    }
    
    func resetProcessingState() {
        setProcessingState(false)
    }
    
    override func configure(with notification: NotificationItem) {
        super.configure(with: notification)
        
        // Hide action buttons if already acted on
        actionButtonsContainer.isHidden = notification.actedOn
        
        // Show stake amount if present
        if let actionData = notification.actionData,
           let stakeAmount = actionData["stake_amount"] {
            stakeLabel.text = "Stake: \(stakeAmount) sats"
            stakeLabel.isHidden = false
        } else {
            stakeLabel.isHidden = true
        }
    }
}

// MARK: - Basic Notification Cell for other types

class BasicNotificationCell: BaseNotificationCell {
    // Uses the base implementation without additional actions
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Result Notification Cell

class ResultNotificationCell: BaseNotificationCell {
    
    private let resultIcon = UIImageView()
    private let resultLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupResultUI()
        setupResultConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupResultUI() {
        // Result icon (trophy, medal, etc.)
        resultIcon.contentMode = .scaleAspectFit
        resultIcon.tintColor = IndustrialDesign.Colors.bitcoin
        resultIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Result text
        resultLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        resultLabel.textColor = IndustrialDesign.Colors.bitcoin
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(resultIcon)
        containerView.addSubview(resultLabel)
    }
    
    private func setupResultConstraints() {
        NSLayoutConstraint.activate([
            // Result icon
            resultIcon.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            resultIcon.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
            resultIcon.widthAnchor.constraint(equalToConstant: 16),
            resultIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Result label
            resultLabel.leadingAnchor.constraint(equalTo: resultIcon.trailingAnchor, constant: 6),
            resultLabel.centerYAnchor.constraint(equalTo: resultIcon.centerYAnchor),
            resultLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleLabel.trailingAnchor)
        ])
    }
    
    override func configure(with notification: NotificationItem) {
        super.configure(with: notification)
        
        // Configure result-specific UI
        if let actionData = notification.actionData {
            if let result = actionData["result"] {
                resultLabel.text = result
                resultIcon.image = getResultIcon(for: result)
            }
        }
    }
    
    private func getResultIcon(for result: String) -> UIImage? {
        if result.lowercased().contains("won") || result.lowercased().contains("victory") {
            return UIImage(systemName: "trophy.fill")
        } else if result.lowercased().contains("completed") {
            return UIImage(systemName: "checkmark.circle.fill")
        } else {
            return UIImage(systemName: "star.fill")
        }
    }
}