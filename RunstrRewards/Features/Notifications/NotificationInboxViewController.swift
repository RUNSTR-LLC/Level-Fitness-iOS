import UIKit

// MARK: - NotificationCellDelegate Protocol

protocol NotificationCellDelegate: AnyObject {
    func notificationCellTapped(notification: NotificationItem)
}

public class NotificationInboxViewController: UIViewController, NotificationCellDelegate {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Header
    private let headerView = UIView()
    private let titleLabel = UILabel()
    
    // Notifications list
    private let notificationsContainer = UIView()
    private let refreshControl = UIRefreshControl()
    private var notificationViews: [UIView] = []
    
    // Empty state
    private let emptyStateView = UIView()
    private let emptyStateIcon = UIImageView()
    private let emptyStateLabel = UILabel()
    private let emptyStateDescription = UILabel()
    
    // Loading
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Data
    private var notifications: [NotificationItem] = []
    private var groupedNotifications: [String: [NotificationItem]] = [:]
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("📥 NotificationInbox: Loading inbox...")
        
        // Hide navigation bar since we have custom header with back button
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupIndustrialBackground()
        setupScrollView()
        setupHeader()
        setupNotificationsContainer()
        setupEmptyState()
        setupLoadingIndicator()
        setupConstraints()
        loadNotifications()
        
