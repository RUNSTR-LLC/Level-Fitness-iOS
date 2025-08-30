import Foundation
import Supabase

// MARK: - P2P Challenge Models

// Progress data structure for database updates
struct P2PChallengeProgressData: Codable {
    var userProgress: [String: Double] = [:]
    var workouts: [String: [String: Double]] = [:]
    var streakDates: [String: [String]] = [:]
    
    init() {}
    
    init(from dictionary: [String: Any]) {
        if let progress = dictionary["userProgress"] as? [String: Double] {
            self.userProgress = progress
        }
        if let workouts = dictionary["workouts"] as? [String: [String: Double]] {
            self.workouts = workouts
        }
        if let streaks = dictionary["streakDates"] as? [String: [String]] {
            self.streakDates = streaks
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userProgress": userProgress,
            "workouts": workouts,
            "streakDates": streakDates
        ]
    }
}

struct P2PChallenge: Codable {
    let id: String
    let challengerId: String
    let challengedId: String
    let teamId: String
    let challengeType: P2PChallengeType
    let entryFee: Int // satoshis
    var status: P2PChallengeStatus
    let startDate: Date
    let endDate: Date
    let acceptDeadline: Date
    let conditions: P2PChallengeConditions
    var winnerId: String?
    var arbitrationStatus: P2PArbitrationStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengerId = "challenger_id"
        case challengedId = "challenged_id"
        case teamId = "team_id"
        case challengeType = "challenge_type"
        case entryFee = "entry_fee"
        case status
        case startDate = "start_date"
        case endDate = "end_date"
        case acceptDeadline = "accept_deadline"
        case conditions
        case winnerId = "winner_id"
        case arbitrationStatus = "arbitration_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum P2PChallengeType: String, Codable, CaseIterable {
    case distanceRace = "distance_race"
    case durationGoal = "duration_goal"
    case streakDays = "streak_days"
    case fastestTime = "fastest_time"
    
    var displayName: String {
        switch self {
        case .distanceRace:
            return "Distance Race"
        case .durationGoal:
            return "Duration Goal"
        case .streakDays:
            return "Workout Streak"
        case .fastestTime:
            return "Fastest Time"
        }
    }
    
    var description: String {
        switch self {
        case .distanceRace:
            return "First to reach target distance wins"
        case .durationGoal:
            return "Most total workout time wins"
        case .streakDays:
            return "Longest consecutive workout streak wins"
        case .fastestTime:
            return "Fastest time for specific distance wins"
        }
    }
}

enum P2PChallengeStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case active = "active"
    case completed = "completed"
    case declined = "declined"
    case expired = "expired"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .active:
            return "Active"
        case .completed:
            return "Completed"
        case .declined:
            return "Declined"
        case .expired:
            return "Expired"
        case .cancelled:
            return "Cancelled"
        }
    }
}

enum P2PArbitrationStatus: String, Codable {
    case notNeeded = "not_needed"
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .notNeeded:
            return "Not Needed"
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
}

struct P2PChallengeConditions: Codable {
    let targetValue: Double // distance in meters, duration in seconds, streak in days
    let unit: String // "meters", "seconds", "days"
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case targetValue = "target_value"
        case unit
        case description
    }
}

// Fixed stake amounts in satoshis
enum P2PChallengeStake: Int, CaseIterable {
    case small = 1000
    case medium = 5000
    case large = 10000
    
    var displayName: String {
        switch self {
        case .small:
            return "1,000 sats"
        case .medium:
            return "5,000 sats"
        case .large:
            return "10,000 sats"
        }
    }
    
    var satoshis: Int {
        return self.rawValue
    }
}

struct P2PChallengeProgress: Codable {
    let challengeId: String
    let userId: String
    let currentValue: Double
    let isCompleted: Bool
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case userId = "user_id"
        case currentValue = "current_value"
        case isCompleted = "is_completed"
        case lastUpdated = "last_updated"
    }
}

struct P2PChallengeParticipant: Codable {
    let userId: String
    let username: String
    let avatarUrl: String?
    let progress: P2PChallengeProgress?
    
