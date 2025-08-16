import Foundation

struct WorkoutReward {
    let satsAmount: Int
    let usdAmount: Double
    let reason: String
}

class WorkoutRewardCalculator {
    static let shared = WorkoutRewardCalculator()
    
    private init() {}
    
    // MARK: - Reward Calculation
    
    func calculateReward(for workout: HealthKitWorkout) -> WorkoutReward {
        var baseSats = 0
        var reason = ""
        
        // Base reward for completing any workout
        baseSats += 100 // 100 sats base reward
        reason = "Workout completion"
        
        // Distance bonus (10 sats per km for distance-based workouts)
        if workout.totalDistance > 0 {
            let distanceKm = workout.totalDistance / 1000.0
            let distanceBonus = Int(distanceKm * 10)
            baseSats += distanceBonus
            reason += " + distance (\(String(format: "%.1f", distanceKm))km)"
        }
        
        // Duration bonus (1 sat per minute over 10 minutes)
        let durationMinutes = workout.duration / 60.0
        if durationMinutes > 10 {
            let durationBonus = Int(durationMinutes - 10)
            baseSats += durationBonus
            reason += " + duration (\(Int(durationMinutes))min)"
        }
        
        // Calories bonus (1 sat per 10 calories burned)
        if workout.totalEnergyBurned > 0 {
            let caloriesBonus = Int(workout.totalEnergyBurned / 10)
            baseSats += caloriesBonus
            reason += " + calories (\(Int(workout.totalEnergyBurned))cal)"
        }
        
        // Workout type multiplier
        let typeMultiplier = getTypeMultiplier(for: workout.workoutType)
        baseSats = Int(Double(baseSats) * typeMultiplier)
        
        if typeMultiplier > 1.0 {
            reason += " × \(typeMultiplier) (\(workout.workoutType))"
        }
        
        // Convert sats to approximate USD (using rough conversion rate)
        // Note: In production, this would use real-time Bitcoin price
        let usdAmount = Double(baseSats) * 0.0005 // Rough estimate: 1 sat ≈ $0.0005
        
        return WorkoutReward(
            satsAmount: baseSats,
            usdAmount: usdAmount,
            reason: reason
        )
    }
    
    // MARK: - Helper Methods
    
    private func getTypeMultiplier(for workoutType: String) -> Double {
        switch workoutType.lowercased() {
        case "running":
            return 1.5 // Running gets 50% bonus
        case "cycling":
            return 1.3 // Cycling gets 30% bonus
        case "swimming":
            return 1.4 // Swimming gets 40% bonus
        case "hiit", "high_intensity_interval_training":
            return 1.6 // HIIT gets 60% bonus
        case "strength_training", "traditional_strength_training", "functional_strength_training":
            return 1.2 // Strength training gets 20% bonus
        case "walking":
            return 1.0 // Walking gets base reward
        case "yoga":
            return 1.1 // Yoga gets 10% bonus
        default:
            return 1.0 // Default base reward
        }
    }
    
    // MARK: - Batch Calculation
    
    func calculateTotalRewards(for workouts: [HealthKitWorkout]) -> WorkoutReward {
        let rewards = workouts.map { calculateReward(for: $0) }
        
        let totalSats = rewards.reduce(0) { $0 + $1.satsAmount }
        let totalUSD = rewards.reduce(0.0) { $0 + $1.usdAmount }
        
        let workoutCount = workouts.count
        let reason = "Total from \(workoutCount) workout\(workoutCount > 1 ? "s" : "")"
        
        return WorkoutReward(
            satsAmount: totalSats,
            usdAmount: totalUSD,
            reason: reason
        )
    }
    
    // MARK: - Streak Bonuses
    
    func calculateStreakBonus(consecutiveDays: Int) -> WorkoutReward {
        var bonusSats = 0
        var reason = "Streak bonus"
        
        switch consecutiveDays {
        case 3...6:
            bonusSats = 50
            reason = "3-day streak bonus"
        case 7...13:
            bonusSats = 150
            reason = "7-day streak bonus"
        case 14...29:
            bonusSats = 350
            reason = "14-day streak bonus"
        case 30...:
            bonusSats = 1000
            reason = "30+ day streak bonus"
        default:
            bonusSats = 0
            reason = "No streak bonus"
        }
        
        let usdAmount = Double(bonusSats) * 0.0005
        
        return WorkoutReward(
            satsAmount: bonusSats,
            usdAmount: usdAmount,
            reason: reason
        )
    }
}