import Foundation
import Supabase

// MARK: - Required Data Models

struct LeaderboardEntry: Codable {
    let userId: String
    let username: String
    let rank: Int
    let points: Int
    let workoutCount: Int
    let totalDistance: Double
}

struct CompetitionEvent: Codable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let targetValue: Double
    let unit: String
    let entryFee: Int
    let prizePool: Int
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int?
    let participantCount: Int
    let status: String
    let imageUrl: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, unit, status
        case createdAt = "created_at"
        case targetValue = "target_value"
        case entryFee = "entry_fee"
        case prizePool = "prize_pool"
        case startDate = "start_date"
        case endDate = "end_date"
        case maxParticipants = "max_participants"
        case participantCount = "participant_count"
        case imageUrl = "image_url"
    }
}

struct EventParticipant: Codable {
    let eventId: String
    let userId: String
    let progress: Double
    let position: Int?
    let completed: Bool
    let completedAt: Date?
    let entryPaid: Bool
    let prizeEarned: Int
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case eventId = "event_id"
        case progress, position, completed
        case completedAt = "completed_at"
        case entryPaid = "entry_paid"
        case prizeEarned = "prize_earned"
        case joinedAt = "joined_at"
    }
}

struct Challenge: Codable {
    let id: String
    let teamId: String
    let name: String
    let description: String?
    let type: String
    let targetValue: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let prizePool: Int
    let status: String
    let createdBy: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, unit, status
        case teamId = "team_id"
        case targetValue = "target_value"
        case startDate = "start_date"
        case endDate = "end_date"
        case prizePool = "prize_pool"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct ChallengeParticipant: Codable {
    let challengeId: String
    let userId: String
    let progress: Double
    let completed: Bool
    let completedAt: Date?
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case userId = "user_id"
        case progress, completed
        case completedAt = "completed_at"
        case joinedAt = "joined_at"
    }
}

struct TeamMessage: Codable {
    let id: String
    let teamId: String
    let userId: String
    let message: String
    let messageType: String
    let edited: Bool
    let editedAt: Date?
    let createdAt: Date
    let username: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, message, edited
        case teamId = "team_id"
        case userId = "user_id"
        case messageType = "message_type"
        case editedAt = "edited_at"
        case createdAt = "created_at"
        case username, avatarUrl = "avatar_url"
    }
}

struct TeamLeaderboardEntry: Codable {
    let teamId: String
    let teamName: String
    let memberCount: Int
    let totalWorkouts: Int
    let totalDuration: Int
    let totalDistance: Double
    let totalPoints: Int
    let totalRewards: Int
    let rank: Int
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case teamName = "team_name"
        case memberCount = "member_count"
        case totalWorkouts = "total_workouts"
        case totalDuration = "total_duration"
        case totalDistance = "total_distance"
        case totalPoints = "total_points"
        case totalRewards = "total_rewards"
        case rank
    }
}

struct TeamLeague: Codable {
    let id: String
    let teamId: String
    let name: String
    let type: String
    let startDate: Date
    let endDate: Date
    let status: String
    let payoutPercentages: [Int]
    let createdBy: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, status
        case teamId = "team_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case payoutPercentages = "payout_percentages"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
    
