import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var deviceToken: String?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission & Setup
    
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional, .criticalAlert]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            if granted {
                await registerForRemoteNotifications()
                setupNotificationCategories()
            }
            
            print("NotificationService: Authorization granted: \(granted)")
            return granted
        } catch {
            print("NotificationService: Authorization error: \(error)")
            throw NotificationError.authorizationFailed
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func setDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        // Store token in Supabase
        Task {
            await storeDeviceToken(token)
        }
        
        print("NotificationService: Device token registered: \(token)")
    }
    
    private func storeDeviceToken(_ token: String) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        // Store in Supabase notification_tokens table
        // This will be used for sending targeted push notifications
        do {
            // TODO: Implement Supabase storage
            print("NotificationService: Storing device token for user \(userId)")
        } catch {
            print("NotificationService: Failed to store device token: \(error)")
        }
    }
    
    // MARK: - Notification Categories
    
    private func setupNotificationCategories() {
        // Workout Reward Category
        let claimAction = UNNotificationAction(
            identifier: "CLAIM_REWARD",
            title: "Claim Reward",
            options: [.foreground]
        )
        
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: []
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_REWARD",
            actions: [claimAction, viewDetailsAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Event Reminder Category
        let joinEventAction = UNNotificationAction(
            identifier: "JOIN_EVENT",
            title: "Join Event",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_REMINDER",
            title: "Remind in 1 hour",
            options: []
        )
        
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [joinEventAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Challenge Invitation Category
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_CHALLENGE",
            title: "Accept",
            options: [.foreground]
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_CHALLENGE",
            title: "Decline",
            options: [.destructive]
        )
        
        let challengeCategory = UNNotificationCategory(
            identifier: "CHALLENGE_INVITATION",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            workoutCategory,
            eventCategory,
            challengeCategory
        ])
    }
    
    // MARK: - Schedule Local Notifications
    
    func scheduleWorkoutRewardNotification(amount: Int, workoutType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Reward Earned! 🎉"
        content.body = "You earned \(amount) sats for completing your \(workoutType) workout!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WORKOUT_REWARD"
        content.userInfo = [
            "type": "workout_reward",
            "amount": amount,
            "workout_type": workoutType
        ]
        
        // Add attachment for rich notification
        if let imageURL = createRewardImage(amount: amount) {
            if let attachment = try? UNNotificationAttachment(identifier: "reward", url: imageURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "workout_reward_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule workout reward: \(error)")
            }
        }
    }
    
    func scheduleEventReminder(eventName: String, eventId: String, reminderDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Event Starting Soon! ⏰"
        content.body = "\(eventName) starts in 1 hour. Don't miss out on the prize pool!"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = [
            "type": "event_reminder",
            "event_id": eventId,
            "event_name": eventName
        ]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "event_\(eventId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule event reminder: \(error)")
            }
        }
    }
    
    func scheduleChallengeInvitation(challengeName: String, teamName: String, challengeId: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Challenge Invitation! 💪"
        content.body = "\(teamName) invited you to join '\(challengeName)'"
        content.sound = .default
        content.categoryIdentifier = "CHALLENGE_INVITATION"
        content.userInfo = [
            "type": "challenge_invitation",
            "challenge_id": challengeId,
            "challenge_name": challengeName,
            "team_name": teamName
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge invitation: \(error)")
            }
        }
    }
    
    func scheduleStreakReminder(currentStreak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Alive! 🔥"
        content.body = "You're on a \(currentStreak) day streak! Complete a workout today to keep it going."
        content.sound = .default
        content.userInfo = [
            "type": "streak_reminder",
            "current_streak": currentStreak
        ]
        
        // Schedule for 8 PM local time
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule streak reminder: \(error)")
            }
        }
    }
    
    func scheduleWeeklySummary(workouts: Int, earnings: Int, rank: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Weekly Summary 📊"
        content.body = "This week: \(workouts) workouts, \(earnings) sats earned, Rank #\(rank)"
        content.sound = .default
        content.userInfo = [
            "type": "weekly_summary",
            "workouts": workouts,
            "earnings": earnings,
            "rank": rank
        ]
        
        // Schedule for Sunday evening
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule weekly summary: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Badge Management
    
    @MainActor
    func updateBadgeCount(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    @MainActor
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Helper Methods
    
    private func createRewardImage(amount: Int) -> URL? {
        // Create a simple image showing reward amount
        // This would generate a custom image for rich notifications
        // For now, return nil
        return nil
    }
    
    // MARK: - Notification Settings
    
    func updateNotificationPreferences(
        workoutRewards: Bool,
        eventReminders: Bool,
        challengeInvites: Bool,
        streakReminders: Bool,
        weeklySummaries: Bool
    ) {
        // Store preferences
        UserDefaults.standard.set(workoutRewards, forKey: "notifications.workout_rewards")
        UserDefaults.standard.set(eventReminders, forKey: "notifications.event_reminders")
        UserDefaults.standard.set(challengeInvites, forKey: "notifications.challenge_invites")
        UserDefaults.standard.set(streakReminders, forKey: "notifications.streak_reminders")
        UserDefaults.standard.set(weeklySummaries, forKey: "notifications.weekly_summaries")
    }
    
    func shouldShowNotification(type: String) -> Bool {
        switch type {
        case "workout_reward":
            return UserDefaults.standard.bool(forKey: "notifications.workout_rewards")
        case "event_reminder":
            return UserDefaults.standard.bool(forKey: "notifications.event_reminders")
        case "challenge_invitation":
            return UserDefaults.standard.bool(forKey: "notifications.challenge_invites")
        case "streak_reminder":
            return UserDefaults.standard.bool(forKey: "notifications.streak_reminders")
        case "weekly_summary":
            return UserDefaults.standard.bool(forKey: "notifications.weekly_summaries")
        default:
            return true
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        let userInfo = notification.request.content.userInfo
        let type = userInfo["type"] as? String ?? ""
        
        if shouldShowNotification(type: type) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle notification actions
        switch actionIdentifier {
        case "CLAIM_REWARD":
            handleClaimReward(userInfo: userInfo)
        case "VIEW_DETAILS":
            handleViewDetails(userInfo: userInfo)
        case "JOIN_EVENT":
            handleJoinEvent(userInfo: userInfo)
        case "ACCEPT_CHALLENGE":
            handleAcceptChallenge(userInfo: userInfo)
        case "DECLINE_CHALLENGE":
            handleDeclineChallenge(userInfo: userInfo)
        case "SNOOZE_REMINDER":
            handleSnoozeReminder(userInfo: userInfo)
        case UNNotificationDefaultActionIdentifier:
            handleDefaultAction(userInfo: userInfo)
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    
    private func handleClaimReward(userInfo: [AnyHashable: Any]) {
        guard let amount = userInfo["amount"] as? Int else { return }
        
        // Navigate to earnings page
        NotificationCenter.default.post(
            name: .navigateToEarnings,
            object: nil,
            userInfo: ["amount": amount]
        )
    }
    
    private func handleViewDetails(userInfo: [AnyHashable: Any]) {
        // Navigate to appropriate details page based on notification type
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout_reward":
                NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
            case "event_reminder":
                if let eventId = userInfo["event_id"] as? String {
                    NotificationCenter.default.post(
                        name: .navigateToEvent,
                        object: nil,
                        userInfo: ["event_id": eventId]
                    )
                }
            default:
                break
            }
        }
    }
    
    private func handleJoinEvent(userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["event_id"] as? String else { return }
        
        NotificationCenter.default.post(
            name: .navigateToEvent,
            object: nil,
            userInfo: ["event_id": eventId, "action": "join"]
        )
    }
    
    private func handleAcceptChallenge(userInfo: [AnyHashable: Any]) {
        guard let challengeId = userInfo["challenge_id"] as? String else { return }
        
        Task {
            // Accept challenge via API
            print("NotificationService: Accepting challenge \(challengeId)")
        }
    }
    
    private func handleDeclineChallenge(userInfo: [AnyHashable: Any]) {
        guard let challengeId = userInfo["challenge_id"] as? String else { return }
        
        print("NotificationService: Declining challenge \(challengeId)")
    }
    
    private func handleSnoozeReminder(userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["event_id"] as? String,
              let eventName = userInfo["event_name"] as? String else { return }
        
        // Reschedule reminder for 1 hour later
        let reminderDate = Date().addingTimeInterval(3600)
        scheduleEventReminder(eventName: eventName, eventId: eventId, reminderDate: reminderDate)
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Handle tap on notification body
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout_reward":
                NotificationCenter.default.post(name: .navigateToEarnings, object: nil)
            case "event_reminder":
                NotificationCenter.default.post(name: .navigateToEvents, object: nil)
            case "challenge_invitation":
                NotificationCenter.default.post(name: .navigateToChallenges, object: nil)
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToEarnings = Notification.Name("navigateToEarnings")
    static let navigateToWorkouts = Notification.Name("navigateToWorkouts")
    static let navigateToEvent = Notification.Name("navigateToEvent")
    static let navigateToEvents = Notification.Name("navigateToEvents")
    static let navigateToChallenges = Notification.Name("navigateToChallenges")
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case authorizationFailed
    case deviceTokenMissing
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Failed to get notification permissions"
        case .deviceTokenMissing:
            return "Device token not available"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
}