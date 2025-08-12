import Foundation
import StoreKit

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // Product IDs (must match App Store Connect)
    enum ProductID {
        static let creatorSubscription = "com.levelfitness.creator"
        static let userSubscription = "com.levelfitness.user" // For team subscriptions
    }
    
    // Subscription Status
    @Published private(set) var creatorSubscriptionActive = false
    @Published private(set) var userTeamSubscriptions: [String] = [] // Array of team IDs user is subscribed to
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .none
    @Published private(set) var isLoading = false
    
    // Products  
    private var creatorProduct: Product?
    private var userProduct: Product? // Base user subscription product
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
                ProductID.creatorSubscription,
                ProductID.userSubscription
            ])
            
            availableProducts = products
            
            for product in products {
                switch product.id {
                case ProductID.creatorSubscription:
                    creatorProduct = product
                    print("SubscriptionService: Creator subscription loaded - \(product.displayPrice)")
                case ProductID.userSubscription:
                    userProduct = product
                    print("SubscriptionService: User subscription loaded - \(product.displayPrice)")
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
    
    func purchaseCreatorSubscription() async throws -> Transaction? {
        guard let creatorProduct = creatorProduct else {
            throw SubscriptionError.productNotFound
        }
        
        return try await purchase(creatorProduct)
    }
    
    // Convenience method that returns Bool for UI usage
    func purchaseCreatorSubscriptionBool() async throws -> Bool {
        let transaction = try await purchaseCreatorSubscription()
        return transaction != nil
    }
    
    func subscribeToTeam(_ teamId: String, price: Double) async throws -> Transaction? {
        guard let userProduct = userProduct else {
            throw SubscriptionError.productNotFound
        }
        
        // For now use the base user product - in full implementation would be dynamic pricing
        let transaction = try await purchase(userProduct)
        
        // Store team subscription mapping
        if transaction != nil {
            userTeamSubscriptions.append(teamId)
            print("SubscriptionService: User subscribed to team \(teamId) for $\(price)/month")
        }
        
        return transaction
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
        var hasCreatorSubscription = false
        var activeTeamSubscriptions: [String] = []
        
        // Check all current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                switch transaction.productID {
                case ProductID.creatorSubscription:
                    if transaction.revocationDate == nil {
                        hasCreatorSubscription = true
                    }
                case ProductID.userSubscription:
                    if transaction.revocationDate == nil {
                        // In full implementation, would map transaction to specific team
                        activeTeamSubscriptions = userTeamSubscriptions
                    }
                default:
                    break
                }
            }
        }
        
        // Update published properties
        creatorSubscriptionActive = hasCreatorSubscription
        userTeamSubscriptions = activeTeamSubscriptions
        
        // Determine overall status
        if hasCreatorSubscription {
            subscriptionStatus = .creator
        } else if !activeTeamSubscriptions.isEmpty {
            subscriptionStatus = .user
        } else {
            subscriptionStatus = .none
        }
        
        // Update user profile in database
        await updateUserSubscriptionStatus()
        
        print("SubscriptionService: Status updated - Creator: \(hasCreatorSubscription), User: \(!activeTeamSubscriptions.isEmpty)")
    }
    
    func checkSubscriptionStatus() async -> SubscriptionStatus {
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
        case ProductID.creatorSubscription:
            if transaction.revocationDate == nil {
                // Creator subscription activated
                await enableCreatorFeatures()
            } else {
                // Creator subscription revoked
                await disableCreatorFeatures()
            }
            
        case ProductID.userSubscription:
            if transaction.revocationDate == nil {
                // User subscription activated
                await enableUserFeatures()
            } else {
                // User subscription revoked
                await disableUserFeatures()
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
    
    func getCreatorSubscriptionPrice() -> String {
        creatorProduct?.displayPrice ?? "$29.99/month"
    }
    
    func getUserSubscriptionPrice() -> String {
        userProduct?.displayPrice ?? "$3.99/month"
    }
    
    func getProductDescription(for productId: String) -> String {
        switch productId {
        case ProductID.creatorSubscription:
            return "Create and manage one team, leaderboard & event wizards, team analytics dashboard"
        case ProductID.userSubscription:
            return "Subscribe to teams, compete in leaderboards, earn Bitcoin rewards"
        default:
            return ""
        }
    }
    
    // MARK: - Feature Gates
    
    func canCreateTeam() -> Bool {
        return creatorSubscriptionActive
    }
    
    func canSubscribeToTeams() -> Bool {
        return true // Users can always subscribe to teams
    }
    
    func canManageTeam() -> Bool {
        return creatorSubscriptionActive
    }
    
    func canCreateLeaderboards() -> Bool {
        return creatorSubscriptionActive
    }
    
    func canCreateEvents() -> Bool {
        return creatorSubscriptionActive
    }
    
    func canAccessAnalytics() -> Bool {
        return creatorSubscriptionActive
    }
    
    func getMaxTeamMembers() -> Int {
        return creatorSubscriptionActive ? 1000 : 0 // Only creators can manage teams
    }
    
    func getRewardMultiplier() -> Double {
        switch subscriptionStatus {
        case .creator:
            return 2.0 // 2x rewards for team creators
        case .user:
            return 1.5 // 1.5x rewards for team subscribers
        case .none:
            return 1.0 // Standard rewards
        }
    }
    
    func isSubscribedToTeam(_ teamId: String) -> Bool {
        return userTeamSubscriptions.contains(teamId)
    }
    
    // MARK: - Database Integration
    
    private func storeSubscriptionInDatabase(_ transaction: StoreKit.Transaction) async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        do {
            // Create subscription record
            let subscriptionData = SubscriptionData(
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
            
        } catch {
            print("SubscriptionService: Failed to store subscription: \(error)")
        }
    }
    
    private func updateUserSubscriptionStatus() async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        let tier: String
        switch subscriptionStatus {
        case .creator:
            tier = "creator"
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
    
    private func enableCreatorFeatures() async {
        print("SubscriptionService: Enabling creator features")
        
        // Enable team creation
        UserDefaults.standard.set(true, forKey: "features.team_creation")
        
        // Enable event creation
        UserDefaults.standard.set(true, forKey: "features.event_creation")
        
        // Enable analytics dashboard
        UserDefaults.standard.set(true, forKey: "features.team_analytics")
        
        // Enable leaderboard management
        UserDefaults.standard.set(true, forKey: "features.leaderboard_management")
        
        // Notify UI of changes
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func disableCreatorFeatures() async {
        print("SubscriptionService: Disabling creator features")
        
        UserDefaults.standard.set(false, forKey: "features.team_creation")
        UserDefaults.standard.set(false, forKey: "features.event_creation")
        UserDefaults.standard.set(false, forKey: "features.team_analytics")
        UserDefaults.standard.set(false, forKey: "features.leaderboard_management")
        
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func enableUserFeatures() async {
        print("SubscriptionService: Enabling user features")
        
        UserDefaults.standard.set(true, forKey: "features.team_subscriptions")
        UserDefaults.standard.set(true, forKey: "features.enhanced_rewards")
        UserDefaults.standard.set(true, forKey: "features.priority_competitions")
        
        NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
    }
    
    private func disableUserFeatures() async {
        print("SubscriptionService: Disabling user features")
        
        UserDefaults.standard.set(false, forKey: "features.team_subscriptions")
        UserDefaults.standard.set(false, forKey: "features.enhanced_rewards")
        UserDefaults.standard.set(false, forKey: "features.priority_competitions")
        
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
}

// MARK: - Data Models

enum SubscriptionStatus {
    case none
    case user  // Subscribed to one or more teams
    case creator // Can create and manage one team
    
    var displayName: String {
        switch self {
        case .none:
            return "Free"
        case .user:
            return "Team Member"
        case .creator:
            return "Team Creator"
        }
    }
    
    var badgeColor: UIColor {
        switch self {
        case .none:
            return .systemGray
        case .user:
            return .systemBlue
        case .creator:
            return .systemPurple
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

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productsNotLoaded
    case productNotFound
    case purchaseFailed
    case purchasePending
    case verificationFailed
    case restoreFailed
    
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
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}

