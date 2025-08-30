import UIKit

// MARK: - Actions Extension

extension NotificationInboxViewController {
    
    @objc func refreshNotifications() {
        loadNotifications()
    }
    
    func markUnreadAsRead() {
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
    
    func addSwipeGesture(to cell: BaseNotificationCell, notification: NotificationItem) {
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        cell.addGestureRecognizer(swipeGesture)
        // No need to set tag since we'll use the cell's notificationId directly
    }
    
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
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
    
    func deleteNotification(withId notificationId: String, cell: BaseNotificationCell) {
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
    
    // MARK: - NotificationCellDelegate Implementation
    
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
    
    func handleChallengeAcceptance(notification: NotificationItem, actionData: [String: String]) async {
        print("📥 NotificationInbox: Accepting challenge")
        
        guard let challengeId = actionData["challenge_id"],
              let userSession = AuthenticationService.shared.loadSession() else {
            print("📥 NotificationInbox: Missing challenge ID or user session")
            return
        }
        
        do {
            // Accept the challenge through P2PChallengeService
            try await P2PChallengeService.shared.acceptChallenge(challengeId: challengeId, userId: userSession.id)
            
            // Mark notification as handled
            await markNotificationAsHandled(notification.id)
            
            // Show success message
            DispatchQueue.main.async {
                self.showAlert(
                    title: "Challenge Accepted!",
                    message: "You've accepted the challenge. You'll need to pay your stake amount to begin."
                )
            }
            
            // Refresh notifications
            await loadNotifications()
            
        } catch {
            print("📥 NotificationInbox: Failed to accept challenge: \(error)")
            DispatchQueue.main.async {
                self.showAlert(
                    title: "Error",
                    message: "Failed to accept challenge. Please try again."
                )
            }
        }
    }
    
    func handleChallengeDecline(notification: NotificationItem, actionData: [String: String]) async {
        print("📥 NotificationInbox: Declining challenge")
        
        guard let challengeId = actionData["challenge_id"],
              let userSession = AuthenticationService.shared.loadSession() else {
            print("📥 NotificationInbox: Missing challenge ID or user session")
            return
        }
        
        do {
            // Decline the challenge through P2PChallengeService
            try await P2PChallengeService.shared.declineChallenge(challengeId: challengeId, userId: userSession.id)
            
            // Mark notification as handled
            await markNotificationAsHandled(notification.id)
            
            // Show confirmation message
            DispatchQueue.main.async {
                self.showAlert(
                    title: "Challenge Declined",
                    message: "You've declined the challenge."
                )
            }
            
            // Refresh notifications
            await loadNotifications()
            
        } catch {
            print("📥 NotificationInbox: Failed to decline challenge: \(error)")
            DispatchQueue.main.async {
                self.showAlert(
                    title: "Error",
                    message: "Failed to decline challenge. Please try again."
                )
            }
        }
    }
    
    func navigateToEvent(eventId: String?) {
        guard let eventId = eventId else {
            print("❌ NotificationInbox: No event ID provided for navigation")
            return
        }
        
        Task {
            do {
                // Fetch the event details first
                let events = try await SupabaseService.shared.fetchEvents()
                guard let event = events.first(where: { $0.id == eventId }) else {
                    await MainActor.run {
                        showAlert(title: "Event Not Found", message: "The event could not be found.")
                    }
                    return
                }
                
                // Navigate to event detail view
                await MainActor.run {
                    let eventDetailVC = EventDetailViewController(event: event)
                    eventDetailVC.onRegistrationComplete = { [weak self] success in
                        // Optionally refresh notifications if user joined event
                        if success {
                            self?.loadNotifications()
                        }
                    }
                    
                    self.navigationController?.pushViewController(eventDetailVC, animated: true)
                    print("📥 NotificationInbox: ✅ Navigated to event: \(event.name)")
                }
                
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: "Failed to load event details.")
                }
                print("❌ NotificationInbox: Failed to fetch event \(eventId): \(error)")
            }
        }
    }
    
    func navigateToTeam(teamId: String?) {
        // TODO: Navigate to team page
        print("📥 NotificationInbox: Navigate to team: \(teamId ?? "unknown")")
    }
    
    func showResultDetails(notification: NotificationItem) {
        // Show alert with result details for now
        let title = "Results"
        let message = notification.body ?? "Check your results in the team page."
        showAlert(title: title, message: message)
    }
    
    func markNotificationAsRead(_ notificationId: String) {
        Task {
            do {
                try await NotificationInboxService.shared.markAsRead(notificationId)
            } catch {
                print("📥 NotificationInbox: Failed to mark notification as read: \(error)")
            }
        }
    }
    
    func markNotificationAsHandled(_ notificationId: String) async {
        do {
            // Mark the notification as handled (removes it from inbox)
            try await NotificationInboxService.shared.markAsActedOn(notificationId, actionTaken: "handled")
        } catch {
            print("📥 NotificationInbox: Failed to mark notification as handled: \(error)")
        }
    }
    
    func showAlert(title: String, message: String) {
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