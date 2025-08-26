import Foundation
import UserNotifications
import Supabase

// MARK: - Data Models

struct TeamAnnouncement {
    let id: String
    let teamId: String
    let captainId: String
    let title: String
    let message: String
    let createdAt: Date
    let priority: AnnouncementPriority
    let targetMemberIds: [String]? // nil means all members
    
    enum AnnouncementPriority: String, CaseIterable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case urgent = "urgent"
        
        var displayName: String {
            switch self {
            case .low: return "Info"
            case .normal: return "Normal"
            case .high: return "Important"
            case .urgent: return "Urgent"
            }
        }
    }
}

// MARK: - Captain Announcement Service

class CaptainAnnouncementService {
    static let shared = CaptainAnnouncementService()
    
    private let supabaseService = SupabaseService.shared
    private let notificationService = NotificationService.shared
    
    private init() {}
    
    // MARK: - Send Announcements
    
    func sendTeamAnnouncement(
        teamId: String,
        title: String,
        message: String,
        priority: TeamAnnouncement.AnnouncementPriority = .normal,
        targetMemberIds: [String]? = nil
    ) async throws {
        guard let captainSession = AuthenticationService.shared.loadSession() else {
            throw AnnouncementError.notAuthenticated
        }
        
        // Verify captain has permission to send announcements for this team
        let hasPermission = await verifyCaptainPermission(captainId: captainSession.id, teamId: teamId)
        guard hasPermission else {
            throw AnnouncementError.insufficientPermissions
        }
        
        // Create announcement record
        let announcement = TeamAnnouncement(
            id: UUID().uuidString,
            teamId: teamId,
            captainId: captainSession.id,
            title: title,
            message: message,
            createdAt: Date(),
            priority: priority,
            targetMemberIds: targetMemberIds
        )
        
        // Store announcement in database
        try await storeAnnouncement(announcement)
        
        // Get team members to notify
        let memberIds = try await getTargetMembers(teamId: teamId, targetMemberIds: targetMemberIds)
        
        // Send push notifications to members
        await sendPushNotifications(announcement: announcement, memberIds: memberIds)
        
        print("CaptainAnnouncementService: ✅ Sent announcement '\(title)' to \(memberIds.count) members")
    }
    
    // MARK: - Permission Verification
    
    private func verifyCaptainPermission(captainId: String, teamId: String) async -> Bool {
        do {
            // Check if user is captain of this team
            let teams = try await supabaseService.fetchUserTeams(userId: captainId)
            let team = teams.first { $0.id == teamId }
            
            return team?.captainId == captainId
        } catch {
            print("CaptainAnnouncementService: ❌ Error verifying captain permission: \(error)")
            return false
        }
    }
    
    // MARK: - Database Operations
    
    private func storeAnnouncement(_ announcement: TeamAnnouncement) async throws {
        // Store announcement in team_announcements table
        let announcementData: [String: Any] = [
            "id": announcement.id,
            "team_id": announcement.teamId,
            "captain_id": announcement.captainId,
            "title": announcement.title,
            "message": announcement.message,
            "priority": announcement.priority.rawValue,
            "target_member_ids": announcement.targetMemberIds as Any,
            "created_at": announcement.createdAt.ISO8601Format()
        ]
        
        try await supabaseService.insertData(
            table: "team_announcements", 
            data: announcementData
        )
    }
    
    private func getTargetMembers(teamId: String, targetMemberIds: [String]?) async throws -> [String] {
        if let specificMembers = targetMemberIds {
            return specificMembers
        } else {
            // Get all team members
            let teamMembers = try await supabaseService.fetchTeamMembers(teamId: teamId)
            return teamMembers.map { $0.userId }
        }
    }
    
    // MARK: - Push Notification Delivery
    
