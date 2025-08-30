import Foundation
import os.log

/// Production-ready logging system for RunstrRewards
/// Replaces debug print statements with structured, filterable logging
final class Logger {
    
    // MARK: - Singleton
    static let shared = Logger()
    private init() {}
    
    // MARK: - Log Categories
    enum Category: String, CaseIterable {
        case app = "App"
        case healthKit = "HealthKit"
        case wallet = "Wallet" 
        case team = "Team"
        case background = "Background"
        case notifications = "Notifications"
        case network = "Network"
        case competition = "Competition"
        case authentication = "Auth"
        case performance = "Performance"
        
        var osLog: OSLog {
            return OSLog(subsystem: "com.runstrrewards.app", category: self.rawValue)
        }
    }
    
    // MARK: - Log Levels
    enum Level {
        case debug
        case info
        case warning
        case error
        case critical
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🔥"
            }
        }
    }
    
    // MARK: - Configuration
    #if DEBUG
    private let enableConsoleLogging = true
    private let minimumLevel: Level = .debug
    #else
    private let enableConsoleLogging = false
    private let minimumLevel: Level = .info
    #endif
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Core Logging
    
    private func log(_ message: String, level: Level, category: Category, file: String, function: String, line: Int) {
        // Check minimum level
        guard shouldLog(level: level) else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let formattedMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        // OS Log for system integration
        os_log("%{public}@", log: category.osLog, type: level.osLogType, formattedMessage)
        
        // Console logging for development
        if enableConsoleLogging {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let consoleMessage = "\(timestamp) \(level.emoji) [\(category.rawValue)] \(formattedMessage)"
            print(consoleMessage)
        }
    }
    
    private func shouldLog(level: Level) -> Bool {
        return level.priority >= minimumLevel.priority
    }
    
    // MARK: - Specialized Logging Methods
    
    /// Log workout processing events with special formatting
    func logWorkout(_ message: String, workoutId: String? = nil, userId: String? = nil) {
        let workoutInfo = workoutId.map { " [Workout: \($0)]" } ?? ""
        let userInfo = userId.map { " [User: \($0)]" } ?? ""
        info("🏃‍♂️ \(message)\(workoutInfo)\(userInfo)", category: .healthKit)
    }
    
    /// Log Bitcoin/Lightning operations with special formatting
    func logWallet(_ message: String, amount: Int? = nil, hash: String? = nil) {
        let amountInfo = amount.map { " [\($0) sats]" } ?? ""
        let hashInfo = hash.map { " [Hash: \($0.prefix(8))...]" } ?? ""
        info("⚡ \(message)\(amountInfo)\(hashInfo)", category: .wallet)
    }
    
    /// Log team operations with special formatting  
    func logTeam(_ message: String, teamId: String? = nil, teamName: String? = nil) {
        let teamInfo = teamName.map { " [Team: \($0)]" } ?? teamId.map { " [ID: \($0)]" } ?? ""
        info("👥 \(message)\(teamInfo)", category: .team)
    }
    
    /// Log background task operations
    func logBackground(_ message: String, taskType: String? = nil) {
        let taskInfo = taskType.map { " [Task: \($0)]" } ?? ""
        info("🔄 \(message)\(taskInfo)", category: .background)
    }
    
    /// Log competition events
    func logCompetition(_ message: String, eventId: String? = nil, leaderboard: String? = nil) {
        let eventInfo = eventId.map { " [Event: \($0)]" } ?? ""
        let leaderboardInfo = leaderboard.map { " [Leaderboard: \($0)]" } ?? ""
        info("🏆 \(message)\(eventInfo)\(leaderboardInfo)", category: .competition)
    }
    
    /// Log performance metrics
    func logPerformance(_ message: String, duration: TimeInterval? = nil, items: Int? = nil) {
        let durationInfo = duration.map { String(format: " [%.2fs]", $0) } ?? ""
        let itemInfo = items.map { " [\($0) items]" } ?? ""
        info("⚡ \(message)\(durationInfo)\(itemInfo)", category: .performance)
    }
}

// MARK: - Extensions

extension Logger.Level {
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// MARK: - Global Convenience Functions

/// Global logging functions for easy access throughout the app
func logDebug(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, category: category, file: file, function: function, line: line)
}

func logInfo(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, category: category, file: file, function: function, line: line)
}

func logWarning(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, category: category, file: file, function: function, line: line)
}

func logError(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, category: category, file: file, function: function, line: line)
}

func logCritical(_ message: String, category: Logger.Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, category: category, file: file, function: function, line: line)
}