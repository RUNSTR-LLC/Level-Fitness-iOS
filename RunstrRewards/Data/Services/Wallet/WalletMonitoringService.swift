import Foundation

class WalletMonitoringService {
    static let shared = WalletMonitoringService()
    
    private init() {}
    
    // MARK: - Transaction Monitoring
    
    func logWalletTransaction(
        teamId: String,
        userId: String,
        operation: String,
        amount: Int,
        success: Bool,
        duration: TimeInterval,
        error: Error? = nil
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        var logMessage = """
        🏦 WALLET TRANSACTION LOG [\(timestamp)]
        Team ID: \(teamId)
        User ID: \(userId.prefix(8))...
        Operation: \(operation)
        Amount: \(amount) sats
        Success: \(success ? "✅" : "❌")
        Duration: \(String(format: "%.2f", duration))s
        """
        
        if let error = error {
            logMessage += "\nError: \(error.localizedDescription)"
        }
        
        logMessage += "\n" + String(repeating: "=", count: 50)
        
        print(logMessage)
        
        // Store in analytics (in production, would send to analytics service)
        recordAnalyticsEvent(
            event: "wallet_transaction",
            properties: [
                "team_id": teamId,
                "operation": operation,
                "amount": amount,
                "success": success,
                "duration": duration,
                "error": error?.localizedDescription ?? ""
            ]
        )
    }
    
    // MARK: - Access Control Monitoring
    
    func logAccessAttempt(
        teamId: String,
        userId: String,
        operation: String,
        granted: Bool,
        reason: String? = nil
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        var logMessage = """
        🔐 ACCESS ATTEMPT LOG [\(timestamp)]
        Team ID: \(teamId)
        User ID: \(userId.prefix(8))...
        Operation: \(operation)
        Access: \(granted ? "GRANTED ✅" : "DENIED ❌")
        """
        
        if let reason = reason {
            logMessage += "\nReason: \(reason)"
        }
        
        logMessage += "\n" + String(repeating: "=", count: 50)
        
        print(logMessage)
        
        recordAnalyticsEvent(
            event: "wallet_access_attempt",
            properties: [
                "team_id": teamId,
                "operation": operation,
                "granted": granted,
                "reason": reason ?? ""
            ]
        )
    }
    
    // MARK: - Performance Monitoring
    
    func logPerformanceMetric(
        operation: String,
        duration: TimeInterval,
        success: Bool,
        metadata: [String: Any] = [:]
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        var logMessage = """
        ⚡ PERFORMANCE LOG [\(timestamp)]
        Operation: \(operation)
        Duration: \(String(format: "%.3f", duration))s
        Success: \(success ? "✅" : "❌")
        """
        
        for (key, value) in metadata {
            logMessage += "\n\(key): \(value)"
        }
        
        logMessage += "\n" + String(repeating: "=", count: 50)
        
        print(logMessage)
        
        var properties = metadata
        properties["operation"] = operation
        properties["duration"] = duration
        properties["success"] = success
        
        recordAnalyticsEvent(event: "wallet_performance", properties: properties)
    }
    
    // MARK: - Security Monitoring
    
    func logSecurityEvent(
        eventType: String,
        teamId: String? = nil,
        userId: String? = nil,
        severity: SecuritySeverity = .medium,
        details: [String: Any] = [:]
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let severityIcon = severity.icon
        
        var logMessage = """
        \(severityIcon) SECURITY EVENT [\(timestamp)]
        Event: \(eventType)
        Severity: \(severity.rawValue.uppercased())
        """
        
        if let teamId = teamId {
            logMessage += "\nTeam ID: \(teamId)"
        }
        
        if let userId = userId {
            logMessage += "\nUser ID: \(userId.prefix(8))..."
        }
        
        for (key, value) in details {
            logMessage += "\n\(key): \(value)"
        }
        
        logMessage += "\n" + String(repeating: "=", count: 50)
        
        print(logMessage)
        
        var properties = details
        properties["event_type"] = eventType
        properties["severity"] = severity.rawValue
        properties["team_id"] = teamId ?? ""
        properties["user_id"] = userId ?? ""
        
        recordAnalyticsEvent(event: "security_event", properties: properties)
        
        // For critical security events, consider immediate alerting
        if severity == .critical {
            handleCriticalSecurityEvent(eventType: eventType, details: details)
        }
    }
    
