import Foundation

// MARK: - Error Categories

enum ExitFeeErrorCategory: String, CaseIterable {
    case paymentFailure = "payment_failure"
    case networkError = "network_error"
    case insufficientFunds = "insufficient_funds"
    case validationError = "validation_error"
    case systemError = "system_error"
    case userCancellation = "user_cancellation"
    case teamConstraint = "team_constraint"
    case lightningNetwork = "lightning_network"
    case timeout = "timeout"
    case unknown = "unknown"
}

// MARK: - Error Context

struct ErrorContext {
    let operationId: String?
    let userId: String?
    let teamId: String?
    let attemptNumber: Int
    let timestamp: Date
    let additionalInfo: [String: Any]
    
    init(
        operationId: String? = nil,
        userId: String? = nil,
        teamId: String? = nil,
        attemptNumber: Int = 1,
        timestamp: Date = Date(),
        additionalInfo: [String: Any] = [:]
    ) {
        self.operationId = operationId
        self.userId = userId
        self.teamId = teamId
        self.attemptNumber = attemptNumber
        self.timestamp = timestamp
        self.additionalInfo = additionalInfo
    }
}

// MARK: - User-Friendly Messages

struct UserErrorMessage {
    let title: String
    let message: String
    let actionButtonTitle: String?
    let secondaryActionTitle: String?
    let helpUrl: String?
    let canRetry: Bool
    
    init(
        title: String,
        message: String,
        actionButtonTitle: String? = nil,
        secondaryActionTitle: String? = nil,
        helpUrl: String? = nil,
        canRetry: Bool = false
    ) {
        self.title = title
        self.message = message
        self.actionButtonTitle = actionButtonTitle
        self.secondaryActionTitle = secondaryActionTitle
        self.helpUrl = helpUrl
        self.canRetry = canRetry
    }
}

// MARK: - Error Logging

struct ErrorLogEntry {
    let id: String
    let category: ExitFeeErrorCategory
    let error: Error
    let context: ErrorContext
    let userMessage: UserErrorMessage
    let severity: ErrorSeverity
    let timestamp: Date
    let stackTrace: String?
    
    enum ErrorSeverity: String {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

// MARK: - Error Handler Service

class ExitFeeErrorHandler {
    static let shared = ExitFeeErrorHandler()
    
    private let logger = ErrorLogger()
    private let retryPolicy = RetryPolicy()
    
    private init() {}
    
    // MARK: - Error Categorization
    
    func categorizeError(_ error: Error) -> ExitFeeErrorCategory {
        // Handle ExitFeeError types first
        if let exitFeeError = error as? ExitFeeError {
            switch exitFeeError {
            case .insufficientFunds:
                return .insufficientFunds
            case .paymentTimeout:
                return .timeout
            case .networkError:
                return .networkError
            case .invalidOperation:
                return .validationError
            case .operationInProgress:
                return .systemError
            case .paymentFailed:
                return .paymentFailure
            case .teamNotFound:
                return .teamConstraint
            case .userNotOnTeam:
                return .teamConstraint
            case .alreadyOnTeam:
                return .teamConstraint
            case .teamFull:
                return .teamConstraint
            }
        }
        
        // Handle NSError types
        if let nsError = error as NSError {
            switch nsError.domain {
            case NSURLErrorDomain:
                return categorizeNetworkError(nsError.code)
            case "CoinOSError":
                return categorizeCoinOSError(nsError.code)
            case "SupabaseError":
                return categorizeSupabaseError(nsError.code)
            default:
                return .systemError
            }
        }
        
        // Check error descriptions for common patterns
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("insufficient") || errorDescription.contains("balance") {
            return .insufficientFunds
        } else if errorDescription.contains("timeout") || errorDescription.contains("timed out") {
            return .timeout
        } else if errorDescription.contains("network") || errorDescription.contains("internet") {
            return .networkError
        } else if errorDescription.contains("cancel") {
            return .userCancellation
        } else if errorDescription.contains("lightning") || errorDescription.contains("invoice") {
            return .lightningNetwork
        }
        
        return .unknown
    }
    
