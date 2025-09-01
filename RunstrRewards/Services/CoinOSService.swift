import Foundation

class CoinOSService {
    static let shared = CoinOSService()
    
    private let baseURL = "https://coinos.io/api"
    private var authToken: String?
    private let session = URLSession.shared
    
    // MARK: - Exit Fee Constants
    static let RUNSTR_LIGHTNING_ADDRESS = "RUNSTR@coinos.io"
    static let EXIT_FEE_AMOUNT = 2000 // sats
    
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
    
    // MARK: - Service Availability
    
    func checkServiceAvailability() async throws {
        guard let url = URL(string: "\(baseURL)/ping") else {
            throw CoinOSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do {
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    throw CoinOSError.serviceUnavailable("CoinOS service returned status \(httpResponse.statusCode)")
                }
            }
            
            print("CoinOSService: Service availability check passed")
            
        } catch {
            print("CoinOSService: Service availability check failed - \(error)")
            throw CoinOSError.serviceUnavailable("CoinOS service is currently unavailable. Please try again later.")
        }
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
    
    // MARK: - Exit Fee Payment Operations
    
    func createExitFeeInvoice(amount: Int = EXIT_FEE_AMOUNT, memo: String = "RunstrRewards exit fee") async throws -> LightningInvoice {
        // Create invoice with RUNSTR wallet context - need to authenticate as RUNSTR first
        guard let runstrToken = await getRunstrAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        let requestBody = CoinOSInvoiceRequest(invoice: CoinOSInvoiceData(amount: amount, type: "lightning"))
        let jsonData = try JSONEncoder().encode(requestBody)
        
        var request = URLRequest(url: URL(string: "\(baseURL)/invoice")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(runstrToken)", forHTTPHeaderField: "Authorization")
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
            expiresAt: Date().addingTimeInterval(120) // 2 minutes expiry for exit fees
        )
    }
    
    func payExitFeeWithTimeout(paymentRequest: String, timeoutSeconds: Int = 120) async throws -> PaymentResult {
        return try await withTimeout(seconds: timeoutSeconds) {
            return try await self.payInvoice(paymentRequest)
        }
    }
    
