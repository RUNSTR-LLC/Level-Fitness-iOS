import Foundation
import UIKit

// MARK: - Challenge Status Enum

enum ChallengeStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case active = "active"
    case completed = "completed"
    
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
        }
    }
}

// MARK: - Event Subtype Enum

enum EventSubtype: String, CaseIterable, Codable {
    case standard = "standard"
    case challenge = "challenge"
    
    var displayName: String {
        switch self {
        case .standard:
            return "Event"
        case .challenge:
            return "Challenge"
        }
    }
}

// MARK: - Challenge Data Model

struct ChallengeData: Codable {
    let challengerId: String
    let challengedUserIds: [String]
    let challengeStatus: ChallengeStatus
    let teamArbitrationFee: Int
    let challengeMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case challengerId = "challenger_id"
        case challengedUserIds = "challenged_user_ids"
        case challengeStatus = "challenge_status"
        case teamArbitrationFee = "team_arbitration_fee"
        case challengeMessage = "challenge_message"
    }
}

// MARK: - Event Extension for Challenges

extension Event {
    
    // MARK: - Challenge Properties
    
    var isChallenge: Bool {
        return eventSubtype == .challenge
    }
    
    var eventSubtype: EventSubtype {
        // This would be populated from the database field
        return EventSubtype(rawValue: "challenge") ?? .standard // TODO: Get from actual event data
    }
    
    var challengeStatus: ChallengeStatus {
        // This would be populated from the database field
        return ChallengeStatus(rawValue: "pending") ?? .pending // TODO: Get from actual event data
    }
    
    var challengerId: String? {
        // TODO: Get from actual event data
        return nil
    }
    
    var challengedUserIds: [String] {
        // TODO: Get from actual event data
        return []
    }
    
    var teamArbitrationFee: Int {
        // TODO: Get from actual event data, default to 10%
        return 10
    }
    
    var challengeMessage: String? {
        // TODO: Get from actual event data
        return nil
    }
    
    // MARK: - Challenge Helper Methods
    
    var isUserChallenger: Bool {
        guard let currentUserId = AuthenticationService.shared.currentUserId else { return false }
        return challengerId == currentUserId
    }
    
    var isUserChallenged: Bool {
        guard let currentUserId = AuthenticationService.shared.currentUserId else { return false }
        return challengedUserIds.contains(currentUserId)
    }
    
    var canUserAcceptChallenge: Bool {
        return isChallenge && 
               challengeStatus == .pending && 
               isUserChallenged && 
               !isUserChallenger
    }
    
    var canUserDeclineChallenge: Bool {
        return isChallenge && 
               challengeStatus == .pending && 
               isUserChallenged && 
               !isUserChallenger
    }
    
    var challengeDisplayText: String {
        if let challengerId = challengerId,
           let challengerName = getUserName(for: challengerId) {
            let opponentNames = challengedUserIds.compactMap { getUserName(for: $0) }
            if opponentNames.count == 1 {
                return "\(challengerName) vs \(opponentNames.first!)"
            } else if opponentNames.count > 1 {
                return "\(challengerName) vs \(opponentNames.joined(separator: ", "))"
            } else {
                return "\(challengerName)'s Challenge"
            }
        }
        return "Challenge"
    }
    
    var stakesDisplayText: String {
        if entryFee > 0 {
            return "\(entryFee) sats"
        }
        return "Free"
    }
    
    var arbitrationFeeAmount: Int {
        let totalPot = entryFee * participantCount
        return (totalPot * teamArbitrationFee) / 100
    }
    
    var winnerPayout: Int {
        let totalPot = entryFee * participantCount
        return totalPot - arbitrationFeeAmount
    }
    
    // MARK: - Challenge Actions
    
    func acceptChallenge(userId: String) async throws {
        guard canUserAcceptChallenge else {
            throw ChallengeError.invalidAction("Cannot accept this challenge")
        }
        
        do {
            // Update challenge status
            try await SupabaseService.shared.updateChallengeStatus(
                eventId: id,
                status: .accepted,
                userId: userId
            )
            
            // Join the event
            try await joinEvent(userId: userId)
            
            // Send notification to challenger
            if let challengerId = challengerId {
                try await NotificationInboxService.shared.storeNotification(
                    userId: challengerId,
                    type: "challenge_accepted",
                    title: "Challenge Accepted!",
                    body: "Your challenge has been accepted.",
                    eventId: id,
                    actionData: ["event_id": id, "action": "accepted"]
                )
            }
            
            print("🏆 Challenge: Accepted challenge \(id) by user \(userId)")
        } catch {
            print("❌ Challenge: Failed to accept challenge: \(error)")
            throw error
        }
    }
    
