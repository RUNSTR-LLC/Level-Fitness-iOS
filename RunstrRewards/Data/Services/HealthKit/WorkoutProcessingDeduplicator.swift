import Foundation

/// Manages temporal deduplication of workouts to prevent processing the same workout multiple times
/// across different detection systems (ObserverQuery, AnchoredQuery, ActivityQuery) within a short time window
@MainActor
class WorkoutProcessingDeduplicator {
    static let shared = WorkoutProcessingDeduplicator()
    
    // Track recently processed workouts with their detection time
    private var recentlyProcessedWorkouts: [String: Date] = [:]
    
    // Cleanup interval (remove workouts older than this)
    private let maxAge: TimeInterval = 300 // 5 minutes
    
    // Debounce window (same workout from multiple sources within this time)
    private let debounceWindow: TimeInterval = 5 // 5 seconds
    
    private init() {
        // Schedule periodic cleanup
        schedulePeriodicCleanup()
    }
    
    // MARK: - Deduplication Logic
    
    /// Checks if workouts should be processed (filters out duplicates and recent ones)
    /// Returns only the workouts that haven't been processed recently
    func filterUniqueWorkouts(_ workouts: [HealthKitWorkout], source: String) -> [HealthKitWorkout] {
        cleanupOldEntries()
        
        let now = Date()
        var uniqueWorkouts: [HealthKitWorkout] = []
        
        for workout in workouts {
            let workoutKey = createWorkoutKey(workout)
            
            if let lastProcessedTime = recentlyProcessedWorkouts[workoutKey] {
                let timeSinceLastProcess = now.timeIntervalSince(lastProcessedTime)
                
                if timeSinceLastProcess < debounceWindow {
                    print("🚫 Deduplication [\(source)]: Skipping duplicate workout \(workout.id) (processed \(String(format: "%.1f", timeSinceLastProcess))s ago)")
                    continue
                } else {
                    print("⏰ Deduplication [\(source)]: Allowing workout \(workout.id) (last processed \(String(format: "%.1f", timeSinceLastProcess))s ago)")
                }
            } else {
                print("✅ Deduplication [\(source)]: New workout \(workout.id)")
            }
            
            // Mark as processed and add to unique list
            recentlyProcessedWorkouts[workoutKey] = now
            uniqueWorkouts.append(workout)
        }
        
        print("📋 Deduplication [\(source)]: \(workouts.count) input → \(uniqueWorkouts.count) unique workouts")
        return uniqueWorkouts
    }
    
    /// Marks a workout as processed manually (useful for external processing)
    func markWorkoutAsProcessed(_ workout: HealthKitWorkout) {
        let workoutKey = createWorkoutKey(workout)
        recentlyProcessedWorkouts[workoutKey] = Date()
        print("✅ Deduplication: Manually marked workout \(workout.id) as processed")
    }
    
    // MARK: - Helper Methods
    
    private func createWorkoutKey(_ workout: HealthKitWorkout) -> String {
        // Create a unique key based on workout characteristics
        // Use ID first, but fallback to workout signature for cross-platform detection
        let timeKey = String(Int(workout.startDate.timeIntervalSince1970))
        let durationKey = String(Int(workout.duration))
        let distanceKey = workout.totalDistance.map { String(Int($0)) } ?? "0"
        
        // Primary key is the workout ID (most reliable)
        let primaryKey = workout.id
        
        // Secondary key for cross-platform duplicate detection
        let signatureKey = "\(timeKey)_\(durationKey)_\(distanceKey)_\(workout.workoutType)"
        
        return "\(primaryKey)|\(signatureKey)"
    }
    
    private func cleanupOldEntries() {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-maxAge)
        
        let originalCount = recentlyProcessedWorkouts.count
        recentlyProcessedWorkouts = recentlyProcessedWorkouts.filter { _, processedTime in
            processedTime > cutoffTime
        }
        
        let cleanedCount = originalCount - recentlyProcessedWorkouts.count
        if cleanedCount > 0 {
            print("🧹 Deduplication: Cleaned up \(cleanedCount) old entries")
        }
    }
    
    private func schedulePeriodicCleanup() {
        // Clean up old entries every 2 minutes
        Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldEntries()
            }
        }
    }
    
    // MARK: - Debug & Monitoring
    
    func getStatus() -> DeduplicationStatus {
        cleanupOldEntries()
        return DeduplicationStatus(
            trackedWorkouts: recentlyProcessedWorkouts.count,
            oldestEntry: recentlyProcessedWorkouts.values.min(),
            newestEntry: recentlyProcessedWorkouts.values.max()
        )
    }
    
    func reset() {
        recentlyProcessedWorkouts.removeAll()
        print("🔄 Deduplication: Reset all tracked workouts")
    }
}

// MARK: - Status Model

struct DeduplicationStatus {
    let trackedWorkouts: Int
    let oldestEntry: Date?
    let newestEntry: Date?
    
    var statusDescription: String {
        if trackedWorkouts == 0 {
            return "No workouts currently tracked"
        } else {
            let oldestText = oldestEntry?.formatted(.relative(presentation: .numeric)) ?? "unknown"
            return "\(trackedWorkouts) workouts tracked (oldest: \(oldestText))"
        }
    }
}