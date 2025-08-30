import Foundation

class LeaderboardDataService {
    static let shared = LeaderboardDataService()
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Weekly Leaderboards
    
    func fetchWeeklyLeaderboard() async throws -> [LeaderboardEntry] {
        do {
            let response = try await supabase.client
                .from("leaderboard_weekly")
                .select("*")
                .order("points", ascending: false)
                .limit(50)
                .execute()
            
            let leaderboard = try JSONDecoder().decode([LeaderboardEntry].self, from: response.data)
            print("LeaderboardDataService: ✅ Fetched \(leaderboard.count) weekly entries")
            return leaderboard
            
        } catch {
            print("LeaderboardDataService: ❌ Failed to fetch weekly leaderboard: \(error)")
            throw error
        }
    }
    
    func fetchTeamLeaderboard() async throws -> [TeamLeaderboardEntry] {
        do {
            let response = try await supabase.client
                .from("leaderboard_teams")
                .select("*")
                .order("points", ascending: false)
                .limit(50)
                .execute()
            
            let leaderboard = try JSONDecoder().decode([TeamLeaderboardEntry].self, from: response.data)
            print("LeaderboardDataService: ✅ Fetched \(leaderboard.count) team entries")
            return leaderboard
            
        } catch {
            print("LeaderboardDataService: ❌ Failed to fetch team leaderboard: \(error)")
            throw error
        }
    }
    
    func fetchTeamRankings(teamId: String, period: String = "weekly") async throws -> [TeamMemberRanking] {
        do {
            let response = try await supabase.client
                .from("team_member_rankings")
                .select("""
                    user_id, full_name, avatar_url, 
                    workouts, distance, calories, 
                    points, ranking, team_id,
                    profiles!inner(full_name, avatar_url)
                """)
                .eq("team_id", value: teamId)
                .eq("period", value: period)
                .order("ranking", ascending: true)
                .execute()
            
            let rankings = try parseTeamRankings(from: response.data)
            print("LeaderboardDataService: ✅ Fetched \(rankings.count) team rankings")
            return rankings
            
        } catch {
            print("LeaderboardDataService: ❌ Failed to fetch team rankings: \(error)")
            throw error
        }
    }
    
    func updateUserProgress(userId: String, workout: HealthKitWorkout, points: Int) async throws {
        do {
            // Update weekly leaderboard
            try await updateWeeklyLeaderboard(userId: userId, workout: workout, points: points)
            
            // Update team rankings if user is in teams
            try await updateTeamRankings(userId: userId, workout: workout, points: points)
            
            print("LeaderboardDataService: ✅ Updated user progress")
            
        } catch {
            print("LeaderboardDataService: ❌ Failed to update user progress: \(error)")
            throw error
        }
    }
    
    private func updateWeeklyLeaderboard(userId: String, workout: HealthKitWorkout, points: Int) async throws {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let update = LeaderboardUpdate(
            userId: userId,
            weekStart: weekStart,
            workouts: 1,
            distance: workout.totalDistance ?? 0.0,
            calories: workout.totalEnergyBurned ?? 0.0,
            points: points
        )
        
        try await supabase.client
            .rpc("update_weekly_leaderboard", params: update)
            .execute()
    }
    
    private func updateTeamRankings(userId: String, workout: HealthKitWorkout, points: Int) async throws {
        // Get user's teams
        let teams = try await supabase.client
            .from("team_members")
            .select("team_id")
            .eq("user_id", value: userId)
            .execute()
        
        guard let teamData = try? JSONDecoder().decode([TeamReference].self, from: teams.data) else {
            return
        }
        
        // Update rankings for each team
        for team in teamData {
            let update = TeamRankingUpdate(
                userId: userId,
                teamId: team.teamId,
                workouts: 1,
                distance: workout.totalDistance ?? 0.0,
                calories: workout.totalEnergyBurned ?? 0.0,
                points: points
            )
            
            try await supabase.client
                .rpc("update_team_rankings", params: update)
                .execute()
        }
    }
    
    // MARK: - Leaderboard Calculations
    
    private func calculateLeaderboardPoints(workouts: Int, distance: Double, time: Double) -> Int {
        let workoutPoints = workouts * 100
        let distancePoints = Int(distance / 1000) * 50 // 50 points per km
        let timePoints = Int(time / 3600) * 25 // 25 points per hour
        
        return workoutPoints + distancePoints + timePoints
    }
    
    // MARK: - Real-time Updates
    
    func subscribeToLeaderboardUpdates(teamId: String?, completion: @escaping ([LeaderboardEntry]) -> Void) {
        // Set up real-time subscription for leaderboard changes
        print("LeaderboardDataService: Setting up real-time updates for team: \(teamId ?? "global")")
    }
    
    func unsubscribeFromLeaderboardUpdates() {
        print("LeaderboardDataService: Unsubscribing from real-time updates")
    }
    
    // MARK: - Helper Methods
    
    private func parseTeamRankings(from data: Data) throws -> [TeamMemberRanking] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TeamMemberRanking].self, from: data)
    }
}

// MARK: - Data Models

struct LeaderboardUpdate: Codable {
    let userId: String
    let weekStart: Date
    let workouts: Int
    let distance: Double
    let calories: Double
    let points: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weekStart = "week_start"
        case workouts, distance, calories, points
    }
}

struct TeamRankingUpdate: Codable {
    let userId: String
    let teamId: String
    let workouts: Int
    let distance: Double
    let calories: Double
    let points: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case teamId = "team_id"
        case workouts, distance, calories, points
    }
}

struct TeamReference: Codable {
    let teamId: String
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
    }
}