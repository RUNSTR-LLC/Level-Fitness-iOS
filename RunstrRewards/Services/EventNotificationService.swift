import Foundation
import UserNotifications

// MARK: - Notification Models

struct EventNotification {
    let id: String
    let eventId: String
    let userId: String
    let type: EventNotificationType
    let title: String
    let body: String
    let data: [String: Any]
    let timestamp: Date
    let priority: NotificationPriority
    let delivered: Bool
    let read: Bool
}

enum EventNotificationType {
    case qualified
    case autoEntered
    case rankUp
    case rankDown
    case goalAchieved
    case eventStarted
    case eventEnding
    case eventCompleted
    case prizeAwarded
    case newChallenger
}

enum NotificationPriority {
    case low
    case normal
    case high
    case critical
}

struct NotificationSettings {
    let qualificationNotifications: Bool
    let rankChangeNotifications: Bool
    let achievementNotifications: Bool
    let prizeNotifications: Bool
    let eventStatusNotifications: Bool
    let sound: Bool
    let quietHours: QuietHours?
}

struct QuietHours {
    let startTime: Date
    let endTime: Date
    let enabled: Bool
}

// MARK: - EventNotificationService

class EventNotificationService {
    static let shared = EventNotificationService()
    
    private var notificationSettings: NotificationSettings
    private var pendingNotifications: [String: EventNotification] = [:]
    private var deliveredNotifications: [EventNotification] = []
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        // Default settings
        notificationSettings = NotificationSettings(
            qualificationNotifications: true,
            rankChangeNotifications: true,
            achievementNotifications: true,
            prizeNotifications: true,
            eventStatusNotifications: true,
            sound: true,
            quietHours: QuietHours(
                startTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
                endTime: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date(),
                enabled: true
            )
        )
        
