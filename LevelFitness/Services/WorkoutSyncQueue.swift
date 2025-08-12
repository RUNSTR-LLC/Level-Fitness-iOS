import Foundation
import CoreData

class WorkoutSyncQueue {
    static let shared = WorkoutSyncQueue()
    
    private let supabaseService = SupabaseService.shared
    private let networkMonitor = NetworkMonitorService.shared
    private let errorHandler = ErrorHandlingService.shared
    
    // Sync queue management
    private var syncQueue: [QueuedWorkout] = []
    private var isSyncing = false
    private let syncLock = NSLock()
    
    // Storage keys
    private let queueStorageKey = "workout_sync_queue"
    private let lastSyncKey = "last_workout_sync"
    
    private init() {
        loadQueueFromStorage()
        setupNetworkMonitoring()
    }
    
    // MARK: - Queue Management
    
    func queueWorkout(_ workout: Workout) {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        let queuedWorkout = QueuedWorkout(
            id: UUID().uuidString,
            workout: workout,
            attempts: 0,
            priority: calculatePriority(workout),
            queuedAt: Date(),
            lastAttempt: nil,
            status: .pending
        )
        
        // Check for duplicates
        if !syncQueue.contains(where: { $0.workout.id == workout.id }) {
            syncQueue.append(queuedWorkout)
            saveQueueToStorage()
            
            print("WorkoutSyncQueue: Queued workout \(workout.id) (Priority: \(queuedWorkout.priority))")
            
            // Try immediate sync if connected
            if networkMonitor.isCurrentlyConnected() {
                Task {
                    await processSyncQueue()
                }
            }
        }
    }
    
    func getQueuedWorkouts() -> [QueuedWorkout] {
        syncLock.lock()
        defer { syncLock.unlock() }
        return syncQueue
    }
    
    func getQueueCount() -> Int {
        syncLock.lock()
        defer { syncLock.unlock() }
        return syncQueue.count
    }
    
    func clearQueue() {
        syncLock.lock()
        defer { syncLock.unlock() }
        syncQueue.removeAll()
        saveQueueToStorage()
        print("WorkoutSyncQueue: Queue cleared")
    }
    
    // MARK: - Sync Processing
    
