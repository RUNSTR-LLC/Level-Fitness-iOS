import Foundation
import UIKit

// MARK: - Challenge Status Enum

enum ChallengeStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case active = "active"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: UIColor {
        switch self {
        case .pending:
            return IndustrialDesign.Colors.accent
        case .accepted:
            return UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
        case .declined:
            return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        case .active:
            return IndustrialDesign.Colors.accent
        case .completed:
            return UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        case .cancelled:
            return UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        }
    }
}

// MARK: - Challenge Data Model for UI Components

struct ChallengeData: Codable {
    let challengeId: String
    let name: String
    let title: String // Alias for name for UI compatibility
    let type: String
    let status: ChallengeStatus
    let prizePool: Int
    let prize: String // Formatted prize string
    let startDate: Date
    let endDate: Date
    let participantCount: Int
    let createdBy: String
    let teamId: String?
    let description: String?
    let icon: String?
    let currentProgress: Double
    let progress: Double // Alias for currentProgress
    let progressText: String
    let timeLeft: String
    let formattedTimeRemaining: String // Alias for timeLeft
    let formattedGoal: String
    let formattedReward: String // Alias for prize
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case name, type, status, title, prize, description, icon
        case prizePool = "prize_pool"
        case startDate = "start_date"
        case endDate = "end_date"
        case participantCount = "participant_count"
        case createdBy = "created_by"
        case teamId = "team_id"
        case currentProgress = "current_progress"
        case progress, progressText = "progress_text"
        case timeLeft = "time_left"
        case formattedTimeRemaining = "formatted_time_remaining"
        case formattedGoal = "formatted_goal"
        case formattedReward = "formatted_reward"
    }
    
    // Convenience initializer from Challenge model
    init(from challenge: Challenge) {
        self.challengeId = challenge.id
        self.name = challenge.name
        self.title = challenge.name // Use name as title
        self.type = challenge.type
        self.status = ChallengeStatus(rawValue: challenge.status) ?? .pending
        self.prizePool = challenge.prizePool
        self.prize = "\(challenge.prizePool) sats" // Format prize
        self.startDate = challenge.startDate
        self.endDate = challenge.endDate
        self.participantCount = 0 // This would need to be fetched separately
        self.createdBy = challenge.createdBy
        self.teamId = challenge.teamId
        self.description = challenge.description
        self.icon = "trophy" // Default icon
        self.currentProgress = 0.0 // Default progress
        self.progress = 0.0 // Alias for currentProgress
        self.progressText = "0% complete"
        self.timeLeft = "Not started"
        self.formattedTimeRemaining = "Not started"
        self.formattedGoal = "Complete challenge"
        self.formattedReward = "\(challenge.prizePool) sats"
    }
}

// MARK: - Challenge Helper Extensions

extension Challenge {
    
    // MARK: - Challenge Status Helpers
    
    var challengeStatus: ChallengeStatus {
        return ChallengeStatus(rawValue: status) ?? .pending
    }
    
    // Status properties available via challengeStatus.isActive, etc.
    
    // MARK: - User Permission Helpers
    
    func canUserJoin(_ userId: String) -> Bool {
        return isActive && createdBy != userId
    }
    
    func isUserCreator(_ userId: String) -> Bool {
        return createdBy == userId
    }
    
    // MARK: - Display Helpers
    
    var prizeDisplayText: String {
        if prizePool > 0 {
            return "\(prizePool) sats"
        }
        return "No prize"
    }
    
    var timeRemainingText: String {
        let timeRemaining = endDate.timeIntervalSinceNow
        
        if timeRemaining <= 0 {
            return "Ended"
        }
        
        let days = Int(timeRemaining) / (24 * 3600)
        let hours = Int(timeRemaining) % (24 * 3600) / 3600
        let minutes = Int(timeRemaining) % 3600 / 60
        
        if days > 0 {
            return "\(days)d \(hours)h left"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    var durationText: String {
        let duration = endDate.timeIntervalSince(startDate)
        let days = Int(duration) / (24 * 3600)
        let hours = Int(duration) % (24 * 3600) / 3600
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "< 1 hour"
        }
    }
}

// MARK: - Challenge Actions

extension Challenge {
    
    func joinChallenge(userId: String) async throws {
        guard canUserJoin(userId) else {
            throw ChallengeError.invalidAction("Cannot join this challenge")
        }
        
        do {
            try await SupabaseService.shared.joinChallenge(challengeId: id, userId: userId)
            
            // Send notification to challenge creator
            try await NotificationInboxService.shared.storeNotification(
                userId: createdBy,
                type: "challenge_joined",
                title: "Challenge Joined!",
                body: "Someone joined your challenge: \(name)",
                actionData: ["challenge_id": id]
            )
            
            print("🏆 Challenge: User \(userId) joined challenge \(id)")
        } catch {
            print("❌ Challenge: Failed to join challenge: \(error)")
            throw error
        }
    }
    
