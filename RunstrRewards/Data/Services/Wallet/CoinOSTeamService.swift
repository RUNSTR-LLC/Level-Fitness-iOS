import Foundation

class CoinOSTeamService {
    static let shared = CoinOSTeamService()
    
    private init() {}
    
    // MARK: - Team Wallet Operations
    
    func createTeamWallet(for teamId: String) async throws -> LightningWallet {
        // Generate unique CoinOS credentials for team wallet
        let timestamp = String(Int(Date().timeIntervalSince1970)).suffix(8)
        let randomSuffix = Int.random(in: 1000...9999)
        let cleanTeamId = teamId.replacingOccurrences(of: "-", with: "").prefix(6)
        let username = "team\(cleanTeamId)\(timestamp)\(randomSuffix)"
        let password = generateSecurePassword()
        
        print("CoinOSTeamService: Creating team wallet for team \(teamId) with username \(username)")
        
        do {
            // Register new team wallet with CoinOS
            let authResponse = try await CoinOSService.shared.registerUser(username: username, password: password)
            
            // Get wallet details
            let userInfo = try await CoinOSService.shared.getCurrentUser()
            
            let wallet = LightningWallet(
                id: authResponse.userId ?? UUID().uuidString,
                userId: teamId, // Using teamId as the identifier
                provider: "coinos",
                balance: userInfo?.balance ?? 0,
                address: username,
                createdAt: Date()
            )
            
            print("CoinOSTeamService: Successfully created team wallet for team \(teamId)")
            return wallet
            
        } catch {
            print("CoinOSTeamService: Failed to create team wallet for team \(teamId): \(error)")
            throw CoinOSError.walletCreationFailed
        }
    }
    
    func authenticateWithTeamWallet(username: String, password: String) async throws {
        print("CoinOSTeamService: Authenticating with team wallet \(username)")
        
        do {
            let authResponse = try await CoinOSService.shared.loginUser(username: username, password: password)
            CoinOSService.shared.setAuthToken(authResponse.token)
            print("CoinOSTeamService: Successfully authenticated with team wallet")
        } catch {
            print("CoinOSTeamService: Failed to authenticate with team wallet: \(error)")
            throw error
        }
    }
    
    func switchToTeamWalletContext(teamId: String, credentials: TeamWalletCredentials) async throws {
        print("CoinOSTeamService: Switching to team wallet context for team \(teamId)")
        
        try await authenticateWithTeamWallet(username: credentials.username, password: credentials.password)
        CoinOSService.shared.setWalletContext(.team(teamId))
    }
    
    func switchToUserWalletContext(userId: String) async throws {
        print("CoinOSTeamService: Switching back to user wallet context for user \(userId)")
        
        // Clear current team wallet token
        CoinOSService.shared.clearAuthToken()
        
        // Load user's wallet credentials
        if let username = KeychainService.shared.load(for: .coinOSUsername),
           let password = KeychainService.shared.load(for: .coinOSPassword) {
            try await authenticateWithTeamWallet(username: username, password: password)
            CoinOSService.shared.setWalletContext(.user(userId))
        } else {
            CoinOSService.shared.setWalletContext(.none)
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
        print("CoinOSTeamService: Transferring \(amount) sats from team \(fromTeamId) to user \(toUserId)")
        
        // Validate transfer amount
        guard amount > 0 else {
            throw CoinOSError.invalidAmount
        }
        
        var userInvoice: LightningInvoice
        var paymentResult: PaymentResult
        
        do {
            // Step 1: Switch to user context to create invoice
            try await switchToUserWalletContext(userId: toUserId)
            userInvoice = try await CoinOSService.shared.addInvoice(amount: amount, memo: memo)
            
            // Step 2: Switch to team wallet context to pay invoice
            try await switchToTeamWalletContext(teamId: fromTeamId, credentials: fromCredentials)
            
            // Verify team wallet has sufficient balance
            let teamBalance = try await CoinOSService.shared.getBalance()
            guard teamBalance.total >= amount else {
                throw CoinOSError.insufficientBalance
            }
            
            // Execute payment
            paymentResult = try await CoinOSService.shared.payInvoice(userInvoice.paymentRequest)
            
        } catch {
            print("CoinOSTeamService: Transfer failed during execution: \(error)")
            // Attempt to restore user context on error
            try? await switchToUserWalletContext(userId: toUserId)
            throw error
        }
        
        print("CoinOSTeamService: Transfer \(paymentResult.success ? "successful" : "failed")")
        return paymentResult
    }
    
    func getTeamWalletBalance(teamId: String, credentials: TeamWalletCredentials) async throws -> WalletBalance {
        print("CoinOSTeamService: Getting team wallet balance for team \(teamId)")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Get balance
        let balance = try await CoinOSService.shared.getBalance()
        
        print("CoinOSTeamService: Team wallet balance: \(balance.total) sats")
        return balance
    }
    
    func createTeamFundingInvoice(
        teamId: String,
        credentials: TeamWalletCredentials,
        amount: Int,
        memo: String
    ) async throws -> LightningInvoice {
        print("CoinOSTeamService: Creating funding invoice for team \(teamId), amount: \(amount) sats")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Create funding invoice
        let invoice = try await CoinOSService.shared.addInvoice(amount: amount, memo: "Team funding: \(memo)")
        
        print("CoinOSTeamService: Created funding invoice for team \(teamId)")
        return invoice
    }
    
    func getTeamWalletTransactions(
        teamId: String,
        credentials: TeamWalletCredentials,
        limit: Int = 50
    ) async throws -> [CoinOSTransaction] {
        print("CoinOSTeamService: Getting team wallet transactions for team \(teamId)")
        
        // Switch to team wallet context
        try await switchToTeamWalletContext(teamId: teamId, credentials: credentials)
        
        // Get transactions
        let transactions = try await CoinOSService.shared.listTransactions(limit: limit)
        
        print("CoinOSTeamService: Retrieved \(transactions.count) team wallet transactions")
        return transactions
    }
    
    // MARK: - Helper Methods
    
    private func generateSecurePassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<24).map { _ in characters.randomElement()! })
    }
}