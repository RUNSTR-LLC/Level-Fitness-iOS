import Foundation
import HealthKit

actor HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    private let syncQueue = DispatchQueue(label: "com.runstrrewards.healthkit", attributes: .concurrent)
    
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataNotAvailable
        }
        
        let workoutType = HKObjectType.workoutType()
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let distanceWalkingRunningType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceCyclingType = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        let typesToRead: Set<HKObjectType> = [
            workoutType,
            heartRateType,
            activeEnergyType,
            distanceWalkingRunningType,
            distanceCyclingType,
            stepCountType
        ]
        
        let typesToWrite: Set<HKSampleType> = [workoutType]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self.isAuthorized = success
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func checkAuthorizationStatus() -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        return status == .sharingAuthorized
    }
    
    // MARK: - Error Handling Helpers
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw HealthKitError.queryTimeout
            }
            
            // Return the first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll() // Cancel the other task
            return result
        }
    }
    
    // MARK: - Workout Data Fetching
    
    func fetchRecentWorkouts(limit: Int = 50) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        // Validate limit with safety bounds
        let safeLimit = min(max(limit, 1), 100) // Limit between 1 and 100
        
        // Add timeout protection for HealthKit queries
        return try await withTimeout(seconds: 30) {
            try await self.performHealthKitQuery(limit: safeLimit)
        }
    }
    
    private func performHealthKitQuery(limit: Int) async throws -> [HealthKitWorkout] {
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let healthKitWorkouts = workouts.map { workout in
                    HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        activityType: workout.workoutActivityType,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()),
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        syncSource: .healthKit,
                        metadata: workout.metadata
                    )
                }
                
                continuation.resume(returning: healthKitWorkouts)
            }
            
            healthStore.execute(workoutQuery)
        }
    }
    
    func fetchWorkoutsSince(_ date: Date, limit: Int = 100) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let healthKitWorkouts = workouts.map { workout in
                    HealthKitWorkout(
                        id: workout.uuid.uuidString,
                        activityType: workout.workoutActivityType,
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()),
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
                        syncSource: .healthKit,
                        metadata: workout.metadata
                    )
                }
                
                continuation.resume(returning: healthKitWorkouts)
            }
            
            healthStore.execute(workoutQuery)
        }
    }
    
    func fetchHeartRateData(for workout: HealthKitWorkout) async throws -> [HeartRateData] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let heartRateQuery = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let heartRateSamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let heartRateData = heartRateSamples.map { sample in
                    HeartRateData(
                        timestamp: sample.startDate,
                        beatsPerMinute: Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                    )
                }
                
                continuation.resume(returning: heartRateData)
            }
            
            healthStore.execute(heartRateQuery)
        }
    }
    
    // MARK: - Background Sync (Delegated)
    
    func enableBackgroundDelivery() async throws {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        try await HealthKitBackgroundService.shared.enableBackgroundDelivery()
    }
    
    func observeWorkouts(handler: @escaping ([HealthKitWorkout]) -> Void) {
        Task {
            await HealthKitBackgroundService.shared.observeWorkouts(handler: handler)
        }
    }
    
    func forceWorkoutCheck(handler: @escaping ([HealthKitWorkout]) -> Void) async {
        await HealthKitBackgroundService.shared.forceWorkoutCheck(handler: handler)
    }
    
    func stopAllQueries() {
        Task {
            await HealthKitBackgroundService.shared.stopAllQueries()
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapWorkoutType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "running"
        case .walking:
            return "walking"
        case .cycling:
            return "cycling"
        case .swimming:
            return "swimming"
        case .tennis:
            return "tennis"
        case .basketball:
            return "basketball"
        case .soccer:
            return "soccer"
        case .baseball:
            return "baseball"
        case .americanFootball:
            return "football"
        case .golf:
            return "golf"
        case .hiking:
            return "hiking"
        case .yoga:
            return "yoga"
        case .functionalStrengthTraining:
            return "strength_training"
        case .traditionalStrengthTraining:
            return "strength_training"
        case .coreTraining:
            return "core_training"
        case .flexibility:
            return "stretching"
        case .highIntensityIntervalTraining:
            return "hiit"
        case .dance:
            return "dance"
        case .boxing:
            return "boxing"
        case .martialArts:
            return "martial_arts"
        case .rowing:
            return "rowing"
        case .elliptical:
            return "elliptical"
        case .stairClimbing:
            return "stairs"
        case .other:
            return "other"
        default:
            return "other"
        }
    }
    
    // Convert HealthKitWorkout to Supabase Workout format
    func convertToSupabaseWorkout(_ healthKitWorkout: HealthKitWorkout, userId: String) -> Workout {
        return Workout(
            id: healthKitWorkout.id,
            userId: userId,
            type: healthKitWorkout.workoutType,
            duration: Int(healthKitWorkout.duration),
            distance: (healthKitWorkout.totalDistance ?? 0.0) > 0 ? healthKitWorkout.totalDistance : nil,
            calories: Int(healthKitWorkout.totalEnergyBurned ?? 0.0),
            heartRate: nil, // Will be calculated from heart rate data if needed
            source: "healthkit",
            startedAt: healthKitWorkout.startDate,
            endedAt: healthKitWorkout.endDate,
            syncedAt: Date()
        )
    }
    
    // MARK: - Enhanced Duplicate Detection
    
    func detectDuplicates(in workouts: [HealthKitWorkout]) -> [HealthKitWorkout] {
        // Use the centralized deduplication service
        return WorkoutDeduplicationService.shared.deduplicateWorkouts(workouts)
    }
    
    // MARK: - Cross-Platform Detection
    
    func detectCrossPlatformDuplicates(_ healthKitWorkouts: [HealthKitWorkout], _ existingWorkouts: [Workout]) -> [HealthKitWorkout] {
        // For now, just return HealthKit workouts as-is since WorkoutDeduplicationService
        // will handle cross-platform deduplication in a more comprehensive way
        print("HealthKitService: 🌐 Cross-platform deduplication handled by WorkoutDeduplicationService")
        return healthKitWorkouts
    }
}