    func leaveChallenge(userId: String) async throws {
        do {
            // This would need to be implemented in SupabaseService
            // For now, just log the action
            print("🏆 Challenge: User \(userId) left challenge \(id)")
        } catch {
            print("❌ Challenge: Failed to leave challenge: \(error)")
            throw error
        }
    }
    
    // MARK: - Challenge Completion & Payout
    
    func completeAndDistributePrize(winnerId: String) async throws {
        guard isCompleted else {
            throw ChallengeError.invalidAction("Challenge is not yet completed")
        }
        
        guard prizePool > 0 else {
            print("🏆 Challenge: No prize to distribute for challenge \(id)")
            return
        }
        
        do {
            // Create prize distribution for the winner
            let distributionResult = await TeamPrizeDistributionService.shared.createDistribution(
                eventId: id,
                teamId: teamId,
                method: .custom, // Winner-takes-all
                totalPrize: Double(prizePool),
                captainUserId: createdBy,
                notes: "Challenge winner payout: \(name)"
            )
            
            switch distributionResult {
            case .success(let distribution):
                // Execute the distribution immediately
                let executionResult = await TeamPrizeDistributionService.shared.executeDistribution(distributionId: distribution.distributionId)
                
                switch executionResult {
                case .success:
                    // Send winner notification
                    try await NotificationInboxService.shared.storeNotification(
                        userId: winnerId,
                        type: "challenge_won",
                        title: "🏆 Challenge Won!",
                        body: "Congratulations! You won the challenge '\(name)' and earned \(prizePool) sats!",
                        actionData: [
                            "challenge_id": id,
                            "prize": String(prizePool)
                        ]
                    )
                    
                    print("🏆 Challenge: ✅ Successfully distributed \(prizePool) sats to winner \(winnerId)")
                    
                case .failure(let error):
                    print("❌ Challenge: Failed to execute prize distribution: \(error)")
                    throw ChallengeError.networkError("Failed to distribute prize: \(error)")
                }
                
            case .failure(let error):
                print("❌ Challenge: Failed to create prize distribution: \(error)")
                throw ChallengeError.networkError("Failed to create prize distribution: \(error)")
            }
            
        } catch {
            print("❌ Challenge: Prize distribution failed: \(error)")
            throw error
        }
    }
    
    func payTeamArbitrationFee(amount: Int) async throws {
        guard amount > 0 else { return }
        
        do {
            // This would transfer funds to team wallet for arbitration fee
            // For now, just log the action - the actual implementation would depend
            // on how team fees are collected and managed
            print("💰 Challenge: Paying team arbitration fee: \(amount) sats for challenge \(id)")
            
            // In a complete implementation, this might:
            // 1. Transfer funds from prize pool to team's main wallet
            // 2. Record the transaction in the team's financial records
            // 3. Update team earnings statistics
            
        } catch {
            print("❌ Challenge: Failed to pay team arbitration fee: \(error)")
            throw error
        }
    }
}

// MARK: - Challenge Errors

enum ChallengeError: LocalizedError {
    case invalidAction(String)
    case noResults(String)
    case insufficientFunds(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAction(let message):
            return "Invalid action: \(message)"
        case .noResults(let message):
            return "No results: \(message)"
        case .insufficientFunds(let message):
            return "Insufficient funds: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Challenge Participant Model

struct ChallengeParticipant: Codable {
    let challengeId: String
    let userId: String
    let progress: Double
    let completed: Bool
    let completedAt: Date?
    let joinedAt: Date
    
    // User profile data (from join with profiles table)
    let fullName: String?
    let username: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case userId = "user_id"
        case progress, completed
        case completedAt = "completed_at"
        case joinedAt = "joined_at"
        case fullName = "full_name"
        case username
        case avatarUrl = "avatar_url"
    }
}

// MARK: - SupabaseService Challenge Methods

extension SupabaseService {
    
    func updateChallengeStatus(challengeId: String, status: ChallengeStatus) async throws {
        try await client
            .from("challenges")
            .update(["status": status.rawValue])
            .eq("id", value: challengeId)
            .execute()
        
        print("🔄 SupabaseService: Updated challenge \(challengeId) status to \(status)")
    }
    
    func acceptChallenge(challengeId: String, userId: String) async throws {
        // For team challenges, this would join the challenge and possibly update status
        try await joinChallenge(challengeId: challengeId, userId: userId)
        print("✅ SupabaseService: User \(userId) accepted challenge \(challengeId)")
    }
    
    func declineChallenge(challengeId: String, userId: String) async throws {
        // For team challenges, this might just log the decline
        // P2P challenges handle this differently in P2PChallengeService
        print("❌ SupabaseService: User \(userId) declined challenge \(challengeId)")
    }
}