    func processExitFeePayment(amount: Int = EXIT_FEE_AMOUNT, maxRetries: Int = 3) async throws -> ExitFeePaymentResult {
        var currentInvoice: LightningInvoice? = nil
        
        for attempt in 1...maxRetries {
            do {
                // Create fresh invoice for each attempt (handles expiry)
                print("CoinOSService: Creating exit fee invoice, attempt \(attempt)/\(maxRetries)")
                currentInvoice = try await createExitFeeInvoice(amount: amount)
                
                // Attempt payment with retry logic
                let paymentResult = try await payExitFeeWithRetry(
                    paymentRequest: currentInvoice!.paymentRequest,
                    maxRetries: 2, // Fewer retries per invoice since we'll create fresh ones
                    timeoutSeconds: 120
                )
                
                // Verify RUNSTR received the payment
                let verified = try await verifyRunstrReceivedPayment(
                    paymentHash: paymentResult.paymentHash,
                    maxAttempts: 5
                )
                
                if verified {
                    print("CoinOSService: Exit fee payment completed and verified")
                    return ExitFeePaymentResult(
                        success: true,
                        paymentHash: paymentResult.paymentHash,
                        amount: amount,
                        invoice: currentInvoice!,
                        verificationComplete: true,
                        timestamp: Date()
                    )
                } else {
                    print("CoinOSService: Payment sent but not verified by RUNSTR")
                    throw CoinOSError.paymentVerificationFailed
                }
                
            } catch CoinOSError.apiError(410), CoinOSError.invoiceExpired {
                // Invoice expired - will create fresh one on next attempt
                print("CoinOSService: Invoice expired, will create fresh invoice on retry")
                if attempt == maxRetries {
                    throw CoinOSError.invoiceExpired
                }
                continue
                
            } catch CoinOSError.apiError(402) {
                // Payment failed after retries - may be insufficient balance
                print("CoinOSService: Payment failed - likely insufficient balance")
                throw CoinOSError.insufficientBalance
                
            } catch CoinOSError.apiError(408) {
                // Timeout
                print("CoinOSService: Payment timed out")
                if attempt == maxRetries {
                    throw CoinOSError.paymentTimeout
                }
                continue
                
            } catch {
                print("CoinOSService: Unexpected error during exit fee payment: \(error)")
                if attempt == maxRetries {
                    throw error
                }
                // Wait before retrying
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        // Should not reach here, but provide fallback
        return ExitFeePaymentResult(
            success: false,
            paymentHash: "",
            amount: amount,
            invoice: currentInvoice,
            verificationComplete: false,
            timestamp: Date()
        )
    }
    
    func verifyRunstrReceivedPayment(paymentHash: String, maxAttempts: Int = 5) async throws -> Bool {
        guard let runstrToken = await getRunstrAuthToken() else {
            throw CoinOSError.notAuthenticated
        }
        
        for attempt in 1...maxAttempts {
            do {
                var request = URLRequest(url: URL(string: "\(baseURL)/invoice/\(paymentHash)")!)
                request.httpMethod = "GET"
                request.setValue("Bearer \(runstrToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw CoinOSError.invalidResponse
                }
                
                if httpResponse.statusCode == 200 {
                    let invoiceResponse = try JSONDecoder().decode(CoinOSInvoiceResponse.self, from: data)
                    // Check if payment was received (not just sent)
                    if (invoiceResponse.received ?? 0) >= CoinOSService.EXIT_FEE_AMOUNT {
                        print("CoinOSService: RUNSTR confirmed payment receipt: \(paymentHash)")
                        return true
                    }
                }
                
                // Wait before retrying (2 seconds between attempts)
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                }
                
            } catch {
                print("CoinOSService: Payment verification attempt \(attempt) failed: \(error)")
                if attempt == maxAttempts {
                    throw error
                }
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        return false
    }
    
    func payExitFeeWithRetry(paymentRequest: String, maxRetries: Int = 3, timeoutSeconds: Int = 120) async throws -> PaymentResult {
        for attempt in 1...maxRetries {
            do {
                print("CoinOSService: Exit fee payment attempt \(attempt)/\(maxRetries)")
                
                // Check if invoice is still valid (not expired)
                if isInvoiceExpired(paymentRequest) {
                    throw CoinOSError.apiError(410) // Gone - invoice expired
                }
                
                let result = try await withTimeout(seconds: timeoutSeconds) {
                    return try await self.payInvoice(paymentRequest)
                }
                
                // If payment succeeded, return immediately
                if result.success {
                    print("CoinOSService: Exit fee payment succeeded on attempt \(attempt)")
                    return result
                }
                
                // If payment failed and we have more retries, wait with exponential backoff
                if attempt < maxRetries {
                    let backoffSeconds = attempt * 2 // 2s, 4s, 6s
                    print("CoinOSService: Payment failed, retrying in \(backoffSeconds)s...")
                    try await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
                } else {
                    throw CoinOSError.apiError(402) // Payment failed after all retries
                }
                
            } catch CoinOSError.apiError(410) {
                // Invoice expired - cannot retry with same invoice
                throw CoinOSError.apiError(410)
            } catch {
                print("CoinOSService: Payment attempt \(attempt) failed: \(error)")
                
                if attempt == maxRetries {
                    throw error
                }
                
                // Exponential backoff for network/timeout errors
                let backoffSeconds = attempt * 2
                try await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
            }
        }
        
        throw CoinOSError.apiError(402) // Should never reach here
    }
    
    private func isInvoiceExpired(_ paymentRequest: String) -> Bool {
        // Basic Lightning invoice parsing to check expiry
        // In production, use proper BOLT11 parsing
        return false // Simplified for now - TODO: implement proper BOLT11 parsing
    }
    
    private func withTimeout<T>(seconds: Int, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                return try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CoinOSError.apiError(408) // Request timeout
            }
            
            // Return the first result (either success or timeout)
            guard let result = try await group.next() else {
                throw CoinOSError.networkError
            }
            
            // Cancel the remaining task
            group.cancelAll()
            return result
        }
    }
    
    private func getRunstrAuthToken() async -> String? {
        // For now, use a hardcoded approach - in production this would be proper service-to-service auth
        // This method would authenticate as RUNSTR@coinos.io to create invoices and check payments
        // TODO: Implement proper RUNSTR service account authentication
        print("CoinOSService: Warning - RUNSTR authentication not yet implemented")
        return loadAuthToken() // Temporary fallback to user token
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
    
    // MARK: - Exit Fee Manager Integration
    
    func createRunstrInvoice(amount: Int, memo: String) async throws -> LightningInvoice {
        return try await createExitFeeInvoice(amount: amount, memo: memo)
    }
    
    func payExitFeeToRunstr(amount: Int, memo: String) async throws -> PaymentResult {
        print("CoinOSService: Processing exit fee payment of \(amount) sats to RUNSTR@coinos.io")
        
        // Create invoice first
        let invoice = try await createRunstrInvoice(amount: amount, memo: memo)
        
        // Pay the invoice
        let paymentResult = try await payInvoice(invoice.paymentRequest)
        
        print("CoinOSService: Exit fee payment \(paymentResult.success ? "successful" : "failed"): \(paymentResult.paymentHash)")
        return paymentResult
    }
    
    func verifyRunstrPayment(paymentHash: String) async throws -> Bool {
        return try await verifyRunstrReceivedPayment(paymentHash: paymentHash, maxAttempts: 5)
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

struct ExitFeePaymentResult: Codable {
    let success: Bool
    let paymentHash: String
    let amount: Int
    let invoice: LightningInvoice?
    let verificationComplete: Bool
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
    case invalidURL
    case apiError(Int)
    case networkError
    case decodingError
    case walletCreationFailed
    case serviceUnavailable(String)
    case paymentTimeout
    case invoiceExpired
    case paymentVerificationFailed
    case insufficientBalance
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "CoinOS authentication required"
        case .invalidResponse:
            return "Invalid response from CoinOS API"
        case .invalidURL:
            return "Invalid CoinOS API URL"
        case .apiError(let code):
            return "CoinOS API error: HTTP \(code)"
        case .serviceUnavailable(let message):
            return message
        case .networkError:
            return "Network error connecting to CoinOS"
        case .decodingError:
            return "Failed to decode CoinOS response"
        case .walletCreationFailed:
            return "Failed to create CoinOS wallet"
        case .paymentTimeout:
            return "Payment timed out - please try again"
        case .invoiceExpired:
            return "Invoice expired - a new payment request will be generated"
        case .paymentVerificationFailed:
            return "Payment verification failed - please contact support"
        case .insufficientBalance:
            return "Insufficient balance - please add funds to your wallet"
        }
    }
}