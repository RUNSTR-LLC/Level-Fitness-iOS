import Foundation
import HealthKit

class NostrWorkoutService {
    static let shared = NostrWorkoutService()
    
    private init() {}
    
    // MARK: - Workout Posting
    
    func postWorkoutToNostr(_ workout: HealthKitWorkout, completion: @escaping (Result<String, NostrWorkoutError>) -> Void) {
        // Check if user is authenticated with Nostr
        guard NostrAuthenticationService.shared.isNostrAuthenticated else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        // Get user's relay configuration
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            completion(.failure(.noCredentials))
            return
        }
        
        // Connect to relays if needed
        if !NostrRelayManager.shared.isConnectedToAnyRelay {
            NostrRelayManager.shared.connectToRelays(credentials.relays)
            
            // Wait a moment for connections to establish
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.publishWorkoutEvent(workout, completion: completion)
            }
        } else {
            publishWorkoutEvent(workout, completion: completion)
        }
    }
    
    private func publishWorkoutEvent(_ workout: HealthKitWorkout, completion: @escaping (Result<String, NostrWorkoutError>) -> Void) {
        // Format workout as Nostr note
        let workoutContent = formatWorkoutContent(workout)
        let hashtags = generateHashtags(for: workout)
        
        // Create Nostr event (kind 1 = text note)
        let event = NostrEvent(
            kind: 1,
            content: workoutContent,
            tags: hashtags.map { ["t", $0] }  // Tag format for hashtags
        )
        
        // Publish to relays
        NostrRelayManager.shared.publishEvent(event) { success, errors in
            DispatchQueue.main.async {
                if success {
                    print("NostrWorkoutService: Workout posted successfully")
                    completion(.success("Workout posted to Nostr successfully"))
                } else {
                    print("NostrWorkoutService: Failed to post workout: \(errors)")
                    completion(.failure(.publishFailed(errors.joined(separator: ", "))))
                }
            }
        }
    }
    
    // MARK: - Workout Formatting
    
    private func formatWorkoutContent(_ workout: HealthKitWorkout) -> String {
        let workoutType = formatWorkoutType(workout.activityType)
        let duration = formatDuration(workout.duration)
        let distance = formatDistance(workout.totalDistance)
        let calories = formatCalories(workout.totalEnergyBurned)
        let date = formatDate(workout.startDate)
        
        var content = "🏃‍♀️ Just completed a \(workoutType)!\n\n"
        
        // Add workout stats
        content += "📊 Workout Stats:\n"
        content += "⏱️ Duration: \(duration)\n"
        
        if !distance.isEmpty {
            content += "📏 Distance: \(distance)\n"
        }
        
        if !calories.isEmpty {
            content += "🔥 Calories: \(calories)\n"
        }
        
        content += "📅 Date: \(date)\n\n"
        
        // Add motivational message
        content += "Staying active and earning Bitcoin rewards! 💪₿\n\n"
        
        // Add Level Fitness branding
        content += "Tracked with @LevelFitness - Earn Bitcoin for staying fit! 🚀"
        
        return content
    }
    
    private func formatWorkoutType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .running:
            return "run 🏃‍♀️"
        case .walking:
            return "walk 🚶‍♀️"
        case .cycling:
            return "bike ride 🚴‍♀️"
        case .swimming:
            return "swim 🏊‍♀️"
        case .yoga:
            return "yoga session 🧘‍♀️"
        case .hiking:
            return "hike 🥾"
        case .functionalStrengthTraining:
            return "strength training 💪"
        case .crossTraining:
            return "cross training 🏋️‍♀️"
        case .elliptical:
            return "elliptical workout 🔄"
        case .rowing:
            return "rowing session 🚣‍♀️"
        case .kickboxing:
            return "kickboxing session 🥊"
        case .tennis:
            return "tennis match 🎾"
        case .golf:
            return "golf round ⛳"
        case .basketball:
            return "basketball game 🏀"
        case .soccer:
            return "soccer match ⚽"
        case .baseball:
            return "baseball game ⚾"
        case .americanFootball:
            return "football game 🏈"
        case .dance:
            return "dance session 💃"
        default:
            return "workout 💪"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm %02ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    private func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance, distance > 0 else { return "" }
        
        // Convert from meters to kilometers/miles based on locale
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 2
        
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        
        // Use kilometers for most locales, miles for US
        let locale = Locale.current
        if #available(iOS 16.0, *) {
            if locale.measurementSystem == .us {
                return formatter.string(from: measurement.converted(to: .miles))
            } else {
                return formatter.string(from: measurement.converted(to: .kilometers))
            }
        } else {
            // Fallback for iOS 15: Use region code
            if locale.regionCode == "US" {
                return formatter.string(from: measurement.converted(to: .miles))
            } else {
                return formatter.string(from: measurement.converted(to: .kilometers))
            }
        }
    }
    
    private func formatCalories(_ calories: Double?) -> String {
        guard let calories = calories, calories > 0 else { return "" }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        
        if let formattedCalories = formatter.string(from: NSNumber(value: calories)) {
            return "\(formattedCalories) cal"
        }
        
        return "\(Int(calories)) cal"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func generateHashtags(for workout: HealthKitWorkout) -> [String] {
        var hashtags: [String] = [
            "fitness",
            "workout",
            "bitcoin",
            "earnbtc",
            "levelfitness",
            "healthkit",
            "nostr"
        ]
        
        // Add activity-specific hashtags
        switch workout.activityType {
        case .running:
            hashtags.append(contentsOf: ["running", "cardio", "endurance"])
        case .walking:
            hashtags.append(contentsOf: ["walking", "steps", "cardio"])
        case .cycling:
            hashtags.append(contentsOf: ["cycling", "biking", "cardio"])
        case .swimming:
            hashtags.append(contentsOf: ["swimming", "pool", "cardio"])
        case .yoga:
            hashtags.append(contentsOf: ["yoga", "flexibility", "mindfulness"])
        case .hiking:
            hashtags.append(contentsOf: ["hiking", "nature", "outdoors"])
        case .functionalStrengthTraining:
            hashtags.append(contentsOf: ["strength", "weightlifting", "muscle"])
        case .crossTraining:
            hashtags.append(contentsOf: ["crosstraining", "hiit", "conditioning"])
        case .dance:
            hashtags.append(contentsOf: ["dance", "cardio", "fun"])
        default:
            hashtags.append("exercise")
        }
        
        // Add distance-based hashtags
        if let distance = workout.totalDistance, distance > 0 {
            let km = distance / 1000
            if km >= 21.1 {
                hashtags.append("halfmarathon")
            } else if km >= 42.2 {
                hashtags.append("marathon")
            } else if km >= 10 {
                hashtags.append("10k")
            } else if km >= 5 {
                hashtags.append("5k")
            }
        }
        
        // Add duration-based hashtags
        let durationMinutes = workout.duration / 60
        if durationMinutes >= 60 {
            hashtags.append("longworkout")
        } else if durationMinutes >= 30 {
            hashtags.append("cardio")
        }
        
        return hashtags
    }
    
    // MARK: - Batch Operations
    
    func postMultipleWorkouts(_ workouts: [HealthKitWorkout], completion: @escaping (Result<Int, NostrWorkoutError>) -> Void) {
        guard !workouts.isEmpty else {
            completion(.success(0))
            return
        }
        
        var successCount = 0
        var errorCount = 0
        let group = DispatchGroup()
        
        for workout in workouts {
            group.enter()
            
            postWorkoutToNostr(workout) { result in
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    errorCount += 1
                }
                group.leave()
            }
            
            // Add delay between posts to avoid overwhelming relays
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        group.notify(queue: .main) {
            if successCount > 0 {
                completion(.success(successCount))
            } else {
                completion(.failure(.batchPostFailed("\(errorCount) workouts failed to post")))
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func canPostToNostr() -> Bool {
        return NostrAuthenticationService.shared.isNostrAuthenticated
    }
    
    func getRelayStatus() -> [String: Bool] {
        return NostrRelayManager.shared.connectionStatus
    }
    
    func reconnectToRelays() {
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else { return }
        NostrRelayManager.shared.connectToRelays(credentials.relays)
    }
}

// MARK: - Nostr Workout Errors

enum NostrWorkoutError: LocalizedError {
    case notAuthenticated
    case noCredentials
    case publishFailed(String)
    case batchPostFailed(String)
    case relayConnectionFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Nostr. Please sign in with your nsec."
        case .noCredentials:
            return "No Nostr credentials found."
        case .publishFailed(let details):
            return "Failed to publish workout to Nostr: \(details)"
        case .batchPostFailed(let details):
            return "Batch workout posting failed: \(details)"
        case .relayConnectionFailed:
            return "Failed to connect to Nostr relays."
        }
    }
}