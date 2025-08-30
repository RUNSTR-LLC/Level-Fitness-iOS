import UIKit

// MARK: - Team Detail Header Controller (Implemented in separate file)

// MARK: - Team Detail Events Controller (Implemented in separate file)

// MARK: - Team Detail Members Controller (Implemented in separate file)

// MARK: - Supporting Types (kept here for compatibility)

struct TeamMember {
    let id: String
    let userId: String
    let username: String?
    let displayName: String?
    let role: String // "captain", "member", "moderator"
    let joinedAt: Date
    let isActive: Bool
    let stats: TeamMemberStats?
}

struct TeamMemberStats {
    let totalWorkouts: Int
    let totalPoints: Int
    let rank: Int
    let lastActiveDate: Date
}