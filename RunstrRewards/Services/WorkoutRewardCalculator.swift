import Foundation

struct WorkoutReward {
    let satsAmount: Int
    let usdAmount: Double
    let reason: String
}

// DEPRECATED: Individual workout rewards removed - rewards now come from team prize pools only
class WorkoutRewardCalculator {
    static let shared = WorkoutRewardCalculator()
    
    private init() {}
    
    // MARK: - Reward Calculation
    
    func calculateReward(for workout: HealthKitWorkout) -> WorkoutReward {
        // DEPRECATED: Individual workout rewards removed
        print("⚠️ DEPRECATED: calculateReward called - individual workout rewards no longer supported")
        
        return WorkoutReward(
            satsAmount: 0,
            usdAmount: 0.0,
            reason: "Individual workout rewards deprecated - rewards come from team prize pools"
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
    
    // MARK: - Team Multiplier Calculation
    
    func calculateRewardWithTeamBonus(for workout: HealthKitWorkout, userId: String) async -> WorkoutReward {
        // Calculate base reward
        let baseReward = calculateReward(for: workout)
        
        // Check if user is member of active teams
        let teamMultiplier = await getTeamMultiplier(userId: userId)
        
        if teamMultiplier > 1.0 {
            let bonusSats = Int(Double(baseReward.satsAmount) * (teamMultiplier - 1.0))
            let bonusUSD = Double(bonusSats) * 0.0005
            
            return WorkoutReward(
                satsAmount: baseReward.satsAmount + bonusSats,
                usdAmount: baseReward.usdAmount + bonusUSD,
                reason: "\(baseReward.reason) + \(Int((teamMultiplier - 1.0) * 100))% team bonus"
            )
        }
        
        return baseReward
    }
    
    private func getTeamMultiplier(userId: String) async -> Double {
        do {
            // Check if user is part of active teams
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: userId)
            
            if !teams.isEmpty {
                // Team members get 25% bonus
                return 1.25
            }
        } catch {
            print("WorkoutRewardCalculator: Error checking team membership: \(error)")
        }
        
        return 1.0 // No team bonus
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