    // MARK: - User-Friendly Messages
    
    func getUserFriendlyMessage(for error: ExitFeeError, context: ErrorContext = ErrorContext()) -> UserErrorMessage {
        let category = categorizeError(error)
        
        switch error {
        case .insufficientFunds:
            return UserErrorMessage(
                title: "Insufficient Funds",
                message: "You need 2,000 sats to leave your team. Please add funds to your wallet and try again.",
                actionButtonTitle: "Add Funds",
                secondaryActionTitle: "Cancel",
                helpUrl: "https://help.runstrrewards.com/exit-fees",
                canRetry: true
            )
            
        case .paymentTimeout:
            return UserErrorMessage(
                title: "Payment Timed Out",
                message: "Your exit fee payment took too long to process. Your team membership is unchanged. Please try again.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Cancel",
                helpUrl: "https://help.runstrrewards.com/payment-issues",
                canRetry: true
            )
            
        case .networkError:
            return UserErrorMessage(
                title: "Connection Problem",
                message: "Unable to process your exit fee due to a network issue. Please check your internet connection and try again.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Cancel",
                helpUrl: "https://help.runstrrewards.com/network-issues",
                canRetry: true
            )
            
        case .invalidOperation:
            return UserErrorMessage(
                title: "Invalid Request",
                message: "This team operation cannot be completed right now. Please refresh and try again.",
                actionButtonTitle: "Refresh",
                secondaryActionTitle: "Cancel",
                canRetry: false
            )
            
        case .operationInProgress:
            return UserErrorMessage(
                title: "Operation in Progress",
                message: "You already have an exit fee payment in progress. Please wait for it to complete before trying again.",
                actionButtonTitle: "Check Status",
                secondaryActionTitle: "Cancel",
                canRetry: false
            )
            
        case .paymentFailed:
            return UserErrorMessage(
                title: "Payment Failed",
                message: "Your exit fee payment could not be processed. Your team membership is unchanged. Please try again or contact support if the problem persists.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Contact Support",
                helpUrl: "https://help.runstrrewards.com/payment-failed",
                canRetry: true
            )
            
        case .teamNotFound:
            return UserErrorMessage(
                title: "Team Not Found",
                message: "The team you're trying to join no longer exists. Please choose a different team.",
                actionButtonTitle: "Browse Teams",
                canRetry: false
            )
            
        case .userNotOnTeam:
            return UserErrorMessage(
                title: "Not on Team",
                message: "You're not currently on this team, so no exit fee is required.",
                actionButtonTitle: "OK",
                canRetry: false
            )
            
        case .alreadyOnTeam:
            return UserErrorMessage(
                title: "Already on Team",
                message: "You can only be on one team at a time. To join this team, you'll need to leave your current team first (2,000 sats exit fee).",
                actionButtonTitle: "Switch Teams",
                secondaryActionTitle: "Cancel",
                canRetry: false
            )
            
        case .teamFull:
            return UserErrorMessage(
                title: "Team Full",
                message: "This team has reached its maximum number of members. Please choose a different team.",
                actionButtonTitle: "Browse Teams",
                secondaryActionTitle: "Cancel",
                canRetry: false
            )
        }
    }
    
