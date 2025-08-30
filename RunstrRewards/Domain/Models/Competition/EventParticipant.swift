import Foundation

// Import AnyCodable from Core utilities

// MARK: - Event Participant Model
// Maps to the 'event_participants' table in the database

struct EventParticipant: Codable, Identifiable {
    let id: String
    let eventId: String
    let userId: String
    let teamId: String?
    let registeredAt: Date
    let status: String // "registered", "active", "completed", "disqualified"
    let currentScore: Double
    let currentRank: Int?
    let lastUpdated: Date
    let metadata: [String: Any]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case teamId = "team_id"
        case registeredAt = "registered_at"
        case status
        case currentScore = "current_score"
        case currentRank = "current_rank"
        case lastUpdated = "last_updated"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        eventId = try container.decode(String.self, forKey: .eventId)
        userId = try container.decode(String.self, forKey: .userId)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        registeredAt = try container.decode(Date.self, forKey: .registeredAt)
        status = try container.decode(String.self, forKey: .status)
        currentScore = try container.decode(Double.self, forKey: .currentScore)
        currentRank = try container.decodeIfPresent(Int.self, forKey: .currentRank)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        
        // Handle metadata - skip complex decoding in domain models
        metadata = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(teamId, forKey: .teamId)
        try container.encode(registeredAt, forKey: .registeredAt)
        try container.encode(status, forKey: .status)
        try container.encode(currentScore, forKey: .currentScore)
        try container.encodeIfPresent(currentRank, forKey: .currentRank)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        
        // Encode metadata - simplified approach for Domain layer
        if let metadata = metadata {
            // For domain models, we'll handle this at the service layer
            // For now, skip encoding complex metadata in pure domain models
        }
    }
    
    // MARK: - Status Helpers
    
    var isActive: Bool {
        return status == "active"
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var isDisqualified: Bool {
        return status == "disqualified"
    }
    
    // MARK: - Performance Metrics
    
    func getPerformanceLevel() -> ParticipantPerformance {
        guard let rank = currentRank else { return .participant }
        switch rank {
        case 1:
            return .leader
        case 2...5:
            return .topTier
        case 6...20:
            return .competitive
        default:
            return .participant
        }
    }
}

// MARK: - Supporting Types

enum ParticipantPerformance: String, CaseIterable {
    case leader = "leader"
    case topTier = "top_tier"
    case competitive = "competitive"
    case participant = "participant"
    
    var displayName: String {
        switch self {
        case .leader:
            return "Leader"
        case .topTier:
            return "Top Tier"
        case .competitive:
            return "Competitive"
        case .participant:
            return "Participant"
        }
    }
}