        print("📥 NotificationInbox: Inbox loaded successfully!")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Only refresh if we don't already have notifications loaded
        if notifications.isEmpty {
            loadNotifications()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupIndustrialBackground() {
        view.backgroundColor = IndustrialDesign.Colors.background
        
        // Add grid pattern background
        let gridView = GridPatternView()
        gridView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gridView)
        
        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshNotifications), for: .valueChanged)
        refreshControl.tintColor = IndustrialDesign.Colors.bitcoin
        scrollView.refreshControl = refreshControl
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.8)
        
        // Add bottom border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor
        headerView.layer.addSublayer(borderLayer)
        
        // Back button
        let backButton = UIButton(type: .custom)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = IndustrialDesign.Colors.secondaryText
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Title
        titleLabel.text = "Notifications"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        contentView.addSubview(headerView)
        
        // Add constraints for header elements
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            backButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        // Update border frame
        DispatchQueue.main.async {
            borderLayer.frame = CGRect(x: 0, y: 59, width: self.view.frame.width, height: 1)
        }
    }
    
    @objc private func backButtonTapped() {
        print("📥 NotificationInbox: Back button tapped")
        navigationController?.popViewController(animated: true)
    }
    
    private func setupNotificationsContainer() {
        notificationsContainer.translatesAutoresizingMaskIntoConstraints = false
        notificationsContainer.backgroundColor = .clear
        contentView.addSubview(notificationsContainer)
    }
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.backgroundColor = .clear
        emptyStateView.isHidden = true
        
        // Icon
        emptyStateIcon.image = UIImage(systemName: "bell.slash")
        emptyStateIcon.tintColor = IndustrialDesign.Colors.secondaryText
        emptyStateIcon.contentMode = .scaleAspectFit
        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Title
        emptyStateLabel.text = "No Notifications"
        emptyStateLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        emptyStateLabel.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Description
        emptyStateDescription.text = "When your team has new activity or you receive challenges, they'll appear here."
        emptyStateDescription.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyStateDescription.textColor = IndustrialDesign.Colors.secondaryText
        emptyStateDescription.textAlignment = .center
        emptyStateDescription.numberOfLines = 0
        emptyStateDescription.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateIcon)
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateView.addSubview(emptyStateDescription)
        contentView.addSubview(emptyStateView)
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = IndustrialDesign.Colors.bitcoin
        loadingIndicator.hidesWhenStopped = true
        contentView.addSubview(loadingIndicator)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            // Notifications container
            notificationsContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            notificationsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            notificationsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            notificationsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Empty state
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 64),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 64),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 16),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            
            emptyStateDescription.topAnchor.constraint(equalTo: emptyStateLabel.bottomAnchor, constant: 8),
            emptyStateDescription.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateDescription.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateDescription.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadNotifications() {
        guard let userId = AuthenticationService.shared.currentUserId else {
            print("📥 NotificationInbox: No current user ID")
            return
        }
        
        loadingIndicator.startAnimating()
        
        Task {
            do {
                notifications = try await NotificationInboxService.shared.getNotifications(for: userId)
                
                await MainActor.run {
                    groupNotificationsByDate()
                    updateUI()
                    loadingIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                    // Mark notifications as read after loading
                    markUnreadAsRead()
                }
            } catch {
                print("📥 NotificationInbox: Failed to load notifications: \(error)")
                await MainActor.run {
                    loadingIndicator.stopAnimating()
                    refreshControl.endRefreshing()
                    showEmptyState()
                }
            }
        }
    }
    
    private func groupNotificationsByDate() {
        groupedNotifications = Dictionary(grouping: notifications) { notification in
            let calendar = Calendar.current
            if calendar.isDateInToday(notification.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(notification.createdAt) {
                return "Yesterday"
            } else if calendar.component(.weekOfYear, from: notification.createdAt) == calendar.component(.weekOfYear, from: Date()) {
                return "This Week"
            } else {
                return "Earlier"
            }
        }
    }
    
    private func updateUI() {
        clearNotificationViews()
        
        if notifications.isEmpty {
            showEmptyState()
            return
        }
        
        hideEmptyState()
        createNotificationViews()
    }
    
    private func clearNotificationViews() {
        notificationViews.forEach { $0.removeFromSuperview() }
        notificationViews.removeAll()
    }
    
    private func showEmptyState() {
        emptyStateView.isHidden = false
        notificationsContainer.isHidden = true
    }
    
    private func hideEmptyState() {
        emptyStateView.isHidden = true
        notificationsContainer.isHidden = false
    }
    
    private func createNotificationViews() {
        var yOffset: CGFloat = 0
        let sectionSpacing: CGFloat = 24
        let itemSpacing: CGFloat = 12
        
        let orderedSections = ["Today", "Yesterday", "This Week", "Earlier"]
        
        for section in orderedSections {
            guard let sectionNotifications = groupedNotifications[section] else { continue }
            
            // Section header
            let sectionHeader = createSectionHeader(title: section)
            sectionHeader.translatesAutoresizingMaskIntoConstraints = false
            notificationsContainer.addSubview(sectionHeader)
            notificationViews.append(sectionHeader)
            
            NSLayoutConstraint.activate([
                sectionHeader.topAnchor.constraint(equalTo: notificationsContainer.topAnchor, constant: yOffset),
                sectionHeader.leadingAnchor.constraint(equalTo: notificationsContainer.leadingAnchor),
                sectionHeader.trailingAnchor.constraint(equalTo: notificationsContainer.trailingAnchor),
                sectionHeader.heightAnchor.constraint(equalToConstant: 30)
            ])
            
            yOffset += 30 + 12
            
            // Section notifications
            for notification in sectionNotifications {
                let notificationCard = createNotificationCell(notification: notification)
                notificationCard.translatesAutoresizingMaskIntoConstraints = false
                notificationsContainer.addSubview(notificationCard)
                notificationViews.append(notificationCard)
                
                NSLayoutConstraint.activate([
                    notificationCard.topAnchor.constraint(equalTo: notificationsContainer.topAnchor, constant: yOffset),
                    notificationCard.leadingAnchor.constraint(equalTo: notificationsContainer.leadingAnchor),
                    notificationCard.trailingAnchor.constraint(equalTo: notificationsContainer.trailingAnchor)
                ])
                
                // Different heights for different cell types
                let cellHeight: CGFloat = notification.type == "challenge_request" ? 110 : 80 // Using NotificationCells constants
                yOffset += cellHeight + itemSpacing
            }
            
            yOffset += sectionSpacing - itemSpacing // Adjust for section spacing
        }
        
        // Update notifications container height
        NSLayoutConstraint.activate([
            notificationsContainer.heightAnchor.constraint(equalToConstant: max(yOffset, 100))
        ])
    }
    
    private func createSectionHeader(title: String) -> UIView {
        let header = UIView()
        header.backgroundColor = .clear
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = IndustrialDesign.Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        
        header.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])
        
        return header
    }
    
    private func createNotificationCell(notification: NotificationItem) -> BaseNotificationCell {
        let cell: BaseNotificationCell
        
        // Create different cell types based on notification type
        switch notification.type {
        case "challenge_request":
            cell = ChallengeRequestCell()
        case "result_announcement", "challenge_completed":
            cell = ResultNotificationCell()
        default:
            cell = BasicNotificationCell()
        }
        
        // Configure the cell
        cell.delegate = self
        cell.configure(with: notification)
        
        // Add swipe gesture for deletion
        addSwipeGesture(to: cell, notification: notification)
        
        return cell
    }
    
    private func getIconForNotificationType(_ type: String) -> UIImage? {
        switch type {
        case "challenge_request":
            return UIImage(systemName: "bolt.circle.fill")
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
    
    // MARK: - Actions
    
    @objc private func refreshNotifications() {
        loadNotifications()
    }
    
    private func markUnreadAsRead() {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        // Only mark as read if there are unread notifications
        let unreadNotifications = notifications.filter { !$0.read }
        guard !unreadNotifications.isEmpty else { return }
        
        Task {
            do {
                try await NotificationInboxService.shared.markAllAsRead(for: userId)
                // Clear badge
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    // Update local notifications to reflect read status
                    self.notifications = self.notifications.map { notification in
                        var updatedNotification = notification
                        // Note: This requires making NotificationItem mutable or creating a new instance
                        return notification
                    }
                }
            } catch {
                print("📥 NotificationInbox: Failed to mark notifications as read: \(error)")
            }
        }
    }
    
    // MARK: - Swipe Gestures
    
    private func addSwipeGesture(to cell: BaseNotificationCell, notification: NotificationItem) {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        cell.addGestureRecognizer(swipeGesture)
        // No need to set tag since we'll use the cell's notificationId directly
    }
    
    @objc private func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        guard let cell = gesture.view as? BaseNotificationCell else { return }
        
        let translation = gesture.translation(in: cell)
        let velocity = gesture.velocity(in: cell)
        
        switch gesture.state {
        case .changed:
            // Only allow left swipe (negative translation)
            if translation.x < 0 {
                cell.transform = CGAffineTransform(translationX: max(translation.x, -100), y: 0)
            }
        case .ended:
            if translation.x < -50 || velocity.x < -500 {
                // Swipe threshold met - delete notification
                guard let notification = cell.notification else { return }
        let notificationId = notification.id
                deleteNotification(withId: notificationId, cell: cell)
            } else {
                // Reset position with animation
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: []) {
                    cell.transform = .identity
                } completion: { _ in }
            }
        default:
            break
        }
    }
    
    private func deleteNotification(withId notificationId: String, cell: BaseNotificationCell) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        
        // Find and remove from local array
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        let notification = notifications[index]
        notifications.remove(at: index)
        
        // Animate cell removal
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            cell.transform = CGAffineTransform(translationX: -UIScreen.main.bounds.width, y: 0)
            cell.alpha = 0
        } completion: { _ in
            // Update UI after animation
            self.updateUI()
            impactFeedback.impactOccurred()
        }
        
        // Delete from database
        Task {
            do {
                try await NotificationInboxService.shared.deleteNotification(notificationId)
                print("📥 NotificationInbox: Successfully deleted notification: \(notificationId)")
            } catch {
                print("📥 NotificationInbox: Failed to delete notification: \(error)")
                // Re-add to array if deletion failed
                await MainActor.run {
                    self.notifications.insert(notification, at: index)
                    self.updateUI()
                    self.showAlert(title: "Delete Failed", message: "Could not delete notification. Please try again.")
                }
            }
        }
    }
    
    // MARK: - NotificationCellDelegate
    
    func notificationCell(_ cell: UIView, didAcceptNotification notification: NotificationItem) {
        print("📥 NotificationInbox: Accepting challenge notification: \(notification.id)")
        
        Task {
            do {
                // Mark as acted on
                try await NotificationInboxService.shared.markAsActedOn(notification.id, actionTaken: "accepted")
                
                // Handle challenge acceptance based on notification data
                if let actionData = notification.actionData {
                    await handleChallengeAcceptance(notification: notification, actionData: actionData)
                }
                
                // Refresh notifications to show updated status
                await MainActor.run {
                    loadNotifications()
                }
            } catch {
                print("📥 NotificationInbox: Failed to accept challenge: \(error)")
                await MainActor.run {
                    // Reset button state if needed
                    // Show error alert
                    showAlert(title: "Error", message: "Failed to accept challenge. Please try again.")
                }
            }
        }
    }
    
    func notificationCell(_ cell: UIView, didDeclineNotification notification: NotificationItem) {
        print("📥 NotificationInbox: Declining challenge notification: \(notification.id)")
        
        Task {
            do {
                // Mark as acted on
                try await NotificationInboxService.shared.markAsActedOn(notification.id, actionTaken: "declined")
                
                // Handle challenge decline
                if let actionData = notification.actionData {
                    await handleChallengeDecline(notification: notification, actionData: actionData)
                }
                
                // Refresh notifications to show updated status
                await MainActor.run {
                    loadNotifications()
                }
            } catch {
                print("📥 NotificationInbox: Failed to decline challenge: \(error)")
                await MainActor.run {
                    // Reset button state if needed
                    showAlert(title: "Error", message: "Failed to decline challenge. Please try again.")
                }
            }
        }
    }
    
    func notificationCell(_ cell: UIView, didTapNotification notification: NotificationItem) {
        print("📥 NotificationInbox: Tapped notification: \(notification.id)")
        
        // Handle different notification types
        switch notification.type {
        case "event_invite":
            // Navigate to event details
            navigateToEvent(eventId: notification.eventId)
        case "team_announcement":
            // Navigate to team page
            navigateToTeam(teamId: notification.teamId)
        case "result_announcement":
            // Show result details
            showResultDetails(notification: notification)
        default:
            // Mark as read if not already
            if !notification.read {
                markNotificationAsRead(notification.id)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleChallengeAcceptance(notification: NotificationItem, actionData: [String: String]) async {
        // TODO: Implement challenge acceptance logic
        // This will be implemented in Day 4 when we add the full challenge system
        print("📥 NotificationInbox: Challenge acceptance logic - TODO for Day 4")
    }
    
    private func handleChallengeDecline(notification: NotificationItem, actionData: [String: String]) async {
        // TODO: Implement challenge decline logic  
        // This will be implemented in Day 4 when we add the full challenge system
        print("📥 NotificationInbox: Challenge decline logic - TODO for Day 4")
    }
    
    private func navigateToEvent(eventId: String?) {
        // TODO: Navigate to event details page
        print("📥 NotificationInbox: Navigate to event: \(eventId ?? "unknown")")
    }
    
    private func navigateToTeam(teamId: String?) {
        // TODO: Navigate to team page
        print("📥 NotificationInbox: Navigate to team: \(teamId ?? "unknown")")
    }
    
    private func showResultDetails(notification: NotificationItem) {
        // Show alert with result details for now
        let title = "Results"
        let message = notification.body ?? "Check your results in the team page."
        showAlert(title: title, message: message)
    }
    
    private func markNotificationAsRead(_ notificationId: String) {
        Task {
            do {
                try await NotificationInboxService.shared.markAsRead(notificationId)
            } catch {
                print("📥 NotificationInbox: Failed to mark notification as read: \(error)")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - NotificationCellDelegate
    
    func notificationCellTapped(notification: NotificationItem) {
        // Handle notification tap - mark as read and handle specific actions
        markNotificationAsRead(notification.id)
        
        switch notification.type {
        case "challenge_request":
            // For challenge requests, show the challenge details
            let title = "Challenge Request"
            let message = notification.body ?? "You have received a challenge request."
            showAlert(title: title, message: message)
        case "result_announcement", "challenge_completed":
            // For results, show the results
            let title = "Results"
            let message = notification.body ?? "Check your results in the team page."
            showAlert(title: title, message: message)
        default:
            // For other notification types, just show the content
            if let body = notification.body {
                showAlert(title: notification.title, message: body)
            }
        }
    }
}

// MARK: - Notification Cell Classes

class BaseNotificationCell: UIView {
    weak var delegate: NotificationCellDelegate?
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadIndicator = UIView()
    
    var notification: NotificationItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Container setup
        containerView.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 0.9)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = IndustrialDesign.Colors.cardBorder.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon setup
        iconImageView.tintColor = IndustrialDesign.Colors.bitcoin
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title setup
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = IndustrialDesign.Colors.primaryText
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Body setup
        bodyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        bodyLabel.textColor = IndustrialDesign.Colors.secondaryText
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Time setup
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.textColor = IndustrialDesign.Colors.secondaryText
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Unread indicator
        unreadIndicator.backgroundColor = IndustrialDesign.Colors.bitcoin
        unreadIndicator.layer.cornerRadius = 3
        unreadIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(bodyLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(unreadIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            
            bodyLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16),
            
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            
            unreadIndicator.widthAnchor.constraint(equalToConstant: 6),
            unreadIndicator.heightAnchor.constraint(equalToConstant: 6),
            unreadIndicator.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            unreadIndicator.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -4)
        ])
    }
    
    func configure(with notification: NotificationItem) {
        self.notification = notification
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        
        // Set icon based on type
        iconImageView.image = getIconForType(notification.type)
        
        // Format time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: notification.createdAt, relativeTo: Date())
        
        // Show/hide unread indicator
        unreadIndicator.isHidden = notification.read
        
        // Update text colors based on read status
        if notification.read {
            titleLabel.alpha = 0.7
            bodyLabel.alpha = 0.7
        } else {
            titleLabel.alpha = 1.0
            bodyLabel.alpha = 1.0
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
    }
    
    private func getIconForType(_ type: String) -> UIImage? {
        switch type {
        case "challenge_request":
            return UIImage(systemName: "bolt.circle.fill")
        case "team_announcement":
            return UIImage(systemName: "megaphone.fill")
        case "event_invite", "event_started":
            return UIImage(systemName: "calendar.circle.fill")
        case "result_announcement", "challenge_completed":
            return UIImage(systemName: "trophy.circle.fill")
        case "payment_received":
            return UIImage(systemName: "bitcoinsign.circle.fill")
        default:
            return UIImage(systemName: "bell.circle.fill")
        }
    }
    
    @objc private func handleTap() {
        guard let notification = notification else { return }
        delegate?.notificationCellTapped(notification: notification)
    }
}

// MARK: - Specific Cell Types

class ChallengeRequestCell: BaseNotificationCell {
    private let acceptButton = UIButton(type: .custom)
    private let declineButton = UIButton(type: .custom)
    
    override func configure(with notification: NotificationItem) {
        super.configure(with: notification)
        
        // Add action buttons for challenge requests
        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.backgroundColor = IndustrialDesign.Colors.bitcoin
        acceptButton.layer.cornerRadius = 6
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        
        declineButton.setTitle("Decline", for: .normal)
        declineButton.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3)
        declineButton.layer.cornerRadius = 6
        declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add buttons if not already added
        if acceptButton.superview == nil {
            addSubview(acceptButton)
            addSubview(declineButton)
            
            NSLayoutConstraint.activate([
                acceptButton.topAnchor.constraint(equalTo: bottomAnchor, constant: 8),
                acceptButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
                acceptButton.widthAnchor.constraint(equalToConstant: 80),
                acceptButton.heightAnchor.constraint(equalToConstant: 32),
                
                declineButton.topAnchor.constraint(equalTo: acceptButton.topAnchor),
                declineButton.leadingAnchor.constraint(equalTo: acceptButton.trailingAnchor, constant: 8),
                declineButton.widthAnchor.constraint(equalToConstant: 80),
                declineButton.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }
}

class ResultNotificationCell: BaseNotificationCell {
    // Customize for result notifications if needed
}

class BasicNotificationCell: BaseNotificationCell {
    // Basic notification cell using default implementation
}