        setupNotificationObservers()
        requestNotificationPermissions()
    }
    
    // MARK: - Setup
    
    private func setupNotificationObservers() {
        // Listen for qualification events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserQualified),
            name: NSNotification.Name("UserQualifiedForEvent"),
            object: nil
        )
        
        // Listen for progress updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("EventProgressUpdated"),
            object: nil
        )
        
        // Listen for real-time leaderboard updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLeaderboardUpdate),
            name: NSNotification.Name("RealtimeLeaderboardUpdate"),
            object: nil
        )
    }
    
    private func requestNotificationPermissions() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) { granted, error in
            if granted {
                print("🔔 Notifications: Permission granted")
            } else {
                print("🔔 Notifications: Permission denied - \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleUserQualified(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String,
              let qualifyingWorkouts = notification.userInfo?["qualifyingWorkouts"] as? [String] else {
            return
        }
        
        let eventName = getEventName(eventId: eventId)
        
        // Create qualification notification
        let qualificationNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            type: .qualified,
            title: "🏆 You're Qualified!",
            body: "Your recent workouts qualify you for \(eventName). You've been automatically entered!",
            data: [
                "eventId": eventId,
                "qualifyingWorkouts": qualifyingWorkouts,
                "autoEntered": true
            ],
            timestamp: Date(),
            priority: .high,
            delivered: false,
            read: false
        )
        
        sendNotification(qualificationNotification)
        
        // Follow up with auto-entry confirmation
        let autoEntryNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            type: .autoEntered,
            title: "⚡ Auto-Entered",
            body: "You're now competing in \(eventName)! Start earning points with your workouts.",
            data: [
                "eventId": eventId,
                "actionable": true,
                "deepLink": "runstrrewards://event/\(eventId)"
            ],
            timestamp: Date().addingTimeInterval(5), // 5 seconds later
            priority: .normal,
            delivered: false,
            read: false
        )
        
        scheduleNotification(autoEntryNotification, delay: 5.0)
        
        print("🔔 Notifications: User qualified for event \(eventName)")
    }
    
    @objc private func handleProgressUpdate(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String,
              let updateType = notification.userInfo?["updateType"] as? ProgressUpdateType,
              let progress = notification.userInfo?["progress"] as? EventProgress else {
            return
        }
        
        let eventName = getEventName(eventId: eventId)
        
        switch updateType {
        case .rankChange:
            handleRankChangeNotification(eventId: eventId, userId: userId, progress: progress, eventName: eventName)
            
        case .goalAchieved:
            let achievementNotification = EventNotification(
                id: UUID().uuidString,
                eventId: eventId,
                userId: userId,
                type: .goalAchieved,
                title: "🎯 Goal Achieved!",
                body: "Congratulations! You've completed your \(eventName) challenge!",
                data: [
                    "eventId": eventId,
                    "progress": progress.progressPercentage,
                    "celebratory": true
                ],
                timestamp: Date(),
                priority: .high,
                delivered: false,
                read: false
            )
            
            sendNotification(achievementNotification)
            
        default:
            break
        }
    }
    
    @objc private func handleLeaderboardUpdate(_ notification: Notification) {
        guard let update = notification.userInfo?["update"] as? LiveLeaderboardUpdate else {
            return
        }
        
        let eventName = getEventName(eventId: update.eventId)
        
        switch update.updateType {
        case .newEntry:
            // Notify existing participants about new challenger
            let newChallengerNotification = EventNotification(
                id: UUID().uuidString,
                eventId: update.eventId,
                userId: "all_participants",
                type: .newChallenger,
                title: "⚔️ New Challenger!",
                body: "Someone new just joined \(eventName). The competition is heating up!",
                data: [
                    "eventId": update.eventId,
                    "participantCount": update.affectedEntries.count
                ],
                timestamp: Date(),
                priority: .low,
                delivered: false,
                read: false
            )
            
            sendNotificationToEventParticipants(newChallengerNotification, eventId: update.eventId)
            
        case .eventComplete:
            let completionNotification = EventNotification(
                id: UUID().uuidString,
                eventId: update.eventId,
                userId: "all_participants",
                type: .eventCompleted,
                title: "🏁 Event Complete!",
                body: "\(eventName) has ended. Check out the final results and your rewards!",
                data: [
                    "eventId": update.eventId,
                    "finalResults": true,
                    "deepLink": "runstrrewards://event/\(update.eventId)/results"
                ],
                timestamp: Date(),
                priority: .high,
                delivered: false,
                read: false
            )
            
            sendNotificationToEventParticipants(completionNotification, eventId: update.eventId)
            
        default:
            break
        }
    }
    
    // MARK: - Notification Creation
    
    private func handleRankChangeNotification(eventId: String, userId: String, progress: EventProgress, eventName: String) {
        guard notificationSettings.rankChangeNotifications else { return }
        
        // Only notify for significant rank changes (top 10 or major improvements)
        guard progress.rank <= 10 || shouldNotifyRankChange(progress: progress) else {
            return
        }
        
        let title = progress.rank <= 3 ? "🥇 Top 3!" : "📈 Rank Up!"
        let body = "You're now ranked #\(progress.rank) in \(eventName)! Keep pushing!"
        
        let rankNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            type: .rankUp,
            title: title,
            body: body,
            data: [
                "eventId": eventId,
                "newRank": progress.rank,
                "totalParticipants": progress.totalParticipants
            ],
            timestamp: Date(),
            priority: .normal,
            delivered: false,
            read: false
        )
        
        sendNotification(rankNotification)
    }
    
    func createEventStartedNotification(eventId: String, eventName: String) {
        let startNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: "all_participants",
            type: .eventStarted,
            title: "🚀 Event Started!",
            body: "\(eventName) is now live! Time to start earning points with your workouts.",
            data: [
                "eventId": eventId,
                "actionable": true,
                "deepLink": "runstrrewards://event/\(eventId)"
            ],
            timestamp: Date(),
            priority: .high,
            delivered: false,
            read: false
        )
        
        sendNotificationToEventParticipants(startNotification, eventId: eventId)
    }
    
    func createEventEndingNotification(eventId: String, eventName: String, hoursRemaining: Int) {
        let endingNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: "all_participants",
            type: .eventEnding,
            title: "⏰ Final Hours!",
            body: "\(eventName) ends in \(hoursRemaining) hours. Make your final push for the leaderboard!",
            data: [
                "eventId": eventId,
                "hoursRemaining": hoursRemaining,
                "urgency": true
            ],
            timestamp: Date(),
            priority: .high,
            delivered: false,
            read: false
        )
        
        sendNotificationToEventParticipants(endingNotification, eventId: eventId)
    }
    
    func createPrizeNotification(eventId: String, userId: String, prizeAmount: Double) {
        let eventName = getEventName(eventId: eventId)
        
        let prizeNotification = EventNotification(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            type: .prizeAwarded,
            title: "💰 Prize Awarded!",
            body: "You've earned ₿\(Int(prizeAmount)) sats from \(eventName)! Check your wallet.",
            data: [
                "eventId": eventId,
                "prizeAmount": prizeAmount,
                "deepLink": "runstrrewards://wallet"
            ],
            timestamp: Date(),
            priority: .critical,
            delivered: false,
            read: false
        )
        
        sendNotification(prizeNotification)
    }
    
    // MARK: - Notification Delivery
    
    private func sendNotification(_ notification: EventNotification) {
        // Check if user should receive this type of notification
        guard shouldSendNotification(notification) else {
            print("🔔 Notifications: Skipping notification due to settings: \(notification.type)")
            return
        }
        
        // Check quiet hours
        if isInQuietHours() && notification.priority != .critical {
            print("🔔 Notifications: Delaying notification due to quiet hours")
            scheduleNotification(notification, delay: getTimeUntilQuietHoursEnd())
            return
        }
        
        // Create iOS notification content
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.userInfo = notification.data
        content.badge = getUnreadNotificationCount() as NSNumber
        
        if notificationSettings.sound {
            content.sound = .default
        }
        
        // Add category for actions
        content.categoryIdentifier = getCategoryIdentifier(for: notification.type)
        
        // Schedule notification
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("🔔 Notifications: Failed to schedule notification - \(error.localizedDescription)")
            } else {
                // Mark as delivered
                var deliveredNotification = notification
                deliveredNotification = EventNotification(
                    id: deliveredNotification.id,
                    eventId: deliveredNotification.eventId,
                    userId: deliveredNotification.userId,
                    type: deliveredNotification.type,
                    title: deliveredNotification.title,
                    body: deliveredNotification.body,
                    data: deliveredNotification.data,
                    timestamp: deliveredNotification.timestamp,
                    priority: deliveredNotification.priority,
                    delivered: true,
                    read: false
                )
                
                self.deliveredNotifications.append(deliveredNotification)
                print("🔔 Notifications: Delivered notification: \(notification.title)")
            }
        }
        
        // Store in pending notifications
        pendingNotifications[notification.id] = notification
    }
    
    private func scheduleNotification(_ notification: EventNotification, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.userInfo = notification.data
        
        if notificationSettings.sound {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("🔔 Notifications: Failed to schedule delayed notification - \(error.localizedDescription)")
            } else {
                print("🔔 Notifications: Scheduled notification with \(delay)s delay: \(notification.title)")
            }
        }
    }
    
    private func sendNotificationToEventParticipants(_ notification: EventNotification, eventId: String) {
        // In a real implementation, this would send to all event participants
        // For now, just send to current user if they're in the event
        let currentUserId = getCurrentUserId()
        
        if isUserInEvent(userId: currentUserId, eventId: eventId) {
            var userNotification = notification
            userNotification = EventNotification(
                id: userNotification.id,
                eventId: userNotification.eventId,
                userId: currentUserId,
                type: userNotification.type,
                title: userNotification.title,
                body: userNotification.body,
                data: userNotification.data,
                timestamp: userNotification.timestamp,
                priority: userNotification.priority,
                delivered: false,
                read: false
            )
            
            sendNotification(userNotification)
        }
    }
    
    // MARK: - Settings & Validation
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        notificationSettings = settings
        print("🔔 Notifications: Settings updated")
    }
    
    private func shouldSendNotification(_ notification: EventNotification) -> Bool {
        switch notification.type {
        case .qualified, .autoEntered:
            return notificationSettings.qualificationNotifications
        case .rankUp, .rankDown:
            return notificationSettings.rankChangeNotifications
        case .goalAchieved:
            return notificationSettings.achievementNotifications
        case .prizeAwarded:
            return notificationSettings.prizeNotifications
        case .eventStarted, .eventEnding, .eventCompleted:
            return notificationSettings.eventStatusNotifications
        case .newChallenger:
            return true // Always send for new challengers
        }
    }
    
    private func shouldNotifyRankChange(progress: EventProgress) -> Bool {
        // Logic for determining significant rank changes
        // For now, notify for any rank improvement in top 20
        return progress.rank <= 20
    }
    
    private func isInQuietHours() -> Bool {
        guard let quietHours = notificationSettings.quietHours, quietHours.enabled else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let startHour = calendar.component(.hour, from: quietHours.startTime)
        let endHour = calendar.component(.hour, from: quietHours.endTime)
        
        if startHour < endHour {
            return currentHour >= startHour && currentHour < endHour
        } else {
            return currentHour >= startHour || currentHour < endHour
        }
    }
    
    private func getTimeUntilQuietHoursEnd() -> TimeInterval {
        guard let quietHours = notificationSettings.quietHours else {
            return 0
        }
        
        let now = Date()
        let endTime = quietHours.endTime
        let calendar = Calendar.current
        
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let nextEndTime = calendar.nextDate(after: now, matching: endComponents, matchingPolicy: .nextTime)
        
        return nextEndTime?.timeIntervalSince(now) ?? 0
    }
    
    // MARK: - Helper Methods
    
    private func getEventName(eventId: String) -> String {
        // In a real implementation, this would fetch from event service
        return "Event \(eventId.prefix(8))"
    }
    
    private func getCurrentUserId() -> String {
        // In a real implementation, this would come from authentication
        return "current_user"
    }
    
    private func isUserInEvent(userId: String, eventId: String) -> Bool {
        // In a real implementation, this would check event participation
        return EventProgressTracker.shared.getProgress(eventId: eventId, userId: userId) != nil
    }
    
    private func getCategoryIdentifier(for type: EventNotificationType) -> String {
        switch type {
        case .qualified, .autoEntered:
            return "EVENT_ENTRY"
        case .prizeAwarded:
            return "PRIZE_NOTIFICATION"
        case .eventCompleted:
            return "EVENT_COMPLETE"
        default:
            return "EVENT_UPDATE"
        }
    }
    
    private func getUnreadNotificationCount() -> Int {
        return deliveredNotifications.filter { !$0.read }.count + 1
    }
    
    // MARK: - Data Access
    
    func getDeliveredNotifications() -> [EventNotification] {
        return deliveredNotifications.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getUnreadNotifications() -> [EventNotification] {
        return deliveredNotifications.filter { !$0.read }
    }
    
    func markNotificationAsRead(_ notificationId: String) {
        if let index = deliveredNotifications.firstIndex(where: { $0.id == notificationId }) {
            let notification = deliveredNotifications[index]
            deliveredNotifications[index] = EventNotification(
                id: notification.id,
                eventId: notification.eventId,
                userId: notification.userId,
                type: notification.type,
                title: notification.title,
                body: notification.body,
                data: notification.data,
                timestamp: notification.timestamp,
                priority: notification.priority,
                delivered: notification.delivered,
                read: true
            )
        }
    }
    
    func clearOldNotifications() {
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 3600) // 7 days ago
        deliveredNotifications = deliveredNotifications.filter { $0.timestamp > cutoffDate }
        print("🔔 Notifications: Cleared old notifications")
    }
    
    // MARK: - Statistics
    
    func getNotificationStats() -> (delivered: Int, unread: Int, byType: [EventNotificationType: Int]) {
        let delivered = deliveredNotifications.count
        let unread = getUnreadNotifications().count
        
        var byType: [EventNotificationType: Int] = [:]
        for notification in deliveredNotifications {
            byType[notification.type] = (byType[notification.type] ?? 0) + 1
        }
        
        return (delivered, unread, byType)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}