import Foundation
import Supabase

// P2P Challenge types are now in Services/P2PChallengeService.swift

// Import comment placeholder removed - P2P challenge types moved to dedicated service
    let challenge: P2PChallenge
    let challenger: Profile
    let challenged: Profile
}

struct P2PChallenge: Codable {
    let id: String
    let challenger_id: String
    let challenged_id: String
    let team_id: String
    let type: P2PChallengeType
    let stake: P2PChallengeStake
    let status: P2PChallengeStatus
    let duration: Int
    let conditions: P2PChallengeConditions
    let created_at: Date
    let updated_at: Date
}

enum P2PChallengeType: String, Codable, CaseIterable {
    case distance_race = "distance_race"
    case duration_goal = "duration_goal" 
    case streak_days = "streak_days"
    case fastest_time = "fastest_time"
    
    var displayName: String {
        switch self {
        case .distance_race: return "Distance Race"
        case .duration_goal: return "Duration Goal"
        case .streak_days: return "Streak Challenge"
        case .fastest_time: return "Fastest Time"
        }
    }
}

enum P2PChallengeStake: Int, Codable, CaseIterable {
    case low = 1000    // 1k sats
    case medium = 5000 // 5k sats  
    case high = 10000  // 10k sats
    
    var displayText: String {
        switch self {
        case .low: return "1,000 sats"
        case .medium: return "5,000 sats"
        case .high: return "10,000 sats"
        }
    }
}

enum P2PChallengeStatus: String, Codable {
    case pending = "pending"
    case active = "active"
    case completed = "completed"
    case declined = "declined"
    case expired = "expired"
    case needs_arbitration = "needs_arbitration"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .active: return "Active"
        case .completed: return "Completed"
        case .declined: return "Declined"
        case .expired: return "Expired"
        case .needs_arbitration: return "Needs Arbitration"
        }
    }
}

struct P2PChallengeConditions: Codable {
    let targetValue: Double?
    let description: String?
}

enum P2PChallengeOutcome: String, Codable {
    case challenger_wins = "challenger_wins"
    case challenged_wins = "challenged_wins"
    case draw = "draw"
}

struct Profile: Codable {
    let id: String
    let username: String?
    let email: String?
}

// MARK: - Temporary P2PChallengeService Mock (until file is added to Xcode project)

class P2PChallengeService {
    static let shared = P2PChallengeService()
    private init() {}
    
    func getActiveUserChallenges(userId: String) async throws -> [P2PChallengeWithParticipants] {
        print("🔄 P2PChallengeService: Getting active challenges for user \(userId)")
        // For now, return empty array until service is properly integrated
        return []
    }
    
    func updateChallengeProgress(challengeId: String, userId: String, progressValue: Double, workoutId: String) async throws {
        print("📊 P2PChallengeService: Progress update - Challenge \(challengeId), User \(userId): +\(progressValue)")
    }
    
    func updateStreakProgress(challengeId: String, userId: String, workoutDate: Date, workoutId: String) async throws {
        print("🔥 P2PChallengeService: Streak progress update - Challenge \(challengeId), User \(userId)")
    }
    
    func updateFastestTimeProgress(challengeId: String, userId: String, timePerKm: Double, workoutId: String) async throws {
        print("⚡ P2PChallengeService: Fastest time update - Challenge \(challengeId), User \(userId): \(timePerKm)s/km")
    }
    
    func checkChallengeCompletion(challengeId: String) async throws -> ChallengeCompletionStatus {
        print("🏁 P2PChallengeService: Checking completion for challenge \(challengeId)")
        return ChallengeCompletionStatus(needsArbitration: false, teamId: nil, winnerId: nil, outcome: nil)
    }
    
    func moveToArbitration(challengeId: String) async throws {
        print("⚖️ P2PChallengeService: Moving challenge \(challengeId) to arbitration")
    }
    
