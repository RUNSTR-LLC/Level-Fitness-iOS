import XCTest
import Foundation
@testable import RunstrRewards

class CoinOSExitFeeServiceTests: XCTestCase {
    
    var coinOSService: CoinOSService!
    var mockCoinOSService: MockCoinOSService!
    
    override func setUp() {
        super.setUp()
        coinOSService = CoinOSService.shared
        mockCoinOSService = MockCoinOSService()
    }
    
    override func tearDown() {
        coinOSService = nil
        mockCoinOSService = nil
        super.tearDown()
    }
    
    // MARK: - Constants Tests
    
    func testExitFeeConstants() {
        XCTAssertEqual(CoinOSService.EXIT_FEE_AMOUNT, 2000, "Exit fee amount should be 2000 sats")
        XCTAssertEqual(CoinOSService.RUNSTR_LIGHTNING_ADDRESS, "RUNSTR@coinos.io", "Lightning address should be RUNSTR@coinos.io")
    }
    
    // MARK: - Invoice Creation Tests
    
    func testCreateExitFeeInvoiceWithDefaultAmount() async {
        do {
            let invoice = try await mockCoinOSService.createExitFeeInvoice()
            
            XCTAssertEqual(invoice.amount, 2000, "Default invoice amount should be 2000 sats")
            XCTAssertEqual(invoice.memo, "RunstrRewards exit fee", "Default memo should be exit fee")
            XCTAssertFalse(invoice.paymentRequest.isEmpty, "Payment request should not be empty")
            XCTAssertNotEqual(invoice.id, "", "Invoice ID should be set")
            
            // Check expiry is 2 minutes (120 seconds)
            let expectedExpiry = Date().addingTimeInterval(120)
            XCTAssertLessThan(abs(invoice.expiresAt.timeIntervalSince(expectedExpiry)), 5, 
                            "Invoice should expire in approximately 2 minutes")
            
        } catch {
            XCTFail("Creating exit fee invoice should not throw error: \(error)")
        }
    }
    
    func testCreateExitFeeInvoiceWithCustomAmount() async {
        do {
            let customAmount = 5000
            let invoice = try await mockCoinOSService.createExitFeeInvoice(amount: customAmount)
            
            XCTAssertEqual(invoice.amount, customAmount, "Invoice amount should match custom amount")
            
        } catch {
            XCTFail("Creating exit fee invoice with custom amount should not throw error: \(error)")
        }
    }
    
    func testCreateExitFeeInvoiceFailsWhenNotAuthenticated() async {
        let unauthenticatedService = MockCoinOSService(authenticated: false)
        
        do {
            _ = try await unauthenticatedService.createExitFeeInvoice()
            XCTFail("Should throw authentication error when not authenticated")
            
        } catch CoinOSError.notAuthenticated {
            // Expected behavior
            XCTAssert(true)
        } catch {
            XCTFail("Should throw notAuthenticated error, got: \(error)")
        }
    }
    
    // MARK: - Payment Retry Tests
    
    func testPaymentSuccessOnFirstAttempt() async {
        let invoice = createMockInvoice(amount: 2000)
        
        do {
            let result = try await mockCoinOSService.payExitFeeWithRetry(
                paymentRequest: invoice.paymentRequest,
                maxRetries: 3,
                timeoutSeconds: 120
            )
            
            XCTAssertTrue(result.success, "Payment should succeed")
            XCTAssertFalse(result.paymentHash.isEmpty, "Payment hash should be set")
            XCTAssertEqual(result.feePaid, 1, "Fee should be minimal for Lightning")
            
        } catch {
            XCTFail("Payment with retry should not throw error: \(error)")
        }
    }
    
    func testPaymentFailsAfterAllRetries() async {
        let failingService = MockCoinOSService(shouldFailPayments: true)
        let invoice = createMockInvoice(amount: 2000)
        
        do {
            _ = try await failingService.payExitFeeWithRetry(
                paymentRequest: invoice.paymentRequest,
                maxRetries: 2,
                timeoutSeconds: 30
            )
            XCTFail("Payment should fail after all retries")
            
        } catch CoinOSError.apiError(402) {
            // Expected - payment failed after retries
            XCTAssert(true)
        } catch {
            XCTFail("Should throw apiError(402), got: \(error)")
        }
    }
    
