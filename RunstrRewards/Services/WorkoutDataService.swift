import Foundation
import Supabase

// MARK: - Service Dependencies
// This service references models from SupabaseService, HealthKitService, WorkoutRewardCalculator, ErrorHandlingService

class WorkoutDataService {
    static let shared = WorkoutDataService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Workout Sync Operations
    
    func syncWorkout(_ workout: Workout) async throws {
        print("🔄 WorkoutDataService: Starting sync for workout \(workout.id) - \(workout.type)")
        
        // If offline, queue the workout sync
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            OfflineDataService.shared.queueWorkoutSync(workout)
            print("📴 WorkoutDataService: Queued workout sync (offline): \(workout.id)")
            return
        }
        
        do {
            // Check if workout already exists to avoid duplicates
            let existing = try await client
                .from("workouts")
                .select()
                .eq("id", value: workout.id)
                .execute()
            
            if existing.data.isEmpty {
                try await client
                    .from("workouts")
                    .insert(workout)
                    .execute()
                print("✅ WorkoutDataService: New workout synced: \(workout.id) - \(workout.type)")
            } else {
                // Update existing workout
                try await client
                    .from("workouts")
                    .update(workout)
                    .eq("id", value: workout.id)
                    .execute()
                print("🔄 WorkoutDataService: Existing workout updated: \(workout.id) - \(workout.type)")
            }
        } catch {
            ErrorHandlingService.shared.logError(error, context: "syncWorkout", userId: workout.userId)
            
            // Queue for retry if sync fails
            OfflineDataService.shared.queueWorkoutSync(workout)
            
            throw error
        }
    }
    
    func fetchWorkouts(userId: String, limit: Int = 20) async throws -> [Workout] {
        // Clean the user ID of any quotes that might have been passed incorrectly
        let cleanUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Try cached data first if offline
        let isConnected = NetworkMonitorService.shared.isCurrentlyConnected()
        if !isConnected {
            if let cached = OfflineDataService.shared.getCachedWorkouts() {
                print("WorkoutDataService: Using cached workouts (offline)")
                return Array(cached.prefix(limit))
            }
            throw AppError.networkUnavailable
        }
        
        do {
            let response = try await client
                .from("workouts")
                .select()
                .eq("user_id", value: cleanUserId)
                .order("started_at", ascending: false)
                .limit(limit)
                .execute()
            
            let data = response.data
            let workouts = try SupabaseService.shared.customJSONDecoder().decode([Workout].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheWorkouts(workouts)
            
            return workouts
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchWorkouts", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedWorkouts() {
                print("WorkoutDataService: Using cached workouts (error fallback)")
                return Array(cached.prefix(limit))
            }
            
            throw error
        }
    }
    
    // MARK: - Team Workout Operations
    
    func fetchTeamWorkouts(teamId: String, period: String = "weekly") async throws -> [Workout] {
        // Calculate date range based on period
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch period {
        case "daily":
            startDate = calendar.startOfDay(for: endDate)
        case "weekly":
            startDate = calendar.dateInterval(of: .weekOfYear, for: endDate)?.start ?? calendar.date(byAdding: .day, value: -7, to: endDate)!
        case "monthly":
            startDate = calendar.dateInterval(of: .month, for: endDate)?.start ?? calendar.date(byAdding: .month, value: -1, to: endDate)!
        default:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        }
        
        // Get team members first
        let memberResponse = try await client
            .from("team_members")
            .select("user_id")
            .eq("team_id", value: teamId)
            .execute()
        
        let memberData = memberResponse.data
        let members = try JSONDecoder().decode([TeamMemberUserIdLocal].self, from: memberData)
        let memberIds = members.map { $0.userId }
        
        if memberIds.isEmpty {
            return []
        }
        
        // Get workouts for all team members in the specified period
        let response = try await client
            .from("workouts")
            .select()
            .in("user_id", values: memberIds)
            .gte("started_at", value: ISO8601DateFormatter().string(from: startDate))
            .lte("started_at", value: ISO8601DateFormatter().string(from: endDate))
            .order("started_at", ascending: false)
            .execute()
        
        let workoutData = response.data
        let decoder = SupabaseService.shared.customJSONDecoder()
        return try decoder.decode([Workout].self, from: workoutData)
    }
    
    // MARK: - Workout Validation and Anti-Cheat
    
    func validateWorkoutData(_ workout: Workout) throws {
        // Basic validation rules
        guard workout.duration > 0 else {
            throw AppError.dataCorrupted
        }
        
        guard workout.duration < 86400 else { // 24 hours
            throw AppError.dataCorrupted
        }
        
        if let distance = workout.distance, distance < 0 {
            throw AppError.dataCorrupted
        }
        
        if let calories = workout.calories, calories < 0 {
            throw AppError.dataCorrupted
        }
        
        if let heartRate = workout.heartRate {
            guard heartRate >= 40 && heartRate <= 220 else {
                throw AppError.dataCorrupted
            }
        }
        
        // Validate workout type
        let validTypes = ["running", "walking", "cycling", "swimming", "strength", "yoga", "other"]
        guard validTypes.contains(workout.type.lowercased()) else {
            throw AppError.dataCorrupted
        }
        
        // Validate date ranges
        guard workout.startedAt <= Date() else {
            throw AppError.dataCorrupted
        }
        
        if let endDate = workout.endedAt {
            guard endDate >= workout.startedAt else {
                throw AppError.dataCorrupted
            }
        }
    }
    
    func detectDuplicateWorkouts(for userId: String, workout: Workout) async throws -> Bool {
        // Check for duplicate workouts within a 5-minute window
        let buffer: TimeInterval = 300 // 5 minutes
        let startRange = workout.startedAt.addingTimeInterval(-buffer)
        let endRange = workout.startedAt.addingTimeInterval(buffer)
        
        let response = try await client
            .from("workouts")
            .select("id, started_at, duration, type")
            .eq("user_id", value: userId)
            .gte("started_at", value: ISO8601DateFormatter().string(from: startRange))
            .lte("started_at", value: ISO8601DateFormatter().string(from: endRange))
            .neq("id", value: workout.id)
            .execute()
        
        let data = response.data
        let existingWorkouts = try SupabaseService.shared.customJSONDecoder().decode([Workout].self, from: data)
        
        // Check for similar workouts (same type, similar duration)
        for existing in existingWorkouts {
            if existing.type == workout.type {
                let durationDiff = abs(existing.duration - workout.duration)
                if durationDiff < 60 { // Within 1 minute duration difference
                    return true
                }
            }
        }
        
        return false
    }
    
    func handleAntiCheat(_ workout: Workout) async throws {
        // Validate the workout data first
        try validateWorkoutData(workout)
        
        // Check for duplicates
        let isDuplicate = try await detectDuplicateWorkouts(for: workout.userId, workout: workout)
        if isDuplicate {
            throw AppError.dataCorrupted
        }
        
        // Check for physiologically impossible performance
        if let distance = workout.distance, workout.duration > 0 {
            let speedKmh = (distance / 1000) / (Double(workout.duration) / 3600)
            
            switch workout.type.lowercased() {
            case "running":
                if speedKmh > 25 { // ~6 min mile pace is near world record
                    throw AppError.dataCorrupted
                }
            case "cycling":
                if speedKmh > 60 { // Professional cyclist speeds
                    throw AppError.dataCorrupted
                }
            case "walking":
                if speedKmh > 10 { // Very fast walking
                    throw AppError.dataCorrupted
                }
            default:
                break
            }
        }
        
        // Log potential suspicious activity for review
        if let distance = workout.distance, workout.duration > 0 {
            let speedKmh = (distance / 1000) / (Double(workout.duration) / 3600)
            if speedKmh > 20 { // Flag high-speed workouts for review
                print("🚨 WorkoutDataService: High-speed workout flagged for review: \(workout.id), speed: \(speedKmh) km/h")
            }
        }
    }
    
    // MARK: - Workout Processing and Rewards
    
    func processWorkoutForRewards(_ workout: Workout) async throws {
        // First run anti-cheat validation
        try await handleAntiCheat(workout)
        
        // Convert to HealthKitWorkout for reward calculation
        guard let healthKitWorkout = convertToHealthKitWorkout(workout) else {
            print("WorkoutDataService: Unable to convert workout for reward calculation")
            return
        }
        
        // Store the processed workout
        try await syncWorkout(workout)
        
        // Send workout completion notification (achievement only, no Bitcoin reward)
        await sendWorkoutCompletionNotification(
            userId: workout.userId,
            workoutType: workout.type
        )
        
        // Process workout against active events and challenges
        await processWorkoutForEvents(healthKitWorkout, userId: workout.userId)
        
        // Update team leaderboards immediately after successful sync
        await updateTeamLeaderboards(userId: workout.userId, workout: workout)
        
        print("🏆 WorkoutDataService: Workout processed for team participation: \(workout.id)")
    }
    
    // MARK: - Helper Methods
    
    private func convertToHealthKitWorkout(_ workout: Workout) -> HealthKitWorkout? {
        // Convert Supabase Workout to HealthKitWorkout for reward calculation
        return HealthKitWorkout(
            id: workout.id,
            activityType: .other, // Default activity type - would need proper mapping
            startDate: workout.startedAt,
            endDate: workout.endedAt ?? Date(),
            duration: TimeInterval(workout.duration),
            totalDistance: Double(workout.distance ?? 0),
            totalEnergyBurned: Double(workout.calories ?? 0),
            syncSource: .healthKit, // Default - would need proper mapping
            metadata: [:]
        )
    }
    
    // Note: Individual workout rewards removed - rewards now come from team prize pools only
    
    // MARK: - Team-Branded Notifications
    
    private func sendWorkoutCompletionNotification(userId: String, workoutType: String) async {
        do {
            // Fetch user's teams to get team branding
            let teams = try await TeamDataService.shared.fetchUserTeams(userId: userId)
            
            if let primaryTeam = teams.first {
                // Send team-branded achievement notification (no Bitcoin reward)
                await MainActor.run {
                    NotificationService.shared.scheduleTeamBrandedNotification(
                        teamName: primaryTeam.name,
                        title: "Workout Complete! 🏃‍♂️",
                        message: "Your \(workoutType.capitalized) workout was synced to Team \(primaryTeam.name)! Contributing to team leaderboards 💪",
                        identifier: "workout_sync_\(UUID().uuidString)",
                        type: "workout_completion",
                        userInfo: [
                            "workout_type": workoutType,
                            "team_id": primaryTeam.id,
                            "user_id": userId
                        ]
                    )
                }
                print("💪 WorkoutDataService: Team achievement notification sent for \(primaryTeam.name)")
            } else {
                // Fallback to generic achievement notification if no team found
                await MainActor.run {
                    NotificationService.shared.scheduleWorkoutCompletionNotification(
                        workoutType: workoutType
                    )
                }
                print("🏃‍♂️ WorkoutDataService: Generic achievement notification sent (no team found)")
            }
        } catch {
            print("❌ WorkoutDataService: Failed to fetch teams for notification: \(error)")
            // Fallback to generic achievement notification
            await MainActor.run {
                NotificationService.shared.scheduleWorkoutCompletionNotification(
                    workoutType: workoutType
                )
            }
        }
    }
    
    // MARK: - Batch Operations
    
    func syncWorkoutBatch(_ workouts: [Workout]) async throws {
        for workout in workouts {
            do {
                try await syncWorkout(workout)
            } catch {
                print("WorkoutDataService: Failed to sync workout \(workout.id): \(error)")
                // Continue with other workouts even if one fails
                continue
            }
        }
        
        print("WorkoutDataService: Batch sync completed for \(workouts.count) workouts")
    }
    
    // MARK: - Team Leaderboard Updates
    
    private func updateTeamLeaderboards(userId: String, workout: Workout) async {
        print("🏆 WorkoutDataService: Tracking user positions after workout")
        
        // Track all leaderboard positions for user after workout
        let positionChanges = await LeaderboardTracker.shared.trackUserPositions(userId: userId)
        
        print("🏆 WorkoutDataService: Found \(positionChanges.count) leaderboard position changes")
        
        // Process any position change notifications
        if !positionChanges.isEmpty {
            await LeaderboardTracker.shared.processPositionChanges(positionChanges)
        }
    }
    
    // MARK: - Event Processing
    
    private func processWorkoutForEvents(_ workout: HealthKitWorkout, userId: String) async {
        print("🎯 WorkoutDataService: Processing workout for events and challenges")
        
        // Use EventCriteriaEngine to check workout against all active events
        await EventCriteriaEngine.shared.processWorkoutForEvents(workout, userId: userId)
        
        print("🎯 WorkoutDataService: Event processing completed for workout \(workout.id)")
    }
    
}

// MARK: - Local Data Models - Temporary until models are extracted

private struct TeamMemberUserIdLocal: Codable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}