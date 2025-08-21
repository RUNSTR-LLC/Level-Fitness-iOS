import Foundation

class TeamWalletManager {
    static let shared = TeamWalletManager()
    
    private let coinOSService = CoinOSService.shared
    private let lightningWalletManager = LightningWalletManager.shared
    private let supabaseService = SupabaseService.shared
    private let accessController = TeamWalletAccessController.shared
    
    private init() {}
    
    // MARK: - Team Wallet Creation
    
    func createTeamWallet(for teamId: String, captainId: String) async throws -> TeamWallet {
        print("TeamWalletManager: Creating team wallet for team \(teamId)")
        
        do {
            // Generate unique CoinOS credentials for team wallet
            let timestamp = String(Int(Date().timeIntervalSince1970)).suffix(8)
            let randomSuffix = Int.random(in: 1000...9999)
            let cleanTeamId = teamId.replacingOccurrences(of: "-", with: "").prefix(6)
            let username = "team\(cleanTeamId)\(timestamp)\(randomSuffix)"
            let password = generateSecurePassword()
            
            print("TeamWalletManager: Creating CoinOS account for team wallet with username: \(username)")
            
            // Register team wallet with CoinOS
            let authResponse = try await coinOSService.registerUser(username: username, password: password)
            
            // Get wallet info
            let userInfo = try await coinOSService.getCurrentUser()
            
            // Create team wallet object
            let teamWallet = TeamWallet(
                id: authResponse.userId ?? UUID().uuidString,
                teamId: teamId,
                captainId: captainId,
                provider: "coinos",
                balance: userInfo?.balance ?? 0,
                address: username,
                walletId: authResponse.userId ?? "",
                createdAt: Date()
            )
            
            // Store team wallet credentials securely
            try storeTeamWalletCredentials(teamId: teamId, username: username, password: password, token: authResponse.token)
            
            // Store team wallet info in database
            try await storeTeamWallet(teamWallet)
            
            // Update team with wallet reference
            try await updateTeamWithWallet(teamId: teamId, walletId: teamWallet.id)
            
            print("TeamWalletManager: Successfully created team wallet for team \(teamId)")
            return teamWallet
            
        } catch {
            print("TeamWalletManager: Failed to create team wallet for team \(teamId): \(error)")
            throw TeamWalletError.teamWalletCreationFailed
        }
    }
    
    // MARK: - Team Wallet Access Control
    
    func verifyTeamCaptainAccess(teamId: String, userId: String) async throws -> Bool {
        // Verify that the user is the captain of the specified team
        guard let userSession = AuthenticationService.shared.loadSession() else {
            throw TeamWalletError.authenticationRequired
        }
        
        if userSession.id != userId {
            throw TeamWalletError.notAuthorized
        }
        
        // Check if user is captain of the team via Supabase
        do {
            let team = try await supabaseService.getTeam(teamId)
            guard let team = team, team.captainId == userId else {
                print("TeamWalletManager: User \(userId) is not captain of team \(teamId)")
                return false
            }
            
            print("TeamWalletManager: Verified captain access for user \(userId) on team \(teamId)")
            return true
            
        } catch {
            print("TeamWalletManager: Error verifying captain access: \(error)")
            throw TeamWalletError.notAuthorized
        }
    }
    
    func canAccessTeamWallet(teamId: String, userId: String, accessType: TeamWalletAccessType) async throws -> Bool {
        switch accessType {
        case .view:
            // All team members can view team wallet balance
            return try await isTeamMember(teamId: teamId, userId: userId)
        case .manage:
            // Only team captain can manage team wallet
            return try await verifyTeamCaptainAccess(teamId: teamId, userId: userId)
        }
    }
    
    // MARK: - Team Wallet Operations
    