    func acceptChallenge(challengeId: String, userId: String) async throws -> P2PChallenge {
        print("✅ P2PChallengeService: Accepting challenge \(challengeId) for user \(userId)")
        // Return mock challenge for now
        return P2PChallenge(
            id: challengeId,
            challenger_id: "challenger",
            challenged_id: userId,
            team_id: "team",
            type: .distance_race,
            stake: .low,
            status: .active,
            duration: 7,
            conditions: P2PChallengeConditions(targetValue: 10.0, description: "Run 10km"),
            created_at: Date(),
            updated_at: Date()
        )
    }
    
    func declineChallenge(challengeId: String, userId: String) async throws -> P2PChallenge {
        print("❌ P2PChallengeService: Declining challenge \(challengeId) for user \(userId)")
        // Return mock challenge for now
        return P2PChallenge(
            id: challengeId,
            challenger_id: "challenger", 
            challenged_id: userId,
            team_id: "team",
            type: .distance_race,
            stake: .low,
            status: .declined,
            duration: 7,
            conditions: P2PChallengeConditions(targetValue: 10.0, description: "Run 10km"),
            created_at: Date(),
            updated_at: Date()
        )
    }
    
    func getChallengesNeedingArbitration(teamId: String) async throws -> [P2PChallengeWithParticipants] {
        print("⚖️ P2PChallengeService: Getting challenges needing arbitration for team \(teamId)")
        // Return empty array for now until service is properly integrated
        return []
    }
    
