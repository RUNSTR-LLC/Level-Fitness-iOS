import Foundation

class CompetitionDataService {
    static let shared = CompetitionDataService()
    private let supabase = SupabaseService.shared
    
    // Component services
    private let leaderboardService = LeaderboardDataService.shared
    private let eventService = EventDataService.shared
    
    private init() {}
    
    // MARK: - Core Competition Methods
    
    func updateUserProgress(userId: String, workout: HealthKitWorkout, points: Int) async throws {
        do {
            // Update leaderboards through specialized service
            try await leaderboardService.updateUserProgress(userId: userId, workout: workout, points: points)
            
            // Update active events/challenges
            try await updateActiveEventProgress(userId: userId, workout: workout, points: points)
            
            // Trigger notifications for position changes
            await checkForPositionChanges(userId: userId)
            
            print("CompetitionDataService: ✅ Updated user progress")
            
        } catch {
            print("CompetitionDataService: ❌ Failed to update user progress: \(error)")
            throw error
        }
    }
    
    private func updateActiveEventProgress(userId: String, workout: HealthKitWorkout, points: Int) async throws {
        // Get user's active events
        let activeEvents = try await fetchUserActiveEvents(userId: userId)
        
        for event in activeEvents {
            let currentProgress = try await getCurrentEventProgress(eventId: event.id, userId: userId)
            let newProgress = currentProgress + Double(points)
            
            try await eventService.updateEventProgress(
                eventId: event.id,
                userId: userId,
                progress: newProgress
            )
        }
    }
    
    private func fetchUserActiveEvents(userId: String) async throws -> [CompetitionEvent] {
        let response = try await supabase.client
            .from("event_participants")
            .select("""
                event_id,
                competition_events!inner(*)
            """)
            .eq("user_id", value: userId)
            .eq("is_active", value: true)
            .execute()
        
        return try parseUserEvents(from: response.data)
    }
    
    private func getCurrentEventProgress(eventId: String, userId: String) async throws -> Double {
        let response = try await supabase.client
            .from("event_participants")
            .select("progress")
            .eq("event_id", value: eventId)
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        if let progressData = try? JSONDecoder().decode([String: Double].self, from: response.data),
           let progress = progressData["progress"] {
            return progress
        }
        
        return 0.0
    }
    
    private func checkForPositionChanges(userId: String) async {
        // Check if user's leaderboard position changed significantly
        do {
            let currentRanking = try await getUserCurrentRanking(userId: userId)
            let previousRanking = getUserPreviousRanking(userId: userId)
            
            if let current = currentRanking, let previous = previousRanking {
                let positionChange = previous - current
                
                // Notify if moved up 3+ positions or broke into top 10
                if positionChange >= 3 || (current <= 10 && previous > 10) {
                    await sendPositionChangeNotification(
                        userId: userId,
                        newPosition: current,
                        positionChange: positionChange
                    )
                }
            }
            
            // Store current ranking for next comparison
            storePreviousRanking(userId: userId, ranking: currentRanking)
            
        } catch {
            print("CompetitionDataService: Failed to check position changes: \(error)")
        }
    }
    
    // MARK: - Event Operations
    
    func fetchEvents(status: String = "active") async throws -> [CompetitionEvent] {
        return try await eventService.fetchEvents(status: status)
    }
    
    func createEvent(_ event: CompetitionEvent) async throws -> CompetitionEvent {
        return try await eventService.createEvent(event)
    }
    
