import Foundation

// MARK: - Team Invitation Models

struct TeamInvitationDetails: Codable, Identifiable {
    let id: String
    let teamId: String
    let teamName: String
    let captainId: String
    let captainName: String?
    let invitedUserId: String?
    let invitedEmail: String?
    let inviteCode: String
    let status: String // "pending", "accepted", "declined", "expired"
    let message: String?
    let createdAt: Date
    let expiresAt: Date
    let acceptedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case teamName = "team_name"
        case captainId = "captain_id"
        case captainName = "captain_name"
        case invitedUserId = "invited_user_id"
        case invitedEmail = "invited_email"
        case inviteCode = "invite_code"
        case status
        case message
        case createdAt = "created_at"
        case expiresAt = "expires_at"
        case acceptedAt = "accepted_at"
    }
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
    
    var isPending: Bool {
        return status == "pending" && !isExpired
    }
    
    var canBeAccepted: Bool {
        return isPending && !isExpired
    }
}

// MARK: - Team Message Models

struct TeamMessage: Codable, Identifiable {
    let id: String
    let teamId: String
    let userId: String
    let username: String?
    let displayName: String?
    let content: String
    let messageType: String // "text", "system", "workout_celebration", "challenge_update"
    let metadata: [String: Any]?
    let createdAt: Date
    let editedAt: Date?
    let isSystemMessage: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case content
        case messageType = "message_type"
        case metadata
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case isSystemMessage = "is_system_message"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        teamId = try container.decode(String.self, forKey: .teamId)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        content = try container.decode(String.self, forKey: .content)
        messageType = try container.decode(String.self, forKey: .messageType)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        editedAt = try container.decodeIfPresent(Date.self, forKey: .editedAt)
        isSystemMessage = try container.decode(Bool.self, forKey: .isSystemMessage)
        
        // Handle metadata as flexible dictionary
        if let metadataData = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
            metadata = metadataData.mapValues { $0.value }
        } else {
            metadata = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(content, forKey: .content)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(editedAt, forKey: .editedAt)
        try container.encode(isSystemMessage, forKey: .isSystemMessage)
        
        // Encode metadata as AnyCodable
        if let metadata = metadata {
            let encodableMetadata = metadata.mapValues { AnyCodable($0) }
            try container.encode(encodableMetadata, forKey: .metadata)
        }
    }
    
    var isWorkoutCelebration: Bool {
        return messageType == "workout_celebration"
    }
    
    var isChallengeUpdate: Bool {
        return messageType == "challenge_update"
    }
    
    var isTextMessage: Bool {
        return messageType == "text"
    }
    
    var senderDisplayName: String {
        if isSystemMessage {
            return "System"
        }
        return displayName ?? username ?? "Unknown User"
    }
}

// MARK: - Team League Models

struct TeamLeague: Codable, Identifiable {
    let id: String
    let teamId: String?
    let name: String
    let description: String?
    let createdBy: String
    let season: String
    let startDate: Date
    let endDate: Date
    let maxTeams: Int?
    let currentTeamCount: Int
    let status: String // "draft", "active", "completed", "cancelled"
    let prizePool: Int
    let entryFee: Int
    let leagueType: String // "competitive", "casual", "corporate"
    let rules: [String: String]?
    let payoutPercentages: [String: Double]?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, season, status, rules
        case teamId = "team_id"
        case createdBy = "created_by"
        case startDate = "start_date"
        case endDate = "end_date"
        case maxTeams = "max_teams"
        case currentTeamCount = "current_team_count"
        case prizePool = "prize_pool"
        case entryFee = "entry_fee"
        case leagueType = "league_type"
        case payoutPercentages = "payout_percentages"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var isActive: Bool {
        return status == "active"
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var isDraft: Bool {
        return status == "draft"
    }
    
    var canAcceptNewTeams: Bool {
        guard isActive || isDraft else { return false }
        if let maxTeams = maxTeams {
            return currentTeamCount < maxTeams
        }
        return true
    }
    
    var durationDays: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var daysRemaining: Int {
        guard isActive else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var isCompetitive: Bool {
        return leagueType == "competitive"
    }
    
    var isCasual: Bool {
        return leagueType == "casual"
    }
    
    var isCorporate: Bool {
        return leagueType == "corporate"
    }
    
    // MARK: - League Validation
    
    func canStart() -> Bool {
        return status == "draft" && Date() >= startDate && currentTeamCount >= 2
    }
    
    func shouldEnd() -> Bool {
        return status == "active" && Date() >= endDate
    }
    
    func getCompetitionLevel() -> LeagueCompetitionLevel {
        switch leagueType {
        case "competitive":
            return .competitive
        case "casual":
            return .casual
        case "corporate":
            return .corporate
        default:
            return .casual
        }
    }
}

// MARK: - Supporting Enums

enum LeagueCompetitionLevel: String, CaseIterable {
    case competitive = "competitive"
    case casual = "casual"
    case corporate = "corporate"
    
    var displayName: String {
        switch self {
        case .competitive:
            return "Competitive"
        case .casual:
            return "Casual"
        case .corporate:
            return "Corporate"
        }
    }
    
    var description: String {
        switch self {
        case .competitive:
            return "High-stakes competition with significant rewards"
        case .casual:
            return "Fun, low-pressure team competition"
        case .corporate:
            return "Corporate wellness team challenges"
        }
    }
    
    var minTeams: Int {
        switch self {
        case .competitive:
            return 4
        case .casual:
            return 2
        case .corporate:
            return 3
        }
    }
}