import XCTest
@testable import RunstrRewards

class ExitFeeManagerTests: XCTestCase {
    
    var exitFeeManager: ExitFeeManager!
    
    override func setUp() {
        super.setUp()
        exitFeeManager = ExitFeeManager.shared
    }
    
    override func tearDown() {
        super.tearDown()
        exitFeeManager = nil
    }
    
    // MARK: - State Machine Tests
    
    func testValidStateTransitions() {
        // Test all valid state transitions
        XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .initiated, to: .invoiceCreated))
        XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .invoiceCreated, to: .paymentSent))
        XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .paymentSent, to: .paymentConfirmed))
        XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .paymentConfirmed, to: .teamChangeComplete))
        XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .failed, to: .compensated))
    }
    
    func testInvalidStateTransitions() {
        // Test invalid state transitions that should throw
        XCTAssertThrowsError(try exitFeeManager.validateStateTransition(from: .initiated, to: .paymentConfirmed)) { error in
            XCTAssertTrue(error is ExitFeeError)
            if case let ExitFeeError.invalidStateTransition(from, to) = error {
                XCTAssertEqual(from, .initiated)
                XCTAssertEqual(to, .paymentConfirmed)
            } else {
                XCTFail("Expected invalidStateTransition error")
            }
        }
        
        // Test transition to terminal state
        XCTAssertThrowsError(try exitFeeManager.validateStateTransition(from: .teamChangeComplete, to: .failed))
        XCTAssertThrowsError(try exitFeeManager.validateStateTransition(from: .compensated, to: .initiated))
    }
    
    func testTerminalStateIdentification() {
        XCTAssertFalse(ExitFeePaymentStatus.initiated.isTerminal)
        XCTAssertFalse(ExitFeePaymentStatus.paymentSent.isTerminal)
        XCTAssertTrue(ExitFeePaymentStatus.teamChangeComplete.isTerminal)
        XCTAssertTrue(ExitFeePaymentStatus.compensated.isTerminal)
    }
    
    func testRecoveryStateIdentification() {
        XCTAssertTrue(ExitFeePaymentStatus.paymentConfirmed.requiresRecovery)
        XCTAssertFalse(ExitFeePaymentStatus.initiated.requiresRecovery)
        XCTAssertFalse(ExitFeePaymentStatus.teamChangeComplete.requiresRecovery)
    }
    
    // MARK: - Concurrent Operation Tests
    
    func testConcurrentOperationPrevention() {
        let testUserId = "test-user-\(UUID().uuidString)"
        
        // First operation should succeed
        XCTAssertNoThrow(try exitFeeManager.reserveUserOperation(userId: testUserId))
        
        // Second operation should fail
        XCTAssertThrowsError(try exitFeeManager.reserveUserOperation(userId: testUserId)) { error in
            XCTAssertTrue(error is ExitFeeError)
            if case let ExitFeeError.operationInProgress(userId) = error {
                XCTAssertEqual(userId, testUserId)
            } else {
                XCTFail("Expected operationInProgress error")
            }
        }
        
        // Release and try again - should succeed
        exitFeeManager.releaseUserOperation(userId: testUserId)
        XCTAssertNoThrow(try exitFeeManager.reserveUserOperation(userId: testUserId))
        
        // Cleanup
        exitFeeManager.releaseUserOperation(userId: testUserId)
    }
    
    func testActiveOperationChecking() {
        let testUserId = "test-user-\(UUID().uuidString)"
        
        // Initially no active operation
        XCTAssertFalse(exitFeeManager.hasActiveOperation(for: testUserId))
        
        // Reserve operation
        XCTAssertNoThrow(try exitFeeManager.reserveUserOperation(userId: testUserId))
        XCTAssertTrue(exitFeeManager.hasActiveOperation(for: testUserId))
        
        // Release operation
        exitFeeManager.releaseUserOperation(userId: testUserId)
        XCTAssertFalse(exitFeeManager.hasActiveOperation(for: testUserId))
    }
    
    // MARK: - Compensation Action Tests
    
    func testCompensationActionDetermination() {
        // Test compensation actions for different operation states
        let baseOperation = ExitFeeOperation(
            id: UUID().uuidString,
            paymentIntentId: "test-intent",
            userId: "test-user",
            fromTeamId: "team-1",
            toTeamId: nil,
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
        
        // Initiated state should be marked as failed
        var operation = baseOperation
        operation.status = .initiated
        let action1 = exitFeeManager.determineCompensationAction(for: operation)
        if case let .markAsFailed(reason) = action1 {
            XCTAssertTrue(reason.contains("Payment never completed"))
        } else {
            XCTFail("Expected markAsFailed action for initiated state")
        }
        
        // Payment confirmed should trigger team change retry
        operation.status = .paymentConfirmed
        operation.paymentHash = "test-hash"
        let action2 = exitFeeManager.determineCompensationAction(for: operation)
        if case let .retryTeamChange(reason) = action2 {
            XCTAssertTrue(reason.contains("Payment confirmed"))
        } else {
            XCTFail("Expected retryTeamChange action for paymentConfirmed state")
        }
        
        // Payment sent should require manual review
        operation.status = .paymentSent
        let action3 = exitFeeManager.determineCompensationAction(for: operation)
        if case let .requireManualReview(reason) = action3 {
            XCTAssertTrue(reason.contains("Payment status unclear"))
        } else {
            XCTFail("Expected requireManualReview action for paymentSent state")
        }
        
        // Terminal states should require no action
        operation.status = .teamChangeComplete
        let action4 = exitFeeManager.determineCompensationAction(for: operation)
        if case .none = action4 {
            // Expected
        } else {
            XCTFail("Expected no action for terminal state")
        }
    }
    
    // MARK: - Operation Validation Tests
    
    func testOperationModelProperties() {
        let leaveOperation = ExitFeeOperation(
            id: UUID().uuidString,
            paymentIntentId: "test-intent",
            userId: "test-user",
            fromTeamId: "team-1",
            toTeamId: nil,
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
        
        XCTAssertTrue(leaveOperation.isLeaveOperation)
        XCTAssertFalse(leaveOperation.isTeamSwitchOperation)
        
        let switchOperation = ExitFeeOperation(
            id: UUID().uuidString,
            paymentIntentId: "test-intent",
            userId: "test-user",
            fromTeamId: "team-1",
            toTeamId: "team-2",
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
        
        XCTAssertFalse(switchOperation.isLeaveOperation)
        XCTAssertTrue(switchOperation.isTeamSwitchOperation)
    }
    
    // MARK: - Error Handling Tests
    
    func testExitFeeErrorDescriptions() {
        let testUserId = "test-user"
        let testIntentId = "test-intent"
        let testTeamId = "test-team"
        
        // Test error descriptions
        let error1 = ExitFeeError.operationInProgress(userId: testUserId)
        XCTAssertTrue(error1.localizedDescription.contains(testUserId))
        XCTAssertTrue(error1.localizedDescription.contains("in progress"))
        
        let error2 = ExitFeeError.invalidStateTransition(from: .initiated, to: .teamChangeComplete)
        XCTAssertTrue(error2.localizedDescription.contains("initiated"))
        XCTAssertTrue(error2.localizedDescription.contains("team_change_complete"))
        
        let error3 = ExitFeeError.operationNotFound(intentId: testIntentId)
        XCTAssertTrue(error3.localizedDescription.contains(testIntentId))
        
        let error4 = ExitFeeError.operationExpired(intentId: testIntentId)
        XCTAssertTrue(error4.localizedDescription.contains("expired"))
        
        let error5 = ExitFeeError.maxRetriesExceeded(intentId: testIntentId)
        XCTAssertTrue(error5.localizedDescription.contains("Maximum retries"))
        
        let error6 = ExitFeeError.userNotOnTeam(userId: testUserId)
        XCTAssertTrue(error6.localizedDescription.contains("not on any team"))
        
        let error7 = ExitFeeError.targetTeamNotFound(teamId: testTeamId)
        XCTAssertTrue(error7.localizedDescription.contains("not found"))
        
        let error8 = ExitFeeError.databaseError("Connection failed")
        XCTAssertTrue(error8.localizedDescription.contains("Connection failed"))
    }
    
    // MARK: - Constants Tests
    
    func testConstants() {
        XCTAssertEqual(ExitFeeManager.EXIT_FEE_AMOUNT, 2000)
        XCTAssertEqual(ExitFeeManager.RUNSTR_LIGHTNING_ADDRESS, "RUNSTR@coinos.io")
        XCTAssertEqual(ExitFeeManager.MAX_RETRY_COUNT, 3)
        XCTAssertEqual(ExitFeeManager.OPERATION_EXPIRY_HOURS, 24)
    }
    
    // MARK: - Integration Tests (Mocked)
    
    func testInitiateExitFeeValidation() async throws {
        // This test would require mocked database services
        // For now, we test the validation logic
        
        let testUserId = "test-user"
        let testTeamId = "team-1"
        
        // Test that operation reservation works
        XCTAssertNoThrow(try exitFeeManager.reserveUserOperation(userId: testUserId))
        
        // Test that duplicate reservation fails
        XCTAssertThrowsError(try exitFeeManager.reserveUserOperation(userId: testUserId))
        
        // Cleanup
        exitFeeManager.releaseUserOperation(userId: testUserId)
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentOperationPerformance() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            
            // Test 100 concurrent reservation attempts
            let userIds = (1...100).map { "user-\($0)" }
            
            DispatchQueue.concurrentPerform(iterations: 100) { index in
                let userId = userIds[index]
                
                do {
                    try exitFeeManager.reserveUserOperation(userId: userId)
                    exitFeeManager.releaseUserOperation(userId: userId)
                } catch {
                    // Expected for some operations due to concurrency
                }
            }
            
            stopMeasuring()
        }
    }
    
    func testStateTransitionPerformance() {
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()
            
            // Test 1000 state transition validations
            for _ in 1...1000 {
                XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .initiated, to: .invoiceCreated))
                XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .invoiceCreated, to: .paymentSent))
                XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .paymentSent, to: .paymentConfirmed))
                XCTAssertNoThrow(try exitFeeManager.validateStateTransition(from: .paymentConfirmed, to: .teamChangeComplete))
            }
            
            stopMeasuring()
        }
    }
}

// MARK: - Mock Data Extensions

extension ExitFeeManagerTests {
    
    func createMockExitFeeOperation(
        status: ExitFeePaymentStatus = .initiated,
        fromTeamId: String? = "team-1",
        toTeamId: String? = nil,
        paymentHash: String? = nil
    ) -> ExitFeeOperation {
        return ExitFeeOperation(
            id: UUID().uuidString,
            paymentIntentId: "test-intent-\(UUID().uuidString)",
            userId: "test-user-\(UUID().uuidString)",
            fromTeamId: fromTeamId,
            toTeamId: toTeamId,
            status: status,
            amount: ExitFeeManager.EXIT_FEE_AMOUNT,
            lightningAddress: ExitFeeManager.RUNSTR_LIGHTNING_ADDRESS,
            paymentHash: paymentHash,
            invoiceText: nil,
            retryCount: 0,
            errorMessage: nil,
            createdAt: Date(),
            updatedAt: Date(),
            completedAt: status.isTerminal ? Date() : nil
        )
    }
}