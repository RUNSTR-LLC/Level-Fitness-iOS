import Foundation
import UserNotifications

class StreakTracker {
    static let shared = StreakTracker()
    
    private let supabaseService = SupabaseService.shared
    private let workoutRewardCalculator = WorkoutRewardCalculator.shared
    private let lightningWalletManager = LightningWalletManager.shared
    private let notificationService = NotificationService.shared
    
    private init() {}
    
    // MARK: - Streak Calculation
    
    func updateUserStreak(userId: String, workoutDate: Date) async -> StreakResult {
        print("StreakTracker: Updating streak for user \(userId)")
        
        do {
            // Get user's recent workouts to calculate streak
            let recentWorkouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 50)
            
            // Calculate current streak
            let streakData = calculateStreakFromWorkouts(recentWorkouts, newWorkoutDate: workoutDate, userId: userId)
            
            // Check if streak bonus should be awarded
            let bonusResult = shouldAwardStreakBonus(streakData)
            if let bonusResult = bonusResult {
                await awardStreakBonus(userId: userId, streakData: streakData, bonusResult: bonusResult)
            }
            
            // Store updated streak in database
            try await storeUserStreak(userId: userId, streakData: streakData)
            
            return StreakResult(
                currentStreak: streakData.consecutiveDays,
                longestStreak: streakData.longestStreak,
                bonusAwarded: bonusResult != nil,
                bonusAmount: bonusResult?.satsAmount ?? 0
            )
            
        } catch {
            print("StreakTracker: Error updating streak: \(error)")
            return StreakResult(currentStreak: 1, longestStreak: 1, bonusAwarded: false, bonusAmount: 0)
        }
    }
    
    private func calculateStreakFromWorkouts(_ workouts: [Workout], newWorkoutDate: Date, userId: String) -> UserStreakData {
        // Sort workouts by date (newest first)
        let sortedWorkouts = workouts.sorted(by: { $0.startedAt > $1.startedAt })
        
        // Group workouts by date
        var workoutDates: Set<String> = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Add today's workout
        workoutDates.insert(dateFormatter.string(from: newWorkoutDate))
        
        // Add existing workout dates
        for workout in sortedWorkouts {
            workoutDates.insert(dateFormatter.string(from: workout.startedAt))
        }
        
        // Calculate consecutive days using Calendar for timezone safety
        var consecutiveDays = 0
        var currentDate = newWorkoutDate
        
        while workoutDates.contains(dateFormatter.string(from: currentDate)) {
            consecutiveDays += 1
            // Use Calendar.date(byAdding:) to handle DST transitions correctly
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }
        
        // Calculate longest streak from all workouts
        let longestStreak = calculateLongestStreakFromWorkouts(sortedWorkouts)
        
        return UserStreakData(
            userId: userId,
            consecutiveDays: consecutiveDays,
            longestStreak: max(longestStreak, consecutiveDays),
            lastWorkoutDate: newWorkoutDate
        )
    }
    
    private func calculateLongestStreakFromWorkouts(_ workouts: [Workout]) -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Get unique workout dates
        let workoutDates = Set(workouts.map { dateFormatter.string(from: $0.startedAt) })
        let sortedDates = workoutDates.sorted().compactMap { dateFormatter.date(from: $0) }
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let previousDate = sortedDates[i-1]
            let currentDate = sortedDates[i]
            
            // Check if dates are consecutive
            if calendar.isDate(currentDate, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: previousDate) ?? Date()) {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    private func shouldAwardStreakBonus(_ streakData: UserStreakData) -> WorkoutReward? {
        // Check if user has reached a streak milestone
        let milestones = [3, 7, 14, 30, 60, 100]
        
        if milestones.contains(streakData.consecutiveDays) {
            return workoutRewardCalculator.calculateStreakBonus(consecutiveDays: streakData.consecutiveDays)
        }
        
        return nil
    }
    
    private func awardStreakBonus(userId: String, streakData: UserStreakData, bonusResult: WorkoutReward) async {
        print("StreakTracker: Awarding streak bonus - \(streakData.consecutiveDays) day streak: \(bonusResult.satsAmount) sats")
        
        do {
            // Distribute streak bonus via Lightning Network
            try await lightningWalletManager.distributeWorkoutReward(
                userId: userId,
                workoutType: "Streak Bonus",
                points: bonusResult.satsAmount / 10 // Convert sats to points for API
            )
            
            // Send streak milestone notification
            await MainActor.run {
                let content = UNMutableNotificationContent()
                content.title = "🔥 Streak Milestone Reached!"
                content.body = "\(streakData.consecutiveDays) day streak! You earned \(bonusResult.satsAmount) bonus sats!"
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "STREAK_BONUS"
                content.userInfo = [
                    "type": "streak_bonus",
                    "streak_days": streakData.consecutiveDays,
                    "bonus_sats": bonusResult.satsAmount
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "streak_bonus_\(streakData.consecutiveDays)_\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
                // Check notification permissions before scheduling
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    if settings.authorizationStatus == .authorized {
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("StreakTracker: Failed to schedule streak bonus notification: \(error)")
                            } else {
                                print("StreakTracker: ✅ Streak bonus notification scheduled")
                            }
                        }
                    } else {
                        print("StreakTracker: ⚠️ Notification permissions not granted, skipping notification")
                    }
                }
            }
            
        } catch {
            print("StreakTracker: Failed to award streak bonus: \(error)")
        }
    }
    
    private func storeUserStreak(userId: String, streakData: UserStreakData) async throws {
        // Store streak data in database for persistence and analytics
        print("StreakTracker: Storing streak data for user \(userId): \(streakData.consecutiveDays) days")
        
        // For now, store in UserDefaults as fallback
        // TODO: Implement Supabase streak storage
        let streakKey = "user_streak_\(userId)"
        if let data = try? JSONEncoder().encode(streakData) {
            UserDefaults.standard.set(data, forKey: streakKey)
        }
    }
    
    // MARK: - Public Interface
    
    func getCurrentStreak(userId: String) async -> Int {
        do {
            let recentWorkouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 30)
            let streakData = calculateStreakFromWorkouts(recentWorkouts, newWorkoutDate: Date(), userId: userId)
            return streakData.consecutiveDays
        } catch {
            print("StreakTracker: Error getting current streak: \(error)")
            return 0
        }
    }
    
    func getLongestStreak(userId: String) async -> Int {
        do {
            let allWorkouts = try await supabaseService.fetchWorkouts(userId: userId, limit: 365)
            return calculateLongestStreakFromWorkouts(allWorkouts)
        } catch {
            print("StreakTracker: Error getting longest streak: \(error)")
            return 0
        }
    }
}

// MARK: - Data Models

struct UserStreakData: Codable {
    let userId: String
    let consecutiveDays: Int
    let longestStreak: Int
    let lastWorkoutDate: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case consecutiveDays = "consecutive_days"
        case longestStreak = "longest_streak"
        case lastWorkoutDate = "last_workout_date"
    }
}

struct StreakResult {
    let currentStreak: Int
    let longestStreak: Int
    let bonusAwarded: Bool
    let bonusAmount: Int
}