    // Helper properties
    var isActive: Bool {
        return status == "active"
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Service Dependencies
// This service references models from SupabaseService, HealthKitService, ErrorHandlingService, WorkoutDataService, OfflineDataService, NetworkMonitorService

class CompetitionDataService {
    static let shared = CompetitionDataService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Competition Events
    
    func fetchEvents(status: String = "active") async throws -> [CompetitionEvent] {
        // Try cached data first if offline
        let isConnected = NetworkMonitorService.shared.isCurrentlyConnected()
        if !isConnected {
            // TODO: Implement offline caching for events
            throw AppError.networkUnavailable
        }
        
        do {
            let response = try await client
                .from("events")
                .select()
                .eq("status", value: status)
                .order("start_date", ascending: true)
                .execute()
            
            let data = response.data
            let events = try SupabaseService.shared.customJSONDecoder().decode([CompetitionEvent].self, from: data)
            
            // TODO: Cache the result when offline service is enhanced
            
            return events
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchEvents")
            throw error
        }
    }
    
    func createEvent(_ event: CompetitionEvent) async throws -> CompetitionEvent {
        print("CompetitionDataService: Creating event \(event.name)")
        
        // If offline, throw error (queuing to be implemented later)
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            print("CompetitionDataService: Cannot create event offline: \(event.id)")
            throw AppError.networkUnavailable
        }
        
        do {
            // Create event with participant count starting at 0
            let newEvent = CompetitionEvent(
                id: event.id,
                name: event.name,
                description: event.description,
                type: event.type,
                targetValue: event.targetValue,
                unit: event.unit,
                entryFee: event.entryFee,
                prizePool: event.prizePool,
                startDate: event.startDate,
                endDate: event.endDate,
                maxParticipants: event.maxParticipants,
                participantCount: 0, // Starting with 0 participants
                status: "active",
                imageUrl: event.imageUrl,
                createdAt: Date()
            )
            
            try await client
                .from("events")
                .insert(newEvent)
                .execute()
            
            print("CompetitionDataService: Event \(event.name) created successfully")
            return newEvent
        } catch {
            ErrorHandlingService.shared.logError(error, context: "createEvent")
            throw error
        }
    }
    
    func joinEvent(eventId: String, userId: String) async throws {
        print("CompetitionDataService: User \(userId) joining event \(eventId)")
        
        do {
            let participant = EventParticipant(
                eventId: eventId,
                userId: userId,
                progress: 0,
                position: nil,
                completed: false,
                completedAt: nil,
                entryPaid: false,
                prizeEarned: 0,
                joinedAt: Date()
            )
            
            try await client
                .from("event_participants")
                .insert(participant)
                .execute()
                
            print("CompetitionDataService: User successfully joined event")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "joinEvent", userId: userId)
            throw error
        }
    }
    
    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        do {
            let response = try await client
                .from("event_participants")
                .select()
                .eq("event_id", value: eventId)
                .order("progress", ascending: false)
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([EventParticipant].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchEventParticipants")
            throw error
        }
    }
    
    func registerUserForEvent(eventId: String, userId: String) async throws {
        print("CompetitionDataService: Registering user \(userId) for event \(eventId)")
        
        do {
            // Create event registration record
            let registration = [
                "event_id": eventId,
                "user_id": userId,
                "registered_at": ISO8601DateFormatter().string(from: Date()),
                "status": "active"
            ]
            
            try await client
                .from("event_registrations")
                .insert(registration)
                .execute()
            
            // Update event participant count
            try await client
                .from("events")
                .update(["participant_count": "participant_count + 1"])
                .eq("id", value: eventId)
                .execute()
            
            print("CompetitionDataService: User successfully registered for event")
            
        } catch {
            ErrorHandlingService.shared.logError(error, context: "registerUserForEvent", userId: userId)
            throw error
        }
    }
    
    // MARK: - Challenges
    
    func fetchChallenges(teamId: String? = nil) async throws -> [Challenge] {
        do {
            var query = client
                .from("challenges")
                .select()
            
            if let teamId = teamId {
                query = query.eq("team_id", value: teamId)
            }
            
            let response = try await query
                .eq("status", value: "active")
                .order("created_at", ascending: false)
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([Challenge].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchChallenges")
            throw error
        }
    }
    
    func createChallenge(_ challenge: Challenge) async throws -> Challenge {
        print("CompetitionDataService: Creating challenge \(challenge.name)")
        
        // If offline, throw error (queuing to be implemented later)
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            print("CompetitionDataService: Cannot create challenge offline: \(challenge.id)")
            throw AppError.networkUnavailable
        }
        
        do {
            try await client
                .from("challenges")
                .insert(challenge)
                .execute()
            
            print("CompetitionDataService: Challenge \(challenge.name) created successfully")
            return challenge
        } catch {
            ErrorHandlingService.shared.logError(error, context: "createChallenge")
            throw error
        }
    }
    
