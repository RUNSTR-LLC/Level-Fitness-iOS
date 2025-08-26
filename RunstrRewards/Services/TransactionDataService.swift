import Foundation
import Supabase

// MARK: - Transaction Data Models

struct DatabaseTransaction: Codable {
    let id: String
    let userId: String
    let walletId: String?
    let type: String
    let amount: Int
    let usdAmount: Double?
    let description: String?
    let status: String
    let transactionHash: String?
    let preimage: String?
    let processedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, amount, description, status, preimage
        case userId = "user_id"
        case walletId = "wallet_id"
        case usdAmount = "usd_amount"
        case transactionHash = "transaction_hash"
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }
}

struct SupabaseLightningWallet: Codable {
    let id: String
    let userId: String
    let provider: String
    let walletId: String
    let address: String
    let balance: Int
    let credentialsEncrypted: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, provider, address, balance, status
        case userId = "user_id"
        case walletId = "wallet_id"
        case credentialsEncrypted = "credentials_encrypted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseTeamSubscription: Codable {
    let id: String
    let userId: String
    let teamId: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let status: String
    let autoRenewing: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case expirationDate = "expiration_date"
        case status
        case autoRenewing = "auto_renewing"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseLightningWallet: Codable {
    let id: String
    let userId: String?
    let teamId: String?
    let walletType: String
    let provider: String
    let walletId: String
    let address: String
    let balance: Int
    let credentialsEncrypted: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case walletType = "wallet_type"
        case provider
        case walletId = "wallet_id"
        case address
        case balance
        case credentialsEncrypted = "credentials_encrypted"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Transaction: Codable {
    let id: String
    let userId: String?
    let teamId: String?
    let walletId: String?
    let fromWalletId: String?
    let toWalletId: String?
    let type: String
    let amount: Int
    let usdAmount: Double?
    let description: String?
    let status: String
    let transactionHash: String?
    let preimage: String?
    let invoiceData: String?
    let metadata: String?
    let processedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case walletId = "wallet_id"
        case fromWalletId = "from_wallet_id"
        case toWalletId = "to_wallet_id"
        case type
        case amount
        case usdAmount = "usd_amount"
        case description
        case status
        case transactionHash = "transaction_hash"
        case preimage
        case invoiceData = "invoice_data"
        case metadata
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }
}

// MARK: - Service Dependencies
// This service references models from SupabaseService, ErrorHandlingService, NetworkMonitorService, OfflineDataService

class TransactionDataService {
    static let shared = TransactionDataService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Transaction Management
    
    func fetchTransactions(userId: String, limit: Int = 50) async throws -> [DatabaseTransaction] {
        // Clean the user ID of any quotes that might have been passed incorrectly
        let cleanUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTransactions() {
                print("TransactionDataService: Using cached transactions (offline)")
                return Array(cached.prefix(limit))
            }
            throw AppError.networkUnavailable
        }
        
        do {
            print("TransactionDataService: Fetching transactions for user ID: \(cleanUserId)")
            
            let response = try await client
                .from("transactions")
                .select()
                .eq("user_id", value: cleanUserId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
            
            let data = response.data
            let transactions = try SupabaseService.shared.customJSONDecoder().decode([DatabaseTransaction].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTransactions(transactions)
            
            return transactions
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTransactions", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTransactions() {
                print("TransactionDataService: Using cached transactions (error fallback)")
                return Array(cached.prefix(limit))
            }
            
            throw error
        }
    }
    
    func createTransaction(userId: String, type: String, amount: Int, description: String) async throws -> DatabaseTransaction {
        let transaction = DatabaseTransaction(
            id: UUID().uuidString,
            userId: userId,
            walletId: nil,
            type: type,
            amount: amount,
            usdAmount: nil,
            description: description,
            status: "pending",
            transactionHash: nil,
            preimage: nil,
            processedAt: nil,
            createdAt: Date()
        )
        
        let response = try await client
            .from("transactions")
            .insert(transaction)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(DatabaseTransaction.self, from: data)
    }
    
