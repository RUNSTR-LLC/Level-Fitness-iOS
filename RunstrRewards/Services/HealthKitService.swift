import Foundation
import HealthKit

class HealthKitService: @unchecked Sendable {
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
    
    // MARK: - Workout Data Fetching
    
    func fetchRecentWorkouts(limit: Int = 50) async throws -> [HealthKitWorkout] {
        guard isAuthorized || checkAuthorizationStatus() else {
            throw HealthKitError.notAuthorized
        }
        
        // Validate limit
        let safeLimit = min(max(limit, 1), 100) // Limit between 1 and 100
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: safeLimit,
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
                print("❌ HealthKitService: Observer query error: \(error)")
                completionHandler()
                return
            }
            
            print("🔍 HealthKitService: New workout detected - fetching recent workouts")
            
            Task {
                do {
                    let workouts = try await self?.fetchRecentWorkouts(limit: 10) ?? []
                    print("📊 HealthKitService: Found \(workouts.count) recent workouts")
                    
                    // Filter for truly new workouts (within last hour)
                    let newWorkouts = workouts.filter { workout in
                        let oneHourAgo = Date().addingTimeInterval(-3600)
                        return workout.startDate >= oneHourAgo
                    }
                    
                    print("🆕 HealthKitService: \(newWorkouts.count) workouts are new (within last hour)")
                    
                    if !newWorkouts.isEmpty {
                        await MainActor.run {
                            handler(newWorkouts)
                            
                            // Post notification for each new workout to trigger event/leaderboard updates
                            for workout in newWorkouts {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("WorkoutAdded"),
                                    object: nil,
                                    userInfo: [
                                        "workout": workout,
                                        "userId": AuthenticationService.shared.currentUserId ?? ""
                                    ]
                                )
                            }
                            
                            print("🔔 HealthKitService: Posted WorkoutAdded notifications for \(newWorkouts.count) workouts")
                        }
                    }
                    
                    completionHandler()
                } catch {
                    print("❌ HealthKitService: Failed to fetch workouts in observer: \(error)")
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

// MARK: - Data Models

// MARK: - Workout Sync Source

enum WorkoutSyncSource: String, CaseIterable {
    case healthKit = "healthkit"
    case garmin = "garmin"
    case googleFit = "googlefit"
    case nostr = "nostr"
    
    var displayName: String {
        switch self {
        case .healthKit: return "HealthKit"
        case .garmin: return "Garmin"
        case .googleFit: return "Google Fit"
        case .nostr: return "Nostr"
        }
    }
    
    var priority: Int {
        switch self {
        case .healthKit: return 3  // Highest priority
        case .garmin: return 2
        case .nostr: return 1
        case .googleFit: return 0  // Lowest priority
        }
    }
}

struct HealthKitWorkout {
    let id: String
    let activityType: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let totalDistance: Double? // meters
    let totalEnergyBurned: Double? // kcal
    
    // Legacy support
    var workoutType: String {
        return activityType.displayName
    }
    
    var source: String {
        return syncSource.rawValue
    }
    
    // Sync source information
    let syncSource: WorkoutSyncSource
    let metadata: [String: Any]?
    
    // Nostr-specific properties
    let nostrEventId: String?
    let nostrPubkey: String?
    let rawNostrContent: [String: Any]?
    
    init(id: String,
         activityType: HKWorkoutActivityType,
         startDate: Date,
         endDate: Date,
         duration: TimeInterval,
         totalDistance: Double? = nil,
         totalEnergyBurned: Double? = nil,
         syncSource: WorkoutSyncSource = .healthKit,
         metadata: [String: Any]? = nil,
         nostrEventId: String? = nil,
         nostrPubkey: String? = nil,
         rawNostrContent: [String: Any]? = nil) {
        
        self.id = id
        self.activityType = activityType
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.totalDistance = totalDistance
        self.totalEnergyBurned = totalEnergyBurned
        self.syncSource = syncSource
        self.metadata = metadata
        self.nostrEventId = nostrEventId
        self.nostrPubkey = nostrPubkey
        self.rawNostrContent = rawNostrContent
    }
}

struct HeartRateData {
    let timestamp: Date
    let beatsPerMinute: Int
}


// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        case .cycling:
            return "Cycling"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .yoga:
            return "Yoga"
        case .functionalStrengthTraining:
            return "Strength Training"
        case .dance:
            return "Dance"
        case .tennis:
            return "Tennis"
        case .basketball:
            return "Basketball"
        case .soccer:
            return "Soccer"
        case .golf:
            return "Golf"
        case .rowing:
            return "Rowing"
        case .kickboxing:
            return "Kickboxing"
        case .crossTraining:
            return "Cross Training"
        case .elliptical:
            return "Elliptical"
        default:
            return "Other"
        }
    }
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