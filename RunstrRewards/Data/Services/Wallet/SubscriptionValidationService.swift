import Foundation
import StoreKit

class SubscriptionValidationService {
    static let shared = SubscriptionValidationService()
    
    // MARK: - Properties
    private let isDevelopmentMode: Bool
    
    private init(isDevelopmentMode: Bool = SubscriptionService.DEVELOPMENT_MODE) {
        self.isDevelopmentMode = isDevelopmentMode
    }
    
    // MARK: - Subscription Status
    
    func updateDetailedSubscriptionStatus() async throws {
        guard !isDevelopmentMode else {
            print("SubscriptionValidationService: Development mode - skipping status update")
            return
        }
        
        guard let userId = AuthenticationService.shared.currentUserId else {
            throw SubscriptionError.noUserAuthenticated
        }
        
        do {
            let status = await checkDetailedSubscriptionStatus()
            
            // Update user status in Supabase
            try await SupabaseService.shared.updateUserDetailedSubscriptionStatus(
                userId: userId,
                productId: "captain_monthly_subscription",
                isActive: status.isActive,
                expiresAt: status.expiresDate
            )
            
            print("SubscriptionValidationService: ✅ Updated subscription status - Active: \(status.isActive)")
            
        } catch {
            print("SubscriptionValidationService: ❌ Failed to update subscription status: \(error)")
            throw error
        }
    }
    
    func checkDetailedSubscriptionStatus() async -> DetailedSubscriptionStatus {
        guard !isDevelopmentMode else {
            print("SubscriptionValidationService: Development mode - returning mock active status")
            return DetailedDetailedSubscriptionStatus(
                isActive: true,
                productId: "captain_monthly_subscription",
                expiresDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                autoRenewEnabled: true,
                inGracePeriod: false
            )
        }
        
        do {
            // Check current entitlements
            for await result in Transaction.currentEntitlements {
                switch result {
                case .verified(let transaction):
                    if transaction.productID == "captain_monthly_subscription" {
                        let subscription = await getSubscriptionInfo(for: transaction)
                        return DetailedSubscriptionStatus(
                            isActive: !transaction.isRevoked,
                            productId: transaction.productID,
                            expiresDate: transaction.expirationDate,
                            autoRenewEnabled: subscription?.willAutoRenew ?? false,
                            inGracePeriod: subscription?.isInGracePeriod ?? false
                        )
                    }
                    
                case .unverified(_, let error):
                    print("SubscriptionValidationService: ⚠️ Unverified transaction: \(error)")
                }
            }
            
            // No active subscription found
            return DetailedSubscriptionStatus(
                isActive: false,
                productId: nil,
                expiresDate: nil,
                autoRenewEnabled: false,
                inGracePeriod: false
            )
            
        } catch {
            print("SubscriptionValidationService: Error checking subscription status: \(error)")
            return DetailedSubscriptionStatus(
                isActive: false,
                productId: nil,
                expiresDate: nil,
                autoRenewEnabled: false,
                inGracePeriod: false
            )
        }
    }
    
    func validateTeamSubscription(_ teamId: String) async throws -> Bool {
        guard !isDevelopmentMode else {
            print("SubscriptionValidationService: Development mode - returning true for team validation")
            return true
        }
        
        do {
            let subscription = try await SupabaseService.shared.fetchTeamSubscription(teamId: teamId)
            
            // Check if subscription is active and not expired
            let isActive = subscription.isActive && 
                          (subscription.expiresAt == nil || subscription.expiresAt! > Date())
            
            print("SubscriptionValidationService: Team \(teamId) subscription active: \(isActive)")
            return isActive
            
        } catch {
            print("SubscriptionValidationService: Failed to validate team subscription: \(error)")
            return false
        }
    }
    
    func validateUserTeamMembership(_ userId: String, teamId: String) async throws -> Bool {
        guard !isDevelopmentMode else {
            print("SubscriptionValidationService: Development mode - returning true for membership validation")
            return true
        }
        
        do {
            let membership = try await SupabaseService.shared.fetchTeamMembership(
                userId: userId,
                teamId: teamId
            )
            
            // Check if membership is active and payment is up to date
            let isValid = membership.isActive && 
                         (membership.lastPaymentDate == nil || 
                          Calendar.current.dateInterval(of: .month, for: membership.lastPaymentDate!)?.contains(Date()) ?? false)
            
            print("SubscriptionValidationService: User \(userId) membership in team \(teamId) valid: \(isValid)")
            return isValid
            
        } catch {
            print("SubscriptionValidationService: Failed to validate team membership: \(error)")
            return false
        }
    }
    
    // MARK: - Subscription Info
    
    private func getSubscriptionInfo(for transaction: StoreKit.Transaction) async -> Product.SubscriptionInfo? {
        do {
            let products = try await Product.products(for: [transaction.productID])
            return products.first?.subscription
        } catch {
            print("SubscriptionValidationService: Failed to get subscription info: \(error)")
            return nil
        }
    }
    
    func getSubscriptionDetails() async -> SubscriptionDetails? {
        let status = await checkDetailedSubscriptionStatus()
        
        guard status.isActive, let productId = status.productId else {
            return nil
        }
        
        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else { return nil }
            
            return SubscriptionDetails(
                productId: productId,
                displayName: product.displayName,
                displayPrice: product.displayPrice,
                isActive: status.isActive,
                expiresDate: status.expiresDate,
                autoRenewEnabled: status.autoRenewEnabled,
                inGracePeriod: status.inGracePeriod
            )
            
        } catch {
            print("SubscriptionValidationService: Failed to get subscription details: \(error)")
            return nil
        }
    }
    
    // MARK: - Grace Period & Renewal
    
    func isInGracePeriod() async -> Bool {
        let status = await checkDetailedSubscriptionStatus()
        return status.inGracePeriod
    }
    
    func daysUntilExpiration() async -> Int? {
        let status = await checkDetailedSubscriptionStatus()
        
        guard let expiresDate = status.expiresDate else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiresDate)
        return components.day
    }
    
    func shouldShowRenewalReminder() async -> Bool {
        guard let daysLeft = await daysUntilExpiration() else { return false }
        
        // Show reminder if less than 7 days left
        return daysLeft <= 7 && daysLeft > 0
    }
}

// MARK: - Data Models

struct DetailedSubscriptionStatus {
    let isActive: Bool
    let productId: String?
    let expiresDate: Date?
    let autoRenewEnabled: Bool
    let inGracePeriod: Bool
    
    var subscriptionStatus: SubscriptionStatus {
        if isActive {
            if let productId = productId, productId.contains("captain") {
                return .captain
            } else {
                return .member
            }
        } else {
            return .none
        }
    }
}

struct SubscriptionDetails {
    let productId: String
    let displayName: String
    let displayPrice: String
    let isActive: Bool
    let expiresDate: Date?
    let autoRenewEnabled: Bool
    let inGracePeriod: Bool
}

struct TeamSubscription: Codable {
    let teamId: String
    let isActive: Bool
    let expiresAt: Date?
    let createdAt: Date
    let lastPaymentDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case isActive = "is_active"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case lastPaymentDate = "last_payment_date"
    }
}

struct TeamMembership: Codable {
    let userId: String
    let teamId: String
    let isActive: Bool
    let lastPaymentDate: Date?
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case teamId = "team_id"
        case isActive = "is_active"
        case lastPaymentDate = "last_payment_date"
        case joinedAt = "joined_at"
    }
}

// MARK: - Extended Errors

extension SubscriptionError {
    static let noUserAuthenticated = SubscriptionError.unknownError
}