    func getUserFriendlyMessage(for error: Error, context: ErrorContext = ErrorContext()) -> UserErrorMessage {
        if let exitFeeError = error as? ExitFeeError {
            return getUserFriendlyMessage(for: exitFeeError, context: context)
        }
        
        let category = categorizeError(error)
        
        switch category {
        case .paymentFailure:
            return UserErrorMessage(
                title: "Payment Error",
                message: "There was a problem processing your payment. Please try again or contact support if the issue persists.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Contact Support",
                helpUrl: "https://help.runstrrewards.com/payment-issues",
                canRetry: true
            )
            
        case .networkError:
            return UserErrorMessage(
                title: "Connection Problem",
                message: "Please check your internet connection and try again.",
                actionButtonTitle: "Try Again",
                canRetry: true
            )
            
        case .insufficientFunds:
            return UserErrorMessage(
                title: "Insufficient Funds",
                message: "You need 2,000 sats to leave your team. Please add funds to your wallet.",
                actionButtonTitle: "Add Funds",
                secondaryActionTitle: "Cancel",
                canRetry: true
            )
            
        case .timeout:
            return UserErrorMessage(
                title: "Request Timed Out",
                message: "The operation took too long to complete. Please try again.",
                actionButtonTitle: "Try Again",
                canRetry: true
            )
            
        case .userCancellation:
            return UserErrorMessage(
                title: "Operation Cancelled",
                message: "You cancelled the operation. Your team membership is unchanged.",
                actionButtonTitle: "OK",
                canRetry: false
            )
            
        case .teamConstraint, .validationError:
            return UserErrorMessage(
                title: "Invalid Operation",
                message: "This operation cannot be completed right now. Please refresh and try again.",
                actionButtonTitle: "Refresh",
                canRetry: false
            )
            
        case .lightningNetwork:
            return UserErrorMessage(
                title: "Lightning Network Error",
                message: "There was an issue with the Lightning Network payment. Please try again in a few moments.",
                actionButtonTitle: "Try Again",
                helpUrl: "https://help.runstrrewards.com/lightning-issues",
                canRetry: true
            )
            
        case .systemError:
            return UserErrorMessage(
                title: "System Error",
                message: "An unexpected error occurred. Please try again or contact support if the problem persists.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Contact Support",
                canRetry: true
            )
            
        case .unknown:
            return UserErrorMessage(
                title: "Unexpected Error",
                message: "Something went wrong. Please try again or contact support if the issue continues.",
                actionButtonTitle: "Try Again",
                secondaryActionTitle: "Contact Support",
                helpUrl: "https://help.runstrrewards.com/support",
                canRetry: true
            )
        }
    }
    
    // MARK: - Retry Logic
    
    func shouldRetry(error: Error, attemptCount: Int, maxAttempts: Int = 3) -> Bool {
        let category = categorizeError(error)
        
        // Never retry these categories
        let nonRetryableCategories: [ExitFeeErrorCategory] = [
            .userCancellation,
            .insufficientFunds,
            .teamConstraint,
            .validationError
        ]
        
        if nonRetryableCategories.contains(category) {
            return false
        }
        
        // Don't exceed max attempts
        if attemptCount >= maxAttempts {
            return false
        }
        
        // Retry logic based on category
        switch category {
        case .networkError, .timeout:
            return attemptCount < 3 // More retries for network issues
        case .paymentFailure, .lightningNetwork:
            return attemptCount < 2 // Fewer retries for payment issues
        case .systemError:
            return attemptCount < 2
        case .unknown:
            return attemptCount < 1 // Very conservative for unknown errors
        default:
            return false
        }
    }
    
    func getRetryDelay(attemptCount: Int, category: ExitFeeErrorCategory) -> TimeInterval {
        let baseDelay: TimeInterval
        
        switch category {
        case .networkError, .timeout:
            baseDelay = 2.0 // Quick retry for network issues
        case .paymentFailure, .lightningNetwork:
            baseDelay = 5.0 // Longer delay for payment issues
        case .systemError:
            baseDelay = 10.0 // Long delay for system errors
        default:
            baseDelay = 3.0
        }
        
        // Exponential backoff with jitter
        let exponentialDelay = baseDelay * pow(2.0, Double(attemptCount - 1))
        let jitter = Double.random(in: 0.8...1.2) // ±20% jitter
        
        return min(exponentialDelay * jitter, 30.0) // Cap at 30 seconds
    }
    
    // MARK: - Error Logging
    