    var displayProgress: String {
        guard let progress = progress else { return "0" }
        
        if progress.currentValue < 1000 {
            return String(format: "%.1f", progress.currentValue)
        } else {
            return String(format: "%.0f", progress.currentValue)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case userId
        case username
        case avatarUrl
        case progress
    }
}

struct P2PChallengeWithParticipants: Codable {
    let challenge: P2PChallenge
    let challenger: P2PChallengeParticipant
    let challenged: P2PChallengeParticipant
    
    var isActive: Bool {
        return challenge.status == .active
    }
    
    var needsArbitration: Bool {
        return challenge.status == .completed && challenge.arbitrationStatus == .pending
    }
    
    var timeRemaining: String {
        let now = Date()
        
        if challenge.status == .pending {
            let timeLeft = challenge.acceptDeadline.timeIntervalSince(now)
            if timeLeft > 0 {
                let hours = Int(timeLeft / 3600)
                return "\(hours)h to accept"
            } else {
                return "Expired"
            }
        } else if challenge.status == .active {
            let timeLeft = challenge.endDate.timeIntervalSince(now)
            if timeLeft > 0 {
                let days = Int(timeLeft / 86400)
                let hours = Int((timeLeft.truncatingRemainder(dividingBy: 86400)) / 3600)
                if days > 0 {
                    return "\(days)d \(hours)h left"
                } else {
                    return "\(hours)h left"
                }
            } else {
                return "Ended"
            }
        }
        
        return ""
    }
    
    enum CodingKeys: String, CodingKey {
        case challenge
        case challenger
        case challenged
    }
}

enum P2PChallengeOutcome: String, Codable {
    case challenger_wins = "challenger_wins"
    case challenged_wins = "challenged_wins"
    case tie = "tie"
    
    var displayName: String {
        switch self {
        case .challenger_wins: return "Challenger Wins"
        case .challenged_wins: return "Challenged Wins"
        case .tie: return "Tie"
        }
    }
}

struct ChallengeCompletionStatus {
    let needsArbitration: Bool
    let teamId: String?
    let winnerId: String?
    let outcome: P2PChallengeOutcome?
}

// MARK: - P2P Challenge Service

class P2PChallengeService {
    static let shared = P2PChallengeService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Challenge Creation
    
    func createChallenge(
        challengerId: String,
        challengedId: String,
        teamId: String,
        type: P2PChallengeType,
        stake: P2PChallengeStake,
        duration: Int, // days
        conditions: P2PChallengeConditions
    ) async throws -> P2PChallenge {
        
        print("🥊 P2PChallengeService: Creating challenge from \(challengerId) to \(challengedId)")
        
        // Validate inputs
        guard challengerId != challengedId else {
            throw P2PChallengeError.cannotChallengeSelf
        }
        
        guard duration >= 1 && duration <= 30 else {
            throw P2PChallengeError.invalidDuration
        }
        
        // Check if challenger has sufficient funds in team wallet
        let teamWalletBalance = try await TeamWalletManager.shared.getTeamWalletBalance(teamId: teamId)
        guard teamWalletBalance.total >= stake.satoshis else {
            throw P2PChallengeError.insufficientFunds
        }
        
        // Check if there's already an active challenge between these users
        let existingChallenges = try await getActiveChallengesBetweenUsers(user1: challengerId, user2: challengedId, teamId: teamId)
        guard existingChallenges.isEmpty else {
            throw P2PChallengeError.challengeAlreadyExists
        }
        
        let now = Date()
        let acceptDeadline = now.addingTimeInterval(24 * 60 * 60) // 24 hours
        let startDate = now
        let endDate = now.addingTimeInterval(Double(duration) * 24 * 60 * 60)
        
        let challengeId = UUID().uuidString
        
        let challenge = P2PChallenge(
            id: challengeId,
            challengerId: challengerId,
            challengedId: challengedId,
            teamId: teamId,
            challengeType: type,
            entryFee: stake.satoshis,
            status: .pending,
            startDate: startDate,
            endDate: endDate,
            acceptDeadline: acceptDeadline,
            conditions: conditions,
            winnerId: nil,
            arbitrationStatus: .notNeeded,
            createdAt: now,
            updatedAt: now
        )
        
        // Store challenge in database
        try await storeChallenge(challenge)
        
        // Lock challenger's stake in team wallet
        try await TeamWalletManager.shared.lockChallengeStake(challengeId: challengeId, amount: stake.satoshis, userId: challengerId, teamId: teamId)
        
        // Send notification to challenged user
        await NotificationService.shared.scheduleChallengeInvite(
            challengeId: challengeId,
            challengedUserId: challengedId,
            challengerUsername: "User", // Would get from database
            stake: stake.satoshis,
            type: type.displayName
        )
        
        print("✅ P2PChallengeService: Challenge created successfully - ID: \(challengeId)")
        return challenge
    }
    