    func arbitrateChallenge(challengeId: String, outcome: P2PChallengeOutcome) async throws {
        print("🏛️ P2PChallengeService: Arbitrating challenge \(challengeId) with outcome \(outcome.rawValue)")
        // Mock arbitration - would need real implementation
    }
}

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
        
        // Process workout against active P2P challenges
        await processWorkoutForP2PChallenges(workout: workout)
        
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
    
    // MARK: - Data Retrieval
    
    func getWorkoutsForDateRange(userId: String, start: Date, end: Date) async throws -> [Workout] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: start)
        let endDateString = dateFormatter.string(from: end)
        
        let response = try await supabase
            .from("workouts")
            .select("*")
            .eq("user_id", value: userId)
            .gte("started_at", value: startDateString)
            .lte("started_at", value: endDateString)
            .order("started_at", ascending: false)
            .execute()
        
        return try JSONDecoder().decode([Workout].self, from: response.data)
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
    
    // MARK: - P2P Challenge Processing
    
    private func processWorkoutForP2PChallenges(workout: Workout) async {
        print("🥊 WorkoutDataService: Processing workout for P2P challenges")
        
        do {
            // Get user's active P2P challenges
            let activeP2PChallenges = try await P2PChallengeService.shared.getActiveUserChallenges(userId: workout.userId)
            
            if activeP2PChallenges.isEmpty {
                print("🥊 WorkoutDataService: No active P2P challenges found for user")
                return
            }
            
            print("🥊 WorkoutDataService: Found \(activeP2PChallenges.count) active P2P challenges to process")
            
            // Process each challenge against the workout
            for challengeData in activeP2PChallenges {
                await processChallengeProgress(challengeData: challengeData, workout: workout)
            }
            
            print("🥊 WorkoutDataService: P2P challenge processing completed for workout \(workout.id)")
            
        } catch {
            print("❌ WorkoutDataService: Failed to process P2P challenges: \(error)")
        }
    }
    
    private func processChallengeProgress(challengeData: P2PChallengeWithParticipants, workout: Workout) async {
        let challenge = challengeData.challenge
        print("🥊 WorkoutDataService: Processing challenge \(challenge.id) - \(challenge.type.displayName)")
        
        // Check if workout is relevant for this challenge type
        guard isWorkoutRelevantForChallenge(workout: workout, challengeType: challenge.type) else {
            print("🥊 WorkoutDataService: Workout type '\(workout.type)' not relevant for challenge type '\(challenge.type.rawValue)'")
            return
        }
        
        do {
            var progressMade = false
            
            switch challenge.type {
            case .distance_race:
                // For distance races, any workout with distance counts toward the goal
                if let distance = workout.distance, distance > 0 {
                    let distanceKm = Double(distance) / 1000.0
                    try await P2PChallengeService.shared.updateChallengeProgress(
                        challengeId: challenge.id,
                        userId: workout.userId,
                        progressValue: distanceKm,
                        workoutId: workout.id
                    )
                    progressMade = true
                    print("✅ WorkoutDataService: Updated distance race progress: +\(distanceKm)km")
                }
                
            case .duration_goal:
                // For duration goals, workout duration counts toward the goal
                let durationMinutes = Double(workout.duration) / 60.0
                try await P2PChallengeService.shared.updateChallengeProgress(
                    challengeId: challenge.id,
                    userId: workout.userId,
                    progressValue: durationMinutes,
                    workoutId: workout.id
                )
                progressMade = true
                print("✅ WorkoutDataService: Updated duration goal progress: +\(durationMinutes)min")
                
            case .streak_days:
                // For streak challenges, mark today as active for this user
                try await P2PChallengeService.shared.updateStreakProgress(
                    challengeId: challenge.id,
                    userId: workout.userId,
                    workoutDate: workout.startedAt,
                    workoutId: workout.id
                )
                progressMade = true
                print("✅ WorkoutDataService: Updated streak progress for date: \(workout.startedAt)")
                
            case .fastest_time:
                // For fastest time challenges, check if this workout beats previous best
                if let distance = workout.distance, distance > 0, workout.duration > 0 {
                    let timePerKm = Double(workout.duration) / (Double(distance) / 1000.0)
                    try await P2PChallengeService.shared.updateFastestTimeProgress(
                        challengeId: challenge.id,
                        userId: workout.userId,
                        timePerKm: timePerKm,
                        workoutId: workout.id
                    )
                    progressMade = true
                    print("✅ WorkoutDataService: Updated fastest time progress: \(timePerKm)s/km")
                }
            }
            
            if progressMade {
                // Check if challenge is now complete and needs arbitration
                try await checkChallengeCompletion(challengeId: challenge.id)
            }
            
        } catch {
            print("❌ WorkoutDataService: Failed to update challenge \(challenge.id) progress: \(error)")
        }
    }
    
    private func isWorkoutRelevantForChallenge(workout: Workout, challengeType: P2PChallengeType) -> Bool {
        let workoutType = workout.type.lowercased()
        
        switch challengeType {
        case .distance_race:
            // Distance races require workouts with distance data
            return workout.distance != nil && workout.distance! > 0 && 
                   ["running", "walking", "cycling"].contains(workoutType)
            
        case .duration_goal:
            // Duration goals can use any workout type
            return workout.duration > 0
            
        case .streak_days:
            // Streak challenges can use any workout type
            return workout.duration > 0
            
        case .fastest_time:
            // Fastest time requires distance and duration data
            return workout.distance != nil && workout.distance! > 0 && 
                   workout.duration > 0 && ["running", "cycling"].contains(workoutType)
        }
    }
    
    private func checkChallengeCompletion(challengeId: String) async throws {
        // Check if challenge conditions are met and should be moved to arbitration
        let challengeStatus = try await P2PChallengeService.shared.checkChallengeCompletion(challengeId: challengeId)
        
        if challengeStatus.needsArbitration {
            print("🏁 WorkoutDataService: Challenge \(challengeId) completed, moving to arbitration")
            
            // Move challenge to arbitration status
            try await P2PChallengeService.shared.moveToArbitration(challengeId: challengeId)
            
            // Send notification to team captain
            if let teamId = challengeStatus.teamId {
                try await NotificationService.shared.notifyCaptainOfArbitrationNeeded(
                    challengeId: challengeId,
                    teamId: teamId
                )
                print("📢 WorkoutDataService: Captain notified of arbitration needed for challenge \(challengeId)")
            }
        }
    }
    
}

// MARK: - P2P Challenge Status Result

struct ChallengeCompletionStatus {
    let needsArbitration: Bool
    let teamId: String?
    let winnerId: String?
    let outcome: P2PChallengeOutcome?
}

// MARK: - Local Data Models - Temporary until models are extracted

private struct TeamMemberUserIdLocal: Codable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}