    func declineChallenge(userId: String) async throws {
        guard canUserDeclineChallenge else {
            throw ChallengeError.invalidAction("Cannot decline this challenge")
        }
        
        do {
            // Update challenge status
            try await SupabaseService.shared.updateChallengeStatus(
                eventId: id,
                status: .declined,
                userId: userId
            )
            
            // Send notification to challenger
            if let challengerId = challengerId {
                try await NotificationInboxService.shared.storeNotification(
                    userId: challengerId,
                    type: "challenge_declined",
                    title: "Challenge Declined",
                    body: "Your challenge was declined.",
                    eventId: id,
                    actionData: ["event_id": id, "action": "declined"]
                )
            }
            
            print("❌ Challenge: Declined challenge \(id) by user \(userId)")
        } catch {
            print("❌ Challenge: Failed to decline challenge: \(error)")
            throw error
        }
    }
    
    private func joinEvent(userId: String) async throws {
        // TODO: Implement event joining logic
        // This will be implemented when we have the full Event model
        print("🏆 Challenge: Joining event \(id) for user \(userId)")
    }
    
    private func getUserName(for userId: String) -> String? {
        // TODO: Implement user lookup
        // For now, return placeholder
        return "User"
    }
    
    // MARK: - Challenge Settlement
    
    func settleChallengeResults() async throws {
        guard isChallenge && challengeStatus == .completed else {
            throw ChallengeError.invalidAction("Challenge is not ready for settlement")
        }
        
        do {
            // Get final results from EventProgressTracker
            let results = try await EventProgressTracker.shared.getEventResults(eventId: id)
            
            // Determine winner (highest value wins)
            guard let winner = results.max(by: { $0.value < $1.value }) else {
                throw ChallengeError.noResults("No results found for challenge")
            }
            
            // Calculate payouts
            let totalPot = entryFee * participantCount
            let teamFee = arbitrationFeeAmount
            let winnerPayout = totalPot - teamFee
            
            // Pay the winner
            if winnerPayout > 0 {
                try await payoutWinner(userId: winner.userId, amount: winnerPayout)
            }
            
            // Pay team arbitration fee
            if teamFee > 0 {
                try await payTeamFee(amount: teamFee)
            }
            
            // Send result notifications
            try await sendResultNotifications(winner: winner, results: results)
            
            print("🏆 Challenge: Successfully settled challenge \(id)")
        } catch {
            print("❌ Challenge: Failed to settle challenge: \(error)")
            throw error
        }
    }
    
    private func payoutWinner(userId: String, amount: Int) async throws {
        // TODO: Implement winner payout via team wallet
        print("💰 Challenge: Paying winner \(userId) amount: \(amount) sats")
    }
    
    private func payTeamFee(amount: Int) async throws {
        // TODO: Implement team fee payment
        print("💰 Challenge: Paying team fee: \(amount) sats")
    }
    
    private func sendResultNotifications(winner: EventResult, results: [EventResult]) async throws {
        // Send notification to all participants
        for result in results {
            let isWinner = result.userId == winner.userId
            let title = isWinner ? "🏆 You won!" : "Challenge Complete"
            let body = isWinner ? 
                "Congratulations! You won the challenge and earned \(winnerPayout) sats!" :
                "Challenge completed. Winner: \(getUserName(for: winner.userId) ?? "Unknown")"
            
            try await NotificationInboxService.shared.storeNotification(
                userId: result.userId,
                type: "challenge_result",
                title: title,
                body: body,
                eventId: id,
                actionData: [
                    "event_id": id,
                    "result": isWinner ? "won" : "completed",
                    "amount": String(isWinner ? winnerPayout : 0)
                ]
            )
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

// MARK: - Supporting Data Structures

struct EventResult {
    let userId: String
    let value: Double
    let rank: Int
}

// MARK: - Placeholder Event Model

// This is a placeholder until we can access the actual Event model
// TODO: Remove this when integrating with real Event model
struct Event {
    let id: String
    let name: String
    let entryFee: Int
    let participantCount: Int
    
    // Add other necessary properties as needed
}

// MARK: - SupabaseService Challenge Extensions

extension SupabaseService {
    
    func updateChallengeStatus(eventId: String, status: ChallengeStatus, userId: String) async throws {
        // TODO: Implement Supabase update
        print("🔄 SupabaseService: Updating challenge \(eventId) status to \(status)")
    }
    
    func createChallenge(
        name: String,
        type: String,
        targetValue: Double,
        unit: String,
        entryFee: Int,
        startDate: Date,
        endDate: Date,
        challengerId: String,
        challengedUserIds: [String],
        teamId: String,
        message: String?
    ) async throws -> String {
        // TODO: Implement challenge creation
        print("🆕 SupabaseService: Creating challenge between \(challengerId) and \(challengedUserIds)")
        return UUID().uuidString // Placeholder
    }
    
    func getChallengesForTeam(teamId: String) async throws -> [Event] {
        // TODO: Implement challenge retrieval
        print("📥 SupabaseService: Getting challenges for team \(teamId)")
        return [] // Placeholder
    }
    
    func getChallengesForUser(userId: String) async throws -> [Event] {
        // TODO: Implement user challenge retrieval
        print("📥 SupabaseService: Getting challenges for user \(userId)")
        return [] // Placeholder
    }
}