    func processSyncQueue() async {
        guard !isSyncing else {
            print("WorkoutSyncQueue: Sync already in progress")
            return
        }
        
        guard networkMonitor.isCurrentlyConnected() else {
            print("WorkoutSyncQueue: No network connection, skipping sync")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        print("WorkoutSyncQueue: Starting sync process")
        
        var processedCount = 0
        var failedCount = 0
        
        // Get items to sync (sorted by priority)
        let itemsToSync = getItemsToSync()
        
        for queuedWorkout in itemsToSync {
            do {
                try await syncWorkout(queuedWorkout)
                removeFromQueue(queuedWorkout.id)
                processedCount += 1
                
                print("WorkoutSyncQueue: Synced workout \(queuedWorkout.workout.id)")
                
                // Add small delay to avoid overwhelming the server
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
            } catch {
                failedCount += 1
                await handleSyncFailure(queuedWorkout, error: error)
            }
        }
        
        // Update last sync time
        UserDefaults.standard.set(Date(), forKey: lastSyncKey)
        
        print("WorkoutSyncQueue: Sync complete - \(processedCount) synced, \(failedCount) failed")
        
        // Send notification about sync completion
        if processedCount > 0 {
            NotificationCenter.default.post(
                name: .workoutSyncCompleted,
                object: nil,
                userInfo: ["synced": processedCount, "failed": failedCount]
            )
        }
    }
    
    private func getItemsToSync() -> [QueuedWorkout] {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        // Filter out items that shouldn't be retried yet
        let now = Date()
        return syncQueue
            .filter { item in
                switch item.status {
                case .pending:
                    return true
                case .retrying:
                    let backoffDelay = calculateBackoffDelay(attempts: item.attempts)
                    let nextRetryTime = item.lastAttempt?.addingTimeInterval(backoffDelay) ?? now
                    return now >= nextRetryTime
                case .failed:
                    return item.attempts < maxRetryAttempts
                case .synced:
                    return false
                }
            }
            .sorted { $0.priority > $1.priority } // Higher priority first
    }
    
    private func syncWorkout(_ queuedWorkout: QueuedWorkout) async throws {
        // Update attempt count
        updateWorkoutAttempt(queuedWorkout.id)
        
        // Perform the actual sync
        try await supabaseService.syncWorkout(queuedWorkout.workout)
        
        // Mark as synced
        updateWorkoutStatus(queuedWorkout.id, status: .synced)
    }
    
    private func handleSyncFailure(_ queuedWorkout: QueuedWorkout, error: Error) async {
        let updatedWorkout = incrementAttempts(queuedWorkout)
        
        if updatedWorkout.attempts >= maxRetryAttempts {
            // Max attempts reached, mark as permanently failed
            updateWorkoutStatus(updatedWorkout.id, status: .failed)
            
            // Log the permanent failure
            errorHandler.logError(
                error,
                context: "WorkoutSyncQueue.permanentFailure",
                metadata: [
                    "workoutId": updatedWorkout.workout.id,
                    "attempts": updatedWorkout.attempts
                ]
            )
            
            print("WorkoutSyncQueue: Permanent failure for workout \(updatedWorkout.workout.id) after \(updatedWorkout.attempts) attempts")
        } else {
            // Schedule for retry
            updateWorkoutStatus(updatedWorkout.id, status: .retrying)
            
            print("WorkoutSyncQueue: Retry \(updatedWorkout.attempts)/\(maxRetryAttempts) for workout \(updatedWorkout.workout.id)")
        }
        
        // Log the error for monitoring
        errorHandler.logError(
            error,
            context: "WorkoutSyncQueue.syncFailure",
            metadata: [
                "workoutId": updatedWorkout.workout.id,
                "attempt": updatedWorkout.attempts
            ]
        )
    }
    
    // MARK: - Priority Calculation
    
    private func calculatePriority(_ workout: Workout) -> Int {
        var priority = 100 // Base priority
        
        // Recent workouts have higher priority
        let ageInHours = Date().timeIntervalSince(workout.startedAt) / 3600
        if ageInHours < 1 {
            priority += 50 // Very recent
        } else if ageInHours < 24 {
            priority += 25 // Within last day
        } else if ageInHours < 168 { // Within last week
            priority += 10
        }
        
        // Longer workouts have higher priority (more valuable data)
        let durationMinutes = workout.duration / 60
        if durationMinutes > 60 {
            priority += 20 // Long workout
        } else if durationMinutes > 30 {
            priority += 10 // Medium workout
        }
        
        // Workouts with distance data have higher priority
        if let distance = workout.distance, distance > 0 {
            priority += 15
        }
        
        // Workouts with heart rate data have higher priority
        if let heartRate = workout.heartRate, heartRate > 0 {
            priority += 10
        }
        
        return priority
    }
    
    // MARK: - Retry Logic
    
    private let maxRetryAttempts = 5
    
    private func calculateBackoffDelay(attempts: Int) -> TimeInterval {
        // Exponential backoff: 30s, 60s, 2m, 4m, 8m
        let baseDelay: TimeInterval = 30
        return baseDelay * pow(2.0, Double(attempts - 1))
    }
    
    // MARK: - Queue Persistence
    
    private func saveQueueToStorage() {
        do {
            let data = try JSONEncoder().encode(syncQueue)
            UserDefaults.standard.set(data, forKey: queueStorageKey)
        } catch {
            print("WorkoutSyncQueue: Failed to save queue: \(error)")
        }
    }
    
    private func loadQueueFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: queueStorageKey) else { return }
        
