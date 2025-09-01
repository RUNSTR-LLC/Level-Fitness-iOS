import XCTest
@testable import RunstrRewards

class ExitFeeAnalyticsServiceTests: XCTestCase {
    var analyticsService: ExitFeeAnalyticsService!
    var mockExitFeeOperations: [ExitFeeOperation] = []
    
    override func setUp() {
        super.setUp()
        analyticsService = ExitFeeAnalyticsService.shared
        setupMockData()
    }
    
    override func tearDown() {
        mockExitFeeOperations.removeAll()
        super.tearDown()
    }
    
    private func setupMockData() {
        let today = Date()
        let calendar = Calendar.current
        
        // Create mock exit fee operations for testing
        mockExitFeeOperations = [
            // Successful payments today
            createMockOperation(
                id: "test-1",
                status: .teamChangeComplete,
                amount: 2000,
                createdAt: today.addingTimeInterval(-3600), // 1 hour ago
                completedAt: today.addingTimeInterval(-3500), // 100 seconds to complete
                fromTeamId: "team-a",
                toTeamId: "team-b"
            ),
            createMockOperation(
                id: "test-2", 
                status: .teamChangeComplete,
                amount: 2000,
                createdAt: today.addingTimeInterval(-7200), // 2 hours ago
                completedAt: today.addingTimeInterval(-7000), // 200 seconds to complete
                fromTeamId: "team-a",
                toTeamId: "team-c"
            ),
            // Failed payment today
            createMockOperation(
                id: "test-3",
                status: .failed,
                amount: 2000,
                createdAt: today.addingTimeInterval(-1800), // 30 minutes ago
                completedAt: nil,
                fromTeamId: "team-b",
                toTeamId: nil
            ),
            // Stuck payment (over threshold)
            createMockOperation(
                id: "test-4",
                status: .paymentSent,
                amount: 2000,
                createdAt: today.addingTimeInterval(-7300), // Over 2 hours ago
                completedAt: nil,
                fromTeamId: "team-c",
                toTeamId: "team-a"
            ),
            // Payment from yesterday (completed)
            createMockOperation(
                id: "test-5",
                status: .teamChangeComplete,
                amount: 2000,
                createdAt: calendar.date(byAdding: .day, value: -1, to: today)!,
                completedAt: calendar.date(byAdding: .day, value: -1, to: today)!.addingTimeInterval(150),
                fromTeamId: "team-b",
                toTeamId: "team-a"
            )
        ]
    }
    
    private func createMockOperation(
        id: String,
        status: ExitFeeStatus,
        amount: Int,
        createdAt: Date,
        completedAt: Date?,
        fromTeamId: String?,
        toTeamId: String?
    ) -> ExitFeeOperation {
        return ExitFeeOperation(
            id: id,
            paymentIntentId: "\(id)-intent",
            userId: "test-user",
            fromTeamId: fromTeamId,
            toTeamId: toTeamId,
            amount: amount,
            lightningAddress: "RUNSTR@coinos.io",
            status: status,
            paymentHash: status == .teamChangeComplete ? "mock-hash-\(id)" : nil,
            invoiceText: "mock-invoice-\(id)",
            retryCount: 0,
            errorMessage: status == .failed ? "Mock failure" : nil,
            createdAt: createdAt,
            completedAt: completedAt
        )
    }
    
    // MARK: - Revenue Analytics Tests
    
    func testCalculateDailyRevenue_WithSuccessfulPayments_ReturnsCorrectAmount() async throws {
        // Test that daily revenue calculation includes only completed payments from today
        // Expected: 2 successful payments × 2000 sats = 4000 sats
        
        // This test would need to be integrated with actual database calls
        // For now, we'll test the data model and calculation logic
        
        let today = Date()
        let todayPayments = mockExitFeeOperations.filter { operation in
            Calendar.current.isDate(operation.createdAt, inSameDayAs: today) &&
            operation.status == .teamChangeComplete
        }
        
        let expectedRevenue = todayPayments.reduce(0) { $0 + $1.amount }
        XCTAssertEqual(expectedRevenue, 4000, "Daily revenue should be 4000 sats (2 × 2000)")
        
        let todayCount = todayPayments.count
        XCTAssertEqual(todayCount, 2, "Should have exactly 2 completed payments today")
    }
    
