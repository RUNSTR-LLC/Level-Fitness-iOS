import Foundation
import Supabase

// MARK: - Team Data Models

struct Team: Codable {
    let id: String
    let name: String
    let description: String?
    let captainId: String
    let memberCount: Int
    let memberLimit: Int?
    let subscriptionTier: String?
    let currentPrizePool: Double
    let status: String
    let inviteCode: String?
    let totalEarnings: Double
    let imageUrl: String?
    let selectedMetrics: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, status
        case captainId = "captain_id"
        case memberCount = "member_count"
        case memberLimit = "member_limit"
        case subscriptionTier = "subscription_tier"
        case currentPrizePool = "current_prize_pool"
        case inviteCode = "invite_code"
        case totalEarnings = "total_earnings"
        case imageUrl = "image_url"
        case selectedMetrics = "selected_metrics"
        case createdAt = "created_at"
    }
}


// Database-specific TeamMember type (avoids collision with Presentation layer TeamMember)
struct TeamMemberDB: Codable {
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
        if let metadataData = try? container.decode([String: String].self, forKey: .metadata) {
            metadata = metadataData
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
        
        // Convert metadata to encodable format
        let encodableMetadata = metadata.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let numberValue = value as? NSNumber {
                return numberValue.stringValue
            } else {
                return String(describing: value)
            }
        }
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
        
        // Points now come from team prize pools and competitions, not individual workouts
        // Individual workout rewards have been deprecated
    }
    
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
}

// MARK: - Service Dependencies
// This service references models from SupabaseService, ErrorHandlingService, NetworkMonitorService, OfflineDataService, WorkoutDataService

class TeamDataService {
    static let shared = TeamDataService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Team Management
    
