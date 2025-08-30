import Foundation
import UserNotifications
import UIKit
import BackgroundTasks

enum SilentSyncType {
    case workoutSync
    case leaderboardCheck
    case challengeUpdate
    case fullSync
}

class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var deviceToken: String?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission & Setup
    
    func getNotificationPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    func openNotificationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
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
            try await SupabaseService.shared.storeDeviceToken(userId: userId, token: token)
            print("NotificationService: ✅ Device token stored successfully for user \(userId)")
        } catch {
            print("NotificationService: ❌ Failed to store device token: \(error)")
            // Don't fail registration for database issues - notifications can still work locally
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
        
        // Workout Completion Category
        let viewStatsAction = UNNotificationAction(
            identifier: "VIEW_WORKOUT_STATS",
            title: "View Stats",
            options: [.foreground]
        )
        
        let shareWorkoutAction = UNNotificationAction(
            identifier: "SHARE_WORKOUT",
            title: "Share",
            options: []
        )
        
        let workoutCompletionCategory = UNNotificationCategory(
            identifier: "WORKOUT_COMPLETION",
            actions: [viewStatsAction, shareWorkoutAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            workoutCategory,
            eventCategory,
            challengeCategory,
            workoutCompletionCategory
        ])
    }
    
    // MARK: - Schedule Local Notifications
    
    func scheduleWorkoutRewardNotification(amount: Int, workoutType: String) {
        // DEPRECATED: Individual workout rewards removed - use schedulePrizeDistributionNotification for actual Bitcoin payouts
        print("⚠️ DEPRECATED: scheduleWorkoutRewardNotification called - individual workout rewards no longer supported")
    }
    
    func schedulePrizeDistributionNotification(amount: Int, reason: String, teamName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Prize Received! 🎉"
        content.body = "You received \(amount) sats from Team \(teamName) for \(reason)!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "PRIZE_DISTRIBUTION"
        content.userInfo = [
            "type": "prize_distribution",
            "amount": amount,
            "reason": reason,
            "team_name": teamName
        ]
        
        // Add attachment for rich notification
        if let imageURL = createRewardImage(amount: amount) {
            if let attachment = try? UNNotificationAttachment(identifier: "prize", url: imageURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "prize_distribution_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule prize distribution: \(error)")
            }
        }
    }
    
    func scheduleWorkoutCompletionNotification(workoutType: String) {
        let content = UNMutableNotificationContent()
        content.title = "Workout Complete! 🏃‍♂️"
        content.body = "Great job on completing your \(workoutType) workout! Your progress is contributing to your team's leaderboard position."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "WORKOUT_COMPLETION"
        content.userInfo = [
            "type": "workout_completion",
            "workout_type": workoutType
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "workout_completion_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule workout completion: \(error)")
            }
        }
    }
    
    func scheduleEventCompletionNotification(eventName: String, achievement: String) {
        let content = UNMutableNotificationContent()
        content.title = "Event \(achievement) 🎉"
        content.body = "Congratulations! You've \(achievement.lowercased()) for \(eventName)! Your team captain can now distribute prizes from the team wallet."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "EVENT_COMPLETION"
        content.userInfo = [
            "type": "event_completion",
            "event_name": eventName,
            "achievement": achievement
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_completion_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule event completion: \(error)")
            }
        }
    }
    
    func scheduleEventProgressNotification(eventName: String, progress: Int, targetDescription: String) {
        let content = UNMutableNotificationContent()
        content.title = "Event Progress Update 📊"
        content.body = "You're \(progress)% towards \(targetDescription) in \(eventName). Keep going!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "EVENT_PROGRESS"
        content.userInfo = [
            "type": "event_progress",
            "event_name": eventName,
            "progress": progress
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_progress_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule event progress: \(error)")
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
    
    // MARK: - Team-Branded Notification Helper
    
    func scheduleTeamBrandedNotification(
        teamName: String,
        title: String,
        message: String,
        identifier: String,
        type: String = "team_update",
        userInfo: [String: Any] = [:],
        delay: TimeInterval = 1
    ) {
        let content = UNMutableNotificationContent()
        content.title = "\(teamName): \(title)"
        content.body = message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = type.uppercased()
        
        var fullUserInfo = userInfo
        fullUserInfo["type"] = type
        fullUserInfo["team_name"] = teamName
        content.userInfo = fullUserInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule team-branded notification for \(teamName): \(error)")
            } else {
                print("NotificationService: Team-branded notification scheduled for \(teamName): \(title)")
            }
        }
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
        workoutCompleted: Bool,
        eventReminders: Bool,
        challengeInvites: Bool,
        streakReminders: Bool,
        weeklySummaries: Bool
    ) {
        // Store preferences
        UserDefaults.standard.set(workoutRewards, forKey: "notifications.workout_rewards")
        UserDefaults.standard.set(workoutCompleted, forKey: "notifications.workout_completed")
        UserDefaults.standard.set(eventReminders, forKey: "notifications.event_reminders")
        UserDefaults.standard.set(challengeInvites, forKey: "notifications.challenge_invites")
        UserDefaults.standard.set(streakReminders, forKey: "notifications.streak_reminders")
        UserDefaults.standard.set(weeklySummaries, forKey: "notifications.weekly_summaries")
    }
    
    func shouldShowNotification(type: String) -> Bool {
        switch type {
        case "workout_reward", "prize_distribution":
            return UserDefaults.standard.bool(forKey: "notifications.workout_rewards")
        case "workout_completed":
            return UserDefaults.standard.bool(forKey: "notifications.workout_completed")
        case "event_reminder", "event_progress", "event_completion":
            return UserDefaults.standard.bool(forKey: "notifications.event_reminders")
        case "challenge_invitation":
            return UserDefaults.standard.bool(forKey: "notifications.challenge_invites")
        case "streak_reminder":
            return UserDefaults.standard.bool(forKey: "notifications.streak_reminders")
        case "weekly_summary":
            return UserDefaults.standard.bool(forKey: "notifications.weekly_summaries")
        case "leaderboard_change", "position_change":
            return UserDefaults.standard.bool(forKey: "notifications.leaderboard_changes")
        case "team_announcement":
            return UserDefaults.standard.bool(forKey: "notifications.team_announcements")
        default:
            return true
        }
    }
    
    // MARK: - Silent Push Notifications
    
    func handleSilentPushNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("NotificationService: 🔕 Received silent push notification: \(userInfo)")
        
        guard let triggerType = userInfo["trigger_type"] as? String else {
            print("NotificationService: ❌ Silent push missing trigger_type")
            completionHandler(.failed)
            return
        }
        
        // Process different types of silent push triggers
        Task {
            let result = await processSilentPushTrigger(triggerType, payload: userInfo)
            await MainActor.run {
                completionHandler(result)
            }
        }
    }
    
    private func processSilentPushTrigger(_ triggerType: String, payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        switch triggerType {
        case "workout_sync":
            return await handleWorkoutSyncTrigger(payload)
        case "leaderboard_update":
            return await handleLeaderboardUpdateTrigger(payload)
        case "event_deadline":
            return await handleEventDeadlineTrigger(payload)
        case "challenge_update":
            return await handleChallengeUpdateTrigger(payload)
        case "emergency_sync":
            return await handleEmergencySyncTrigger(payload)
        default:
            print("NotificationService: ⚠️ Unknown silent push trigger type: \(triggerType)")
            return .failed
        }
    }
    
    private func handleWorkoutSyncTrigger(_ payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("NotificationService: 🏃‍♂️ Processing workout sync trigger")
        
        // Trigger immediate workout sync
        return await performBackgroundSync(type: .workoutSync)
    }
    
    private func handleLeaderboardUpdateTrigger(_ payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("NotificationService: 🏆 Processing leaderboard update trigger")
        
        // Extract leaderboard information if available
        if let leaderboardType = payload["leaderboard_type"] as? String,
           let userId = payload["user_id"] as? String {
            print("NotificationService: Leaderboard update for \(leaderboardType), user: \(userId)")
        }
        
        // Trigger leaderboard position check
        return await performBackgroundSync(type: .leaderboardCheck)
    }
    
    private func handleEventDeadlineTrigger(_ payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("NotificationService: ⏰ Processing event deadline trigger")
        
        if let eventId = payload["event_id"] as? String,
           let eventName = payload["event_name"] as? String,
           let deadlineTimestamp = payload["deadline"] as? TimeInterval {
            
            let deadline = Date(timeIntervalSince1970: deadlineTimestamp)
            let timeUntilDeadline = deadline.timeIntervalSinceNow
            
            // Only send notification if deadline is imminent and user hasn't been notified recently
            if timeUntilDeadline > 0 && timeUntilDeadline <= 3600 { // Within 1 hour
                await scheduleUrgentEventReminder(eventId: eventId, eventName: eventName, deadline: deadline)
            }
        }
        
        return .newData
    }
    
    private func handleChallengeUpdateTrigger(_ payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("NotificationService: 💪 Processing challenge update trigger")
        
        // Trigger challenge status update
        return await performBackgroundSync(type: .challengeUpdate)
    }
    
    private func handleEmergencySyncTrigger(_ payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("NotificationService: 🚨 Processing emergency sync trigger")
        
        // Trigger full data sync
        return await performBackgroundSync(type: .fullSync)
    }
    
    private func performBackgroundSync(type: SilentSyncType) async -> UIBackgroundFetchResult {
        // Request background processing time
        let backgroundTaskId = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "SilentPushSync") {
                print("NotificationService: Background task expired during silent push processing")
            }
        }
        
        defer {
            if backgroundTaskId != .invalid {
                Task { @MainActor in
                    UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
            }
        }
        
        do {
            switch type {
            case .workoutSync:
                let backgroundTaskManager = BackgroundTaskManager.shared
                backgroundTaskManager.triggerWorkoutSync()
                return .newData
                
            case .leaderboardCheck:
                // TODO: Trigger leaderboard position tracking when service is added
                // guard let userId = AuthenticationService.shared.currentUserId else {
                //     return .failed
                // }
                // 
                // let leaderboardTracker = LeaderboardTracker.shared
                // let changes = await leaderboardTracker.trackUserPositions(userId: userId)
                // await leaderboardTracker.processPositionChanges(changes)
                // 
                // return changes.isEmpty ? .noData : .newData
                print("NotificationService: Leaderboard check triggered (placeholder)")
                return .newData
                
            case .challengeUpdate, .fullSync:
                // Trigger comprehensive sync
                let backgroundTaskManager = BackgroundTaskManager.shared
                backgroundTaskManager.triggerWorkoutSync()
                backgroundTaskManager.triggerRewardCheck()
                return .newData
            }
        } catch {
            print("NotificationService: Silent push sync failed: \(error)")
            return .failed
        }
    }
    
    private func scheduleUrgentEventReminder(eventId: String, eventName: String, deadline: Date) async {
        let timeUntilDeadline = deadline.timeIntervalSinceNow
        let timeString = formatTimeRemaining(timeUntilDeadline)
        
        await MainActor.run {
            let content = UNMutableNotificationContent()
            content.title = "⏰ Event Deadline Approaching!"
            content.body = "\(eventName) ends in \(timeString). Submit your final entries now!"
            content.sound = .default
            content.categoryIdentifier = "EVENT_URGENT"
            content.userInfo = [
                "type": "event_deadline",
                "event_id": eventId,
                "urgency": "high"
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "event_urgent_\(eventId)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("NotificationService: Failed to schedule urgent event reminder: \(error)")
                } else {
                    print("NotificationService: 🚨 Scheduled urgent event reminder for \(eventName)")
                }
            }
        }
    }
    
    private func formatTimeRemaining(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    // MARK: - Background Sync Optimization
    
    func optimizeBackgroundProcessingBudget() {
        // Track background processing usage to optimize future silent push handling
        let lastProcessingTime = UserDefaults.standard.double(forKey: "last_background_processing_time")
        let currentTime = Date().timeIntervalSince1970
        
        // Only allow background processing if it hasn't been used recently
        let timeSinceLastProcessing = currentTime - lastProcessingTime
        let minProcessingInterval: TimeInterval = 900 // 15 minutes
        
        if timeSinceLastProcessing < minProcessingInterval {
            print("NotificationService: ⏰ Background processing budget optimization: too soon since last processing")
        } else {
            UserDefaults.standard.set(currentTime, forKey: "last_background_processing_time")
        }
    }
    
    // MARK: - Position Change Notifications
    
    func schedulePositionChangeNotification(title: String, message: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "POSITION_CHANGE"
        content.userInfo = [
            "type": "position_change",
            "identifier": identifier
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule position change notification: \(error)")
            } else {
                print("NotificationService: ✅ Position change notification scheduled: \(title)")
            }
        }
    }
    
    // MARK: - P2P Challenge Notifications
    
    func scheduleChallengeInvite(challengeId: String, challengedUserId: String, challengerUsername: String, stake: Int, type: String) async {
        let content = UNMutableNotificationContent()
        content.title = "💪 Challenge Received!"
        content.body = "\(challengerUsername) challenged you to a \(type) for \(stake) sats! You have 24 hours to accept."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_INVITATION"
        content.userInfo = [
            "type": "challenge_invitation",
            "challenge_id": challengeId,
            "challenger": challengerUsername,
            "stake": stake,
            "challenge_type": type
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_invite_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge invite: \(error)")
            } else {
                print("NotificationService: ✅ Challenge invite notification scheduled")
            }
        }
    }
    
    func scheduleChallengeAccepted(challengeId: String, challengerUserId: String, challengedUsername: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⚡ Challenge Accepted!"
        content.body = "\(challengedUsername) accepted your challenge! The competition begins now."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_ACCEPTED"
        content.userInfo = [
            "type": "challenge_accepted",
            "challenge_id": challengeId,
            "opponent": challengedUsername
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_accepted_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge accepted notification: \(error)")
            } else {
                print("NotificationService: ✅ Challenge accepted notification scheduled")
            }
        }
    }
    
    func scheduleChallengeDeclined(challengeId: String, challengerUserId: String, challengedUsername: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Declined"
        content.body = "\(challengedUsername) declined your challenge. Your stake has been refunded."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_DECLINED"
        content.userInfo = [
            "type": "challenge_declined",
            "challenge_id": challengeId,
            "opponent": challengedUsername
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_declined_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge declined notification: \(error)")
            } else {
                print("NotificationService: ✅ Challenge declined notification scheduled")
            }
        }
    }
    
    // MARK: - Captain Arbitration Notifications
    
    func sendP2PChallengeNotification(toUserId: String, challengerName: String, challengeType: String) async throws {
        print("🥊 NotificationService: Sending P2P challenge notification to \(toUserId)")
        
        // Get challenged user's FCM token
        let response = try await SupabaseService.shared.client
            .from("profiles")
            .select("fcm_token, display_name")
            .eq("id", value: toUserId)
            .single()
            .execute()
        
        let profileData = try JSONDecoder().decode([String: AnyCodable].self, from: response.data)
        
        guard let fcmToken = profileData["fcm_token"]?.value as? String,
              let displayName = profileData["display_name"]?.value as? String else {
            print("❌ NotificationService: No FCM token found for user \(toUserId)")
            return
        }
        
        // Create local notification for immediate display
        let content = UNMutableNotificationContent()
        content.title = "Challenge Received! 🥊"
        content.body = "\(challengerName) challenged you to a \(challengeType) competition! Will you accept?"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "P2P_CHALLENGE"
        content.userInfo = [
            "type": "p2p_challenge",
            "challenger_name": challengerName,
            "challenge_type": challengeType,
            "to_user_id": toUserId
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "p2p_challenge_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule P2P challenge notification: \(error)")
            } else {
                print("✅ NotificationService: P2P challenge notification scheduled")
            }
        }
        
        // Send FCM notification for background delivery
        let payload: [String: Any] = [
            "to": fcmToken,
            "notification": [
                "title": "Challenge Received! 🥊",
                "body": "\(challengerName) challenged you to a \(challengeType) competition!"
            ],
            "data": [
                "type": "p2p_challenge",
                "challenger_name": challengerName,
                "challenge_type": challengeType,
                "to_user_id": toUserId
            ]
        ]
        
        // TODO: Implement FCM notification sending when backend is ready
        print("📮 NotificationService: P2P challenge notification queued for \(displayName)")
    }
    
    func notifyCaptainOfArbitrationNeeded(challengeId: String, teamId: String) async throws {
        print("⚖️ NotificationService: Notifying captain of arbitration needed for challenge \(challengeId)")
        
        // Get team captain information  
        let response = try await SupabaseService.shared.client
            .from("team_members")
            .select("""
                profiles:user_id(id, username, fcm_token),
                teams:team_id(name)
            """)
            .eq("team_id", value: teamId)
            .eq("role", value: "captain")
            .execute()
        
        if response.data.isEmpty {
            print("❌ NotificationService: No captain found for team \(teamId)")
            return
        }
        
        let captainData = try JSONDecoder().decode([[String: AnyCodable]].self, from: response.data)
        
        guard let captain = captainData.first,
              let profile = captain["profiles"]?.value as? [String: Any],
              let team = captain["teams"]?.value as? [String: Any],
              let captainId = profile["id"] as? String,
              let captainUsername = profile["username"] as? String,
              let teamName = team["name"] as? String,
              let fcmToken = profile["fcm_token"] as? String else {
            print("❌ NotificationService: Invalid captain data structure")
            return
        }
        
        // Send push notification to captain
        let content = UNMutableNotificationContent()
        content.title = "Challenge Arbitration Needed ⚖️"
        content.body = "A P2P challenge in Team \(teamName) needs your arbitration decision. Open the team wallet to review."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_ARBITRATION"
        content.userInfo = [
            "type": "challenge_arbitration",
            "challenge_id": challengeId,
            "team_id": teamId,
            "captain_id": captainId
        ]
        
        // Schedule local notification
        let identifier = "arbitration_\(challengeId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ NotificationService: Failed to schedule arbitration notification: \(error)")
            } else {
                print("✅ NotificationService: Captain \(captainUsername) notified of arbitration needed")
            }
        }
        
        // Note: FCM push notification would be sent here if implemented
    }
    
    func scheduleChallengeExpired(challengeId: String, challengerUserId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Expired"
        content.body = "Your challenge invitation expired after 24 hours. Your stake has been refunded."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_EXPIRED"
        content.userInfo = [
            "type": "challenge_expired",
            "challenge_id": challengeId
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_expired_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge expired notification: \(error)")
            } else {
                print("NotificationService: ✅ Challenge expired notification scheduled")
            }
        }
    }
    
    func scheduleChallengeProgress(challengeId: String, userId: String, position: String, opponentName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Update 📊"
        content.body = "You're currently \(position) in your challenge against \(opponentName). Keep pushing!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_PROGRESS"
        content.userInfo = [
            "type": "challenge_progress",
            "challenge_id": challengeId,
            "position": position,
            "opponent": opponentName
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_progress_\(challengeId)_\(userId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge progress notification: \(error)")
            } else {
                print("NotificationService: ✅ Challenge progress notification scheduled")
            }
        }
    }
    
    func scheduleChallengeComplete(challengeId: String, winnerId: String, amount: Int, challengeType: String) async {
        let content = UNMutableNotificationContent()
        content.title = "🏆 Challenge Won!"
        content.body = "Congratulations! You won your \(challengeType) challenge and earned \(amount) sats!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_COMPLETE"
        content.userInfo = [
            "type": "challenge_complete",
            "challenge_id": challengeId,
            "amount": amount,
            "challenge_type": challengeType
        ]
        
        // Add celebration attachment
        if let celebrationURL = createCelebrationImage(amount: amount) {
            if let attachment = try? UNNotificationAttachment(identifier: "celebration", url: celebrationURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_complete_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge complete notification: \(error)")
            } else {
                print("NotificationService: ✅ Challenge complete notification scheduled")
            }
        }
    }
    
    func scheduleArbitrationRequest(challengeId: String, captainId: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⚖️ Arbitration Needed"
        content.body = "A P2P challenge in your team is complete and needs your arbitration. Review the results and declare a winner."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_ARBITRATION"
        content.userInfo = [
            "type": "challenge_arbitration",
            "challenge_id": challengeId,
            "requires_action": true
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "arbitration_\(challengeId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule arbitration request: \(error)")
            } else {
                print("NotificationService: ✅ Arbitration request notification scheduled")
            }
        }
    }
    
    func scheduleChallengeReminder(challengeId: String, userId: String, hoursLeft: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Challenge Reminder"
        
        if hoursLeft > 1 {
            content.body = "\(hoursLeft) hours left to accept your challenge! Don't let this opportunity slip away."
        } else {
            content.body = "Less than 1 hour left to accept your challenge! Time is running out!"
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "CHALLENGE_REMINDER"
        content.userInfo = [
            "type": "challenge_reminder",
            "challenge_id": challengeId,
            "hours_left": hoursLeft
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_reminder_\(challengeId)_\(hoursLeft)h",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule challenge reminder: \(error)")
            } else {
                print("NotificationService: ✅ Challenge reminder notification scheduled")
            }
        }
    }
    
    // MARK: - Challenge Notification Helpers
    
    private func createCelebrationImage(amount: Int) -> URL? {
        // Create a simple celebration image for winning notifications
        // For now, return nil - could implement dynamic image generation
        return nil
    }
    
    // MARK: - Silent Push Registration
    
    func configureSilentPushNotifications() {
        // This would typically involve server-side configuration
        // to send silent push notifications with the appropriate payload
        print("NotificationService: 🔕 Silent push notifications configured")
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
        case "VIEW_WORKOUT_STATS":
            handleViewWorkoutStats(userInfo: userInfo)
        case "SHARE_WORKOUT":
            handleShareWorkout(userInfo: userInfo)
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
        guard let challengeId = userInfo["challenge_id"] as? String,
              let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                let updatedChallenge = try await P2PChallengeService.shared.acceptChallenge(challengeId: challengeId, userId: userId)
                print("NotificationService: ✅ Challenge accepted successfully")
                
                // Navigate to challenges to show active challenge
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .navigateToChallenges,
                        object: nil,
                        userInfo: ["challenge_id": challengeId, "action": "view_active"]
                    )
                }
            } catch {
                print("NotificationService: ❌ Failed to accept challenge: \(error)")
                await MainActor.run {
                    // Show error to user
                    NotificationCenter.default.post(
                        name: .showError,
                        object: nil,
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
    }
    
    private func handleDeclineChallenge(userInfo: [AnyHashable: Any]) {
        guard let challengeId = userInfo["challenge_id"] as? String,
              let userId = AuthenticationService.shared.currentUserId else { return }
        
        Task {
            do {
                let updatedChallenge = try await P2PChallengeService.shared.declineChallenge(challengeId: challengeId, userId: userId)
                print("NotificationService: ✅ Challenge declined successfully")
                
                // Show confirmation to user
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .showMessage,
                        object: nil,
                        userInfo: ["message": "Challenge declined. Stake has been refunded."]
                    )
                }
            } catch {
                print("NotificationService: ❌ Failed to decline challenge: \(error)")
                await MainActor.run {
                    // Show error to user
                    NotificationCenter.default.post(
                        name: .showError,
                        object: nil,
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
    }
    
    private func handleSnoozeReminder(userInfo: [AnyHashable: Any]) {
        guard let eventId = userInfo["event_id"] as? String,
              let eventName = userInfo["event_name"] as? String else { return }
        
        // Reschedule reminder for 1 hour later
        let reminderDate = Date().addingTimeInterval(3600)
        scheduleEventReminder(eventName: eventName, eventId: eventId, reminderDate: reminderDate)
    }
    
    private func handleViewWorkoutStats(userInfo: [AnyHashable: Any]) {
        // Navigate to workouts page to show workout details
        NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
    }
    
    private func handleShareWorkout(userInfo: [AnyHashable: Any]) {
        // Share workout achievement
        guard let workoutType = userInfo["workout_type"] as? String,
              let estimatedSats = userInfo["estimated_sats"] as? Int else { return }
        
        let shareText = "Just completed a \(workoutType) workout and earned \(estimatedSats) sats! 💪⚡ #RunstrRewards"
        
        NotificationCenter.default.post(
            name: .shareWorkout,
            object: nil,
            userInfo: ["shareText": shareText]
        )
    }
    
    private func handleDefaultAction(userInfo: [AnyHashable: Any]) {
        // Handle tap on notification body
        if let type = userInfo["type"] as? String {
            switch type {
            case "workout_reward":
                NotificationCenter.default.post(name: .navigateToEarnings, object: nil)
            case "workout_completed":
                NotificationCenter.default.post(name: .navigateToWorkouts, object: nil)
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
    static let shareWorkout = Notification.Name("shareWorkout")
    static let showError = Notification.Name("showError")
    static let showMessage = Notification.Name("showMessage")
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