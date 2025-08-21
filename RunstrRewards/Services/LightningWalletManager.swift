import Foundation

class LightningWalletManager {
    static let shared = LightningWalletManager()
    
    private let coinOSService = CoinOSService.shared
    private let supabaseService = SupabaseService.shared
    private var retryCount = 0
    private let maxRetries = 3
    
    private init() {}
    
    // MARK: - New User Wallet Setup
    
    func setupWalletForNewUser(_ userId: String) async throws {
        print("LightningWalletManager: Setting up wallet for new user \(userId)")
        
        do {
            // Step 1: Create CoinOS wallet
            let wallet = try await coinOSService.createWalletForUser(userId)
            print("LightningWalletManager: Created CoinOS wallet \(wallet.id)")
            
            // Step 2: Store wallet info in Supabase
            try await storeUserWallet(wallet)
            print("LightningWalletManager: Stored wallet info in database")
            
            // Step 3: Setup initial reward (welcome bonus)
            try await distributeWelcomeBonus(userId: userId)
            print("LightningWalletManager: Distributed welcome bonus")
            
        } catch {
            print("LightningWalletManager: Failed to setup wallet for user \(userId): \(error)")
            throw LightningWalletError.walletSetupFailed
        }
    }
    
    func setupCoinOSAuthentication(username: String, password: String) async throws {
        do {
            _ = try await coinOSService.loginUser(username: username, password: password)
            print("LightningWalletManager: CoinOS authentication successful")
        } catch {
            print("LightningWalletManager: CoinOS authentication failed: \(error)")
            throw LightningWalletError.authenticationRequired
        }
    }
    
    func setupCoinOSToken(_ token: String) {
        coinOSService.setAuthToken(token)
        print("LightningWalletManager: CoinOS token configured")
    }
    
    // MARK: - Wallet Operations
    
