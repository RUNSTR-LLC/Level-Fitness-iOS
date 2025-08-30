import Foundation
import Supabase

// MARK: - NotificationItem Model

public struct NotificationItem: Codable {
    let id: String
    let userId: String
    let teamId: String?
    let type: String
    let title: String
    let body: String?
    let actionType: String?
    let actionData: [String: String]?
    let fromUserId: String?
    let eventId: String?
    let read: Bool
    let actedOn: Bool
    let actionTaken: String?
    let expiresAt: Date?
    let createdAt: Date
    let actedAt: Date?
    
    // From user data (joined)
    let fromUserName: String?
    let fromUserAvatar: String?
    
    // Team data (joined)
    let teamName: String?
    
    // Regular initializer for manual creation
    init(id: String, userId: String, teamId: String? = nil, type: String, title: String,
         body: String? = nil, actionType: String? = nil, actionData: [String: String]? = nil,
         fromUserId: String? = nil, eventId: String? = nil, read: Bool = false,
         actedOn: Bool = false, actionTaken: String? = nil, expiresAt: Date? = nil,
         createdAt: Date = Date(), actedAt: Date? = nil, fromUserName: String? = nil,
         fromUserAvatar: String? = nil, teamName: String? = nil) {
        self.id = id
        self.userId = userId
        self.teamId = teamId
        self.type = type
        self.title = title
        self.body = body
        self.actionType = actionType
        self.actionData = actionData
        self.fromUserId = fromUserId
        self.eventId = eventId
        self.read = read
        self.actedOn = actedOn
        self.actionTaken = actionTaken
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.actedAt = actedAt
        self.fromUserName = fromUserName
        self.fromUserAvatar = fromUserAvatar
        self.teamName = teamName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case type
        case title
        case body
        case actionType = "action_type"
        case actionData = "action_data"
        case fromUserId = "from_user_id"
        case eventId = "event_id"
        case read
        case actedOn = "acted_on"
        case actionTaken = "action_taken"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case actedAt = "acted_at"
        case fromUserName = "from_user_name"
        case fromUserAvatar = "from_user_avatar"
        case teamName = "team_name"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        actionType = try container.decodeIfPresent(String.self, forKey: .actionType)
        fromUserId = try container.decodeIfPresent(String.self, forKey: .fromUserId)
        eventId = try container.decodeIfPresent(String.self, forKey: .eventId)
        read = try container.decode(Bool.self, forKey: .read)
        actedOn = try container.decode(Bool.self, forKey: .actedOn)
        actionTaken = try container.decodeIfPresent(String.self, forKey: .actionTaken)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        actedAt = try container.decodeIfPresent(Date.self, forKey: .actedAt)
        fromUserName = try container.decodeIfPresent(String.self, forKey: .fromUserName)
        fromUserAvatar = try container.decodeIfPresent(String.self, forKey: .fromUserAvatar)
        teamName = try container.decodeIfPresent(String.self, forKey: .teamName)
        
        // Handle actionData as string dictionary
        actionData = try container.decodeIfPresent([String: String].self, forKey: .actionData)
    }
}

// MARK: - Database Helper Structs

private struct NotificationInsert: Codable {
    let userId: String
    let teamId: String?
    let type: String
    let title: String
    let body: String?
    let actionType: String?
    let actionData: String?
    let fromUserId: String?
    let eventId: String?
    let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case teamId = "team_id"
        case type, title, body
        case actionType = "action_type"
        case actionData = "action_data"
        case fromUserId = "from_user_id"
        case eventId = "event_id"
        case expiresAt = "expires_at"
    }
}

private struct NotificationReadUpdate: Codable {
    let read: Bool
}

private struct NotificationActionUpdate: Codable {
    let actedOn: Bool
    let actionTaken: String
    let actedAt: String
    
    enum CodingKeys: String, CodingKey {
        case actedOn = "acted_on"
        case actionTaken = "action_taken"
        case actedAt = "acted_at"
    }
}

// MARK: - Notification Types

enum NotificationInboxType {
    static let challengeRequest = "challenge_request"
    static let challengeAccepted = "challenge_accepted"
    static let challengeDeclined = "challenge_declined"
    static let challengeCompleted = "challenge_completed"
    static let challengeExpired = "challenge_expired"
    static let paymentReceived = "payment_received"
    static let paymentRequired = "payment_required"
    static let leaderboardUpdate = "leaderboard_update"
    static let teamInvite = "team_invite"
    static let eventStarting = "event_starting"
    static let eventCompleted = "event_completed"
    static let achievementUnlocked = "achievement_unlocked"
}

// MARK: - NotificationInboxService

class NotificationInboxService {
    static let shared = NotificationInboxService()
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Store Notifications
    
    func storeNotification(
        userId: String,
        type: String,
        title: String,
        body: String? = nil,
        teamId: String? = nil,
        fromUserId: String? = nil,
        eventId: String? = nil,
        actionType: String? = nil,
        actionData: [String: Any]? = nil,
        expiresAt: Date? = nil
    ) async throws {
        
        // Convert action_data to JSON string
        let actionDataString: String?
        if let actionData = actionData,
           let jsonData = try? JSONSerialization.data(withJSONObject: actionData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            actionDataString = jsonString
        } else {
            actionDataString = nil
        }
        
        // Create notification insert struct
        let notification = NotificationInsert(
            userId: userId,
            teamId: teamId,
            type: type,
            title: title,
            body: body,
            actionType: actionType,
            actionData: actionDataString,
            fromUserId: fromUserId,
            eventId: eventId,
            expiresAt: expiresAt != nil ? ISO8601DateFormatter().string(from: expiresAt!) : nil
        )
        
        try await supabase.client
            .from("notification_inbox")
            .insert(notification)
            .execute()
        
        print("📥 Notification stored: \(type) for user \(userId)")
    }
    
