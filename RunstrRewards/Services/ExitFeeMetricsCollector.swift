import Foundation
import Combine

// MARK: - Metrics Data Models

struct StateTransitionMetric: Codable {
    let operationId: String
    let fromState: ExitFeeStatus
    let toState: ExitFeeStatus
    let duration: TimeInterval
    let timestamp: Date
    let userId: String
    let metadata: [String: String]?
}

struct PaymentAttemptMetric: Codable {
    let operationId: String
    let userId: String
    let success: Bool
    let errorType: ExitFeeError?
    let attemptNumber: Int
    let duration: TimeInterval?
    let timestamp: Date
    let amount: Int
}

struct TeamSwitchMetric: Codable {
    let operationId: String
    let userId: String
    let fromTeamId: String
    let toTeamId: String
    let duration: TimeInterval
    let timestamp: Date
    let wasSuccessful: Bool
}

struct ExitFeeMetricsReport: Codable {
    let reportId: String
    let generatedAt: Date
    let timeRange: DateInterval
    let totalOperations: Int
    let successfulOperations: Int
    let failedOperations: Int
    let averageProcessingTime: TimeInterval
    let stateTransitions: [StateTransitionSummary]
    let errorBreakdown: [ErrorMetricSummary]
    let teamSwitchPatterns: [TeamSwitchSummary]
    let performanceMetrics: PerformanceMetrics
}

struct StateTransitionSummary: Codable {
    let fromState: ExitFeeStatus
    let toState: ExitFeeStatus
    let count: Int
    let averageDuration: TimeInterval
    let successRate: Double
}

struct ErrorMetricSummary: Codable {
    let errorType: String
    let count: Int
    let percentage: Double
    let averageRetryCount: Double
}

struct TeamSwitchSummary: Codable {
    let fromTeamId: String
    let toTeamId: String
    let switchCount: Int
    let averageDuration: TimeInterval
    let successRate: Double
}

struct PerformanceMetrics: Codable {
    let operationsPerSecond: Double
    let averageMemoryUsage: Double
    let peakMemoryUsage: Double
    let cacheHitRate: Double
    let databaseQueryCount: Int
    let averageQueryDuration: TimeInterval
}

// MARK: - Real-time Metrics

struct RealtimeMetrics {
    let activeOperations: Int
    let operationsLastMinute: Int
    let successRate: Double
    let currentRevenue: Int
    let averageProcessingTime: TimeInterval
    let errorCount: Int
    let timestamp: Date
}

// MARK: - Metrics Collector Service

class ExitFeeMetricsCollector {
    static let shared = ExitFeeMetricsCollector()
    
    // MARK: - Properties
    
    private let metricsQueue = DispatchQueue(label: "exit_fee_metrics", qos: .utility)
    private let storageQueue = DispatchQueue(label: "exit_fee_metrics_storage", qos: .background)
    
    // In-memory storage for real-time metrics
    private var stateTransitions: [StateTransitionMetric] = []
    private var paymentAttempts: [PaymentAttemptMetric] = []
    private var teamSwitches: [TeamSwitchMetric] = []
    
    // Performance tracking
    private var operationStartTimes: [String: Date] = [:]
    private var memoryUsageHistory: [Double] = []
    private var queryPerformanceHistory: [(String, TimeInterval)] = []
    
    // Real-time publishers
    private let realtimeMetricsSubject = PassthroughSubject<RealtimeMetrics, Never>()
    var realtimeMetrics: AnyPublisher<RealtimeMetrics, Never> {
        return realtimeMetricsSubject.eraseToAnyPublisher()
    }
    
    private let alertSubject = PassthroughSubject<MetricsAlert, Never>()
    var alerts: AnyPublisher<MetricsAlert, Never> {
        return alertSubject.eraseToAnyPublisher()
    }
    
    // Configuration
    private let maxInMemoryMetrics = 10000 // Rotate to storage after this
    private let metricsRetentionDays = 30
    private let alertThresholds = MetricsAlertThresholds()
    
    private init() {
        startRealtimeMetricsTimer()
        startMemoryMonitoring()
    }
    