    func getWalletBalance() async throws -> WalletBalance {
        // Ensure user has their own CoinOS wallet
        try await ensureUserWalletExists()
        
        // Retry logic for network failures
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let balance = try await coinOSService.getBalance()
                print("LightningWalletManager: Retrieved balance for current user - Lightning: \(balance.lightning) sats")
                retryCount = 0 // Reset retry count on success
                return balance
            } catch {
                lastError = error
                print("LightningWalletManager: Balance retrieval attempt \(attempt) failed: \(error)")
                
                if attempt < maxRetries {
                    // Exponential backoff
                    let delay = Double(attempt) * 1.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        print("LightningWalletManager: Failed to get balance after \(maxRetries) attempts")
        throw lastError ?? LightningWalletError.balanceRetrievalFailed
    }
    
    func createInvoice(amount: Int, memo: String) async throws -> LightningInvoice {
        // Ensure user has their own CoinOS wallet
        try await ensureUserWalletExists()
        
        do {
            let invoice = try await coinOSService.addInvoice(amount: amount, memo: memo)
            print("LightningWalletManager: Created invoice for \(amount) sats for current user")
            return invoice
        } catch {
            print("LightningWalletManager: Failed to create invoice: \(error)")
            throw LightningWalletError.invoiceCreationFailed
        }
    }
    
    func payInvoice(_ paymentRequest: String) async throws -> PaymentResult {
        do {
            let result = try await coinOSService.payInvoice(paymentRequest)
            print("LightningWalletManager: Payment result - Success: \(result.success)")
            return result
        } catch {
            print("LightningWalletManager: Failed to pay invoice: \(error)")
            throw LightningWalletError.paymentFailed
        }
    }
    
    // MARK: - Reward Distribution
    
    func distributeWorkoutReward(userId: String, workoutType: String, points: Int) async throws {
        let rewardAmount = calculateRewardAmount(points: points)
        let memo = "Workout reward: \(workoutType) - \(points) points"
        
        // Retry logic for failed payments
        var attempts = 0
        let maxAttempts = 3
        
        while attempts < maxAttempts {
            do {
                let result = try await coinOSService.distributeReward(
                    to: userId,
                    amount: rewardAmount,
                    memo: memo
                )
                
                if result.success {
                    // Store transaction record in Supabase
                    try await storeRewardTransaction(
                        userId: userId,
                        amount: rewardAmount,
                        type: "workout_reward",
                        description: memo
                    )
                    
                    print("LightningWalletManager: Distributed \(rewardAmount) sats reward to user \(userId)")
                    return // Success - exit retry loop
                } else {
                    throw LightningWalletError.rewardDistributionFailed
                }
            } catch {
                attempts += 1
                print("LightningWalletManager: Payment attempt \(attempts) failed: \(error)")
                
                if attempts < maxAttempts {
                    // Wait before retry (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(attempts * 2 * 1_000_000_000))
                } else {
                    // Final attempt failed - store for manual retry
                    await storeFailedPayment(userId: userId, amount: rewardAmount, type: workoutType, error: error)
                    throw error
                }
            }
        }
    }
    
    func distributeTeamReward(teamId: String, memberIds: [String], totalAmount: Int) async throws {
        let amountPerMember = totalAmount / memberIds.count
        let memo = "Team challenge reward"
        
        for memberId in memberIds {
            do {
                let _ = try await coinOSService.distributeReward(
                    to: memberId,
                    amount: amountPerMember,
                    memo: memo
                )
                
                try await storeRewardTransaction(
                    userId: memberId,
                    amount: amountPerMember,
                    type: "team_reward",
                    description: "Team \(teamId) challenge reward"
                )
                
                print("LightningWalletManager: Distributed \(amountPerMember) sats to team member \(memberId)")
            } catch {
                print("LightningWalletManager: Failed to distribute team reward to \(memberId): \(error)")
                // Continue with other members even if one fails
            }
        }
    }
    
    private func distributeWelcomeBonus(userId: String) async throws {
        let welcomeAmount = 1000 // 1000 sats welcome bonus
        let memo = "Welcome to RunstrRewards! 🎉"
        
        let result = try await coinOSService.distributeReward(
            to: userId,
            amount: welcomeAmount,
            memo: memo
        )
        
        if result.success {
            try await storeRewardTransaction(
                userId: userId,
                amount: welcomeAmount,
                type: "welcome_bonus",
                description: memo
            )
        }
    }
    
    // MARK: - Wallet Reset and Helper Methods
    
    func clearExistingWallet() {
        // Clear any existing temporary or invalid credentials
        KeychainService.shared.delete(for: .coinOSUsername)
        KeychainService.shared.delete(for: .coinOSPassword)
        KeychainService.shared.delete(for: .coinOSToken)
        coinOSService.clearAuthToken()
        print("LightningWalletManager: Cleared existing wallet credentials")
    }
    
    // MARK: - Helper Methods
    
    private func ensureUserWalletExists() async throws {
        guard let userSession = AuthenticationService.shared.loadSession() else {
            throw LightningWalletError.authenticationRequired
        }
        
        let userId = userSession.id
        
        // Check if user already has CoinOS credentials
        if let existingUsername = KeychainService.shared.load(for: .coinOSUsername),
           let existingPassword = KeychainService.shared.load(for: .coinOSPassword) {
            // Try to login with existing credentials
            do {
                let authResponse = try await coinOSService.loginUser(username: existingUsername, password: existingPassword)
                coinOSService.setAuthToken(authResponse.token)
                print("LightningWalletManager: Successfully authenticated with existing wallet for user \(userId)")
                return
            } catch {
                print("LightningWalletManager: Failed to login with existing credentials: \(error)")
                // Clear invalid credentials
                KeychainService.shared.delete(for: .coinOSUsername)
                KeychainService.shared.delete(for: .coinOSPassword)
                KeychainService.shared.delete(for: .coinOSToken)
            }
        }
        
        // Create new individual wallet for this user
        print("LightningWalletManager: Creating new individual wallet for user \(userId)")
        
        do {
            let wallet = try await coinOSService.createWalletForUser(userId)
            print("LightningWalletManager: Successfully created individual wallet for user \(userId)")
            
            // Store wallet info in Supabase if needed
            try await storeUserWallet(wallet)
            
        } catch {
            print("LightningWalletManager: Failed to create individual wallet for user \(userId): \(error)")
            throw LightningWalletError.walletSetupFailed
        }
    }
    
    
    private func calculateRewardAmount(points: Int) -> Int {
        // Convert points to satoshis
        // Example: 1 point = 10 sats, with bonuses for higher point values
        let baseSats = points * 10
        
        // Bonus multipliers
        if points >= 100 {
            return Int(Double(baseSats) * 1.5) // 50% bonus for high performance
        } else if points >= 50 {
            return Int(Double(baseSats) * 1.2) // 20% bonus for good performance
        }
        
        return baseSats
    }
    
    private func storeUserWallet(_ wallet: LightningWallet) async throws {
        // Store wallet information in Supabase
        print("LightningWalletManager: Storing wallet \(wallet.id) in database")
        
        do {
            try await SupabaseService.shared.storeUserWallet(wallet)
            print("LightningWalletManager: ✅ User wallet stored successfully")
        } catch {
            print("LightningWalletManager: ❌ Failed to store user wallet: \(error)")
            // Don't fail wallet creation for database issues - wallet is still functional
            ErrorHandlingService.shared.logError(error, context: "storeUserWallet", userId: wallet.userId)
        }
    }
    
    private func storeRewardTransaction(userId: String, amount: Int, type: String, description: String) async throws {
        print("LightningWalletManager: Storing reward transaction - \(amount) sats for user \(userId)")
        
        do {
            // Store transaction in Supabase database
            let transaction = try await SupabaseService.shared.createTransaction(
                userId: userId,
                type: type,
                amount: amount,
                description: description
            )
            
            print("LightningWalletManager: ✅ Transaction stored successfully with ID: \(transaction.id)")
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .transactionAdded,
                object: nil,
                userInfo: ["transaction": transaction]
            )
            
        } catch {
            print("LightningWalletManager: ❌ Failed to store transaction: \(error)")
            // Don't throw - we don't want to fail the reward distribution because of database issues
            // The Bitcoin was already sent, so log the error but continue
            ErrorHandlingService.shared.logError(error, context: "storeRewardTransaction", userId: userId)
        }
    }
    
