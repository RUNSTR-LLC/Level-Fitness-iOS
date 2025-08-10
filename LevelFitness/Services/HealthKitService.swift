import Foundation
import HealthKit

class HealthKitService {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    
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
    
    // MARK: - Workout Data Fetching
    
    func fetchRecentWorkouts(limit: Int = 50) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: nil,
            limit: limit,
            sortDescriptors: [sortDescriptor]
        ) { query, samples, error in
            // Handled in continuation below
        }
        
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
                        workoutType: self.mapWorkoutType(workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
                        source: workout.sourceRevision.source.name,
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
                        workoutType: self.mapWorkoutType(workout.workoutActivityType),
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        duration: workout.duration,
                        totalDistance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0.0,
                        totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0.0,
                        source: workout.sourceRevision.source.name,
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
    
    // MARK: - Background Sync
    
    func enableBackgroundDelivery() async throws {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    print("HealthKitService: Background delivery enabled")
                    continuation.resume()
                }
            }
        }
    }
    
    func observeWorkouts(handler: @escaping ([HealthKitWorkout]) -> Void) {
        let workoutType = HKObjectType.workoutType()
        
        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("HealthKitService: Observer query error: \(error)")
                completionHandler()
                return
            }
            
            Task {
                do {
                    let workouts = try await self?.fetchRecentWorkouts(limit: 10) ?? []
                    await MainActor.run {
                        handler(workouts)
                    }
                    completionHandler()
                } catch {
                    print("HealthKitService: Failed to fetch workouts in observer: \(error)")
                    completionHandler()
                }
            }
        }
        
        healthStore.execute(query)
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
            distance: healthKitWorkout.totalDistance > 0 ? healthKitWorkout.totalDistance : nil,
            calories: Int(healthKitWorkout.totalEnergyBurned),
            heartRate: nil, // Will be calculated from heart rate data if needed
            source: "healthkit",
            startedAt: healthKitWorkout.startDate,
            endedAt: healthKitWorkout.endDate,
            syncedAt: Date()
        )
    }
}

// MARK: - Data Models

struct HealthKitWorkout {
    let id: String
    let workoutType: String
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalDistance: Double // meters
    let totalEnergyBurned: Double // kcal
    let source: String
    let metadata: [String: Any]?
}

struct HeartRateData {
    let timestamp: Date
    let beatsPerMinute: Int
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case notAuthorized
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .notAuthorized:
            return "Health data access not authorized"
        case .queryFailed:
            return "Failed to query health data"
        }
    }
}