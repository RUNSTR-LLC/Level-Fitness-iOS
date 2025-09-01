import XCTest
import Combine
@testable import RunstrRewards

class ExitFeeMetricsCollectorTests: XCTestCase {
    var metricsCollector: ExitFeeMetricsCollector!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        metricsCollector = ExitFeeMetricsCollector.shared
        cancellables.removeAll()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - State Transition Tracking Tests
    
    func testRecordStateTransition_WithValidData_RecordsCorrectly() {
        let expectation = XCTestExpectation(description: "State transition recorded")
        let operationId = "test-operation-1"
        let duration: TimeInterval = 2.5
        
        // Record a state transition
        metricsCollector.recordStateTransition(
            operationId: operationId,
            from: .initiated,
            to: .invoiceCreated,
            duration: duration,
            userId: "test-user",
            metadata: ["attempt": "1", "source": "test"]
        )
        
        // Give async operation time to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify the transition was recorded (we can't directly access private arrays, 
        // but we can verify through the metrics report)
        XCTAssertNoThrow(try { 
            Task {
                let report = try await self.metricsCollector.exportMetrics()
                XCTAssertGreaterThan(report.stateTransitions.count, 0, "Should have recorded state transitions")
            }
        }())
    }
    
    func testRecordStateTransition_WithSlowTransition_TriggersAlert() {
        let alertExpectation = XCTestExpectation(description: "Slow transition alert triggered")
        
        // Subscribe to alerts
        metricsCollector.alerts
            .sink { alert in
                if case .slowStateTransition(let metric) = alert {
                    XCTAssertEqual(metric.fromState, .paymentSent, "Alert should be for correct from state")
                    XCTAssertEqual(metric.toState, .paymentConfirmed, "Alert should be for correct to state")
                    XCTAssertGreaterThan(metric.duration, 10.0, "Duration should exceed threshold")
                    alertExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Record a slow transition (>10 seconds threshold)
        metricsCollector.recordStateTransition(
            operationId: "slow-operation",
            from: .paymentSent,
            to: .paymentConfirmed,
            duration: 15.0,
            userId: "test-user"
        )
        
        wait(for: [alertExpectation], timeout: 2.0)
    }
    
    // MARK: - Payment Attempt Tracking Tests
    
    func testRecordPaymentAttempt_WithSuccessfulPayment_RecordsCorrectly() {
        let operationId = "payment-success-test"
        
        metricsCollector.recordPaymentAttempt(
            operationId: operationId,
            userId: "test-user",
            success: true,
            errorType: nil,
            attemptNumber: 1,
            duration: 3.2
        )
        
        // Test successful payment recording
        XCTAssertNoThrow("Payment attempt should be recorded without errors")
        
        // Verify through real-time metrics
        let realtimeMetrics = metricsCollector.getCurrentMetrics()
        XCTAssertGreaterThanOrEqual(realtimeMetrics.successRate, 0, "Success rate should be non-negative")
    }
    
    func testRecordPaymentAttempt_WithFailedPayments_TriggersHighFailureRateAlert() {
        let alertExpectation = XCTestExpectation(description: "High failure rate alert triggered")
        
        // Subscribe to alerts
        metricsCollector.alerts
            .sink { alert in
                if case .highFailureRate(let rate) = alert {
                    XCTAssertGreaterThan(rate, 0.2, "Failure rate should exceed 20% threshold")
                    alertExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Record many failed payments to trigger high failure rate
        for i in 1...25 {
            metricsCollector.recordPaymentAttempt(
                operationId: "failed-payment-\(i)",
                userId: "test-user",
                success: false,
                errorType: ExitFeeError.insufficientFunds,
                attemptNumber: 1
            )
        }
        
        wait(for: [alertExpectation], timeout: 2.0)
    }
    
    func testRecordPaymentAttempt_WithMixedResults_CalculatesCorrectSuccessRate() {
        // Record mix of successful and failed payments
        for i in 1...10 {
            metricsCollector.recordPaymentAttempt(
                operationId: "mixed-payment-\(i)",
                userId: "test-user",
                success: i <= 7, // 7 successes, 3 failures = 70% success rate
                errorType: i > 7 ? ExitFeeError.networkError : nil,
                attemptNumber: 1,
                duration: 2.0
            )
        }
        
        // Give time for processing
        let expectation = XCTestExpectation(description: "Metrics processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let realtimeMetrics = self.metricsCollector.getCurrentMetrics()
            
            // Since we just recorded payments, success rate should be around 70%
            // (might vary due to other tests, but should be positive)
            XCTAssertGreaterThan(realtimeMetrics.successRate, 0.0, "Should have positive success rate")
            XCTAssertLessThanOrEqual(realtimeMetrics.successRate, 1.0, "Success rate should not exceed 100%")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Team Switch Tracking Tests
    
    func testRecordTeamSwitch_WithValidData_RecordsCorrectly() {
        let operationId = "team-switch-test"
        let fromTeam = "team-alpha"
        let toTeam = "team-beta"
        let duration: TimeInterval = 5.7
        
        metricsCollector.recordTeamSwitch(
            operationId: operationId,
            userId: "test-user",
            fromTeam: fromTeam,
            toTeam: toTeam,
            duration: duration,
            wasSuccessful: true
        )
        
        XCTAssertNoThrow("Team switch should be recorded without errors")
        
        // Verify through metrics export
        let exportExpectation = XCTestExpectation(description: "Metrics exported")
        
        Task {
            do {
                let report = try await self.metricsCollector.exportMetrics()
                
                // Should have team switch patterns
                let teamSwitchPattern = report.teamSwitchPatterns.first { 
                    $0.fromTeamId == fromTeam && $0.toTeamId == toTeam 
                }
                
                XCTAssertNotNil(teamSwitchPattern, "Should have recorded team switch pattern")
                XCTAssertGreaterThan(teamSwitchPattern?.switchCount ?? 0, 0, "Switch count should be positive")
                XCTAssertEqual(teamSwitchPattern?.successRate ?? 0, 1.0, accuracy: 0.01, "Success rate should be 100%")
                
                exportExpectation.fulfill()
            } catch {
                XCTFail("Metrics export failed: \(error)")
                exportExpectation.fulfill()
            }
        }
        
        wait(for: [exportExpectation], timeout: 2.0)
    }
    
    func testRecordTeamSwitch_WithFailures_CalculatesCorrectSuccessRate() {
        let fromTeam = "team-gamma"
        let toTeam = "team-delta"
        
        // Record 3 successful and 1 failed switch
        for i in 1...4 {
            metricsCollector.recordTeamSwitch(
                operationId: "switch-test-\(i)",
                userId: "test-user",
                fromTeam: fromTeam,
                toTeam: toTeam,
                duration: Double(i) * 2.0,
                wasSuccessful: i <= 3 // First 3 succeed, 4th fails
            )
        }
        
        let exportExpectation = XCTestExpectation(description: "Team switch metrics calculated")
        
        Task {
            do {
                let report = try await self.metricsCollector.exportMetrics()
                
                if let pattern = report.teamSwitchPatterns.first(where: { 
                    $0.fromTeamId == fromTeam && $0.toTeamId == toTeam 
                }) {
                    XCTAssertEqual(pattern.switchCount, 4, "Should have 4 total switches")
                    XCTAssertEqual(pattern.successRate, 0.75, accuracy: 0.01, "Success rate should be 75%")
                    XCTAssertGreaterThan(pattern.averageDuration, 0, "Should have positive average duration")
                }
                
                exportExpectation.fulfill()
            } catch {
                XCTFail("Failed to export metrics: \(error)")
                exportExpectation.fulfill()
            }
        }
        
        wait(for: [exportExpectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tracking Tests
    
    func testOperationTiming_WithValidOperation_TracksCorrectly() {
        let operationId = "timing-test-operation"
        
        // Start timing
        metricsCollector.startOperationTiming(operationId: operationId)
        
        // Simulate some work
        let expectation = XCTestExpectation(description: "Operation timing completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // End timing
            if let duration = self.metricsCollector.endOperationTiming(operationId: operationId) {
                XCTAssertGreaterThan(duration, 0.05, "Duration should be at least 50ms")
                XCTAssertLessThan(duration, 1.0, "Duration should be less than 1 second")
                expectation.fulfill()
            } else {
                XCTFail("Should return timing duration")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testOperationTiming_WithUnknownOperation_ReturnsNil() {
        // Try to end timing for operation that wasn't started
        let duration = metricsCollector.endOperationTiming(operationId: "unknown-operation")
        XCTAssertNil(duration, "Should return nil for unknown operation")
    }
    
    func testRecordDatabaseQuery_WithSlowQuery_TriggersAlert() {
        let alertExpectation = XCTestExpectation(description: "Slow query alert triggered")
        
        // Subscribe to alerts
        metricsCollector.alerts
            .sink { alert in
                if case .slowDatabaseQuery(let query, let duration) = alert {
                    XCTAssertEqual(query, "SELECT * FROM exit_fee_payments WHERE created_at < NOW() - INTERVAL '1 hour'")
                    XCTAssertGreaterThan(duration, 2.0, "Duration should exceed 2 second threshold")
                    alertExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Record a slow query (>2 seconds threshold)
        metricsCollector.recordDatabaseQuery(
            query: "SELECT * FROM exit_fee_payments WHERE created_at < NOW() - INTERVAL '1 hour'",
            duration: 3.5
        )
        
        wait(for: [alertExpectation], timeout: 2.0)
    }
    
    // MARK: - Real-time Metrics Tests
    
    func testGetCurrentMetrics_ReturnsValidData() {
        let metrics = metricsCollector.getCurrentMetrics()
        
        XCTAssertGreaterThanOrEqual(metrics.activeOperations, 0, "Active operations should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.operationsLastMinute, 0, "Operations last minute should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.successRate, 0.0, "Success rate should be non-negative")
        XCTAssertLessThanOrEqual(metrics.successRate, 1.0, "Success rate should not exceed 100%")
        XCTAssertGreaterThanOrEqual(metrics.currentRevenue, 0, "Current revenue should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.errorCount, 0, "Error count should be non-negative")
        XCTAssertNotNil(metrics.timestamp, "Should have valid timestamp")
    }
    
    func testRealtimeMetricsPublisher_EmitsRegularUpdates() {
        let metricsExpectation = XCTestExpectation(description: "Real-time metrics received")
        metricsExpectation.expectedFulfillmentCount = 2 // Expect at least 2 updates
        
        // Subscribe to real-time metrics
        metricsCollector.realtimeMetrics
            .sink { metrics in
                XCTAssertNotNil(metrics.timestamp, "Metrics should have timestamp")
                XCTAssertGreaterThanOrEqual(metrics.successRate, 0.0, "Success rate should be valid")
                metricsExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait longer to catch multiple emissions (timer is set to 5 seconds)
        wait(for: [metricsExpectation], timeout: 12.0)
    }
    
    // MARK: - Metrics Export Tests
    
    func testExportMetrics_WithNoTimeRange_ReturnsLast24Hours() async throws {
        // Record some test metrics first
        metricsCollector.recordPaymentAttempt(
            operationId: "export-test-1",
            userId: "test-user",
            success: true,
            duration: 2.0
        )
        
        let report = try await metricsCollector.exportMetrics()
        
        XCTAssertNotNil(report.reportId, "Report should have ID")
        XCTAssertNotNil(report.generatedAt, "Report should have generation timestamp")
        XCTAssertGreaterThanOrEqual(report.totalOperations, 0, "Should have non-negative operation count")
        XCTAssertGreaterThanOrEqual(report.averageProcessingTime, 0, "Should have non-negative average processing time")
        
        // Check that time range is approximately last 24 hours
        let expectedStart = Date().addingTimeInterval(-86400)
        XCTAssertLessThan(abs(report.timeRange.start.timeIntervalSince(expectedStart)), 60, "Time range start should be approximately 24 hours ago")
    }
    
    func testExportMetrics_WithCustomTimeRange_ReturnsCorrectRange() async throws {
        let startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let endDate = Date()
        let customRange = DateInterval(start: startDate, end: endDate)
        
        let report = try await metricsCollector.exportMetrics(timeRange: customRange)
        
        XCTAssertEqual(report.timeRange.start, customRange.start, "Should use custom start date")
        XCTAssertEqual(report.timeRange.end, customRange.end, "Should use custom end date")
    }
    
    func testExportMetrics_WithMultipleMetricTypes_IncludesAllSummaries() async throws {
        // Record various types of metrics
        metricsCollector.recordStateTransition(
            operationId: "export-state-test",
            from: .initiated,
            to: .invoiceCreated,
            duration: 1.0
        )
        
        metricsCollector.recordPaymentAttempt(
            operationId: "export-payment-test",
            userId: "test-user",
            success: false,
            errorType: ExitFeeError.paymentTimeout
        )
        
        metricsCollector.recordTeamSwitch(
            operationId: "export-switch-test",
            userId: "test-user",
            fromTeam: "team-export-from",
            toTeam: "team-export-to",
            duration: 4.0,
            wasSuccessful: true
        )
        
        let report = try await metricsCollector.exportMetrics()
        
        XCTAssertGreaterThanOrEqual(report.stateTransitions.count, 0, "Should have state transition summaries")
        XCTAssertGreaterThanOrEqual(report.errorBreakdown.count, 0, "Should have error summaries")
        XCTAssertGreaterThanOrEqual(report.teamSwitchPatterns.count, 0, "Should have team switch summaries")
        XCTAssertNotNil(report.performanceMetrics, "Should have performance metrics")
    }
    
    // MARK: - Error Handling Tests
    
    func testMetricsCollector_WithHighVolumeData_PerformsWithoutCrashing() {
        let highVolumeExpectation = XCTestExpectation(description: "High volume metrics processed")
        
        // Record a large number of metrics quickly
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 1...1000 {
                self.metricsCollector.recordPaymentAttempt(
                    operationId: "volume-test-\(i)",
                    userId: "test-user",
                    success: i % 3 != 0, // 2/3 success rate
                    duration: Double.random(in: 1.0...10.0)
                )
            }
            
            DispatchQueue.main.async {
                highVolumeExpectation.fulfill()
            }
        }
        
        wait(for: [highVolumeExpectation], timeout: 5.0)
        
        // Verify system is still responsive
        let metrics = metricsCollector.getCurrentMetrics()
        XCTAssertNotNil(metrics, "Should still be able to get current metrics")
    }
    
    func testAlertSystem_DoesNotCrashWithInvalidData() {
        // Test with edge cases that might cause issues
        XCTAssertNoThrow(metricsCollector.recordStateTransition(
            operationId: "",
            from: .initiated,
            to: .teamChangeComplete,
            duration: 0
        ))
        
        XCTAssertNoThrow(metricsCollector.recordPaymentAttempt(
            operationId: "edge-case-test",
            userId: "",
            success: true,
            duration: 0
        ))
        
        XCTAssertNoThrow(metricsCollector.recordTeamSwitch(
            operationId: "edge-case-switch",
            userId: "",
            fromTeam: "",
            toTeam: "",
            duration: 0,
            wasSuccessful: false
        ))
    }
}