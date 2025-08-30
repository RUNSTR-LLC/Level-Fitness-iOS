import Foundation
import UIKit
import UserNotifications

class NotificationHandlers: NSObject {
    static let shared = NotificationHandlers()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Action Handlers
    
    func handleNotificationAction(identifier: String, userInfo: [AnyHashable: Any]) async {
        print("NotificationHandlers: Handling action \(identifier)")
        
        switch identifier {
        case "VIEW_DETAILS":
            await handleViewDetails(userInfo: userInfo)
            
        case "VIEW_LEADERBOARD":
            await handleViewLeaderboard(userInfo: userInfo)
            
        case "ACCEPT_CHALLENGE":
            await handleAcceptChallenge(userInfo: userInfo)
            
        case "DECLINE_CHALLENGE":
            await handleDeclineChallenge(userInfo: userInfo)
            
        default:
            print("NotificationHandlers: Unknown action identifier: \(identifier)")
        }
    }
    
    private func handleViewDetails(userInfo: [AnyHashable: Any]) async {
        guard let workoutId = userInfo["workout_id"] as? String else { return }
        
        await MainActor.run {
            // Navigate to workout details
            NotificationCenter.default.post(
                name: .navigateToWorkoutDetails,
                object: nil,
                userInfo: ["workout_id": workoutId]
            )
        }
    }
    
    private func handleViewLeaderboard(userInfo: [AnyHashable: Any]) async {
        let teamId = userInfo["team_id"] as? String
        
        await MainActor.run {
            NotificationCenter.default.post(
                name: .navigateToLeaderboard,
                object: nil,
                userInfo: teamId != nil ? ["team_id": teamId!] : [:]
            )
        }
    }
    
    private func handleAcceptChallenge(userInfo: [AnyHashable: Any]) async {
        guard let challengeId = userInfo["challenge_id"] as? String,
              let userId = AuthenticationService.shared.currentUserId else { return }
        
        do {
            try await SupabaseService.shared.acceptChallenge(challengeId: challengeId, userId: userId)
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .challengeAccepted,
                    object: nil,
                    userInfo: ["challenge_id": challengeId]
                )
            }
            
