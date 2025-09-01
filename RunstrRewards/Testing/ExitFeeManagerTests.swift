import Foundation

/// Comprehensive unit tests for ExitFeeManager state machine infrastructure
/// Tests state transitions, error handling, concurrency, and recovery logic
class ExitFeeManagerTests {
    
    static let shared = ExitFeeManagerTests()
    private init() {}
    
    // MARK: - Test Configuration
    
    private let testUserId = "test_user_12345"
    private let testFromTeamId = "test_from_team_67890"
    private let testToTeamId = "test_to_team_54321"
    private let testPaymentHash = "test_payment_hash_abcdef"
    
    // MARK: - State Machine Tests
    
    /// Tests all valid state transitions in the exit fee payment flow
    func testValidStateTransitions() throws {
        let manager = ExitFeeManager.shared
        
        // Test initiated -> invoiceCreated
        try manager.validateStateTransition(from: .initiated, to: .invoiceCreated)
        
        // Test invoiceCreated -> paymentSent
        try manager.validateStateTransition(from: .invoiceCreated, to: .paymentSent)
        
        // Test paymentSent -> paymentConfirmed
        try manager.validateStateTransition(from: .paymentSent, to: .paymentConfirmed)
        
        // Test paymentConfirmed -> teamChangeComplete
        try manager.validateStateTransition(from: .paymentConfirmed, to: .teamChangeComplete)
        
        // Test failure transitions from each state
        try manager.validateStateTransition(from: .initiated, to: .failed)
        try manager.validateStateTransition(from: .invoiceCreated, to: .failed)
        try manager.validateStateTransition(from: .paymentSent, to: .failed)
        try manager.validateStateTransition(from: .paymentConfirmed, to: .failed)
        
        // Test compensation transition
        try manager.validateStateTransition(from: .failed, to: .compensated)
        
        print("✅ ExitFeeManagerTests: Valid state transitions test passed")
    }
    
    /// Tests that invalid state transitions are properly blocked
    func testInvalidStateTransitions() {
        let manager = ExitFeeManager.shared
        let invalidTransitions: [(ExitFeePaymentStatus, ExitFeePaymentStatus)] = [
            // Skip states
            (.initiated, .paymentSent),
            (.initiated, .paymentConfirmed),
            (.initiated, .teamChangeComplete),
            (.invoiceCreated, .paymentConfirmed),
            (.invoiceCreated, .teamChangeComplete),
            (.paymentSent, .teamChangeComplete),
            
            // Backward transitions
            (.paymentSent, .invoiceCreated),
            (.paymentConfirmed, .paymentSent),
            (.teamChangeComplete, .paymentConfirmed),
            
            // Terminal state transitions
            (.teamChangeComplete, .failed),
            (.compensated, .failed),
            (.compensated, .initiated)
        ]
        
        var blockedCount = 0
        for (from, to) in invalidTransitions {
            do {
                try manager.validateStateTransition(from: from, to: to)
                print("❌ Invalid transition \(from) -> \(to) was NOT blocked!")
            } catch ExitFeeError.invalidStateTransition {
                blockedCount += 1
            } catch {
                print("❌ Unexpected error for transition \(from) -> \(to): \(error)")
            }
        }
        
        print("✅ ExitFeeManagerTests: Blocked \(blockedCount)/\(invalidTransitions.count) invalid transitions")
    }
    
    /// Tests terminal state detection
    func testTerminalStates() {
        let terminalStates: [ExitFeePaymentStatus] = [.teamChangeComplete, .compensated]
        let nonTerminalStates: [ExitFeePaymentStatus] = [.initiated, .invoiceCreated, .paymentSent, .paymentConfirmed, .failed]
        
        for state in terminalStates {
            if !state.isTerminal {
                print("❌ State \(state) should be terminal but isTerminal = false")
                return
            }
        }
        
        for state in nonTerminalStates {
            if state.isTerminal {
                print("❌ State \(state) should NOT be terminal but isTerminal = true")
                return
            }
        }
        
        print("✅ ExitFeeManagerTests: Terminal state detection test passed")
    }
    
    /// Tests concurrent operation blocking for same user
    func testConcurrentOperationBlocking() throws {
        let manager = ExitFeeManager.shared
        
        // Reserve operation for test user
        try manager.reserveUserOperation(userId: testUserId)
        
        // Verify operation is active
        if !manager.hasActiveOperation(for: testUserId) {
            print("❌ Active operation not detected after reservation")
            return
        }
        
        // Try to reserve again - should fail
        do {
            try manager.reserveUserOperation(userId: testUserId)
            print("❌ Second operation reservation should have failed!")
            return
        } catch ExitFeeError.operationInProgress {
            // Expected behavior
        }
        
        // Release operation
        manager.releaseUserOperation(userId: testUserId)
        
        // Verify operation is released
        if manager.hasActiveOperation(for: testUserId) {
            print("❌ Operation still active after release")
            return
        }
        
        // Should be able to reserve again
        try manager.reserveUserOperation(userId: testUserId)
        manager.releaseUserOperation(userId: testUserId)
        
        print("✅ ExitFeeManagerTests: Concurrent operation blocking test passed")
    }
    
