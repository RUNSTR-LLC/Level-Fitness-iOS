import Foundation

class CoinOSService {
    static let shared = CoinOSService()
    
    private let baseURL = "https://coinos.io"
    private var authToken: String?
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Authentication
    
    func setAuthToken(_ token: String) {
        authToken = token
        KeychainService.shared.save(token, for: .coinOSToken)
        print("CoinOSService: Auth token set successfully")
    }
    
    func loadAuthToken() -> String? {
        if authToken == nil {
            authToken = KeychainService.shared.load(for: .coinOSToken)
        }
        return authToken
    }
    
    func clearAuthToken() {
        authToken = nil
        KeychainService.shared.delete(for: .coinOSToken)
        print("CoinOSService: Auth token cleared")
    }
    
    // MARK: - User Registration and Login
    
    func registerUser(username: String, password: String) async throws -> CoinOSAuthResponse {
        let requestBody = CoinOSRegisterRequest(user: CoinOSUserCredentials(username: username, password: password))
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let authResponse = try JSONDecoder().decode(CoinOSAuthResponse.self, from: data)
        setAuthToken(authResponse.token)
        
        print("CoinOSService: User registered successfully")
        return authResponse
    }
    
    func loginUser(username: String, password: String) async throws -> CoinOSAuthResponse {
        let requestBody = CoinOSUserCredentials(username: username, password: password)
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let authResponse = try JSONDecoder().decode(CoinOSAuthResponse.self, from: data)
        setAuthToken(authResponse.token)
        
        print("CoinOSService: User logged in successfully")
        return authResponse
    }
    
    // MARK: - Wallet Creation for New Users
    
    func createWalletForUser(_ userId: String) async throws -> LightningWallet {
        // Generate unique CoinOS credentials for this user
        let username = "levelfitness_\(userId.prefix(8))"
        let password = generateSecurePassword()
        
        do {
            // Register new user with CoinOS
            let authResponse = try await registerUser(username: username, password: password)
            
            // Get user balance and details
            let userInfo = try await getCurrentUser()
            
            let wallet = LightningWallet(
                id: authResponse.userId ?? UUID().uuidString,
                userId: userId,
                provider: "coinos",
                balance: userInfo?.balance ?? 0,
                address: username,
                createdAt: Date()
            )
            
            // Store CoinOS credentials securely
            KeychainService.shared.save(username, for: .coinOSUsername)
            KeychainService.shared.save(password, for: .coinOSPassword)
            
            print("CoinOSService: Created CoinOS wallet for user \(userId)")
            return wallet
        } catch {
            print("CoinOSService: Failed to create CoinOS wallet: \(error)")
            throw CoinOSError.walletCreationFailed
        }
    }
    
    private func generateSecurePassword() -> String {
        let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return String((0..<16).map { _ in charset.randomElement()! })
    }
    
    // MARK: - Lightning Network Operations
    
    func getCurrentUser() async throws -> CoinOSUserInfo? {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/me")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(CoinOSUserInfo.self, from: data)
    }
    
    func getBalance() async throws -> WalletBalance {
        let userInfo = try await getCurrentUser()
        
        let totalBalance = userInfo?.balance ?? 0
        
        return WalletBalance(
            lightning: totalBalance, // CoinOS shows total balance
            onchain: 0,
            liquid: 0,
            total: totalBalance
        )
    }
    
    func addInvoice(amount: Int, memo: String = "") async throws -> LightningInvoice {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        let requestBody = CoinOSInvoiceRequest(invoice: CoinOSInvoiceData(amount: amount, type: "lightning"))
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/invoice")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let invoiceResponse = try JSONDecoder().decode(CoinOSInvoiceResponse.self, from: data)
        
        return LightningInvoice(
            id: invoiceResponse.hash ?? invoiceResponse.uid ?? UUID().uuidString,
            paymentRequest: invoiceResponse.text ?? "",
            amount: amount,
            memo: memo,
            status: (invoiceResponse.received ?? 0) > 0 ? "paid" : "pending",
            createdAt: Date(timeIntervalSince1970: TimeInterval((invoiceResponse.created ?? 0) / 1000)),
            expiresAt: Date().addingTimeInterval(3600) // 1 hour expiry
        )
    }
    