    func joinChallenge(challengeId: String, userId: String) async throws {
        print("CompetitionDataService: User \(userId) joining challenge \(challengeId)")
        
        do {
            let participant = ChallengeParticipant(
                challengeId: challengeId,
                userId: userId,
                progress: 0,
                completed: false,
                completedAt: nil,
                joinedAt: Date()
            )
            
            try await client
                .from("challenge_participants")
                .insert(participant)
                .execute()
                
            print("CompetitionDataService: User successfully joined challenge")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "joinChallenge", userId: userId)
            throw error
        }
    }
    
    func fetchChallengeParticipants(challengeId: String) async throws -> [ChallengeParticipant] {
        do {
            let response = try await client
                .from("challenge_participants")
                .select()
                .eq("challenge_id", value: challengeId)
                .order("progress", ascending: false)
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([ChallengeParticipant].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchChallengeParticipants")
            throw error
        }
    }
    
    func updateChallengeProgress(challengeId: String, userId: String, progress: Double) async throws {
        print("CompetitionDataService: Updating challenge progress: \(progress) for user \(userId)")
        
        do {
            try await client
                .from("challenge_participants")
                .update([
                    "progress": String(progress),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("challenge_id", value: challengeId)
                .eq("user_id", value: userId)
                .execute()
                
            print("CompetitionDataService: Challenge progress updated successfully")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "updateChallengeProgress", userId: userId)
            throw error
        }
    }
    
    // MARK: - Leaderboards
    
    func fetchWeeklyLeaderboard() async throws -> [LeaderboardEntry] {
        do {
            let response = try await client
                .from("weekly_leaderboard")
                .select()
                .order("rank", ascending: true)
                .limit(100)
                .execute()
            
            let data = response.data
            return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchWeeklyLeaderboard")
            throw error
        }
    }
    
    func fetchTeamLeaderboard() async throws -> [TeamLeaderboardEntry] {
        do {
            let response = try await client
                .from("team_leaderboard")
                .select()
                .order("rank", ascending: true)
                .limit(50)
                .execute()
            
            let data = response.data
            return try JSONDecoder().decode([TeamLeaderboardEntry].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeamLeaderboard")
            throw error
        }
    }
    
    func fetchTeamRankings(teamId: String, period: String = "weekly") async throws -> [TeamMemberRanking] {
        print("CompetitionDataService: Fetching team rankings for team \(teamId), period: \(period)")
        
        // Note: Date range calculation moved to WorkoutDataService.fetchTeamWorkouts
        
        do {
            // Get team workouts for the period using WorkoutDataService
            let teamWorkouts = try await WorkoutDataService.shared.fetchTeamWorkouts(teamId: teamId, period: period)
            
            // Calculate rankings based on workout data
            var userStats: [String: (workouts: Int, distance: Double, time: Double)] = [:]
            
            for workout in teamWorkouts {
                let userId = workout.userId
                let distance = Double(workout.distance ?? 0) / 1000.0 // Convert to km
                let time = Double(workout.duration)
                
                if userStats[userId] == nil {
                    userStats[userId] = (workouts: 0, distance: 0.0, time: 0.0)
                }
                
                userStats[userId]!.workouts += 1
                userStats[userId]!.distance += distance
                userStats[userId]!.time += time
            }
            
            // Convert to rankings and sort by total points
            var rankings: [TeamMemberRanking] = []
            for (userId, stats) in userStats {
                let points = calculateLeaderboardPoints(workouts: stats.workouts, distance: stats.distance, time: stats.time)
                
                let ranking = TeamMemberRanking(
                    userId: userId,
                    username: "User \(userId.prefix(8))", // Simplified for MVP
                    rank: 0, // Will be set after sorting
                    totalPoints: points,
                    workoutCount: stats.workouts,
                    totalDistance: stats.distance,
                    totalTime: stats.time
                )
                rankings.append(ranking)
            }
            
            // Sort by points and assign ranks
            rankings.sort { $0.totalPoints > $1.totalPoints }
            for (index, _) in rankings.enumerated() {
                rankings[index].rank = index + 1
            }
            
            return rankings
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeamRankings")
            throw error
        }
    }
    
    private func calculateLeaderboardPoints(workouts: Int, distance: Double, time: Double) -> Int {
        // Simple point calculation based on activity
        let workoutPoints = workouts * 10
        let distancePoints = Int(distance * 5) // 5 points per km
        let timePoints = Int(time / 60) // 1 point per minute
        
        return workoutPoints + distancePoints + timePoints
    }
    
    // MARK: - Team Chat
    
    func fetchTeamMessages(teamId: String, limit: Int = 50) async throws -> [TeamMessage] {
        do {
            let response = try await client
                .from("team_messages")
                .select("*, profiles(username, avatar_url)")
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([TeamMessage].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeamMessages")
            throw error
        }
    }
    
    func sendTeamMessage(teamId: String, userId: String, message: String, messageType: String = "text") async throws {
        print("CompetitionDataService: Sending team message from user \(userId)")
        
        // If offline, throw error (queuing to be implemented later)
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            print("CompetitionDataService: Cannot send message offline")
            throw AppError.networkUnavailable
        }
        
        do {
            let teamMessage = TeamMessage(
                id: UUID().uuidString,
                teamId: teamId,
                userId: userId,
                message: message,
                messageType: messageType,
                edited: false,
                editedAt: nil,
                createdAt: Date(),
                username: nil,
                avatarUrl: nil
            )
            
            try await client
                .from("team_messages")
                .insert(teamMessage)
                .execute()
                
            print("CompetitionDataService: Team message sent successfully")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "sendTeamMessage", userId: userId)
            throw error
        }
    }
    
    func fetchTeamChatHistory(teamId: String, beforeMessageId: String? = nil, limit: Int = 20) async throws -> [TeamMessage] {
        do {
            let query = client
                .from("team_messages")
                .select("*, profiles(username, avatar_url)")
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .limit(limit)
            
            if beforeMessageId != nil {
                // TODO: Implement pagination when lt() is available
                print("CompetitionDataService: Pagination not yet implemented")
            }
            
            let response = try await query.execute()
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([TeamMessage].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeamChatHistory")
            throw error
        }
    }
    
    // MARK: - Streaks and Performance
    
    func fetchUserStreak(userId: String) async throws -> CompetitionStreakData? {
        do {
            let response = try await client
                .from("user_streaks")
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode(CompetitionStreakData.self, from: data)
        } catch {
            // User might not have a streak record yet
            return nil
        }
    }
    
    func updateUserStreak(userId: String, workoutDate: Date) async throws {
        print("CompetitionDataService: Updating streak for user \(userId)")
        
        do {
            // Check if user has an existing streak
            if let existingStreak = try await fetchUserStreak(userId: userId) {
                // Calculate new streak based on workout date
                let calendar = Calendar.current
                let lastWorkoutDate = existingStreak.lastWorkoutDate
                let daysDifference = calendar.dateComponents([.day], from: lastWorkoutDate, to: workoutDate).day ?? 0
                
                var newStreakCount = existingStreak.currentStreak
                var newBestStreak = existingStreak.bestStreak
                
                if daysDifference == 1 {
                    // Consecutive day - extend streak
                    newStreakCount += 1
                    newBestStreak = max(newBestStreak, newStreakCount)
                } else if daysDifference > 1 {
                    // Streak broken - reset to 1
                    newStreakCount = 1
                }
                // If daysDifference == 0, same day workout - no change to streak
                
                let updatedStreak = CompetitionStreakData(
                    userId: userId,
                    currentStreak: newStreakCount,
                    bestStreak: newBestStreak,
                    lastWorkoutDate: workoutDate,
                    streakType: determineStreakType(count: newStreakCount)
                )
                
                try await client
                    .from("user_streaks")
                    .update(updatedStreak)
                    .eq("user_id", value: userId)
                    .execute()
            } else {
                // Create new streak record
                let newStreak = CompetitionStreakData(
                    userId: userId,
                    currentStreak: 1,
                    bestStreak: 1,
                    lastWorkoutDate: workoutDate,
                    streakType: .beginner
                )
                
                try await client
                    .from("user_streaks")
                    .insert(newStreak)
                    .execute()
            }
            
            print("CompetitionDataService: User streak updated successfully")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "updateUserStreak", userId: userId)
            throw error
        }
    }
    
    private func determineStreakType(count: Int) -> CompetitionStreakType {
        switch count {
        case 1...6:
            return .beginner
        case 7...20:
            return .consistent
        case 21...49:
            return .dedicated
        case 50...:
            return .legendary
        default:
            return .beginner
        }
    }
    
    // MARK: - Competition Analytics
    
    func fetchCompetitionStats(eventId: String) async throws -> CompetitionStats {
        do {
            // Fetch event details
            let eventResponse = try await client
                .from("events")
                .select()
                .eq("id", value: eventId)
                .single()
                .execute()
            
            let eventData = eventResponse.data
            let event = try SupabaseService.shared.customJSONDecoder().decode(CompetitionEvent.self, from: eventData)
            
            // Fetch participants
            let participants = try await fetchEventParticipants(eventId: eventId)
            
            // Calculate statistics
            let totalParticipants = participants.count
            let completedParticipants = participants.filter { $0.completed }.count
            let averageProgress = participants.isEmpty ? 0.0 : participants.reduce(0.0) { $0 + $1.progress } / Double(participants.count)
            let totalPrizeDistributed = participants.reduce(0) { $0 + $1.prizeEarned }
            
            return CompetitionStats(
                eventId: eventId,
                totalParticipants: totalParticipants,
                completedParticipants: completedParticipants,
                averageProgress: averageProgress,
                totalPrizePool: event.prizePool,
                distributedPrizes: totalPrizeDistributed,
                startDate: event.startDate,
                endDate: event.endDate,
                completionRate: totalParticipants > 0 ? Double(completedParticipants) / Double(totalParticipants) : 0.0
            )
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchCompetitionStats")
            throw error
        }
    }
    
    // MARK: - Prize Distribution
    
    func calculateEventPrizes(eventId: String) async throws -> [EventPrizeDistribution] {
        print("CompetitionDataService: Calculating prize distribution for event \(eventId)")
        
        do {
            // Fetch event details
            let eventResponse = try await client
                .from("events")
                .select()
                .eq("id", value: eventId)
                .single()
                .execute()
            
            let eventData = eventResponse.data
            let event = try SupabaseService.shared.customJSONDecoder().decode(CompetitionEvent.self, from: eventData)
            
            // Fetch participants sorted by performance
            let participants = try await fetchEventParticipants(eventId: eventId)
            let completedParticipants = participants.filter { $0.completed }.sorted { $0.progress > $1.progress }
            
            guard !completedParticipants.isEmpty else {
                return [] // No prizes if no one completed
            }
            
            // Calculate prize distribution based on ranking
            var distributions: [EventPrizeDistribution] = []
            let totalPrize = event.prizePool
            
            // Prize distribution: 50% to 1st, 30% to 2nd, 20% to 3rd
            let prizePercentages = [0.5, 0.3, 0.2]
            
            for (index, participant) in completedParticipants.enumerated() {
                guard index < prizePercentages.count else { break }
                
                let prizeAmount = Int(Double(totalPrize) * prizePercentages[index])
                let distribution = EventPrizeDistribution(
                    userId: participant.userId,
                    eventId: eventId,
                    rank: index + 1,
                    prizeAmount: prizeAmount,
                    distributedAt: Date()
                )
                distributions.append(distribution)
            }
            
            return distributions
        } catch {
            ErrorHandlingService.shared.logError(error, context: "calculateEventPrizes")
            throw error
        }
    }
    
    func distributePrizes(distributions: [EventPrizeDistribution]) async throws {
        print("CompetitionDataService: Distributing \(distributions.count) prizes")
        
        for distribution in distributions {
            do {
                // Update participant record with prize
                try await client
                    .from("event_participants")
                    .update([
                        "prize_earned": distribution.prizeAmount,
                        "position": distribution.rank
                    ])
                    .eq("event_id", value: distribution.eventId)
                    .eq("user_id", value: distribution.userId)
                    .execute()
                
                // Create transaction record (will be handled by TransactionDataService later)
                let transaction = DatabaseTransaction(
                    id: UUID().uuidString,
                    userId: distribution.userId,
                    walletId: nil,
                    type: "event_prize",
                    amount: distribution.prizeAmount,
                    usdAmount: nil,
                    description: "Event prize - Rank #\(distribution.rank)",
                    status: "completed",
                    transactionHash: nil,
                    preimage: nil,
                    processedAt: Date(),
                    createdAt: Date()
                )
                
                try await client
                    .from("transactions")
                    .insert(transaction)
                    .execute()
                
                print("CompetitionDataService: Prize distributed: \(distribution.prizeAmount) sats to user \(distribution.userId)")
            } catch {
                ErrorHandlingService.shared.logError(error, context: "distributePrize", userId: distribution.userId)
                // Continue with other prizes even if one fails
                continue
            }
        }
        
        print("CompetitionDataService: Prize distribution completed")
    }
    
    // MARK: - Team League Management
    
    func fetchActiveTeamLeague(teamId: String) async throws -> TeamLeague? {
        do {
            let response = try await client
                .from("team_leagues")
                .select()
                .eq("team_id", value: teamId)
                .eq("status", value: "active")
                .single()
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode(TeamLeague.self, from: data)
        } catch {
            // No active league found is not an error
            return nil
        }
    }
    
    func createTeamLeague(_ league: TeamLeague) async throws -> TeamLeague {
        print("CompetitionDataService: Creating team league \(league.name) for team \(league.teamId)")
        
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            throw AppError.networkUnavailable
        }
        
        do {
            // Check if team already has an active league
            if try await fetchActiveTeamLeague(teamId: league.teamId) != nil {
                throw AppError.dataCorrupted // Team already has an active league
            }
            
            try await client
                .from("team_leagues")
                .insert(league)
                .execute()
            
            print("CompetitionDataService: Team league created successfully")
            return league
        } catch {
            ErrorHandlingService.shared.logError(error, context: "createTeamLeague")
            throw error
        }
    }
    
    func completeTeamLeague(leagueId: String) async throws {
        print("CompetitionDataService: Completing team league \(leagueId)")
        
        do {
            try await client
                .from("team_leagues")
                .update(["status": "completed", "completed_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: leagueId)
                .execute()
            
            print("CompetitionDataService: Team league marked as completed")
        } catch {
            ErrorHandlingService.shared.logError(error, context: "completeTeamLeague")
            throw error
        }
    }
    
    func fetchTeamLeagueHistory(teamId: String, limit: Int = 10) async throws -> [TeamLeague] {
        do {
            let response = try await client
                .from("team_leagues")
                .select()
                .eq("team_id", value: teamId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode([TeamLeague].self, from: data)
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeamLeagueHistory")
            throw error
        }
    }
    
    func calculateLeaguePrizeDistribution(leagueId: String, teamWalletBalance: Int) async throws -> [LeaguePrizeDistribution] {
        print("CompetitionDataService: Calculating league prize distribution for league \(leagueId)")
        
        do {
            // Get the league details
            guard let league = try await fetchTeamLeague(leagueId: leagueId) else {
                throw AppError.dataCorrupted // League not found
            }
            
            // Get final team rankings for this league period using existing leaderboard method
            let teamLeaderboard = try await SupabaseService.shared.fetchTeamLeaderboard(teamId: league.teamId, type: "distance", period: "monthly")
            
            // Calculate prize distributions based on league payout structure
            var distributions: [LeaguePrizeDistribution] = []
            let payoutPercentages = league.payoutPercentages
            
            for (index, member) in teamLeaderboard.enumerated() {
                // Check if this rank qualifies for a prize
                guard index < payoutPercentages.count else {
                    break // No more prizes for lower ranks
                }
                
                // Calculate prize amount (index is 0-based, percentages correspond to ranks)
                let percentage = payoutPercentages[index]
                let prizeAmount = Int(Double(teamWalletBalance) * Double(percentage) / 100.0)
                
                let distribution = LeaguePrizeDistribution(
                    userId: member.userId,
                    leagueId: leagueId,
                    rank: index + 1, // Convert to 1-based rank
                    prizeAmount: prizeAmount,
                    distributedAt: Date()
                )
                
                distributions.append(distribution)
            }
            
            print("CompetitionDataService: Calculated \(distributions.count) prize distributions")
            return distributions
            
        } catch {
            ErrorHandlingService.shared.logError(error, context: "calculateLeaguePrizeDistribution")
            throw error
        }
    }
    
    private func fetchTeamLeague(leagueId: String) async throws -> TeamLeague? {
        do {
            let response = try await client
                .from("team_leagues")
                .select()
                .eq("id", value: leagueId)
                .single()
                .execute()
            
            let data = response.data
            return try SupabaseService.shared.customJSONDecoder().decode(TeamLeague.self, from: data)
        } catch {
            return nil
        }
    }
    
    func distributeLeaguePrizes(distributions: [LeaguePrizeDistribution], fromTeamWallet teamWalletId: String) async throws {
        print("CompetitionDataService: Distributing \(distributions.count) league prizes")
        
        // TODO: Integrate with LightningWalletManager to transfer from team wallet to user wallets
        // For now, create transaction records
        
        for distribution in distributions {
            do {
                let transaction = DatabaseTransaction(
                    id: UUID().uuidString,
                    userId: distribution.userId,
                    walletId: nil,
                    type: "league_prize",
                    amount: distribution.prizeAmount,
                    usdAmount: nil,
                    description: "Monthly league prize - Rank #\(distribution.rank)",
                    status: "completed",
                    transactionHash: nil,
                    preimage: nil,
                    processedAt: Date(),
                    createdAt: Date()
                )
                
                try await client
                    .from("transactions")
                    .insert(transaction)
                    .execute()
                
                print("CompetitionDataService: League prize distributed: \(distribution.prizeAmount) sats to user \(distribution.userId)")
            } catch {
                ErrorHandlingService.shared.logError(error, context: "distributeLeaguePrize", userId: distribution.userId)
                continue
            }
        }
        
        print("CompetitionDataService: League prize distribution completed")
    }
    
}

// MARK: - Models moved to top of file

// MARK: - Internal Data Models

struct TeamMemberRanking {
    let userId: String
    let username: String
    var rank: Int
    let totalPoints: Int
    let workoutCount: Int
    let totalDistance: Double
    let totalTime: Double
}

struct CompetitionStats {
    let eventId: String
    let totalParticipants: Int
    let completedParticipants: Int
    let averageProgress: Double
    let totalPrizePool: Int
    let distributedPrizes: Int
    let startDate: Date
    let endDate: Date
    let completionRate: Double
}

struct EventPrizeDistribution {
    let userId: String
    let eventId: String
    let rank: Int
    let prizeAmount: Int
    let distributedAt: Date
}

struct LeaguePrizeDistribution {
    let userId: String
    let leagueId: String
    let rank: Int
    let prizeAmount: Int
    let distributedAt: Date
}

// MARK: - Enums

enum CompetitionStreakType: String, Codable {
    case beginner = "beginner"     // 1-6 days
    case consistent = "consistent" // 7-20 days
    case dedicated = "dedicated"   // 21-49 days
    case legendary = "legendary"   // 50+ days
    
    var title: String {
        switch self {
        case .beginner: return "Getting Started"
        case .consistent: return "Building Habits"
        case .dedicated: return "Fitness Focused"
        case .legendary: return "Unstoppable"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .consistent: return "🔥"
        case .dedicated: return "💪"
        case .legendary: return "👑"
        }
    }
}

// MARK: - Local Supporting Models

struct CompetitionStreakData: Codable {
    let userId: String
    let currentStreak: Int
    let bestStreak: Int
    let lastWorkoutDate: Date
    let streakType: CompetitionStreakType
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStreak = "current_streak"
        case bestStreak = "best_streak"
        case lastWorkoutDate = "last_workout_date"
        case streakType = "streak_type"
    }
}