import Foundation

class CoinOSService {
    static let shared = CoinOSService()
    
    private let baseURL = "https://coinos.io/api"
    private var authToken: String?
    private let session = URLSession.shared
    
    private init() {
        // Load existing auth token from keychain if available
        self.authToken = KeychainService.shared.load(for: .coinOSToken)
        if self.authToken != nil {
            print("CoinOSService: Initialized with existing auth token from keychain")
        } else {
            print("CoinOSService: Initialized without auth token - user needs to create wallet")
        }
    }
    
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
    
    func getCurrentAuthToken() -> String? {
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
        
        print("CoinOSService: Registering user with username: \(username)")
        
        var request = URLRequest(url: URL(string: "\(baseURL)/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            // Log the error response for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("CoinOSService: Registration failed with status \(httpResponse.statusCode): \(errorString)")
            }
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        let authResponse = try JSONDecoder().decode(CoinOSAuthResponse.self, from: data)
        setAuthToken(authResponse.token)
        
        print("CoinOSService: User registered successfully with token")
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
        // CoinOS only allows letters and numbers in usernames
        let timestamp = String(Int(Date().timeIntervalSince1970)).suffix(8) // Last 8 digits
        let randomSuffix = Int.random(in: 1000...9999)
        let cleanUserId = userId.replacingOccurrences(of: "-", with: "").prefix(6)
        let username = "lf\(cleanUserId)\(timestamp)\(randomSuffix)"
        let password = generateSecurePassword()
        
        print("CoinOSService: Creating wallet for user \(userId) with username \(username)")
        
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
            
            // Store CoinOS credentials securely for this user
            KeychainService.shared.save(username, for: .coinOSUsername)
            KeychainService.shared.save(password, for: .coinOSPassword)
            
            print("CoinOSService: Successfully created CoinOS wallet for user \(userId)")
            return wallet
        } catch {
            print("CoinOSService: Failed to create CoinOS wallet for user \(userId): \(error)")
            throw CoinOSError.walletCreationFailed
        }
    }
    