            print("NotificationHandlers: ✅ Accepted challenge \(challengeId)")
        } catch {
            print("NotificationHandlers: ❌ Failed to accept challenge: \(error)")
        }
    }
    
    private func handleDeclineChallenge(userInfo: [AnyHashable: Any]) async {
        guard let challengeId = userInfo["challenge_id"] as? String,
              let userId = AuthenticationService.shared.currentUserId else { return }
        
        do {
            try await SupabaseService.shared.declineChallenge(challengeId: challengeId, userId: userId)
            
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .challengeDeclined,
                    object: nil,
                    userInfo: ["challenge_id": challengeId]
                )
            }
            
            print("NotificationHandlers: ✅ Declined challenge \(challengeId)")
        } catch {
            print("NotificationHandlers: ❌ Failed to decline challenge: \(error)")
        }
    }
    
    // MARK: - Position Change Notifications
    
    func sendPositionChangeNotification(
        userId: String,
        newPosition: Int,
        oldPosition: Int,
        teamId: String? = nil
    ) async {
        let positionChange = oldPosition - newPosition
        
        guard positionChange > 0 else { return } // Only notify for improvements
        
        let title: String
        let body: String
        
        if newPosition <= 3 {
            title = "🏆 Top 3!"
            body = "Amazing! You're now #\(newPosition) on the leaderboard!"
        } else if positionChange >= 10 {
            title = "🚀 Big Move!"
            body = "You jumped \(positionChange) spots to #\(newPosition)!"
        } else if positionChange >= 3 {
            title = "📈 Moving Up!"
            body = "You moved up \(positionChange) spots to #\(newPosition)!"
        } else {
            return // Don't notify for small changes
        }
        
        do {
            let teamBranding: TeamBranding?
            if let teamId = teamId {
                let teamData = try await TeamDataService.shared.fetchTeamDetails(teamId: teamId)
                teamBranding = TeamBranding(teamData: teamData)
            } else {
                teamBranding = nil
            }
            
            try await NotificationScheduler.shared.scheduleTeamUpdate(
                identifier: "position_change_\(userId)_\(Date().timeIntervalSince1970)",
                title: title,
                body: body,
                teamBranding: teamBranding ?? TeamBranding.defaultBranding,
                userInfo: [
                    "type": "position_change",
                    "new_position": newPosition,
                    "position_change": positionChange,
                    "team_id": teamId as Any
                ]
            )
            
            // Store in inbox
            try await NotificationInboxService.shared.storeNotification(
                userId: userId,
                type: "position_change",
                title: title,
                body: body,
                teamId: teamId,
                actionType: "view_leaderboard",
                actionData: ["position": String(newPosition)]
            )
            
        } catch {
            print("NotificationHandlers: ❌ Failed to send position change notification: \(error)")
        }
    }
    
    func scheduleLeaderboardUpdate(userId: String, message: String, teamBranding: TeamBranding?) async {
        do {
            try await NotificationScheduler.shared.scheduleTeamUpdate(
                identifier: "leaderboard_\(userId)_\(Date().timeIntervalSince1970)",
                title: "Leaderboard Update",
                body: message,
                teamBranding: teamBranding ?? TeamBranding.defaultBranding,
                userInfo: [
                    "type": "leaderboard_update",
                    "user_id": userId
                ]
            )
        } catch {
            print("NotificationHandlers: ❌ Failed to schedule leaderboard update: \(error)")
        }
    }
    
    // MARK: - Silent Push Processing
    
    func processSilentPush(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let pushType = userInfo["type"] as? String else {
            return .noData
        }
        
        print("NotificationHandlers: Processing silent push: \(pushType)")
        
        switch pushType {
        case "workout_sync":
            return await processWorkoutSyncPush()
            
        case "leaderboard_update":
            return await processLeaderboardUpdatePush(userInfo: userInfo)
            
        case "team_update":
            return await processTeamUpdatePush(userInfo: userInfo)
            
        case "challenge_request":
            return await processChallengeRequestPush(userInfo: userInfo)
            
        default:
            print("NotificationHandlers: Unknown silent push type: \(pushType)")
            return .noData
        }
    }
    
    private func processWorkoutSyncPush() async -> UIBackgroundFetchResult {
        do {
            // Trigger background workout sync
            let workouts = await HealthKitService.shared.detectNewWorkouts()
            
            if !workouts.isEmpty {
                print("NotificationHandlers: ✅ Processed \(workouts.count) workouts from silent push")
                return .newData
            } else {
                return .noData
            }
        } catch {
            print("NotificationHandlers: ❌ Failed to process workout sync push: \(error)")
            return .failed
        }
    }
    
    private func processLeaderboardUpdatePush(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let userId = userInfo["user_id"] as? String else { return .noData }
        
        print("NotificationHandlers: Leaderboard check triggered for user \(userId)")
        return .newData
    }
    
    private func processTeamUpdatePush(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let teamId = userInfo["team_id"] as? String else { return .noData }
        
        print("NotificationHandlers: Team update processed for \(teamId)")
        return .newData
    }
    
    private func processChallengeRequestPush(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let challengeId = userInfo["challenge_id"] as? String else { return .noData }
        
        print("NotificationHandlers: Challenge request processed: \(challengeId)")
        return .newData
    }
    
    // MARK: - Notification Settings
    
    func getNotificationSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }
    
    func areNotificationsEnabled() async -> Bool {
        let settings = await getNotificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func canScheduleNotifications() async -> Bool {
        let settings = await getNotificationSettings()
        return settings.authorizationStatus == .authorized && 
               settings.alertSetting == .enabled
    }
}

// MARK: - Team Branding Extension

extension TeamBranding {
    static let defaultBranding = TeamBranding(
        teamId: "",
        teamName: "RunstrRewards",
        teamColor: "#007AFF",
        teamLogoUrl: nil
    )
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToWorkoutDetails = Notification.Name("navigateToWorkoutDetails")
    static let navigateToLeaderboard = Notification.Name("navigateToLeaderboard")
    static let challengeAccepted = Notification.Name("challengeAccepted")
    static let challengeDeclined = Notification.Name("challengeDeclined")
}