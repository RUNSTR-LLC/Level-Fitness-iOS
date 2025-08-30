import UIKit

// MARK: - Data Loading Extension

extension NotificationInboxViewController {
    
    func loadNotifications() {
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
    
    func groupNotificationsByDate() {
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
    
    func updateUI() {
        clearNotificationViews()
        
        if notifications.isEmpty {
            showEmptyState()
            return
        }
        
        hideEmptyState()
        createNotificationViews()
    }
    
    func clearNotificationViews() {
        notificationViews.forEach { $0.removeFromSuperview() }
        notificationViews.removeAll()
    }
    
    func showEmptyState() {
        emptyStateView.isHidden = false
        notificationsContainer.isHidden = true
    }
    
    func hideEmptyState() {
        emptyStateView.isHidden = true
        notificationsContainer.isHidden = false
    }
    
    func createNotificationViews() {
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
    
    func createSectionHeader(title: String) -> UIView {
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
    
    func createNotificationCell(notification: NotificationItem) -> BaseNotificationCell {
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
    
    func getIconForNotificationType(_ type: String) -> UIImage? {
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
}