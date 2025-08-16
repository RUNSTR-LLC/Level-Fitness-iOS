import Foundation
import Network

// MARK: - Network Status

enum NetworkStatus {
    case connected(NetworkConnectionType)
    case disconnected
    case unknown
    
    var isConnected: Bool {
        switch self {
        case .connected:
            return true
        case .disconnected, .unknown:
            return false
        }
    }
}

enum NetworkConnectionType {
    case wifi
    case cellular
    case wiredEthernet
    case other
    
    var displayName: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .other:
            return "Network"
        }
    }
    
    var isExpensive: Bool {
        switch self {
        case .cellular:
            return true
        case .wifi, .wiredEthernet, .other:
            return false
        }
    }
}

// MARK: - Network Monitor Service

class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    @Published var status: NetworkStatus = .unknown
    @Published var isConnected: Bool = false
    
    private var connectionHistory: [NetworkConnectionEvent] = []
    private let maxHistoryCount = 50
    
    private struct NetworkConnectionEvent {
        let timestamp: Date
        let status: NetworkStatus
        let previousStatus: NetworkStatus?
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateNetworkStatus(path)
        }
        
        monitor.start(queue: queue)
        print("🌐 NetworkMonitor: Started network monitoring")
    }
    
    private func stopMonitoring() {
        monitor.cancel()
        print("🌐 NetworkMonitor: Stopped network monitoring")
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        let previousStatus = status
        let newStatus = determineStatus(from: path)
        
        // Update status on main thread
        DispatchQueue.main.async {
            self.status = newStatus
            self.isConnected = newStatus.isConnected
            
            // Log connection changes
            if newStatus.isConnected != previousStatus.isConnected {
                self.logConnectionChange(from: previousStatus, to: newStatus)
                self.handleConnectionChange(from: previousStatus, to: newStatus)
            }
        }
    }
    
    private func determineStatus(from path: NWPath) -> NetworkStatus {
        guard path.status == .satisfied else {
            return .disconnected
        }
        
        if path.usesInterfaceType(.wifi) {
            return .connected(.wifi)
        } else if path.usesInterfaceType(.cellular) {
            return .connected(.cellular)
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .connected(.wiredEthernet)
        } else {
            return .connected(.other)
        }
    }
    
    private func logConnectionChange(from previous: NetworkStatus, to current: NetworkStatus) {
        let event = NetworkConnectionEvent(
            timestamp: Date(),
            status: current,
            previousStatus: previous
        )
        
        connectionHistory.append(event)
        
        // Keep history size manageable
        if connectionHistory.count > maxHistoryCount {
            connectionHistory.removeFirst(connectionHistory.count - maxHistoryCount)
        }
        
        // Log the change
        switch (previous.isConnected, current.isConnected) {
        case (false, true):
            print("🌐 NetworkMonitor: Connected via \(getConnectionTypeName(current))")
        case (true, false):
            print("🌐 NetworkMonitor: Disconnected from \(getConnectionTypeName(previous))")
        case (true, true):
            print("🌐 NetworkMonitor: Connection changed from \(getConnectionTypeName(previous)) to \(getConnectionTypeName(current))")
        default:
            break
        }
    }
    
    private func getConnectionTypeName(_ status: NetworkStatus) -> String {
        switch status {
        case .connected(let type):
            return type.displayName
        case .disconnected:
            return "Disconnected"
        case .unknown:
            return "Unknown"
        }
    }
    
    // MARK: - Connection Change Handling
    
    private func handleConnectionChange(from previous: NetworkStatus, to current: NetworkStatus) {
        // Notify other services about connection changes
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: [
                "previousStatus": previous,
                "currentStatus": current
            ]
        )
        
        // Update offline data service
        OfflineDataService.shared.setOfflineMode(!current.isConnected)
        
        // Handle specific connection scenarios
        switch (previous.isConnected, current.isConnected) {
        case (false, true):
            handleConnectionRestored(current)
        case (true, false):
            handleConnectionLost()
        case (true, true):
            handleConnectionTypeChanged(from: previous, to: current)
        default:
            break
        }
    }
    
    private func handleConnectionRestored(_ status: NetworkStatus) {
        print("🌐 NetworkMonitor: Connection restored - syncing pending data")
        
        // Trigger sync of pending actions
        Task {
            await OfflineDataService.shared.processPendingActions()
        }
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .connectionRestored, object: status)
        }
    }
    
    private func handleConnectionLost() {
        print("🌐 NetworkMonitor: Connection lost - switching to offline mode")
        
        // Post notification for UI updates
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .connectionLost, object: nil)
        }
    }
    
    private func handleConnectionTypeChanged(from previous: NetworkStatus, to current: NetworkStatus) {
        // Check if switching from expensive to cheap connection or vice versa
        let previousExpensive = isExpensiveConnection(previous)
        let currentExpensive = isExpensiveConnection(current)
        
        if previousExpensive && !currentExpensive {
            print("🌐 NetworkMonitor: Switched to cheaper connection - enabling background sync")
            // Enable more aggressive syncing
        } else if !previousExpensive && currentExpensive {
            print("🌐 NetworkMonitor: Switched to expensive connection - limiting background sync")
            // Reduce background syncing
        }
    }
    
    private func isExpensiveConnection(_ status: NetworkStatus) -> Bool {
        switch status {
        case .connected(let type):
            return type.isExpensive
        case .disconnected, .unknown:
            return false
        }
    }
    
    // MARK: - Public Methods
    
    func getCurrentStatus() -> NetworkStatus {
        return status
    }
    
    func isCurrentlyConnected() -> Bool {
        return isConnected
    }
    
    func getConnectionType() -> NetworkConnectionType? {
        switch status {
        case .connected(let type):
            return type
        case .disconnected, .unknown:
            return nil
        }
    }
    
    func isExpensiveConnection() -> Bool {
        return isExpensiveConnection(status)
    }
    
    // MARK: - Connection Testing
    
    func testConnectivity() async -> Bool {
        guard isConnected else { return false }
        
        do {
            // Test with a lightweight request to Supabase
            let url = URL(string: "https://cqhlwoguxbwnqdternci.supabase.co/rest/v1/")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isReachable = httpResponse.statusCode < 500
                print("🌐 NetworkMonitor: Connectivity test \(isReachable ? "passed" : "failed") - Status: \(httpResponse.statusCode)")
                return isReachable
            }
            
            return false
        } catch {
            print("🌐 NetworkMonitor: Connectivity test failed: \(error)")
            return false
        }
    }
    
    // MARK: - Connection History
    
    func getConnectionHistory() -> [(Date, String)] {
        return connectionHistory.map { event in
            let statusText = getConnectionTypeName(event.status)
            return (event.timestamp, statusText)
        }
    }
    
    func getConnectionReport() -> String {
        let recentEvents = connectionHistory.suffix(10)
        
        var report = "Network Connection Report:\n"
        report += "Current Status: \(getConnectionTypeName(status))\n"
        report += "Is Connected: \(isConnected ? "Yes" : "No")\n"
        
        if let connectionType = getConnectionType() {
            report += "Connection Type: \(connectionType.displayName)\n"
            report += "Is Expensive: \(connectionType.isExpensive ? "Yes" : "No")\n"
        }
        
        report += "\nRecent Connection History:\n"
        
        for event in recentEvents {
            let timeString = DateFormatter.shortTime.string(from: event.timestamp)
            report += "• \(timeString): \(getConnectionTypeName(event.status))\n"
        }
        
        return report
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let connectionRestored = Notification.Name("connectionRestored")
    static let connectionLost = Notification.Name("connectionLost")
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Network-Aware Operations

protocol NetworkAware {
    func handleNetworkStatusChange(_ isConnected: Bool)
    func shouldPerformNetworkOperation() -> Bool
}

extension NetworkAware {
    func shouldPerformNetworkOperation() -> Bool {
        let monitor = NetworkMonitorService.shared
        
        // Always allow if connected to non-expensive network
        guard monitor.isCurrentlyConnected() else { return false }
        
        // Limit operations on expensive connections
        if monitor.isExpensiveConnection() {
            // Allow critical operations only
            return true // In practice, you'd check operation priority
        }
        
        return true
    }
}

// MARK: - Network-Aware Task Extension

extension Task where Success == Void, Failure == Error {
    
    static func networkAware(
        priority: TaskPriority? = nil,
        requiresNetwork: Bool = true,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            if requiresNetwork && !NetworkMonitorService.shared.isCurrentlyConnected() {
                throw AppError.networkUnavailable
            }
            
            try await operation()
        }
    }
}