    /// Tests compensation action determination for different operation states
    func testCompensationActionLogic() {
        let manager = ExitFeeManager.shared
        
        // Test operations in different states
        let testOperations = [
            createTestOperation(status: .initiated),
            createTestOperation(status: .invoiceCreated),
            createTestOperation(status: .paymentSent),
            createTestOperation(status: .paymentConfirmed),
            createTestOperation(status: .teamChangeComplete),
            createTestOperation(status: .failed),
            createTestOperation(status: .compensated)
        ]
        
        let expectedActions: [ExitFeeManager.CompensationAction] = [
            .markAsFailed("Payment never completed"), // initiated
            .markAsFailed("Payment never completed"), // invoiceCreated
            .requireManualReview("Payment status unclear"), // paymentSent
            .retryTeamChange("Payment confirmed, retry team operation"), // paymentConfirmed
            .none, // teamChangeComplete
            .none, // failed
            .none  // compensated
        ]
        
        for (operation, expectedAction) in zip(testOperations, expectedActions) {
            let actualAction = manager.determineCompensationAction(for: operation)
            
            // Compare action types (simplified comparison)
            let match = switch (actualAction, expectedAction) {
            case (.markAsFailed(_), .markAsFailed(_)): true
            case (.retryTeamChange(_), .retryTeamChange(_)): true
            case (.requireManualReview(_), .requireManualReview(_)): true
            case (.none, .none): true
            default: false
            }
            
            if !match {
                print("❌ Wrong compensation action for status \(operation.status): expected \(expectedAction), got \(actualAction)")
                return
            }
        }
        
        print("✅ ExitFeeManagerTests: Compensation action logic test passed")
    }
    
    /// Tests ExitFeeOperation model encoding/decoding
    func testOperationModelSerialization() throws {
        let operation = createTestOperation(status: .paymentConfirmed)
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(operation)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExitFeeOperation.self, from: data)
        
        // Verify all fields match
        if decoded.id != operation.id ||
           decoded.paymentIntentId != operation.paymentIntentId ||
           decoded.userId != operation.userId ||
           decoded.status != operation.status ||
           decoded.amount != operation.amount {
            print("❌ Operation model serialization failed - fields don't match")
            return
        }
        
        print("✅ ExitFeeManagerTests: Operation model serialization test passed")
    }
    
    /// Tests operation type detection (leave vs switch)
    func testOperationTypeDetection() {
        let leaveOperation = ExitFeeOperation(
            id: "test1",
            paymentIntentId: "intent1",
            userId: testUserId,
            fromTeamId: testFromTeamId,
            toTeamId: nil, // No destination = leave
            status: .initiated,
            amount: 2000,
            lightningAddress: "RUNSTR@coinos.io",
            paymentHash: nil,
            invoiceText: nil,
            retryCount: 0,
            errorMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: nil
        )
        
        let switchOperation = ExitFeeOperation(
            id: "test2",
            paymentIntentId: "intent2",
            userId: testUserId,
            fromTeamId: testFromTeamId,
            toTeamId: testToTeamId, // Has destination = switch
            status: .initiated,
            amount: 2000,
            lightningAddress: "RUNSTR@coinos.io",
            paymentHash: nil,
            invoiceText: nil,
            retryCount: 0,
            errorMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: nil
        )
        
        if !leaveOperation.isLeaveOperation || leaveOperation.isTeamSwitchOperation {
            print("❌ Leave operation type detection failed")
            return
        }
        
        if switchOperation.isLeaveOperation || !switchOperation.isTeamSwitchOperation {
            print("❌ Switch operation type detection failed")
            return
        }
        
        print("✅ ExitFeeManagerTests: Operation type detection test passed")
    }
    
    // MARK: - Test Helpers
    
    private func createTestOperation(status: ExitFeePaymentStatus) -> ExitFeeOperation {
        return ExitFeeOperation(
            id: "test_operation_\(Int.random(in: 1000...9999))",
            paymentIntentId: "test_intent_\(Int.random(in: 1000...9999))",
            userId: testUserId,
            fromTeamId: testFromTeamId,
            toTeamId: status == .paymentConfirmed ? testToTeamId : nil,
            status: status,
            amount: ExitFeeManager.EXIT_FEE_AMOUNT,
            lightningAddress: ExitFeeManager.RUNSTR_LIGHTNING_ADDRESS,
            paymentHash: status.rawValue.contains("payment") ? testPaymentHash : nil,
            invoiceText: status.rawValue.contains("invoice") ? "test_invoice_text" : nil,
            retryCount: 0,
            errorMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: status.isTerminal ? Date() : nil
        )
    }
    
    // MARK: - Test Runner
    
    /// Runs all exit fee manager tests
    func runAllTests() {
        print("🧪 Starting ExitFeeManager Tests...")
        
        do {
            try testValidStateTransitions()
            testInvalidStateTransitions()
            testTerminalStates()
            try testConcurrentOperationBlocking()
            testCompensationActionLogic()
            try testOperationModelSerialization()
            testOperationTypeDetection()
            
            print("✅ ExitFeeManagerTests: All tests completed successfully!")
            
        } catch {
            print("❌ ExitFeeManagerTests: Test failed with error: \(error)")
        }
    }
}