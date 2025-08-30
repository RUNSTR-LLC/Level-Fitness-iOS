import Foundation

// MARK: - Leaderboard Models

// Individual user leaderboard entry
struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String?
    let displayName: String?
    let rank: Int
    let score: Double
    let totalWorkouts: Int
    let totalDistance: Double
    let totalCalories: Int
    let period: String // "daily", "weekly", "monthly", "all_time"
    let lastUpdated: Date
    let teamId: String?
    let teamName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case rank
        case score
        case totalWorkouts = "total_workouts"
        case totalDistance = "total_distance"
        case totalCalories = "total_calories"
        case period
        case lastUpdated = "last_updated"
        case teamId = "team_id"
        case teamName = "team_name"
    }
    
    var isTopTen: Bool {
        return rank <= 10
    }
    
    var performanceTier: LeaderboardTier {
        switch rank {
        case 1:
            return .champion
        case 2...3:
            return .podium
        case 4...10:
            return .topTen
        case 11...50:
            return .competitive
        default:
            return .participant
        }
    }
}

// Team-based leaderboard entry
struct TeamLeaderboardEntry: Codable, Identifiable {
    let id: String
    let teamId: String
    let teamName: String
    let captainId: String
    let rank: Int
    let totalScore: Double
    let memberCount: Int
    let activeMembers: Int
    let avgScorePerMember: Double
    let totalWorkouts: Int
    let period: String
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case teamName = "team_name"
        case captainId = "captain_id"
        case rank
        case totalScore = "total_score"
        case memberCount = "member_count"
        case activeMembers = "active_members"
        case avgScorePerMember = "avg_score_per_member"
        case totalWorkouts = "total_workouts"
        case period
        case lastUpdated = "last_updated"
    }
    
    var isTopTeam: Bool {
        return rank <= 5
    }
    
    var participationRate: Double {
        guard memberCount > 0 else { return 0 }
        return Double(activeMembers) / Double(memberCount)
    }
}

// Individual member ranking within a team
struct TeamMemberRanking: Codable, Identifiable {
    let id: String
    let teamId: String
    let userId: String
    let username: String?
    let displayName: String?
    let teamRank: Int
    let globalRank: Int?
    let score: Double
    let totalWorkouts: Int
    let totalDistance: Double
    let totalCalories: Int
    let contributionPercentage: Double
    let period: String
    let lastUpdated: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case teamRank = "team_rank"
        case globalRank = "global_rank"
        case score
        case totalWorkouts = "total_workouts"
        case totalDistance = "total_distance"
        case totalCalories = "total_calories"
        case contributionPercentage = "contribution_percentage"
        case period
        case lastUpdated = "last_updated"
        case isActive = "is_active"
    }
    
    var isTopContributor: Bool {
        return teamRank <= 3
    }
    
    var contributionLevel: ContributionLevel {
        switch contributionPercentage {
        case 20...:
            return .superstar
        case 10..<20:
            return .highContributor
        case 5..<10:
            return .regularContributor
        case 1..<5:
            return .lightContributor
        default:
            return .inactive
        }
    }
}

// MARK: - Supporting Enums

enum LeaderboardTier: String, CaseIterable {
    case champion = "champion"
    case podium = "podium"
    case topTen = "top_ten"
    case competitive = "competitive"
    case participant = "participant"
    
    var displayName: String {
        switch self {
        case .champion:
            return "Champion"
        case .podium:
            return "Podium"
        case .topTen:
            return "Top 10"
        case .competitive:
            return "Competitive"
        case .participant:
            return "Participant"
        }
    }
    
    var rewardMultiplier: Double {
        switch self {
        case .champion:
            return 3.0
        case .podium:
            return 2.0
        case .topTen:
            return 1.5
        case .competitive:
            return 1.2
        case .participant:
            return 1.0
        }
    }
}

enum ContributionLevel: String, CaseIterable {
    case superstar = "superstar"
    case highContributor = "high_contributor"
    case regularContributor = "regular_contributor"
    case lightContributor = "light_contributor"
    case inactive = "inactive"
    
    var displayName: String {
        switch self {
        case .superstar:
            return "Superstar"
        case .highContributor:
            return "High Contributor"
        case .regularContributor:
            return "Regular Contributor"
        case .lightContributor:
            return "Light Contributor"
        case .inactive:
            return "Inactive"
        }
    }
}