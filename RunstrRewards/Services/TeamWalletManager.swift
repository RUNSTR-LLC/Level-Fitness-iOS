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
            print("TeamWalletManager: ❌ No user session found")
            throw TeamWalletError.authenticationRequired
        }
        
        print("TeamWalletManager: 🔍 Verifying captain access for user \(userId) on team \(teamId)")
        print("TeamWalletManager: 🔍 Session user ID: \(userSession.id)")
        
        if userSession.id != userId {
            print("TeamWalletManager: ❌ Session user ID doesn't match requested user ID")
            throw TeamWalletError.notAuthorized
        }
        
        // Check if user is captain of the team via Supabase
        do {
            let team = try await supabaseService.getTeam(teamId)
            print("TeamWalletManager: 🔍 Team data retrieved: \(String(describing: team))")
            
            if let team = team {
                print("TeamWalletManager: 🔍 Team captain_id: '\(team.captainId)' (length: \(team.captainId.count))")
                print("TeamWalletManager: 🔍 Comparing with user_id: '\(userId)' (length: \(userId.count))")
                
                let captainIdLower = team.captainId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let userIdLower = userId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("TeamWalletManager: 🔍 Normalized comparison: '\(captainIdLower)' vs '\(userIdLower)'")
                
                if captainIdLower == userIdLower {
                    print("TeamWalletManager: ✅ CAPTAIN ACCESS VERIFIED - User \(userId) is captain of team \(teamId)")
                    return true
                } else {
                    print("TeamWalletManager: ❌ CAPTAIN CHECK FAILED in teams table - user '\(userId)' is not captain")
                }
            } else {
                print("TeamWalletManager: ❌ TEAM NOT FOUND: \(teamId) - team data is null")
            }
            
            // Fallback: Check team_members table for captain role
            print("TeamWalletManager: 🔍 FALLBACK CHECK: Checking team_members table for captain role...")
            let isCaptainInMembers = try await isUserTeamCaptainInMembers(teamId: teamId, userId: userId)
            
            if isCaptainInMembers {
                print("TeamWalletManager: ✅ CAPTAIN ACCESS VERIFIED - User found as captain in team_members table")
                return true
            }
            
            print("TeamWalletManager: ❌ FINAL RESULT: User \(userId) is NOT captain of team \(teamId) in either teams table or team_members table")
            return false
            
        } catch {
            print("TeamWalletManager: ❌ EXCEPTION during captain verification: \(error)")
            print("TeamWalletManager: ❌ Error type: \(type(of: error))")
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
        print("TeamWalletManager: Creating invoice for user \(userId), amount: \(amount) sats")
        
        // Get user's wallet credentials
        guard let userCredentials = await getUserWalletCredentials(userId: userId) else {
            print("TeamWalletManager: ❌ No wallet credentials found for user \(userId)")
            throw TeamWalletError.userWalletNotFound
        }
        
        // Store current CoinOS auth state to restore later
        let currentAuthToken = coinOSService.getCurrentAuthToken()
        
        do {
            // Temporarily authenticate with user's wallet
            print("TeamWalletManager: 🔄 Switching to user wallet authentication...")
            let userAuthResponse = try await coinOSService.loginUser(
                username: userCredentials.username, 
                password: userCredentials.password
            )
            coinOSService.setAuthToken(userAuthResponse.token)
            
            // Create invoice in user's wallet
            let invoice = try await coinOSService.addInvoice(amount: amount, memo: memo)
            print("TeamWalletManager: ✅ Created invoice in user \(userId) wallet: \(amount) sats")
            
            // Restore previous auth state
            if let previousToken = currentAuthToken {
                coinOSService.setAuthToken(previousToken)
                print("TeamWalletManager: 🔄 Restored previous CoinOS authentication")
            }
            
            return invoice
            
        } catch {
            // Restore previous auth state even if creation failed
            if let previousToken = currentAuthToken {
                coinOSService.setAuthToken(previousToken)
            }
            
            print("TeamWalletManager: ❌ Failed to create user invoice: \(error)")
            throw TeamWalletError.userInvoiceCreationFailed
        }
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
    
    private func isUserTeamCaptainInMembers(teamId: String, userId: String) async throws -> Bool {
        // Check if user has captain role in team_members table
        do {
            print("TeamWalletManager: 🔍 FALLBACK: Fetching team members for team \(teamId)")
            let members = try await supabaseService.fetchTeamMembers(teamId: teamId)
            print("TeamWalletManager: 🔍 FALLBACK: Found \(members.count) team members")
            
            // Debug: Print all members and their roles
            for member in members {
                print("TeamWalletManager: 🔍 Member: '\(member.profile.id)' (role: '\(member.role)')")
            }
            
            let userIdLower = userId.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let captainMember = members.first { member in
                let memberIdLower = member.profile.id.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let isMatch = memberIdLower == userIdLower && member.role == "captain"
                print("TeamWalletManager: 🔍 Comparing member '\(memberIdLower)' with target '\(userIdLower)' (role: '\(member.role)') -> match: \(isMatch)")
                return isMatch
            }
            
            let isCaptain = captainMember != nil
            
            print("TeamWalletManager: FALLBACK RESULT: User \(userId) captain role in team_members for team \(teamId): \(isCaptain)")
            if let member = captainMember {
                print("TeamWalletManager: ✅ FALLBACK SUCCESS: Found captain member: \(member.profile.id) with role: \(member.role)")
            } else {
                print("TeamWalletManager: ❌ FALLBACK FAILED: User not found as captain in team_members table")
            }
            
            return isCaptain
            
        } catch {
            print("TeamWalletManager: ❌ FALLBACK ERROR: Error checking captain role in team_members: \(error)")
            return false // Don't throw, just return false as fallback
        }
    }
    
    private func storeTeamWalletCredentials(teamId: String, username: String, password: String, token: String) throws {
        print("TeamWalletManager: Storing team-specific wallet credentials for team \(teamId)")
        
        // Use team-specific keychain keys to prevent collision between teams
        let usernameKey = "coinOS_team_\(teamId)_username"
        let passwordKey = "coinOS_team_\(teamId)_password"
        let tokenKey = "coinOS_team_\(teamId)_token"
        
        // Create custom keychain items for team-specific credentials
        let usernameResult = KeychainService.shared.saveCustom(username, for: usernameKey)
        let passwordResult = KeychainService.shared.saveCustom(password, for: passwordKey)
        let tokenResult = KeychainService.shared.saveCustom(token, for: tokenKey)
        
        if usernameResult && passwordResult && tokenResult {
            print("TeamWalletManager: ✅ Team wallet credentials stored successfully for team \(teamId)")
        } else {
            print("TeamWalletManager: ❌ Failed to store some team wallet credentials")
            throw TeamWalletError.teamWalletCreationFailed
        }
    }
    
    func loadTeamWalletCredentials(teamId: String) -> TeamWalletCredentials? {
        print("TeamWalletManager: Loading team-specific wallet credentials for team \(teamId)")
        
        // Load team-specific credentials
        let usernameKey = "coinOS_team_\(teamId)_username"
        let passwordKey = "coinOS_team_\(teamId)_password"
        let tokenKey = "coinOS_team_\(teamId)_token"
        
        guard let username = KeychainService.shared.loadCustom(for: usernameKey),
              let password = KeychainService.shared.loadCustom(for: passwordKey),
              let token = KeychainService.shared.loadCustom(for: tokenKey) else {
            print("TeamWalletManager: ❌ Could not load team wallet credentials for team \(teamId)")
            return nil
        }
        
        print("TeamWalletManager: ✅ Team wallet credentials loaded successfully for team \(teamId)")
        return TeamWalletCredentials(username: username, password: password, token: token)
    }
    
    private func getUserWalletCredentials(userId: String) async -> UserWalletCredentials? {
        // For now, use global CoinOS credentials for users
        // TODO: Implement per-user credential storage similar to teams
        print("TeamWalletManager: Loading user wallet credentials for user \(userId)")
        
        guard let username = KeychainService.shared.load(for: .coinOSUsername),
              let password = KeychainService.shared.load(for: .coinOSPassword) else {
            print("TeamWalletManager: ❌ No user wallet credentials found")
            return nil
        }
        
        print("TeamWalletManager: ✅ Found user wallet credentials")
        return UserWalletCredentials(username: username, password: password)
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

struct UserWalletCredentials {
    let username: String
    let password: String
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
    case userWalletNotFound
    case userInvoiceCreationFailed
    
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
        case .userWalletNotFound:
            return "User wallet not found or not set up"
        case .userInvoiceCreationFailed:
            return "Failed to create invoice in user wallet"
        }
    }
}