    // MARK: - Challenge Response
    
    func acceptChallenge(challengeId: String, userId: String) async throws -> P2PChallenge {
        print("✅ P2PChallengeService: User \(userId) accepting challenge \(challengeId)")
        
        var challenge = try await getChallenge(challengeId: challengeId)
        
        guard challenge.challengedId == userId else {
            throw P2PChallengeError.notAuthorized
        }
        
        guard challenge.status == .pending else {
            throw P2PChallengeError.challengeNotPending
        }
        
        guard Date() <= challenge.acceptDeadline else {
            throw P2PChallengeError.challengeExpired
        }
        
        // Check if challenged user has sufficient funds in team wallet
        let teamWalletBalance = try await TeamWalletManager.shared.getTeamWalletBalance(teamId: challenge.teamId)
        guard teamWalletBalance.total >= challenge.entryFee else {
            throw P2PChallengeError.insufficientFunds
        }
        
        // Lock challenged user's stake
        try await TeamWalletManager.shared.lockChallengeStake(
            challengeId: challengeId,
            amount: challenge.entryFee,
            userId: userId,
            teamId: challenge.teamId
        )
        
        // Update challenge status
        challenge.status = .active
        try await updateChallenge(challenge)
        
        // Send notifications
        await NotificationService.shared.scheduleChallengeAccepted(
            challengeId: challengeId,
            challengerUserId: challenge.challengerId,
            challengedUsername: "User" // Would get from database
        )
        
        print("✅ P2PChallengeService: Challenge accepted successfully")
        return challenge
    }
    
    func declineChallenge(challengeId: String, userId: String) async throws -> P2PChallenge {
        print("❌ P2PChallengeService: User \(userId) declining challenge \(challengeId)")
        
        var challenge = try await getChallenge(challengeId: challengeId)
        
        guard challenge.challengedId == userId else {
            throw P2PChallengeError.notAuthorized
        }
        
        guard challenge.status == .pending else {
            throw P2PChallengeError.challengeNotPending
        }
        
        // Update challenge status
        challenge.status = .declined
        try await updateChallenge(challenge)
        
        // Refund challenger's stake
        try await TeamWalletManager.shared.refundChallenge(
            challengeId: challengeId,
            userId: challenge.challengerId,
            amount: challenge.entryFee,
            teamId: challenge.teamId
        )
        
        // Send notification to challenger
        await NotificationService.shared.scheduleChallengeDeclined(
            challengeId: challengeId,
            challengerUserId: challenge.challengerId,
            challengedUsername: "User" // Would get from database
        )
        
        print("✅ P2PChallengeService: Challenge declined successfully")
        return challenge
    }
    
    // MARK: - Challenge Progress
    
    func updateChallengeProgress(challengeId: String) async throws {
        print("📊 P2PChallengeService: Updating progress for challenge \(challengeId)")
        
        let challenge = try await getChallenge(challengeId: challengeId)
        guard challenge.status == .active else { return }
        
        // Get workout data for both participants since challenge start
        let challengerProgress = try await calculateProgress(
            userId: challenge.challengerId,
            challenge: challenge
        )
        
        let challengedProgress = try await calculateProgress(
            userId: challenge.challengedId,
            challenge: challenge
        )
        
        // Check if challenge is complete
        let now = Date()
        let isTimeExpired = now >= challenge.endDate
        let hasWinner = challengerProgress.isCompleted || challengedProgress.isCompleted
        
        if isTimeExpired || hasWinner {
            try await completeChallenge(challenge, challengerProgress: challengerProgress, challengedProgress: challengedProgress)
        }
    }
    
