import Foundation

class TeamWalletTransactionService {
    static let shared = TeamWalletTransactionService()
    
    weak var delegate: TeamPaymentServiceDelegate?
    private let lightningWalletManager = LightningWalletManager.shared
    private let coinOSService = CoinOSService.shared
    
    private init() {}
    
    // MARK: - Payment Processing
    
    func initiateTeamPayment(teamId: String, recipientId: String, amountSats: Int) async {
        do {
            await MainActor.run {
                delegate?.didStartPaymentProcessing()
            }
            
            // Verify team captain access
            guard let userId = AuthenticationService.shared.currentUserId else {
                throw PaymentError.userNotAuthenticated
            }
            
            let hasAccess = try await validateCaptainAccess(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw PaymentError.insufficientPermissions
            }
            
            // Create payment ID for tracking
            let paymentId = UUID().uuidString
            
            await MainActor.run {
                delegate?.didInitiatePayment(paymentId)
            }
            
            // Process Lightning payment
            let result = try await coinOSService.sendPayment(
                recipientId: recipientId,
                amountSats: amountSats
            )
            
            if result.success {
                await MainActor.run {
                    let paymentResult = PaymentResult(
                        success: true,
                        paymentId: paymentId,
                        transactionHash: result.transactionHash,
                        amountSats: amountSats,
                        recipientId: recipientId,
                        timestamp: Date()
                    )
                    delegate?.didCompletePayment(paymentResult)
                }
                
                print("✅ TeamWalletPaymentService: Payment completed successfully")
            } else {
                await MainActor.run {
                    delegate?.didFailPayment(PaymentError.transactionFailed)
                }
            }
            
        } catch {
            print("❌ TeamWalletPaymentService: Payment failed: \(error)")
            await MainActor.run {
                delegate?.didFailPayment(error)
            }
        }
    }
    
    func processBulkTeamDistribution(teamId: String, recipients: [String], amountSats: Int) async {
        do {
            await MainActor.run {
                delegate?.didStartPaymentProcessing()
            }
            
            // Verify team captain access
            guard let userId = AuthenticationService.shared.currentUserId else {
                throw PaymentError.userNotAuthenticated
            }
            
            let hasAccess = try await validateCaptainAccess(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw PaymentError.insufficientPermissions
            }
            
            var successfulPayments = 0
            var failedPayments: [String] = []
            var transactionHashes: [String] = []
            
            // Process each payment
            for recipient in recipients {
                do {
                    let result = try await coinOSService.sendPayment(
                        recipientId: recipient,
                        amountSats: amountSats
                    )
                    
                    if result.success {
                        successfulPayments += 1
                        if let txHash = result.transactionHash {
                            transactionHashes.append(txHash)
                        }
                    } else {
                        failedPayments.append(recipient)
                    }
                } catch {
                    print("❌ Payment failed for recipient \(recipient): \(error)")
                    failedPayments.append(recipient)
                }
            }
            
            // Create bulk payment result
            let bulkResult = PaymentResult(
                success: failedPayments.isEmpty,
                paymentId: UUID().uuidString,
                transactionHash: transactionHashes.first,
                amountSats: successfulPayments * amountSats,
                recipientId: nil, // Bulk payment
                timestamp: Date(),
                additionalData: [
                    "total_recipients": recipients.count,
                    "successful_payments": successfulPayments,
                    "failed_payments": failedPayments.count,
                    "transaction_hashes": transactionHashes
                ]
            )
            
            await MainActor.run {
                delegate?.didCompletePayment(bulkResult)
            }
            
            print("✅ TeamWalletPaymentService: Bulk distribution completed - Success: \(successfulPayments), Failed: \(failedPayments.count)")
            
        } catch {
            print("❌ TeamWalletPaymentService: Bulk distribution failed: \(error)")
            await MainActor.run {
                delegate?.didFailPayment(error)
            }
        }
    }
    
