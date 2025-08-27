import Foundation
import HealthKit

// MARK: - P2P Challenge Models

struct P2PChallenge: Codable {
    let id: String
    let challengerId: String
    let challengedId: String
    
    // Challenge details
    let type: String // '5k_race', 'weekly_miles', 'daily_run'
    let targetValue: Double? // 5 (for 5K), 50 (for 50 miles)
    let endDate: Date
    
    // Payment tracking
    let stakeAmount: Int // sats per person
    let challengerPaid: Bool
    let challengedPaid: Bool
    
    // Results
    let winnerId: String?
    let challengerResult: Double?
    let challengedResult: Double?
    let payoutCompleted: Bool
    
    // Status
    let status: String // 'pending', 'active', 'completed'
    let createdAt: Date
    
    // Optional message
    let challengeMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id, challengerId = "challenger_id", challengedId = "challenged_id"
        case type, targetValue = "target_value", endDate = "end_date"
        case stakeAmount = "stake_amount", challengerPaid = "challenger_paid", challengedPaid = "challenged_paid"
        case winnerId = "winner_id", challengerResult = "challenger_result", challengedResult = "challenged_result"
        case payoutCompleted = "payout_completed", status, createdAt = "created_at"
        case challengeMessage = "challenge_message"
    }
}

// MARK: - Payment Instructions

struct PaymentInstructions {
    let challengeId: String
    let lightningAddress: String
    let memo: String
    let amount: Int // satoshis
    let instructions: String
}

// MARK: - P2P Challenge Service

class P2PChallengeService: ObservableObject {
    
    static let shared = P2PChallengeService()
    
    private init() {}
    
    // MARK: - Challenge Creation
    
    func createChallenge(
        from challengerId: String,
        to challengedId: String,
        type: ChallengeType,
        stakeAmount: Int,
        startDate: Date,
        endDate: Date,
        message: String? = nil
    ) async throws -> P2PChallenge {
        print("🏆 P2PChallengeService: Creating new challenge from \(challengerId) to \(challengedId)")
        
        // Create a mock challenge for now - will be replaced with real database integration
        let challenge = P2PChallenge(
            id: UUID().uuidString,
            challengerId: challengerId,
            challengedId: challengedId,
            type: type.rawValue,
            targetValue: type.targetValue,
            endDate: endDate,
            stakeAmount: stakeAmount,
            challengerPaid: false,
            challengedPaid: false,
            winnerId: nil,
            challengerResult: nil,
            challengedResult: nil,
            payoutCompleted: false,
            status: "pending",
            createdAt: Date(),
            challengeMessage: message
        )
        
        // TODO: Implement actual database storage
        print("🏆 P2PChallengeService: Challenge created with ID: \(challenge.id)")
        
        // TODO: Send notification to challenged user
        
        return challenge
    }
    
    // MARK: - Challenge Management
    
    func acceptChallenge(challengeId: String, userId: String) async throws {
        print("🏆 P2PChallengeService: User \(userId) accepting challenge \(challengeId)")
        
        // TODO: Update challenge status in database
        
        // TODO: Send notification to challenger
        
        print("🏆 P2PChallengeService: Challenge accepted successfully")
    }
    
    func declineChallenge(challengeId: String, userId: String) async throws {
        print("🏆 P2PChallengeService: User \(userId) declining challenge \(challengeId)")
        
        // TODO: Update challenge status in database
        
        // TODO: Send notification to challenger
        
        print("🏆 P2PChallengeService: Challenge declined successfully")
    }
    
    // MARK: - Payment Management
    
    func getPaymentInstructions(challengeId: String, userId: String) -> PaymentInstructions {
        // Generate payment instructions for the user
        let memo = "RunstrRewards Challenge \(challengeId.prefix(8))"
        
        return PaymentInstructions(
            challengeId: challengeId,
            lightningAddress: "runstrrewards@coinos.io", // Team's Lightning address
            memo: memo,
            amount: 100, // Default stake amount in satoshis
            instructions: "Send payment to the Lightning address above using the exact memo. Your challenge will activate once both players have paid."
        )
    }
    
    func markPaid(challengeId: String, userId: String) async throws {
        print("🏆 P2PChallengeService: Marking payment complete for user \(userId) in challenge \(challengeId)")
        
        // TODO: Update payment status in database
        
        // Check if both players have paid
        let bothPaid = false // TODO: Check actual payment status
        
        if bothPaid {
            try await startChallenge(challengeId: challengeId)
        }
    }
    
    private func startChallenge(challengeId: String) async throws {
        print("🏆 P2PChallengeService: Starting challenge \(challengeId) - both players have paid!")
        
        // TODO: Update challenge status to 'active'
        
        // TODO: Send notifications to both players
    }
    
    // MARK: - Challenge Results & Settlement
    
    func updateChallengeProgress(
        challengeId: String,
        userId: String,
        distance: Double,
        workoutData: HealthKitWorkoutData? = nil
    ) async throws {
        print("🏆 P2PChallengeService: Updating progress for user \(userId) in challenge \(challengeId)")
        print("📊 Distance: \(distance) meters")
        
        // TODO: Store progress in database
    }
    
    func settleChallenge(challengeId: String) async throws {
        print("🏆 P2PChallengeService: Settling challenge \(challengeId)")
        
        // TODO: Determine winner based on challenge type and results
        
        // TODO: Distribute funds to winner
        
        // TODO: Send notifications to both players
    }
    
    // MARK: - Query Methods
    
    func getChallenge(challengeId: String) async throws -> P2PChallenge? {
        // TODO: Fetch challenge from database
        return nil
    }
    
    func getUserChallenges(userId: String) async throws -> [P2PChallenge] {
        // TODO: Fetch user's challenges from database
        return []
    }
    
    func getActiveChallenges(userId: String) async throws -> [P2PChallenge] {
        // TODO: Fetch active challenges for user
        return []
    }
}

// MARK: - Challenge Type Extension

extension ChallengeType {
    var targetValue: Double? {
        switch self {
        case .fiveK:
            return 5000 // 5K in meters
        case .tenK:
            return 10000 // 10K in meters
        case .weeklyMiles:
            return nil // No specific target, most miles wins
        case .dailyStreak:
            return nil // No specific target, longest streak wins
        case .custom:
            return nil // Custom challenges define their own rules
        }
    }
}

// MARK: - Date Extension

private extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - HealthKit Workout Data

struct HealthKitWorkoutData {
    let startDate: Date
    let endDate: Date
    let distance: Double // meters
    let duration: TimeInterval
    let heartRateAverage: Double?
    let caloriesBurned: Double?
    let workoutType: HKWorkoutActivityType
}