import Foundation
import Supabase

// MARK: - Exit Fee Models

struct ExitFeeOperation: Codable {
    let id: String
    let paymentIntentId: String
    let userId: String
    let fromTeamId: String?
    let toTeamId: String?
    let amount: Int
    let lightningAddress: String
    let status: ExitFeeStatus
    let paymentHash: String?
    let invoiceText: String?
    let retryCount: Int
    let errorMessage: String?
    let createdAt: Date
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, status, retryCount, createdAt, completedAt
        case paymentIntentId = "payment_intent_id"
        case userId = "user_id"
        case fromTeamId = "from_team_id"
        case toTeamId = "to_team_id"
        case lightningAddress = "lightning_address"
        case paymentHash = "payment_hash"
        case invoiceText = "invoice_text"
        case errorMessage = "error_message"
    }
    
    var operationType: ExitFeeOperationType {
        return toTeamId != nil ? .`switch` : .leave
    }
}

enum ExitFeeOperationType: String, Codable {
    case leave = "leave"
    case `switch` = "switch"
}

enum ExitFeeStatus: String, Codable, CaseIterable {
    case initiated = "initiated"
    case invoiceCreated = "invoice_created"
    case paymentSent = "payment_sent"
    case paymentConfirmed = "payment_confirmed"
    case teamChangeComplete = "team_change_complete"
    case failed = "failed"
    case compensated = "compensated"
    case expired = "expired"
}

struct TeamSwitchOperation: Codable {
    let id: String
    let userId: String
    let fromTeamId: String?
    let toTeamId: String?
    let exitFeePaymentId: String
    let operationType: ExitFeeOperationType
    let status: TeamSwitchStatus
    let errorMessage: String?
    let createdAt: Date
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, status, createdAt, completedAt
        case userId = "user_id"
        case fromTeamId = "from_team_id"
        case toTeamId = "to_team_id"
        case exitFeePaymentId = "exit_fee_payment_id"
        case operationType = "operation_type"
        case errorMessage = "error_message"
    }
}

enum TeamSwitchStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case rolledBack = "rolled_back"
}

// MARK: - Exit Fee Errors

enum ExitFeeError: LocalizedError {
    case operationInProgress
    case invalidOperation
    case paymentFailed(String)
    case teamChangesFailed(String)
    case maxRetriesExceeded
    case operationExpired
    case compensationRequired
    
    var errorDescription: String? {
        switch self {
        case .operationInProgress:
            return "Another exit fee operation is already in progress"
        case .invalidOperation:
            return "Invalid exit fee operation"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .teamChangesFailed(let reason):
            return "Team changes failed: \(reason)"
        case .maxRetriesExceeded:
            return "Maximum payment retries exceeded"
        case .operationExpired:
            return "Exit fee operation has expired"
        case .compensationRequired:
            return "Operation requires manual compensation"
        }
    }
}

// MARK: - Exit Fee Manager

class ExitFeeManager {
    static let shared = ExitFeeManager()
    
    private let RUNSTR_LIGHTNING_ADDRESS = "RUNSTR@coinos.io"
    private let EXIT_FEE_AMOUNT = 2000
    private let MAX_RETRIES = 3
    private let OPERATION_TIMEOUT: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private var activeOperations: Set<String> = []
    private let operationQueue = DispatchQueue(label: "com.runstrrewards.exitfee", qos: .userInitiated)
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {
        // Resume incomplete operations on initialization
        Task {
            await resumeIncompleteOperations()
        }
    }
    
    // MARK: - Public Interface
    
    func initiateTeamLeave(userId: String, teamId: String) async throws -> ExitFeeOperation {
        return try await initiateExitFee(userId: userId, fromTeamId: teamId, toTeamId: nil)
    }
    
    func initiateTeamSwitch(userId: String, fromTeamId: String, toTeamId: String) async throws -> ExitFeeOperation {
        return try await initiateExitFee(userId: userId, fromTeamId: fromTeamId, toTeamId: toTeamId)
    }
    
    func processExitFeePayment(operationId: String) async throws -> PaymentResult {
        let operation = try await getExitFeeOperation(operationId: operationId)
        
        guard operation.status == .initiated || operation.status == .invoiceCreated else {
            throw ExitFeeError.invalidOperation
        }
        
        // Update to payment sent status
        try await updateExitFeeStatus(operationId: operationId, status: .paymentSent)
        
        do {
            // Process payment with retries
            let paymentResult = try await processPaymentWithRetries(operation: operation)
            
            // Update with payment confirmation
            try await updateExitFeeStatus(
                operationId: operationId,
                status: .paymentConfirmed,
                paymentHash: paymentResult.paymentHash
            )
            
            return paymentResult
            
        } catch {
            try await updateExitFeeStatus(
                operationId: operationId,
                status: .failed,
                errorMessage: error.localizedDescription
            )
            throw error
        }
    }
    
