import Foundation
import HealthKit

// MARK: - Workout Sync Source

public enum WorkoutSyncSource: String, CaseIterable {
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

// MARK: - Data Models

public struct HealthKitWorkout {
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

public struct HeartRateData {
    let timestamp: Date
    let beatsPerMinute: Int
}

// MARK: - Type Conversion Extensions

extension HealthKitWorkout {
    func toSupabaseWorkout(userId: String) -> Workout {
        return Workout(
            id: self.id,
            userId: userId,
            type: self.activityType.displayName,
            duration: Int(self.duration),
            distance: self.totalDistance,
            calories: self.totalEnergyBurned.map { Int($0.rounded()) },
            heartRate: nil,
            source: self.syncSource.rawValue,
            startedAt: self.startDate,
            endedAt: self.endDate,
            syncedAt: Date()
        )
    }
}

extension Workout {
    func toHealthKitWorkout() -> HealthKitWorkout? {
        guard let activityType = HKWorkoutActivityType.from(displayName: self.type) else {
            return nil
        }
        
        return HealthKitWorkout(
            id: self.id,
            activityType: activityType,
            startDate: self.startedAt,
            endDate: self.endedAt ?? self.startedAt.addingTimeInterval(TimeInterval(self.duration)),
            duration: TimeInterval(self.duration),
            totalDistance: self.distance,
            totalEnergyBurned: self.calories.map(Double.init),
            syncSource: WorkoutSyncSource(rawValue: self.source) ?? .healthKit,
            metadata: nil,
            nostrEventId: nil,
            nostrPubkey: nil,
            rawNostrContent: nil
        )
    }
}

// MARK: - HKWorkoutActivityType Extension

extension HKWorkoutActivityType {
    static func from(displayName: String) -> HKWorkoutActivityType? {
        switch displayName {
        case "Running": return .running
        case "Walking": return .walking
        case "Cycling": return .cycling
        case "Swimming": return .swimming
        case "Yoga": return .yoga
        case "HIIT": return .highIntensityIntervalTraining
        case "Core Training": return .coreTraining
        case "Functional Strength": return .functionalStrengthTraining
        case "Strength Training": return .traditionalStrengthTraining
        default: return nil
        }
    }
    
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

public enum HealthKitError: LocalizedError {
    case healthDataNotAvailable
    case notAuthorized
    case queryFailed
    case queryTimeout
    
    public var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "Health data is not available on this device"
        case .notAuthorized:
            return "Health data access not authorized"
        case .queryFailed:
            return "Failed to query health data"
        case .queryTimeout:
            return "HealthKit query timed out - please try again"
        }
    }
}