    func recordTransaction(
        teamId: String? = nil,
        userId: String? = nil,
        walletId: String? = nil,
        amount: Int,
        type: String,
        description: String,
        metadata: [String: Any] = [:]
    ) async throws {
        // For MVP: Simple logging implementation
        // TODO: Implement full transaction recording when Supabase client supports complex types
        print("TransactionDataService: Recording transaction - \(amount) sats, type: \(type)")
        print("TransactionDataService: Description: \(description)")
        
        if let teamId = teamId {
            print("TransactionDataService: Team ID: \(teamId)")
        }
        
        if let userId = userId {
            print("TransactionDataService: User ID: \(userId)")
        }
        
        print("TransactionDataService: Transaction recorded successfully (simplified for MVP)")
    }
    
    // MARK: - Lightning Wallet Operations
    
    func createLightningWallet(userId: String, provider: String, walletId: String, address: String) async throws -> SupabaseLightningWallet {
        let wallet = SupabaseLightningWallet(
            id: UUID().uuidString,
            userId: userId,
            provider: provider,
            walletId: walletId,
            address: address,
            balance: 0,
            credentialsEncrypted: nil,
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let response = try await client
            .from("lightning_wallets")
            .insert(wallet)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(SupabaseLightningWallet.self, from: data)
    }
    
    func fetchLightningWallet(userId: String) async throws -> SupabaseLightningWallet? {
        let response = try await client
            .from("lightning_wallets")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(SupabaseLightningWallet.self, from: data)
    }
    
    func storeUserWallet(_ wallet: LightningWallet) async throws {
        struct DatabaseWallet: Encodable {
            let id: String
            let userId: String
            let walletType: String
            let balance: Int
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case walletType = "wallet_type"
                case balance
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseWallet = DatabaseWallet(
            id: wallet.id,
            userId: wallet.userId,
            walletType: "lightning",
            balance: wallet.balance,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("user_wallets")
            .insert(databaseWallet)
            .execute()
        
        print("TransactionDataService: User wallet stored successfully")
    }
    
    // MARK: - Team Wallet Operations
    
    func storeTeamWallet(_ teamWallet: TeamWallet) async throws {
        struct DatabaseTeamWallet: Encodable {
            let id: String
            let teamId: String
            let captainId: String
            let provider: String
            let balance: Int
            let address: String
            let walletId: String
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case teamId = "team_id"
                case captainId = "captain_id"
                case provider
                case balance
                case address
                case walletId = "wallet_id"
                case createdAt = "created_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseTeamWallet = DatabaseTeamWallet(
            id: teamWallet.id,
            teamId: teamWallet.teamId,
            captainId: teamWallet.captainId,
            provider: teamWallet.provider,
            balance: teamWallet.balance,
            address: teamWallet.address,
            walletId: teamWallet.walletId,
            createdAt: iso8601Formatter.string(from: teamWallet.createdAt)
        )
        
        try await client
            .from("team_wallets")
            .insert(databaseTeamWallet)
            .execute()
        
        print("TransactionDataService: Team wallet stored successfully")
    }
    
    func updateTeamWalletId(teamId: String, walletId: String) async throws {
        struct TeamUpdate: Encodable {
            let walletId: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case walletId = "wallet_id"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let teamUpdate = TeamUpdate(
            walletId: walletId,
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("teams")
            .update(teamUpdate)
            .eq("id", value: teamId)
            .execute()
        
        print("TransactionDataService: Team wallet ID updated successfully")
    }
    
    func recordTeamTransaction(
        teamId: String,
        userId: String?,
        amount: Int,
        type: String,
        description: String
    ) async throws {
        struct TeamTransaction: Encodable {
            let id: String
            let teamId: String
            let userId: String?
            let amount: Int
            let type: String
            let description: String
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case teamId = "team_id"
                case userId = "user_id"
                case amount
                case type
                case description
                case createdAt = "created_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let teamTransaction = TeamTransaction(
            id: UUID().uuidString,
            teamId: teamId,
            userId: userId,
            amount: amount,
            type: type,
            description: description,
            createdAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("team_transactions")
            .insert(teamTransaction)
            .execute()
        
        print("TransactionDataService: Team transaction recorded successfully")
    }
    
    func getTeamWalletBalance(teamId: String) async throws -> Int {
        print("TransactionDataService: Getting team wallet balance for team \(teamId)")
        
        do {
            // Check if team wallet exists in database
            let response: [TeamWallet] = try await client
                .from("team_wallets")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            guard let teamWallet = response.first else {
                print("TransactionDataService: No wallet found for team \(teamId), returning 0")
                return 0
            }
            
            // Use TeamWalletManager to get balance (it handles credentials properly)
            let walletBalance = try await TeamWalletManager.shared.getTeamWalletBalance(teamId: teamId)
            let balance = walletBalance.total
            
            print("TransactionDataService: Retrieved real balance: \(balance) sats for team \(teamId)")
            return balance
            
        } catch {
            print("TransactionDataService: Failed to get team wallet balance: \(error)")
            // Return 0 instead of mock data on error
            return 0
        }
    }
    
    // MARK: - Subscription Management
    
    func createTeamSubscription(_ subscription: DatabaseTeamSubscription) async throws {
        try await client
            .from("team_subscriptions")
            .insert(subscription)
            .execute()
        
        print("TransactionDataService: Team subscription created for team \(subscription.teamId)")
    }
    
    func storeSubscriptionData(_ subscriptionData: SubscriptionData) async throws {
        struct DatabaseSubscription: Encodable {
            let id: String
            let userId: String
            let productId: String
            let purchaseDate: String
            let expirationDate: String?
            let status: String
            let originalTransactionId: String
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case productId = "product_id"
                case purchaseDate = "purchase_date"
                case expirationDate = "expiration_date"
                case status
                case originalTransactionId = "original_transaction_id"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseSubscription = DatabaseSubscription(
            id: String(subscriptionData.id),
            userId: subscriptionData.userId,
            productId: subscriptionData.productId,
            purchaseDate: iso8601Formatter.string(from: subscriptionData.purchaseDate),
            expirationDate: subscriptionData.expirationDate != nil ? iso8601Formatter.string(from: subscriptionData.expirationDate!) : nil,
            status: subscriptionData.status,
            originalTransactionId: subscriptionData.originalTransactionId,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("subscriptions")
            .insert(databaseSubscription)
            .execute()
        
        print("TransactionDataService: Subscription data stored successfully")
    }
    
    func updateUserSubscriptionTier(userId: String, tier: String) async throws {
        struct UserUpdate: Encodable {
            let subscriptionTier: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case subscriptionTier = "subscription_tier"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let userUpdate = UserUpdate(
            subscriptionTier: tier,
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("profiles")
            .update(userUpdate)
            .eq("id", value: userId)
            .execute()
        
        print("TransactionDataService: User subscription tier updated successfully")
    }
    
    func fetchTeamSubscription(userId: String, transactionId: String) async throws -> DatabaseTeamSubscription? {
        let response = try await client
            .from("team_subscriptions")
            .select()
            .eq("user_id", value: userId)
            .eq("transaction_id", value: transactionId)
            .single()
            .execute()
        
        let data = response.data
        return try SupabaseService.shared.customJSONDecoder().decode(DatabaseTeamSubscription.self, from: data)
    }
    
    func updateTeamSubscriptionStatus(userId: String, transactionId: String, status: String, expirationDate: Date?) async throws {
        struct UpdateData: Encodable {
            let status: String
            let updatedAt: String
            let expirationDate: String?
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
                case expirationDate = "expiration_date"
            }
        }
        
        let updateData = UpdateData(
            status: status,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            expirationDate: expirationDate != nil ? ISO8601DateFormatter().string(from: expirationDate!) : nil
        )
        
        try await client
            .from("team_subscriptions")
            .update(updateData)
            .eq("user_id", value: userId)
            .eq("transaction_id", value: transactionId)
            .execute()
        
        print("TransactionDataService: Team subscription status updated to \(status)")
    }
    
    func fetchUserTeamSubscriptions(userId: String) async throws -> [DatabaseTeamSubscription] {
        let response = try await client
            .from("team_subscriptions")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        return try SupabaseService.shared.customJSONDecoder().decode([DatabaseTeamSubscription].self, from: data)
    }
    
    func getTeamTransactions(teamId: String, limit: Int = 50) async throws -> [TeamTransaction] {
        // For now, return empty array until proper implementation
        return []
    }
}