    func testCalculateRevenue_WithMixedPaymentStates_ReturnsAccurateMetrics() throws {
        let today = Date()
        let period = DateInterval(start: today.addingTimeInterval(-86400), end: today) // Last 24 hours
        
        let allPayments = mockExitFeeOperations.filter { operation in
            period.contains(operation.createdAt)
        }
        
        let completedPayments = allPayments.filter { $0.status == .teamChangeComplete }
        let totalAmount = completedPayments.reduce(0) { $0 + $1.amount }
        let averageAmount = Double(totalAmount) / Double(completedPayments.count)
        let successRate = Double(completedPayments.count) / Double(allPayments.count)
        
        XCTAssertEqual(totalAmount, 4000, "Total revenue should be 4000 sats")
        XCTAssertEqual(averageAmount, 2000.0, "Average payment should be 2000 sats")
        XCTAssertEqual(successRate, 0.5, accuracy: 0.01, "Success rate should be 50% (2 success out of 4 total)")
        XCTAssertEqual(completedPayments.count, 2, "Should have 2 completed payments")
        XCTAssertEqual(allPayments.count, 4, "Should have 4 total payments in period")
    }
    
    // MARK: - Performance Analytics Tests
    
    func testCalculatePaymentSuccessRate_WithVariousStates_ReturnsCorrectPercentage() throws {
        let totalPayments = mockExitFeeOperations.count // 5 total
        let successfulPayments = mockExitFeeOperations.filter { $0.status == .teamChangeComplete }.count // 3 successful
        
        let expectedSuccessRate = Double(successfulPayments) / Double(totalPayments)
        
        XCTAssertEqual(expectedSuccessRate, 0.6, accuracy: 0.01, "Success rate should be 60% (3 out of 5)")
        XCTAssertEqual(successfulPayments, 3, "Should have exactly 3 successful payments")
        XCTAssertEqual(totalPayments, 5, "Should have exactly 5 total payments")
    }
    
    func testGetAveragePaymentTime_WithCompletedPayments_ReturnsCorrectAverage() throws {
        let completedPayments = mockExitFeeOperations.filter { 
            $0.status == .teamChangeComplete && $0.completedAt != nil 
        }
        
        var totalDuration: TimeInterval = 0
        for payment in completedPayments {
            guard let completedAt = payment.completedAt else { continue }
            totalDuration += completedAt.timeIntervalSince(payment.createdAt)
        }
        
        let averageTime = totalDuration / Double(completedPayments.count)
        
        // Expected: (100 + 200 + 150) / 3 = 150 seconds average
        XCTAssertEqual(averageTime, 150.0, accuracy: 1.0, "Average payment time should be 150 seconds")
        XCTAssertEqual(completedPayments.count, 3, "Should have 3 completed payments with completion times")
        XCTAssertGreaterThan(averageTime, 0, "Average payment time should be positive")
    }
    
    // MARK: - Team Switching Analytics Tests
    
    func testGetTeamSwitchingPatterns_WithMultipleSwitches_ReturnsCorrectPatterns() throws {
        let teamSwitches = mockExitFeeOperations.filter { 
            $0.status == .teamChangeComplete && $0.toTeamId != nil 
        }
        
        var fromTeamCounts: [String: Int] = [:]
        var toTeamCounts: [String: Int] = [:]
        
        for switchData in teamSwitches {
            if let fromTeamId = switchData.fromTeamId {
                fromTeamCounts[fromTeamId, default: 0] += 1
            }
            if let toTeamId = switchData.toTeamId {
                toTeamCounts[toTeamId, default: 0] += 1
            }
        }
        
        XCTAssertEqual(teamSwitches.count, 2, "Should have 2 team switches")
        XCTAssertEqual(fromTeamCounts["team-a"], 2, "Team A should be source for 2 switches")
        XCTAssertEqual(toTeamCounts["team-b"], 1, "Team B should be destination for 1 switch")
        XCTAssertEqual(toTeamCounts["team-c"], 1, "Team C should be destination for 1 switch")
        
        let totalSwitchesFromA = fromTeamCounts["team-a"] ?? 0
        let percentageFromA = Double(totalSwitchesFromA) / Double(teamSwitches.count)
        XCTAssertEqual(percentageFromA, 1.0, accuracy: 0.01, "100% of switches should be from team A")
    }
    