    private func sendPushNotifications(announcement: TeamAnnouncement, memberIds: [String]) async {
        // Get team name for notification branding
        guard let teamName = await getTeamName(teamId: announcement.teamId) else {
            print("CaptainAnnouncementService: ❌ Could not get team name for announcement")
            return
        }
        
        let notificationTitle = "📢 \(teamName)"
        let notificationBody = "\(announcement.title)\n\n\(announcement.message)"
        
        // Create notification content with team branding
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = notificationBody
        content.sound = getSoundForPriority(announcement.priority)
        content.badge = 1
        content.categoryIdentifier = "TEAM_ANNOUNCEMENT"
        content.userInfo = [
            "type": "team_announcement",
            "team_id": announcement.teamId,
            "team_name": teamName,
            "announcement_id": announcement.id,
            "priority": announcement.priority.rawValue
        ]
        
        // Send to each member
        for memberId in memberIds {
            let identifier = "team_announcement_\(announcement.id)_\(memberId)"
            
            // Check if member has team announcements enabled
            let hasAnnouncementsEnabled = await checkMemberNotificationPreference(memberId: memberId)
            guard hasAnnouncementsEnabled else {
                continue
            }
            
            // Schedule notification
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("CaptainAnnouncementService: ❌ Failed to send notification to \(memberId): \(error)")
                } else {
                    print("CaptainAnnouncementService: ✅ Sent announcement notification to member \(memberId)")
                }
            }
        }
    }
    
    private func getSoundForPriority(_ priority: TeamAnnouncement.AnnouncementPriority) -> UNNotificationSound {
        switch priority {
        case .urgent:
            return UNNotificationSound.defaultCritical
        case .high:
            return UNNotificationSound.default
        case .normal, .low:
            return UNNotificationSound.default
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTeamName(teamId: String) async -> String? {
        do {
            let teamDetails = try await supabaseService.getTeam(teamId)
            return teamDetails?.name
        } catch {
            print("CaptainAnnouncementService: ❌ Error fetching team name: \(error)")
            return nil
        }
    }
    
    private func checkMemberNotificationPreference(memberId: String) async -> Bool {
        // Check if the member has team announcements enabled in their notification settings
        // This uses the same UserDefaults key that the notification toggles use
        let hasTeamAnnouncementsEnabled = UserDefaults.standard.bool(forKey: "notifications.team_announcements")
        
        // For remote members (not current user), we assume they want announcements
        // In a full implementation, this would query the member's preferences from the database
        if memberId != AuthenticationService.shared.currentUserId {
            return true
        }
        
        return hasTeamAnnouncementsEnabled
    }
    
    // MARK: - Fetch Announcements
    
    func fetchTeamAnnouncements(teamId: String, limit: Int = 50) async throws -> [TeamAnnouncement] {
        do {
            let announcementData = try await supabaseService.fetchTeamAnnouncements(
                teamId: teamId, 
                limit: limit
            )
            
            return announcementData.compactMap { data in
                guard let id = data["id"] as? String,
                      let captainId = data["captain_id"] as? String,
                      let title = data["title"] as? String,
                      let message = data["message"] as? String,
                      let priorityRaw = data["priority"] as? String,
                      let priority = TeamAnnouncement.AnnouncementPriority(rawValue: priorityRaw),
                      let createdAtString = data["created_at"] as? String,
                      let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
                    return nil
                }
                
                let targetMemberIds = data["target_member_ids"] as? [String]
                
                return TeamAnnouncement(
                    id: id,
                    teamId: teamId,
                    captainId: captainId,
                    title: title,
                    message: message,
                    createdAt: createdAt,
                    priority: priority,
                    targetMemberIds: targetMemberIds
                )
            }
        } catch {
            print("CaptainAnnouncementService: ❌ Error fetching announcements: \(error)")
            throw error
        }
    }
}

// MARK: - Errors

enum AnnouncementError: LocalizedError {
    case notAuthenticated
    case insufficientPermissions
    case teamNotFound
    case invalidAnnouncementData
    case sendingFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to send announcements"
        case .insufficientPermissions:
            return "Only team captains can send announcements"
        case .teamNotFound:
            return "Team not found"
        case .invalidAnnouncementData:
            return "Invalid announcement data"
        case .sendingFailed:
            return "Failed to send announcement"
        }
    }
}

// MARK: - Supabase Service Extension

extension SupabaseService {
    func fetchTeamAnnouncements(teamId: String, limit: Int) async throws -> [[String: Any]] {
        let response: [DatabaseTeamAnnouncement] = try await client
            .from("team_announcements")
            .select()
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return response.map { announcement in
            [
                "id": announcement.id,
                "team_id": announcement.teamId,
                "captain_id": announcement.captainId,
                "title": announcement.title,
                "message": announcement.message,
                "priority": announcement.priority,
                "target_member_ids": announcement.targetMemberIds as Any,
                "created_at": announcement.createdAt.ISO8601Format()
            ]
        }
    }
    
    func insertData(table: String, data: [String: Any]) async throws {
        if table == "team_announcements" {
            let announcement = DatabaseTeamAnnouncement(
                id: data["id"] as? String ?? UUID().uuidString,
                teamId: data["team_id"] as! String,
                captainId: data["captain_id"] as! String,
                title: data["title"] as! String,
                message: data["message"] as! String,
                priority: data["priority"] as! String,
                targetMemberIds: data["target_member_ids"] as? [String],
                createdAt: ISO8601DateFormatter().date(from: data["created_at"] as! String) ?? Date()
            )
            
            try await client
                .from("team_announcements")
                .insert(announcement)
                .execute()
            
            print("SupabaseService: ✅ Inserted team announcement into database")
        } else {
            print("SupabaseService: ⚠️ Generic insertData not implemented for table: \(table)")
        }
    }
}

// MARK: - Database Models

struct DatabaseTeamAnnouncement: Codable {
    let id: String
    let teamId: String
    let captainId: String
    let title: String
    let message: String
    let priority: String
    let targetMemberIds: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case captainId = "captain_id"
        case title
        case message
        case priority
        case targetMemberIds = "target_member_ids"
        case createdAt = "created_at"
    }
}