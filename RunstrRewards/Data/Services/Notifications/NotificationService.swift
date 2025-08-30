import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    // MARK: - Components
    private let scheduler = NotificationScheduler.shared
    private let handlers = NotificationHandlers.shared
    private let supabase = SupabaseService.shared
    
    // MARK: - Properties
    private var silentPushToken: String?
    
    private override init() {
        super.init()
        setupDelegate()
    }
    
    // MARK: - Public Interface
    
    func requestPermission() async throws -> Bool {
        return try await scheduler.requestPermission()
    }
    
    func sendWorkoutRewardNotification(
        userId: String,
        workoutType: String,
        points: Int,
        teamBranding: TeamBranding? = nil
    ) async {
        let title = "💪 Workout Completed!"
        let body = "Great \(workoutType.lowercased())! You earned \(points) points."
        
        do {
            try await scheduler.scheduleWorkoutReward(
                identifier: "workout_\(userId)_\(Date().timeIntervalSince1970)",
                title: title,
                body: body,
                teamBranding: teamBranding,
                userInfo: [
                    "type": "workout_reward",
                    "points": points,
                    "workout_type": workoutType
                ]
            )
            
            // Store in inbox
            storeNotificationInInbox(
                userId: userId,
                type: "workout_reward",
                title: title,
                body: body,
                teamId: teamBranding?.teamId,
                actionData: ["points": String(points)]
            )
            
        } catch {
            print("NotificationService: ❌ Failed to send workout reward notification: \(error)")
        }
    }
    
    func sendTeamPositionUpdate(
        userId: String,
        newPosition: Int,
        oldPosition: Int,
        teamBranding: TeamBranding
    ) async {
        await handlers.sendPositionChangeNotification(
            userId: userId,
            newPosition: newPosition,
            oldPosition: oldPosition,
            teamId: teamBranding.teamId
        )
    }
    
    func sendChallengeRequest(
        fromUserId: String,
        toUserId: String,
        challengeId: String,
        message: String,
        teamBranding: TeamBranding
    ) async {
        let title = "⚡ Challenge Request!"
        let body = message
        
        do {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.subtitle = teamBranding.teamName
            content.sound = .default
            content.categoryIdentifier = "CHALLENGE_REQUEST"
            content.userInfo = [
                "type": "challenge_request",
                "challenge_id": challengeId,
                "from_user_id": fromUserId,
                "team_id": teamBranding.teamId
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "challenge_\(challengeId)",
                content: content,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(request)
            
            // Store in inbox
            try await NotificationInboxService.shared.storeChallengeNotification(
                to: toUserId,
                from: fromUserId,
                challengeId: challengeId,
                type: "challenge_request",
                title: title,
                body: body,
                teamId: teamBranding.teamId
            )
            
            print("NotificationService: ✅ Sent challenge request notification")
            
        } catch {
            print("NotificationService: ❌ Failed to send challenge request: \(error)")
        }
    }
    
    func sendEventReminder(
        userId: String,
        eventName: String,
        minutesUntilStart: Int,
        teamBranding: TeamBranding
    ) async {
        let title = "⏰ Event Starting Soon!"
        let body = "\(eventName) starts in \(minutesUntilStart) minutes. Get ready!"
        
        do {
            try await scheduler.scheduleTeamUpdate(
                identifier: "event_reminder_\(userId)_\(Date().timeIntervalSince1970)",
                title: title,
                body: body,
                teamBranding: teamBranding,
                userInfo: [
                    "type": "event_reminder",
                    "minutes_until_start": minutesUntilStart
                ]
            )
            
            // Store in inbox
            storeNotificationInInbox(
                userId: userId,
                type: "event_reminder",
                title: title,
                body: body,
                teamId: teamBranding.teamId
            )
            
        } catch {
            print("NotificationService: ❌ Failed to send event reminder: \(error)")
        }
    }
    
    func scheduleChallengeInvitation(
        challengeId: String,
        fromUserId: String,
        toUserId: String,
        teamBranding: TeamBranding,
        message: String
    ) async {
        await sendChallengeRequest(
            fromUserId: fromUserId,
            toUserId: toUserId,
            challengeId: challengeId,
            message: message,
            teamBranding: teamBranding
        )
    }
    
    func scheduleTeamBrandedNotification(
        userId: String,
        title: String,
        body: String,
        teamBranding: TeamBranding,
        type: String = "team_update",
        delay: TimeInterval = 1.0,
        actionData: [String: String]? = nil
    ) async {
        do {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.subtitle = teamBranding.teamName
            content.sound = .default
            content.userInfo = [
                "type": type,
                "team_id": teamBranding.teamId
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(type)_\(userId)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(request)
            
            // Store in inbox
            storeNotificationInInbox(
                userId: userId,
                type: type,
                title: title,
                body: body,
                teamId: teamBranding.teamId,
                actionData: actionData
            )
            
            print("NotificationService: ✅ Scheduled team-branded notification")
            
        } catch {
            print("NotificationService: ❌ Failed to schedule team-branded notification: \(error)")
        }
    }
    
    // MARK: - Silent Push Registration
    
    func registerForSilentPushNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func updatePushToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        self.silentPushToken = tokenString
        
        Task {
            await storePushToken(tokenString)
        }
        
        print("NotificationService: ✅ Updated push token")
    }
    
    private func storePushToken(_ token: String) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        do {
            try await supabase.client
                .from("user_push_tokens")
                .upsert([
                    "user_id": userId,
                    "token": token,
                    "platform": "ios",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            print("NotificationService: ✅ Stored push token in database")
        } catch {
            print("NotificationService: ❌ Failed to store push token: \(error)")
        }
    }
    
    // MARK: - Background Processing
    
    func processSilentPush(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        return await handlers.processSilentPush(userInfo: userInfo)
    }
    
    // MARK: - Notification Inbox Integration
    
    func storeNotificationInInbox(
        userId: String,
        type: String,
        title: String,
        body: String? = nil,
        teamId: String? = nil,
        fromUserId: String? = nil,
        eventId: String? = nil,
        actionType: String? = nil,
        actionData: [String: String]? = nil,
        expiresAt: Date? = nil
    ) {
        Task {
            do {
                try await NotificationInboxService.shared.storeNotification(
                    userId: userId,
                    type: type,
                    title: title,
                    body: body,
                    teamId: teamId,
                    fromUserId: fromUserId,
                    eventId: eventId,
                    actionType: actionType,
                    actionData: actionData,
                    expiresAt: expiresAt
                )
                print("NotificationService: 📥 Notification stored in inbox: \(title)")
            } catch {
                print("NotificationService: ❌ Failed to store notification in inbox: \(error)")
            }
        }
    }
    
    func scheduleAndStoreNotification(
        identifier: String,
        title: String,
        body: String,
        teamBranding: TeamBranding?,
        userInfo: [AnyHashable: Any] = [:],
        triggerDate: Date? = nil,
        userId: String,
        type: String
    ) async throws {
        
        // Schedule the notification
        try await scheduler.scheduleWorkoutReward(
            identifier: identifier,
            title: title,
            body: body,
            teamBranding: teamBranding,
            userInfo: userInfo,
            triggerDate: triggerDate
        )
        
        // Store in inbox
        storeNotificationInInbox(
            userId: userId,
            type: type,
            title: title,
            body: body,
            teamId: teamBranding?.teamId
        )
    }
    
    func schedulePrizeDistributionNotification(
        userId: String,
        eventId: String,
        prizeAmount: Int,
        position: Int,
        teamBranding: TeamBranding
    ) async {
        let title = "🏆 Prize Won!"
        let body = "Congratulations! You finished #\(position) and earned \(prizeAmount) sats!"
        
        await scheduleTeamBrandedNotification(
            userId: userId,
            title: title,
            body: body,
            teamBranding: teamBranding,
            type: "prize_distribution",
            delay: 1.0,
            actionData: [
                "event_id": eventId,
                "prize_amount": String(prizeAmount),
                "position": String(position)
            ]
        )
    }
    
    // MARK: - Legacy Compatibility Methods
    // These methods are called by BackgroundTaskManager and maintain backward compatibility
    
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule event reminder: \(error)")
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
        
        UNUserNotificationCenter.current().add(request) { error in
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
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule weekly summary: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) async {
        await scheduler.updateBadgeCount(count)
    }
    
    func clearBadge() async {
        await scheduler.clearBadge()
    }
    
    // MARK: - Setup
    
    private func setupDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        Task {
            await handlers.handleNotificationAction(identifier: actionIdentifier, userInfo: userInfo)
            completionHandler()
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}