    // MARK: - Retrieve Notifications
    
    public func getNotifications(for userId: String, limit: Int = 50) async throws -> [NotificationItem] {
        let response = try await supabase.client
            .from("notification_inbox")
            .select("""
                id, user_id, team_id, type, title, body, action_type, action_data,
                from_user_id, event_id, read, acted_on, action_taken, expires_at,
                created_at, acted_at,
                from_profiles:from_user_id(full_name, avatar_url),
                teams:team_id(name)
            """)
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        var notifications: [NotificationItem] = []
        
        // Parse the response manually to handle joined data
        if let data = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
            for notificationDict in data {
                if let notification = parseNotificationFromDict(notificationDict) {
                    notifications.append(notification)
                }
            }
        }
        
        return notifications
    }
    
    private func parseNotificationFromDict(_ dict: [String: Any]) -> NotificationItem? {
        guard let id = dict["id"] as? String,
              let userId = dict["user_id"] as? String,
              let type = dict["type"] as? String,
              let title = dict["title"] as? String,
              let read = dict["read"] as? Bool,
              let actedOn = dict["acted_on"] as? Bool,
              let createdAtString = dict["created_at"] as? String else {
            return nil
        }
        
        // Parse dates
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAt = formatter.date(from: createdAtString) ?? Date()
        
        let expiresAt: Date?
        if let expiresAtString = dict["expires_at"] as? String {
            expiresAt = formatter.date(from: expiresAtString)
        } else {
            expiresAt = nil
        }
        
        let actedAt: Date?
        if let actedAtString = dict["acted_at"] as? String {
            actedAt = formatter.date(from: actedAtString)
        } else {
            actedAt = nil
        }
        
        // Parse joined from_profiles data
        var fromUserName: String? = nil
        var fromUserAvatar: String? = nil
        if let fromProfiles = dict["from_profiles"] as? [String: Any] {
            fromUserName = fromProfiles["full_name"] as? String
            fromUserAvatar = fromProfiles["avatar_url"] as? String
        }
        
        // Parse joined teams data
        var teamName: String? = nil
        if let teams = dict["teams"] as? [String: Any] {
            teamName = teams["name"] as? String
        }
        
        // Parse action_data from JSON string to dictionary
        var actionDataDict: [String: String]? = nil
        if let actionDataString = dict["action_data"] as? String,
           let data = actionDataString.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            actionDataDict = parsed
        }
        
        // Create a simplified init for NotificationItem
        return NotificationItem(
            id: id,
            userId: userId,
            teamId: dict["team_id"] as? String,
            type: type,
            title: title,
            body: dict["body"] as? String,
            actionType: dict["action_type"] as? String,
            actionData: actionDataDict,
            fromUserId: dict["from_user_id"] as? String,
            eventId: dict["event_id"] as? String,
            read: read,
            actedOn: actedOn,
            actionTaken: dict["action_taken"] as? String,
            expiresAt: expiresAt,
            createdAt: createdAt,
            actedAt: actedAt,
            fromUserName: fromUserName,
            fromUserAvatar: fromUserAvatar,
            teamName: teamName
        )
    }
    
    // MARK: - Update Notifications
    
    func markAsRead(_ notificationId: String) async throws {
        let updateData = NotificationReadUpdate(read: true)
        
        try await supabase.client
            .from("notification_inbox")
            .update(updateData)
            .eq("id", value: notificationId)
            .execute()
    }
    
    func markAsActedOn(_ notificationId: String, actionTaken: String) async throws {
        let updateData = NotificationActionUpdate(
            actedOn: true,
            actionTaken: actionTaken,
            actedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase.client
            .from("notification_inbox")
            .update(updateData)
            .eq("id", value: notificationId)
            .execute()
    }
    
    public func markAllAsRead(for userId: String) async throws {
        let updateData = NotificationReadUpdate(read: true)
        
        try await supabase.client
            .from("notification_inbox")
            .update(updateData)
            .eq("user_id", value: userId)
            .eq("read", value: false)
            .execute()
    }
    
    // MARK: - Delete Notifications
    
    func deleteNotification(_ notificationId: String) async throws {
        try await supabase.client
            .from("notification_inbox")
            .delete()
            .eq("id", value: notificationId)
            .execute()
    }
    
    func deleteExpiredNotifications(for userId: String) async throws {
        let now = ISO8601DateFormatter().string(from: Date())
        
        try await supabase.client
            .from("notification_inbox")
            .delete()
            .eq("user_id", value: userId)
            .lt("expires_at", value: now)
            .execute()
    }
    
    // MARK: - Count Methods
    
    func getUnreadCount(for userId: String) async throws -> Int {
        let response = try await supabase.client
            .from("notification_inbox")
            .select("*", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("read", value: false)
            .execute()
        
        return response.count ?? 0
    }
    
    // MARK: - Challenge-Specific Notifications
    
    func storeChallengeNotification(
        to userId: String,
        from fromUserId: String,
        challengeId: String,
        type: String,
        title: String,
        body: String,
        teamId: String? = nil
    ) async throws {
        let actionData: [String: Any] = [
            "challenge_id": challengeId
        ]
        
        try await storeNotification(
            userId: userId,
            type: type,
            title: title,
            body: body,
            teamId: teamId,
            fromUserId: fromUserId,
            actionType: "challenge",
            actionData: actionData,
            expiresAt: Date().addingTimeInterval(7 * 24 * 60 * 60) // Expires in 7 days
        )
    }
}