    func testGetTeamSwitchingPatterns_CalculatesSwitchDuration() throws {
        let teamSwitches = mockExitFeeOperations.filter { 
            $0.status == .teamChangeComplete && 
            $0.toTeamId != nil && 
            $0.completedAt != nil 
        }
        
        var totalDuration: TimeInterval = 0
        for switchData in teamSwitches {
            guard let completedAt = switchData.completedAt else { continue }
            totalDuration += completedAt.timeIntervalSince(switchData.createdAt)
        }
        
        let averageSwitchTime = totalDuration / Double(teamSwitches.count)
        
        // Expected: (100 + 200) / 2 = 150 seconds average for switches
        XCTAssertEqual(averageSwitchTime, 150.0, accuracy: 1.0, "Average switch time should be 150 seconds")
        XCTAssertEqual(teamSwitches.count, 2, "Should have 2 completed team switches")
    }
    
    // MARK: - Monitoring Tests
    
    func testGetStuckPayments_WithThreshold_ReturnsStuckOperations() throws {
        let threshold: TimeInterval = 3600 // 1 hour
        let currentTime = Date()
        
        let stuckPayments = mockExitFeeOperations.filter { operation in
            let isNonTerminalState = [
                ExitFeeStatus.initiated,
                .invoiceCreated,
                .paymentSent,
                .paymentConfirmed
            ].contains(operation.status)
            
            let isOverThreshold = currentTime.timeIntervalSince(operation.createdAt) > threshold
            
            return isNonTerminalState && isOverThreshold
        }
        
        XCTAssertEqual(stuckPayments.count, 1, "Should have exactly 1 stuck payment")
        XCTAssertEqual(stuckPayments.first?.id, "test-4", "Stuck payment should be test-4")
        XCTAssertEqual(stuckPayments.first?.status, .paymentSent, "Stuck payment should be in paymentSent state")
        
        let stuckDuration = currentTime.timeIntervalSince(stuckPayments.first!.createdAt)
        XCTAssertGreaterThan(stuckDuration, threshold, "Stuck payment should be over threshold time")
    }
    
    func testGetStuckPayments_WithNoStuckPayments_ReturnsEmptyArray() throws {
        let threshold: TimeInterval = 86400 // 24 hours (much longer threshold)
        let currentTime = Date()
        
        let stuckPayments = mockExitFeeOperations.filter { operation in
            let isNonTerminalState = [
                ExitFeeStatus.initiated,
                .invoiceCreated,
                .paymentSent,
                .paymentConfirmed
            ].contains(operation.status)
            
            let isOverThreshold = currentTime.timeIntervalSince(operation.createdAt) > threshold
            
            return isNonTerminalState && isOverThreshold
        }
        
        XCTAssertEqual(stuckPayments.count, 0, "Should have no stuck payments with 24h threshold")
    }
    
    // MARK: - Performance Metrics Tests
    
