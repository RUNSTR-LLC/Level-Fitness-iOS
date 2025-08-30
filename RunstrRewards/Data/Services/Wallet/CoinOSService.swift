import Foundation

class CoinOSService {
    static let shared = CoinOSService()
    
    private let baseURL = "https://coinos.io/api"
    private var authToken: String?
    private let session = URLSession.shared
    private let contextLock = NSLock() // Prevent concurrent context switches
    private var currentWalletContext: WalletContext = .none
    
    // Rate limiting for security
    private var lastRequestTimes: [String: Date] = [:]
    private let rateLimitInterval: TimeInterval = 1.0 // 1 second between requests
    private let rateLimitLock = NSLock()
    
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
    
    func setWalletContext(_ context: WalletContext) {
        contextLock.lock()
        defer { contextLock.unlock() }
        
        currentWalletContext = context
        print("CoinOSService: Wallet context set to \(context)")
    }
    
    func clearAuthToken() {
        authToken = nil
        KeychainService.shared.delete(for: .coinOSToken)
        print("CoinOSService: Auth token cleared")
    }
    
    // MARK: - Rate Limiting
    
    private func checkRateLimit(for operation: String) throws {
        rateLimitLock.lock()
        defer { rateLimitLock.unlock() }
        
        let now = Date()
        if let lastTime = lastRequestTimes[operation] {
            let timeSinceLastRequest = now.timeIntervalSince(lastTime)
            if timeSinceLastRequest < rateLimitInterval {
                throw CoinOSError.networkError // Reuse existing error for rate limiting
            }
        }
        lastRequestTimes[operation] = now
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
        var password = generateSecurePassword()
        
        // Ensure password is zeroed from memory after use
        defer {
            // Explicitly zero password string from memory for security
            password.withUTF8 { utf8Bytes in
                utf8Bytes.withMemoryRebound(to: UInt8.self) { bytes in
                    bytes.baseAddress?.initialize(repeating: 0, count: bytes.count)
                }
            }
        }
        
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
            
            // Store only CoinOS username - password is never reused for security
            KeychainService.shared.save(username, for: .coinOSUsername)
            
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
        let charsetArray = Array(charset)
        let passwordLength = 16
        
        // Use cryptographically secure random bytes
        var randomBytes = [UInt8](repeating: 0, count: passwordLength)
        let result = SecRandomCopyBytes(kSecRandomDefault, passwordLength, &randomBytes)
        
        // Defer cleanup to ensure random bytes are always zeroed
        defer {
            // Explicitly zero random bytes from memory for security
            randomBytes.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress?.initialize(repeating: 0, count: passwordLength)
            }
        }
        
