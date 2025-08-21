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
    
    // MARK: - JSON Decoding Helper
    
    func customJSONDecoder() -> JSONDecoder {
        return createSupabaseDecoder()
    }
    
    private func createSupabaseDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // First try ISO8601DateFormatter which handles most common formats efficiently
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to ISO8601 without fractional seconds
            iso8601Formatter.formatOptions = [.withInternetDateTime]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Final fallback for edge cases
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            fallbackFormatter.timeZone = TimeZone(abbreviation: "UTC")
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to parse date: \(dateString)")
        }
        return decoder
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
        
        // Use real Supabase session tokens for proper authentication
        return UserSession(
            id: response.user.id.uuidString,
            email: response.user.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
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
    
    func restoreSession(accessToken: String, refreshToken: String) async throws {
        // Restore the Supabase session using stored tokens
        print("SupabaseService: Attempting to restore session with tokens: \(accessToken.prefix(10))..., \(refreshToken.prefix(10))...")
        try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        print("SupabaseService: Session restored successfully")
        
        // Verify the session was restored
        if let session = try? await client.auth.session {
            print("SupabaseService: Verified session exists for user: \(session.user.id)")
        } else {
            print("SupabaseService: Warning - No session found after restoration")
        }
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
    
    func syncLocalProfileToSupabase(userId: String, username: String?, fullName: String?) async throws {
        print("SupabaseService: Syncing local profile data to Supabase for user: \(userId)")
        
        // Create a proper Encodable struct for the update
        struct ProfileUpdate: Encodable {
            let username: String?
            let fullName: String?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case username
                case fullName = "full_name"
                case updatedAt = "updated_at"
            }
        }
        
        let updateData = ProfileUpdate(
            username: username?.isEmpty == false ? username : nil,
            fullName: fullName?.isEmpty == false ? fullName : nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("profiles")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
        
        print("SupabaseService: Successfully synced profile data for user: \(userId)")
    }
    
    
    func fetchUserTeams(userId: String) async throws -> [Team] {
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("SupabaseService: Using cached user teams (offline)")
                return cached
            }
            throw AppError.networkUnavailable
        }
        
        do {
            // First get team IDs the user is a member of
            let memberResponse = try await client
                .from("team_members")
                .select("team_id")
                .eq("user_id", value: userId)
                .execute()
            
            let memberData = memberResponse.data
            let teamMembers = try JSONDecoder().decode([TeamMemberResult].self, from: memberData)
            let teamIds = teamMembers.map { $0.teamId }
            
            if teamIds.isEmpty {
                return []
            }
            
            // Then fetch the teams
            let response = try await client
                .from("teams")
                .select()
                .in("id", values: teamIds)
                .execute()
            
            let data = response.data
            let teams = try createSupabaseDecoder().decode([Team].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTeams(teams)
            
            return teams
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchUserTeams", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("SupabaseService: Using cached user teams (error fallback)")
                return cached
            }
            
            throw error
        }
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
            let teams = try createSupabaseDecoder().decode([Team].self, from: data)
            
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
        // Check if captain already has a team (captains can only create one team)
        let existingTeamCount = try await getCaptainTeamCount(captainId: team.captainId)
        if existingTeamCount > 0 {
            throw AppError.teamLimitReached
        }
        
        let response = try await client
            .from("teams")
            .insert(team)
            .select()
            .single()
            .execute()
        
        let data = response.data
        let createdTeam = try createSupabaseDecoder().decode(Team.self, from: data)
        
        // Automatically add the creator as the captain/member
        let teamMember = TeamMember(
            teamId: createdTeam.id,
            userId: team.captainId,
            role: "captain",
            joinedAt: Date()
        )
        
        try await client
            .from("team_members")
            .insert(teamMember)
            .execute()
        
        // Update the team's member count to ensure it's accurate
        try await client
            .from("teams")
            .update(["member_count": 1])
            .eq("id", value: createdTeam.id)
            .execute()
        
        // Update captain's profile to link to this team
        try await client
            .from("profiles")
            .update(["captain_team_id": createdTeam.id])
            .eq("id", value: team.captainId)
            .execute()
        
        print("SupabaseService: Team created and captain added successfully with updated member count")
        return createdTeam
    }
    
    func getCaptainTeamCount(captainId: String) async throws -> Int {
        let response = try await client
            .from("teams")
            .select("id")
            .eq("captain_id", value: captainId)
            .execute()
        
        let data = response.data
        let teams = try JSONDecoder().decode([[String: String]].self, from: data)
        return teams.count
    }
    
    func updateTeam(teamId: String, name: String, description: String?) async throws {
        var updateData: [String: String] = ["name": name]
        if let description = description, !description.isEmpty {
            updateData["description"] = description
        }
        
        try await client
            .from("teams")
            .update(updateData)
            .eq("id", value: teamId)
            .execute()
        
        print("SupabaseService: Team updated successfully")
    }
    
    func removeTeamMember(teamId: String, userId: String) async throws {
        // Remove member from team_members table
        try await client
            .from("team_members")
            .delete()
            .eq("team_id", value: teamId)
            .eq("user_id", value: userId)
            .execute()
        
        // Update team member count by fetching all members and counting them
        
        // Note: Supabase count function might need specific handling
        // For now, we'll fetch all members and count them
        let allMembersResponse = try await client
            .from("team_members")
            .select("user_id")
            .eq("team_id", value: teamId)
            .execute()
        
        let membersData = allMembersResponse.data
        let members = try JSONDecoder().decode([TeamMemberUserId].self, from: membersData)
        let currentMemberCount = members.count
        
        try await client
            .from("teams")
            .update(["member_count": currentMemberCount])
            .eq("id", value: teamId)
            .execute()
        
        print("SupabaseService: Team member removed successfully, updated count to \(currentMemberCount)")
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
    
    func deleteTeam(teamId: String) async throws {
        print("SupabaseService: Starting deletion of team \(teamId)")
        
        // First delete all team members
        do {
            _ = try await client
                .from("team_members")
                .delete()
                .eq("team_id", value: teamId)
                .execute()
            print("SupabaseService: Deleted team members for team \(teamId)")
        } catch {
            print("SupabaseService: Failed to delete team members: \(error)")
            throw NSError(domain: "TeamDeletion", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to remove team members. \(error.localizedDescription)"])
        }
        
        // Then delete the team itself
        do {
            _ = try await client
                .from("teams")
                .delete()
                .eq("id", value: teamId)
                .execute()
            print("SupabaseService: Successfully deleted team \(teamId)")
        } catch {
            print("SupabaseService: Failed to delete team: \(error)")
            // Check if it's a permission error
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("permission") || errorMessage.contains("policy") || errorMessage.contains("denied") {
                throw NSError(domain: "TeamDeletion", code: 2002, userInfo: [NSLocalizedDescriptionKey: "You don't have permission to delete this team. Only the team captain can delete their team."])
            } else {
                throw NSError(domain: "TeamDeletion", code: 2003, userInfo: [NSLocalizedDescriptionKey: "Failed to delete team. \(error.localizedDescription)"])
            }
        }
        
        // Invalidate teams cache to force fresh fetch
        OfflineDataService.shared.clearTeamsCache()
        
        print("SupabaseService: Team \(teamId) and all members deleted successfully")
    }
    
    func fetchUsername(userId: String) async throws -> String? {
        let response = try await client
            .from("profiles")
            .select("username")
            .eq("id", value: userId)
            .single()
            .execute()
        
        let data = response.data
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let username = json["username"] as? String {
            return username
        }
        
        return nil
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
            let workouts = try customJSONDecoder().decode([Workout].self, from: data)
            
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
        return try customJSONDecoder().decode([CompetitionEvent].self, from: data)
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
        return try customJSONDecoder().decode([EventParticipant].self, from: data)
    }
    
    func createEvent(_ event: CompetitionEvent) async throws -> CompetitionEvent {
        print("SupabaseService: Creating event \(event.name)")
        
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
        
        print("SupabaseService: Event \(event.name) created successfully")
        return newEvent
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
        return try customJSONDecoder().decode([TeamMessage].self, from: data)
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
        return try customJSONDecoder().decode([Challenge].self, from: data)
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
            let transactions = try customJSONDecoder().decode([DatabaseTransaction].self, from: data)
            
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
    
    // MARK: - Team Subscription Methods
    
    func createTeamSubscription(_ subscription: DatabaseTeamSubscription) async throws {
        try await client
            .from("team_subscriptions")
            .insert(subscription)
            .execute()
        
        print("SupabaseService: Team subscription created for team \(subscription.teamId)")
    }
    
    // MARK: - Subscription Data Methods
    
    func storeSubscriptionData(_ subscriptionData: SubscriptionData) async throws {
        struct DatabaseSubscription: Encodable {
            let id: String
            let userId: String
            let productId: String
            let purchaseDate: String
            let expirationDate: String?
            let status: String
            let originalTransactionId: String
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case productId = "product_id"
                case purchaseDate = "purchase_date"
                case expirationDate = "expiration_date"
                case status
                case originalTransactionId = "original_transaction_id"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseSubscription = DatabaseSubscription(
            id: String(subscriptionData.id),
            userId: subscriptionData.userId,
            productId: subscriptionData.productId,
            purchaseDate: iso8601Formatter.string(from: subscriptionData.purchaseDate),
            expirationDate: subscriptionData.expirationDate != nil ? iso8601Formatter.string(from: subscriptionData.expirationDate!) : nil,
            status: subscriptionData.status,
            originalTransactionId: subscriptionData.originalTransactionId,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("subscriptions")
            .insert(databaseSubscription)
            .execute()
        
        print("SupabaseService: Subscription data stored successfully")
    }
    
    func updateUserSubscriptionTier(userId: String, tier: String) async throws {
        struct UserUpdate: Encodable {
            let subscriptionTier: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case subscriptionTier = "subscription_tier"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let userUpdate = UserUpdate(
            subscriptionTier: tier,
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("profiles")
            .update(userUpdate)
            .eq("id", value: userId)
            .execute()
        
        print("SupabaseService: User subscription tier updated successfully")
    }
    
    func storeUserWallet(_ wallet: LightningWallet) async throws {
        struct DatabaseWallet: Encodable {
            let id: String
            let userId: String
            let walletType: String
            let balance: Int
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case walletType = "wallet_type"
                case balance
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseWallet = DatabaseWallet(
            id: wallet.id,
            userId: wallet.userId,
            walletType: "lightning",
            balance: wallet.balance,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("user_wallets")
            .insert(databaseWallet)
            .execute()
        
        print("SupabaseService: User wallet stored successfully")
    }
    
    // MARK: - Team Wallet Methods
    
    func storeTeamWallet(_ teamWallet: TeamWallet) async throws {
        struct DatabaseTeamWallet: Encodable {
            let id: String
            let teamId: String
            let captainId: String
            let provider: String
            let balance: Int
            let address: String
            let walletId: String
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case teamId = "team_id"
                case captainId = "captain_id"
                case provider
                case balance
                case address
                case walletId = "wallet_id"
                case createdAt = "created_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseTeamWallet = DatabaseTeamWallet(
            id: teamWallet.id,
            teamId: teamWallet.teamId,
            captainId: teamWallet.captainId,
            provider: teamWallet.provider,
            balance: teamWallet.balance,
            address: teamWallet.address,
            walletId: teamWallet.walletId,
            createdAt: iso8601Formatter.string(from: teamWallet.createdAt)
        )
        
        try await client
            .from("team_wallets")
            .insert(databaseTeamWallet)
            .execute()
        
        print("SupabaseService: Team wallet stored successfully")
    }
    
    func updateTeamWalletId(teamId: String, walletId: String) async throws {
        struct TeamUpdate: Encodable {
            let walletId: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case walletId = "wallet_id"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let teamUpdate = TeamUpdate(
            walletId: walletId,
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("teams")
            .update(teamUpdate)
            .eq("id", value: teamId)
            .execute()
        
        print("SupabaseService: Team wallet ID updated successfully")
    }
    
    func recordTeamTransaction(
        teamId: String,
        userId: String?,
        amount: Int,
        type: String,
        description: String
    ) async throws {
        struct TeamTransaction: Encodable {
            let id: String
            let teamId: String
            let userId: String?
            let amount: Int
            let type: String
            let description: String
            let createdAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case teamId = "team_id"
                case userId = "user_id"
                case amount
                case type
                case description
                case createdAt = "created_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let teamTransaction = TeamTransaction(
            id: UUID().uuidString,
            teamId: teamId,
            userId: userId,
            amount: amount,
            type: type,
            description: description,
            createdAt: iso8601Formatter.string(from: Date())
        )
        
        try await client
            .from("team_transactions")
            .insert(teamTransaction)
            .execute()
        
        print("SupabaseService: Team transaction recorded successfully")
    }
    
    // MARK: - Streak Tracking Methods
    
    func storeUserStreak(userId: String, streakData: UserStreakData) async throws {
        struct DatabaseStreakData: Encodable {
            let id: String
            let userId: String
            let consecutiveDays: Int
            let lastWorkoutDate: String
            let longestStreak: Int
            let totalWorkoutDays: Int
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case consecutiveDays = "consecutive_days"
                case lastWorkoutDate = "last_workout_date"
                case longestStreak = "longest_streak"
                case totalWorkoutDays = "total_workout_days"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let databaseStreakData = DatabaseStreakData(
            id: UUID().uuidString,
            userId: userId,
            consecutiveDays: streakData.consecutiveDays,
            lastWorkoutDate: iso8601Formatter.string(from: streakData.lastWorkoutDate),
            longestStreak: streakData.longestStreak,
            totalWorkoutDays: 0,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        // Use upsert to update existing record or create new one
        try await client
            .from("user_streaks")
            .upsert(databaseStreakData)
            .execute()
        
        print("SupabaseService: User streak data stored successfully")
    }
    
    // MARK: - Device Token Storage
    
    func storeDeviceToken(userId: String, token: String) async throws {
        struct DeviceToken: Encodable {
            let id: String
            let userId: String
            let token: String
            let platform: String
            let isActive: Bool
            let createdAt: String
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case token
                case platform
                case isActive = "is_active"
                case createdAt = "created_at"
                case updatedAt = "updated_at"
            }
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let deviceToken = DeviceToken(
            id: UUID().uuidString,
            userId: userId,
            token: token,
            platform: "ios",
            isActive: true,
            createdAt: iso8601Formatter.string(from: Date()),
            updatedAt: iso8601Formatter.string(from: Date())
        )
        
        // Use upsert to update existing token or create new one
        try await client
            .from("device_tokens")
            .upsert(deviceToken)
            .execute()
        
        print("SupabaseService: Device token stored successfully")
    }
    
    // MARK: - Team Management Methods
    
    func removeUserFromTeam(userId: String, teamId: String) async throws {
        try await client
            .from("team_members")
            .delete()
            .eq("user_id", value: userId)
            .eq("team_id", value: teamId)
            .execute()
        
        print("SupabaseService: User \(userId) removed from team \(teamId) successfully")
    }
    
    func fetchTeamSubscription(userId: String, transactionId: String) async throws -> DatabaseTeamSubscription? {
        let response = try await client
            .from("team_subscriptions")
            .select()
            .eq("user_id", value: userId)
            .eq("transaction_id", value: transactionId)
            .single()
            .execute()
        
        let data = response.data
        return try customJSONDecoder().decode(DatabaseTeamSubscription.self, from: data)
    }
    
    func updateTeamSubscriptionStatus(userId: String, transactionId: String, status: String, expirationDate: Date?) async throws {
        struct UpdateData: Encodable {
            let status: String
            let updatedAt: String
            let expirationDate: String?
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
                case expirationDate = "expiration_date"
            }
        }
        
        let updateData = UpdateData(
            status: status,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            expirationDate: expirationDate != nil ? ISO8601DateFormatter().string(from: expirationDate!) : nil
        )
        
        try await client
            .from("team_subscriptions")
            .update(updateData)
            .eq("user_id", value: userId)
            .eq("transaction_id", value: transactionId)
            .execute()
        
        print("SupabaseService: Team subscription status updated to \(status)")
    }
    
    func fetchUserTeamSubscriptions(userId: String) async throws -> [DatabaseTeamSubscription] {
        let response = try await client
            .from("team_subscriptions")
            .select()
            .eq("user_id", value: userId)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .execute()
        
        let data = response.data
        return try customJSONDecoder().decode([DatabaseTeamSubscription].self, from: data)
    }
    
    // MARK: - Enhanced Team Data Methods
    
    func fetchTeamMembers(teamId: String) async throws -> [TeamMemberWithProfile] {
        // Join team_members with profiles to get member details
        let response = try await client
            .from("team_members")
            .select("""
                user_id, role, joined_at,
                profiles!inner(id, username, full_name, avatar_url)
            """)
            .eq("team_id", value: teamId)
            .order("joined_at", ascending: true)
            .execute()
        
        let data = response.data
        return try customJSONDecoder().decode([TeamMemberWithProfile].self, from: data)
    }
    
    func fetchTeamWorkouts(teamId: String, period: String = "weekly") async throws -> [Workout] {
        // First get team member IDs
        let memberResponse = try await client
            .from("team_members")
            .select("user_id")
            .eq("team_id", value: teamId)
            .execute()
        
        let memberData = memberResponse.data
        let teamMembers = try JSONDecoder().decode([TeamMemberUserId].self, from: memberData)
        let userIds = teamMembers.map { $0.userId }
        
        if userIds.isEmpty {
            return []
        }
        
        // Calculate date range based on period
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case "daily":
            startDate = calendar.startOfDay(for: now)
        case "weekly":
            startDate = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case "monthly":
            startDate = calendar.dateInterval(of: .month, for: now)?.start ?? now
        default:
            startDate = Date.distantPast
        }
        
        // Fetch workouts for team members in the specified period
        let response = try await client
            .from("workouts")
            .select()
            .in("user_id", values: userIds)
            .gte("started_at", value: ISO8601DateFormatter().string(from: startDate))
            .order("started_at", ascending: false)
            .execute()
        
        let data = response.data
        return try customJSONDecoder().decode([Workout].self, from: data)
    }
    
    func fetchTeamLeaderboard(teamId: String, type: String = "distance", period: String = "weekly") async throws -> [TeamLeaderboardMember] {
        // Get team workouts for the specified period
        let workouts = try await fetchTeamWorkouts(teamId: teamId, period: period)
        
        // Group workouts by user and calculate metrics
        var userMetrics: [String: TeamMemberMetrics] = [:]
        
        for workout in workouts {
            if userMetrics[workout.userId] == nil {
                userMetrics[workout.userId] = TeamMemberMetrics(userId: workout.userId)
            }
            
            userMetrics[workout.userId]?.addWorkout(workout)
        }
        
        // Get member profiles
        let members = try await fetchTeamMembers(teamId: teamId)
        let memberProfiles = Dictionary(uniqueKeysWithValues: members.map { ($0.userId, $0) })
        
        // Create leaderboard entries
        var leaderboardMembers: [TeamLeaderboardMember] = []
        
        for (userId, metrics) in userMetrics {
            if let profile = memberProfiles[userId] {
                let member = TeamLeaderboardMember(
                    userId: userId,
                    username: profile.profile.username ?? "Unknown",
                    avatarUrl: profile.profile.avatarUrl,
                    workoutCount: metrics.workoutCount,
                    totalDistance: metrics.totalDistance,
                    totalDuration: metrics.totalDuration,
                    totalPoints: metrics.totalPoints,
                    rank: 0 // Will be set after sorting
                )
                leaderboardMembers.append(member)
            }
        }
        
        // Sort based on type and assign ranks
        switch type {
        case "distance":
            leaderboardMembers.sort { $0.totalDistance > $1.totalDistance }
        case "workout_count":
            leaderboardMembers.sort { $0.workoutCount > $1.workoutCount }
        case "points":
            leaderboardMembers.sort { $0.totalPoints > $1.totalPoints }
        default:
            leaderboardMembers.sort { $0.totalDistance > $1.totalDistance }
        }
        
        // Assign ranks
        for (index, _) in leaderboardMembers.enumerated() {
            leaderboardMembers[index].rank = index + 1
        }
        
        return leaderboardMembers
    }
    
    
    func fetchTeamActivity(teamId: String, limit: Int = 20) async throws -> [TeamActivity] {
        // For now, we'll create activity from recent workouts and member joins
        // In a full implementation, this would be a separate activities table
        var activities: [TeamActivity] = []
        
        // Get recent workouts
        let recentWorkouts = try await fetchTeamWorkouts(teamId: teamId, period: "weekly")
        let members = try await fetchTeamMembers(teamId: teamId)
        let memberProfiles = Dictionary(uniqueKeysWithValues: members.map { ($0.userId, $0) })
        
        // Add workout activities
        for workout in recentWorkouts.prefix(limit) {
            if let member = memberProfiles[workout.userId] {
                let activity = TeamActivity(
                    id: UUID().uuidString,
                    teamId: teamId,
                    userId: workout.userId,
                    username: member.profile.username ?? "Unknown",
                    type: "workout_completed",
                    description: "completed a \(workout.type) workout",
                    metadata: [
                        "distance": workout.distance ?? 0,
                        "duration": workout.duration
                    ],
                    createdAt: workout.startedAt
                )
                activities.append(activity)
            }
        }
        
        // Add recent member joins
        let recentMembers = members.filter { member in
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains(member.joinedAt) ?? false
        }
        
        for member in recentMembers {
            let activity = TeamActivity(
                id: UUID().uuidString,
                teamId: teamId,
                userId: member.userId,
                username: member.profile.username ?? "Unknown",
                type: "member_joined",
                description: "joined the team",
                metadata: [:],
                createdAt: member.joinedAt
            )
            activities.append(activity)
        }
        
        // Sort by most recent and return limited results
        activities.sort { $0.createdAt > $1.createdAt }
        return Array(activities.prefix(limit))
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToTeamUpdates(teamId: String, onUpdate: @escaping (Team) -> Void) {
        let _ = client.channel("team-\(teamId)")
        
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
                selectedMetrics: nil,
                createdAt: Date()
            ))
        }
    }
    
    func subscribeToLeaderboard(onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        let _ = client.channel("leaderboard")
        
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
        print("SupabaseService: Real-time subscriptions planned for future implementation")
        print("SupabaseService: Team chat \(teamId) will use polling for now")
        
        // Note: Real-time subscriptions will be implemented in Phase 3
        // For now, team chat uses manual refresh patterns
        // This prevents blocking the build while we complete other Phase 2 priorities
    }
    
    // MARK: - Team Wallet Support Methods
    
    func isUserMemberOfTeam(userId: String, teamId: String) async throws -> Bool {
        do {
            let response: [TeamMember] = try await client
                .from("team_members")
                .select("user_id")
                .eq("team_id", value: teamId)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            print("SupabaseService: Error checking team membership: \(error)")
            throw error
        }
    }
    
    func getTeam(_ teamId: String) async throws -> Team? {
        do {
            let response: [Team] = try await client
                .from("teams")
                .select("*")
                .eq("id", value: teamId)
                .execute()
                .value
            
            return response.first
        } catch {
            print("SupabaseService: Error fetching team: \(error)")
            throw error
        }
    }
    
    
    func recordTransaction(
        teamId: String? = nil,
        userId: String? = nil,
        walletId: String? = nil,
        amount: Int,
        type: String,
        description: String,
        metadata: [String: Any] = [:]
    ) async throws {
        // For MVP: Simple logging implementation
        // TODO: Implement full transaction recording when Supabase client supports complex types
        print("SupabaseService: Recording transaction - \(amount) sats, type: \(type)")
        print("SupabaseService: Description: \(description)")
        
        if let teamId = teamId {
            print("SupabaseService: Team ID: \(teamId)")
        }
        
        if let userId = userId {
            print("SupabaseService: User ID: \(userId)")
        }
        
        print("SupabaseService: Transaction recorded successfully (simplified for MVP)")
    }
    
    func getTeamWalletBalance(teamId: String) async throws -> Int {
        print("SupabaseService: Getting team wallet balance for team \(teamId)")
        
        do {
            // Check if team wallet exists in database
            let response: [TeamWallet] = try await client
                .from("team_wallets")
                .select()
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            guard let teamWallet = response.first else {
                print("SupabaseService: No wallet found for team \(teamId), returning 0")
                return 0
            }
            
            // Use TeamWalletManager to get balance (it handles credentials properly)
            let walletBalance = try await TeamWalletManager.shared.getTeamWalletBalance(teamId: teamId)
            let balance = walletBalance.total
            
            print("SupabaseService: Retrieved real balance: \(balance) sats for team \(teamId)")
            return balance
            
        } catch {
            print("SupabaseService: Failed to get team wallet balance: \(error)")
            // Return 0 instead of mock data on error
            return 0
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
    let totalWorkouts: Int?
    let totalDistance: Double?
    let totalEarnings: Double?
    let createdAt: Date?
    let updatedAt: Date?
}

struct Team: Codable {
    let id: String
    let name: String
    let description: String?
    let captainId: String
    let memberCount: Int
    let totalEarnings: Double
    let imageUrl: String?
    let selectedMetrics: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case captainId = "captain_id"
        case memberCount = "member_count"
        case totalEarnings = "total_earnings"
        case imageUrl = "image_url"
        case selectedMetrics = "selected_metrics"
        case createdAt = "created_at"
    }
}

struct TeamMember: Codable {
    let teamId: String
    let userId: String
    let role: String
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
    }
}

struct TeamMemberResult: Codable {
    let teamId: String
    
    enum CodingKeys: String, CodingKey {
        case teamId = "team_id"
    }
}

struct TeamMemberUserId: Codable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
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
    let endedAt: Date?  // Made optional in case column doesn't exist
    let syncedAt: Date
    
    // Custom CodingKeys to handle snake_case in database
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case duration
        case distance
        case calories
        case heartRate = "heart_rate"
        case source
        case startedAt = "started_at"
        case endedAt = "ended_at"  // Map to snake_case column name
        case syncedAt = "synced_at"
    }
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

struct DatabaseTeamSubscription: Codable {
    let id: String
    let userId: String
    let teamId: String
    let productId: String
    let transactionId: String
    let originalTransactionId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let status: String
    let autoRenewing: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case productId = "product_id"
        case transactionId = "transaction_id"
        case originalTransactionId = "original_transaction_id"
        case purchaseDate = "purchase_date"
        case expirationDate = "expiration_date"
        case status
        case autoRenewing = "auto_renewing"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Team Wallet Data Models

struct DatabaseLightningWallet: Codable {
    let id: String
    let userId: String?
    let teamId: String?
    let walletType: String
    let provider: String
    let walletId: String
    let address: String
    let balance: Int
    let credentialsEncrypted: String?
    let status: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case walletType = "wallet_type"
        case provider
        case walletId = "wallet_id"
        case address
        case balance
        case credentialsEncrypted = "credentials_encrypted"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Transaction: Codable {
    let id: String
    let userId: String?
    let teamId: String?
    let walletId: String?
    let fromWalletId: String?
    let toWalletId: String?
    let type: String
    let amount: Int
    let usdAmount: Double?
    let description: String?
    let status: String
    let transactionHash: String?
    let preimage: String?
    let invoiceData: String? // JSON string for MVP
    let metadata: String? // JSON string for MVP
    let processedAt: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teamId = "team_id"
        case walletId = "wallet_id"
        case fromWalletId = "from_wallet_id"
        case toWalletId = "to_wallet_id"
        case type
        case amount
        case usdAmount = "usd_amount"
        case description
        case status
        case transactionHash = "transaction_hash"
        case preimage
        case invoiceData = "invoice_data"
        case metadata
        case processedAt = "processed_at"
        case createdAt = "created_at"
    }
    
}

// MARK: - Enhanced Team Data Models

struct TeamMemberWithProfile: Codable {
    let userId: String
    let role: String
    let joinedAt: Date
    let profile: UserProfile
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case role
        case joinedAt = "joined_at"
        case profile = "profiles"
    }
}

struct TeamLeaderboardMember: Codable {
    let userId: String
    let username: String
    let avatarUrl: String?
    let workoutCount: Int
    let totalDistance: Double
    let totalDuration: Int
    let totalPoints: Int
    var rank: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatarUrl = "avatar_url"
        case workoutCount = "workout_count"
        case totalDistance = "total_distance"
        case totalDuration = "total_duration"
        case totalPoints = "total_points"
        case rank
    }
}


struct TeamActivity: Codable {
    let id: String
    let teamId: String
    let userId: String
    let username: String
    let type: String
    let description: String
    let metadata: [String: Any]
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case teamId = "team_id"
        case userId = "user_id"
        case username
        case type
        case description
        case metadata
        case createdAt = "created_at"
    }
    
    init(id: String, teamId: String, userId: String, username: String, type: String, description: String, metadata: [String: Any], createdAt: Date) {
        self.id = id
        self.teamId = teamId
        self.userId = userId
        self.username = username
        self.type = type
        self.description = description
        self.metadata = metadata
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        teamId = try container.decode(String.self, forKey: .teamId)
        userId = try container.decode(String.self, forKey: .userId)
        username = try container.decode(String.self, forKey: .username)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Handle metadata as a flexible dictionary
        if let metadataData = try? container.decode([String: AnyCodable].self, forKey: .metadata) {
            metadata = metadataData.mapValues { $0.value }
        } else {
            metadata = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(teamId, forKey: .teamId)
        try container.encode(userId, forKey: .userId)
        try container.encode(username, forKey: .username)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Encode metadata as AnyCodable
        let encodableMetadata = metadata.mapValues { AnyCodable($0) }
        try container.encode(encodableMetadata, forKey: .metadata)
    }
}

class TeamMemberMetrics {
    let userId: String
    var workoutCount: Int = 0
    var totalDistance: Double = 0
    var totalDuration: Int = 0
    var totalPoints: Int = 0
    
    init(userId: String) {
        self.userId = userId
    }
    
    func addWorkout(_ workout: Workout) {
        workoutCount += 1
        totalDistance += workout.distance ?? 0
        totalDuration += workout.duration
        
        // Calculate points using WorkoutRewardCalculator
        if let healthKitWorkout = convertToHealthKitWorkout(workout) {
            let reward = WorkoutRewardCalculator.shared.calculateReward(for: healthKitWorkout)
            totalPoints += reward.satsAmount
        }
    }
    
    private func convertToHealthKitWorkout(_ workout: Workout) -> HealthKitWorkout? {
        // Convert Supabase Workout to HealthKitWorkout for reward calculation
        return HealthKitWorkout(
            id: workout.id,
            workoutType: workout.type,
            startDate: workout.startedAt,
            endDate: workout.endedAt ?? Date(),
            duration: TimeInterval(workout.duration),
            totalDistance: Double(workout.distance ?? 0),
            totalEnergyBurned: Double(workout.calories ?? 0),
            source: "HealthKit",
            metadata: [:]
        )
    }
}

// Helper struct for flexible JSON encoding/decoding
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else {
            try container.encodeNil()
        }
    }
}