    func getTeamWalletBalance(teamId: String, userId: String? = nil) async throws -> WalletBalance {
        print("TeamWalletManager: Getting team wallet balance for team \(teamId)")
        
        // Verify access permission
        guard let userId = userId else {
            throw TeamWalletError.authenticationRequired
        }
        try await accessController.validateTeamWalletAccess(
            teamId: teamId,
            userId: userId,
            accessType: .view
        )
        
        // Load team wallet credentials
        guard let credentials = loadTeamWalletCredentials(teamId: teamId) else {
            throw TeamWalletError.teamWalletNotFound
        }
        
        // Authenticate with team wallet
        let authResponse = try await coinOSService.loginUser(username: credentials.username, password: credentials.password)
        coinOSService.setAuthToken(authResponse.token)
        
        // Get balance
        let balance = try await coinOSService.getBalance()
        
        print("TeamWalletManager: Team wallet balance for team \(teamId): \(balance.total) sats")
        return balance
    }
    
    func fundTeamWallet(teamId: String, amount: Int, memo: String, userId: String? = nil) async throws -> LightningInvoice {
        print("TeamWalletManager: Creating funding invoice for team \(teamId), amount: \(amount) sats")
        
        // Verify operation permission
        guard let userId = userId else {
            throw TeamWalletError.authenticationRequired
        }
        try await accessController.validateTeamWalletOperation(
            teamId: teamId,
            userId: userId,
            operation: .fundWallet
        )
        
        // Load team wallet credentials
        guard let credentials = loadTeamWalletCredentials(teamId: teamId) else {
            throw TeamWalletError.teamWalletNotFound
        }
        
        // Authenticate with team wallet
        let authResponse = try await coinOSService.loginUser(username: credentials.username, password: credentials.password)
        coinOSService.setAuthToken(authResponse.token)
        
        // Create invoice for funding
        let invoice = try await coinOSService.addInvoice(amount: amount, memo: "Team funding: \(memo)")
        
        // Record funding transaction
        try await recordTeamTransaction(
            teamId: teamId,
            amount: amount,
            type: "team_funding",
            description: "Team wallet funding: \(memo)",
            invoice: invoice
        )
        
        print("TeamWalletManager: Created funding invoice for team \(teamId)")
        return invoice
    }
    
    // MARK: - Reward Distribution
    
    func distributeTeamReward(
        teamId: String,
        recipients: [String], // User IDs
        totalAmount: Int,
        memo: String,
        distributionType: RewardDistributionType = .equal,
        userId: String? = nil
    ) async throws {
        print("TeamWalletManager: Distributing \(totalAmount) sats to \(recipients.count) team members")
        
        // Verify distribution permission
        guard let userId = userId else {
            throw TeamWalletError.authenticationRequired
        }
        try await accessController.validateTeamWalletOperation(
            teamId: teamId,
            userId: userId,
            operation: .distributeReward
        )
        
        // Verify team has sufficient balance
        let balance = try await getTeamWalletBalance(teamId: teamId, userId: userId)
        guard balance.total >= totalAmount else {
            throw TeamWalletError.insufficientBalance
        }
        
        // Calculate individual amounts
        let amounts = calculateRewardDistribution(totalAmount: totalAmount, recipients: recipients, type: distributionType)
        
        // Load team wallet credentials
        guard let credentials = loadTeamWalletCredentials(teamId: teamId) else {
            throw TeamWalletError.teamWalletNotFound
        }
        
        // Authenticate with team wallet
        let authResponse = try await coinOSService.loginUser(username: credentials.username, password: credentials.password)
        coinOSService.setAuthToken(authResponse.token)
        
        // Distribute rewards to each recipient
        for (index, userId) in recipients.enumerated() {
            let amount = amounts[index]
            
            do {
                // Create invoice for user's individual wallet
                let userInvoice = try await createUserInvoice(userId: userId, amount: amount, memo: "Team reward: \(memo)")
                
                // Pay invoice from team wallet
                let paymentResult = try await coinOSService.payInvoice(userInvoice.paymentRequest)
                
                if paymentResult.success {
                    // Record successful reward transaction
                    try await recordTeamTransaction(
                        teamId: teamId,
                        userId: userId,
                        amount: -amount, // Negative for outgoing
                        type: "team_reward",
                        description: "Team reward to \(userId): \(memo)"
                    )
                    
                    print("TeamWalletManager: Distributed \(amount) sats to user \(userId)")
                } else {
                    print("TeamWalletManager: Failed to distribute reward to user \(userId)")
                    throw TeamWalletError.rewardDistributionFailed
                }
                
            } catch {
                print("TeamWalletManager: Error distributing reward to user \(userId): \(error)")
                // Continue with other recipients even if one fails
            }
        }
        
        print("TeamWalletManager: Completed reward distribution for team \(teamId)")
    }
    
