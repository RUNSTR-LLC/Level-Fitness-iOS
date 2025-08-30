import Foundation

// MARK: - Service Dependencies
// This service references models from HealthKitModels, CompetitionDataService, TeamDataService

class WorkoutRewardCalculator {
    static let shared = WorkoutRewardCalculator()
    
    private init() {}
    
    // MARK: - Reward Calculation Types
    
    enum RewardType {
        case individual(multiplier: Double)
        case team(teamId: String, prizePool: Int)
        case event(eventId: String, placement: Int, totalParticipants: Int)
        case streak(streakDays: Int)
    }
    
    struct WorkoutReward {
        let workoutId: String
        let userId: String
        let teamId: String?
        let baseSats: Int
        let bonusSats: Int
        let totalSats: Int
        let rewardType: String
        let calculatedAt: Date
        let metadata: [String: Any]
    }
    
    // MARK: - Reward Calculation
    
    func calculateWorkoutReward(
        for workout: Workout,
        userId: String,
        teamId: String?,
        rewardType: RewardType
    ) async throws -> WorkoutReward {
        print("💰 WorkoutRewardCalculator: Calculating reward for workout \(workout.id)")
        
        let baseReward = calculateBaseReward(for: workout)
        let bonusReward = try await calculateBonusReward(
            for: workout,
            userId: userId,
            teamId: teamId,
            rewardType: rewardType
        )
        
        let totalSats = baseReward + bonusReward
        
        let reward = WorkoutReward(
            workoutId: workout.id,
            userId: userId,
            teamId: teamId,
            baseSats: baseReward,
            bonusSats: bonusReward,
            totalSats: totalSats,
            rewardType: rewardType.description,
            calculatedAt: Date(),
            metadata: createRewardMetadata(for: workout, rewardType: rewardType)
        )
        
        print("💰 WorkoutRewardCalculator: Calculated \(totalSats) sats for workout \(workout.id)")
        return reward
    }
    
    // MARK: - Base Reward Calculation
    
    private func calculateBaseReward(for workout: Workout) -> Int {
        // Base reward calculation based on workout metrics
        let durationMinutes = Double(workout.duration) / 60.0
        let baseSatsPerMinute = 1
        
        var baseSats = Int(durationMinutes * Double(baseSatsPerMinute))
        
        // Activity type multipliers
        switch workout.type.lowercased() {
        case "running", "cycling":
            baseSats = Int(Double(baseSats) * 1.5)
        case "strength_training", "functional_strength_training":
            baseSats = Int(Double(baseSats) * 1.3)
        case "walking":
            baseSats = Int(Double(baseSats) * 1.0)
        default:
            baseSats = Int(Double(baseSats) * 1.2)
        }
        
        // Intensity bonus based on heart rate if available
        if let avgHeartRate = workout.averageHeartRate, avgHeartRate > 0 {
            let intensityMultiplier = calculateIntensityMultiplier(heartRate: Double(avgHeartRate))
            baseSats = Int(Double(baseSats) * intensityMultiplier)
        }
        
        // Minimum reward
        return max(baseSats, 1)
    }
    
    private func calculateIntensityMultiplier(heartRate: Double) -> Double {
        // Simple intensity calculation - could be enhanced with age-based zones
        switch heartRate {
        case 150...:
            return 1.5  // High intensity
        case 120..<150:
            return 1.3  // Moderate intensity  
        case 100..<120:
            return 1.1  // Light intensity
        default:
            return 1.0  // Very light or not available
        }
    }
    
    // MARK: - Bonus Reward Calculation
    
    private func calculateBonusReward(
        for workout: Workout,
        userId: String,
        teamId: String?,
        rewardType: RewardType
    ) async throws -> Int {
        
        switch rewardType {
        case .individual(let multiplier):
            return Int(Double(calculateBaseReward(for: workout)) * (multiplier - 1.0))
            
        case .team(let teamId, let prizePool):
            return try await calculateTeamBonus(
                workout: workout,
                userId: userId,
                teamId: teamId,
                prizePool: prizePool
            )
            
        case .event(let eventId, let placement, let totalParticipants):
            return calculateEventBonus(
                workout: workout,
                eventId: eventId,
                placement: placement,
                totalParticipants: totalParticipants
            )
            
        case .streak(let streakDays):
            return calculateStreakBonus(workout: workout, streakDays: streakDays)
        }
    }
    