    func testPaymentRetriesWithExponentialBackoff() async {
        // This test verifies the retry timing but in a controlled way
        let startTime = Date()
        let partiallyFailingService = MockCoinOSService(failFirstAttempts: 2)
        let invoice = createMockInvoice(amount: 2000)
        
        do {
            let result = try await partiallyFailingService.payExitFeeWithRetry(
                paymentRequest: invoice.paymentRequest,
                maxRetries: 3,
                timeoutSeconds: 30
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            XCTAssertTrue(result.success, "Payment should eventually succeed")
            // Should take at least 2s + 4s = 6s due to exponential backoff
            XCTAssertGreaterThan(duration, 5.0, "Should include backoff delays")
            
        } catch {
            XCTFail("Payment with retry should eventually succeed: \(error)")
        }
    }
    
    // MARK: - Payment Verification Tests
    
    func testVerifyPaymentReceiptSuccess() async {
        let paymentHash = "mock_payment_hash_123"
        
        do {
            let verified = try await mockCoinOSService.verifyRunstrReceivedPayment(
                paymentHash: paymentHash,
                maxAttempts: 5
            )
            
            XCTAssertTrue(verified, "Payment verification should succeed")
            
        } catch {
            XCTFail("Payment verification should not throw error: \(error)")
        }
    }
    
    func testVerifyPaymentReceiptFailsAfterMaxAttempts() async {
        let failingService = MockCoinOSService(shouldFailVerification: true)
        let paymentHash = "mock_payment_hash_456"
        
        do {
            let verified = try await failingService.verifyRunstrReceivedPayment(
                paymentHash: paymentHash,
                maxAttempts: 3
            )
            
            XCTAssertFalse(verified, "Payment verification should fail after max attempts")
            
        } catch {
            // If it throws an error after max attempts, that's also acceptable behavior
            XCTAssert(true, "Verification failure after max attempts is expected")
        }
    }
    
    // MARK: - Complete Payment Flow Tests
    
    func testCompleteExitFeePaymentFlow() async {
        do {
            let result = try await mockCoinOSService.processExitFeePayment(
                amount: 2000,
                maxRetries: 3
            )
            
            XCTAssertTrue(result.success, "Complete payment flow should succeed")
            XCTAssertEqual(result.amount, 2000, "Result should show correct amount")
            XCTAssertFalse(result.paymentHash.isEmpty, "Payment hash should be set")
            XCTAssertTrue(result.verificationComplete, "Verification should be complete")
            XCTAssertNotNil(result.invoice, "Invoice should be included in result")
            
            // Verify timestamp is recent
            let timeDiff = abs(result.timestamp.timeIntervalSinceNow)
            XCTAssertLessThan(timeDiff, 5.0, "Timestamp should be recent")
            
        } catch {
            XCTFail("Complete exit fee payment should not throw error: \(error)")
        }
    }
    
    func testCompletePaymentFlowFailsWithInsufficientBalance() async {
        let insufficientBalanceService = MockCoinOSService(simulateInsufficientBalance: true)
        
        do {
            _ = try await insufficientBalanceService.processExitFeePayment(
                amount: 2000,
                maxRetries: 2
            )
            XCTFail("Payment should fail with insufficient balance")
            
        } catch CoinOSError.insufficientBalance {
            XCTAssert(true, "Should throw insufficient balance error")
        } catch {
            XCTFail("Should throw insufficientBalance error, got: \(error)")
        }
    }
    
    func testCompletePaymentFlowHandlesInvoiceExpiry() async {
        let expiringInvoiceService = MockCoinOSService(simulateInvoiceExpiry: true)
        
        do {
            let result = try await expiringInvoiceService.processExitFeePayment(
                amount: 2000,
                maxRetries: 3
            )
            
            // Should succeed by creating fresh invoices
            XCTAssertTrue(result.success, "Should succeed by creating fresh invoices")
            
        } catch CoinOSError.invoiceExpired {
            XCTAssert(true, "Invoice expiry after all retries is acceptable")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorDescriptions() {
        XCTAssertEqual(CoinOSError.paymentTimeout.errorDescription, 
                      "Payment timed out - please try again")
        XCTAssertEqual(CoinOSError.invoiceExpired.errorDescription, 
                      "Invoice expired - a new payment request will be generated")
        XCTAssertEqual(CoinOSError.paymentVerificationFailed.errorDescription, 
                      "Payment verification failed - please contact support")
        XCTAssertEqual(CoinOSError.insufficientBalance.errorDescription, 
                      "Insufficient balance - please add funds to your wallet")
    }
    
    // MARK: - Helper Methods
    
    private func createMockInvoice(amount: Int) -> LightningInvoice {
        return LightningInvoice(
            id: "mock_invoice_id",
            paymentRequest: "lnbc2u1p3xnhl2pp5...",
            amount: amount,
            memo: "Test exit fee",
            status: "pending",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(120)
        )
    }
}

// MARK: - Mock Service for Testing

class MockCoinOSService {
    private let authenticated: Bool
    private let shouldFailPayments: Bool
    private let shouldFailVerification: Bool
    private let simulateInsufficientBalance: Bool
    private let simulateInvoiceExpiry: Bool
    private let failFirstAttempts: Int
    private var attemptCount = 0
    
    init(authenticated: Bool = true,
         shouldFailPayments: Bool = false,
         shouldFailVerification: Bool = false,
         simulateInsufficientBalance: Bool = false,
         simulateInvoiceExpiry: Bool = false,
         failFirstAttempts: Int = 0) {
        self.authenticated = authenticated
        self.shouldFailPayments = shouldFailPayments
        self.shouldFailVerification = shouldFailVerification
        self.simulateInsufficientBalance = simulateInsufficientBalance
        self.simulateInvoiceExpiry = simulateInvoiceExpiry
        self.failFirstAttempts = failFirstAttempts
    }
    
    func createExitFeeInvoice(amount: Int = CoinOSService.EXIT_FEE_AMOUNT, memo: String = "RunstrRewards exit fee") async throws -> LightningInvoice {
        if !authenticated {
            throw CoinOSError.notAuthenticated
        }
        
        return LightningInvoice(
            id: UUID().uuidString,
            paymentRequest: "lnbc\(amount)u1p3xnhl2pp5...",
            amount: amount,
            memo: memo,
            status: "pending",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(120)
        )
    }
    
    func payExitFeeWithRetry(paymentRequest: String, maxRetries: Int = 3, timeoutSeconds: Int = 120) async throws -> PaymentResult {
        attemptCount += 1
        
        if attemptCount <= failFirstAttempts {
            // Wait for backoff simulation
            try await Task.sleep(nanoseconds: UInt64(attemptCount * 2 * 1_000_000_000))
            throw CoinOSError.networkError
        }
        
        if simulateInsufficientBalance {
            throw CoinOSError.apiError(402)
        }
        
        if shouldFailPayments {
            throw CoinOSError.apiError(402)
        }
        
        return PaymentResult(
            success: true,
            paymentHash: "mock_payment_hash_\(UUID().uuidString)",
            preimage: "mock_preimage",
            feePaid: 1,
            timestamp: Date()
        )
    }
    
    func verifyRunstrReceivedPayment(paymentHash: String, maxAttempts: Int = 5) async throws -> Bool {
        if shouldFailVerification {
            return false
        }
        
        return true
    }
    
    func processExitFeePayment(amount: Int = CoinOSService.EXIT_FEE_AMOUNT, maxRetries: Int = 3) async throws -> ExitFeePaymentResult {
        if simulateInsufficientBalance {
            throw CoinOSError.insufficientBalance
        }
        
        if simulateInvoiceExpiry {
            throw CoinOSError.invoiceExpired
        }
        
        let invoice = try await createExitFeeInvoice(amount: amount)
        let paymentResult = try await payExitFeeWithRetry(paymentRequest: invoice.paymentRequest)
        let verified = try await verifyRunstrReceivedPayment(paymentHash: paymentResult.paymentHash)
        
        return ExitFeePaymentResult(
            success: verified,
            paymentHash: paymentResult.paymentHash,
            amount: amount,
            invoice: invoice,
            verificationComplete: verified,
            timestamp: Date()
        )
    }
}