    func distributeCompetitionPrize(
        teamId: String,
        competitionId: String,
        winners: [(userId: String, position: Int, amount: Int)],
        memo: String,
        requestingUserId: String
    ) async throws {
        print("TeamWalletManager: Distributing competition prizes for team \(teamId), competition \(competitionId)")
        
        let totalAmount = winners.reduce(0) { $0 + $1.amount }
        
        // Verify team has sufficient balance
        let balance = try await getTeamWalletBalance(teamId: teamId, userId: requestingUserId)
        guard balance.total >= totalAmount else {
            throw TeamWalletError.insufficientBalance
        }
        
        // Load team wallet credentials
        guard let credentials = loadTeamWalletCredentials(teamId: teamId) else {
            throw TeamWalletError.teamWalletNotFound
        }
        
        // Authenticate with team wallet
        let authResponse = try await coinOSService.loginUser(username: credentials.username, password: credentials.password)
        coinOSService.setAuthToken(authResponse.token)
        
        // Distribute prizes to each winner
        for winner in winners {
            do {
                // Create invoice for user's individual wallet
                let userInvoice = try await createUserInvoice(
                    userId: winner.userId,
                    amount: winner.amount,
                    memo: "Competition prize - Position \(winner.position): \(memo)"
                )
                
                // Pay invoice from team wallet
                let paymentResult = try await coinOSService.payInvoice(userInvoice.paymentRequest)
                
                if paymentResult.success {
                    // Record successful prize transaction
                    try await recordTeamTransaction(
                        teamId: teamId,
                        userId: winner.userId,
                        amount: -winner.amount, // Negative for outgoing
                        type: "competition_prize",
                        description: "Competition prize - Position \(winner.position): \(memo)",
                        metadata: ["competition_id": competitionId, "position": winner.position]
                    )
                    
                    print("TeamWalletManager: Distributed \(winner.amount) sats prize to user \(winner.userId) for position \(winner.position)")
                } else {
                    print("TeamWalletManager: Failed to distribute prize to user \(winner.userId)")
                    throw TeamWalletError.rewardDistributionFailed
                }
                
            } catch {
                print("TeamWalletManager: Error distributing prize to user \(winner.userId): \(error)")
                // Continue with other winners even if one fails
            }
        }
        
        print("TeamWalletManager: Completed competition prize distribution for team \(teamId)")
    }
    
    // MARK: - Helper Methods
    