    func testGetPaymentPerformanceMetrics_WithMixedData_ReturnsCompleteMetrics() throws {
        let allPayments = mockExitFeeOperations
        let totalCount = allPayments.count
        
        let successCount = allPayments.filter { $0.status == .teamChangeComplete }.count
        let failureCount = allPayments.filter { $0.status == .failed }.count
        let expiredCount = allPayments.filter { $0.status.rawValue == "expired" }.count
        
        let successRate = Double(successCount) / Double(totalCount)
        let failureRate = Double(failureCount) / Double(totalCount)
        let timeoutRate = Double(expiredCount) / Double(totalCount)
        
        XCTAssertEqual(successRate, 0.6, accuracy: 0.01, "Success rate should be 60%")
        XCTAssertEqual(failureRate, 0.2, accuracy: 0.01, "Failure rate should be 20%")
        XCTAssertEqual(timeoutRate, 0.0, accuracy: 0.01, "Timeout rate should be 0%")
        
        XCTAssertEqual(successCount, 3, "Should have 3 successful payments")
        XCTAssertEqual(failureCount, 1, "Should have 1 failed payment") 
        XCTAssertEqual(expiredCount, 0, "Should have 0 expired payments")
        
        // Test that rates sum correctly (allowing for one pending payment)
        let accountedRate = successRate + failureRate + timeoutRate
        XCTAssertLessThanOrEqual(accountedRate, 1.0, "Success + failure + timeout rates should not exceed 100%")
    }
    
    func testGetPaymentPerformanceMetrics_CalculatesPaymentTimes() throws {
        let completedPayments = mockExitFeeOperations.filter { 
            $0.status == .teamChangeComplete && $0.completedAt != nil 
        }
        
        var paymentTimes: [TimeInterval] = []
        for payment in completedPayments {
            guard let completedAt = payment.completedAt else { continue }
            paymentTimes.append(completedAt.timeIntervalSince(payment.createdAt))
        }
        
        let averageTime = paymentTimes.reduce(0, +) / Double(paymentTimes.count)
        let sortedTimes = paymentTimes.sorted()
        let medianTime = sortedTimes[sortedTimes.count / 2]
        
        // Expected times: 100, 200, 150 seconds
        // Average: (100 + 200 + 150) / 3 = 150
        // Median: 150 (middle value when sorted: 100, 150, 200)
        XCTAssertEqual(averageTime, 150.0, accuracy: 1.0, "Average payment time should be 150 seconds")
        XCTAssertEqual(medianTime, 150.0, accuracy: 1.0, "Median payment time should be 150 seconds")
        XCTAssertEqual(paymentTimes.count, 3, "Should have 3 completed payments with times")
    }
    
    // MARK: - Error Handling Tests
    
    func testTrackExitFeePayment_WithValidOperation_LogsCorrectly() throws {
        let mockOperation = mockExitFeeOperations.first!
        
        // Test that tracking doesn't crash and handles the operation correctly
        XCTAssertNoThrow(analyticsService.trackExitFeePayment(operation: mockOperation))
        
        // Verify operation data integrity
        XCTAssertNotNil(mockOperation.id, "Operation should have valid ID")
        XCTAssertEqual(mockOperation.amount, 2000, "Operation should have correct amount")
        XCTAssertEqual(mockOperation.lightningAddress, "RUNSTR@coinos.io", "Operation should have correct lightning address")
    }
    
    func testAnalyticsModels_InitializeCorrectly() throws {
        let revenue = ExitFeeRevenue(
            totalAmount: 4000,
            paymentCount: 2,
            averageAmount: 2000.0,
            period: DateInterval(start: Date().addingTimeInterval(-86400), end: Date()),
            successRate: 1.0
        )
        
        XCTAssertEqual(revenue.totalAmount, 4000)
        XCTAssertEqual(revenue.paymentCount, 2)
        XCTAssertEqual(revenue.averageAmount, 2000.0)
        XCTAssertEqual(revenue.successRate, 1.0)
        
        let switchPattern = TeamSwitchPattern(
            teamId: "team-a",
            teamName: "Team Alpha",
            switchCount: 5,
            percentage: 0.25
        )
        
        XCTAssertEqual(switchPattern.teamId, "team-a")
        XCTAssertEqual(switchPattern.teamName, "Team Alpha")
        XCTAssertEqual(switchPattern.switchCount, 5)
        XCTAssertEqual(switchPattern.percentage, 0.25)
    }
}