    func executeTeamChanges(operationId: String) async throws {
        let operation = try await getExitFeeOperation(operationId: operationId)
        
        guard operation.status == .paymentConfirmed else {
            throw ExitFeeError.invalidOperation
        }
        
        do {
            // Execute team changes based on operation type
            switch operation.operationType {
            case .leave:
                try await executeTeamLeave(operation: operation)
            case .`switch`:
                try await executeTeamSwitch(operation: operation)
            }
            
            // Mark as complete
            try await updateExitFeeStatus(operationId: operationId, status: .teamChangeComplete)
            
        } catch {
            try await updateExitFeeStatus(
                operationId: operationId,
                status: .failed,
                errorMessage: error.localizedDescription
            )
            throw ExitFeeError.teamChangesFailed(error.localizedDescription)
        }
    }
    
    func cancelOperation(operationId: String) async throws {
        let operation = try await getExitFeeOperation(operationId: operationId)
        
        // Can only cancel operations that haven't been paid
        guard [.initiated, .invoiceCreated].contains(operation.status) else {
            throw ExitFeeError.invalidOperation
        }
        
        try await updateExitFeeStatus(operationId: operationId, status: .failed, errorMessage: "Cancelled by user")
        activeOperations.remove(operation.userId)
    }
    
    // MARK: - Private Implementation
    
    func initiateExitFee(userId: String, fromTeamId: String?, toTeamId: String?) async throws -> ExitFeeOperation {
        return try await operationQueue.asyncOperation {
            // Prevent concurrent operations for same user
            guard !self.activeOperations.contains(userId) else {
                throw ExitFeeError.operationInProgress
            }
            
            // Validate team switch is possible
            if let toTeamId = toTeamId {
                try await self.validateTeamSwitch(userId: userId, toTeamId: toTeamId)
            }
            
            self.activeOperations.insert(userId)
            
            do {
                // Create exit fee payment record
                let operation = try await self.createExitFeePayment(
                    userId: userId,
                    fromTeamId: fromTeamId,
                    toTeamId: toTeamId
                )
                
                print("ExitFeeManager: Initiated \(operation.operationType.rawValue) operation for user \(userId)")
                return operation
                
            } catch {
                self.activeOperations.remove(userId)
                throw error
            }
        }
    }
    
    private func createExitFeePayment(userId: String, fromTeamId: String?, toTeamId: String?) async throws -> ExitFeeOperation {
        struct CreatePaymentRequest: Encodable {
            let userId: String
            let fromTeamId: String?
            let toTeamId: String?
            let amount: Int
            let lightningAddress: String
            let paymentStatus: String
            
            enum CodingKeys: String, CodingKey {
                case amount
                case paymentStatus = "payment_status"
                case userId = "user_id"
                case fromTeamId = "from_team_id"
                case toTeamId = "to_team_id"
                case lightningAddress = "lightning_address"
            }
        }
        
        let request = CreatePaymentRequest(
            userId: userId,
            fromTeamId: fromTeamId,
            toTeamId: toTeamId,
            amount: EXIT_FEE_AMOUNT,
            lightningAddress: RUNSTR_LIGHTNING_ADDRESS,
            paymentStatus: ExitFeeStatus.initiated.rawValue
        )
        
        let response = try await client
            .from("exit_fee_payments")
            .insert(request)
            .select()
            .single()
            .execute()
        
        let operation = try SupabaseService.shared.customJSONDecoder().decode(ExitFeeOperation.self, from: response.data)
        return operation
    }
    
