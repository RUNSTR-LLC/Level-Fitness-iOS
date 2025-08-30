import Foundation

// MARK: - Payment Queue Manager

class PaymentQueueManager: ObservableObject {
    static let shared = PaymentQueueManager()
    
    // MARK: - Properties
    
    // In-memory storage for MVP (can move to Supabase later)
    @Published private var allPayments: [PendingPayment] = []
    
    private let notificationCenter = NotificationCenter.default
    
    // MARK: - Initialization
    
    private init() {
        print("PaymentQueueManager: Initializing payment queue")
        loadPersistedPayments()
    }
    
    // MARK: - Public Methods
    
    /// Add a new pending payment to the queue
    func addPendingPayment(_ payment: PendingPayment) {
        print("PaymentQueueManager: Adding pending payment - \(payment.title) for \(payment.totalAmount) sats")
        
        allPayments.append(payment)
        persistPayments()
        
        // Notify observers that payment queue changed
        notificationCenter.post(name: .paymentQueueDidChange, object: nil, userInfo: [
            "teamId": payment.teamId,
            "action": "added",
            "paymentId": payment.id
        ])
    }
    
    /// Get all pending payments for a specific team
    func getPendingPayments(for teamId: String) -> [PendingPayment] {
        let pending = allPayments.filter { 
            $0.teamId == teamId && $0.status == .pending 
        }.sorted { $0.createdAt > $1.createdAt }
        
        print("PaymentQueueManager: Found \(pending.count) pending payments for team \(teamId)")
        return pending
    }
    
    /// Get all completed payments for a specific team
    func getCompletedPayments(for teamId: String) -> [PendingPayment] {
        let completed = allPayments.filter { 
            $0.teamId == teamId && $0.status == .completed 
        }.sorted { ($0.paidAt ?? Date.distantPast) > ($1.paidAt ?? Date.distantPast) }
        
        print("PaymentQueueManager: Found \(completed.count) completed payments for team \(teamId)")
        return completed
    }
    
    /// Get count of pending payments for a team (for badge display)
    func getPendingCount(for teamId: String) -> Int {
        let count = allPayments.filter { 
            $0.teamId == teamId && $0.status == .pending 
        }.count
        
        return count
    }
    
    /// Get total pending amount for a team
    func getPendingAmount(for teamId: String) -> Int {
        let totalAmount = allPayments
            .filter { $0.teamId == teamId && $0.status == .pending }
            .reduce(0) { $0 + $1.totalAmount }
        
        return totalAmount
    }
    
    /// Mark a payment as processing
    func markPaymentProcessing(_ paymentId: String) {
        guard let index = allPayments.firstIndex(where: { $0.id == paymentId }) else {
            print("PaymentQueueManager: Payment not found: \(paymentId)")
            return
        }
        
        allPayments[index].status = .processing
        persistPayments()
        
        print("PaymentQueueManager: Marked payment \(paymentId) as processing")
        
        notificationCenter.post(name: .paymentStatusDidChange, object: nil, userInfo: [
            "paymentId": paymentId,
            "status": "processing"
        ])
    }
    
    /// Mark a payment as completed
    func markPaymentCompleted(_ paymentId: String) {
        guard let index = allPayments.firstIndex(where: { $0.id == paymentId }) else {
            print("PaymentQueueManager: Payment not found: \(paymentId)")
            return
        }
        
        allPayments[index].status = .completed
        allPayments[index].paidAt = Date()
        persistPayments()
        
        let payment = allPayments[index]
        print("PaymentQueueManager: Marked payment \(paymentId) as completed - \(payment.title)")
        
        notificationCenter.post(name: .paymentStatusDidChange, object: nil, userInfo: [
            "paymentId": paymentId,
            "status": "completed",
            "teamId": payment.teamId
        ])
    }
    
    /// Mark a payment as failed
    func markPaymentFailed(_ paymentId: String, error: Error?) {
        guard let index = allPayments.firstIndex(where: { $0.id == paymentId }) else {
            print("PaymentQueueManager: Payment not found: \(paymentId)")
            return
        }
        
        allPayments[index].status = .failed
        persistPayments()
        
        let payment = allPayments[index]
        print("PaymentQueueManager: Marked payment \(paymentId) as failed - \(payment.title)")
        
        notificationCenter.post(name: .paymentStatusDidChange, object: nil, userInfo: [
            "paymentId": paymentId,
            "status": "failed",
            "teamId": payment.teamId,
            "error": error?.localizedDescription
        ])
    }
    
    /// Get a specific payment by ID
    func getPayment(by paymentId: String) -> PendingPayment? {
        return allPayments.first { $0.id == paymentId }
    }
    
