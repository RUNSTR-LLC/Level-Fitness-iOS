import XCTest
@testable import RunstrRewards

class ExitFeeErrorHandlerTests: XCTestCase {
    var errorHandler: ExitFeeErrorHandler!
    
    override func setUp() {
        super.setUp()
        errorHandler = ExitFeeErrorHandler.shared
    }
    
    // MARK: - Error Categorization Tests
    
    func testCategorizeError_WithExitFeeErrors_ReturnsCorrectCategories() {
        // Test all ExitFeeError cases
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.insufficientFunds),
            .insufficientFunds,
            "Insufficient funds should be categorized correctly"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.paymentTimeout),
            .timeout,
            "Payment timeout should be categorized as timeout"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.networkError),
            .networkError,
            "Network error should be categorized correctly"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.invalidOperation),
            .validationError,
            "Invalid operation should be categorized as validation error"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.operationInProgress),
            .systemError,
            "Operation in progress should be categorized as system error"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.paymentFailed),
            .paymentFailure,
            "Payment failed should be categorized as payment failure"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.teamNotFound),
            .teamConstraint,
            "Team not found should be categorized as team constraint"
        )
        
        XCTAssertEqual(
            errorHandler.categorizeError(ExitFeeError.alreadyOnTeam),
            .teamConstraint,
            "Already on team should be categorized as team constraint"
        )
    }
    
    func testCategorizeError_WithNSURLErrors_ReturnsCorrectCategories() {
        // Test network error categorization
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(timeoutError),
            .timeout,
            "URL timeout error should be categorized as timeout"
        )
        
        let networkLostError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(networkLostError),
            .timeout,
            "Network connection lost should be categorized as timeout"
        )
        
        let noInternetError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(noInternetError),
            .networkError,
            "No internet error should be categorized as network error"
        )
        
        let cancelledError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(cancelledError),
            .userCancellation,
            "Cancelled error should be categorized as user cancellation"
        )
    }
    
    func testCategorizeError_WithCustomDomainErrors_ReturnsCorrectCategories() {
        // Test CoinOS error categorization
        let insufficientBalanceError = NSError(domain: "CoinOSError", code: 1001, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(insufficientBalanceError),
            .insufficientFunds,
            "CoinOS insufficient balance should be categorized correctly"
        )
        
        let coinOSTimeoutError = NSError(domain: "CoinOSError", code: 1002, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(coinOSTimeoutError),
            .timeout,
            "CoinOS timeout should be categorized correctly"
        )
        
        let lightningError = NSError(domain: "CoinOSError", code: 1003, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(lightningError),
            .lightningNetwork,
            "CoinOS lightning error should be categorized correctly"
        )
        
        // Test Supabase error categorization
        let notFoundError = NSError(domain: "SupabaseError", code: 404, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(notFoundError),
            .validationError,
            "Supabase 404 should be categorized as validation error"
        )
        
        let conflictError = NSError(domain: "SupabaseError", code: 409, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(conflictError),
            .teamConstraint,
            "Supabase 409 should be categorized as team constraint"
        )
        
        let serverError = NSError(domain: "SupabaseError", code: 500, userInfo: nil)
        XCTAssertEqual(
            errorHandler.categorizeError(serverError),
            .systemError,
            "Supabase 500 should be categorized as system error"
        )
    }
    
    func testCategorizeError_WithDescriptionPatterns_ReturnsCorrectCategories() {
        // Test error description pattern matching
        let insufficientError = NSError(domain: "CustomError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Insufficient balance to complete transaction"
        ])
        XCTAssertEqual(
            errorHandler.categorizeError(insufficientError),
            .insufficientFunds,
            "Should detect insufficient funds from description"
        )
        
        let timeoutError = NSError(domain: "CustomError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Operation timed out after 30 seconds"
        ])
        XCTAssertEqual(
            errorHandler.categorizeError(timeoutError),
            .timeout,
            "Should detect timeout from description"
        )
        
        let networkError = NSError(domain: "CustomError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Network connection failed"
        ])
        XCTAssertEqual(
            errorHandler.categorizeError(networkError),
            .networkError,
            "Should detect network error from description"
        )
        
        let cancelError = NSError(domain: "CustomError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "User cancelled the operation"
        ])
        XCTAssertEqual(
            errorHandler.categorizeError(cancelError),
            .userCancellation,
            "Should detect cancellation from description"
        )
        
        let lightningError = NSError(domain: "CustomError", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Lightning invoice payment failed"
        ])
        XCTAssertEqual(
            errorHandler.categorizeError(lightningError),
            .lightningNetwork,
            "Should detect lightning error from description"
        )
    }
    
    // MARK: - User-Friendly Message Tests
    
    func testGetUserFriendlyMessage_ForInsufficientFunds_ReturnsCorrectMessage() {
        let message = errorHandler.getUserFriendlyMessage(for: ExitFeeError.insufficientFunds)
        
        XCTAssertEqual(message.title, "Insufficient Funds", "Should have correct title")
        XCTAssertTrue(message.message.contains("2,000 sats"), "Should mention exit fee amount")
        XCTAssertTrue(message.message.contains("add funds"), "Should suggest adding funds")
        XCTAssertEqual(message.actionButtonTitle, "Add Funds", "Should have add funds button")
        XCTAssertEqual(message.secondaryActionTitle, "Cancel", "Should have cancel option")
        XCTAssertTrue(message.canRetry, "Should be retryable after adding funds")
        XCTAssertNotNil(message.helpUrl, "Should have help URL")
    }
    
    func testGetUserFriendlyMessage_ForPaymentTimeout_ReturnsCorrectMessage() {
        let message = errorHandler.getUserFriendlyMessage(for: ExitFeeError.paymentTimeout)
        
        XCTAssertEqual(message.title, "Payment Timed Out", "Should have correct title")
        XCTAssertTrue(message.message.contains("too long"), "Should explain timeout")
        XCTAssertTrue(message.message.contains("team membership is unchanged"), "Should reassure user")
        XCTAssertEqual(message.actionButtonTitle, "Try Again", "Should have retry option")
        XCTAssertTrue(message.canRetry, "Should be retryable")
        XCTAssertNotNil(message.helpUrl, "Should have help URL")
    }
    
    func testGetUserFriendlyMessage_ForAlreadyOnTeam_ReturnsCorrectMessage() {
        let message = errorHandler.getUserFriendlyMessage(for: ExitFeeError.alreadyOnTeam)
        
        XCTAssertEqual(message.title, "Already on Team", "Should have correct title")
        XCTAssertTrue(message.message.contains("one team at a time"), "Should explain constraint")
        XCTAssertTrue(message.message.contains("2,000 sats exit fee"), "Should mention exit fee")
        XCTAssertEqual(message.actionButtonTitle, "Switch Teams", "Should offer team switching")
        XCTAssertFalse(message.canRetry, "Should not be directly retryable")
    }
    
    func testGetUserFriendlyMessage_ForTeamFull_ReturnsCorrectMessage() {
        let message = errorHandler.getUserFriendlyMessage(for: ExitFeeError.teamFull)
        
        XCTAssertEqual(message.title, "Team Full", "Should have correct title")
        XCTAssertTrue(message.message.contains("maximum number of members"), "Should explain the issue")
        XCTAssertTrue(message.message.contains("choose a different team"), "Should suggest alternative")
        XCTAssertEqual(message.actionButtonTitle, "Browse Teams", "Should offer team browsing")
        XCTAssertFalse(message.canRetry, "Should not be retryable for same team")
    }
    
    func testGetUserFriendlyMessage_ForOperationInProgress_ReturnsCorrectMessage() {
        let message = errorHandler.getUserFriendlyMessage(for: ExitFeeError.operationInProgress)
        
        XCTAssertEqual(message.title, "Operation in Progress", "Should have correct title")
        XCTAssertTrue(message.message.contains("already have"), "Should explain existing operation")
        XCTAssertTrue(message.message.contains("wait for it to complete"), "Should explain what to do")
        XCTAssertEqual(message.actionButtonTitle, "Check Status", "Should offer status check")
        XCTAssertFalse(message.canRetry, "Should not be directly retryable")
    }
    
    func testGetUserFriendlyMessage_ForGenericError_ReturnsReasonableMessage() {
        let genericError = NSError(domain: "UnknownError", code: 999, userInfo: [
            NSLocalizedDescriptionKey: "Some unknown error occurred"
        ])
        
        let message = errorHandler.getUserFriendlyMessage(for: genericError)
        
        XCTAssertEqual(message.title, "Unexpected Error", "Should have generic title")
        XCTAssertTrue(message.message.contains("went wrong"), "Should acknowledge the error")
        XCTAssertTrue(message.message.contains("try again"), "Should suggest retry")
        XCTAssertTrue(message.message.contains("contact support"), "Should offer support option")
        XCTAssertEqual(message.actionButtonTitle, "Try Again", "Should have retry option")
        XCTAssertEqual(message.secondaryActionTitle, "Contact Support", "Should have support option")
        XCTAssertTrue(message.canRetry, "Should be retryable")
        XCTAssertNotNil(message.helpUrl, "Should have help URL")
    }
    
    // MARK: - Retry Logic Tests
    
    func testShouldRetry_WithNonRetryableErrors_ReturnsFalse() {
        // User cancellation should not be retried
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.insufficientFunds, attemptCount: 1),
            "Insufficient funds should not be retried"
        )
        
        // Team constraints should not be retried
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.alreadyOnTeam, attemptCount: 1),
            "Already on team should not be retried"
        )
        
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.teamFull, attemptCount: 1),
            "Team full should not be retried"
        )
        
        // Validation errors should not be retried
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.invalidOperation, attemptCount: 1),
            "Invalid operation should not be retried"
        )
    }
    
    func testShouldRetry_WithRetryableErrors_ReturnsCorrectly() {
        // Network errors should be retried (up to limit)
        XCTAssertTrue(
            errorHandler.shouldRetry(error: ExitFeeError.networkError, attemptCount: 1),
            "Network error should be retried on first attempt"
        )
        
        XCTAssertTrue(
            errorHandler.shouldRetry(error: ExitFeeError.networkError, attemptCount: 2),
            "Network error should be retried on second attempt"
        )
        
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.networkError, attemptCount: 3),
            "Network error should not be retried after 3 attempts"
        )
        
        // Payment failures should be retried (fewer times)
        XCTAssertTrue(
            errorHandler.shouldRetry(error: ExitFeeError.paymentFailed, attemptCount: 1),
            "Payment failed should be retried on first attempt"
        )
        
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.paymentFailed, attemptCount: 2),
            "Payment failed should not be retried after 2 attempts"
        )
        
        // Timeout errors should be retried
        XCTAssertTrue(
            errorHandler.shouldRetry(error: ExitFeeError.paymentTimeout, attemptCount: 1),
            "Payment timeout should be retried"
        )
    }
    
    func testShouldRetry_WithMaxAttempts_ReturnsFalse() {
        // Should never retry beyond max attempts regardless of error type
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.networkError, attemptCount: 5, maxAttempts: 3),
            "Should not retry beyond max attempts"
        )
        
        XCTAssertFalse(
            errorHandler.shouldRetry(error: ExitFeeError.paymentTimeout, attemptCount: 4, maxAttempts: 3),
            "Should not retry beyond max attempts even for retryable errors"
        )
    }
    
    func testGetRetryDelay_WithDifferentCategories_ReturnsAppropriateDelays() {
        // Network errors should have shorter delays
        let networkDelay = errorHandler.getRetryDelay(attemptCount: 1, category: .networkError)
        XCTAssertLessThan(networkDelay, 5.0, "Network error delay should be short")
        XCTAssertGreaterThan(networkDelay, 1.0, "Network error delay should not be too short")
        
        // Payment errors should have longer delays
        let paymentDelay = errorHandler.getRetryDelay(attemptCount: 1, category: .paymentFailure)
        XCTAssertGreaterThan(paymentDelay, networkDelay, "Payment delays should be longer than network delays")
        
        // System errors should have even longer delays
        let systemDelay = errorHandler.getRetryDelay(attemptCount: 1, category: .systemError)
        XCTAssertGreaterThan(systemDelay, paymentDelay, "System error delays should be longest")
        
        // Delays should increase exponentially
        let firstAttempt = errorHandler.getRetryDelay(attemptCount: 1, category: .networkError)
        let secondAttempt = errorHandler.getRetryDelay(attemptCount: 2, category: .networkError)
        XCTAssertGreaterThan(secondAttempt, firstAttempt, "Delays should increase with attempt count")
        
        // Delays should be capped
        let longDelay = errorHandler.getRetryDelay(attemptCount: 10, category: .systemError)
        XCTAssertLessThanOrEqual(longDelay, 30.0, "Delays should be capped at 30 seconds")
    }
    
    // MARK: - Error Logging Tests
    
    func testLogError_WithValidOperation_LogsCorrectly() {
        let mockOperation = ExitFeeOperation(
            id: "test-operation",
            paymentIntentId: "test-intent",
            userId: "test-user",
            fromTeamId: "test-from-team",
            toTeamId: "test-to-team",
            amount: 2000,
            lightningAddress: "RUNSTR@coinos.io",
            status: .failed,
            paymentHash: nil,
            invoiceText: nil,
            retryCount: 1,
            errorMessage: "Test error message",
            createdAt: Date(),
            completedAt: nil
        )
        
        let context = ErrorContext(
            operationId: mockOperation.id,
            userId: mockOperation.userId,
            teamId: mockOperation.fromTeamId,
            attemptNumber: 2
        )
        
        // This should not crash
        XCTAssertNoThrow(
            errorHandler.logError(
                operation: mockOperation,
                error: ExitFeeError.paymentFailed,
                context: context
            )
        )
    }
    
    // MARK: - Error Context Tests
    
    func testErrorContext_InitializesWithDefaults() {
        let context = ErrorContext()
        
        XCTAssertNil(context.operationId, "Operation ID should default to nil")
        XCTAssertNil(context.userId, "User ID should default to nil")
        XCTAssertNil(context.teamId, "Team ID should default to nil")
        XCTAssertEqual(context.attemptNumber, 1, "Attempt number should default to 1")
        XCTAssertTrue(context.additionalInfo.isEmpty, "Additional info should default to empty")
        
        // Timestamp should be recent
        let now = Date()
        XCTAssertLessThan(abs(context.timestamp.timeIntervalSince(now)), 1.0, "Timestamp should be current")
    }
    
    func testErrorContext_InitializesWithProvidedValues() {
        let additionalInfo = ["key": "value", "retry": "true"]
        let testDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let context = ErrorContext(
            operationId: "test-op",
            userId: "test-user",
            teamId: "test-team",
            attemptNumber: 3,
            timestamp: testDate,
            additionalInfo: additionalInfo
        )
        
        XCTAssertEqual(context.operationId, "test-op")
        XCTAssertEqual(context.userId, "test-user")
        XCTAssertEqual(context.teamId, "test-team")
        XCTAssertEqual(context.attemptNumber, 3)
        XCTAssertEqual(context.timestamp, testDate)
        XCTAssertEqual(context.additionalInfo["key"] as? String, "value")
        XCTAssertEqual(context.additionalInfo["retry"] as? String, "true")
    }
    
    // MARK: - UserErrorMessage Tests
    
    func testUserErrorMessage_InitializesCorrectly() {
        let message = UserErrorMessage(
            title: "Test Title",
            message: "Test message",
            actionButtonTitle: "Test Action",
            secondaryActionTitle: "Secondary Action",
            helpUrl: "https://help.example.com",
            canRetry: true
        )
        
        XCTAssertEqual(message.title, "Test Title")
        XCTAssertEqual(message.message, "Test message")
        XCTAssertEqual(message.actionButtonTitle, "Test Action")
        XCTAssertEqual(message.secondaryActionTitle, "Secondary Action")
        XCTAssertEqual(message.helpUrl, "https://help.example.com")
        XCTAssertTrue(message.canRetry)
    }
    
    func testUserErrorMessage_InitializesWithDefaults() {
        let message = UserErrorMessage(title: "Title", message: "Message")
        
        XCTAssertEqual(message.title, "Title")
        XCTAssertEqual(message.message, "Message")
        XCTAssertNil(message.actionButtonTitle)
        XCTAssertNil(message.secondaryActionTitle)
        XCTAssertNil(message.helpUrl)
        XCTAssertFalse(message.canRetry)
    }
}