    private func calculateProgress(userId: String, challenge: P2PChallenge) async throws -> P2PChallengeProgress {
        // Fetch all workouts for the user and filter by date range
        let allWorkouts = try await WorkoutDataService.shared.fetchWorkouts(userId: userId, limit: 100)
        let workouts = allWorkouts.filter { workout in
            workout.startedAt >= challenge.startDate && 
            workout.startedAt <= min(Date(), challenge.endDate)
        }
        
        var currentValue: Double = 0
        var isCompleted = false
        
        switch challenge.challengeType {
        case .distanceRace:
            currentValue = workouts.compactMap { $0.distance }.reduce(0, +)
            isCompleted = currentValue >= challenge.conditions.targetValue
            
        case .durationGoal:
            currentValue = Double(workouts.map { $0.duration }.reduce(0, +))
            isCompleted = currentValue >= challenge.conditions.targetValue
            
        case .streakDays:
            currentValue = Double(calculateWorkoutStreak(workouts: workouts, startDate: challenge.startDate))
            isCompleted = currentValue >= challenge.conditions.targetValue
            
        case .fastestTime:
            // Find fastest time for target distance
            let targetDistance = challenge.conditions.targetValue
            let qualifyingWorkouts = workouts.filter { 
                ($0.distance ?? 0) >= targetDistance * 0.95 // Allow 5% tolerance
            }
            
            if let fastestTime = qualifyingWorkouts.map({ $0.duration }).min() {
                currentValue = Double(fastestTime)
                isCompleted = currentValue <= challenge.conditions.targetValue
            }
        }
        
        return P2PChallengeProgress(
            challengeId: challenge.id,
            userId: userId,
            currentValue: currentValue,
            isCompleted: isCompleted,
            lastUpdated: Date()
        )
    }
    
