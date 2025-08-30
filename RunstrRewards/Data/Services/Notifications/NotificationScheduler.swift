import Foundation
import UserNotifications

class NotificationScheduler {
    static let shared = NotificationScheduler()
    
    private init() {}
    
    // MARK: - Permission & Setup
    
    func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
        do {
            let granted = try await center.requestAuthorization(options: options)
            
            if granted {
                await setupNotificationCategories()
                print("NotificationScheduler: ✅ Permission granted")
            } else {
                print("NotificationScheduler: ❌ Permission denied")
            }
            
            return granted
        } catch {
            print("NotificationScheduler: ❌ Permission request failed: \(error)")
            throw error
        }
    }
    
    func setupNotificationCategories() async {
        let center = UNUserNotificationCenter.current()
        
        // Workout reward category
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: [.foreground]
        )
        
        let workoutCategory = UNNotificationCategory(
            identifier: "WORKOUT_REWARD",
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Team update category
        let viewLeaderboardAction = UNNotificationAction(
            identifier: "VIEW_LEADERBOARD",
            title: "View Leaderboard",
            options: [.foreground]
        )
        
        let teamCategory = UNNotificationCategory(
            identifier: "TEAM_UPDATE",
            actions: [viewLeaderboardAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Challenge category
        let acceptAction = UNNotificationAction(
            identifier: "ACCEPT_CHALLENGE",
            title: "Accept",
            options: []
        )
        
        let declineAction = UNNotificationAction(
            identifier: "DECLINE_CHALLENGE",
            title: "Decline",
            options: []
        )
        
        let challengeCategory = UNNotificationCategory(
            identifier: "CHALLENGE_REQUEST",
            actions: [acceptAction, declineAction],
            intentIdentifiers: [],
            options: []
        )
        
        await center.setNotificationCategories([
            workoutCategory,
            teamCategory, 
            challengeCategory
        ])
        
        print("NotificationScheduler: ✅ Notification categories configured")
    }
    
    // MARK: - Schedule Local Notifications
    
    func scheduleWorkoutReward(
        identifier: String,
        title: String,
        body: String,
        teamBranding: TeamBranding? = nil,
        userInfo: [AnyHashable: Any] = [:],
        triggerDate: Date? = nil
    ) async throws {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_REWARD"
        
        // Add team branding if provided
        if let branding = teamBranding {
            content.subtitle = branding.teamName
            content.userInfo = userInfo.merging([
                "team_id": branding.teamId,
                "team_name": branding.teamName
            ]) { (_, new) in new }
        } else {
            content.userInfo = userInfo
        }
        
        // Determine trigger
        let trigger: UNNotificationTrigger?
        if let triggerDate = triggerDate, triggerDate > Date() {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("NotificationScheduler: ✅ Scheduled notification: \(title)")
        } catch {
            print("NotificationScheduler: ❌ Failed to schedule notification: \(error)")
            throw error
        }
    }
    
    func scheduleTeamUpdate(
        identifier: String,
        title: String,
        body: String,
        teamBranding: TeamBranding,
        userInfo: [AnyHashable: Any] = [:],
        triggerDate: Date? = nil
    ) async throws {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.subtitle = teamBranding.teamName
        content.sound = .default
        content.categoryIdentifier = "TEAM_UPDATE"
        
        content.userInfo = userInfo.merging([
            "team_id": teamBranding.teamId,
            "team_name": teamBranding.teamName,
            "team_color": teamBranding.primaryColor
        ]) { (_, new) in new }
        
        let trigger: UNNotificationTrigger?
        if let triggerDate = triggerDate, triggerDate > Date() {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: triggerDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
        print("NotificationScheduler: ✅ Scheduled team update: \(title)")
    }
    
    // MARK: - Cancel Notifications
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("NotificationScheduler: ❌ Cancelled notification: \(identifier)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("NotificationScheduler: ❌ Cancelled all pending notifications")
    }
    
    func cancelNotifications(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("NotificationScheduler: ❌ Cancelled \(identifiers.count) notifications")
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount(_ count: Int) async {
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    func clearBadge() async {
        await updateBadgeCount(0)
    }
    
    func incrementBadge() async {
        let current = await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber
        }
        await updateBadgeCount(current + 1)
    }
}

// MARK: - Team Branding Model

struct TeamBranding {
    let teamId: String
    let teamName: String
    let primaryColor: String
    let logoUrl: String?
    
    init(teamId: String, teamName: String, teamColor: String, teamLogoUrl: String?) {
        self.teamId = teamId
        self.teamName = teamName
        self.primaryColor = teamColor
        self.logoUrl = teamLogoUrl
    }
    
    init(teamData: TeamData) {
        self.teamId = teamData.id
        self.teamName = teamData.name
        self.primaryColor = teamData.primaryColor ?? "#007AFF"
        self.logoUrl = teamData.logoUrl
    }
}