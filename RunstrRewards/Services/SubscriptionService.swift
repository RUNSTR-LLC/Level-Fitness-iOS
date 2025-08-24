import Foundation
import StoreKit
import UIKit

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // Product IDs (must match App Store Connect)
    enum ProductID {
        static let captainSubscription = "com.runstrrewards.captain" // $19.99/month captain subscription
        static let teamSubscription = "com.runstrrewards.team.monthly" // $1.99/month team subscription
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
        
        print("SubscriptionService: Loading products...")
        
        do {
            guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil else {
                print("SubscriptionService: Skipping product load in Preview mode")
                return
            }
            
            let products = try await Product.products(for: [
                ProductID.captainSubscription,
                ProductID.teamSubscription
            ])
            
            // Validate that products are properly configured as subscriptions
            let validProducts = products.filter { validateSubscriptionProduct($0) }
            if validProducts.count != products.count {
                print("SubscriptionService: WARNING - Some products failed subscription validation")
            }
            
            print("SubscriptionService: Loaded \(products.count) products from StoreKit")
            availableProducts = products
            
            if products.isEmpty {
                print("SubscriptionService: WARNING - No products loaded from StoreKit")
                print("SubscriptionService: Check StoreKit configuration file")
            }
            
            for product in validProducts {
                switch product.id {
                case ProductID.captainSubscription:
                    captainProduct = product
                    print("SubscriptionService: Captain subscription loaded - \(product.displayPrice)")
                case ProductID.teamSubscription:
                    teamProduct = product
                    print("SubscriptionService: Team subscription loaded - \(product.displayPrice)")
                default:
                    print("SubscriptionService: Unknown product loaded: \(product.id)")
                    break
                }
            }
            
            // Check current subscription status
            try await updateSubscriptionStatus()
            
        } catch {
            print("SubscriptionService: Failed to load products: \(error)")
            print("SubscriptionService: Error details: \(error.localizedDescription)")
            
            // Try to use cached subscription status if products can't be loaded
            let cachedStatus = loadCachedSubscriptionStatus()
            if cachedStatus.isValid && !cachedStatus.isExpired {
                print("SubscriptionService: Using cached subscription status due to product loading failure")
                captainSubscriptionActive = cachedStatus.hasCaptain
                activeTeamSubscriptions = cachedStatus.teamSubscriptions
                
                if cachedStatus.hasCaptain {
                    subscriptionStatus = .captain
                } else if !cachedStatus.teamSubscriptions.isEmpty {
                    subscriptionStatus = .user
                } else {
                    subscriptionStatus = .none
                }
                
                // Don't throw error if we have valid cached data
                return
            }
            
            throw SubscriptionError.productsNotLoaded
        }
    }
    
    // MARK: - Error Handling
    
    enum SubscriptionError: LocalizedError {
        case productNotFound
        case productsNotLoaded
        case purchaseFailed(String)
        case purchasePending
        case verificationFailed
        case networkError
        case invalidReceipt
        case alreadySubscribed
        case subscriptionNotFound
        case userNotFound
        
        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "Subscription product not found. Please try again later."
            case .productsNotLoaded:
                return "Products not loaded. Please try again."
            case .purchaseFailed(let message):
                return "Purchase failed: \(message)"
            case .purchasePending:
                return "Purchase is pending. Please wait."
            case .verificationFailed:
                return "Unable to verify purchase. Please contact support."
            case .networkError:
                return "Network error. Please check your connection."
            case .invalidReceipt:
                return "Invalid receipt. Please restore purchases."
            case .alreadySubscribed:
                return "Already subscribed to this service."
            case .subscriptionNotFound:
                return "Subscription not found."
            case .userNotFound:
                return "User not found. Please sign in again."
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchaseCaptainSubscription() async throws -> StoreKit.Transaction? {
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
            do {
                try await storeTeamSubscription(teamId: teamId, transaction: transaction)
            } catch {
                print("SubscriptionService: Failed to store team subscription in database: \(error)")
                // Continue with local state update even if database storage fails
            }
            
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
        // Mark as inactive in our database
        if let userId = AuthenticationService.shared.currentUserId {
            do {
                try await updateTeamSubscriptionStatus(
                    userId: userId,
                    transactionId: subscription.transactionId,
                    status: "cancelled",
                    expirationDate: nil
                )
            } catch {
                print("SubscriptionService: Failed to update team subscription status: \(error)")
            }
        }
        
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
            try? await updateSubscriptionStatus()
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
            throw SubscriptionError.purchaseFailed("Unknown error")
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Sync with App Store to restore purchases
        try await AppStore.sync()
        
        // Update subscription status
        try? await updateSubscriptionStatus()
        
        print("SubscriptionService: Purchases restored")
    }
    
    // MARK: - Subscription Validation
    
    private func validateSubscriptionProduct(_ product: Product) -> Bool {
        // Ensure product is a recurring subscription
        guard product.type == .autoRenewable else {
            print("SubscriptionService: Product \(product.id) is not a recurring subscription")
            return false
        }
        
        // Validate subscription group
        if let subscription = product.subscription {
            print("SubscriptionService: Product \(product.id) belongs to subscription group \(subscription.subscriptionGroupID)")
            return true
        }
        
        print("SubscriptionService: Product \(product.id) has no subscription information")
        return false
    }
    
    private func checkSubscriptionEligibility(for product: Product) async -> Bool {
        do {
            let eligibility = await product.subscription?.isEligibleForIntroOffer ?? false
            print("SubscriptionService: Intro offer eligibility for \(product.id): \(eligibility)")
            return eligibility
        }
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async throws {
        print("SubscriptionService: Starting subscription status update")
        
        var hasCaptainSubscription = false
        var teamSubscriptions: [TeamSubscriptionInfo] = []
        
        do {
            // Try to load cached status first
            let cachedStatus = loadCachedSubscriptionStatus()
            print("SubscriptionService: Loaded cached status - Captain: \(cachedStatus.hasCaptain), Teams: \(cachedStatus.teamCount)")
            
            // Check all current entitlements
            var entitlementCount = 0
            for await result in StoreKit.Transaction.currentEntitlements {
                entitlementCount += 1
                if case .verified(let transaction) = result {
                    print("SubscriptionService: Processing verified transaction \(transaction.id) for product \(transaction.productID)")
                    
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
                            print("SubscriptionService: Active captain subscription found")
                        }
                    case ProductID.teamSubscription:
                        if transaction.revocationDate == nil && isSubscriptionActive(transaction) {
                            // Get team subscription details from Supabase with fallback
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
                                        print("SubscriptionService: Team subscription found for team \(teamSub.teamId)")
                                    } else {
                                        print("SubscriptionService: No team subscription details found in Supabase")
                                    }
                                } catch {
                                    print("SubscriptionService: Failed to fetch team subscription details: \(error)")
                                    // Fall back to basic subscription info without team details
                                    let basicSubscriptionInfo = TeamSubscriptionInfo(
                                        teamId: "team_\(String(transaction.id).suffix(8))", // Temporary team ID
                                        transactionId: String(transaction.id),
                                        purchaseDate: transaction.purchaseDate,
                                        expirationDate: transaction.expirationDate,
                                        isActive: isSubscriptionActive(transaction)
                                    )
                                    teamSubscriptions.append(basicSubscriptionInfo)
                                    print("SubscriptionService: Using fallback team subscription info")
                                }
                            }
                        }
                    default:
                        print("SubscriptionService: Unknown product ID: \(transaction.productID)")
                        break
                    }
                } else {
                    print("SubscriptionService: Unverified transaction found")
                }
            }
            
            print("SubscriptionService: Processed \(entitlementCount) entitlements")
            
        } catch {
            print("SubscriptionService: Error checking entitlements: \(error)")
            // Fall back to cached status if available
            let cachedStatus = loadCachedSubscriptionStatus()
            if cachedStatus.isValid {
                print("SubscriptionService: Using cached subscription status due to error")
                hasCaptainSubscription = cachedStatus.hasCaptain
                teamSubscriptions = cachedStatus.teamSubscriptions
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
        
        // Cache the updated status
        cacheSubscriptionStatus(hasCaptain: hasCaptainSubscription, teamSubscriptions: teamSubscriptions)
        
        // Update user profile in database (with error handling)
        do {
            try await updateUserSubscriptionStatus()
        } catch {
            print("SubscriptionService: Failed to update user subscription status in database: \(error)")
            // Don't fail the entire operation for this
        }
        
        print("SubscriptionService: Status updated - Captain: \(hasCaptainSubscription), Team Subscriptions: \(teamSubscriptions.count)")
    }
    
    func checkSubscriptionStatus() async -> SubscriptionStatus {
        print("SubscriptionService: Checking subscription status...")
        
        // Try to update from live data first
        do {
            try await updateSubscriptionStatus()
            print("SubscriptionService: Successfully updated subscription status from live data")
        } catch {
            print("SubscriptionService: Failed to update from live data: \(error)")
            
            // Fall back to cached data
            let cachedStatus = loadCachedSubscriptionStatus()
            if cachedStatus.isValid {
                print("SubscriptionService: Using cached subscription status")
                
                captainSubscriptionActive = cachedStatus.hasCaptain
                activeTeamSubscriptions = cachedStatus.teamSubscriptions
                
                if cachedStatus.hasCaptain {
                    subscriptionStatus = .captain
                } else if !cachedStatus.teamSubscriptions.isEmpty {
                    subscriptionStatus = .user
                } else {
                    subscriptionStatus = .none
                }
                
                if cachedStatus.isExpired {
                    print("SubscriptionService: WARNING - Using expired cached data")
                }
            } else {
                print("SubscriptionService: No cached data available, using default status")
                subscriptionStatus = .none
                captainSubscriptionActive = false
                activeTeamSubscriptions = []
            }
        }
        
        print("SubscriptionService: Final status: \(subscriptionStatus)")
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
        print("SubscriptionService: Transaction update - \(transaction.productID), ID: \(transaction.id)")
        
        // Validate transaction before processing
        let isValid = await verifyReceiptData(transaction: transaction)
        guard isValid else {
            print("SubscriptionService: Invalid transaction \(transaction.id), ignoring update")
            return
        }
        
        // Log transaction details for debugging
        print("SubscriptionService: Transaction details - Purchased: \(transaction.purchaseDate), Expires: \(transaction.expirationDate?.description ?? "N/A")")
        
        // Update subscription status
        try? await updateSubscriptionStatus()
        
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
        // Check if subscription was revoked
        guard transaction.revocationDate == nil else {
            print("SubscriptionService: Transaction \(transaction.id) was revoked on \(transaction.revocationDate!)")
            return false
        }
        
        // Check if subscription is currently active with grace period
        if let expirationDate = transaction.expirationDate {
            // Add 24-hour grace period for subscription renewals
            let gracePeriod: TimeInterval = 24 * 60 * 60 // 24 hours
            let effectiveExpirationDate = expirationDate.addingTimeInterval(gracePeriod)
            
            let isActive = effectiveExpirationDate > Date()
            let isInGracePeriod = Date() > expirationDate && Date() <= effectiveExpirationDate
            
            if isInGracePeriod {
                print("SubscriptionService: Transaction \(transaction.id) in grace period, expires \(expirationDate)")
            }
            
            return isActive
        }
        
        // If no expiration date, verify it's a valid subscription product
        let isValidProduct = transaction.productID == ProductID.captainSubscription || 
                            transaction.productID == ProductID.teamSubscription
        
        if !isValidProduct {
            print("SubscriptionService: Transaction \(transaction.id) for unknown product \(transaction.productID)")
        }
        
        return isValidProduct
    }
    
    // MARK: - Server-Side Verification (Production)
    
    private func verifyTransactionWithApple(transaction: StoreKit.Transaction) async throws -> Bool {
        // In production, implement server-side verification
        // This involves sending the transaction receipt to Apple's verification servers
        // For now, return true for local development
        
        print("SubscriptionService: Server-side verification would be implemented here for production")
        return true
    }
    
    // MARK: - StoreKit Validation
    
    func validateStoreKitConfiguration() async -> Bool {
        print("SubscriptionService: 🧪 Validating StoreKit configuration...")
        
        do {
            // Test product loading
            let products = try await Product.products(for: [
                ProductID.captainSubscription,
                ProductID.teamSubscription
            ])
            
            print("SubscriptionService: ✅ Loaded \(products.count) products from StoreKit")
            
            // Validate each product
            var validProductCount = 0
            for product in products {
                print("SubscriptionService: 🔍 Validating product: \(product.id)")
                print("  - Display Name: \(product.displayName)")
                print("  - Price: \(product.displayPrice)")
                print("  - Type: \(product.type)")
                
                // Check if it's a proper subscription
                if validateSubscriptionProduct(product) {
                    validProductCount += 1
                    print("  - ✅ Valid subscription product")
                    
                    // Check subscription details
                    if let subscription = product.subscription {
                        print("  - Subscription Group: \(subscription.subscriptionGroupID)")
                        print("  - Period: \(subscription.subscriptionPeriod)")
                    }
                } else {
                    print("  - ❌ Invalid subscription product")
                }
            }
            
            let isValid = validProductCount == 2 && products.count == 2
            print("SubscriptionService: \(isValid ? "✅" : "❌") StoreKit validation result: \(validProductCount)/2 valid products")
            
            return isValid
            
        } catch {
            print("SubscriptionService: ❌ StoreKit validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Manage Subscriptions
    
    func openManageSubscriptions() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("SubscriptionService: Failed to open manage subscriptions: \(error)")
                
                // Fallback to custom subscription management UI
                await showCustomSubscriptionManagement()
            }
        }
    }
    
    private func showCustomSubscriptionManagement() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let currentStatus = await checkSubscriptionStatus()
        let statusText: String
        let actionTitle: String
        
        switch currentStatus {
        case .captain:
            statusText = "You have an active Captain subscription ($19.99/month) which allows you to create and manage teams."
            actionTitle = "Continue"
        case .user:
            statusText = "You have active team subscriptions. You can manage individual team subscriptions from the Teams page."
            actionTitle = "Continue"
        case .none:
            statusText = "You don't have any active subscriptions. You can subscribe to teams or upgrade to Captain status to create your own teams."
            actionTitle = "Continue"
        }
        
        let alert = UIAlertController(
            title: "Subscription Status",
            message: statusText,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: actionTitle, style: .default))
        
        if currentStatus == .none {
            alert.addAction(UIAlertAction(title: "Upgrade to Captain", style: .default) { _ in
                Task {
                    _ = try? await self.purchaseCaptainSubscriptionBool()
                }
            })
        }
        
        rootViewController.present(alert, animated: true)
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
        // For now, return false to allow team creation during development
        return false
    }
    
    func hasExistingTeamAsync() async throws -> Bool {
        guard let userId = AuthenticationService.shared.currentUserId else { return false }
        
        do {
            let teamCount = try await TeamDataService.shared.getCaptainTeamCount(captainId: userId)
            return teamCount > 0
        } catch {
            print("SubscriptionService: Failed to check existing teams: \(error)")
            return false
        }
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
        guard let userId = AuthenticationService.shared.currentUserId else { 
            print("SubscriptionService: No user ID available for storing subscription")
            return 
        }
        
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
        do {
            try await TransactionDataService.shared.storeSubscriptionData(subscriptionData)
            print("SubscriptionService: Successfully stored subscription in database for user \(userId)")
        } catch {
            print("SubscriptionService: Failed to store subscription in database: \(error)")
            // Don't throw error - subscription still processed locally
        }
    }
    
    private func updateUserSubscriptionStatus() async throws {
        guard let userId = AuthenticationService.shared.currentUserId else { 
            print("SubscriptionService: No user ID available for updating subscription status")
            return 
        }
        
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
        do {
            try await TransactionDataService.shared.updateUserSubscriptionTier(userId: userId, tier: tier)
            print("SubscriptionService: Successfully updated user subscription tier to: \(tier) for user \(userId)")
        } catch {
            print("SubscriptionService: Failed to update user subscription tier: \(error)")
            // Don't fail the entire operation for this
        }
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
            throw SubscriptionError.purchaseFailed("Unknown error")
        }
    }
    */
    
    // MARK: - Cached Status Management
    
    private struct CachedSubscriptionStatus {
        let hasCaptain: Bool
        let teamSubscriptions: [TeamSubscriptionInfo]
        let timestamp: Date
        let isValid: Bool
        
        var teamCount: Int {
            return teamSubscriptions.count
        }
        
        // Consider cache valid for 24 hours
        var isExpired: Bool {
            return Date().timeIntervalSince(timestamp) > 86400
        }
    }
    
    private func loadCachedSubscriptionStatus() -> CachedSubscriptionStatus {
        let defaults = UserDefaults.standard
        
        // Load cached values
        let hasCaptain = defaults.bool(forKey: "cache.subscription.hasCaptain")
        let timestamp = defaults.object(forKey: "cache.subscription.timestamp") as? Date ?? Date.distantPast
        
        // Load cached team subscriptions
        var teamSubscriptions: [TeamSubscriptionInfo] = []
        if let data = defaults.data(forKey: "cache.subscription.teamSubscriptions") {
            do {
                teamSubscriptions = try JSONDecoder().decode([TeamSubscriptionInfo].self, from: data)
            } catch {
                print("SubscriptionService: Failed to decode cached team subscriptions: \(error)")
            }
        }
        
        let cached = CachedSubscriptionStatus(
            hasCaptain: hasCaptain,
            teamSubscriptions: teamSubscriptions,
            timestamp: timestamp,
            isValid: timestamp != Date.distantPast
        )
        
        if cached.isExpired {
            print("SubscriptionService: Cached subscription status is expired")
        }
        
        return cached
    }
    
    private func cacheSubscriptionStatus(hasCaptain: Bool, teamSubscriptions: [TeamSubscriptionInfo]) {
        let defaults = UserDefaults.standard
        
        // Cache basic values
        defaults.set(hasCaptain, forKey: "cache.subscription.hasCaptain")
        defaults.set(Date(), forKey: "cache.subscription.timestamp")
        
        // Cache team subscriptions
        do {
            let data = try JSONEncoder().encode(teamSubscriptions)
            defaults.set(data, forKey: "cache.subscription.teamSubscriptions")
        } catch {
            print("SubscriptionService: Failed to cache team subscriptions: \(error)")
        }
        
        defaults.synchronize()
        print("SubscriptionService: Cached subscription status - Captain: \(hasCaptain), Teams: \(teamSubscriptions.count)")
    }
    
    private func clearCachedSubscriptionStatus() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cache.subscription.hasCaptain")
        defaults.removeObject(forKey: "cache.subscription.teamSubscriptions")
        defaults.removeObject(forKey: "cache.subscription.timestamp")
        defaults.synchronize()
        print("SubscriptionService: Cleared cached subscription status")
    }
    
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
        
        try await TransactionDataService.shared.createTeamSubscription(subscription)
        print("SubscriptionService: Successfully stored team subscription in database")
    }
    
    private func fetchTeamSubscriptionFromSupabase(userId: String, transactionId: String) async throws -> DatabaseTeamSubscription? {
        return try await TransactionDataService.shared.fetchTeamSubscription(userId: userId, transactionId: transactionId)
    }
    
    private func updateTeamSubscriptionStatus(userId: String, transactionId: String, status: String, expirationDate: Date?) async throws {
        try await TransactionDataService.shared.updateTeamSubscriptionStatus(
            userId: userId,
            transactionId: transactionId,
            status: status,
            expirationDate: expirationDate
        )
        print("SubscriptionService: Successfully updated team subscription status to \(status)")
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
            return UIColor.systemOrange
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

