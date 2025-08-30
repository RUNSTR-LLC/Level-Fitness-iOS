import Foundation
import HealthKit

class WorkoutDeduplicationService {
    static let shared = WorkoutDeduplicationService()
    
    private init() {}
    
    // MARK: - Deduplication
    
    func deduplicateWorkouts(_ workouts: [HealthKitWorkout]) -> [HealthKitWorkout] {
        var deduplicatedWorkouts: [HealthKitWorkout] = []
        var processedFingerprints: [WorkoutFingerprint] = []
        
        // Sort by sync source priority (highest first) and then by start date (most recent first)
        let sortedWorkouts = workouts.sorted { workout1, workout2 in
            if workout1.syncSource.priority != workout2.syncSource.priority {
                return workout1.syncSource.priority > workout2.syncSource.priority
            }
            return workout1.startDate > workout2.startDate
        }
        
        for workout in sortedWorkouts {
            let fingerprint = createWorkoutFingerprint(workout)
            
            if let duplicateIndex = findDuplicateIndex(fingerprint, in: processedFingerprints) {
                let existingFingerprint = processedFingerprints[duplicateIndex]
                
                print("WorkoutDeduplicationService: Found duplicate workout")
                print("  New: \(workout.syncSource.displayName) - \(workout.activityType.displayName)")
                print("  Existing: \(existingFingerprint.syncSource.displayName) - \(existingFingerprint.activityType)")
                
                // Check if new workout should replace existing one
                if shouldReplaceExisting(newFingerprint: fingerprint, existingFingerprint: existingFingerprint) {
                    // Replace existing workout
                    processedFingerprints[duplicateIndex] = fingerprint
                    
                    if let workoutIndex = deduplicatedWorkouts.firstIndex(where: { $0.id == existingFingerprint.workoutId }) {
                        deduplicatedWorkouts[workoutIndex] = workout
                        print("  → Replaced with higher priority source")
                    }
                } else {
                    print("  → Kept existing workout with higher/equal priority")
                }
                
            } else {
                // No duplicate found, add workout
                processedFingerprints.append(fingerprint)
                deduplicatedWorkouts.append(workout)
            }
        }
        
        let removedCount = workouts.count - deduplicatedWorkouts.count
        if removedCount > 0 {
            print("WorkoutDeduplicationService: Removed \(removedCount) duplicate workouts from \(workouts.count) total")
        }
        
        return deduplicatedWorkouts
    }
    
    // MARK: - Cross-Source Deduplication
    
    func deduplicateAcrossSources(healthKit: [HealthKitWorkout], 
                                 nostr: [HealthKitWorkout], 
                                 garmin: [HealthKitWorkout] = [],
                                 googleFit: [HealthKitWorkout] = []) -> [HealthKitWorkout] {
        
        // Combine all workouts with their source information preserved
        var allWorkouts: [HealthKitWorkout] = []
        allWorkouts.append(contentsOf: healthKit)
        allWorkouts.append(contentsOf: nostr)
        allWorkouts.append(contentsOf: garmin)
        allWorkouts.append(contentsOf: googleFit)
        
        print("WorkoutDeduplicationService: Deduplicating across sources:")
        print("  HealthKit: \(healthKit.count)")
        print("  Nostr: \(nostr.count)")
        print("  Garmin: \(garmin.count)")
        print("  Google Fit: \(googleFit.count)")
        print("  Total: \(allWorkouts.count)")
        
        return deduplicateWorkouts(allWorkouts)
    }
    
    // MARK: - Fingerprint Creation
    
    private func createWorkoutFingerprint(_ workout: HealthKitWorkout) -> WorkoutFingerprint {
        return WorkoutFingerprint(
            workoutId: workout.id,
            syncSource: workout.syncSource,
            activityType: workout.activityType.displayName,
            startDate: workout.startDate,
            duration: workout.duration,
            distance: workout.totalDistance ?? 0.0,
            calories: workout.totalEnergyBurned ?? 0.0,
            fingerprint: generateWorkoutFingerprint(workout)
        )
    }
    
    private func generateWorkoutFingerprint(_ workout: HealthKitWorkout) -> String {
        // Round values to create fuzzy matching for slight variations
        let startTimestamp = Int(workout.startDate.timeIntervalSince1970 / 60) * 60 // Round to nearest minute
        let duration = Int(workout.duration / 60) * 60 // Round to nearest minute
        let distance = Int((workout.totalDistance ?? 0) / 100) * 100 // Round to nearest 100m
        let calories = Int((workout.totalEnergyBurned ?? 0) / 10) * 10 // Round to nearest 10 calories
        
        return "\(workout.activityType.displayName.lowercased())_\(startTimestamp)_\(duration)_\(distance)_\(calories)"
    }
    
    // MARK: - Duplicate Detection
    
    private func findDuplicateIndex(_ fingerprint: WorkoutFingerprint, in existing: [WorkoutFingerprint]) -> Int? {
        for (index, existingFingerprint) in existing.enumerated() {
            if isDuplicate(fingerprint, existingFingerprint) {
                return index
            }
        }
        return nil
    }
    