    private func calculateWorkoutStreak(workouts: [Workout], startDate: Date) -> Int {
        let calendar = Calendar.current
        let sortedWorkouts = workouts.sorted { $0.startedAt < $1.startedAt }
        
        var streak = 0
        var currentDate = startDate
        let endDate = Date()
        
        while currentDate <= endDate {
            let hasWorkoutOnDate = sortedWorkouts.contains { workout in
                calendar.isDate(workout.startedAt, inSameDayAs: currentDate)
            }
            
            if hasWorkoutOnDate {
                streak += 1
            } else {
                break
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func completeChallenge(
        _ challenge: P2PChallenge,
        challengerProgress: P2PChallengeProgress,
        challengedProgress: P2PChallengeProgress
    ) async throws {
        
        var updatedChallenge = challenge
        updatedChallenge.status = .completed
        updatedChallenge.arbitrationStatus = .pending
        
        // For now, all completed challenges go to captain arbitration
        // In the future, we could add automatic winner detection for clear cases
        
        try await updateChallenge(updatedChallenge)
        
        // Notify team captain about arbitration needed
        guard let teamData = try await TeamDataService.shared.getTeam(challenge.teamId) else {
            throw P2PChallengeError.teamNotFound
        }
        await NotificationService.shared.scheduleArbitrationRequest(
            challengeId: challenge.id,
            captainId: teamData.captainId
        )
        
        print("🏁 P2PChallengeService: Challenge completed, arbitration requested")
    }
    
    // MARK: - Captain Arbitration
    
    func arbitrateChallenge(challengeId: String, winnerId: String, captainId: String) async throws {
        print("⚖️ P2PChallengeService: Captain \(captainId) arbitrating challenge \(challengeId)")
        
        var challenge = try await getChallenge(challengeId: challengeId)
        
        guard challenge.status == .completed else {
            throw P2PChallengeError.challengeNotComplete
        }
        
        guard challenge.arbitrationStatus == .pending else {
            throw P2PChallengeError.arbitrationNotPending
        }
        
        // Verify captain has permission
        guard let teamData = try await TeamDataService.shared.getTeam(challenge.teamId) else {
            throw P2PChallengeError.teamNotFound
        }
        guard teamData.captainId == captainId else {
            throw P2PChallengeError.notAuthorized
        }
        
        guard winnerId == challenge.challengerId || winnerId == challenge.challengedId else {
            throw P2PChallengeError.invalidWinner
        }
        
        // Update challenge with winner
        challenge.winnerId = winnerId
        challenge.arbitrationStatus = .completed
        try await updateChallenge(challenge)
        
        // Distribute funds: 80% to winner, 20% to team
        let totalStake = challenge.entryFee * 2 // Both participants staked
        let winnerAmount = Int(Double(totalStake) * 0.8)
        let teamFee = totalStake - winnerAmount
        
        try await TeamWalletManager.shared.distributeChallengeReward(
            challengeId: challengeId,
            winnerId: winnerId,
            winnerAmount: winnerAmount,
            teamFee: teamFee,
            teamId: challenge.teamId
        )
        
        // Send notifications
        await NotificationService.shared.scheduleChallengeComplete(
            challengeId: challengeId,
            winnerId: winnerId,
            amount: winnerAmount,
            challengeType: challenge.challengeType.displayName
        )
        
        print("✅ P2PChallengeService: Challenge arbitration completed")
    }
    
    // MARK: - Data Access
    
    func getTeamChallenges(teamId: String, limit: Int = 20) async throws -> [P2PChallengeWithParticipants] {
        let response: [P2PChallenge] = try await client
            .from("p2p_challenges")
            .select("*")
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return try await withThrowingTaskGroup(of: P2PChallengeWithParticipants?.self) { group in
            var results: [P2PChallengeWithParticipants] = []
            
            for challenge in response {
                group.addTask {
                    return try await self.getChallengeWithParticipants(challenge)
                }
            }
            
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            return results.sorted { $0.challenge.createdAt > $1.challenge.createdAt }
        }
    }
    
    func getUserActiveChallenges(userId: String) async throws -> [P2PChallengeWithParticipants] {
        let response: [P2PChallenge] = try await client
            .from("p2p_challenges")
            .select("*")
            .or("challenger_id.eq.\(userId),challenged_id.eq.\(userId)")
            .in("status", values: ["pending", "active"])
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return try await withThrowingTaskGroup(of: P2PChallengeWithParticipants?.self) { group in
            var results: [P2PChallengeWithParticipants] = []
            
            for challenge in response {
                group.addTask {
                    return try await self.getChallengeWithParticipants(challenge)
                }
            }
            
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            return results
        }
    }
    
    func getPendingArbitrations(captainId: String) async throws -> [P2PChallengeWithParticipants] {
        // First get team IDs where user is captain
        let teamData: [Team] = try await client
            .from("teams")
            .select("*")
            .eq("captain_id", value: captainId)
            .execute()
            .value
        
        let teamIds = teamData.map { $0.id }
        
        guard !teamIds.isEmpty else { return [] }
        
        let response: [P2PChallenge] = try await client
            .from("p2p_challenges")
            .select("*")
            .in("team_id", values: teamIds)
            .eq("status", value: "completed")
            .eq("arbitration_status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return try await withThrowingTaskGroup(of: P2PChallengeWithParticipants?.self) { group in
            var results: [P2PChallengeWithParticipants] = []
            
            for challenge in response {
                group.addTask {
                    return try await self.getChallengeWithParticipants(challenge)
                }
            }
            
            for try await result in group {
                if let result = result {
                    results.append(result)
                }
            }
            
            return results
        }
    }
    
    // MARK: - Private Helpers
    
    private func getChallenge(challengeId: String) async throws -> P2PChallenge {
        let response: [P2PChallenge] = try await client
            .from("p2p_challenges")
            .select("*")
            .eq("id", value: challengeId)
            .execute()
            .value
        
        guard let challenge = response.first else {
            throw P2PChallengeError.challengeNotFound
        }
        
        return challenge
    }
    
    private func getChallengeWithParticipants(_ challenge: P2PChallenge) async throws -> P2PChallengeWithParticipants? {
        // Get participant profiles
        async let challengerProfile = getUserProfile(userId: challenge.challengerId)
        async let challengedProfile = getUserProfile(userId: challenge.challengedId)
        
        guard let challenger = try await challengerProfile,
              let challenged = try await challengedProfile else {
            return nil
        }
        
        // Get progress if challenge is active
        var challengerProgress: P2PChallengeProgress?
        var challengedProgress: P2PChallengeProgress?
        
        if challenge.status == .active {
            challengerProgress = try? await calculateProgress(userId: challenge.challengerId, challenge: challenge)
            challengedProgress = try? await calculateProgress(userId: challenge.challengedId, challenge: challenge)
        }
        
        let challengerParticipant = P2PChallengeParticipant(
            userId: challenger.id,
            username: challenger.username ?? "Unknown",
            avatarUrl: challenger.avatarUrl,
            progress: challengerProgress
        )
        
        let challengedParticipant = P2PChallengeParticipant(
            userId: challenged.id,
            username: challenged.username ?? "Unknown",
            avatarUrl: challenged.avatarUrl,
            progress: challengedProgress
        )
        
        return P2PChallengeWithParticipants(
            challenge: challenge,
            challenger: challengerParticipant,
            challenged: challengedParticipant
        )
    }
    
    private func getUserProfile(userId: String) async throws -> UserProfile? {
        let response: [UserProfile] = try await client
            .from("profiles")
            .select("*")
            .eq("id", value: userId)
            .execute()
            .value
        
        return response.first
    }
    
    private func storeChallenge(_ challenge: P2PChallenge) async throws {
        try await client
            .from("p2p_challenges")
            .insert(challenge)
            .execute()
    }
    
    private func updateChallenge(_ challenge: P2PChallenge) async throws {
        try await client
            .from("p2p_challenges")
            .update(challenge)
            .eq("id", value: challenge.id)
            .execute()
    }
    
    private func getActiveChallengesBetweenUsers(user1: String, user2: String, teamId: String) async throws -> [P2PChallenge] {
        let response: [P2PChallenge] = try await client
            .from("p2p_challenges")
            .select("*")
            .eq("team_id", value: teamId)
            .or("and(challenger_id.eq.\(user1),challenged_id.eq.\(user2)),and(challenger_id.eq.\(user2),challenged_id.eq.\(user1))")
            .in("status", values: ["pending", "accepted", "active"])
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Progress Tracking Methods
    
    func getActiveUserChallenges(userId: String) async throws -> [P2PChallengeWithParticipants] {
        print("🔄 P2PChallengeService: Getting active challenges for user \(userId)")
        
        let response = try await client
            .from("p2p_challenges")
            .select("""
                *,
                challenger:challenger_id(id, username, email),
                challenged:challenged_id(id, username, email)
            """)
            .or("challenger_id.eq.\(userId),challenged_id.eq.\(userId)")
            .eq("status", value: "active")
            .execute()
        
        let challenges = try JSONDecoder().decode([P2PChallengeWithParticipants].self, from: response.data)
        print("✅ P2PChallengeService: Found \(challenges.count) active challenges for user")
        
        return challenges
    }
    
    func updateChallengeProgress(challengeId: String, userId: String, progressValue: Double, workoutId: String) async throws {
        print("📊 P2PChallengeService: Updating progress for challenge \(challengeId), user \(userId): +\(progressValue)")
        
        // First get current progress data
        let response = try await client
            .from("p2p_challenges")
            .select("progress_data")
            .eq("id", value: challengeId)
            .single()
            .execute()
        
        let challengeData = try JSONDecoder().decode([String: AnyCodable].self, from: response.data)
        let existingData = challengeData["progress_data"]?.value as? [String: Any] ?? [:]
        
        // Create or update progress data using the struct
        var progressData = P2PChallengeProgressData(from: existingData)
        
        // Update user's cumulative progress
        let currentProgress = progressData.userProgress[userId] ?? 0.0
        let newProgress = currentProgress + progressValue
        progressData.userProgress[userId] = newProgress
        
        // Record this workout contribution
        if progressData.workouts[userId] == nil {
            progressData.workouts[userId] = [:]
        }
        progressData.workouts[userId]![workoutId] = progressValue
        
        // Update the challenge with proper Codable struct
        try await client
            .from("p2p_challenges")
            .update(["progress_data": progressData])
            .eq("id", value: challengeId)
            .execute()
        
        print("✅ P2PChallengeService: Progress updated - user now has \(newProgress)")
    }
    
    func updateStreakProgress(challengeId: String, userId: String, workoutDate: Date, workoutId: String) async throws {
        print("🔥 P2PChallengeService: Updating streak progress for challenge \(challengeId), user \(userId)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: workoutDate)
        
        // Get current progress data
        let response = try await client
            .from("p2p_challenges")
            .select("progress_data")
            .eq("id", value: challengeId)
            .single()
            .execute()
        
        let challengeData = try JSONDecoder().decode([String: AnyCodable].self, from: response.data)
        let existingData = challengeData["progress_data"]?.value as? [String: Any] ?? [:]
        
        // Create or update progress data using the struct
        var progressData = P2PChallengeProgressData(from: existingData)
        
        // Track active days for user
        var activeDays = progressData.streakDates[userId] ?? []
        
        // Add today if not already recorded
        if !activeDays.contains(dateKey) {
            activeDays.append(dateKey)
            activeDays.sort()
        }
        
        // Calculate current streak
        let currentStreak = calculateCurrentStreak(from: activeDays)
        
        // Update streak dates
        progressData.streakDates[userId] = activeDays
        progressData.userProgress[userId] = Double(currentStreak)
        
        // Record this workout
        if progressData.workouts[userId] == nil {
            progressData.workouts[userId] = [:]
        }
        progressData.workouts[userId]![workoutId] = 1.0  // Just mark as completed
        
        // Update the challenge with proper Codable struct
        try await client
            .from("p2p_challenges")
            .update(["progress_data": progressData])
            .eq("id", value: challengeId)
            .execute()
        
        print("✅ P2PChallengeService: Streak updated - user now has \(currentStreak) day streak")
    }
    
    func updateFastestTimeProgress(challengeId: String, userId: String, timePerKm: Double, workoutId: String) async throws {
        print("⚡ P2PChallengeService: Updating fastest time for challenge \(challengeId), user \(userId): \(timePerKm)s/km")
        
        // Get current progress data
        let response = try await client
            .from("p2p_challenges")
            .select("progress_data")
            .eq("id", value: challengeId)
            .single()
            .execute()
        
        let challengeData = try JSONDecoder().decode([String: AnyCodable].self, from: response.data)
        let existingData = challengeData["progress_data"]?.value as? [String: Any] ?? [:]
        
        // Create or update progress data using the struct
        var progressData = P2PChallengeProgressData(from: existingData)
        
        // Check if this is a personal best for the user
        let currentBest = progressData.userProgress[userId]
        let isNewBest = currentBest == nil || timePerKm < currentBest!
        
        if isNewBest {
            progressData.userProgress[userId] = timePerKm
            
            // Track workout that set this record
            if progressData.workouts[userId] == nil {
                progressData.workouts[userId] = [:]
            }
            progressData.workouts[userId]![workoutId] = timePerKm
            
            // Update the challenge with proper Codable struct
            try await client
                .from("p2p_challenges")
                .update(["progress_data": progressData])
                .eq("id", value: challengeId)
                .execute()
            
            print("🏆 P2PChallengeService: New personal best! \(timePerKm)s/km")
        } else {
            print("📊 P2PChallengeService: Time not a personal best, current best: \(currentBest!)s/km")
        }
    }
    
    func checkChallengeCompletion(challengeId: String) async throws -> ChallengeCompletionStatus {
        print("🏁 P2PChallengeService: Checking completion status for challenge \(challengeId)")
        
        // Get the challenge with progress data
        let response = try await client
            .from("p2p_challenges")
            .select("*")
            .eq("id", value: challengeId)
            .single()
            .execute()
        
        let challengeData = try JSONDecoder().decode([String: AnyCodable].self, from: response.data)
        
        // Extract challenge details
        let challengeId = challengeData["id"]?.value as? String ?? ""
        let challengerId = challengeData["challenger_id"]?.value as? String ?? ""
        let challengedId = challengeData["challenged_id"]?.value as? String ?? ""
        let teamId = challengeData["team_id"]?.value as? String ?? ""
        let duration = challengeData["duration"]?.value as? Int ?? 7
        let createdAtStr = challengeData["created_at"]?.value as? String ?? ""
        let typeStr = challengeData["type"]?.value as? String ?? "distance_race"
        let conditionsData = challengeData["conditions"]?.value as? [String: Any] ?? [:]
        let progressData = challengeData["progress_data"]?.value as? [String: Any] ?? [:]
        
        // Parse created_at date
        let createdAt = ISO8601DateFormatter().date(from: createdAtStr) ?? Date()
        
        // Check if challenge duration has expired
        let endDate = Calendar.current.date(byAdding: .day, value: duration, to: createdAt) ?? Date()
        let hasExpired = Date() > endDate
        
        if hasExpired {
            print("⏰ P2PChallengeService: Challenge has expired, needs arbitration")
            return ChallengeCompletionStatus(
                needsArbitration: true,
                teamId: teamId,
                winnerId: nil,
                outcome: nil
            )
        }
        
        // Check challenge-specific completion criteria
        let challengeType = P2PChallengeType(rawValue: typeStr) ?? .distanceRace
        
        switch challengeType {
        case .distanceRace, .durationGoal:
            // Check if anyone has reached the goal
            let targetValue = conditionsData["targetValue"] as? Double ?? 0
            let challengerProgress = progressData[challengerId] as? Double ?? 0
            let challengedProgress = progressData[challengedId] as? Double ?? 0
            
            if challengerProgress >= targetValue || challengedProgress >= targetValue {
                print("🎯 P2PChallengeService: Goal reached, needs arbitration")
                return ChallengeCompletionStatus(
                    needsArbitration: true,
                    teamId: teamId,
                    winnerId: challengerProgress >= targetValue ? challengerId : challengedId,
                    outcome: challengerProgress >= targetValue ? .challenger_wins : .challenged_wins
                )
            }
            
        case .streakDays:
            // Check if anyone has reached the streak goal
            let targetStreak = Int(conditionsData["targetValue"] as? Double ?? 0)
            let challengerData = progressData[challengerId] as? [String: Any] ?? [:]
            let challengedData = progressData[challengedId] as? [String: Any] ?? [:]
            let challengerStreak = challengerData["current_streak"] as? Int ?? 0
            let challengedStreak = challengedData["current_streak"] as? Int ?? 0
            
            if challengerStreak >= targetStreak || challengedStreak >= targetStreak {
                print("🔥 P2PChallengeService: Streak goal reached, needs arbitration")
                return ChallengeCompletionStatus(
                    needsArbitration: true,
                    teamId: teamId,
                    winnerId: challengerStreak >= targetStreak ? challengerId : challengedId,
                    outcome: challengerStreak >= targetStreak ? .challenger_wins : .challenged_wins
                )
            }
            
        case .fastestTime:
            // Fastest time challenges complete when duration expires (always need arbitration)
            break
        }
        
        // Challenge is still active
        return ChallengeCompletionStatus(
            needsArbitration: false,
            teamId: teamId,
            winnerId: nil,
            outcome: nil
        )
    }
    
    func moveToArbitration(challengeId: String) async throws {
        print("⚖️ P2PChallengeService: Moving challenge \(challengeId) to arbitration")
        
        try await client
            .from("p2p_challenges")
            .update(["status": "needs_arbitration"])
            .eq("id", value: challengeId)
            .execute()
        
        print("✅ P2PChallengeService: Challenge moved to arbitration status")
    }
    
    // MARK: - Helper Methods
    
    private func calculateCurrentStreak(from activeDays: [String]) -> Int {
        guard !activeDays.isEmpty else { return 0 }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Convert strings to dates and sort
        let dates = activeDays.compactMap { dateFormatter.date(from: $0) }.sorted()
        
        var currentStreak = 0
        let calendar = Calendar.current
        let todayDate = Date()
        
        // Count backwards from today to find consecutive days
        for i in stride(from: 0, to: dates.count, by: 1) {
            let checkDate = calendar.date(byAdding: .day, value: -i, to: todayDate)!
            let checkDateString = dateFormatter.string(from: checkDate)
            
            if activeDays.contains(checkDateString) {
                currentStreak += 1
            } else {
                break
            }
        }
        
        return currentStreak
    }
}

// MARK: - Error Types

enum P2PChallengeError: LocalizedError {
    case cannotChallengeSelf
    case invalidDuration
    case insufficientFunds
    case challengeAlreadyExists
    case challengeNotFound
    case challengeNotPending
    case challengeExpired
    case challengeNotComplete
    case arbitrationNotPending
    case notAuthorized
    case teamNotFound
    case invalidWinner
    
    var errorDescription: String? {
        switch self {
        case .cannotChallengeSelf:
            return "You cannot challenge yourself"
        case .invalidDuration:
            return "Challenge duration must be between 1 and 30 days"
        case .insufficientFunds:
            return "Insufficient funds in team wallet"
        case .challengeAlreadyExists:
            return "Active challenge already exists between these users"
        case .challengeNotFound:
            return "Challenge not found"
        case .challengeNotPending:
            return "Challenge is not pending"
        case .challengeExpired:
            return "Challenge has expired"
        case .challengeNotComplete:
            return "Challenge is not complete"
        case .arbitrationNotPending:
            return "Arbitration is not pending"
        case .notAuthorized:
            return "Not authorized to perform this action"
        case .teamNotFound:
            return "Team not found"
        case .invalidWinner:
            return "Invalid winner selection"
        }
    }
}