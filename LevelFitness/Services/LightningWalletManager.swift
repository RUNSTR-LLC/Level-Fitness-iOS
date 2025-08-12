import Foundation

class LightningWalletManager {
    static let shared = LightningWalletManager()
    
    private let coinOSService = CoinOSService.shared
    private let supabaseService = SupabaseService.shared
    
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
        do {
            let balance = try await coinOSService.getBalance()
            print("LightningWalletManager: Retrieved balance - Lightning: \(balance.lightning) sats")
            return balance
        } catch {
            print("LightningWalletManager: Failed to get balance: \(error)")
            throw LightningWalletError.balanceRetrievalFailed
        }
    }
    
    func createInvoice(amount: Int, memo: String) async throws -> LightningInvoice {
        do {
            let invoice = try await coinOSService.addInvoice(amount: amount, memo: memo)
            print("LightningWalletManager: Created invoice for \(amount) sats")
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
            } else {
                throw LightningWalletError.rewardDistributionFailed
            }
        } catch {
            print("LightningWalletManager: Failed to distribute reward: \(error)")
            throw error
        }
    }
    
    func distributeTeamReward(teamId: String, memberIds: [String], totalAmount: Int) async throws {
        let amountPerMember = totalAmount / memberIds.count
        let memo = "Team challenge reward"
        
        for memberId in memberIds {
            do {
                try await coinOSService.distributeReward(
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
        let memo = "Welcome to Level Fitness! 🎉"
        
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
    
    // MARK: - Helper Methods
    
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
        // This would involve creating a wallets table and inserting the wallet data
        print("LightningWalletManager: Storing wallet \(wallet.id) in database")
        
        // TODO: Implement actual Supabase storage
        // For now, we'll just log the action
    }
    
    private func storeRewardTransaction(userId: String, amount: Int, type: String, description: String) async throws {
        let transaction = RewardTransaction(
            id: UUID().uuidString,
            userId: userId,
            amount: amount,
            type: type,
            description: description,
            status: "completed",
            createdAt: Date()
        )
        
        print("LightningWalletManager: Storing reward transaction - \(amount) sats for user \(userId)")
        
        // TODO: Store in Supabase transactions table
        // For now, we'll just log the transaction
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