    private func isDuplicate(_ workout1: WorkoutFingerprint, _ workout2: WorkoutFingerprint) -> Bool {
        // Quick exact fingerprint match
        if workout1.fingerprint == workout2.fingerprint {
            return true
        }
        
        // More detailed similarity check
        return isSimilarWorkout(workout1, workout2)
    }
    
    private func isSimilarWorkout(_ workout1: WorkoutFingerprint, _ workout2: WorkoutFingerprint) -> Bool {
        // Must be same activity type
        guard workout1.activityType.lowercased() == workout2.activityType.lowercased() else {
            return false
        }
        
        // Time window check (within 5 minutes)
        let timeDifference = abs(workout1.startDate.timeIntervalSince(workout2.startDate))
        guard timeDifference <= 300 else { // 5 minutes
            return false
        }
        
        // Duration similarity (within 2 minutes or 10%)
        let durationDifference = abs(workout1.duration - workout2.duration)
        let durationTolerance = max(120, min(workout1.duration, workout2.duration) * 0.1) // 2 minutes or 10%
        guard durationDifference <= durationTolerance else {
            return false
        }
        
        // Distance similarity (within 100m or 5% for longer distances)
        if workout1.distance > 0 && workout2.distance > 0 {
            let distanceDifference = abs(workout1.distance - workout2.distance)
            let distanceTolerance = max(100, min(workout1.distance, workout2.distance) * 0.05) // 100m or 5%
            guard distanceDifference <= distanceTolerance else {
                return false
            }
        }
        
        // Calorie similarity (within 50 calories or 15%)
        if workout1.calories > 0 && workout2.calories > 0 {
            let calorieDifference = abs(workout1.calories - workout2.calories)
            let calorieTolerance = max(50, min(workout1.calories, workout2.calories) * 0.15) // 50 calories or 15%
            guard calorieDifference <= calorieTolerance else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Priority Resolution
    
    private func shouldReplaceExisting(newFingerprint: WorkoutFingerprint, existingFingerprint: WorkoutFingerprint) -> Bool {
        // Higher priority source wins
        if newFingerprint.syncSource.priority > existingFingerprint.syncSource.priority {
            return true
        }
        
        // Lower priority never replaces higher priority
        if newFingerprint.syncSource.priority < existingFingerprint.syncSource.priority {
            return false
        }
        
        // Same priority - prefer more complete data
        let newCompleteness = calculateDataCompleteness(newFingerprint)
        let existingCompleteness = calculateDataCompleteness(existingFingerprint)
        
        if newCompleteness > existingCompleteness {
            return true
        }
        
        // If completeness is the same, prefer more recent workout
        if newCompleteness == existingCompleteness {
            return newFingerprint.startDate > existingFingerprint.startDate
        }
        
        return false
    }
    
    private func calculateDataCompleteness(_ fingerprint: WorkoutFingerprint) -> Int {
        var completeness = 0
        
        if fingerprint.duration > 0 { completeness += 1 }
        if fingerprint.distance > 0 { completeness += 1 }
        if fingerprint.calories > 0 { completeness += 1 }
        
        // Bonus for manual or watch-based sources
        let sourceName = fingerprint.syncSource.displayName.lowercased()
        if sourceName.contains("manual") || sourceName.contains("watch") {
            completeness += 1
        }
        
        return completeness
    }
    
    // MARK: - Statistics
    
    func generateDeduplicationReport(_ originalWorkouts: [HealthKitWorkout], _ deduplicatedWorkouts: [HealthKitWorkout]) -> DeduplicationReport {
        let totalRemoved = originalWorkouts.count - deduplicatedWorkouts.count
        
        var sourceStats: [WorkoutSyncSource: DeduplicationReport.SourceStats] = [:]
        
        for source in WorkoutSyncSource.allCases {
            let originalCount = originalWorkouts.filter { $0.syncSource == source }.count
            let finalCount = deduplicatedWorkouts.filter { $0.syncSource == source }.count
            let removedCount = originalCount - finalCount
            
            sourceStats[source] = DeduplicationReport.SourceStats(
                original: originalCount,
                final: finalCount,
                removed: removedCount
            )
        }
        
        return DeduplicationReport(
            totalOriginal: originalWorkouts.count,
            totalFinal: deduplicatedWorkouts.count,
            totalRemoved: totalRemoved,
            sourceStats: sourceStats
        )
    }
}

// MARK: - Data Models

struct WorkoutFingerprint {
    let workoutId: String
    let syncSource: WorkoutSyncSource
    let activityType: String
    let startDate: Date
    let duration: TimeInterval
    let distance: Double
    let calories: Double
    let fingerprint: String
}

struct DeduplicationReport {
    let totalOriginal: Int
    let totalFinal: Int
    let totalRemoved: Int
    let sourceStats: [WorkoutSyncSource: SourceStats]
    
    struct SourceStats {
        let original: Int
        let final: Int
        let removed: Int
    }
    
    func printReport() {
        print("=== Workout Deduplication Report ===")
        print("Total: \(totalOriginal) → \(totalFinal) (removed \(totalRemoved))")
        
        for (source, stats) in sourceStats {
            if stats.original > 0 {
                print("\(source.displayName): \(stats.original) → \(stats.final) (removed \(stats.removed))")
            }
        }
        print("=====================================")
    }
}