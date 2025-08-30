import Foundation

/// Manages retry logic for failed workout syncs with exponential backoff
@MainActor
class WorkoutSyncRetryManager {
    static let shared = WorkoutSyncRetryManager()
    
    // Track failed workouts for retry
    private var failedWorkouts: [String: FailedWorkoutSync] = [:]
    
    // Retry configuration
    private let maxRetryAttempts: Int = 3
    private let baseDelay: TimeInterval = 2.0 // Start with 2 seconds
    private let maxDelay: TimeInterval = 60.0 // Cap at 1 minute
    
    private init() {
        // Schedule periodic retry processing
        schedulePeriodicRetries()
    }
    
    // MARK: - Public Interface
    
    /// Records a failed workout sync for later retry
    func recordFailedSync(
        workout: HealthKitWorkout,
        userId: String,
        error: Error,
        source: String = "Unknown"
    ) {
        let workoutKey = workout.id
        let now = Date()
        
        if let existingFailure = failedWorkouts[workoutKey] {
            // Update existing failure
            let newAttemptCount = existingFailure.attemptCount + 1
            
            if newAttemptCount >= maxRetryAttempts {
                print("❌ RetryManager: Workout \(workout.id) exceeded max retry attempts (\(maxRetryAttempts))")
                failedWorkouts.removeValue(forKey: workoutKey)
                recordPermanentFailure(workout: workout, error: error)
                return
            }
            
            failedWorkouts[workoutKey] = FailedWorkoutSync(
                workout: workout,
                userId: userId,
                error: error,
                firstFailureTime: existingFailure.firstFailureTime,
                lastAttemptTime: now,
                attemptCount: newAttemptCount,
                source: source
            )
            
            print("⚠️ RetryManager: Workout \(workout.id) failed again (attempt \(newAttemptCount)/\(maxRetryAttempts))")
        } else {
            // New failure
            failedWorkouts[workoutKey] = FailedWorkoutSync(
                workout: workout,
                userId: userId,
                error: error,
                firstFailureTime: now,
                lastAttemptTime: now,
                attemptCount: 1,
                source: source
            )
            
            print("⚠️ RetryManager: New workout sync failure recorded: \(workout.id)")
        }
        
        // Schedule immediate retry for the first failure
        if failedWorkouts[workoutKey]?.attemptCount == 1 {
            scheduleRetryForWorkout(workoutKey, delay: baseDelay)
        }
    }
    
    /// Marks a workout sync as successful (removes from retry queue)
    func recordSuccessfulSync(workoutId: String) {
        if failedWorkouts.removeValue(forKey: workoutId) != nil {
            print("✅ RetryManager: Workout \(workoutId) sync succeeded - removed from retry queue")
        }
    }
    
    /// Gets current retry statistics
    func getRetryStatistics() -> RetryStatistics {
        let now = Date()
        let pending = failedWorkouts.values.filter { $0.shouldRetry(at: now) }.count
        let waiting = failedWorkouts.count - pending
        
        return RetryStatistics(
            totalFailed: failedWorkouts.count,
            pendingRetry: pending,
            waitingForRetry: waiting,
            oldestFailure: failedWorkouts.values.map(\.firstFailureTime).min()
        )
    }
    
    // MARK: - Private Methods
    
    private func scheduleRetryForWorkout(_ workoutKey: String, delay: TimeInterval) {
        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await processRetryForWorkout(workoutKey)
        }
    }
    
    private func processRetryForWorkout(_ workoutKey: String) async {
        guard let failedSync = failedWorkouts[workoutKey] else { return }
        
        let now = Date()
        guard failedSync.shouldRetry(at: now) else {
            print("⏰ RetryManager: Too soon to retry workout \(workoutKey)")
            return
        }
        
        print("🔄 RetryManager: Retrying workout \(workoutKey) (attempt \(failedSync.attemptCount + 1))")
        
        do {
            // Attempt to sync the workout again
            let supabaseWorkout = await HealthKitService.shared.convertToSupabaseWorkout(failedSync.workout, userId: failedSync.userId)
            
            // Use the same processing as immediate sync but without notifications to avoid duplicates
            try await WorkoutDataService.shared.processWorkoutForRewards(supabaseWorkout)
            
            // If successful, remove from retry queue
            recordSuccessfulSync(workoutId: workoutKey)
            
            print("✅ RetryManager: Workout \(workoutKey) retry succeeded!")
            
        } catch {
            print("❌ RetryManager: Workout \(workoutKey) retry failed: \(error)")
            
            // Record this failure for another retry
            recordFailedSync(
                workout: failedSync.workout,
                userId: failedSync.userId,
                error: error,
                source: "Retry-\(failedSync.source)"
            )
        }
    }
    
    private func schedulePeriodicRetries() {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.processAllPendingRetries()
            }
        }
    }
    
    private func processAllPendingRetries() async {
        let now = Date()
        let readyForRetry = failedWorkouts.filter { _, failedSync in
            failedSync.shouldRetry(at: now)
        }
        
        if !readyForRetry.isEmpty {
            print("🔄 RetryManager: Processing \(readyForRetry.count) pending retries")
            
            for (workoutKey, _) in readyForRetry {
                await processRetryForWorkout(workoutKey)
            }
        }
    }
    
    private func recordPermanentFailure(workout: HealthKitWorkout, error: Error) {
        // Log permanent failure for monitoring
        print("🚨 RetryManager: PERMANENT FAILURE for workout \(workout.id): \(error)")
        
        // Could send this to analytics or error reporting service
        // For now, just log it
    }
}

// MARK: - Supporting Models

struct FailedWorkoutSync {
    let workout: HealthKitWorkout
    let userId: String
    let error: Error
    let firstFailureTime: Date
    let lastAttemptTime: Date
    let attemptCount: Int
    let source: String
    
    func shouldRetry(at date: Date) -> Bool {
        let timeSinceLastAttempt = date.timeIntervalSince(lastAttemptTime)
        let requiredDelay = calculateBackoffDelay()
        return timeSinceLastAttempt >= requiredDelay
    }
    
    private func calculateBackoffDelay() -> TimeInterval {
        // Exponential backoff: 2^attempt * base delay, capped at max delay
        let exponentialDelay = pow(2.0, Double(attemptCount - 1)) * 2.0
        return min(exponentialDelay, 60.0) // Cap at 1 minute
    }
}

struct RetryStatistics {
    let totalFailed: Int
    let pendingRetry: Int
    let waitingForRetry: Int
    let oldestFailure: Date?
    
    var statusDescription: String {
        if totalFailed == 0 {
            return "No failed workouts"
        } else {
            return "\(totalFailed) failed (\(pendingRetry) ready to retry, \(waitingForRetry) waiting)"
        }
    }
}