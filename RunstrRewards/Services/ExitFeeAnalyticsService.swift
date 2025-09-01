import Foundation
import Supabase

// MARK: - Analytics Data Models

struct ExitFeeRevenue: Codable {
    let totalAmount: Int
    let paymentCount: Int
    let averageAmount: Double
    let period: DateInterval
    let successRate: Double
}

struct TeamSwitchAnalytics: Codable {
    let totalSwitches: Int
    let topSourceTeams: [TeamSwitchPattern]
    let topDestinationTeams: [TeamSwitchPattern]
    let averageSwitchTime: TimeInterval
}

struct TeamSwitchPattern: Codable {
    let teamId: String
    let teamName: String?
    let switchCount: Int
    let percentage: Double
}

struct PaymentPerformanceMetrics: Codable {
    let averagePaymentTime: TimeInterval
    let medianPaymentTime: TimeInterval
    let successRate: Double
    let failureRate: Double
    let timeoutRate: Double
}

// MARK: - Analytics Service

class ExitFeeAnalyticsService {
    static let shared = ExitFeeAnalyticsService()
    private let client = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Revenue Analytics
    
    func calculateDailyRevenue(date: Date) async throws -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let response = try await client
            .from("exit_fee_payments")
            .select("amount")
            .eq("payment_status", value: ExitFeeStatus.teamChangeComplete.rawValue)
            .gte("completed_at", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("completed_at", value: ISO8601DateFormatter().string(from: endOfDay))
            .execute()
        
        struct RevenueRow: Codable {
            let amount: Int
        }
        
        let payments = try SupabaseService.shared.customJSONDecoder().decode([RevenueRow].self, from: response.data)
        return payments.reduce(0) { $0 + $1.amount }
    }
    
    func calculateRevenue(period: DateInterval) async throws -> ExitFeeRevenue {
        let startDate = ISO8601DateFormatter().string(from: period.start)
        let endDate = ISO8601DateFormatter().string(from: period.end)
        
        // Get completed payments
        let completedResponse = try await client
            .from("exit_fee_payments")
            .select("amount, created_at, completed_at")
            .eq("payment_status", value: ExitFeeStatus.teamChangeComplete.rawValue)
            .gte("completed_at", value: startDate)
            .lte("completed_at", value: endDate)
            .execute()
        
        // Get total attempts for success rate
        let totalResponse = try await client
            .from("exit_fee_payments")
            .select("payment_status")
            .gte("created_at", value: startDate)
            .lte("created_at", value: endDate)
            .execute()
        
        struct PaymentRow: Codable {
            let amount: Int
            let createdAt: String
            let completedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case amount
                case createdAt = "created_at"
                case completedAt = "completed_at"
            }
        }
        
        struct StatusRow: Codable {
            let paymentStatus: String
            
            enum CodingKeys: String, CodingKey {
                case paymentStatus = "payment_status"
            }
        }
        
        let completedPayments = try SupabaseService.shared.customJSONDecoder().decode([PaymentRow].self, from: completedResponse.data)
        let totalAttempts = try SupabaseService.shared.customJSONDecoder().decode([StatusRow].self, from: totalResponse.data)
        
        let totalAmount = completedPayments.reduce(0) { $0 + $1.amount }
        let paymentCount = completedPayments.count
        let averageAmount = paymentCount > 0 ? Double(totalAmount) / Double(paymentCount) : 0.0
        let successRate = totalAttempts.count > 0 ? Double(paymentCount) / Double(totalAttempts.count) : 0.0
        