    // MARK: - Failed Payment Handling
    
    private func storeFailedPayment(userId: String, amount: Int, type: String, error: Error) async {
        // Store failed payment for manual retry or user notification
        let failedPayment = [
            "userId": userId,
            "amount": amount,
            "type": type,
            "error": error.localizedDescription,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        // Store in UserDefaults for now (could be moved to Supabase)
        var failedPayments = UserDefaults.standard.array(forKey: "failed_payments") as? [[String: Any]] ?? []
        failedPayments.append(failedPayment)
        UserDefaults.standard.set(failedPayments, forKey: "failed_payments")
        
        print("LightningWalletManager: ⚠️ Stored failed payment: \(amount) sats for user \(userId)")
    }
    
    // MARK: - Wallet Status
    
    func isWalletSetup(for userId: String) async -> Bool {
        // Check if user has CoinOS credentials stored
        guard let username = KeychainService.shared.load(for: .coinOSUsername),
              let password = KeychainService.shared.load(for: .coinOSPassword) else {
            return false
        }
        
        // Try to authenticate with stored credentials
        do {
            try await setupCoinOSAuthentication(username: username, password: password)
            let _ = try await getWalletBalance()
            return true
        } catch {
            print("LightningWalletManager: Wallet setup check failed: \(error)")
            return false
        }
    }
    
    func getWalletStatus() async -> WalletStatus {
        // Check if we have stored credentials
        guard let username = KeychainService.shared.load(for: .coinOSUsername),
              let password = KeychainService.shared.load(for: .coinOSPassword) else {
            return .notConfigured
        }
        
        do {
            // Try to authenticate and get balance
            try await setupCoinOSAuthentication(username: username, password: password)
            _ = try await getWalletBalance()
            return .active
        } catch {
            return .error(error.localizedDescription)
        }
    }
}

// MARK: - Data Models

struct RewardTransaction: Codable {
    let id: String
    let userId: String
    let amount: Int
    let type: String
    let description: String
    let status: String
    let createdAt: Date
}

enum WalletStatus {
    case notConfigured
    case active
    case error(String)
    
    var displayText: String {
        switch self {
        case .notConfigured:
            return "Wallet not configured"
        case .active:
            return "Wallet active"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let transactionAdded = Notification.Name("transactionAdded")
}

// MARK: - Errors

enum LightningWalletError: LocalizedError {
    case walletSetupFailed
    case balanceRetrievalFailed
    case invoiceCreationFailed
    case paymentFailed
    case rewardDistributionFailed
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .walletSetupFailed:
            return "Failed to set up Lightning wallet"
        case .balanceRetrievalFailed:
            return "Failed to retrieve wallet balance"
        case .invoiceCreationFailed:
            return "Failed to create Lightning invoice"
        case .paymentFailed:
            return "Lightning payment failed"
        case .rewardDistributionFailed:
            return "Failed to distribute reward"
        case .authenticationRequired:
            return "Lightning wallet authentication required"
        }
    }
}