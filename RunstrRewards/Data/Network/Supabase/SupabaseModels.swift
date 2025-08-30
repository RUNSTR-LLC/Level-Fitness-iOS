import Foundation

// MARK: - Core Data Models

// UserSession and UserProfile moved to AuthDataService
// Transaction models moved to TransactionDataService  
// Team models moved to TeamDataService
// Competition models moved to CompetitionDataService

// Workout model kept here as it's used by multiple services (HealthKitService, WorkoutDataService, TeamDataService)
struct Workout: Codable {
    let id: String
    let userId: String
    let type: String
    let duration: Int // seconds
    let distance: Double? // meters
    let calories: Int?
    let heartRate: Int?
    let source: String // "healthkit", "strava", etc.
    let startedAt: Date
    let endedAt: Date?  // Made optional in case column doesn't exist
    let syncedAt: Date
    
    // Custom CodingKeys to handle snake_case in database
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case duration
        case distance
        case calories
        case heartRate = "heart_rate"
        case source
        case startedAt = "started_at"
        case endedAt = "ended_at"  // Map to snake_case column name
        case syncedAt = "synced_at"
    }
    
    // MARK: - Compatibility Properties
    // These provide backwards compatibility for code expecting different property names
    var averageHeartRate: Int? { heartRate }
    var totalEnergyBurned: Double? { calories.map(Double.init) }
    var totalDistance: Double? { distance }
    var startDate: Date { startedAt }
}

// MARK: - Payment Coordination Data Models

struct BasicUserInfo: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let createdAt: Date
    let lastActiveAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
    }
}

struct BasicTeamInfo: Codable {
    let id: String
    let name: String
    let captainId: String
    let isActive: Bool
    let createdAt: Date
    let memberCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case captainId = "captain_id"
        case isActive = "is_active"
        case createdAt = "created_at"
        case memberCount = "member_count"
    }
}

struct TransactionSummary: Codable {
    let id: String
    let userId: String
    let amount: Int
    let type: String
    let description: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case type
        case description
        case createdAt = "created_at"
    }
}

struct PaymentCoordinationSummary: Codable {
    let totalActiveUsers: Int
    let totalActiveTeams: Int
    let totalRecentTransactions: Int
    let totalTransactionVolume: Int
    let generatedAt: Date
    let users: [BasicUserInfo]
    let teams: [BasicTeamInfo]
    let recentTransactions: [TransactionSummary]
}

struct TeamInvitationValidation: Codable {
    let id: String
    let expiresAt: Date?
    let usedCount: Int
    let maxUses: Int?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case expiresAt = "expires_at"
        case usedCount = "used_count"
        case maxUses = "max_uses"
        case isActive = "is_active"
    }
}