    func generateTeamInvoice(teamId: String, amountSats: Int, description: String) async {
        do {
            // Verify team access
            guard let userId = AuthenticationService.shared.currentUserId else {
                throw PaymentError.userNotAuthenticated
            }
            
            let hasAccess = try await validateTeamAccess(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw PaymentError.insufficientPermissions
            }
            
            // Generate Lightning invoice
            let invoice = try await coinOSService.createInvoice(
                amountSats: amountSats,
                description: "Team \(teamId): \(description)"
            )
            
            await MainActor.run {
                delegate?.didGenerateInvoice(invoice)
            }
            
            print("✅ TeamWalletPaymentService: Generated invoice for team \(teamId)")
            
        } catch {
            print("❌ TeamWalletPaymentService: Failed to generate invoice: \(error)")
            await MainActor.run {
                delegate?.didFailPayment(error)
            }
        }
    }
    
    // MARK: - Payment Validation
    
    func validatePaymentAmount(amountSats: Int, teamBalance: Int) -> Bool {
        // Ensure payment doesn't exceed team balance
        return amountSats > 0 && amountSats <= teamBalance
    }
    
    func validateBulkPayment(recipients: [String], amountSats: Int, teamBalance: Int) -> Bool {
        let totalAmount = recipients.count * amountSats
        return recipients.count > 0 && amountSats > 0 && totalAmount <= teamBalance
    }
    
    // MARK: - Access Control
    
    private func validateCaptainAccess(teamId: String, userId: String) async throws -> Bool {
        let team = try await SupabaseService.shared.fetchTeam(id: teamId)
        return team.captainId == userId
    }
    
    private func validateTeamAccess(teamId: String, userId: String) async throws -> Bool {
        // Check if user is team member (captain or regular member)
        let membership = try await SupabaseService.shared.fetchTeamMembership(
            userId: userId,
            teamId: teamId
        )
        return membership.isActive
    }
    
    // MARK: - Payment History
    
    func loadTeamPaymentHistory(teamId: String, limit: Int = 20) async -> [PaymentResult] {
        do {
            // Load payment history from database
            let payments = try await SupabaseService.shared.fetchTeamPayments(
                teamId: teamId,
                limit: limit
            )
            
            return payments.map { payment in
                PaymentResult(
                    success: payment.status == "completed",
                    paymentId: payment.id,
                    transactionHash: payment.transactionHash,
                    amountSats: payment.amountSats,
                    recipientId: payment.recipientId,
                    timestamp: payment.createdAt
                )
            }
            
        } catch {
            print("❌ TeamWalletPaymentService: Failed to load payment history: \(error)")
            return []
        }
    }
}

// MARK: - Supporting Types

struct TeamPaymentResult {
    let success: Bool
    let paymentId: String
    let transactionHash: String?
    let amountSats: Int
    let recipientId: String?
    let timestamp: Date
    let additionalData: [String: Any]?
    
    init(success: Bool, 
         paymentId: String, 
         transactionHash: String?, 
         amountSats: Int, 
         recipientId: String?, 
         timestamp: Date, 
         additionalData: [String: Any]? = nil) {
        self.success = success
        self.paymentId = paymentId
        self.transactionHash = transactionHash
        self.amountSats = amountSats
        self.recipientId = recipientId
        self.timestamp = timestamp
        self.additionalData = additionalData
    }
    
    var formattedAmount: String {
        return "\(amountSats) sats"
    }
    
    var isBulkPayment: Bool {
        return recipientId == nil
    }
}

// MARK: - TeamWalletPaymentDelegate Protocol

protocol TeamPaymentServiceDelegate: AnyObject {
    func didStartPaymentProcessing()
    func didInitiatePayment(_ paymentId: String)
    func didCompletePayment(_ result: TeamPaymentResult)
    func didFailPayment(_ error: Error)
    func didGenerateInvoice(_ invoice: LightningInvoice)
}

enum PaymentError: LocalizedError {
    case userNotAuthenticated
    case insufficientPermissions
    case insufficientBalance
    case transactionFailed
    case invalidAmount
    case invalidRecipient
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .insufficientBalance:
            return "Insufficient team wallet balance"
        case .transactionFailed:
            return "Lightning transaction failed"
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidRecipient:
            return "Invalid recipient"
        }
    }
}