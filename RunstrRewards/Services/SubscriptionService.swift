import Foundation
import StoreKit

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // Product IDs (must match App Store Connect)
    enum ProductID {
        static let captainSubscription = "com.runstrrewards.captain" // $29.99/month captain subscription
        static let teamSubscription = "com.runstrrewards.team.monthly" // $3.99/month team subscription
    }
    
    // Subscription Status
    @Published private(set) var captainSubscriptionActive = false
    @Published private(set) var activeTeamSubscriptions: [TeamSubscriptionInfo] = [] // Active team subscriptions
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .none
    @Published private(set) var isLoading = false
    
    // Products  
    private var captainProduct: Product? // $29.99/month captain subscription product
    private var teamProduct: Product? // $3.99/month team subscription product
    private var availableProducts: [Product] = []
    
    // Transaction listener
    private var updateListenerTask: Task<Void, Error>?
    
    private override init() {
        super.init()
        startTransactionListener()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await Product.products(for: [
                ProductID.captainSubscription,
                ProductID.teamSubscription
            ])
            
            availableProducts = products
            
            for product in products {
                switch product.id {
                case ProductID.captainSubscription:
                    captainProduct = product
                    print("SubscriptionService: Captain subscription loaded - \(product.displayPrice)")
                case ProductID.teamSubscription:
                    teamProduct = product
                    print("SubscriptionService: Team subscription loaded - \(product.displayPrice)")
                default:
                    break
                }
            }
            
            // Check current subscription status
            await updateSubscriptionStatus()
            
        } catch {
            print("SubscriptionService: Failed to load products: \(error)")
            throw SubscriptionError.productsNotLoaded
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchaseCaptainSubscription() async throws -> Transaction? {
        guard let captainProduct = captainProduct else {
            throw SubscriptionError.productNotFound
        }
        
        return try await purchase(captainProduct)
    }
    
    // Convenience method that returns Bool for UI usage
    func purchaseCaptainSubscriptionBool() async throws -> Bool {
        let transaction = try await purchaseCaptainSubscription()
        return transaction != nil
    }
    
    func subscribeToTeam(_ teamId: String) async throws -> Bool {
        guard let teamProduct = teamProduct else {
            throw SubscriptionError.productNotFound
        }
        
        // Check if already subscribed to this team
        if isSubscribedToTeam(teamId) {
            print("SubscriptionService: Already subscribed to team \(teamId)")
            throw SubscriptionError.alreadySubscribed
        }
        
        // Purchase team subscription ($1.99/month for this specific team)
        let transaction = try await purchase(teamProduct)
        
        if let transaction = transaction {
            // Store team subscription in Supabase with team ID
            try await storeTeamSubscription(teamId: teamId, transaction: transaction)
            
            // Update local state
            let subscriptionInfo = TeamSubscriptionInfo(
                teamId: teamId,
                transactionId: String(transaction.id),
                purchaseDate: transaction.purchaseDate,
                expirationDate: transaction.expirationDate,
                isActive: true
            )
            
            activeTeamSubscriptions.append(subscriptionInfo)
            
            print("SubscriptionService: Successfully subscribed to team \(teamId) for $1.99/month")
            return true
        }
        
        return false
    }
    
    func unsubscribeFromTeam(_ teamId: String) async throws -> Bool {
        // Find the subscription for this team
        guard let subscription = activeTeamSubscriptions.first(where: { $0.teamId == teamId }) else {
            throw SubscriptionError.subscriptionNotFound
        }
        
        // Note: Actual cancellation would need to be done through App Store
        // For now, we'll mark as inactive in our database
        try await updateTeamSubscriptionStatus(
            userId: AuthenticationService.shared.currentUserId ?? "",
            transactionId: subscription.transactionId,
            status: "cancelled",
            expirationDate: nil
        )
        
        // Remove from local state
        activeTeamSubscriptions.removeAll { $0.teamId == teamId }
        
        print("SubscriptionService: Unsubscribed from team \(teamId)")
        return true
    }
    
    private func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        // Initiate purchase
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerified(verification)
            
            // Deliver content
            await updateSubscriptionStatus()
            await transaction.finish()
            
            // Update database
            await storeSubscriptionInDatabase(transaction)
            
            // Send confirmation notification
            print("SubscriptionService: Subscription confirmed for \(product.displayName) - \(product.displayPrice)")
            
            print("SubscriptionService: Purchase successful - \(product.id)")
            return transaction
            
        case .pending:
            // Transaction is pending (waiting for approval, etc.)
            print("SubscriptionService: Purchase pending")
            throw SubscriptionError.purchasePending
            
        case .userCancelled:
            // User cancelled the purchase
            print("SubscriptionService: Purchase cancelled by user")
            return nil
            
        @unknown default:
            throw SubscriptionError.purchaseFailed
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Sync with App Store to restore purchases
        try await AppStore.sync()
        
        // Update subscription status
        await updateSubscriptionStatus()
        
        print("SubscriptionService: Purchases restored")
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var hasCaptainSubscription = false
        var teamSubscriptions: [TeamSubscriptionInfo] = []
        
        // Check all current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Verify receipt to ensure authenticity
                let isValid = await verifyReceiptData(transaction: transaction)
                guard isValid else {
                    print("SubscriptionService: Receipt verification failed for transaction \(transaction.id)")
                    continue
                }
                
                switch transaction.productID {
                case ProductID.captainSubscription:
                    if transaction.revocationDate == nil && isSubscriptionActive(transaction) {
                        hasCaptainSubscription = true
                    }
                case ProductID.teamSubscription:
                    if transaction.revocationDate == nil && isSubscriptionActive(transaction) {
                        // Get team subscription details from Supabase
                        if let userId = AuthenticationService.shared.currentUserId {
                            do {
                                if let teamSub = try await fetchTeamSubscriptionFromSupabase(
                                    userId: userId, 
                                    transactionId: String(transaction.id)
                                ) {
                                    let subscriptionInfo = TeamSubscriptionInfo(
                                        teamId: teamSub.teamId,
                                        transactionId: String(transaction.id),
                                        purchaseDate: transaction.purchaseDate,
                                        expirationDate: transaction.expirationDate,
                                        isActive: isSubscriptionActive(transaction)
                                    )
                                    teamSubscriptions.append(subscriptionInfo)
                                }
                            } catch {
                                print("SubscriptionService: Failed to fetch team subscription details: \(error)")
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
        
        // Update published properties
        captainSubscriptionActive = hasCaptainSubscription
        activeTeamSubscriptions = teamSubscriptions
        
        // Determine overall status
        if hasCaptainSubscription {
            subscriptionStatus = .captain
        } else if !teamSubscriptions.isEmpty {
            subscriptionStatus = .user
        } else {
            subscriptionStatus = .none
        }
        
        // Update user profile in database
        await updateUserSubscriptionStatus()
        
        print("SubscriptionService: Status updated - Captain: \(hasCaptainSubscription), Team Subscriptions: \(teamSubscriptions.count)")
    }
    
    func checkSubscriptionStatus() async -> SubscriptionStatus {
        // Check actual subscription status - no more bypassing for testing
        await updateSubscriptionStatus()
        return subscriptionStatus
    }
    
    // MARK: - Transaction Listener
    
    private func startTransactionListener() {
        updateListenerTask = Task {
            for await result in StoreKit.Transaction.updates {
                if case .verified(let transaction) = result {
                    // Handle transaction update
                    await handleTransactionUpdate(transaction)
                    await transaction.finish()
                }
            }
        }
    }
    
    private func handleTransactionUpdate(_ transaction: StoreKit.Transaction) async {
        print("SubscriptionService: Transaction update - \(transaction.productID)")
        
        // Update subscription status
        await updateSubscriptionStatus()
        
        // Store in database
        await storeSubscriptionInDatabase(transaction)
        
        // Handle specific product updates
        switch transaction.productID {
        case ProductID.captainSubscription:
            if transaction.revocationDate == nil {
                // Captain subscription activated
                await enableCaptainFeatures()
            } else {
                // Captain subscription revoked
                await disableCaptainFeatures()
            }
            
        case ProductID.teamSubscription:
            if transaction.revocationDate == nil {
                // Team subscription activated
                await enableTeamFeatures(transactionId: String(transaction.id))
            } else {
                // Team subscription revoked
                await disableTeamFeatures(transactionId: String(transaction.id))
            }
            
        default:
            break
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Receipt Verification
    
    private func verifyReceiptData(transaction: StoreKit.Transaction) async -> Bool {
        // Basic transaction validation
        guard transaction.productID == ProductID.teamSubscription || transaction.productID == ProductID.captainSubscription else {
            print("SubscriptionService: Invalid product ID in transaction")
            return false
        }
        
        // Check if transaction is not too old (prevent replay attacks)
        let maxAge: TimeInterval = 86400 * 30 // 30 days
        guard Date().timeIntervalSince(transaction.purchaseDate) < maxAge else {
            print("SubscriptionService: Transaction too old")
            return false
        }
        
        // For production, implement additional server-side verification
        // This would involve sending the transaction to your backend for verification with Apple's servers
        
        return true
    }
    
    private func isSubscriptionActive(_ transaction: StoreKit.Transaction) -> Bool {
        // Check if subscription is currently active
        if let expirationDate = transaction.expirationDate {
            return expirationDate > Date()
        }
        
        // If no expiration date, it's likely a lifetime or non-renewing subscription
        // For monthly subscriptions, there should always be an expiration date
        return transaction.productID == ProductID.captainSubscription || transaction.productID == ProductID.teamSubscription
    }
    
    // MARK: - Server-Side Verification (Production)
    
    private func verifyTransactionWithApple(transaction: StoreKit.Transaction) async throws -> Bool {
        // In production, implement server-side verification
        // This involves sending the transaction receipt to Apple's verification servers
        // For now, return true for local development
        
        print("SubscriptionService: Server-side verification would be implemented here for production")
        return true
    }
    
    // MARK: - Manage Subscriptions
    
    func openManageSubscriptions() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("SubscriptionService: Failed to open manage subscriptions: \(error)")
            }
        }
    }
    
    // MARK: - Pricing Information
    
    func getCaptainSubscriptionPrice() -> String {
        captainProduct?.displayPrice ?? "$19.99/month"
    }
    
    func getTeamSubscriptionPrice() -> String {
        teamProduct?.displayPrice ?? "$1.99/month"
    }
    
    func getProductDescription(for productId: String) -> String {
        switch productId {
        case ProductID.captainSubscription:
            return "Create and manage one fitness team. Full access to team management, analytics, and creation tools."
        case ProductID.teamSubscription:
            return "Join a specific team to compete in leaderboards and earn Bitcoin rewards"
        default:
            return ""
        }
    }
    
    // MARK: - Feature Gates
    
    func canCreateTeam() -> Bool {
        // Must be a captain and not already have a team
        return captainSubscriptionActive && !hasExistingTeam()
    }
    
    func hasExistingTeam() -> Bool {
        // Check if captain already has a team
        // This checks synchronously using cached data
        // For real-time check, use hasExistingTeamAsync()
        guard let userId = AuthenticationService.shared.currentUserId else { return false }
        
        // TODO: Implement actual check via Supabase
        // For now, return false to allow team creation during development
        return false
    }
    
    func hasExistingTeamAsync() async throws -> Bool {
        guard let userId = AuthenticationService.shared.currentUserId else { return false }
        
        let teamCount = try await SupabaseService.shared.getCaptainTeamCount(captainId: userId)
        return teamCount > 0
    }
    
    func getMaxTeamsForCaptain() -> Int {
        return captainSubscriptionActive ? 1 : 0
    }
    
    func canSubscribeToTeams() -> Bool {
        return true // Users can always subscribe to teams
    }
    
    func canManageTeam() -> Bool {
        return captainSubscriptionActive
    }
    
    func canCreateLeaderboards() -> Bool {
        return captainSubscriptionActive
    }
    
    func canCreateEvents() -> Bool {
        return captainSubscriptionActive
    }
    
    func canAccessAnalytics() -> Bool {
        return captainSubscriptionActive
    }
    
    func getMaxTeamMembers() -> Int {
        return captainSubscriptionActive ? 1000 : 0 // Only captains can manage teams
    }
    
    func getRewardMultiplier() -> Double {
        switch subscriptionStatus {
        case .captain:
            return 2.0 // 2x rewards for team captains
        case .user:
            return 1.5 // 1.5x rewards for team subscribers
        case .none:
            return 1.0 // Standard rewards
        }
    }
    
    func isSubscribedToTeam(_ teamId: String) -> Bool {
        return activeTeamSubscriptions.contains { $0.teamId == teamId && $0.isActive }
    }
    
    func getSubscribedTeams() -> [String] {
        return activeTeamSubscriptions.filter { $0.isActive }.map { $0.teamId }
    }
    
    func getActiveTeamSubscriptionCount() -> Int {
        return activeTeamSubscriptions.filter { $0.isActive }.count
    }
    
    func getTotalMonthlyTeamCost() -> Double {
        let activeCount = getActiveTeamSubscriptionCount()
        return Double(activeCount) * 1.99 // $1.99 per team
    }
    
    func getTeamSubscription(for teamId: String) -> TeamSubscriptionInfo? {
        return activeTeamSubscriptions.first { $0.teamId == teamId && $0.isActive }
    }
    
    // MARK: - Database Integration
    
    private func storeSubscriptionInDatabase(_ transaction: StoreKit.Transaction) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        // Create subscription record
        let _ = SubscriptionData(
            id: transaction.id,
            userId: userId,
            productId: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            status: transaction.revocationDate == nil ? "active" : "cancelled",
            originalTransactionId: String(transaction.originalID)
        )
        
        // Store in Supabase
        // TODO: Implement actual Supabase storage
        print("SubscriptionService: Storing subscription in database")
    }
    
    private func updateUserSubscriptionStatus() async {
        guard AuthenticationService.shared.currentUserId != nil else { return }
        
        let tier: String
        switch subscriptionStatus {
        case .captain:
            tier = "captain"
        case .user:
            tier = "user"
        case .none:
            tier = "free"
        }
        
        // Update user profile with subscription tier
        // TODO: Implement actual Supabase update
        print("SubscriptionService: Updating user subscription tier to: \(tier)")
    }
    
    // MARK: - Feature Management
    
    private func enableCaptainFeatures() async {
        print("SubscriptionService: Enabling captain features")
        
        // Enable team creation
        UserDefaults.standard.set(true, forKey: "features.team_creation")
        
        // Enable event creation
        UserDefaults.standard.set(true, forKey: "features.event_creation")
        
        // Enable analytics dashboard
        UserDefaults.standard.set(true, forKey: "features.team_analytics")
        
        // Enable leaderboard management
        UserDefaults.standard.set(true, forKey: "features.leaderboard_management")
        
        // Enable captain-specific features
        UserDefaults.standard.set(true, forKey: "features.team_management")
        UserDefaults.standard.set(true, forKey: "features.revenue_sharing")
        
        // Notify UI of changes
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func disableCaptainFeatures() async {
        print("SubscriptionService: Disabling captain features")
        
        UserDefaults.standard.set(false, forKey: "features.team_creation")
        UserDefaults.standard.set(false, forKey: "features.event_creation")
        UserDefaults.standard.set(false, forKey: "features.team_analytics")
        UserDefaults.standard.set(false, forKey: "features.leaderboard_management")
        UserDefaults.standard.set(false, forKey: "features.team_management")
        UserDefaults.standard.set(false, forKey: "features.revenue_sharing")
        
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func enableTeamFeatures(transactionId: String) async {
        print("SubscriptionService: Enabling team features for transaction \(transactionId)")
        
        // Enable team subscription features
        UserDefaults.standard.set(true, forKey: "features.team_subscriptions")
        UserDefaults.standard.set(true, forKey: "features.enhanced_rewards")
        UserDefaults.standard.set(true, forKey: "features.priority_competitions")
        UserDefaults.standard.set(true, forKey: "features.team_chat")
        UserDefaults.standard.set(true, forKey: "features.team_leaderboards")
        
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func disableTeamFeatures(transactionId: String) async {
        print("SubscriptionService: Disabling team features for transaction \(transactionId)")
        
        // Only disable if user has no other active team subscriptions
        if activeTeamSubscriptions.filter({ $0.isActive && $0.transactionId != transactionId }).isEmpty {
            UserDefaults.standard.set(false, forKey: "features.team_subscriptions")
            UserDefaults.standard.set(false, forKey: "features.enhanced_rewards")
            UserDefaults.standard.set(false, forKey: "features.priority_competitions")
            UserDefaults.standard.set(false, forKey: "features.team_chat")
            UserDefaults.standard.set(false, forKey: "features.team_leaderboards")
        }
        
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    // MARK: - Promotional Offers (commented out due to API availability)
    
    /*
    func checkForPromotionalOffers() async -> [Product.PromotionalOffer] {
        var offers: [Product.PromotionalOffer] = []
        
        for product in availableProducts {
            // Check if user is eligible for promotional offers
            if let subscriptions = product.subscription {
                let eligibleOffers = await subscriptions.promotionalOffers
                offers.append(contentsOf: eligibleOffers)
            }
        }
        
        return offers
    }
    
    func redeemPromotionalOffer(_ offer: Product.PromotionalOffer, for product: Product) async throws -> Transaction? {
        let result = try await product.purchase(options: [.promotionalOffer(offer)])
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction
        case .pending:
            throw SubscriptionError.purchasePending
        case .userCancelled:
            return nil
        @unknown default:
            throw SubscriptionError.purchaseFailed
        }
    }
    */
    
    // MARK: - Supabase Integration Methods
    
    private func storeTeamSubscription(teamId: String, transaction: StoreKit.Transaction) async throws {
        guard let userId = AuthenticationService.shared.currentUserId else {
            throw SubscriptionError.userNotFound
        }
        
        let subscription = DatabaseTeamSubscription(
            id: UUID().uuidString,
            userId: userId,
            teamId: teamId,
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            status: "active",
            autoRenewing: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await SupabaseService.shared.createTeamSubscription(subscription)
    }
    
    private func fetchTeamSubscriptionFromSupabase(userId: String, transactionId: String) async throws -> DatabaseTeamSubscription? {
        return try await SupabaseService.shared.fetchTeamSubscription(userId: userId, transactionId: transactionId)
    }
    
    private func updateTeamSubscriptionStatus(userId: String, transactionId: String, status: String, expirationDate: Date?) async throws {
        try await SupabaseService.shared.updateTeamSubscriptionStatus(
            userId: userId,
            transactionId: transactionId,
            status: status,
            expirationDate: expirationDate
        )
    }
}

// MARK: - Data Models

enum SubscriptionStatus {
    case none
    case user    // Subscribed to one or more teams
    case captain // RunstrRewards captain - can create and manage teams
    
    var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .user:
            return "Team Member"
        case .captain:
            return "RunstrRewards Captain"
        }
    }
    
    var badgeColor: UIColor {
        switch self {
        case .none:
            return .systemGray
        case .user:
            return .systemBlue
        case .captain:
            return IndustrialDesign.Colors.bitcoin
        }
    }
}

struct SubscriptionData: Codable {
    let id: UInt64
    let userId: String
    let productId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let status: String
    let originalTransactionId: String
}

struct TeamSubscriptionInfo: Codable {
    let teamId: String
    let transactionId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case transactionId = "transaction_id"
        case purchaseDate = "purchase_date"
        case expirationDate = "expiration_date"
        case isActive = "is_active"
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productsNotLoaded
    case productNotFound
    case purchaseFailed
    case purchasePending
    case verificationFailed
    case restoreFailed
    case userNotFound
    case alreadySubscribed
    case subscriptionExpired
    case subscriptionNotFound
    case teamLimitReached
    
    var errorDescription: String? {
        switch self {
        case .productsNotLoaded:
            return "Subscription products not loaded"
        case .productNotFound:
            return "Subscription product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .purchasePending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Purchase verification failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .userNotFound:
            return "User not logged in"
        case .alreadySubscribed:
            return "Already subscribed to this team"
        case .subscriptionExpired:
            return "Subscription has expired"
        case .subscriptionNotFound:
            return "Subscription not found"
        case .teamLimitReached:
            return "Team limit reached - captains can only create one team"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