    /// Remove a payment from the queue (for testing or admin purposes)
    func removePayment(_ paymentId: String) {
        guard let index = allPayments.firstIndex(where: { $0.id == paymentId }) else {
            print("PaymentQueueManager: Payment not found: \(paymentId)")
            return
        }
        
        let removedPayment = allPayments.remove(at: index)
        persistPayments()
        
        print("PaymentQueueManager: Removed payment \(paymentId) - \(removedPayment.title)")
        
        notificationCenter.post(name: .paymentQueueDidChange, object: nil, userInfo: [
            "teamId": removedPayment.teamId,
            "action": "removed",
            "paymentId": paymentId
        ])
    }
    
    /// Clear all completed payments for a team (cleanup)
    func clearCompletedPayments(for teamId: String) {
        let beforeCount = allPayments.count
        allPayments.removeAll { $0.teamId == teamId && $0.status == .completed }
        let removed = beforeCount - allPayments.count
        
        if removed > 0 {
            persistPayments()
            print("PaymentQueueManager: Cleared \(removed) completed payments for team \(teamId)")
            
            notificationCenter.post(name: .paymentQueueDidChange, object: nil, userInfo: [
                "teamId": teamId,
                "action": "cleared_completed"
            ])
        }
    }
    
    // MARK: - Analytics & Reporting
    
    /// Get payment statistics for a team
    func getPaymentStats(for teamId: String) -> PaymentStats {
        let teamPayments = allPayments.filter { $0.teamId == teamId }
        
        let totalPaid = teamPayments
            .filter { $0.status == .completed }
            .reduce(0) { $0 + $1.totalAmount }
        
        let totalPending = teamPayments
            .filter { $0.status == .pending }
            .reduce(0) { $0 + $1.totalAmount }
        
        return PaymentStats(
            totalPaid: totalPaid,
            totalPending: totalPending,
            completedCount: teamPayments.filter { $0.status == .completed }.count,
            pendingCount: teamPayments.filter { $0.status == .pending }.count,
            failedCount: teamPayments.filter { $0.status == .failed }.count
        )
    }
    
    // MARK: - Private Methods
    
    private func persistPayments() {
        // For MVP, store in UserDefaults
        // Later can move to Supabase or Core Data
        do {
            let data = try JSONEncoder().encode(allPayments)
            UserDefaults.standard.set(data, forKey: "PendingPayments")
            print("PaymentQueueManager: Persisted \(allPayments.count) payments")
        } catch {
            print("PaymentQueueManager: Failed to persist payments: \(error)")
        }
    }
    
    private func loadPersistedPayments() {
        guard let data = UserDefaults.standard.data(forKey: "PendingPayments") else {
            print("PaymentQueueManager: No persisted payments found")
            return
        }
        
        do {
            allPayments = try JSONDecoder().decode([PendingPayment].self, from: data)
            print("PaymentQueueManager: Loaded \(allPayments.count) persisted payments")
        } catch {
            print("PaymentQueueManager: Failed to load persisted payments: \(error)")
            allPayments = []
        }
    }
}

// MARK: - Supporting Models

struct PaymentStats {
    let totalPaid: Int
    let totalPending: Int
    let completedCount: Int
    let pendingCount: Int
    let failedCount: Int
    
    var totalProcessed: Int {
        return totalPaid + totalPending
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let paymentQueueDidChange = Notification.Name("PaymentQueueDidChange")
    static let paymentStatusDidChange = Notification.Name("PaymentStatusDidChange")
}

// MARK: - Payment Queue Manager Extensions

extension PaymentQueueManager {
    
    /// Debug method to add sample payments for testing
    func addSamplePayments(for teamId: String) {
        print("PaymentQueueManager: Adding sample payments for testing")
        
        // Sample event payment
        let eventPayment = PendingPayment.forEvent(
            teamId: teamId,
            eventName: "5K December Race",
            eventId: "test_event_1",
            endDate: Date(),
            winners: [
                ("user_1", "John Doe", 1, 2500),
                ("user_2", "Sarah Miller", 2, 1500),
                ("user_3", "Mike Roberts", 3, 1000)
            ]
        )
        addPendingPayment(eventPayment)
        
        // Sample challenge payment
        let challengePayment = PendingPayment.forChallenge(
            teamId: teamId,
            challengerId: "user_4",
            challengerName: "Alex Johnson",
            challengedId: "user_5",
            challengedName: "Lisa Chen",
            winnerId: "user_4",
            winnerName: "Alex Johnson",
            amount: 800,
            challengeId: "test_challenge_1"
        )
        addPendingPayment(challengePayment)
        
        // Sample leaderboard payment
        let leaderboardPayment = PendingPayment.forLeaderboard(
            teamId: teamId,
            weekEnding: Date(),
            topUsers: [
                ("user_6", "David Wilson", 1, 1000),
                ("user_7", "Emma Davis", 2, 600),
                ("user_8", "Tom Anderson", 3, 400)
            ]
        )
        addPendingPayment(leaderboardPayment)
    }
}