import Foundation
import StoreKit
import UIKit

@MainActor
class SubscriptionService: NSObject, ObservableObject {
    static let shared = SubscriptionService()
    
    // MARK: - Development Mode Flag
    static let DEVELOPMENT_MODE = true
    
    // MARK: - Published Properties
    @Published private(set) var captainSubscriptionActive = false
    @Published private(set) var activeTeamSubscriptions: [TeamSubscriptionInfo] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .none
    @Published private(set) var isLoading = false
    
    // MARK: - Private Properties
    private var products: [Product] = []
    private let validationService = SubscriptionValidationService.shared
    private let paymentHandler: SubscriptionPaymentHandler
    
    // MARK: - Transaction Listener
    private var transactionListener: Task<Void, Error>?
    
    // Product IDs
    enum ProductID {
        static let captainSubscription = "com.runstrrewards.captain"
        static let teamSubscription = "com.runstrrewards.team.monthly"
    }
    
    private override init() {
        self.paymentHandler = SubscriptionPaymentHandler(isDevelopmentMode: Self.DEVELOPMENT_MODE)
        super.init()
        
        startTransactionListener()
        
        Task {
            await initializeService()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Initialization
    
    private func initializeService() async {
        isLoading = true
        
        do {
            try await loadProducts()
            try await updateSubscriptionStatus()
        } catch {
            print("SubscriptionService: Failed to initialize: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Public Interface
    
    func loadProducts() async throws {
        guard !Self.DEVELOPMENT_MODE else {
            print("SubscriptionService: Development mode - skipping App Store product loading")
            return
        }
        
        do {
            let products = try await Product.products(for: ["captain_monthly_subscription"])
            self.products = products
            print("SubscriptionService: ✅ Loaded \(products.count) products")
        } catch {
            print("SubscriptionService: ❌ Failed to load products: \(error)")
            throw error
        }
    }
    
    func purchaseCaptainSubscription() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let transaction = try await paymentHandler.purchaseCaptainSubscription()
            if transaction != nil || Self.DEVELOPMENT_MODE {
                captainSubscriptionActive = true
                subscriptionStatus = .captain
                return true
            }
            return false
        } catch {
            print("SubscriptionService: Captain subscription purchase failed: \(error)")
            throw error
        }
    }
    
    func subscribeToTeam(_ teamId: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = try await paymentHandler.subscribeToTeam(teamId)
            if success {
                await loadActiveTeamSubscriptions()
            }
            return success
        } catch {
            print("SubscriptionService: Team subscription failed: \(error)")
            throw error
        }
    }
    
    func unsubscribeFromTeam(_ teamId: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = try await paymentHandler.unsubscribeFromTeam(teamId)
            if success {
                await loadActiveTeamSubscriptions()
            }
            return success
        } catch {
            print("SubscriptionService: Team unsubscription failed: \(error)")
            throw error
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await paymentHandler.restorePurchases()
        try await updateSubscriptionStatus()
    }
    
    // MARK: - Status Management
    
    func updateSubscriptionStatus() async throws {
        try await validationService.updateSubscriptionStatus()
        
        let status = await validationService.checkSubscriptionStatus()
        captainSubscriptionActive = status.isActive
        subscriptionStatus = status.isActive ? .captain : .none
        
        await loadActiveTeamSubscriptions()
    }
    
    func checkSubscriptionStatus() async -> DetailedSubscriptionStatus {
        return await validationService.checkSubscriptionStatus()
    }
    
    func getActiveTeamSubscriptionCount() -> Int {
        return activeTeamSubscriptions.count
    }
    
    func getTotalMonthlyTeamCost() -> Double {
        // Assuming each team subscription costs $1.99 per month
        return Double(activeTeamSubscriptions.count) * 1.99
    }
    
    func hasExistingTeamAsync() async throws -> Bool {
        guard let userId = AuthenticationService.shared.currentUserId else { 
            throw NSError(domain: "SubscriptionService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            // Check if user is captain of any team
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: userId)
            return teams.contains { team in
                team.captainId == userId
            }
        } catch {
            throw error
        }
    }
    
    private func loadActiveTeamSubscriptions() async {
        guard let userId = AuthenticationService.shared.currentUserId else { return }
        
        do {
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: userId)
            var activeSubscriptions: [TeamSubscriptionInfo] = []
            
            for team in teams {
                let isValid = try await validationService.validateTeamSubscription(team.id)
                if isValid {
                    activeSubscriptions.append(TeamSubscriptionInfo(
                        teamId: team.id,
                        teamName: team.name,
                        isActive: true
                    ))
                }
            }
            
            self.activeTeamSubscriptions = activeSubscriptions
        } catch {
            print("SubscriptionService: Failed to load team subscriptions: \(error)")
        }
    }
    
    // MARK: - Validation
    
    func validateTeamSubscription(_ teamId: String) async -> Bool {
        do {
            return try await validationService.validateTeamSubscription(teamId)
        } catch {
            print("SubscriptionService: Team validation failed: \(error)")
            return false
        }
    }
    
    func validateUserTeamMembership(_ userId: String, teamId: String) async -> Bool {
        do {
            return try await validationService.validateUserTeamMembership(userId, teamId: teamId)
        } catch {
            print("SubscriptionService: Membership validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Product Access
    
    func getCaptainSubscriptionProduct() -> Product? {
        return paymentHandler.getCaptainSubscriptionProduct()
    }
    
    func getSubscriptionDetails() async -> SubscriptionDetails? {
        return await validationService.getSubscriptionDetails()
    }
    
    func shouldShowRenewalReminder() async -> Bool {
        return await validationService.shouldShowRenewalReminder()
    }
    
    func getTeamSubscriptionPrice() -> Double {
        return 1.99 // Team subscription price in USD
    }
    
    func isSubscribedToTeam(_ teamId: String) -> Bool {
        return activeTeamSubscriptions.contains { $0.teamId == teamId && $0.isActive }
    }
    
    func openManageSubscriptions() async {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Transaction Listener
    
    private func startTransactionListener() {
        transactionListener = Task {
            for await result in StoreKit.Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await handleTransaction(transaction)
                    
                case .unverified(_, let error):
                    print("SubscriptionService: Unverified transaction: \(error)")
                }
            }
        }
    }
    
    private func handleTransaction(_ transaction: StoreKit.Transaction) async {
        print("SubscriptionService: Handling transaction update for \(transaction.productID)")
        
        do {
            try await validationService.updateSubscriptionStatus()
            
            // Update UI state
            let status = await validationService.checkSubscriptionStatus()
            captainSubscriptionActive = status.isActive
            subscriptionStatus = status.isActive ? .captain : .none
            
            await loadActiveTeamSubscriptions()
            
        } catch {
            print("SubscriptionService: Failed to handle transaction update: \(error)")
        }
    }
    
    // MARK: - Development Helper Methods
    
    #if DEBUG
    func resetDevelopmentState() {
        guard Self.DEVELOPMENT_MODE else { return }
        
        captainSubscriptionActive = false
        activeTeamSubscriptions = []
        subscriptionStatus = .none
        
        print("SubscriptionService: Development state reset")
    }
    
    func simulateCaptainSubscription() {
        guard Self.DEVELOPMENT_MODE else { return }
        
        captainSubscriptionActive = true
        subscriptionStatus = .captain
        
        print("SubscriptionService: Simulated captain subscription activation")
    }
    #endif
}

// MARK: - Data Models

enum SubscriptionStatus {
    case none
    case captain
    case member
    case user
}

struct TeamSubscriptionInfo {
    let teamId: String
    let teamName: String
    let isActive: Bool
}

// MARK: - Notifications

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
    static let teamSubscriptionUpdated = Notification.Name("teamSubscriptionUpdated")
}