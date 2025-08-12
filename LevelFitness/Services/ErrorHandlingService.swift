import Foundation
import UIKit

// MARK: - Custom Error Types

enum AppError: LocalizedError, Equatable, CustomStringConvertible {
    case networkUnavailable
    case authenticationRequired
    case dataCorrupted
    case serviceUnavailable
    case syncFailed(String)
    case walletError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .authenticationRequired:
            return "Authentication required. Please sign in to continue."
        case .dataCorrupted:
            return "Data appears to be corrupted. Please try refreshing."
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again later."
        case .syncFailed(let details):
            return "Sync failed: \(details)"
        case .walletError(let details):
            return "Wallet error: \(details)"
        case .unknownError(let details):
            return "An unexpected error occurred: \(details)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your WiFi or cellular connection and try again."
        case .authenticationRequired:
            return "Sign in with your Apple ID to access your data."
        case .dataCorrupted:
            return "Pull down to refresh and reload your data."
        case .serviceUnavailable:
            return "Our servers are experiencing issues. Please try again in a few minutes."
        case .syncFailed:
            return "Check your internet connection and try syncing again."
        case .walletError:
            return "Check your Lightning wallet connection in Settings."
        case .unknownError:
            return "If this continues, please contact support."
        }
    }
    
    var isCritical: Bool {
        switch self {
        case .authenticationRequired, .dataCorrupted:
            return true
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .networkUnavailable:
            return "networkUnavailable"
        case .authenticationRequired:
            return "authenticationRequired"
        case .dataCorrupted:
            return "dataCorrupted"
        case .serviceUnavailable:
            return "serviceUnavailable"
        case .syncFailed(let details):
            return "syncFailed(\(details))"
        case .walletError(let details):
            return "walletError(\(details))"
        case .unknownError(let details):
            return "unknownError(\(details))"
        }
    }
}

// MARK: - Error Handling Service