        return ExitFeeRevenue(
            totalAmount: totalAmount,
            paymentCount: paymentCount,
            averageAmount: averageAmount,
            period: period,
            successRate: successRate
        )
    }
    
    // MARK: - Performance Analytics
    
    func calculatePaymentSuccessRate(period: DateInterval) async throws -> Double {
        let startDate = ISO8601DateFormatter().string(from: period.start)
        let endDate = ISO8601DateFormatter().string(from: period.end)
        
        let response = try await client
            .from("exit_fee_payments")
            .select("payment_status")
            .gte("created_at", value: startDate)
            .lte("created_at", value: endDate)
            .execute()
        
        struct StatusRow: Codable {
            let paymentStatus: String
            
            enum CodingKeys: String, CodingKey {
                case paymentStatus = "payment_status"
            }
        }
        
        let payments = try SupabaseService.shared.customJSONDecoder().decode([StatusRow].self, from: response.data)
        
        guard !payments.isEmpty else { return 0.0 }
        
        let successCount = payments.filter { $0.paymentStatus == ExitFeeStatus.teamChangeComplete.rawValue }.count
        return Double(successCount) / Double(payments.count)
    }
    
    func getAveragePaymentTime() async throws -> TimeInterval {
        let response = try await client
            .from("exit_fee_payments")
            .select("created_at, completed_at")
            .eq("payment_status", value: ExitFeeStatus.teamChangeComplete.rawValue)
            .not("completed_at", operator: "is", value: nil)
            .execute()
        
        struct TimeRow: Codable {
            let createdAt: String
            let completedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case createdAt = "created_at"
                case completedAt = "completed_at"
            }
        }
        
        let payments = try SupabaseService.shared.customJSONDecoder().decode([TimeRow].self, from: response.data)
        
        guard !payments.isEmpty else { return 0 }
        
        let formatter = ISO8601DateFormatter()
        var totalDuration: TimeInterval = 0
        var validPayments = 0
        
        for payment in payments {
            guard let completedAt = payment.completedAt,
                  let createdDate = formatter.date(from: payment.createdAt),
                  let completedDate = formatter.date(from: completedAt) else {
                continue
            }
            
            totalDuration += completedDate.timeIntervalSince(createdDate)
            validPayments += 1
        }
        
        return validPayments > 0 ? totalDuration / Double(validPayments) : 0
    }
    
    // MARK: - Team Switching Analytics
    
    func getTeamSwitchingPatterns() async throws -> TeamSwitchAnalytics {
        let response = try await client
            .from("exit_fee_payments")
            .select("from_team_id, to_team_id, created_at, completed_at")
            .eq("payment_status", value: ExitFeeStatus.teamChangeComplete.rawValue)
            .not("to_team_id", operator: "is", value: nil)
            .execute()
        
        struct SwitchRow: Codable {
            let fromTeamId: String?
            let toTeamId: String?
            let createdAt: String
            let completedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case fromTeamId = "from_team_id"
                case toTeamId = "to_team_id"
                case createdAt = "created_at"
                case completedAt = "completed_at"
            }
        }
        
        let switches = try SupabaseService.shared.customJSONDecoder().decode([SwitchRow].self, from: response.data)
        
        // Calculate patterns
        var fromTeamCounts: [String: Int] = [:]
        var toTeamCounts: [String: Int] = [:]
        var totalDuration: TimeInterval = 0
        var validSwitches = 0
        
        let formatter = ISO8601DateFormatter()
        
        for switchData in switches {
            if let fromTeamId = switchData.fromTeamId {
                fromTeamCounts[fromTeamId, default: 0] += 1
            }
            
            if let toTeamId = switchData.toTeamId {
                toTeamCounts[toTeamId, default: 0] += 1
            }
            
            // Calculate switch duration
            if let completedAt = switchData.completedAt,
               let createdDate = formatter.date(from: switchData.createdAt),
               let completedDate = formatter.date(from: completedAt) {
                totalDuration += completedDate.timeIntervalSince(createdDate)
                validSwitches += 1
            }
        }
        
        let totalSwitches = switches.count
        
        // Convert to sorted patterns
        let topSourceTeams = fromTeamCounts.map { teamId, count in
            TeamSwitchPattern(
                teamId: teamId,
                teamName: nil, // TODO: Fetch team names
                switchCount: count,
                percentage: totalSwitches > 0 ? Double(count) / Double(totalSwitches) : 0.0
            )
        }.sorted { $0.switchCount > $1.switchCount }.prefix(5).map { $0 }
        
        let topDestinationTeams = toTeamCounts.map { teamId, count in
            TeamSwitchPattern(
                teamId: teamId,
                teamName: nil, // TODO: Fetch team names
                switchCount: count,
                percentage: totalSwitches > 0 ? Double(count) / Double(totalSwitches) : 0.0
            )
        }.sorted { $0.switchCount > $1.switchCount }.prefix(5).map { $0 }
        
        let averageSwitchTime = validSwitches > 0 ? totalDuration / Double(validSwitches) : 0
        
        return TeamSwitchAnalytics(
            totalSwitches: totalSwitches,
            topSourceTeams: topSourceTeams,
            topDestinationTeams: topDestinationTeams,
            averageSwitchTime: averageSwitchTime
        )
    }
    
    // MARK: - Monitoring
    
    func getStuckPayments(threshold: TimeInterval = 3600) async throws -> [ExitFeeOperation] {
        let cutoffTime = Date().addingTimeInterval(-threshold)
        let cutoffString = ISO8601DateFormatter().string(from: cutoffTime)
        
        let response = try await client
            .from("exit_fee_payments")
            .select()
            .in("payment_status", values: [
                ExitFeeStatus.initiated.rawValue,
                ExitFeeStatus.invoiceCreated.rawValue,
                ExitFeeStatus.paymentSent.rawValue,
                ExitFeeStatus.paymentConfirmed.rawValue
            ])
            .lt("created_at", value: cutoffString)
            .execute()
        
        return try SupabaseService.shared.customJSONDecoder().decode([ExitFeeOperation].self, from: response.data)
    }
    
    func getPaymentPerformanceMetrics(period: DateInterval) async throws -> PaymentPerformanceMetrics {
        let startDate = ISO8601DateFormatter().string(from: period.start)
        let endDate = ISO8601DateFormatter().string(from: period.end)
        
        let response = try await client
            .from("exit_fee_payments")
            .select("payment_status, created_at, completed_at")
            .gte("created_at", value: startDate)
            .lte("created_at", value: endDate)
            .execute()
        
        struct MetricRow: Codable {
            let paymentStatus: String
            let createdAt: String
            let completedAt: String?
            
            enum CodingKeys: String, CodingKey {
                case paymentStatus = "payment_status"
                case createdAt = "created_at" 
                case completedAt = "completed_at"
            }
        }
        
        let payments = try SupabaseService.shared.customJSONDecoder().decode([MetricRow].self, from: response.data)
        
        guard !payments.isEmpty else {
            return PaymentPerformanceMetrics(
                averagePaymentTime: 0,
                medianPaymentTime: 0,
                successRate: 0,
                failureRate: 0,
                timeoutRate: 0
            )
        }
        
        let totalCount = payments.count
        let successCount = payments.filter { $0.paymentStatus == ExitFeeStatus.teamChangeComplete.rawValue }.count
        let failureCount = payments.filter { $0.paymentStatus == ExitFeeStatus.failed.rawValue }.count
        let expiredCount = payments.filter { $0.paymentStatus == "expired" }.count
        
        // Calculate payment times for completed payments
        let formatter = ISO8601DateFormatter()
        var paymentTimes: [TimeInterval] = []
        
        for payment in payments {
            guard payment.paymentStatus == ExitFeeStatus.teamChangeComplete.rawValue,
                  let completedAt = payment.completedAt,
                  let createdDate = formatter.date(from: payment.createdAt),
                  let completedDate = formatter.date(from: completedAt) else {
                continue
            }
            
            paymentTimes.append(completedDate.timeIntervalSince(createdDate))
        }
        
        let averageTime = paymentTimes.isEmpty ? 0 : paymentTimes.reduce(0, +) / Double(paymentTimes.count)
        let medianTime = paymentTimes.isEmpty ? 0 : paymentTimes.sorted()[paymentTimes.count / 2]
        
        return PaymentPerformanceMetrics(
            averagePaymentTime: averageTime,
            medianPaymentTime: medianTime,
            successRate: Double(successCount) / Double(totalCount),
            failureRate: Double(failureCount) / Double(totalCount),
            timeoutRate: Double(expiredCount) / Double(totalCount)
        )
    }
    
    // MARK: - Utility Methods
    
    func trackExitFeePayment(operation: ExitFeeOperation) {
        // Record payment event for real-time analytics
        print("ExitFeeAnalytics: Tracking payment \(operation.id) - Status: \(operation.status.rawValue)")
        
        // TODO: Implement real-time analytics tracking
        // This could push to analytics service, update dashboards, etc.
    }
}