    private func calculateTeamBonus(
        workout: Workout,
        userId: String,
        teamId: String,
        prizePool: Int
    ) async throws -> Int {
        // Get team performance data to calculate proportional bonus
        // This would typically query team standings and member contributions
        
        // Simplified calculation - in production this would be more sophisticated
        let memberContributionWeight = 0.1 // User's contribution to team success
        return Int(Double(prizePool) * memberContributionWeight)
    }
    
    private func calculateEventBonus(
        workout: Workout,
        eventId: String,
        placement: Int,
        totalParticipants: Int
    ) -> Int {
        // Placement-based bonus calculation
        let percentile = Double(totalParticipants - placement + 1) / Double(totalParticipants)
        let maxBonus = 50 // Maximum bonus sats for first place
        
        return Int(Double(maxBonus) * percentile)
    }
    
    private func calculateStreakBonus(workout: Workout, streakDays: Int) -> Int {
        // Streak bonus - increases with consecutive days
        let baseStreakBonus = 2
        let maxStreakBonus = 20
        
        let bonus = min(baseStreakBonus * streakDays, maxStreakBonus)
        return bonus
    }
    
    // MARK: - Helper Methods
    
    private func createRewardMetadata(for workout: Workout, rewardType: RewardType) -> [String: Any] {
        var metadata: [String: Any] = [
            "workout_type": workout.type,
            "workout_duration": workout.duration,
            "calculation_version": "1.0"
        ]
        
        switch rewardType {
        case .individual(let multiplier):
            metadata["individual_multiplier"] = multiplier
        case .team(let teamId, let prizePool):
            metadata["team_id"] = teamId
            metadata["prize_pool"] = prizePool
        case .event(let eventId, let placement, let total):
            metadata["event_id"] = eventId
            metadata["placement"] = placement
            metadata["total_participants"] = total
        case .streak(let days):
            metadata["streak_days"] = days
        }
        
        return metadata
    }
    
    // MARK: - Validation
    
    func validateWorkoutForReward(_ workout: Workout) -> Bool {
        // Basic validation rules for reward eligibility
        
        // Minimum duration (5 minutes)
        guard workout.duration >= 300 else {
            print("⚠️ WorkoutRewardCalculator: Workout too short for reward: \(workout.duration)s")
            return false
        }
        
        // Must have valid calories or distance
        guard (workout.totalEnergyBurned ?? 0) > 0 || (workout.totalDistance ?? 0) > 0 else {
            print("⚠️ WorkoutRewardCalculator: Workout missing key metrics")
            return false
        }
        
        // Must be from today (within 24 hours)
        let dayAgo = Date().addingTimeInterval(-86400)
        guard workout.startDate >= dayAgo else {
            print("⚠️ WorkoutRewardCalculator: Workout too old for reward")
            return false
        }
        
        return true
    }
    
    // MARK: - Analytics
    
    func getRewardSummary(for userId: String, period: TimeInterval) async throws -> RewardSummary {
        // Calculate reward summary for analytics
        // This would typically query the database for recent rewards
        
        return RewardSummary(
            totalSats: 0,
            workoutCount: 0,
            avgRewardPerWorkout: 0,
            bestDay: Date(),
            streakDays: 0,
            period: period
        )
    }
}

// MARK: - Supporting Types

extension WorkoutRewardCalculator.RewardType {
    var description: String {
        switch self {
        case .individual:
            return "individual"
        case .team:
            return "team"
        case .event:
            return "event"
        case .streak:
            return "streak"
        }
    }
}

struct RewardSummary {
    let totalSats: Int
    let workoutCount: Int
    let avgRewardPerWorkout: Int
    let bestDay: Date
    let streakDays: Int
    let period: TimeInterval
}