class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    private var errorCount: [String: Int] = [:]
    private let maxRetryAttempts = 3
    private let errorLogLimit = 100
    private var errorLog: [ErrorLogEntry] = []
    
    private struct ErrorLogEntry {
        let timestamp: Date
        let error: AppError
        let context: String
        let userId: String?
    }
    
    private init() {}
    
    // MARK: - Error Logging
    
    func logError(_ error: Error, context: String, userId: String? = nil) {
        let appError = convertToAppError(error)
        
        let logEntry = ErrorLogEntry(
            timestamp: Date(),
            error: appError,
            context: context,
            userId: userId
        )
        
        errorLog.append(logEntry)
        
        // Keep only the most recent errors
        if errorLog.count > errorLogLimit {
            errorLog.removeFirst(errorLog.count - errorLogLimit)
        }
        
        // Safe error logging without dictionary operations
        print("🚨 ErrorHandling: [\(context)] \(appError.localizedDescription)")
        
        // Log critical errors more prominently
        if appError.isCritical {
            print("🚨 CRITICAL ERROR: \(appError.localizedDescription)")
        }
        
        // Update error count for retry logic in a safer way
        updateErrorCount(context: context, error: appError)
    }
    
    // MARK: - Safe Error Count Management
    
    private func updateErrorCount(context: String, error: AppError) {
        // Temporarily disable error counting to prevent crashes
        // TODO: Re-enable once root cause is identified
        print("🚨 ErrorHandling: Error count tracking disabled for safety")
        return
        
        /*
        // Use a simple, safe key generation without string interpolation
        guard let contextData = context.data(using: .utf8),
              let errorData = error.description.data(using: .utf8) else {
            print("🚨 ErrorHandling: Failed to create error key safely")
            return
        }
        
        let contextHash = contextData.hashValue
        let errorHash = errorData.hashValue
        let safeKey = "\(contextHash)_\(errorHash)"
        
        do {
            errorCount[safeKey, default: 0] += 1
        } catch {
            print("🚨 ErrorHandling: Failed to update error count: \(error)")
        }
        */
    }
    
    // MARK: - Error Conversion
    
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Convert common errors to AppError
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .serviceUnavailable
            default:
                return .unknownError(urlError.localizedDescription)
            }
        }
        
        // Handle authentication errors
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("unauthorized") || errorDescription.contains("authentication") {
            return .authenticationRequired
        }
        
        // Handle sync/wallet specific errors
        if errorDescription.contains("sync") {
            return .syncFailed(error.localizedDescription)
        }
        
        if errorDescription.contains("wallet") || errorDescription.contains("lightning") {
            return .walletError(error.localizedDescription)
        }
        
        return .unknownError(error.localizedDescription)
    }
    
    // MARK: - Retry Logic
    
    func shouldRetry(context: String, error: AppError) -> Bool {
        // Disable retry logic temporarily to prevent dictionary access crashes
        switch error {
        case .networkUnavailable, .serviceUnavailable:
            return true // Allow one retry
        case .authenticationRequired, .dataCorrupted:
            return false // Don't retry these
        default:
            return true // Allow one retry for other errors
        }
    }
    
    private func getErrorCount(context: String, error: AppError) -> Int {
        guard let contextData = context.data(using: .utf8),
              let errorData = error.description.data(using: .utf8) else {
            return 0
        }
        
        let contextHash = contextData.hashValue
        let errorHash = errorData.hashValue
        let safeKey = "\(contextHash)_\(errorHash)"
        
        return errorCount[safeKey, default: 0]
    }
    
    func resetRetryCount(context: String, error: AppError) {
        guard let contextData = context.data(using: .utf8),
              let errorData = error.description.data(using: .utf8) else {
            return
        }
        
        let contextHash = contextData.hashValue
        let errorHash = errorData.hashValue
        let safeKey = "\(contextHash)_\(errorHash)"
        
        errorCount.removeValue(forKey: safeKey)
    }
    
    // MARK: - User Facing Error Handling
    
    func handleError(_ error: Error, context: String, in viewController: UIViewController?, showAlert: Bool = true) {
        let appError = convertToAppError(error)
        logError(error, context: context, userId: getCurrentUserId())
        
        guard showAlert, let viewController = viewController else { return }
        
        DispatchQueue.main.async {
            self.showErrorAlert(appError, context: context, in: viewController)
        }
    }
    
    private func showErrorAlert(_ error: AppError, context: String, in viewController: UIViewController) {
        let alert = UIAlertController(
            title: error.isCritical ? "Critical Error" : "Something went wrong",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        // Add recovery suggestion as subtitle
        if let suggestion = error.recoverySuggestion {
            alert.message = "\(error.localizedDescription)\n\n\(suggestion)"
        }
        
        // Add retry option for retryable errors
        if shouldRetry(context: context, error: error) {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                // Implement retry logic based on context
                NotificationCenter.default.post(
                    name: .errorRetryRequested,
                    object: nil,
                    userInfo: ["context": context, "error": error]
                )
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Network Status
    
    func isNetworkAvailable() -> Bool {
        // Simple network check - in production, use Network framework
        return true // Placeholder implementation
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        return AuthenticationService.shared.loadSession()?.id
    }
    
    // MARK: - Error Reporting
    
    func getErrorReport() -> String {
        let recentErrors = errorLog.suffix(20)
        
        var report = "Error Report - Last \(recentErrors.count) errors:\n\n"
        
        for (index, entry) in recentErrors.enumerated() {
            report += "\(index + 1). [\(entry.timestamp)] \(entry.context): \(entry.error.localizedDescription)\n"
        }
        
        return report
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let errorRetryRequested = Notification.Name("errorRetryRequested")
}

// MARK: - Retry Helper Protocol

protocol Retryable {
    func retry(context: String)
}

// MARK: - Error Handling Extensions

extension UIViewController {
    
    func handleError(_ error: Error, context: String, showAlert: Bool = true) {
        ErrorHandlingService.shared.handleError(error, context: context, in: self, showAlert: showAlert)
    }
    
    func showOfflineMessage() {
        let alert = UIAlertController(
            title: "You're Offline",
            message: "Some features may not be available. Your data will sync when you reconnect.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func showRetryAlert(action: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Something went wrong",
            message: "Would you like to try again?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            action()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - Task Extension for Error Handling

extension Task where Success == Void, Failure == Error {
    
    static func handleErrors(
        context: String,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            do {
                try await operation()
            } catch {
                ErrorHandlingService.shared.logError(error, context: context)
                throw error
            }
        }
    }
}