    private func generateSecurePassword() -> String {
        // CoinOS might have restrictions on password characters, use only alphanumeric
        let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
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
    
    func listTransactions(limit: Int = 50) async throws -> [CoinOSTransaction] {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        print("CoinOSService: Fetching transactions for authenticated user (limit: \(limit))")
        
        var request = URLRequest(url: URL(string: "\(baseURL)/payments?limit=\(limit)")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinOSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("CoinOSService: Failed to fetch transactions, HTTP \(httpResponse.statusCode)")
            throw CoinOSError.apiError(httpResponse.statusCode)
        }
        
        // Parse the response which contains a "payments" array
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let paymentsArray = json?["payments"] as? [[String: Any]] else {
            print("CoinOSService: No payments found in response")
            throw CoinOSError.decodingError
        }
        
        let paymentsData = try JSONSerialization.data(withJSONObject: paymentsArray, options: [])
        let decoder = JSONDecoder()
        let payments = try decoder.decode([CoinOSPaymentData].self, from: paymentsData)
        
        let transactions = payments.map { payment in
            CoinOSTransaction(
                id: payment.id,
                amount: payment.amount,
                type: payment.type ?? "lightning",
                memo: payment.memo ?? "",
                confirmed: payment.confirmed ?? true,
                createdAt: Date(timeIntervalSince1970: TimeInterval((payment.created ?? 0) / 1000)),
                hash: payment.hash ?? ""
            )
        }
        
        print("CoinOSService: Retrieved \(transactions.count) transactions for authenticated user")
        return transactions
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
        // For RunstrRewards rewards distribution
        
        print("CoinOSService: Distributing \(amount) sats to user \(userId) - \(memo)")
        
        // In production, this would involve creating an invoice for the user's wallet
        // and then paying it from the RunstrRewards treasury wallet
        
        return PaymentResult(
            success: true,
            paymentHash: "reward_\(UUID().uuidString)",
            preimage: nil,
            feePaid: 1, // 1 sat fee
            timestamp: Date()
        )
    }
    
    // MARK: - Team Wallet Operations
    
    func createTeamWallet(for teamId: String) async throws -> LightningWallet {
        // Generate unique CoinOS credentials for team wallet
        let timestamp = String(Int(Date().timeIntervalSince1970)).suffix(8)
        let randomSuffix = Int.random(in: 1000...9999)
        let cleanTeamId = teamId.replacingOccurrences(of: "-", with: "").prefix(6)
        let username = "team\(cleanTeamId)\(timestamp)\(randomSuffix)"
        let password = generateSecurePassword()
        
        print("CoinOSService: Creating team wallet for team \(teamId) with username \(username)")
        
        do {
            // Register new team wallet with CoinOS
            let authResponse = try await registerUser(username: username, password: password)
            
            // Get wallet details
            let userInfo = try await getCurrentUser()
            
            let wallet = LightningWallet(
                id: authResponse.userId ?? UUID().uuidString,
                userId: teamId, // Using teamId as the identifier
                provider: "coinos",
                balance: userInfo?.balance ?? 0,
                address: username,
                createdAt: Date()
            )
            
            print("CoinOSService: Successfully created team wallet for team \(teamId)")
            return wallet
            
        } catch {
            print("CoinOSService: Failed to create team wallet for team \(teamId): \(error)")
            throw CoinOSError.walletCreationFailed
        }
    }
    
    func authenticateWithTeamWallet(username: String, password: String) async throws {
        print("CoinOSService: Authenticating with team wallet \(username)")
        
        do {
            let authResponse = try await loginUser(username: username, password: password)
            setAuthToken(authResponse.token)
            print("CoinOSService: Successfully authenticated with team wallet")
        } catch {
            print("CoinOSService: Failed to authenticate with team wallet: \(error)")
            throw error
        }
    }
    
    func switchToTeamWalletContext(teamId: String, credentials: TeamWalletCredentials) async throws {
        print("CoinOSService: Switching to team wallet context for team \(teamId)")
        
        try await authenticateWithTeamWallet(username: credentials.username, password: credentials.password)
    }
    
    func switchToUserWalletContext(userId: String) async throws {
        print("CoinOSService: Switching back to user wallet context for user \(userId)")
        
        // Clear current team wallet token
        clearAuthToken()
        
        // Load user's wallet credentials
        if let username = KeychainService.shared.load(for: .coinOSUsername),
           let password = KeychainService.shared.load(for: .coinOSPassword) {
            try await authenticateWithTeamWallet(username: username, password: password)
        } else {
            throw CoinOSError.notAuthenticated
        }
    }
    
    func transferFromTeamToUser(
        fromTeamId: String,
        fromCredentials: TeamWalletCredentials,
        toUserId: String,
        amount: Int,
        memo: String
    ) async throws -> PaymentResult {
        print("CoinOSService: Transferring \(amount) sats from team \(fromTeamId) to user \(toUserId)")
        
        // Step 1: Switch to user context to create invoice
        try await switchToUserWalletContext(userId: toUserId)
        let userInvoice = try await addInvoice(amount: amount, memo: memo)
        
        // Step 2: Switch to team wallet context to pay invoice
        try await switchToTeamWalletContext(teamId: fromTeamId, credentials: fromCredentials)
        let paymentResult = try await payInvoice(userInvoice.paymentRequest)
        
        print("CoinOSService: Transfer \(paymentResult.success ? "successful" : "failed")")
        return paymentResult
    }
    
    func getTeamWalletBalance(teamId: String, credentials: TeamWalletCredentials) async throws -> WalletBalance {
        print("CoinOSService: Getting team wallet balance for team \(teamId)")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Get balance
        let balance = try await getBalance()
        
        print("CoinOSService: Team wallet balance: \(balance.total) sats")
        return balance
    }
    
    func createTeamFundingInvoice(
        teamId: String,
        credentials: TeamWalletCredentials,
        amount: Int,
        memo: String
    ) async throws -> LightningInvoice {
        print("CoinOSService: Creating funding invoice for team \(teamId), amount: \(amount) sats")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Create funding invoice
        let invoice = try await addInvoice(amount: amount, memo: "Team funding: \(memo)")
        
        print("CoinOSService: Created funding invoice for team \(teamId)")
        return invoice
    }
    
    func getTeamWalletTransactions(
        teamId: String,
        credentials: TeamWalletCredentials,
        limit: Int = 50
    ) async throws -> [CoinOSTransaction] {
        print("CoinOSService: Getting team wallet transactions for team \(teamId)")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Get transactions
        let transactions = try await listTransactions(limit: limit)
        
        print("CoinOSService: Retrieved \(transactions.count) team wallet transactions")
        return transactions
    }
    
    // MARK: - Lightning Address Support
    
    func getLightningAddress(for userId: String) async throws -> String {
        // Get the CoinOS username for this user
        // First check if we have stored credentials for current user context
        if let storedUsername = KeychainService.shared.load(for: .coinOSUsername) {
            print("CoinOSService: Retrieved Lightning address for current user: \(storedUsername)@coinos.io")
            return "\(storedUsername)@coinos.io"
        }
        
        // If no stored credentials, we need to authenticate first
        throw CoinOSError.notAuthenticated
    }
    
    func getUserPaymentCoordinationInfo(for userId: String) async throws -> PaymentCoordinationInfo {
        print("CoinOSService: Getting payment coordination info for user \(userId)")
        
        // Ensure user context is active
        guard let username = KeychainService.shared.load(for: .coinOSUsername) else {
            throw CoinOSError.notAuthenticated
        }
        
        // Get current balance
        let balance = try await getBalance()
        
        // Get Lightning address
        let lightningAddress = "\(username)@coinos.io"
        
        let coordinationInfo = PaymentCoordinationInfo(
            userId: userId,
            lightningAddress: lightningAddress,
            currentBalance: balance.total,
            coinOSUsername: username,
            lastUpdated: Date()
        )
        
        print("CoinOSService: Payment coordination info retrieved - Address: \(lightningAddress), Balance: \(balance.total) sats")
        return coordinationInfo
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

private struct CoinOSPaymentData: Codable {
    let id: String
    let amount: Int
    let type: String?
    let memo: String?
    let confirmed: Bool?
    let created: Int64?
    let hash: String?
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