    func fetchUserTeams(userId: String) async throws -> [Team] {
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("TeamDataService: Using cached user teams (offline)")
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
            let teams = try SupabaseService.shared.customJSONDecoder().decode([Team].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTeams(teams)
            
            return teams
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchUserTeams", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("TeamDataService: Using cached user teams (error fallback)")
                return cached
            }
            
            throw error
        }
    }
    
    func fetchTeams() async throws -> [Team] {
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("TeamDataService: Using cached teams (offline)")
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
            let teams = try SupabaseService.shared.customJSONDecoder().decode([Team].self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheTeams(teams)
            
            return teams
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchTeams")
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedTeams() {
                print("TeamDataService: Using cached teams (error fallback)")
                return cached
            }
            
            throw error
        }
    }
    
    func createTeam(_ team: Team) async throws -> Team {
        // Always check if captain already has a team to prevent duplicates
        // Even in development mode, we want to prevent accidental duplicates
        let existingTeamCount = try await getCaptainTeamCount(captainId: team.captainId)
        if existingTeamCount > 0 {
            // Check if any of the existing teams were created very recently (within 30 seconds)
            // This helps identify potential duplicate creation issues
            let recentTeams = try await getRecentTeamsForCaptain(captainId: team.captainId, within: 30)
            if !recentTeams.isEmpty {
                print("TeamDataService: WARNING - Captain \(team.captainId) already has \(existingTeamCount) teams, including \(recentTeams.count) created recently")
            }
            
            if !SubscriptionService.DEVELOPMENT_MODE {
                throw AppError.teamLimitReached
            } else {
                print("TeamDataService: DEVELOPMENT MODE - Allowing duplicate team creation for captain \(team.captainId)")
            }
        }
        
        let response = try await client
            .from("teams")
            .insert(team)
            .select()
            .single()
            .execute()
        
        let data = response.data
        let createdTeam = try SupabaseService.shared.customJSONDecoder().decode(Team.self, from: data)
        
        // Automatically add the creator as the captain/member
        let teamMember = TeamMemberDB(
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
        
        print("TeamDataService: Team created and captain added successfully with updated member count")
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
    
    func getRecentTeamsForCaptain(captainId: String, within seconds: Int) async throws -> [Team] {
        let cutoffDate = Date().addingTimeInterval(-Double(seconds))
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        
        let response = try await client
            .from("teams")
            .select()
            .eq("captain_id", value: captainId)
            .gte("created_at", value: iso8601Formatter.string(from: cutoffDate))
            .execute()
        
        let data = response.data
        return try SupabaseService.shared.customJSONDecoder().decode([Team].self, from: data)
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
        
        print("TeamDataService: Team updated successfully")
    }
    
    func deleteTeam(teamId: String) async throws {
        print("TeamDataService: Starting deletion of team \(teamId)")
        
        // First delete all team members
        do {
            _ = try await client
                .from("team_members")
                .delete()
                .eq("team_id", value: teamId)
                .execute()
            print("TeamDataService: Deleted team members for team \(teamId)")
        } catch {
            print("TeamDataService: Failed to delete team members: \(error)")
            throw NSError(domain: "TeamDeletion", code: 2001, userInfo: [NSLocalizedDescriptionKey: "Failed to remove team members. \(error.localizedDescription)"])
        }
        
        // Then delete the team itself
        do {
            _ = try await client
                .from("teams")
                .delete()
                .eq("id", value: teamId)
                .execute()
            print("TeamDataService: Successfully deleted team \(teamId)")
        } catch {
            print("TeamDataService: Failed to delete team: \(error)")
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
        
        print("TeamDataService: Team \(teamId) and all members deleted successfully")
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
            print("TeamDataService: Error fetching team: \(error)")
            throw error
        }
    }
    
    func fetchTeamDetails(teamId: String) async throws -> Team {
        do {
            let response: [Team] = try await client
                .from("teams")
                .select("*")
                .eq("id", value: teamId)
                .execute()
                .value
            
            guard let team = response.first else {
                throw NSError(domain: "TeamDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Team not found"])
            }
            
            return team
        } catch {
            print("TeamDataService: Error fetching team details: \(error)")
            throw error
        }
    }
    
    func subscribeToTeam(userId: String, teamId: String) async throws {
        // Add user to team as subscriber/member
        let teamMember = TeamMemberDB(
            teamId: teamId,
            userId: userId,
            role: "member",
            joinedAt: Date()
        )
        
        try await client
            .from("team_members")
            .insert(teamMember)
            .execute()
        
        // Update team member count
        let currentCount = try await fetchTeamMembers(teamId: teamId).count
        
        try await client
            .from("teams")
            .update(["member_count": currentCount])
            .eq("id", value: teamId)
            .execute()
        
        print("TeamDataService: User \(userId) subscribed to team \(teamId)")
    }
    
    func unsubscribeFromTeam(userId: String, teamId: String) async throws {
        // Remove user from team
        try await client
            .from("team_members")
            .delete()
            .eq("user_id", value: userId)
            .eq("team_id", value: teamId)
            .execute()
        
        // Update team member count
        let currentCount = try await fetchTeamMembers(teamId: teamId).count
        
        try await client
            .from("teams")
            .update(["member_count": currentCount])
            .eq("id", value: teamId)
            .execute()
        
        print("TeamDataService: User \(userId) unsubscribed from team \(teamId)")
    }
    
    // MARK: - Team Member Management
    
    func joinTeam(teamId: String, userId: String) async throws {
        let teamMember = TeamMemberDB(
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
    
    func removeTeamMember(teamId: String, userId: String) async throws {
        // Remove member from team_members table
        try await client
            .from("team_members")
            .delete()
            .eq("team_id", value: teamId)
            .eq("user_id", value: userId)
            .execute()
        
        // Update team member count by fetching all members and counting them
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
        
        print("TeamDataService: Team member removed successfully, updated count to \(currentMemberCount)")
    }
    
    func removeUserFromTeam(userId: String, teamId: String) async throws {
        try await client
            .from("team_members")
            .delete()
            .eq("user_id", value: userId)
            .eq("team_id", value: teamId)
            .execute()
        
        print("TeamDataService: User \(userId) removed from team \(teamId) successfully")
    }
    
    func isUserMemberOfTeam(userId: String, teamId: String) async throws -> Bool {
        do {
            let response: [TeamMemberUserId] = try await client
                .from("team_members")
                .select("user_id")
                .eq("team_id", value: teamId)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            print("TeamDataService: Error checking team membership: \(error)")
            throw error
        }
    }
    
    func isUserSubscribedToTeam(userId: String, teamId: String) async throws -> Bool {
        do {
            // Check if user has active team subscription
            let response: [TeamMemberUserId] = try await client
                .from("team_members")
                .select("user_id")
                .eq("team_id", value: teamId)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return !response.isEmpty
        } catch {
            print("TeamDataService: Error checking team subscription: \(error)")
            throw error
        }
    }
    
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
        return try SupabaseService.shared.customJSONDecoder().decode([TeamMemberWithProfile].self, from: data)
    }
    
    // MARK: - Team Analytics
    
    func fetchTeamLeaderboard(teamId: String, type: String = "distance", period: String = "weekly") async throws -> [TeamLeaderboardMember] {
        // Get team workouts for the specified period
        let workouts = try await WorkoutDataService.shared.fetchTeamWorkouts(teamId: teamId, period: period)
        
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
        let recentWorkouts = try await WorkoutDataService.shared.fetchTeamWorkouts(teamId: teamId, period: "weekly")
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
                        "distance": String(workout.distance ?? 0),
                        "duration": String(workout.duration)
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
    
    // MARK: - Utility Methods
    
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
        
        print("TeamDataService: Device token stored successfully")
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
                memberLimit: nil,
                subscriptionTier: nil,
                currentPrizePool: 0.0,
                status: "active",
                inviteCode: nil,
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
        print("TeamDataService: Real-time subscriptions planned for future implementation")
        print("TeamDataService: Team announcements \(teamId) use push notification delivery")
        
        // Note: Team announcements are delivered via push notifications
        // This aligns with the invisible micro app design pattern
        // Captain announcements broadcast to all team members automatically
    }
    
    // MARK: - Team Messaging
    
    func sendTeamMessage(teamId: String, userId: String, message: String, messageType: String) async throws {
        do {
            let teamMessage = [
                "team_id": teamId,
                "user_id": userId,
                "message": message,
                "message_type": messageType,
                "created_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            try await client
                .from("team_messages")
                .insert(teamMessage)
                .execute()
            
            print("TeamDataService: ✅ Team message sent successfully")
            
        } catch {
            print("TeamDataService: ❌ Failed to send team message: \(error)")
            throw error
        }
    }
}