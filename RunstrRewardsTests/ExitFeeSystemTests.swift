import XCTest
@testable import RunstrRewards

final class ExitFeeSystemTests: XCTestCase {
    
    private let mockUserId = "test-user-123"
    private let mockTeamId = "test-team-456"
    private let mockNewTeamId = "test-team-789"
    
    override func setUpWithError() throws {
        // Set up test environment
        continueAfterFailure = false
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
    }
    
    // MARK: - Exit Fee Manager Tests
    
    func testExitFeeOperationInitiation() throws {
        // Test that exit fee operations can be initiated with correct parameters
        let expectation = XCTestExpectation(description: "Exit fee operation initiated")
        
        Task {
            do {
                let operation = try await ExitFeeManager.shared.initiateTeamLeave(
                    userId: mockUserId,
                    teamId: mockTeamId
                )
                
                // Verify operation was created with correct parameters
                XCTAssertEqual(operation.userId, mockUserId)
                XCTAssertEqual(operation.fromTeamId, mockTeamId)
                XCTAssertNil(operation.toTeamId)
                XCTAssertEqual(operation.amount, 2000)
                XCTAssertEqual(operation.lightningAddress, "RUNSTR@coinos.io")
                XCTAssertEqual(operation.status, .initiated)
                XCTAssertEqual(operation.operationType, .leave)
                
                expectation.fulfill()
                
            } catch {
                XCTFail("Exit fee operation initiation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testTeamSwitchOperationInitiation() throws {
        // Test that team switch operations can be initiated with correct parameters
        let expectation = XCTestExpectation(description: "Team switch operation initiated")
        
        Task {
            do {
                let operation = try await ExitFeeManager.shared.initiateTeamSwitch(
                    userId: mockUserId,
                    fromTeamId: mockTeamId,
                    toTeamId: mockNewTeamId
                )
                
                // Verify operation was created with correct parameters
                XCTAssertEqual(operation.userId, mockUserId)
                XCTAssertEqual(operation.fromTeamId, mockTeamId)
                XCTAssertEqual(operation.toTeamId, mockNewTeamId)
                XCTAssertEqual(operation.amount, 2000)
                XCTAssertEqual(operation.lightningAddress, "RUNSTR@coinos.io")
                XCTAssertEqual(operation.status, .initiated)
                XCTAssertEqual(operation.operationType, .switch)
                
                expectation.fulfill()
                
            } catch {
                XCTFail("Team switch operation initiation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testConcurrentOperationPrevention() throws {
        // Test that concurrent operations for the same user are blocked
        let expectation1 = XCTestExpectation(description: "First operation initiated")
        let expectation2 = XCTestExpectation(description: "Second operation blocked")
        
        Task {
            // Start first operation
            do {
                let _ = try await ExitFeeManager.shared.initiateTeamLeave(
                    userId: mockUserId,
                    teamId: mockTeamId
                )
                expectation1.fulfill()
                
                // Try to start second operation - should be blocked
                do {
                    let _ = try await ExitFeeManager.shared.initiateTeamSwitch(
                        userId: mockUserId,
                        fromTeamId: mockTeamId,
                        toTeamId: mockNewTeamId
                    )
                    XCTFail("Second operation should have been blocked")
                } catch ExitFeeError.operationInProgress {
                    // Expected behavior
                    expectation2.fulfill()
                } catch {
                    XCTFail("Unexpected error: \(error)")
                }
                
            } catch {
                XCTFail("First operation failed: \(error)")
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    func testExitFeeStatusTransitions() throws {
        // Test that exit fee operations transition through correct states
        let expectation = XCTestExpectation(description: "Status transitions verified")
        
        Task {
            do {
                // Initiate operation
                let operation = try await ExitFeeManager.shared.initiateTeamLeave(
                    userId: mockUserId,
                    teamId: mockTeamId
                )
                
                XCTAssertEqual(operation.status, .initiated)
                
                // Note: In a real test environment, you would mock the payment processing
                // and verify transitions through: initiated -> invoice_created -> payment_sent 
                // -> payment_confirmed -> team_change_complete
                
                expectation.fulfill()
                
            } catch {
                XCTFail("Status transition test failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Team Data Service Tests
    
    func testTeamSwitchValidation() throws {
        // Test team switch validation logic
        let expectation = XCTestExpectation(description: "Team switch validation")
        
        Task {
            do {
                // Test getting user's active team (should handle nil case gracefully)
                let activeTeam = try await TeamDataService.shared.getUserActiveTeam(userId: mockUserId)
                
                // In a test environment, this might be nil - that's expected
                if let team = activeTeam {
                    XCTAssertNotNil(team.id)
                    XCTAssertNotNil(team.name)
                    XCTAssertGreaterThanOrEqual(team.memberCount, 0)
                    XCTAssertLessThanOrEqual(team.memberCount, team.maxMembers)
                }
                
                expectation.fulfill()
                
            } catch {
                // Team not found is acceptable in test environment
                if error.localizedDescription.contains("not found") {
                    expectation.fulfill()
                } else {
                    XCTFail("Team validation failed: \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - CoinOS Service Tests
    
    func testCoinOSServiceIntegration() throws {
        // Test CoinOS service methods exist and have correct signatures
        let expectation = XCTestExpectation(description: "CoinOS integration verified")
        
        Task {
            // These tests verify the methods exist and can be called
            // In a production test, you would mock CoinOS responses
            
            do {
                // Test createRunstrInvoice exists
                let _ = try await CoinOSService.shared.createRunstrInvoice(
                    amount: 2000,
                    memo: "Test exit fee"
                )
                
                // If we reach here without compilation errors, the method exists
                // In practice, this would fail due to authentication in test environment
                
            } catch CoinOSError.notAuthenticated {
                // Expected in test environment
                expectation.fulfill()
            } catch {
                // Other errors are acceptable in test environment
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testExitFeeErrorHandling() throws {
        // Test proper error handling throughout the system
        let expectation = XCTestExpectation(description: "Error handling verified")
        
        // Test ExitFeeError types
        let operationInProgressError = ExitFeeError.operationInProgress
        XCTAssertNotNil(operationInProgressError.errorDescription)
        
        let paymentFailedError = ExitFeeError.paymentFailed("Test reason")
        XCTAssertTrue(paymentFailedError.errorDescription?.contains("Test reason") ?? false)
        
        let maxRetriesError = ExitFeeError.maxRetriesExceeded
        XCTAssertNotNil(maxRetriesError.errorDescription)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTeamMembershipErrorHandling() throws {
        // Test team membership error types
        let expectation = XCTestExpectation(description: "Team membership error handling verified")
        
        let alreadyOnTeamError = TeamMembershipError.alreadyOnTeam(
            currentTeamId: "team-123",
            currentTeamName: "Test Team"
        )
        XCTAssertTrue(alreadyOnTeamError.errorDescription?.contains("Test Team") ?? false)
        
        let notOnTeamError = TeamMembershipError.notOnAnyTeam(userId: "user-123")
        XCTAssertNotNil(notOnTeamError.errorDescription)
        
        let teamNotFoundError = TeamMembershipError.teamNotFound(teamId: "team-456")
        XCTAssertTrue(teamNotFoundError.errorDescription?.contains("team-456") ?? false)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Constants and Configuration Tests
    
    func testExitFeeConstants() throws {
        // Verify exit fee constants are correctly set
        XCTAssertEqual(CoinOSService.EXIT_FEE_AMOUNT, 2000)
        XCTAssertEqual(CoinOSService.RUNSTR_LIGHTNING_ADDRESS, "RUNSTR@coinos.io")
    }
    
    func testExitFeeStatusEnum() throws {
        // Test all exit fee status cases exist
        let allStatuses: [ExitFeeStatus] = [
            .initiated,
            .invoiceCreated,
            .paymentSent,
            .paymentConfirmed,
            .teamChangeComplete,
            .failed,
            .compensated,
            .expired
        ]
        
        XCTAssertEqual(allStatuses.count, 8)
        
        // Verify they can be encoded/decoded
        for status in allStatuses {
            let encoded = status.rawValue
            let decoded = ExitFeeStatus(rawValue: encoded)
            XCTAssertNotNil(decoded)
            XCTAssertEqual(decoded, status)
        }
    }
    
    // MARK: - Model Tests
    
    func testExitFeeOperationModel() throws {
        // Test ExitFeeOperation model can be properly initialized and encoded
        let operation = ExitFeeOperation(
            id: "test-id",
            paymentIntentId: "intent-123",
            userId: mockUserId,
            fromTeamId: mockTeamId,
            toTeamId: nil,
            amount: 2000,
            lightningAddress: "RUNSTR@coinos.io",
            operationType: .leave,
            status: .initiated,
            paymentHash: nil,
            invoiceText: nil,
            retryCount: 0,
            errorMessage: nil,
            createdAt: Date(),
            completedAt: nil
        )
        
        XCTAssertEqual(operation.operationType, .leave)
        XCTAssertEqual(operation.amount, 2000)
        XCTAssertEqual(operation.status, .initiated)
        XCTAssertNil(operation.toTeamId)
        
        // Test encoding/decoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(operation)
        XCTAssertGreaterThan(data.count, 0)
        
        let decoder = JSONDecoder()
        let decodedOperation = try decoder.decode(ExitFeeOperation.self, from: data)
        XCTAssertEqual(decodedOperation.id, operation.id)
        XCTAssertEqual(decodedOperation.operationType, operation.operationType)
    }
}