    func payInvoice(_ paymentRequest: String) async throws -> PaymentResult {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        let requestBody = CoinOSPaymentRequest(payreq: paymentRequest)
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/payments")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let paymentResponse = try JSONDecoder().decode(CoinOSPaymentResponse.self, from: data)
        
        return PaymentResult(
            success: paymentResponse.confirmed ?? false,
            paymentHash: paymentResponse.hash ?? "",
            preimage: paymentResponse.preimage,
            feePaid: paymentResponse.fee ?? 0,
            timestamp: Date()
        )
    }
    
    func listInvoices(limit: Int = 20) async throws -> [LightningInvoice] {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/payments?limit=\(limit)")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let invoicesResponse = try JSONDecoder().decode([CoinOSInvoiceResponse].self, from: data)
        
        return invoicesResponse.map { invoice in
            LightningInvoice(
                id: invoice.hash ?? invoice.uid ?? UUID().uuidString,
                paymentRequest: invoice.text ?? "",
                amount: invoice.amount ?? 0,
                memo: "", // CoinOS doesn't return memo in list
                status: (invoice.received ?? 0) > 0 ? "paid" : "pending",
                createdAt: Date(timeIntervalSince1970: TimeInterval((invoice.created ?? 0) / 1000)),
                expiresAt: Date().addingTimeInterval(3600)
            )
        }
    }
    
    func lookupInvoice(_ invoiceHash: String) async throws -> LightningInvoice {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        var request = URLRequest(url: URL(string: "\(baseURL)/invoice/\(invoiceHash)")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let invoiceResponse = try JSONDecoder().decode(CoinOSInvoiceResponse.self, from: data)
        
        return LightningInvoice(
            id: invoiceResponse.hash ?? invoiceResponse.uid ?? UUID().uuidString,
            paymentRequest: invoiceResponse.text ?? "",
            amount: invoiceResponse.amount ?? 0,
            memo: "", // CoinOS doesn't include memo in response
            status: (invoiceResponse.received ?? 0) > 0 ? "paid" : "pending",
            createdAt: Date(timeIntervalSince1970: TimeInterval((invoiceResponse.created ?? 0) / 1000)),
            expiresAt: Date().addingTimeInterval(3600)
        )
    }
    
    // MARK: - Reward Distribution
    
    func distributeReward(to userId: String, amount: Int, memo: String) async throws -> PaymentResult {
        // This would typically create an invoice for the user and immediately pay it
        // For Level Fitness rewards distribution
        
        print("CoinOSService: Distributing \(amount) sats to user \(userId) - \(memo)")
        
        // In production, this would involve creating an invoice for the user's wallet
        // and then paying it from the Level Fitness treasury wallet
        
        return PaymentResult(
            success: true,
            paymentHash: "reward_\(UUID().uuidString)",
            preimage: nil,
            feePaid: 1, // 1 sat fee
            timestamp: Date()
        )
    }
}

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

private struct CoinOSRegisterRequest: Codable {
    let user: CoinOSUserCredentials
}

private struct CoinOSUserCredentials: Codable {
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

private struct CoinOSInvoiceRequest: Codable {
    let invoice: CoinOSInvoiceData
}

private struct CoinOSInvoiceData: Codable {
    let amount: Int
    let type: String
}

private struct CoinOSInvoiceResponse: Codable {
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

private struct CoinOSPaymentRequest: Codable {
    let payreq: String
}

private struct CoinOSPaymentResponse: Codable {
    let confirmed: Bool?
    let hash: String?
    let preimage: String?
    let fee: Int?
}

// MARK: - Errors

enum CoinOSError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case apiError(Int)
    case networkError
    case decodingError
    case walletCreationFailed
    
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
        }
    }
}