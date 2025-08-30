import Foundation
import UIKit

// MARK: - Pending Payment Models

struct PendingPayment: Codable, Identifiable {
    let id: String
    let teamId: String
    let type: PaymentType
    let title: String
    let description: String
    let recipients: [PaymentRecipient]
    let totalAmount: Int // in sats
    var status: PaymentStatus
    let createdAt: Date
    var paidAt: Date?
    let referenceId: String? // eventId, challengeId, etc
    
    init(
        teamId: String,
        type: PaymentType,
        title: String,
        description: String,
        recipients: [PaymentRecipient],
        totalAmount: Int,
        referenceId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.teamId = teamId
        self.type = type
        self.title = title
        self.description = description
        self.recipients = recipients
        self.totalAmount = totalAmount
        self.status = .pending
        self.createdAt = Date()
        self.paidAt = nil
        self.referenceId = referenceId
    }
}

enum PaymentType: String, Codable, CaseIterable {
    case event = "event"
    case challenge = "challenge" 
    case leaderboard = "leaderboard"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .event:
            return "Event"
        case .challenge:
            return "Challenge"
        case .leaderboard:
            return "Leaderboard"
        case .custom:
            return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .event:
            return "trophy.fill"
        case .challenge:
            return "bolt.fill"
        case .leaderboard:
            return "chart.bar.fill"
        case .custom:
            return "bitcoinsign.circle.fill"
        }
    }
    
    var iconColor: UIColor {
        switch self {
        case .event:
            return .systemYellow
        case .challenge:
            return .systemOrange
        case .leaderboard:
            return .systemBlue
        case .custom:
            return IndustrialDesign.Colors.bitcoin
        }
    }
}

struct PaymentRecipient: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let amount: Int // sats
    let position: Int?
    let reason: String
    
    init(userId: String, username: String, amount: Int, position: Int? = nil, reason: String) {
        self.id = UUID().uuidString
        self.userId = userId
        self.username = username
        self.amount = amount
        self.position = position
        self.reason = reason
    }
}

enum PaymentStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    var color: UIColor {
        switch self {
        case .pending:
            return .systemOrange
        case .processing:
            return .systemBlue
        case .completed:
            return .systemGreen
        case .failed:
            return .systemRed
        }
    }
}

// MARK: - Payment Creation Helpers

extension PendingPayment {
    
    /// Create payment for event completion
    static func forEvent(
        teamId: String,
        eventName: String,
        eventId: String,
        endDate: Date,
        winners: [(userId: String, username: String, position: Int, amount: Int)]
    ) -> PendingPayment {
        
        let recipients = winners.map { winner in
            PaymentRecipient(
                userId: winner.userId,
                username: winner.username,
                amount: winner.amount,
                position: winner.position,
                reason: "Position #\(winner.position)"
            )
        }
        
        let totalAmount = recipients.reduce(0) { $0 + $1.amount }
        
        return PendingPayment(
            teamId: teamId,
            type: .event,
            title: "Event: \(eventName)",
            description: "Completed \(formatDate(endDate))",
            recipients: recipients,
            totalAmount: totalAmount,
            referenceId: eventId
        )
    }
    
    /// Create payment for P2P challenge completion
    static func forChallenge(
        teamId: String,
        challengerId: String,
        challengerName: String,
        challengedId: String,
        challengedName: String,
        winnerId: String,
        winnerName: String,
        amount: Int,
        challengeId: String
    ) -> PendingPayment {
        
        let recipient = PaymentRecipient(
            userId: winnerId,
            username: winnerName,
            amount: amount,
            reason: "Challenge winner"
        )
        
        return PendingPayment(
            teamId: teamId,
            type: .challenge,
            title: "P2P Challenge",
            description: "\(challengerName) vs \(challengedName)",
            recipients: [recipient],
            totalAmount: amount,
            referenceId: challengeId
        )
    }
    
    /// Create payment for weekly leaderboard
    static func forLeaderboard(
        teamId: String,
        weekEnding: Date,
        topUsers: [(userId: String, username: String, rank: Int, amount: Int)]
    ) -> PendingPayment {
        
        let recipients = topUsers.map { user in
            PaymentRecipient(
                userId: user.userId,
                username: user.username,
                amount: user.amount,
                position: user.rank,
                reason: "Leaderboard position #\(user.rank)"
            )
        }
        
        let totalAmount = recipients.reduce(0) { $0 + $1.amount }
        
        return PendingPayment(
            teamId: teamId,
            type: .leaderboard,
            title: "Weekly Leaderboard",
            description: "Week ending \(formatDate(weekEnding))",
            recipients: recipients,
            totalAmount: totalAmount,
            referenceId: nil
        )
    }
    
    /// Create custom payment
    static func custom(
        teamId: String,
        title: String,
        description: String,
        recipients: [PaymentRecipient]
    ) -> PendingPayment {
        
        let totalAmount = recipients.reduce(0) { $0 + $1.amount }
        
        return PendingPayment(
            teamId: teamId,
            type: .custom,
            title: title,
            description: description,
            recipients: recipients,
            totalAmount: totalAmount,
            referenceId: nil
        )
    }
}

// MARK: - Helper Functions

private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}