    func logError(
        operation: ExitFeeOperation,
        error: Error,
        context: ErrorContext
    ) {
        let category = categorizeError(error)
        let userMessage = getUserFriendlyMessage(for: error, context: context)
        let severity = determineSeverity(category: category, attemptCount: context.attemptNumber)
        
        let logEntry = ErrorLogEntry(
            id: UUID().uuidString,
            category: category,
            error: error,
            context: context,
            userMessage: userMessage,
            severity: severity,
            timestamp: Date(),
            stackTrace: Thread.callStackSymbols.joined(separator: "\n")
        )
        
        logger.log(logEntry)
        
        // Send to analytics if it's a high severity error
        if severity == .high || severity == .critical {
            ExitFeeMetricsCollector.shared.recordPaymentAttempt(
                operationId: operation.id,
                userId: operation.userId,
                success: false,
                errorType: error as? ExitFeeError,
                attemptNumber: context.attemptNumber
            )
        }
        
        print("ExitFeeError: [\(severity.rawValue.uppercased())] \(category.rawValue) - \(error.localizedDescription)")
    }
    
    // MARK: - Private Helpers
    
    private func categorizeNetworkError(_ code: Int) -> ExitFeeErrorCategory {
        switch code {
        case NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost:
            return .timeout
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return .networkError
        case NSURLErrorCancelled:
            return .userCancellation
        default:
            return .networkError
        }
    }
    
    private func categorizeCoinOSError(_ code: Int) -> ExitFeeErrorCategory {
        switch code {
        case 1001: // Insufficient balance
            return .insufficientFunds
        case 1002: // Payment timeout
            return .timeout
        case 1003: // Lightning network error
            return .lightningNetwork
        case 1004: // Payment failed
            return .paymentFailure
        default:
            return .paymentFailure
        }
    }
    
    private func categorizeSupabaseError(_ code: Int) -> ExitFeeErrorCategory {
        switch code {
        case 404: // Not found
            return .validationError
        case 409: // Conflict (constraint violation)
            return .teamConstraint
        case 500, 502, 503: // Server errors
            return .systemError
        default:
            return .systemError
        }
    }
    
    private func determineSeverity(category: ExitFeeErrorCategory, attemptCount: Int) -> ErrorLogEntry.ErrorSeverity {
        switch category {
        case .userCancellation:
            return .low
        case .insufficientFunds, .teamConstraint, .validationError:
            return .low
        case .networkError, .timeout:
            return attemptCount > 2 ? .medium : .low
        case .paymentFailure, .lightningNetwork:
            return attemptCount > 1 ? .high : .medium
        case .systemError:
            return .high
        case .unknown:
            return .critical
        }
    }
}

// MARK: - Error Logger

private class ErrorLogger {
    private let logQueue = DispatchQueue(label: "exit_fee_error_logger", qos: .utility)
    private let maxLogEntries = 1000
    private var logEntries: [ErrorLogEntry] = []
    
    func log(_ entry: ErrorLogEntry) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.logEntries.append(entry)
            
            // Rotate logs if needed
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(500)
            }
            
            // In a production app, you might also send high-severity errors
            // to a remote logging service here
            if entry.severity == .critical {
                self.sendToRemoteLogging(entry)
            }
        }
    }
    
    func getRecentErrors(count: Int = 100) -> [ErrorLogEntry] {
        return logQueue.sync {
            return Array(logEntries.suffix(count))
        }
    }
    
    private func sendToRemoteLogging(_ entry: ErrorLogEntry) {
        // TODO: Implement remote logging for critical errors
        print("CRITICAL ERROR: \(entry.category.rawValue) - \(entry.error.localizedDescription)")
    }
}

// MARK: - Retry Policy

private class RetryPolicy {
    func shouldRetryBasedOnHistory(_ error: Error, operationId: String) -> Bool {
        // In a more sophisticated implementation, this could check
        // error history for this operation and make intelligent decisions
        // about whether retrying is likely to succeed
        
        let category = ExitFeeErrorHandler.shared.categorizeError(error)
        
        switch category {
        case .networkError:
            // Maybe check if we've had recent network issues
            return true
        case .systemError:
            // Maybe check if there's a known outage
            return true
        default:
            return false
        }
    }
}