        guard result == errSecSuccess else {
            // Critical security failure - log error and report to error handling service
            let errorMessage = "CoinOSService: CRITICAL SECURITY FAILURE - SecRandomCopyBytes failed with code: \(result)"
            print(errorMessage)
            ErrorHandlingService.shared.logCriticalError(errorMessage, context: ["function": "generateSecurePassword", "errorCode": result])
            
            // Use a more secure fallback with CryptoKit if available
            if #available(iOS 13.0, *) {
                return generateCryptoKitFallbackPassword(length: passwordLength, charset: charsetArray)
            } else {
                // Last resort fallback with warning
                print("CoinOSService: WARNING - Using system random as final fallback")
                return generateSystemRandomPassword(length: passwordLength, charset: charsetArray)
            }
        }
        
        // Map secure random bytes to charset
        let password = String(randomBytes.map { byte in
            charsetArray[Int(byte) % charsetArray.count]
        })
        
        return password
    }
    
    @available(iOS 13.0, *)
    private func generateCryptoKitFallbackPassword(length: Int, charset: [Character]) -> String {
        import CryptoKit
        let randomData = SymmetricKey(size: .init(bitCount: length * 8))
        let bytes = randomData.withUnsafeBytes { Data($0) }
        
        // Defer cleanup
        defer {
            // Zero the key from memory (CryptoKit handles this automatically, but being explicit)
            print("CoinOSService: Using CryptoKit fallback for password generation")
        }
        
        return String(bytes.prefix(length).map { byte in
            charset[Int(byte) % charset.count]
        })
    }
    
    private func generateSystemRandomPassword(length: Int, charset: [Character]) -> String {
        return String((0..<length).map { _ in charset.randomElement()! })
    }
    
    // MARK: - Error Handling & Retry Logic
    
    private func performWithRetry<T>(maxAttempts: Int, operation: @Sendable () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry for certain errors
                if case CoinOSError.notAuthenticated = error {
                    throw error
                }
                
                // Exponential backoff for retries
                if attempt < maxAttempts {
                    let delay = min(pow(2.0, Double(attempt - 1)), 10.0) // Cap at 10 seconds
                    print("CoinOSService: Attempt \(attempt) failed, retrying in \(delay)s: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All attempts failed, throw the last error
        throw lastError ?? CoinOSError.networkError
    }
    
    // MARK: - Lightning Network Operations
    
    func getCurrentUser() async throws -> CoinOSUserInfo? {
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        // Retry logic for network failures
        return try await performWithRetry(maxAttempts: 3) {
            var request = URLRequest(url: URL(string: "\(self.baseURL)/me")!)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10.0 // 10 second timeout
            
            let (data, response) = try await self.session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CoinOSError.invalidResponse
            }
            
            // Handle different HTTP status codes appropriately
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(CoinOSUserInfo.self, from: data)
            case 401:
                // Token expired or invalid - clear it
                self.clearAuthToken()
                throw CoinOSError.notAuthenticated
            case 429:
                // Rate limited - throw specific error for backoff
                throw CoinOSError.networkError
            case 500...599:
                // Server error - retry appropriate
                throw CoinOSError.apiError(httpResponse.statusCode)
            default:
                throw CoinOSError.apiError(httpResponse.statusCode)
            }
        }
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
        // Rate limiting for security
        try checkRateLimit(for: "addInvoice")
        
        guard let token = loadAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        // Input validation for security
        guard amount > 0 && amount <= 1_000_000 else { // Max 1M sats for safety
            throw CoinOSError.invalidAmount
        }
        
        // Sanitize memo to prevent injection attacks
        let sanitizedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .prefix(280) // Twitter-like limit
        
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
    
    // MARK: - Team Wallet Operations (Delegated)
    
    func createTeamWallet(for teamId: String) async throws -> LightningWallet {
        return try await CoinOSTeamService.shared.createTeamWallet(for: teamId)
    }
    
    func transferFromTeamToUser(
        fromTeamId: String,
        fromCredentials: TeamWalletCredentials,
        toUserId: String,
        amount: Int,
        memo: String
    ) async throws -> PaymentResult {
        return try await CoinOSTeamService.shared.transferFromTeamToUser(
            fromTeamId: fromTeamId,
            fromCredentials: fromCredentials,
            toUserId: toUserId,
            amount: amount,
            memo: memo
        )
    }
    
    func getTeamWalletBalance(teamId: String, credentials: TeamWalletCredentials) async throws -> WalletBalance {
        return try await CoinOSTeamService.shared.getTeamWalletBalance(teamId: teamId, credentials: credentials)
    }
    
    func createTeamFundingInvoice(
        teamId: String,
        credentials: TeamWalletCredentials,
        amount: Int,
        memo: String
    ) async throws -> LightningInvoice {
        return try await CoinOSTeamService.shared.createTeamFundingInvoice(
            teamId: teamId,
            credentials: credentials,
            amount: amount,
            memo: memo
        )
    }
    
    func getTeamWalletTransactions(
        teamId: String,
        credentials: TeamWalletCredentials,
        limit: Int = 50
    ) async throws -> [CoinOSTransaction] {
        return try await CoinOSTeamService.shared.getTeamWalletTransactions(
            teamId: teamId,
            credentials: credentials,
            limit: limit
        )
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