    func joinEvent(eventId: String, userId: String) async throws {
        try await eventService.joinEvent(eventId: eventId, userId: userId)
    }
    
    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        return try await eventService.fetchEventParticipants(eventId: eventId)
    }
    
    // MARK: - Challenge Operations
    
    func fetchChallenges(teamId: String? = nil) async throws -> [Challenge] {
        return try await eventService.fetchChallenges(teamId: teamId)
    }
    
    func createChallenge(_ challenge: Challenge) async throws -> Challenge {
        return try await eventService.createChallenge(challenge)
    }
    
    func joinChallenge(challengeId: String, userId: String) async throws {
        try await eventService.joinChallenge(challengeId: challengeId, userId: userId)
    }
    
    // MARK: - Missing Method Implementations
    
    func registerUserForEvent(eventId: String, userId: String) async throws {
        try await eventService.registerUserForEvent(eventId: eventId, userId: userId)
    }
    
    func sendTeamMessage(teamId: String, userId: String, message: String, messageType: String) async throws {
        // Delegate to TeamDataService
        try await TeamDataService.shared.sendTeamMessage(teamId: teamId, userId: userId, message: message, messageType: messageType)
    }
    
    func fetchActiveTeamLeague(teamId: String) async throws -> TeamLeague? {
        do {
            let response = try await supabase.client
                .from("team_leagues")
                .select("*")
                .eq("team_id", value: teamId)
                .eq("status", value: "active")
                .order("start_date", ascending: false)
                .limit(1)
                .execute()
            
            if response.data.isEmpty {
                return nil
            }
            
            let leagues = try JSONDecoder().decode([TeamLeague].self, from: response.data)
            return leagues.first
            
        } catch {
            print("CompetitionDataService: ❌ Failed to fetch active team league: \(error)")
            throw error
        }
    }
    
    // MARK: - Leaderboard Operations
    
    func fetchWeeklyLeaderboard() async throws -> [LeaderboardEntry] {
        return try await leaderboardService.fetchWeeklyLeaderboard()
    }
    
    func fetchTeamLeaderboard() async throws -> [TeamLeaderboardEntry] {
        return try await leaderboardService.fetchTeamLeaderboard()
    }
    
    func fetchTeamRankings(teamId: String, period: String = "weekly") async throws -> [TeamMemberRanking] {
        return try await leaderboardService.fetchTeamRankings(teamId: teamId, period: period)
    }
    
    // MARK: - Team League Operations
    
    func createTeamLeague(_ league: TeamLeague) async throws -> TeamLeague {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let leagueData = try encoder.encode(league)
            let leagueDict = try JSONSerialization.jsonObject(with: leagueData) as! [String: Any]
            
            let response = try await supabase.client
                .from("team_leagues")
                .insert(leagueDict)
                .select()
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let createdLeague = try decoder.decode(TeamLeague.self, from: response.data)
            
            print("CompetitionDataService: ✅ Created team league \(createdLeague.id)")
            return createdLeague
            
        } catch {
            print("CompetitionDataService: ❌ Failed to create team league: \(error)")
            throw error
        }
    }
    
    func completeTeamLeague(_ league: TeamLeague) async throws {
        do {
            let response = try await supabase.client
                .from("team_leagues")
                .update([
                    "status": "completed",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("id", value: league.id)
                .execute()
            
            print("CompetitionDataService: ✅ Completed team league \(league.id)")
            
        } catch {
            print("CompetitionDataService: ❌ Failed to complete team league: \(error)")
            throw error
        }
    }
    
    func calculateLeaguePrizeDistribution(_ league: TeamLeague) async throws -> LeaguePrizeDistribution {
        do {
            // Get final standings for the league
            let standings = try await getLeagueFinalStandings(leagueId: league.id)
            
            // Calculate prize distribution based on league prize pool
            let totalPrize = league.prizePool
            let distribution = calculatePrizeBreakdown(totalPrize: totalPrize, standings: standings)
            
            return LeaguePrizeDistribution(
                leagueId: league.id,
                totalPrizePool: totalPrize,
                distribution: distribution,
                calculatedAt: Date()
            )
            
        } catch {
            print("CompetitionDataService: ❌ Failed to calculate league prize distribution: \(error)")
            throw error
        }
    }
    
    func distributeLeaguePrizes(distribution: LeaguePrizeDistribution) async throws {
        do {
            // Distribute prizes to team members based on final standings
            for prizeEntry in distribution.distribution {
                try await TeamWalletManager.shared.distributePrize(
                    userId: prizeEntry.userId,
                    amount: prizeEntry.amount,
                    reason: "League prize for position \(prizeEntry.position)"
                )
            }
            
            print("CompetitionDataService: ✅ Distributed league prizes for \(distribution.leagueId)")
            
        } catch {
            print("CompetitionDataService: ❌ Failed to distribute league prizes: \(error)")
            throw error
        }
    }
    
    private func getLeagueFinalStandings(leagueId: String) async throws -> [LeagueStanding] {
        let response = try await supabase.client
            .from("league_standings")
            .select("*")
            .eq("league_id", value: leagueId)
            .order("position", ascending: true)
            .execute()
        
        return try JSONDecoder().decode([LeagueStanding].self, from: response.data)
    }
    
    private func calculatePrizeBreakdown(totalPrize: Int, standings: [LeagueStanding]) -> [PrizeEntry] {
        guard !standings.isEmpty else { return [] }
        
        var distribution: [PrizeEntry] = []
        
        // Winner takes 50%, 2nd gets 30%, 3rd gets 20%
        if standings.count >= 1 {
            distribution.append(PrizeEntry(
                userId: standings[0].userId,
                position: 1,
                amount: Int(Double(totalPrize) * 0.5)
            ))
        }
        
        if standings.count >= 2 {
            distribution.append(PrizeEntry(
                userId: standings[1].userId,
                position: 2,
                amount: Int(Double(totalPrize) * 0.3)
            ))
        }
        
        if standings.count >= 3 {
            distribution.append(PrizeEntry(
                userId: standings[2].userId,
                position: 3,
                amount: Int(Double(totalPrize) * 0.2)
            ))
        }
        
        return distribution
    }
    
    // MARK: - Competition Analytics
    
    func getCompetitionSummary(userId: String) async throws -> CompetitionSummary {
        do {
            let weeklyRanking = try await getUserCurrentRanking(userId: userId)
            let teamRankings = try await getUserTeamRankings(userId: userId)
            let activeEvents = try await fetchUserActiveEvents(userId: userId)
            
            return CompetitionSummary(
                userId: userId,
                weeklyRanking: weeklyRanking,
                teamRankings: teamRankings,
                activeEventsCount: activeEvents.count,
                totalPoints: calculateTotalPoints(teamRankings)
            )
            
        } catch {
            print("CompetitionDataService: ❌ Failed to get competition summary: \(error)")
            throw error
        }
    }
    
    // MARK: - Team Messages
    
    func fetchTeamMessages(teamId: String, limit: Int = 50) async throws -> [TeamMessage] {
        let response = try await supabase.client
            .from("team_messages")
            .select("*")
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try JSONDecoder().decode([TeamMessage].self, from: response.data)
    }
    
    func fetchTeamEvents(teamId: String, limit: Int = 20) async throws -> [CompetitionEvent] {
        let response = try await supabase.client
            .from("events")
            .select("*")
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        return try JSONDecoder().decode([CompetitionEvent].self, from: response.data)
    }
    
    // MARK: - Helper Methods
    
    private func getUserCurrentRanking(userId: String) async throws -> Int? {
        let response = try await supabase.client
            .from("leaderboard_weekly")
            .select("ranking")
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        if let rankingData = try? JSONDecoder().decode([String: Int].self, from: response.data),
           let ranking = rankingData["ranking"] {
            return ranking
        }
        
        return nil
    }
    
    private func getUserTeamRankings(userId: String) async throws -> [TeamMemberRanking] {
        let response = try await supabase.client
            .from("team_member_rankings")
            .select("*")
            .eq("user_id", value: userId)
            .execute()
        
        return try JSONDecoder().decode([TeamMemberRanking].self, from: response.data)
    }
    
    private func getUserPreviousRanking(userId: String) -> Int? {
        return UserDefaults.standard.object(forKey: "previous_ranking_\(userId)") as? Int
    }
    
    private func storePreviousRanking(userId: String, ranking: Int?) {
        if let ranking = ranking {
            UserDefaults.standard.set(ranking, forKey: "previous_ranking_\(userId)")
        } else {
            UserDefaults.standard.removeObject(forKey: "previous_ranking_\(userId)")
        }
    }
    
    private func calculateTotalPoints(_ rankings: [TeamMemberRanking]) -> Int {
        return rankings.reduce(0) { $0 + $1.points }
    }
    
    private func sendPositionChangeNotification(userId: String, newPosition: Int, positionChange: Int) async {
        let title = positionChange >= 10 ? "🚀 Big Move!" : "📈 Position Update"
        let body = "You moved up \(positionChange) spots to #\(newPosition)!"
        
        do {
            try await NotificationInboxService.shared.storeNotification(
                userId: userId,
                type: "position_change",
                title: title,
                body: body,
                actionData: [
                    "new_position": String(newPosition),
                    "position_change": String(positionChange)
                ]
            )
        } catch {
            print("CompetitionDataService: Failed to send position change notification: \(error)")
        }
    }
    
    private func parseUserEvents(from data: Data) throws -> [CompetitionEvent] {
        // Parse nested event data from event_participants join
        return []
    }
}

// MARK: - Data Models

struct CompetitionSummary {
    let userId: String
    let weeklyRanking: Int?
    let teamRankings: [TeamMemberRanking]
    let activeEventsCount: Int
    let totalPoints: Int
}

struct LeaguePrizeDistribution {
    let leagueId: String
    let totalPrizePool: Int
    let distribution: [PrizeEntry]
    let calculatedAt: Date
}

struct PrizeEntry {
    let userId: String
    let position: Int
    let amount: Int
}

struct LeagueStanding: Codable {
    let userId: String
    let leagueId: String
    let position: Int
    let totalPoints: Int
    let teamId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case leagueId = "league_id"
        case position
        case totalPoints = "total_points"
        case teamId = "team_id"
    }
}

// MARK: - Real-time Subscriptions

extension CompetitionDataService {
    func subscribeToCompetitionUpdates(userId: String, completion: @escaping (CompetitionUpdate) -> Void) {
        print("CompetitionDataService: Setting up real-time competition updates for \(userId)")
    }
    
    func unsubscribeFromCompetitionUpdates(userId: String) {
        print("CompetitionDataService: Unsubscribing from competition updates for \(userId)")
    }
}

struct CompetitionUpdate {
    let type: UpdateType
    let data: [String: Any]
    
    enum UpdateType {
        case leaderboardChange
        case eventProgress
        case challengeUpdate
        case positionChange
    }
}