    // MARK: - Wallet Health Monitoring
    
    func checkWalletHealth(teamId: String) async -> WalletHealthReport {
        let startTime = Date()
        
        do {
            // Check wallet connectivity
            let connectivityOk = await checkWalletConnectivity(teamId: teamId)
            
            // Check credential validity
            let credentialsOk = checkCredentialValidity(teamId: teamId)
            
            // Check recent transaction success rate
            let transactionHealthOk = await checkTransactionHealth(teamId: teamId)
            
            let duration = Date().timeIntervalSince(startTime)
            let overallHealth = connectivityOk && credentialsOk && transactionHealthOk
            
            let report = WalletHealthReport(
                teamId: teamId,
                overallHealth: overallHealth ? .healthy : .degraded,
                connectivity: connectivityOk,
                credentialsValid: credentialsOk,
                transactionHealth: transactionHealthOk,
                checkDuration: duration,
                timestamp: Date()
            )
            
            logPerformanceMetric(
                operation: "wallet_health_check",
                duration: duration,
                success: overallHealth,
                metadata: [
                    "team_id": teamId,
                    "connectivity": connectivityOk,
                    "credentials": credentialsOk,
                    "transactions": transactionHealthOk
                ]
            )
            
            return report
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            logSecurityEvent(
                eventType: "wallet_health_check_failed",
                teamId: teamId,
                severity: .high,
                details: [
                    "error": error.localizedDescription,
                    "duration": duration
                ]
            )
            
            return WalletHealthReport(
                teamId: teamId,
                overallHealth: .unhealthy,
                connectivity: false,
                credentialsValid: false,
                transactionHealth: false,
                checkDuration: duration,
                timestamp: Date()
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func checkWalletConnectivity(teamId: String) async -> Bool {
        // Implementation would test actual wallet connectivity
        // For now, return true as placeholder
        return true
    }
    
    private func checkCredentialValidity(teamId: String) -> Bool {
        guard let credentials = KeychainService.shared.loadCustom(for: "coinOS_team_\(teamId)_username") else {
            return false
        }
        
        // Check if credentials exist and are not empty
        return !credentials.isEmpty
    }
    
    private func checkTransactionHealth(teamId: String) async -> Bool {
        // Implementation would check recent transaction success rate
        // For now, return true as placeholder
        return true
    }
    
    private func recordAnalyticsEvent(event: String, properties: [String: Any]) {
        // In production, this would send to analytics service like Mixpanel, Amplitude, etc.
        print("📊 Analytics: \(event) - \(properties)")
    }
    
    private func handleCriticalSecurityEvent(eventType: String, details: [String: Any]) {
        // In production, this would trigger immediate alerts
        print("🚨 CRITICAL SECURITY ALERT: \(eventType) - \(details)")
        
        // Could implement:
        // - Slack/PagerDuty notifications
        // - Temporary wallet lockdown
        // - Enhanced monitoring
    }
}

// MARK: - Supporting Types

enum SecuritySeverity: String {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var icon: String {
        switch self {
        case .low: return "🟢"
        case .medium: return "🟡"
        case .high: return "🟠"
        case .critical: return "🔴"
        }
    }
}

enum WalletHealth {
    case healthy
    case degraded
    case unhealthy
    
    var description: String {
        switch self {
        case .healthy: return "Healthy ✅"
        case .degraded: return "Degraded ⚠️"
        case .unhealthy: return "Unhealthy ❌"
        }
    }
}

struct WalletHealthReport {
    let teamId: String
    let overallHealth: WalletHealth
    let connectivity: Bool
    let credentialsValid: Bool
    let transactionHealth: Bool
    let checkDuration: TimeInterval
    let timestamp: Date
    
    var summary: String {
        return """
        Wallet Health Report for Team \(teamId.prefix(8))...
        Overall: \(overallHealth.description)
        Connectivity: \(connectivity ? "✅" : "❌")
        Credentials: \(credentialsValid ? "✅" : "❌")
        Transactions: \(transactionHealth ? "✅" : "❌")
        Check Duration: \(String(format: "%.2f", checkDuration))s
        Timestamp: \(timestamp)
        """
    }
}