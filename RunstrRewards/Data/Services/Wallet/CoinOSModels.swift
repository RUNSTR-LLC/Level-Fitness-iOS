import Foundation

// MARK: - Data Models

struct LightningWallet: Codable {
    let id: String
    let userId: String
    let provider: String
    let balance: Int
    let address: String
    let createdAt: Date
}

struct WalletBalance: Codable {
    let lightning: Int
    let onchain: Int
    let liquid: Int
    let total: Int
}

struct LightningInvoice: Codable {
    let id: String
    let paymentRequest: String
    let amount: Int
    let memo: String
    let status: String
    let createdAt: Date
    let expiresAt: Date
}

struct PaymentResult: Codable {
    let success: Bool
    let paymentHash: String
    let preimage: String?
    let feePaid: Int
    let timestamp: Date
}

// MARK: - CoinOS API Request/Response Models

struct CoinOSRegisterRequest: Codable {
    let user: CoinOSUserCredentials
}

struct CoinOSUserCredentials: Codable {
    let username: String
    let password: String
}

struct CoinOSAuthResponse: Codable {
    let token: String
    let userId: String?
    
    private enum CodingKeys: String, CodingKey {
        case token
        case userId = "id"
    }
}

struct CoinOSUserInfo: Codable {
    let id: String?
    let username: String?
    let balance: Int?
    let currency: String?
    let language: String?
}

struct CoinOSInvoiceRequest: Codable {
    let invoice: CoinOSInvoiceData
}

struct CoinOSInvoiceData: Codable {
    let amount: Int
    let type: String
}

struct CoinOSInvoiceResponse: Codable {
    let amount: Int?
    let tip: Int?
    let type: String?
    let prompt: Bool?
    let rate: Double?
    let hash: String?
    let text: String?
    let currency: String?
    let uid: String?
    let received: Int?
    let created: Int64?
}

struct CoinOSPaymentRequest: Codable {
    let payreq: String
}

struct CoinOSPaymentResponse: Codable {
    let confirmed: Bool?
    let hash: String?
    let preimage: String?
    let fee: Int?
}

// MARK: - CoinOS Transaction Models

struct CoinOSTransaction: Codable {
    let id: String
    let amount: Int
    let type: String
    let memo: String
    let confirmed: Bool
    let createdAt: Date
    let hash: String
}

struct TeamWalletCredentials {
    let username: String
    let password: String
    let token: String
}

// MARK: - Payment Coordination Models

struct PaymentCoordinationInfo: Codable {
    let userId: String
    let lightningAddress: String
    let currentBalance: Int
    let coinOSUsername: String
    let lastUpdated: Date
}

struct CoinOSPaymentData: Codable {
    let id: String
    let amount: Int
    let type: String?
    let memo: String?
    let confirmed: Bool?
    let created: Int64?
    let hash: String?
}

// MARK: - Wallet Context Management

enum WalletContext {
    case none
    case user(String) // userId
    case team(String) // teamId
}

// MARK: - Errors

enum CoinOSError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case apiError(Int)
    case networkError
    case decodingError
    case walletCreationFailed
    case invalidAmount
    case insufficientBalance
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "CoinOS authentication required"
        case .invalidResponse:
            return "Invalid response from CoinOS API"
        case .apiError(let code):
            return "CoinOS API error: HTTP \(code)"
        case .networkError:
            return "Network error connecting to CoinOS"
        case .decodingError:
            return "Failed to decode CoinOS response"
        case .walletCreationFailed:
            return "Failed to create CoinOS wallet"
        case .invalidAmount:
            return "Invalid transfer amount"
        case .insufficientBalance:
            return "Insufficient wallet balance"
        }
    }
}