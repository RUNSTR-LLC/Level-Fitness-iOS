import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    // Supabase project credentials
    private let supabaseURL = "https://cqhlwoguxbwnqdternci.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNxaGx3b2d1eGJ3bnFkdGVybmNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ3ODA4NTgsImV4cCI6MjA3MDM1Njg1OH0.vnA3CFYBeyCXr0tvGCGDcaD_9PXOeBjhwfT2AaWqO-8"
    
    private var _client: SupabaseClient!
    
    // Expose client for data services
    var client: SupabaseClient {
        return _client
    }
    
    private init() {
        setupClient()
    }
    
    private func setupClient() {
        _client = SupabaseClient(
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
    
    // MARK: - Authentication Methods (Delegated to AuthDataService)
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserSession? {
        return try await AuthDataService.shared.signInWithApple(idToken: idToken, nonce: nonce)
    }
    
    func signOut() async throws {
        try await AuthDataService.shared.signOut()
    }
    
    func getCurrentUser() async throws -> UserSession? {
        return try await AuthDataService.shared.getCurrentUser()
    }
    
    func restoreSession(accessToken: String, refreshToken: String) async throws {
        try await AuthDataService.shared.restoreSession(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    // MARK: - Database Methods
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        return try await AuthDataService.shared.fetchUserProfile(userId: userId)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await AuthDataService.shared.updateUserProfile(profile)
    }
    
    func syncLocalProfileToSupabase(userId: String, username: String?, fullName: String?) async throws {
        try await AuthDataService.shared.syncLocalProfileToSupabase(userId: userId, username: username, fullName: fullName)
    }
    
    
    func fetchUserTeams(userId: String) async throws -> [Team] {
        return try await TeamDataService.shared.fetchUserTeams(userId: userId)
    }
    
    func fetchTeams() async throws -> [Team] {
        return try await TeamDataService.shared.fetchTeams()
    }
    
    func createTeam(_ team: Team) async throws -> Team {
        return try await TeamDataService.shared.createTeam(team)
    }
    
    func getCaptainTeamCount(captainId: String) async throws -> Int {
        return try await TeamDataService.shared.getCaptainTeamCount(captainId: captainId)
    }
    
    func updateTeam(teamId: String, name: String, description: String?) async throws {
        return try await TeamDataService.shared.updateTeam(teamId: teamId, name: name, description: description)
    }
    
    func removeTeamMember(teamId: String, userId: String) async throws {
        return try await TeamDataService.shared.removeTeamMember(teamId: teamId, userId: userId)
    }
    
    func joinTeam(teamId: String, userId: String) async throws {
        return try await TeamDataService.shared.joinTeam(teamId: teamId, userId: userId)
    }
    
    func deleteTeam(teamId: String) async throws {
        return try await TeamDataService.shared.deleteTeam(teamId: teamId)
    }
    
    func fetchUsername(userId: String) async throws -> String? {
        return try await TeamDataService.shared.fetchUsername(userId: userId)
    }
    
    func syncWorkout(_ workout: Workout) async throws {
        return try await WorkoutDataService.shared.syncWorkout(workout)
    }
    
    func fetchWorkouts(userId: String, limit: Int = 20) async throws -> [Workout] {
        return try await WorkoutDataService.shared.fetchWorkouts(userId: userId, limit: limit)
    }
    
    
    // MARK: - Competition Events Methods - Delegated to CompetitionDataService
    
    func fetchEvents(status: String = "active") async throws -> [CompetitionEvent] {
        return try await CompetitionDataService.shared.fetchEvents(status: status)
    }
    
    func joinEvent(eventId: String, userId: String) async throws {
        return try await CompetitionDataService.shared.joinEvent(eventId: eventId, userId: userId)
    }
    
    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        return try await CompetitionDataService.shared.fetchEventParticipants(eventId: eventId)
    }
    
    func createEvent(_ event: CompetitionEvent) async throws -> CompetitionEvent {
        return try await CompetitionDataService.shared.createEvent(event)
    }
    
    // MARK: - Team Chat Methods - Delegated to CompetitionDataService
    
    func fetchTeamMessages(teamId: String, limit: Int = 50) async throws -> [TeamMessage] {
        return try await CompetitionDataService.shared.fetchTeamMessages(teamId: teamId, limit: limit)
    }
    
    func sendTeamMessage(teamId: String, userId: String, message: String, messageType: String = "text") async throws {
        return try await CompetitionDataService.shared.sendTeamMessage(teamId: teamId, userId: userId, message: message, messageType: messageType)
    }
    
    // MARK: - Challenge Methods - Delegated to CompetitionDataService
    
    func fetchChallenges(teamId: String? = nil) async throws -> [Challenge] {
        return try await CompetitionDataService.shared.fetchChallenges(teamId: teamId)
    }
    
    func joinChallenge(challengeId: String, userId: String) async throws {
        return try await CompetitionDataService.shared.joinChallenge(challengeId: challengeId, userId: userId)
    }
    
    // MARK: - Leaderboard Methods - Delegated to CompetitionDataService
    
    func fetchWeeklyLeaderboard() async throws -> [LeaderboardEntry] {
        return try await CompetitionDataService.shared.fetchWeeklyLeaderboard()
    }
    
    func fetchTeamLeaderboard() async throws -> [TeamLeaderboardEntry] {
        return try await CompetitionDataService.shared.fetchTeamLeaderboard()
    }
    
    // MARK: - Lightning Wallet Methods - Delegated to TransactionDataService
    
    func createLightningWallet(userId: String, provider: String, walletId: String, address: String) async throws -> SupabaseLightningWallet {
        return try await TransactionDataService.shared.createLightningWallet(userId: userId, provider: provider, walletId: walletId, address: address)
    }
    
    func fetchLightningWallet(userId: String) async throws -> SupabaseLightningWallet? {
        return try await TransactionDataService.shared.fetchLightningWallet(userId: userId)
    }
    
    func fetchTransactions(userId: String, limit: Int = 50) async throws -> [DatabaseTransaction] {
        return try await TransactionDataService.shared.fetchTransactions(userId: userId, limit: limit)
    }
    
    func createTransaction(userId: String, type: String, amount: Int, description: String) async throws -> DatabaseTransaction {
        return try await TransactionDataService.shared.createTransaction(userId: userId, type: type, amount: amount, description: description)
    }
    
    // MARK: - Team Subscription Methods - Delegated to TransactionDataService
    
    func createTeamSubscription(_ subscription: DatabaseTeamSubscription) async throws {
        return try await TransactionDataService.shared.createTeamSubscription(subscription)
    }
    
    // MARK: - Subscription Data Methods - Delegated to TransactionDataService
    
    func storeSubscriptionData(_ subscriptionData: SubscriptionData) async throws {
        return try await TransactionDataService.shared.storeSubscriptionData(subscriptionData)
    }
    
    func updateUserSubscriptionTier(userId: String, tier: String) async throws {
        return try await TransactionDataService.shared.updateUserSubscriptionTier(userId: userId, tier: tier)
    }
    
    func storeUserWallet(_ wallet: LightningWallet) async throws {
        return try await TransactionDataService.shared.storeUserWallet(wallet)
    }
    
    // MARK: - Team Wallet Methods - Delegated to TransactionDataService
    
    func storeTeamWallet(_ teamWallet: TeamWallet) async throws {
        return try await TransactionDataService.shared.storeTeamWallet(teamWallet)
    }
    
    func updateTeamWalletId(teamId: String, walletId: String) async throws {
        return try await TransactionDataService.shared.updateTeamWalletId(teamId: teamId, walletId: walletId)
    }
    
    func recordTeamTransaction(
        teamId: String,
        userId: String?,
        amount: Int,
        type: String,
        description: String
    ) async throws {
        return try await TransactionDataService.shared.recordTeamTransaction(teamId: teamId, userId: userId, amount: amount, type: type, description: description)
    }
    
    // MARK: - Streak Tracking Methods (removed - only for streak events now)
    
    // MARK: - Device Token Storage - Delegated to TeamDataService
    
    func storeDeviceToken(userId: String, token: String) async throws {
        return try await TeamDataService.shared.storeDeviceToken(userId: userId, token: token)
    }
    
    // MARK: - Team Management Methods
    
    func removeUserFromTeam(userId: String, teamId: String) async throws {
        return try await TeamDataService.shared.removeUserFromTeam(userId: userId, teamId: teamId)
    }
    
    func fetchTeamSubscription(userId: String, transactionId: String) async throws -> DatabaseTeamSubscription? {
        return try await TransactionDataService.shared.fetchTeamSubscription(userId: userId, transactionId: transactionId)
    }
    
    func updateTeamSubscriptionStatus(userId: String, transactionId: String, status: String, expirationDate: Date?) async throws {
        return try await TransactionDataService.shared.updateTeamSubscriptionStatus(userId: userId, transactionId: transactionId, status: status, expirationDate: expirationDate)
    }
    
    func fetchUserTeamSubscriptions(userId: String) async throws -> [DatabaseTeamSubscription] {
        return try await TransactionDataService.shared.fetchUserTeamSubscriptions(userId: userId)
    }
    
    // MARK: - Storage Methods (Profile Images)
    
    func uploadProfileImage(_ imageData: Data, userId: String, fileName: String) async throws -> String {
        print("SupabaseService: Uploading profile image for user: \(userId)")
        
        let filePath = "profiles/\(userId)/\(fileName)"
        
        let file = File(
            name: fileName,
            data: imageData,
            fileName: fileName,
            contentType: "image/jpeg"
        )
        
        let response = try await client.storage
            .from("profile-images")
            .upload(path: filePath, file: imageData)
        
        // Get the public URL for the uploaded image
        let publicURL = try client.storage
            .from("profile-images")
            .getPublicURL(path: filePath)
        
        print("SupabaseService: Profile image uploaded successfully to: \(publicURL)")
        return publicURL.absoluteString
    }
    
    func deleteProfileImage(userId: String, fileName: String) async throws {
        let filePath = "profiles/\(userId)/\(fileName)"
        
        try await client.storage
            .from("profile-images")
            .remove(paths: [filePath])
        
        print("SupabaseService: Deleted profile image: \(filePath)")
    }
    
    // MARK: - Enhanced Team Data Methods
    
    func fetchTeamMembers(teamId: String) async throws -> [TeamMemberWithProfile] {
        return try await TeamDataService.shared.fetchTeamMembers(teamId: teamId)
    }
    
    func fetchTeamWorkouts(teamId: String, period: String = "weekly") async throws -> [Workout] {
        return try await WorkoutDataService.shared.fetchTeamWorkouts(teamId: teamId, period: period)
    }
    
    func fetchTeamLeaderboard(teamId: String, type: String = "distance", period: String = "weekly") async throws -> [TeamLeaderboardMember] {
        return try await TeamDataService.shared.fetchTeamLeaderboard(teamId: teamId, type: type, period: period)
    }
    
    
    func fetchTeamActivity(teamId: String, limit: Int = 20) async throws -> [TeamActivity] {
        return try await TeamDataService.shared.fetchTeamActivity(teamId: teamId, limit: limit)
    }
    
    // MARK: - Real-time Subscriptions - Delegated to TeamDataService
    
    func subscribeToTeamUpdates(teamId: String, onUpdate: @escaping (Team) -> Void) {
        return TeamDataService.shared.subscribeToTeamUpdates(teamId: teamId, onUpdate: onUpdate)
    }
    
    func subscribeToLeaderboard(onUpdate: @escaping ([LeaderboardEntry]) -> Void) {
        return TeamDataService.shared.subscribeToLeaderboard(onUpdate: onUpdate)
    }
    
    func subscribeToTeamChat(teamId: String, onNewMessage: @escaping (TeamMessage) -> Void) {
        return TeamDataService.shared.subscribeToTeamChat(teamId: teamId, onNewMessage: onNewMessage)
    }
    
    // MARK: - Team Wallet Support Methods
    
    func isUserMemberOfTeam(userId: String, teamId: String) async throws -> Bool {
        return try await TeamDataService.shared.isUserMemberOfTeam(userId: userId, teamId: teamId)
    }
    
    func getTeam(_ teamId: String) async throws -> Team? {
        return try await TeamDataService.shared.getTeam(teamId)
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
        return try await TransactionDataService.shared.recordTransaction(teamId: teamId, userId: userId, walletId: walletId, amount: amount, type: type, description: description, metadata: metadata)
    }
    
    func registerUserForEvent(eventId: String, userId: String) async throws {
        return try await CompetitionDataService.shared.registerUserForEvent(eventId: eventId, userId: userId)
    }
    
    func getTeamWalletBalance(teamId: String) async throws -> Int {
        return try await TransactionDataService.shared.getTeamWalletBalance(teamId: teamId)
    }
    
    // MARK: - Bulk Query Methods for Payment Coordination
    
    func fetchAllActiveUsers() async throws -> [BasicUserInfo] {
        print("SupabaseService: Fetching all active users for payment coordination")
        
        let response = try await client
            .from("users")
            .select("id, email, display_name, created_at, last_active_at")
            .eq("is_active", value: true)
            .execute()
        
        let users = try customJSONDecoder().decode([BasicUserInfo].self, from: response.data)
        print("SupabaseService: Retrieved \(users.count) active users")
        return users
    }
    
    func fetchAllTeams() async throws -> [BasicTeamInfo] {
        print("SupabaseService: Fetching all teams for payment coordination")
        
        let response = try await client
            .from("teams")
            .select("id, name, captain_id, is_active, created_at, member_count")
            .eq("is_active", value: true)
            .execute()
        
        let teams = try customJSONDecoder().decode([BasicTeamInfo].self, from: response.data)
        print("SupabaseService: Retrieved \(teams.count) active teams")
        return teams
    }
    
    func fetchAllUserTransactions(since: Date) async throws -> [TransactionSummary] {
        print("SupabaseService: Fetching all user transactions since \(since)")
        
        let sinceString = ISO8601DateFormatter().string(from: since)
        
        let response = try await client
            .from("transactions")
            .select("id, user_id, amount, type, description, created_at")
            .gte("created_at", value: sinceString)
            .execute()
        
        let transactions = try customJSONDecoder().decode([TransactionSummary].self, from: response.data)
        print("SupabaseService: Retrieved \(transactions.count) transactions since \(since)")
        return transactions
    }
    
    func getPaymentCoordinationSummary() async throws -> PaymentCoordinationSummary {
        print("SupabaseService: Generating payment coordination summary")
        
        async let users = fetchAllActiveUsers()
        async let teams = fetchAllTeams()
        async let recentTransactions = fetchAllUserTransactions(since: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
        
        let (userList, teamList, transactionList) = try await (users, teams, recentTransactions)
        
        let summary = PaymentCoordinationSummary(
            totalActiveUsers: userList.count,
            totalActiveTeams: teamList.count,
            totalRecentTransactions: transactionList.count,
            totalTransactionVolume: transactionList.reduce(0) { $0 + abs($1.amount) },
            generatedAt: Date(),
            users: userList,
            teams: teamList,
            recentTransactions: transactionList
        )
        
        print("SupabaseService: Generated coordination summary - \(summary.totalActiveUsers) users, \(summary.totalActiveTeams) teams")
        return summary
    }
}

// MARK: - Core Data Models

// UserSession and UserProfile moved to AuthDataService
// Transaction models moved to TransactionDataService  
// Team models moved to TeamDataService
// Competition models moved to CompetitionDataService

// Workout model kept here as it's used by multiple services (HealthKitService, WorkoutDataService, TeamDataService)
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

// MARK: - Payment Coordination Data Models

struct BasicUserInfo: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let createdAt: Date
    let lastActiveAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
    }
}

struct BasicTeamInfo: Codable {
    let id: String
    let name: String
    let captainId: String
    let isActive: Bool
    let createdAt: Date
    let memberCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case captainId = "captain_id"
        case isActive = "is_active"
        case createdAt = "created_at"
        case memberCount = "member_count"
    }
}

struct TransactionSummary: Codable {
    let id: String
    let userId: String
    let amount: Int
    let type: String
    let description: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amount
        case type
        case description
        case createdAt = "created_at"
    }
}

struct PaymentCoordinationSummary: Codable {
    let totalActiveUsers: Int
    let totalActiveTeams: Int
    let totalRecentTransactions: Int
    let totalTransactionVolume: Int
    let generatedAt: Date
    let users: [BasicUserInfo]
    let teams: [BasicTeamInfo]
    let recentTransactions: [TransactionSummary]
}