import Foundation

// MARK: - Team Wallet Access Types

enum TeamWalletAccessType {
    case view    // Can see balance and transactions
    case manage  // Can fund wallet and distribute rewards
}

enum TeamRole {
    case captain
    case member
    case none
    
    var description: String {
        switch self {
        case .captain: return "Team Captain"
        case .member: return "Team Member"
        case .none: return "Not a team member"
        }
    }
}

enum TeamWalletOperation {
    case fundWallet
    case distributeReward
}

// MARK: - Team Wallet Data Models

struct TeamWallet: Codable {
    let id: String
    let teamId: String
    let captainId: String
    let provider: String
    let balance: Int
    let address: String
    let walletId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case captainId = "captain_id" 
        case provider
        case balance
        case address
        case walletId = "wallet_id"
        case createdAt = "created_at"
    }
}

struct UserWalletCredentials {
    let username: String
    let password: String
}

struct TeamWalletBalance {
    let teamId: String
    let totalBalance: Double
    let availableBalance: Double
    let pendingDistributions: Double
    let lastUpdated: Date
    let transactions: [TeamTransaction]
}

struct TeamTransaction {
    let transactionId: String
    let type: TeamTransactionType
    let amount: Double
    let description: String
    let timestamp: Date
    let userId: String?
    let eventId: String?
}

enum TeamTransactionType {
    case prizeReceived
    case prizeDistributed
    case memberContribution
    case feeDeducted
    
    var capitalized: String {
        switch self {
        case .prizeReceived:
            return "Prize Received"
        case .prizeDistributed:
            return "Prize Distributed"
        case .memberContribution:
            return "Member Contribution"
        case .feeDeducted:
            return "Fee Deducted"
        }
    }
}

enum RewardDistributionType {
    case equal
    case weighted([Int]) // Array of weights for each recipient
}

// MARK: - Error Types

enum TeamWalletError: LocalizedError {
    case teamWalletCreationFailed
    case teamWalletNotFound
    case authenticationRequired
    case notAuthorized
    case insufficientBalance
    case rewardDistributionFailed
    case userWalletNotFound
    case userInvoiceCreationFailed
    case keychainError(String)
    case networkError(String)
    case invalidCredentials
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .teamWalletCreationFailed:
            return "Failed to create team wallet"
        case .teamWalletNotFound:
            return "Team wallet not found"
        case .authenticationRequired:
            return "Authentication required for team wallet access"
        case .notAuthorized:
            return "Not authorized to access team wallet"
        case .insufficientBalance:
            return "Insufficient balance in team wallet"
        case .rewardDistributionFailed:
            return "Failed to distribute rewards"
        case .userWalletNotFound:
            return "User wallet not found"
        case .userInvoiceCreationFailed:
            return "Failed to create user invoice"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidCredentials:
            return "Invalid wallet credentials"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        }
    }
}

enum TeamWalletAccessError: LocalizedError {
    case notAuthenticated
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Authentication required to access team wallet"
        case .accessDenied:
            return "Access denied for team wallet operation"
        }
    }
}