    private func generateSecurePassword() -> String {
        let charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<16).map { _ in charset.randomElement()! })
    }
    
    private func calculateRewardDistribution(
        totalAmount: Int,
        recipients: [String],
        type: RewardDistributionType
    ) -> [Int] {
        switch type {
        case .equal:
            let amountPerRecipient = totalAmount / recipients.count
            return Array(repeating: amountPerRecipient, count: recipients.count)
        case .weighted(let weights):
            let totalWeight = weights.reduce(0, +)
            return weights.map { weight in
                Int(Double(totalAmount) * (Double(weight) / Double(totalWeight)))
            }
        }
    }
    
    private func createUserInvoice(userId: String, amount: Int, memo: String) async throws -> LightningInvoice {
        // Switch to user's individual wallet context to create invoice
        // This requires temporarily switching CoinOS authentication
        
        // TODO: Implement user wallet invoice creation
        // For now, return a placeholder invoice
        return LightningInvoice(
            id: UUID().uuidString,
            paymentRequest: "placeholder_invoice_\(userId)",
            amount: amount,
            memo: memo,
            status: "pending",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600)
        )
    }
    
    private func isTeamMember(teamId: String, userId: String) async throws -> Bool {
        // Check if user is a member of the team via Supabase
        do {
            let isMember = try await supabaseService.isUserMemberOfTeam(userId: userId, teamId: teamId)
            print("TeamWalletManager: User \(userId) membership status for team \(teamId): \(isMember)")
            return isMember
            
        } catch {
            print("TeamWalletManager: Error checking team membership: \(error)")
            throw TeamWalletError.notAuthorized
        }
    }
    
    private func storeTeamWalletCredentials(teamId: String, username: String, password: String, token: String) throws {
        // For MVP: Store team wallet credentials using existing CoinOS keys
        // TODO: Implement team-specific credential storage
        print("TeamWalletManager: Storing team wallet credentials for team \(teamId)")
        
        let _ = KeychainService.shared.save(username, for: .coinOSUsername)
        let _ = KeychainService.shared.save(password, for: .coinOSPassword) 
        let _ = KeychainService.shared.save(token, for: .coinOSToken)
        
        print("TeamWalletManager: Team wallet credentials stored successfully")
    }
    
    private func loadTeamWalletCredentials(teamId: String) -> TeamWalletCredentials? {
        // For MVP: Load team wallet credentials from existing CoinOS keys
        // TODO: Implement team-specific credential loading
        guard let username = KeychainService.shared.load(for: .coinOSUsername),
              let password = KeychainService.shared.load(for: .coinOSPassword),
              let token = KeychainService.shared.load(for: .coinOSToken) else {
            print("TeamWalletManager: Could not load team wallet credentials for team \(teamId)")
            return nil
        }
        
        return TeamWalletCredentials(username: username, password: password, token: token)
    }
    
    private func storeTeamWallet(_ teamWallet: TeamWallet) async throws {
        print("TeamWalletManager: Storing team wallet \(teamWallet.id) in database")
        
        do {
            try await supabaseService.storeTeamWallet(teamWallet)
            print("TeamWalletManager: ✅ Team wallet stored successfully")
        } catch {
            print("TeamWalletManager: ❌ Failed to store team wallet: \(error)")
            // Don't fail wallet creation for database issues - wallet is still functional
            throw error
        }
    }
    
    private func updateTeamWithWallet(teamId: String, walletId: String) async throws {
        print("TeamWalletManager: Updating team \(teamId) with wallet ID \(walletId)")
        
        do {
            try await supabaseService.updateTeamWalletId(teamId: teamId, walletId: walletId)
            print("TeamWalletManager: ✅ Team updated with wallet ID successfully")
        } catch {
            print("TeamWalletManager: ❌ Failed to update team with wallet ID: \(error)")
            throw error
        }
    }
    
    private func recordTeamTransaction(
        teamId: String,
        userId: String? = nil,
        amount: Int,
        type: String,
        description: String,
        invoice: LightningInvoice? = nil,
        metadata: [String: Any] = [:]
    ) async throws {
        print("TeamWalletManager: Recording team transaction - \(amount) sats for team \(teamId)")
        
        do {
            try await supabaseService.recordTeamTransaction(
                teamId: teamId,
                userId: userId,
                amount: amount,
                type: type,
                description: description
            )
            print("TeamWalletManager: ✅ Team transaction recorded successfully")
        } catch {
            print("TeamWalletManager: ❌ Failed to record team transaction: \(error)")
            // Don't fail the operation for database issues - transaction already completed
        }
    }
}

// MARK: - Data Models

struct TeamWallet: Codable {
    let id: String
    let teamId: String
    let captainId: String
    let provider: String
    let balance: Int
    let address: String
    let walletId: String
    let createdAt: Date
}


enum TeamWalletAccessType {
    case view    // Can see balance and transactions
    case manage  // Can fund wallet and distribute rewards
}

enum RewardDistributionType {
    case equal
    case weighted([Int]) // Array of weights for each recipient
}

// MARK: - Errors

enum TeamWalletError: LocalizedError {
    case teamWalletCreationFailed
    case teamWalletNotFound
    case authenticationRequired
    case notAuthorized
    case insufficientBalance
    case rewardDistributionFailed
    
    var errorDescription: String? {
        switch self {
        case .teamWalletCreationFailed:
            return "Failed to create team wallet"
        case .teamWalletNotFound:
            return "Team wallet not found"
        case .authenticationRequired:
            return "Authentication required for team wallet operations"
        case .notAuthorized:
            return "Not authorized to perform this team wallet operation"
        case .insufficientBalance:
            return "Insufficient team wallet balance"
        case .rewardDistributionFailed:
            return "Failed to distribute team rewards"
        }
    }
}

