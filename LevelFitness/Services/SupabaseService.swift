import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    // Supabase project credentials
    private let supabaseURL = "https://cqhlwoguxbwnqdternci.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxaGx3b2d1eGJ3bnFkdGVybmNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3ODA4NTgsImV4cCI6MjA3MDM1Njg1OH0.vnA3CFYBeyCXr0tvGCGDcaD_9PXOeBjhwfT2AaWqO-8"
    
    private var client: SupabaseClient!
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
        
        print("SupabaseService: Client initialized successfully")
    }
    
    // MARK: - Authentication Methods
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserSession? {
        let response = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        
        // TODO: Fix Supabase API compatibility
        return UserSession(
            id: response.user.id.uuidString,
            email: response.user.email,
            accessToken: "temp_token",
            refreshToken: "temp_refresh_token"
        )
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> UserSession? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        
        let user = try await client.auth.user()
        
        return UserSession(
            id: user.id.uuidString,
            email: user.email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
    }
    
    // MARK: - Database Methods
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        // Clean the user ID of any quotes that might have been passed incorrectly
        let cleanUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedUserProfile() {
                print("SupabaseService: Using cached user profile (offline)")
                return cached
            }
            throw AppError.networkUnavailable
        }
        
        do {
            let response = try await client
                .from("profiles")
                .select()
                .eq("id", value: cleanUserId)
                .single()
                .execute()
            
            let data = response.data
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheUserProfile(profile)
            
            return profile
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchUserProfile", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedUserProfile() {
                print("SupabaseService: Using cached user profile (error fallback)")
                return cached
            }
            
            throw error
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    
    func fetchTeams() async throws -> [Team] {
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("SupabaseService: Using cached teams (offline)")
                return cached
            }
            throw AppError.networkUnavailable
        }
        
        do {
            let response = try await client
                .from("teams")
                .select()
                .execute()
            
            let data = response.data
            let teams = try JSONDecoder().decode([Team].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTeams(teams)
            
            return teams
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeams")
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("SupabaseService: Using cached teams (error fallback)")
                return cached
            }
            
            throw error
        }
    }
    
    func createTeam(_ team: Team) async throws -> Team {
        let response = try await client
            .from("teams")
            .insert(team)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(Team.self, from: data)
    }
    
    func joinTeam(teamId: String, userId: String) async throws {
        let teamMember = TeamMember(
            teamId: teamId,
            userId: userId,
            role: "member",
            joinedAt: Date()
        )
        
        try await client
            .from("team_members")
            .insert(teamMember)
            .execute()
    }
    
    func syncWorkout(_ workout: Workout) async throws {
        // If offline, queue the workout sync
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            OfflineDataService.shared.queueWorkoutSync(workout)
            print("🏃‍♂️ SupabaseService: Queued workout sync (offline): \(workout.id)")
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
                print("🏃‍♂️ SupabaseService: New workout synced: \(workout.id)")
            } else {
                // Update existing workout
                try await client
                    .from("workouts")
                    .update(workout)
                    .eq("id", value: workout.id)
                    .execute()
                print("🏃‍♂️ SupabaseService: Existing workout updated: \(workout.id)")
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
                print("SupabaseService: Using cached workouts (offline)")
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
            let workouts = try JSONDecoder().decode([Workout].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheWorkouts(workouts)
            
            return workouts
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchWorkouts", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedWorkouts() {
                print("SupabaseService: Using cached workouts (error fallback)")
                return Array(cached.prefix(limit))
            }
            
            throw error
        }
    }
    
    
    // MARK: - Competition Events Methods
    
    func fetchEvents(status: String = "active") async throws -> [CompetitionEvent] {
        let response = try await client
            .from("events")
            .select()
            .eq("status", value: status)
            .order("start_date", ascending: true)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([CompetitionEvent].self, from: data)
    }
    
    func joinEvent(eventId: String, userId: String) async throws {
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
    }
    
    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        let response = try await client
            .from("event_participants")
            .select()
            .eq("event_id", value: eventId)
            .order("progress", ascending: false)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([EventParticipant].self, from: data)
    }
    
    // MARK: - Team Chat Methods
    
    func fetchTeamMessages(teamId: String, limit: Int = 50) async throws -> [TeamMessage] {
        let response = try await client
            .from("team_messages")
            .select("*, profiles(username, avatar_url)")
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([TeamMessage].self, from: data)
    }
    
    func sendTeamMessage(teamId: String, userId: String, message: String, messageType: String = "text") async throws {
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
    }
    
    // MARK: - Challenge Methods
    
    func fetchChallenges(teamId: String? = nil) async throws -> [Challenge] {
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
        return try JSONDecoder().decode([Challenge].self, from: data)
    }
    
    func joinChallenge(challengeId: String, userId: String) async throws {
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
    }
    
    // MARK: - Leaderboard Methods
    
    func fetchWeeklyLeaderboard() async throws -> [LeaderboardEntry] {
        let response = try await client
            .from("weekly_leaderboard")
            .select()
            .order("rank", ascending: true)
            .limit(100)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([LeaderboardEntry].self, from: data)
    }
    
    func fetchTeamLeaderboard() async throws -> [TeamLeaderboardEntry] {
        let response = try await client
            .from("team_leaderboard")
            .select()
            .order("rank", ascending: true)
            .limit(50)
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode([TeamLeaderboardEntry].self, from: data)
    }
    
    // MARK: - Lightning Wallet Methods
    
    func createLightningWallet(userId: String, provider: String, walletId: String, address: String) async throws -> SupabaseLightningWallet {
        let wallet = SupabaseLightningWallet(
            id: UUID().uuidString,
            userId: userId,
            provider: provider,
            walletId: walletId,
            address: address,
            balance: 0,
            credentialsEncrypted: nil,
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let response = try await client
            .from("lightning_wallets")
            .insert(wallet)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(SupabaseLightningWallet.self, from: data)
    }
    
    func fetchLightningWallet(userId: String) async throws -> SupabaseLightningWallet? {
        let response = try await client
            .from("lightning_wallets")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(SupabaseLightningWallet.self, from: data)
    }
    
    func fetchTransactions(userId: String, limit: Int = 50) async throws -> [DatabaseTransaction] {
        // Clean the user ID of any quotes that might have been passed incorrectly
        let cleanUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTransactions() {
                print("SupabaseService: Using cached transactions (offline)")
                return Array(cached.prefix(limit))
            }
            throw AppError.networkUnavailable
        }
        
        do {
            print("SupabaseService: Fetching transactions for user ID: \(cleanUserId)")
            
            let response = try await client
                .from("transactions")
                .select()
                .eq("user_id", value: cleanUserId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
            
            let data = response.data
            let transactions = try JSONDecoder().decode([DatabaseTransaction].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTransactions(transactions)
            
            return transactions
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTransactions", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTransactions() {
                print("SupabaseService: Using cached transactions (error fallback)")
                return Array(cached.prefix(limit))
            }
            
            throw error
        }
    }
    
    func createTransaction(userId: String, type: String, amount: Int, description: String) async throws -> DatabaseTransaction {
        let transaction = DatabaseTransaction(
            id: UUID().uuidString,
            userId: userId,
            walletId: nil,
            type: type,
            amount: amount,
            usdAmount: nil,
            description: description,
            status: "pending",
            transactionHash: nil,
            preimage: nil,
            processedAt: nil,
            createdAt: Date()
        )
        
        let response = try await client
            .from("transactions")
            .insert(transaction)
            .select()
            .single()
            .execute()
        
        let data = response.data
        return try JSONDecoder().decode(DatabaseTransaction.self, from: data)
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToTeamUpdates(teamId: String, onUpdate: @escaping (Team) -> Void) {
        let channel = client.channel("team-\(teamId)")
        
        // Note: Realtime subscriptions would be implemented here
        // For now, we'll use a simple callback mechanism
        Task {
            // Simulate real-time updates
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            onUpdate(Team(
                id: teamId, 
                name: "Updated Team", 
                description: "Team updated", 
                captainId: "captain-123",
                memberCount: 0, 
                totalEarnings: 0.0,
                imageUrl: nil,
                createdAt: Date()
            ))
        }
    }
    
    func subscribeToLeaderboard(onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        let channel = client.channel("leaderboard")
        
        // Note: Realtime subscriptions would be implemented here
        // For now, we'll use a simple callback mechanism
        Task {
            // Simulate real-time updates
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            // In a real implementation, you'd fetch the leaderboard data here
            print("Leaderboard update triggered by workout change")
            onUpdate([])
        }
    }
    
    func subscribeToTeamChat(teamId: String, onNewMessage: @escaping (TeamMessage) -> Void) {
        let channel = client.channel("team-chat-\(teamId)")
        
        // TODO: Implement real Supabase realtime subscriptions
        // channel.on("INSERT", filter: "team_id=eq.\(teamId)") { message in
        //     if let payload = message.payload["new"] as? [String: Any] {
        //         // Parse and return new message
        //     }
        // }
        
        // For now, simulate real-time chat updates
        Task {
            while true {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                
                // Simulate new message
                let simulatedMessage = TeamMessage(
                    id: UUID().uuidString,
                    teamId: teamId,
                    userId: "user-\(Int.random(in: 1...100))",
                    message: "New message from real-time subscription!",
                    messageType: "text",
                    edited: false,
                    editedAt: nil,
                    createdAt: Date(),
                    username: "@realtime_user",
                    avatarUrl: nil
                )
                
                onNewMessage(simulatedMessage)
            }
        }
    }
}

// MARK: - Data Models

struct UserSession: Codable {
    let id: String
    let email: String?
    let accessToken: String
    let refreshToken: String
}

struct UserProfile: Codable {
    let id: String
    let email: String?
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let totalWorkouts: Int
    let totalDistance: Double
    let totalEarnings: Double
    let createdAt: Date
    let updatedAt: Date
}

struct Team: Codable {
    let id: String
    let name: String
    let description: String?
    let captainId: String
    let memberCount: Int
    let totalEarnings: Double
    let imageUrl: String?
    let createdAt: Date
}

struct TeamMember: Codable {
    let teamId: String
    let userId: String
    let role: String
    let joinedAt: Date
}

struct Workout: Codable {
    let id: String
    let userId: String
    let type: String
    let duration: Int // seconds
    let distance: Double? // meters
    let calories: Int?
    let heartRate: Int?
    let source: String // "healthkit", "strava", etc.
    let startedAt: Date
    let endedAt: Date
    let syncedAt: Date
}

struct LeaderboardEntry: Codable {
    let userId: String
    let username: String
    let rank: Int
    let points: Int
    let workoutCount: Int
    let totalDistance: Double
}

// MARK: - Enhanced Data Models

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
        case id, name, description, type, unit, status, createdAt
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

struct SupabaseLightningWallet: Codable {
    let id: String
    let userId: String
    let provider: String
    let walletId: String
    let address: String
    let balance: Int
    let credentialsEncrypted: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, provider, address, balance, status
        case userId = "user_id"
        case walletId = "wallet_id"
        case credentialsEncrypted = "credentials_encrypted"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DatabaseTransaction: Codable {
    let id: String
    let userId: String
    let walletId: String?
    let type: String
    let amount: Int
    let usdAmount: Double?
    let description: String?
    let status: String
    let transactionHash: String?
    let preimage: String?
    let processedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, amount, description, status, preimage
        case userId = "user_id"
        case walletId = "wallet_id"
        case usdAmount = "usd_amount"
        case transactionHash = "transaction_hash"
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }
}