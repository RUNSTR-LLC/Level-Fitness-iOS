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
    
    private let supabaseService = SupabaseService.shared
    private let notificationService = NotificationService.shared
    private let notificationInboxService = NotificationInboxService.shared
    
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
        
        // Input validation
        try validateChallengeInputs(
            challengerId: challengerId,
            challengedId: challengedId,
            stakeAmount: stakeAmount,
            endDate: endDate,
            message: message
        )
        
        // Create challenge data for database
        let challengeData = [
            "challenger_id": challengerId,
            "challenged_id": challengedId,
            "type": type.rawValue,
            "target_value": String(type.targetValue ?? 0),
            "end_date": ISO8601DateFormatter().string(from: endDate),
            "stake_amount": String(stakeAmount),
            "challenger_paid": "false",
            "challenged_paid": "false",
            "payout_completed": "false",
            "status": "pending",
            "challenge_message": sanitizeMessage(message)
        ]
        
        do {
            // Insert into database
            let response = try await supabaseService.client
                .from("p2p_challenges")
                .insert(challengeData)
                .select()
                .single()
                .execute()
            
            // Decode the response
            let challenge = try supabaseService.customJSONDecoder().decode(P2PChallenge.self, from: response.data)
            
            print("🏆 P2PChallengeService: Challenge created successfully with ID: \(challenge.id)")
            
            // Send notification to challenged user
            await sendChallengeNotification(to: challengedId, challenge: challenge)
            
            return challenge
            
        } catch {
            print("🏆 P2PChallengeService: Failed to create challenge: \(error)")
            throw error
        }
    }
    
    // MARK: - Challenge Management
    
    func acceptChallenge(challengeId: String, userId: String) async throws {
        print("🏆 P2PChallengeService: User \(userId) accepting challenge \(challengeId)")
        
        do {
            // Update challenge status to 'active' (assuming both parties need to pay first)
            try await supabaseService.client
                .from("p2p_challenges")
                .update(["status": "active", "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: challengeId)
                .eq("challenged_id", value: userId)
                .execute()
            
            // Get the challenge details to send notification
            let challenge = try await getChallenge(challengeId: challengeId)
            if let challenge = challenge {
                // Send notification to challenger
                await sendChallengeAcceptedNotification(to: challenge.challengerId, challenge: challenge)
            }
            
            print("🏆 P2PChallengeService: Challenge accepted successfully")
            
        } catch {
            print("🏆 P2PChallengeService: Failed to accept challenge: \(error)")
            throw error
        }
    }
    
    func declineChallenge(challengeId: String, userId: String) async throws {
        print("🏆 P2PChallengeService: User \(userId) declining challenge \(challengeId)")
        
        do {
            // Update challenge status to 'cancelled'
            let updateData = [
                "status": "cancelled",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("p2p_challenges")
                .update(updateData)
                .eq("id", value: challengeId)
                .eq("challenged_id", value: userId)
                .execute()
            
            // Get the challenge details to send notification
            let challenge = try await getChallenge(challengeId: challengeId)
            if let challenge = challenge {
                // Send notification to challenger
                await sendChallengeDeclinedNotification(to: challenge.challengerId, challenge: challenge)
            }
            
            print("🏆 P2PChallengeService: Challenge declined successfully")
            
        } catch {
            print("🏆 P2PChallengeService: Failed to decline challenge: \(error)")
            throw error
        }
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
        
        do {
            // Get current challenge to determine if user is challenger or challenged
            guard let challenge = try await getChallenge(challengeId: challengeId) else {
                throw NSError(domain: "P2PChallengeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
            }
            
            // Determine which field to update
            let updateField: String
            if challenge.challengerId == userId {
                updateField = "challenger_paid"
            } else if challenge.challengedId == userId {
                updateField = "challenged_paid"
            } else {
                throw NSError(domain: "P2PChallengeService", code: 403, userInfo: [NSLocalizedDescriptionKey: "User not involved in this challenge"])
            }
            
            // Update payment status in database
            let updateData = [
                updateField: "true",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("p2p_challenges")
                .update(updateData)
                .eq("id", value: challengeId)
                .execute()
            
            // Check if both players have paid
            let updatedChallenge = try await getChallenge(challengeId: challengeId)
            if let updatedChallenge = updatedChallenge,
               updatedChallenge.challengerPaid && updatedChallenge.challengedPaid {
                try await startChallenge(challengeId: challengeId)
            }
            
        } catch {
            print("🏆 P2PChallengeService: Failed to mark payment: \(error)")
            throw error
        }
    }
    
    private func startChallenge(challengeId: String) async throws {
        print("🏆 P2PChallengeService: Starting challenge \(challengeId) - both players have paid!")
        
        do {
            // Update challenge status to 'active'
            let updateData = [
                "status": "active",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("p2p_challenges")
                .update(updateData)
                .eq("id", value: challengeId)
                .execute()
            
            // Get challenge details and send notifications to both players
            if let challenge = try await getChallenge(challengeId: challengeId) {
                await sendChallengeStartedNotification(to: challenge.challengerId, challenge: challenge)
                await sendChallengeStartedNotification(to: challenge.challengedId, challenge: challenge)
            }
            
            print("🏆 P2PChallengeService: Challenge started successfully")
            
        } catch {
            print("🏆 P2PChallengeService: Failed to start challenge: \(error)")
            throw error
        }
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
        
        do {
            // Get current challenge to determine user role
            guard let challenge = try await getChallenge(challengeId: challengeId) else {
                throw NSError(domain: "P2PChallengeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
            }
            
            // Only update if challenge is active
            guard challenge.status == "active" else {
                print("🏆 P2PChallengeService: Cannot update progress - challenge status is \(challenge.status)")
                return
            }
            
            // Determine which field to update and convert distance to appropriate units
            let updateField: String
            let progressValue: Double
            
            if challenge.challengerId == userId {
                updateField = "challenger_result"
            } else if challenge.challengedId == userId {
                updateField = "challenged_result"
            } else {
                throw NSError(domain: "P2PChallengeService", code: 403, userInfo: [NSLocalizedDescriptionKey: "User not involved in this challenge"])
            }
            
            // Convert distance based on challenge type
            switch challenge.type {
            case "5k_race", "10k_race":
                // For races, store time in seconds (if available), otherwise distance
                progressValue = workoutData?.duration ?? distance
            case "weekly_miles", "daily_run":
                // For distance challenges, convert meters to miles
                progressValue = distance * 0.000621371 // meters to miles conversion
            default:
                // Default to storing distance as-is
                progressValue = distance
            }
            
            // Update the progress in database
            let updateData = [
                updateField: String(progressValue),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("p2p_challenges")
                .update(updateData)
                .eq("id", value: challengeId)
                .execute()
            
            print("🏆 P2PChallengeService: Updated \(updateField) to \(progressValue) for challenge \(challengeId)")
            
            // Check if both participants have results and auto-settle if challenge is complete
            let updatedChallenge = try await getChallenge(challengeId: challengeId)
            if let updatedChallenge = updatedChallenge,
               updatedChallenge.challengerResult != nil,
               updatedChallenge.challengedResult != nil {
                print("🏆 P2PChallengeService: Both participants have results, settling challenge")
                try await settleChallenge(challengeId: challengeId)
            }
            
        } catch {
            print("🏆 P2PChallengeService: Failed to update challenge progress: \(error)")
            throw error
        }
    }
    
    func settleChallenge(challengeId: String) async throws {
        print("🏆 P2PChallengeService: Settling challenge \(challengeId)")
        
        do {
            // Get challenge details
            guard let challenge = try await getChallenge(challengeId: challengeId) else {
                throw NSError(domain: "P2PChallengeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Challenge not found"])
            }
            
            // Determine winner based on challenge results
            let winnerId = determineWinner(challenge: challenge)
            
            // Update challenge with winner and completion status
            let updates = [
                "winner_id": winnerId ?? "",
                "status": "completed",
                "payout_completed": "true",
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await supabaseService.client
                .from("p2p_challenges")
                .update(updates)
                .eq("id", value: challengeId)
                .execute()
            
            // Process payout (total stake amount to winner)
            if let winnerId = winnerId {
                let totalPayout = challenge.stakeAmount * 2 // Both players' stakes
                try await processPayout(winnerId: winnerId, amount: totalPayout, challengeId: challengeId)
            }
            
            // Send notifications to both players
            let finalChallenge = try await getChallenge(challengeId: challengeId)
            if let finalChallenge = finalChallenge {
                await sendChallengeCompletedNotification(to: challenge.challengerId, challenge: finalChallenge)
                await sendChallengeCompletedNotification(to: challenge.challengedId, challenge: finalChallenge)
            }
            
            print("🏆 P2PChallengeService: Challenge settled successfully")
            
        } catch {
            print("🏆 P2PChallengeService: Failed to settle challenge: \(error)")
            throw error
        }
    }
    
    // MARK: - Query Methods
    
    func getChallenge(challengeId: String) async throws -> P2PChallenge? {
        do {
            let response = try await supabaseService.client
                .from("p2p_challenges")
                .select()
                .eq("id", value: challengeId)
                .single()
                .execute()
            
            return try supabaseService.customJSONDecoder().decode(P2PChallenge.self, from: response.data)
            
        } catch {
            print("🏆 P2PChallengeService: Failed to fetch challenge: \(error)")
            return nil
        }
    }
    
    func getUserChallenges(userId: String) async throws -> [P2PChallenge] {
        do {
            let response = try await supabaseService.client
                .from("p2p_challenges")
                .select()
                .or("challenger_id.eq.\(userId),challenged_id.eq.\(userId)")
                .order("created_at", ascending: false)
                .execute()
            
            return try supabaseService.customJSONDecoder().decode([P2PChallenge].self, from: response.data)
            
        } catch {
            print("🏆 P2PChallengeService: Failed to fetch user challenges: \(error)")
            throw error
        }
    }
    
    func getActiveChallenges(userId: String) async throws -> [P2PChallenge] {
        do {
            let response = try await supabaseService.client
                .from("p2p_challenges")
                .select()
                .or("challenger_id.eq.\(userId),challenged_id.eq.\(userId)")
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
            
            return try supabaseService.customJSONDecoder().decode([P2PChallenge].self, from: response.data)
            
        } catch {
            print("🏆 P2PChallengeService: Failed to fetch active challenges: \(error)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func determineWinner(challenge: P2PChallenge) -> String? {
        guard let challengerResult = challenge.challengerResult,
              let challengedResult = challenge.challengedResult else {
            return nil // No results available
        }
        
        // Winner determination based on challenge type
        switch challenge.type {
        case "5k_race":
            // For races, fastest time wins (lower is better)
            return challengerResult < challengedResult ? challenge.challengerId : challenge.challengedId
        case "weekly_miles", "daily_run":
            // For distance/duration challenges, higher is better
            return challengerResult > challengedResult ? challenge.challengerId : challenge.challengedId
        default:
            // Default: higher is better
            return challengerResult > challengedResult ? challenge.challengerId : challenge.challengedId
        }
    }
    
    private func processPayout(winnerId: String, amount: Int, challengeId: String) async throws {
        // Record the transaction in the database
        try await supabaseService.recordTransaction(
            teamId: nil,
            userId: winnerId,
            walletId: nil,
            amount: amount,
            type: "p2p_challenge_win",
            description: "P2P Challenge winnings from challenge \(challengeId)",
            metadata: ["challenge_id": challengeId]
        )
        
        print("🏆 P2PChallengeService: Payout of \(amount) sats processed for winner \(winnerId)")
    }
    
    // MARK: - Notification Methods
    
    private func sendChallengeNotification(to userId: String, challenge: P2PChallenge) async {
        // Send immediate push notification
        await notificationService.scheduleChallengeInvitation(
            challengeId: challenge.id,
            fromUserId: challenge.challengerId,
            toUserId: userId,
            teamBranding: TeamBranding(teamId: "", teamName: "P2P Challenge", teamColor: "#f7931a", teamLogoUrl: nil),
            message: "You've been challenged to a \(challenge.type) competition!"
        )
        
        // Store persistent notification in inbox
        do {
            try await notificationInboxService.storeChallengeNotification(
                to: userId,
                from: challenge.challengerId,
                challengeId: challenge.id,
                type: "p2p_challenge_invitation",
                title: "P2P Challenge Invitation! 🏆",
                body: "You've been challenged to a \(challenge.type) competition!"
            )
        } catch {
            print("🏆 P2PChallengeService: Failed to store challenge notification in inbox: \(error)")
        }
    }
    
    private func sendChallengeAcceptedNotification(to userId: String, challenge: P2PChallenge) async {
        // Send immediate push notification
        await notificationService.scheduleTeamBrandedNotification(
            userId: userId,
            title: "Challenge Accepted! 💪",
            body: "Your P2P challenge has been accepted. Time to pay your stake!",
            teamBranding: TeamBranding(teamId: "", teamName: "P2P Challenge", teamColor: "#f7931a", teamLogoUrl: nil),
            type: "challenge_accepted"
        )
        
        // Store persistent notification in inbox
        do {
            try await notificationInboxService.storeChallengeNotification(
                to: userId,
                from: challenge.challengedId,
                challengeId: challenge.id,
                type: "p2p_challenge_accepted",
                title: "Challenge Accepted! 💪",
                body: "Your P2P challenge has been accepted. Time to pay your stake!"
            )
        } catch {
            print("🏆 P2PChallengeService: Failed to store accepted notification in inbox: \(error)")
        }
    }
    
    private func sendChallengeDeclinedNotification(to userId: String, challenge: P2PChallenge) async {
        // Send immediate push notification
        await notificationService.scheduleTeamBrandedNotification(
            userId: userId,
            title: "Challenge Declined",
            body: "Your P2P challenge was declined.",
            teamBranding: TeamBranding(teamId: "", teamName: "P2P Challenge", teamColor: "#f7931a", teamLogoUrl: nil),
            type: "challenge_declined"
        )
        
        // Store persistent notification in inbox  
        do {
            try await notificationInboxService.storeChallengeNotification(
                to: userId,
                from: challenge.challengedId,
                challengeId: challenge.id,
                type: "p2p_challenge_declined",
                title: "Challenge Declined",
                body: "Your P2P challenge was declined."
            )
        } catch {
            print("🏆 P2PChallengeService: Failed to store declined notification in inbox: \(error)")
        }
    }
    
    private func sendChallengeStartedNotification(to userId: String, challenge: P2PChallenge) async {
        // Send immediate push notification
        await notificationService.scheduleTeamBrandedNotification(
            userId: userId,
            title: "Challenge Started! 🏃‍♂️", 
            body: "Both players have paid. Let the challenge begin!",
            teamBranding: TeamBranding(teamId: "", teamName: "P2P Challenge", teamColor: "#f7931a", teamLogoUrl: nil),
            type: "challenge_started"
        )
        
        // Store persistent notification in inbox
        do {
            try await notificationInboxService.storeChallengeNotification(
                to: userId,
                from: "system", // System notification since both players paid
                challengeId: challenge.id,
                type: "p2p_challenge_started", 
                title: "Challenge Started! 🏃‍♂️",
                body: "Both players have paid. Let the challenge begin!"
            )
        } catch {
            print("🏆 P2PChallengeService: Failed to store started notification in inbox: \(error)")
        }
    }
    
    private func sendChallengeCompletedNotification(to userId: String, challenge: P2PChallenge) async {
        let isWinner = challenge.winnerId == userId
        let title = isWinner ? "You Won! 🏆" : "Challenge Complete"
        let message = isWinner ? "Congratulations! Your winnings have been added to your wallet." : "Better luck next time!"
        
        // Send immediate push notification
        await notificationService.scheduleTeamBrandedNotification(
            userId: userId,
            title: title,
            body: message,
            teamBranding: TeamBranding(teamId: "", teamName: "P2P Challenge", teamColor: "#f7931a", teamLogoUrl: nil),
            type: "challenge_completed"
        )
        
        // Store persistent notification in inbox
        do {
            try await notificationInboxService.storeChallengeNotification(
                to: userId,
                from: "system", // System notification for completion
                challengeId: challenge.id,
                type: "p2p_challenge_completed",
                title: title,
                body: message
            )
        } catch {
            print("🏆 P2PChallengeService: Failed to store completed notification in inbox: \(error)")
        }
    }
    
    // MARK: - Input Validation & Sanitization
    
    private func validateChallengeInputs(
        challengerId: String,
        challengedId: String,
        stakeAmount: Int,
        endDate: Date,
        message: String?
    ) throws {
        // Validate user IDs
        guard !challengerId.isEmpty && !challengedId.isEmpty else {
            throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user IDs provided"])
        }
        
        // Prevent self-challenges
        guard challengerId != challengedId else {
            throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot challenge yourself"])
        }
        
        // Validate stake amount
        guard stakeAmount >= 0 && stakeAmount <= 100000 else { // Max 100,000 sats
            throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Stake amount must be between 0 and 100,000 sats"])
        }
        
        // Validate end date is in the future
        guard endDate > Date() else {
            throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Challenge end date must be in the future"])
        }
        
        // Validate end date is not too far in the future (max 30 days)
        let maxEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        guard endDate <= maxEndDate else {
            throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Challenge end date cannot be more than 30 days in the future"])
        }
        
        // Validate message length if provided
        if let message = message {
            guard message.count <= 500 else {
                throw NSError(domain: "P2PChallengeService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Challenge message cannot exceed 500 characters"])
            }
        }
    }
    
    private func sanitizeMessage(_ message: String?) -> String {
        guard let message = message else { return "" }
        
        // Remove any potentially harmful characters and trim whitespace
        let sanitized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
            .replacingOccurrences(of: "/", with: "&#x2F;")
        
        // Limit length as additional safety
        return String(sanitized.prefix(500))
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