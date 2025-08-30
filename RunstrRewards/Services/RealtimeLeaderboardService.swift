import Foundation
import Combine

// MARK: - Real-time Models

struct LiveLeaderboardUpdate {
    let eventId: String
    let timestamp: Date
    let updateType: LeaderboardUpdateType
    let affectedEntries: [LeaderboardEntry]
    let metadata: [String: Any]
}

enum LeaderboardUpdateType {
    case newEntry
    case positionChange
    case valueUpdate
    case userJoined
    case userLeft
    case eventComplete
}

struct LiveEventStatus {
    let eventId: String
    var isActive: Bool
    let participantCount: Int
    let lastUpdate: Date
    let updateFrequency: TimeInterval
    let connectionStatus: ConnectionStatus
}

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case error(String)
}

// MARK: - RealtimeLeaderboardService

class RealtimeLeaderboardService: ObservableObject {
    static let shared = RealtimeLeaderboardService()
    
    @Published var liveUpdates: [String: LiveLeaderboardUpdate] = [:]
    @Published var eventStatuses: [String: LiveEventStatus] = [:]
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private var updateTimers: [String: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = NotificationCenter.default
    
    // Update frequencies for different event types
    private let updateIntervals: [EventType: TimeInterval] = [
        .sprint: 10.0,      // 10 seconds for sprints
        .marathon: 60.0,    // 1 minute for marathons
        .challenge: 30.0    // 30 seconds for challenges
    ]
    
    private init() {
        setupNotificationObservers()
        startConnectionMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupNotificationObservers() {
        // Listen for progress updates from EventProgressTracker
        notificationCenter.addObserver(
            self,
            selector: #selector(handleProgressUpdate),
            name: NSNotification.Name("EventProgressUpdated"),
            object: nil
        )
        
        // Listen for new user qualifications
        notificationCenter.addObserver(
            self,
            selector: #selector(handleUserQualified),
            name: NSNotification.Name("UserQualifiedForEvent"),
            object: nil
        )
    }
    
    private func startConnectionMonitoring() {
        // Simulate connection monitoring
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkConnectionHealth()
        }
    }
    
    // MARK: - Event Management
    
    func startRealtimeUpdates(for eventId: String, eventType: EventType) {
        print("🔴 Realtime: Starting live updates for event: \(eventId)")
        
        // Set update frequency based on event type
        let interval = updateIntervals[eventType] ?? 30.0
        
        // Create live event status
        let status = LiveEventStatus(
            eventId: eventId,
            isActive: true,
            participantCount: getParticipantCount(eventId: eventId),
            lastUpdate: Date(),
            updateFrequency: interval,
            connectionStatus: .connected
        )
        
        eventStatuses[eventId] = status
        
        // Start update timer
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchLatestData(for: eventId)
        }
        
        updateTimers[eventId] = timer
        
        // Initial fetch
        fetchLatestData(for: eventId)
    }
    
    func stopRealtimeUpdates(for eventId: String) {
        print("🔴 Realtime: Stopping live updates for event: \(eventId)")
        
        updateTimers[eventId]?.invalidate()
        updateTimers.removeValue(forKey: eventId)
        
        var status = eventStatuses[eventId]
        status?.isActive = false
        if let updatedStatus = status {
            eventStatuses[eventId] = updatedStatus
        }
        
        // Send final update
        let finalUpdate = LiveLeaderboardUpdate(
            eventId: eventId,
            timestamp: Date(),
            updateType: .eventComplete,
            affectedEntries: EventProgressTracker.shared.getLeaderboard(eventId: eventId).map { eventEntry in
                LeaderboardEntry(
                    userId: eventEntry.userId,
                    username: eventEntry.username,
                    rank: eventEntry.rank,
                    points: eventEntry.points,
                    workoutCount: 0, // Default value
                    totalDistance: eventEntry.totalValue // Use totalValue as distance
                )
            },
            metadata: ["reason": "Event completed"]
        )
        
        liveUpdates[eventId] = finalUpdate
        broadcastUpdate(finalUpdate)
    }
    