    private func processPaymentWithRetries(operation: ExitFeeOperation) async throws -> PaymentResult {
        var lastError: Error?
        
        for attempt in 1...MAX_RETRIES {
            do {
                print("ExitFeeManager: Payment attempt \(attempt)/\(MAX_RETRIES)")
                
                // Create fresh invoice for each attempt
                let invoice = try await CoinOSService.shared.createRunstrInvoice(
                    amount: operation.amount,
                    memo: "Exit fee - \(operation.operationType.rawValue) team"
                )
                
                // Store invoice in database
                try await updateExitFeeInvoice(operationId: operation.id, invoice: invoice)
                
                // Process payment
                let paymentResult = try await CoinOSService.shared.payExitFeeToRunstr(
                    amount: operation.amount,
                    memo: "Exit fee payment"
                )
                
                // Verify RUNSTR received the payment
                let verified = try await CoinOSService.shared.verifyRunstrPayment(
                    paymentHash: paymentResult.paymentHash
                )
                
                guard verified else {
                    throw ExitFeeError.paymentFailed("Payment not confirmed by RUNSTR")
                }
                
                print("ExitFeeManager: Payment successful on attempt \(attempt)")
                return paymentResult
                
            } catch {
                lastError = error
                print("ExitFeeManager: Payment attempt \(attempt) failed: \(error)")
                
                // Update retry count
                try await updateExitFeeRetryCount(operationId: operation.id, retryCount: attempt)
                
                // Don't retry on certain errors
                if case CoinOSError.notAuthenticated = error {
                    throw error
                }
                
                // Wait before retry (exponential backoff)
                if attempt < MAX_RETRIES {
                    let delay = TimeInterval(attempt * 2)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw ExitFeeError.maxRetriesExceeded
    }
    
    private func executeTeamLeave(operation: ExitFeeOperation) async throws {
        guard let fromTeamId = operation.fromTeamId else {
            throw ExitFeeError.invalidOperation
        }
        
        try await TeamDataService.shared.executeTeamExit(
            userId: operation.userId,
            teamId: fromTeamId,
            exitFeePaymentId: operation.id
        )
        
        print("ExitFeeManager: User \(operation.userId) left team \(fromTeamId)")
    }
    
    private func executeTeamSwitch(operation: ExitFeeOperation) async throws {
        guard let fromTeamId = operation.fromTeamId,
              let toTeamId = operation.toTeamId else {
            throw ExitFeeError.invalidOperation
        }
        
        try await TeamDataService.shared.executeAtomicTeamSwitch(
            userId: operation.userId,
            fromTeamId: fromTeamId,
            toTeamId: toTeamId,
            exitFeePaymentId: operation.id
        )
        
        print("ExitFeeManager: User \(operation.userId) switched from team \(fromTeamId) to team \(toTeamId)")
    }
    
    private func validateTeamSwitch(userId: String, toTeamId: String) async throws {
        // Check if target team exists and has space
        guard let team = try await TeamDataService.shared.getTeam(toTeamId) else {
            throw ExitFeeError.invalidOperation
        }
        guard team.memberCount < team.maxMembers else {
            throw ExitFeeError.invalidOperation
        }
    }
    
    // MARK: - Database Operations
    
    private func getExitFeeOperation(operationId: String) async throws -> ExitFeeOperation {
        let response = try await client
            .from("exit_fee_payments")
            .select()
            .eq("id", value: operationId)
            .single()
            .execute()
        
        return try SupabaseService.shared.customJSONDecoder().decode(ExitFeeOperation.self, from: response.data)
    }
    
    private func updateExitFeeStatus(operationId: String, status: ExitFeeStatus, paymentHash: String? = nil, errorMessage: String? = nil) async throws {
        struct UpdateRequest: Encodable {
            let paymentStatus: String
            let paymentHash: String?
            let errorMessage: String?
            let completedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case paymentStatus = "payment_status"
                case paymentHash = "payment_hash"
                case errorMessage = "error_message"
                case completedAt = "completed_at"
            }
        }
        
        let completedAt = (status == .teamChangeComplete) ? ISO8601DateFormatter().string(from: Date()) : nil
        
        let update = UpdateRequest(
            paymentStatus: status.rawValue,
            paymentHash: paymentHash,
            errorMessage: errorMessage,
            completedAt: completedAt
        )
        
        try await client
            .from("exit_fee_payments")
            .update(update)
            .eq("id", value: operationId)
            .execute()
        
        // Remove from active operations if completed or failed
        if [.teamChangeComplete, .failed, .expired].contains(status) {
            if let operation = try? await getExitFeeOperation(operationId: operationId) {
                activeOperations.remove(operation.userId)
            }
        }
    }
    
    private func updateExitFeeInvoice(operationId: String, invoice: LightningInvoice) async throws {
        struct UpdateRequest: Encodable {
            let invoiceText: String
            let paymentStatus: String
            
            enum CodingKeys: String, CodingKey {
                case invoiceText = "invoice_text"
                case paymentStatus = "payment_status"
            }
        }
        
        let update = UpdateRequest(
            invoiceText: invoice.paymentRequest,
            paymentStatus: ExitFeeStatus.invoiceCreated.rawValue
        )
        
        try await client
            .from("exit_fee_payments")
            .update(update)
            .eq("id", value: operationId)
            .execute()
    }
    
    private func updateExitFeeRetryCount(operationId: String, retryCount: Int) async throws {
        struct UpdateRequest: Encodable {
            let retryCount: Int
            
            enum CodingKeys: String, CodingKey {
                case retryCount = "retry_count"
            }
        }
        
        let update = UpdateRequest(retryCount: retryCount)
        
        try await client
            .from("exit_fee_payments")
            .update(update)
            .eq("id", value: operationId)
            .execute()
    }
    
    // MARK: - Recovery Operations
    
    func resumeIncompleteOperations() async {
        do {
            // Get incomplete operations
            let response = try await client
                .from("exit_fee_payments")
                .select()
                .in("payment_status", values: [
                    ExitFeeStatus.paymentConfirmed.rawValue
                ])
                .execute()
            
            let operations = try SupabaseService.shared.customJSONDecoder().decode([ExitFeeOperation].self, from: response.data)
            
            for operation in operations {
                print("ExitFeeManager: Resuming incomplete operation \(operation.id)")
                
                Task {
                    do {
                        try await executeTeamChanges(operationId: operation.id)
                    } catch {
                        print("ExitFeeManager: Failed to resume operation \(operation.id): \(error)")
                        try? await updateExitFeeStatus(
                            operationId: operation.id,
                            status: .failed,
                            errorMessage: "Resume failed: \(error.localizedDescription)"
                        )
                    }
                }
            }
            
        } catch {
            print("ExitFeeManager: Failed to resume incomplete operations: \(error)")
        }
    }
}

// MARK: - Async Queue Extension

extension DispatchQueue {
    func asyncOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.async {
                Task {
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}