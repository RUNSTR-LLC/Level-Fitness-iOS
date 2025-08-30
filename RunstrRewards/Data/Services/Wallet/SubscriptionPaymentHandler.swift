import Foundation
import StoreKit

class SubscriptionPaymentHandler {
    
    // MARK: - Properties
    private let isDevelopmentMode: Bool
    private var products: [Product] = []
    
    init(isDevelopmentMode: Bool = false) {
        self.isDevelopmentMode = isDevelopmentMode
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async throws {
        guard !isDevelopmentMode else {
            print("SubscriptionPaymentHandler: Development mode - skipping App Store product loading")
            return
        }
        
        do {
            let products = try await Product.products(for: ["captain_monthly_subscription"])
            self.products = products
            print("SubscriptionPaymentHandler: ✅ Loaded \(products.count) products")
            
            for product in products {
                print("Product: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            print("SubscriptionPaymentHandler: ❌ Failed to load products: \(error)")
            throw SubscriptionError.productLoadFailed
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchaseCaptainSubscription() async throws -> StoreKit.Transaction? {
        guard !isDevelopmentMode else {
            print("SubscriptionPaymentHandler: Development mode - simulating successful purchase")
            return nil
        }
        
        guard let product = products.first(where: { $0.id == "captain_monthly_subscription" }) else {
            throw SubscriptionError.productNotFound
        }
        
        guard validateSubscriptionProduct(product) else {
            throw SubscriptionError.invalidProduct
        }
        
        return try await purchase(product)
    }
    
    func subscribeToTeam(_ teamId: String) async throws -> Bool {
        guard !isDevelopmentMode else {
            print("SubscriptionPaymentHandler: Development mode - simulating team subscription")
            return true
        }
        
        // For team subscriptions, we use a simpler flow since they're processed server-side
        // The actual payment processing would be handled by Stripe or similar
        print("SubscriptionPaymentHandler: Processing team subscription for \(teamId)")
        
        do {
            // Store subscription in Supabase
            try await SupabaseService.shared.createTeamSubscription(teamId: teamId)
            return true
        } catch {
            print("SubscriptionPaymentHandler: Failed to create team subscription: \(error)")
            throw SubscriptionError.purchaseFailed
        }
    }
    
    func unsubscribeFromTeam(_ teamId: String) async throws -> Bool {
        guard !isDevelopmentMode else {
            print("SubscriptionPaymentHandler: Development mode - simulating team unsubscription")
            return true
        }
        
        do {
            try await SupabaseService.shared.cancelTeamSubscription(teamId: teamId)
            return true
        } catch {
            print("SubscriptionPaymentHandler: Failed to cancel team subscription: \(error)")
            throw SubscriptionError.cancellationFailed
        }
    }
    
    private func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Process the verified transaction
                    try await handleVerifiedTransaction(transaction)
                    await transaction.finish()
                    return transaction
                    
                case .unverified(let transaction, let error):
                    print("SubscriptionPaymentHandler: ⚠️ Unverified transaction: \(error)")
                    throw SubscriptionError.verificationFailed
                }
                
            case .userCancelled:
                print("SubscriptionPaymentHandler: User cancelled purchase")
                throw SubscriptionError.userCancelled
                
            case .pending:
                print("SubscriptionPaymentHandler: Purchase pending")
                throw SubscriptionError.purchasePending
                
            @unknown default:
                throw SubscriptionError.unknownError
            }
        } catch {
            print("SubscriptionPaymentHandler: Purchase failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Transaction Processing
    
    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async throws {
        print("SubscriptionPaymentHandler: ✅ Processing verified transaction \(transaction.id)")
        
        // Store transaction in Supabase
        try await SupabaseService.shared.recordTransaction(
            transactionId: String(transaction.id),
            productId: transaction.productID,
            purchaseDate: transaction.purchaseDate,
            expiresDate: transaction.expirationDate
        )
        
        // Update user subscription status
        if let userId = AuthenticationService.shared.currentUserId {
            try await SupabaseService.shared.updateUserSubscriptionStatus(
                userId: userId,
                productId: transaction.productID,
                isActive: true,
                expiresAt: transaction.expirationDate
            )
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        guard !isDevelopmentMode else {
            print("SubscriptionPaymentHandler: Development mode - skipping purchase restoration")
            return
        }
        
        do {
            try await AppStore.sync()
            
            var hasActiveSubscription = false
            
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == "captain_monthly_subscription" {
                        try await handleVerifiedTransaction(transaction)
                        hasActiveSubscription = true
                    }
                    
                case .unverified(_, let error):
                    print("SubscriptionPaymentHandler: ⚠️ Unverified entitlement: \(error)")
                }
            }
            
            if hasActiveSubscription {
                print("SubscriptionPaymentHandler: ✅ Restored active subscription")
            } else {
                print("SubscriptionPaymentHandler: No active subscriptions found")
            }
            
        } catch {
            print("SubscriptionPaymentHandler: ❌ Failed to restore purchases: \(error)")
            throw SubscriptionError.restoreFailed
        }
    }
    
    // MARK: - Validation
    
    private func validateSubscriptionProduct(_ product: Product) -> Bool {
        guard product.type == .autoRenewable else {
            print("SubscriptionPaymentHandler: ❌ Product is not auto-renewable")
            return false
        }
        
        guard product.id == "captain_monthly_subscription" else {
            print("SubscriptionPaymentHandler: ❌ Invalid product ID")
            return false
        }
        
        return true
    }
    
    private func checkSubscriptionEligibility(for product: Product) async -> Bool {
        do {
            let eligibility = await product.subscription?.isEligibleForIntroOffer ?? false
            print("SubscriptionPaymentHandler: Intro offer eligibility: \(eligibility)")
            return true // Always allow purchase attempts
        }
    }
    
    // MARK: - Product Access
    
    func getCaptainSubscriptionProduct() -> Product? {
        return products.first(where: { $0.id == "captain_monthly_subscription" })
    }
    
    func getProducts() -> [Product] {
        return products
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case productLoadFailed
    case productNotFound
    case invalidProduct
    case purchaseFailed
    case verificationFailed
    case userCancelled
    case purchasePending
    case restoreFailed
    case cancellationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .productLoadFailed:
            return "Failed to load subscription products"
        case .productNotFound:
            return "Subscription product not found"
        case .invalidProduct:
            return "Invalid subscription product"
        case .purchaseFailed:
            return "Purchase failed"
        case .verificationFailed:
            return "Failed to verify purchase"
        case .userCancelled:
            return "Purchase cancelled by user"
        case .purchasePending:
            return "Purchase is pending approval"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .cancellationFailed:
            return "Failed to cancel subscription"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}