    // MARK: - Data Fetching
    
    private func fetchLatestData(for eventId: String) {
        // Get current leaderboard
        let currentLeaderboard = EventProgressTracker.shared.getLeaderboard(eventId: eventId)
        
        // Check for changes since last update
        let lastUpdate = liveUpdates[eventId]
        var hasChanges = false
        var updateType: LeaderboardUpdateType = .valueUpdate
        
        if let lastUpdate = lastUpdate {
            // Compare with previous leaderboard
            let previousEntries = lastUpdate.affectedEntries
            
            // Check for position changes
            for (index, entry) in currentLeaderboard.enumerated() {
                if index < previousEntries.count {
                    let previousEntry = previousEntries[index]
                    if previousEntry.userId != entry.userId {
                        hasChanges = true
                        updateType = .positionChange
                        break
                    } else if previousEntry.points != entry.points {
                        hasChanges = true
                        updateType = .valueUpdate
                    }
                }
            }
            
            // Check for new participants
            if currentLeaderboard.count != previousEntries.count {
                hasChanges = true
                updateType = currentLeaderboard.count > previousEntries.count ? .userJoined : .userLeft
            }
        } else {
            // First update
            hasChanges = true
            updateType = .newEntry
        }
        
        if hasChanges {
            let update = LiveLeaderboardUpdate(
                eventId: eventId,
                timestamp: Date(),
                updateType: updateType,
                affectedEntries: currentLeaderboard.map { eventEntry in
                    LeaderboardEntry(
                        userId: eventEntry.userId,
                        username: eventEntry.username,
                        rank: eventEntry.rank,
                        points: eventEntry.points,
                        workoutCount: 0, // Default value
                        totalDistance: eventEntry.totalValue
                    )
                },
                metadata: [
                    "participantCount": currentLeaderboard.count,
                    "topPerformer": currentLeaderboard.first?.username ?? "None"
                ]
            )
            
            liveUpdates[eventId] = update
            updateEventStatus(eventId: eventId)
            broadcastUpdate(update)
            
            print("🔴 Realtime: Broadcasting update for \(eventId): \(updateType)")
        }
    }
    
