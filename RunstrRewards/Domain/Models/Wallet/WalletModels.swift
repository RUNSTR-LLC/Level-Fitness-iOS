import Foundation

// MARK: - Wallet Result Types

struct DistributionResult: Codable {
    let success: Bool
    let totalAmount: Int
    let distributedAmount: Int
    let recipientCount: Int
    let failedRecipients: [String]
    let transactionHashes: [String]
    let timestamp: Date
    let distributionId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case totalAmount = "total_amount"
        case distributedAmount = "distributed_amount"
        case recipientCount = "recipient_count"
        case failedRecipients = "failed_recipients"
        case transactionHashes = "transaction_hashes"
        case timestamp
        case distributionId = "distribution_id"
    }
    
    var failureRate: Double {
        guard recipientCount > 0 else { return 0 }
        return Double(failedRecipients.count) / Double(recipientCount)
    }
    
    var successRate: Double {
        return 1.0 - failureRate
    }
    
    var hasPartialFailures: Bool {
        return !failedRecipients.isEmpty && success
    }
}

// MARK: - Subscription Models

struct SubscriptionData: Codable {
    let id: String
    let userId: String
    let teamId: String?
    let subscriptionType: String // "individual", "team"
    let status: String // "active", "cancelled", "past_due", "expired"
    let priceId: String
    let amount: Int // in cents
    let currency: String
    let interval: String // "month", "year"
    let currentPeriodStart: Date
    let currentPeriodEnd: Date
    let cancelAtPeriodEnd: Bool
    let trialEnd: Date?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case subscriptionType = "subscription_type"
        case status
        case priceId = "price_id"
        case amount
        case currency
        case interval
        case currentPeriodStart = "current_period_start"
        case currentPeriodEnd = "current_period_end"
        case cancelAtPeriodEnd = "cancel_at_period_end"
        case trialEnd = "trial_end"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Computed Properties
    
    var isActive: Bool {
        return status == "active"
    }
    
    var isExpired: Bool {
        return status == "expired" || Date() > currentPeriodEnd
    }
    
    var isPastDue: Bool {
        return status == "past_due"
    }
    
    var isCancelled: Bool {
        return status == "cancelled"
    }
    
    var isInTrial: Bool {
        guard let trialEnd = trialEnd else { return false }
        return Date() < trialEnd
    }
    
    var daysRemaining: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: currentPeriodEnd).day ?? 0
    }
    
    var monthlyAmount: Double {
        let baseAmount = Double(amount) / 100.0 // Convert from cents
        switch interval {
        case "month":
            return baseAmount
        case "year":
            return baseAmount / 12.0
        default:
            return baseAmount
        }
    }
    
    var isIndividualSubscription: Bool {
        return subscriptionType == "individual"
    }
    
    var isTeamSubscription: Bool {
        return subscriptionType == "team"
    }
}



// MARK: - Team Wallet Data Model

struct TeamWalletData {
    let teamId: String
    let balance: Int
    let pendingDistributions: [PendingDistribution]
    let recentTransactions: [CoinOSTransaction]
    let memberPayouts: [MemberPayout]
    let lastUpdated: Date
}

struct PendingDistribution {
    let id: String
    let amount: Int
    let recipientCount: Int
    let scheduledDate: Date
    let status: String
}

struct MemberPayout {
    let memberId: String
    let memberName: String
    let amount: Int
    let transactionHash: String?
    let paidAt: Date?
    let status: String // "pending", "completed", "failed"
}