        do {
            syncQueue = try JSONDecoder().decode([QueuedWorkout].self, from: data)
            print("WorkoutSyncQueue: Loaded \(syncQueue.count) items from storage")
        } catch {
            print("WorkoutSyncQueue: Failed to load queue: \(error)")
            syncQueue = []
        }
    }
    
    // MARK: - Queue Item Updates
    
    private func removeFromQueue(_ id: String) {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        syncQueue.removeAll { $0.id == id }
        saveQueueToStorage()
    }
    
    private func updateWorkoutAttempt(_ id: String) {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        if let index = syncQueue.firstIndex(where: { $0.id == id }) {
            syncQueue[index].lastAttempt = Date()
        }
        saveQueueToStorage()
    }
    
    private func updateWorkoutStatus(_ id: String, status: SyncStatus) {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        if let index = syncQueue.firstIndex(where: { $0.id == id }) {
            syncQueue[index].status = status
            saveQueueToStorage()
        }
    }
    
    private func incrementAttempts(_ queuedWorkout: QueuedWorkout) -> QueuedWorkout {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        if let index = syncQueue.firstIndex(where: { $0.id == queuedWorkout.id }) {
            syncQueue[index].attempts += 1
            syncQueue[index].lastAttempt = Date()
            saveQueueToStorage()
            return syncQueue[index]
        }
        
        return queuedWorkout
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Monitor network status changes
        NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if self?.networkMonitor.isCurrentlyConnected() == true {
                // Network came back, try to sync
                Task {
                    await self?.processSyncQueue()
                }
            }
        }
    }
    
    // MARK: - Manual Operations
    
    func forceSyncAll() async {
        print("WorkoutSyncQueue: Force syncing all queued workouts")
        await processSyncQueue()
    }
    
    func retryFailedWorkouts() {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        // Reset failed workouts to pending
        for index in syncQueue.indices {
            if syncQueue[index].status == .failed {
                syncQueue[index].status = .pending
                syncQueue[index].attempts = 0
                syncQueue[index].lastAttempt = nil
            }
        }
        
        saveQueueToStorage()
        
        // Try to sync
        if networkMonitor.isCurrentlyConnected() {
            Task {
                await processSyncQueue()
            }
        }
        
        print("WorkoutSyncQueue: Reset \(syncQueue.filter { $0.status == .pending }.count) failed workouts for retry")
    }
    
    func removeWorkout(id: String) {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        syncQueue.removeAll { $0.workout.id == id }
        saveQueueToStorage()
        print("WorkoutSyncQueue: Manually removed workout \(id)")
    }
    
    // MARK: - Statistics
    
    func getSyncStatistics() -> SyncStatistics {
        syncLock.lock()
        defer { syncLock.unlock() }
        
        let pending = syncQueue.filter { $0.status == .pending }.count
        let retrying = syncQueue.filter { $0.status == .retrying }.count
        let failed = syncQueue.filter { $0.status == .failed }.count
        let synced = syncQueue.filter { $0.status == .synced }.count
        
        let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
        
        return SyncStatistics(
            totalQueued: syncQueue.count,
            pending: pending,
            retrying: retrying,
            failed: failed,
            synced: synced,
            lastSyncTime: lastSync,
            isCurrentlyConnected: networkMonitor.isCurrentlyConnected()
        )
    }
}

// MARK: - Data Models

struct QueuedWorkout: Codable {
    let id: String
    let workout: Workout
    var attempts: Int
    let priority: Int
    let queuedAt: Date
    var lastAttempt: Date?
    var status: SyncStatus
}

enum SyncStatus: String, Codable {
    case pending = "pending"
    case retrying = "retrying"
    case synced = "synced"
    case failed = "failed"
}

struct SyncStatistics {
    let totalQueued: Int
    let pending: Int
    let retrying: Int
    let failed: Int
    let synced: Int
    let lastSyncTime: Date?
    let isCurrentlyConnected: Bool
    
    var pendingCount: Int {
        return pending + retrying
    }
    
    var successRate: Double {
        guard totalQueued > 0 else { return 0 }
        return Double(synced) / Double(totalQueued)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workoutSyncCompleted = Notification.Name("workoutSyncCompleted")
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - Background Sync Integration

extension WorkoutSyncQueue {
    
    /// Process sync queue in background task
    func processInBackground() async {
        print("WorkoutSyncQueue: Processing queue in background")
        await processSyncQueue()
    }
    
    /// Quick sync for immediate operations
    func quickSync(workout: Workout) async {
        if networkMonitor.isCurrentlyConnected() {
            do {
                try await supabaseService.syncWorkout(workout)
                print("WorkoutSyncQueue: Quick sync successful for workout \(workout.id)")
            } catch {
                // If quick sync fails, add to queue
                queueWorkout(workout)
                print("WorkoutSyncQueue: Quick sync failed, added to queue")
            }
        } else {
            // No connection, add to queue
            queueWorkout(workout)
            print("WorkoutSyncQueue: No connection, added workout to queue")
        }
    }
    
    /// Batch sync multiple workouts efficiently
    func batchSync(workouts: [Workout]) async {
        guard networkMonitor.isCurrentlyConnected() else {
            // Queue all workouts if offline
            for workout in workouts {
                queueWorkout(workout)
            }
            return
        }
        
        var synced = 0
        var failed = 0
        
        for workout in workouts {
            do {
                try await supabaseService.syncWorkout(workout)
                synced += 1
                
                // Small delay between batch items
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                
            } catch {
                queueWorkout(workout)
                failed += 1
            }
        }
        
        print("WorkoutSyncQueue: Batch sync complete - \(synced) synced, \(failed) queued")
    }
}