    private func updateEventStatus(eventId: String) {
        guard var status = eventStatuses[eventId] else { return }
        
        let participantCount = getParticipantCount(eventId: eventId)
        
        status = LiveEventStatus(
            eventId: status.eventId,
            isActive: status.isActive,
            participantCount: participantCount,
            lastUpdate: Date(),
            updateFrequency: status.updateFrequency,
            connectionStatus: status.connectionStatus
        )
        
        eventStatuses[eventId] = status
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleProgressUpdate(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String,
              let updateType = notification.userInfo?["updateType"] as? ProgressUpdateType else {
            return
        }
        
        // Trigger immediate update for significant changes
        if case .rankChange = updateType {
            DispatchQueue.main.async {
                self.fetchLatestData(for: eventId)
            }
        }
        
        print("🔴 Realtime: Received progress update for user \(userId) in event \(eventId)")
    }
    
    @objc private func handleUserQualified(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let userId = notification.userInfo?["userId"] as? String else {
            return
        }
        
        // User qualified and auto-entered, trigger leaderboard update
        DispatchQueue.main.async {
            self.fetchLatestData(for: eventId)
        }
        
        print("🔴 Realtime: User \(userId) qualified for event \(eventId)")
    }
    
    // MARK: - Broadcasting
    
    private func broadcastUpdate(_ update: LiveLeaderboardUpdate) {
        // Post notification for UI components to listen to
        let notification = Notification(
            name: NSNotification.Name("RealtimeLeaderboardUpdate"),
            object: nil,
            userInfo: [
                "update": update,
                "eventId": update.eventId,
                "updateType": update.updateType
            ]
        )
        
        notificationCenter.post(notification)
        
        // Update published properties on main queue
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Connection Monitoring
    
    private func checkConnectionHealth() {
        // Simulate connection health check
        let isHealthy = Bool.random() ? true : (Int.random(in: 1...10) <= 9) // 90% uptime
        
        let newStatus: ConnectionStatus = isHealthy ? .connected : .error("Network timeout")
        
        if case .connected = connectionStatus, case .error = newStatus {
            print("🔴 Realtime: Connection lost - switching to offline mode")
        } else if case .error = connectionStatus, case .connected = newStatus {
            print("🔴 Realtime: Connection restored - resuming live updates")
        }
        
        connectionStatus = newStatus
        
        // Update all event statuses
        for (eventId, var status) in eventStatuses {
            status = LiveEventStatus(
                eventId: status.eventId,
                isActive: status.isActive,
                participantCount: status.participantCount,
                lastUpdate: status.lastUpdate,
                updateFrequency: status.updateFrequency,
                connectionStatus: newStatus
            )
            eventStatuses[eventId] = status
        }
    }
    
    // MARK: - Data Access
    
    func getLatestUpdate(for eventId: String) -> LiveLeaderboardUpdate? {
        return liveUpdates[eventId]
    }
    
    func getEventStatus(for eventId: String) -> LiveEventStatus? {
        return eventStatuses[eventId]
    }
    
    func isEventActive(eventId: String) -> Bool {
        return eventStatuses[eventId]?.isActive ?? false
    }
    
    func getUpdateFrequency(for eventId: String) -> TimeInterval {
        return eventStatuses[eventId]?.updateFrequency ?? 30.0
    }
    
    // MARK: - Manual Updates
    
    func forceUpdate(for eventId: String) {
        print("🔴 Realtime: Force updating leaderboard for event: \(eventId)")
        fetchLatestData(for: eventId)
    }
    
    func refreshAll() {
        print("🔴 Realtime: Refreshing all active leaderboards")
        for eventId in eventStatuses.keys {
            fetchLatestData(for: eventId)
        }
    }
    
    // MARK: - Analytics
    
    func getUpdateStats() -> (totalEvents: Int, totalUpdates: Int, avgFrequency: TimeInterval) {
        let totalEvents = eventStatuses.count
        let totalUpdates = liveUpdates.count
        let avgFrequency = eventStatuses.values.map { $0.updateFrequency }.reduce(0, +) / Double(max(1, totalEvents))
        
        return (totalEvents, totalUpdates, avgFrequency)
    }
    
    func getRecentUpdates(limit: Int = 10) -> [LiveLeaderboardUpdate] {
        return Array(liveUpdates.values
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit))
    }
    
    // MARK: - Helper Methods
    
    private func getParticipantCount(eventId: String) -> Int {
        return EventProgressTracker.shared.getLeaderboard(eventId: eventId).count
    }
    
    // MARK: - Cleanup
    
    deinit {
        for timer in updateTimers.values {
            timer.invalidate()
        }
        notificationCenter.removeObserver(self)
    }
}

// MARK: - Extensions

extension RealtimeLeaderboardService {
    
    // Convenience methods for UI components
    func startLiveTracking(for event: EventData) {
        startRealtimeUpdates(for: event.id, eventType: event.type)
    }
    
    func stopLiveTracking(for event: EventData) {
        stopRealtimeUpdates(for: event.id)
    }
    
    func getCurrentRank(eventId: String, userId: String) -> Int? {
        return getLatestUpdate(for: eventId)?
            .affectedEntries
            .first(where: { $0.userId == userId })?
            .rank
    }
    
    func getTopPerformers(eventId: String, limit: Int = 3) -> [LeaderboardEntry] {
        guard let update = getLatestUpdate(for: eventId) else { return [] }
        return Array(update.affectedEntries.prefix(limit))
    }
}