    // MARK: - State Transition Tracking
    
    func recordStateTransition(
        operationId: String,
        from fromState: ExitFeeStatus,
        to toState: ExitFeeStatus,
        duration: TimeInterval,
        userId: String = "",
        metadata: [String: String]? = nil
    ) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let metric = StateTransitionMetric(
                operationId: operationId,
                fromState: fromState,
                toState: toState,
                duration: duration,
                timestamp: Date(),
                userId: userId,
                metadata: metadata
            )
            
            self.stateTransitions.append(metric)
            
            // Check for performance alerts
            if duration > self.alertThresholds.slowTransitionThreshold {
                self.alertSubject.send(.slowStateTransition(metric))
            }
            
            print("ExitFeeMetrics: State transition \(fromState.rawValue) → \(toState.rawValue) took \(String(format: "%.2f", duration))s")
            
            self.rotateMetricsIfNeeded()
        }
    }
    
    // MARK: - Payment Attempt Tracking
    
    func recordPaymentAttempt(
        operationId: String,
        userId: String,
        success: Bool,
        errorType: ExitFeeError? = nil,
        attemptNumber: Int = 1,
        duration: TimeInterval? = nil
    ) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let metric = PaymentAttemptMetric(
                operationId: operationId,
                userId: userId,
                success: success,
                errorType: errorType,
                attemptNumber: attemptNumber,
                duration: duration,
                timestamp: Date(),
                amount: 2000 // Hardcoded for now
            )
            
            self.paymentAttempts.append(metric)
            
            // Check for error rate alerts
            if !success {
                let recentFailures = self.paymentAttempts.suffix(100).filter { !$0.success }
                let failureRate = Double(recentFailures.count) / 100.0
                
                if failureRate > self.alertThresholds.highFailureRateThreshold {
                    self.alertSubject.send(.highFailureRate(failureRate))
                }
            }
            
            print("ExitFeeMetrics: Payment attempt \(success ? "succeeded" : "failed") for operation \(operationId)")
            
            self.rotateMetricsIfNeeded()
        }
    }
    
    // MARK: - Team Switch Tracking
    
    func recordTeamSwitch(
        operationId: String,
        userId: String,
        fromTeam: String,
        toTeam: String,
        duration: TimeInterval,
        wasSuccessful: Bool
    ) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            let metric = TeamSwitchMetric(
                operationId: operationId,
                userId: userId,
                fromTeamId: fromTeam,
                toTeamId: toTeam,
                duration: duration,
                timestamp: Date(),
                wasSuccessful: wasSuccessful
            )
            
            self.teamSwitches.append(metric)
            
            print("ExitFeeMetrics: Team switch from \(fromTeam) to \(toTeam) \(wasSuccessful ? "succeeded" : "failed") in \(String(format: "%.2f", duration))s")
            
            self.rotateMetricsIfNeeded()
        }
    }
    
    // MARK: - Performance Tracking
    
    func startOperationTiming(operationId: String) {
        metricsQueue.async { [weak self] in
            self?.operationStartTimes[operationId] = Date()
        }
    }
    
    func endOperationTiming(operationId: String) -> TimeInterval? {
        return metricsQueue.sync { [weak self] in
            guard let self = self,
                  let startTime = self.operationStartTimes.removeValue(forKey: operationId) else {
                return nil
            }
            
            return Date().timeIntervalSince(startTime)
        }
    }
    
    func recordDatabaseQuery(query: String, duration: TimeInterval) {
        metricsQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.queryPerformanceHistory.append((query, duration))
            
            // Keep only recent queries
            if self.queryPerformanceHistory.count > 1000 {
                self.queryPerformanceHistory.removeFirst(500)
            }
            
            // Alert for slow queries
            if duration > self.alertThresholds.slowQueryThreshold {
                self.alertSubject.send(.slowDatabaseQuery(query, duration))
            }
        }
    }
    
    // MARK: - Metrics Export
    
    func exportMetrics(timeRange: DateInterval? = nil) async throws -> ExitFeeMetricsReport {
        return try await withCheckedThrowingContinuation { continuation in
            metricsQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "MetricsCollector", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service unavailable"]))
                    return
                }
                
                let range = timeRange ?? DateInterval(start: Date().addingTimeInterval(-86400), end: Date())
                
                // Filter metrics by time range
                let filteredTransitions = self.stateTransitions.filter { range.contains($0.timestamp) }
                let filteredAttempts = self.paymentAttempts.filter { range.contains($0.timestamp) }
                let filteredSwitches = self.teamSwitches.filter { range.contains($0.timestamp) }
                
                // Calculate summaries
                let stateTransitionSummaries = self.calculateStateTransitionSummaries(from: filteredTransitions)
                let errorSummaries = self.calculateErrorSummaries(from: filteredAttempts)
                let teamSwitchSummaries = self.calculateTeamSwitchSummaries(from: filteredSwitches)
                let performanceMetrics = self.calculatePerformanceMetrics()
                
                // Generate report
                let report = ExitFeeMetricsReport(
                    reportId: UUID().uuidString,
                    generatedAt: Date(),
                    timeRange: range,
                    totalOperations: filteredAttempts.count,
                    successfulOperations: filteredAttempts.filter { $0.success }.count,
                    failedOperations: filteredAttempts.filter { !$0.success }.count,
                    averageProcessingTime: filteredAttempts.compactMap { $0.duration }.reduce(0, +) / Double(max(filteredAttempts.compactMap { $0.duration }.count, 1)),
                    stateTransitions: stateTransitionSummaries,
                    errorBreakdown: errorSummaries,
                    teamSwitchPatterns: teamSwitchSummaries,
                    performanceMetrics: performanceMetrics
                )
                
                continuation.resume(returning: report)
            }
        }
    }
    
    // MARK: - Real-time Metrics
    
    func getCurrentMetrics() -> RealtimeMetrics {
        return metricsQueue.sync { [weak self] in
            guard let self = self else {
                return RealtimeMetrics(
                    activeOperations: 0,
                    operationsLastMinute: 0,
                    successRate: 0,
                    currentRevenue: 0,
                    averageProcessingTime: 0,
                    errorCount: 0,
                    timestamp: Date()
                )
            }
            
            let lastMinute = Date().addingTimeInterval(-60)
            let recentAttempts = self.paymentAttempts.filter { $0.timestamp > lastMinute }
            let recentSuccesses = recentAttempts.filter { $0.success }
            
            return RealtimeMetrics(
                activeOperations: self.operationStartTimes.count,
                operationsLastMinute: recentAttempts.count,
                successRate: recentAttempts.isEmpty ? 0 : Double(recentSuccesses.count) / Double(recentAttempts.count),
                currentRevenue: recentSuccesses.reduce(0) { $0 + $1.amount },
                averageProcessingTime: recentSuccesses.compactMap { $0.duration }.reduce(0, +) / Double(max(recentSuccesses.compactMap { $0.duration }.count, 1)),
                errorCount: recentAttempts.filter { !$0.success }.count,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func startRealtimeMetricsTimer() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let metrics = self.getCurrentMetrics()
            self.realtimeMetricsSubject.send(metrics)
        }
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let memoryUsage = self.getCurrentMemoryUsage()
            
            self.metricsQueue.async {
                self.memoryUsageHistory.append(memoryUsage)
                
                if self.memoryUsageHistory.count > 100 {
                    self.memoryUsageHistory.removeFirst(50)
                }
                
                // Alert for high memory usage
                if memoryUsage > self.alertThresholds.highMemoryUsageThreshold {
                    self.alertSubject.send(.highMemoryUsage(memoryUsage))
                }
            }
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024 / 1024 // MB
        }
        
        return 0.0
    }
    
    private func rotateMetricsIfNeeded() {
        let totalMetrics = stateTransitions.count + paymentAttempts.count + teamSwitches.count
        
        if totalMetrics > maxInMemoryMetrics {
            storageQueue.async { [weak self] in
                self?.archiveOldMetrics()
            }
        }
    }
    
    private func archiveOldMetrics() {
        // Archive metrics older than retention period
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(metricsRetentionDays * 24 * 60 * 60))
        
        stateTransitions.removeAll { $0.timestamp < cutoffDate }
        paymentAttempts.removeAll { $0.timestamp < cutoffDate }
        teamSwitches.removeAll { $0.timestamp < cutoffDate }
        
        print("ExitFeeMetrics: Archived old metrics, current counts - Transitions: \(stateTransitions.count), Attempts: \(paymentAttempts.count), Switches: \(teamSwitches.count)")
    }
    
    // MARK: - Summary Calculations
    
    private func calculateStateTransitionSummaries(from transitions: [StateTransitionMetric]) -> [StateTransitionSummary] {
        let grouped = Dictionary(grouping: transitions) { ($0.fromState, $0.toState) }
        
        return grouped.map { key, values in
            let durations = values.map { $0.duration }
            let averageDuration = durations.reduce(0, +) / Double(values.count)
            
            return StateTransitionSummary(
                fromState: key.0,
                toState: key.1,
                count: values.count,
                averageDuration: averageDuration,
                successRate: 1.0 // All recorded transitions are considered successful
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateErrorSummaries(from attempts: [PaymentAttemptMetric]) -> [ErrorMetricSummary] {
        let failures = attempts.filter { !$0.success }
        let totalFailures = failures.count
        
        guard totalFailures > 0 else { return [] }
        
        let grouped = Dictionary(grouping: failures) { $0.errorType?.localizedDescription ?? "Unknown" }
        
        return grouped.map { errorType, values in
            ErrorMetricSummary(
                errorType: errorType,
                count: values.count,
                percentage: Double(values.count) / Double(totalFailures),
                averageRetryCount: values.map { Double($0.attemptNumber) }.reduce(0, +) / Double(values.count)
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateTeamSwitchSummaries(from switches: [TeamSwitchMetric]) -> [TeamSwitchSummary] {
        let grouped = Dictionary(grouping: switches) { ($0.fromTeamId, $0.toTeamId) }
        
        return grouped.map { key, values in
            let durations = values.map { $0.duration }
            let averageDuration = durations.reduce(0, +) / Double(values.count)
            let successCount = values.filter { $0.wasSuccessful }.count
            let successRate = Double(successCount) / Double(values.count)
            
            return TeamSwitchSummary(
                fromTeamId: key.0,
                toTeamId: key.1,
                switchCount: values.count,
                averageDuration: averageDuration,
                successRate: successRate
            )
        }.sorted { $0.switchCount > $1.switchCount }
    }
    
    private func calculatePerformanceMetrics() -> PerformanceMetrics {
        let recentQueries = queryPerformanceHistory.suffix(100)
        let averageQueryDuration = recentQueries.isEmpty ? 0 : recentQueries.map { $0.1 }.reduce(0, +) / Double(recentQueries.count)
        
        let peakMemory = memoryUsageHistory.max() ?? 0
        let averageMemory = memoryUsageHistory.isEmpty ? 0 : memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
        
        return PerformanceMetrics(
            operationsPerSecond: 0, // TODO: Calculate from recent activity
            averageMemoryUsage: averageMemory,
            peakMemoryUsage: peakMemory,
            cacheHitRate: 0, // TODO: Implement cache metrics
            databaseQueryCount: recentQueries.count,
            averageQueryDuration: averageQueryDuration
        )
    }
}

// MARK: - Alert System

enum MetricsAlert {
    case slowStateTransition(StateTransitionMetric)
    case highFailureRate(Double)
    case slowDatabaseQuery(String, TimeInterval)
    case highMemoryUsage(Double)
    case stuckPayments(Int)
}

struct MetricsAlertThresholds {
    let slowTransitionThreshold: TimeInterval = 10.0 // 10 seconds
    let highFailureRateThreshold: Double = 0.2 // 20%
    let slowQueryThreshold: TimeInterval = 2.0 // 2 seconds
    let highMemoryUsageThreshold: Double = 200.0 // 200 MB
    let stuckPaymentThreshold: TimeInterval = 300.0 // 5 minutes
}