import Foundation
import CoreData

// MARK: - Offline Data Management

class OfflineDataService {
    static let shared = OfflineDataService()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    // MARK: - Cache Keys
    
    private enum CacheKey: String {
        case workouts = "cached_workouts"
        case teams = "cached_teams"
        case transactions = "cached_transactions"
        case events = "cached_events"
        case leaderboard = "cached_leaderboard"
        case userProfile = "cached_user_profile"
        case syncQueue = "sync_queue"
        case lastSyncTime = "last_sync_time"
        case pendingActions = "pending_actions"
    }
    
    // MARK: - Data Models
    
    struct CachedData<T: Codable>: Codable {
        let data: T
        let timestamp: Date
        let expirationDate: Date
        
        var isExpired: Bool {
            return Date() > expirationDate
        }
    }
    
    struct PendingAction: Codable {
        let id: String
        let type: ActionType
        let payload: Data
        let timestamp: Date
        let retryCount: Int
        
        enum ActionType: String, Codable {
            case syncWorkout = "sync_workout"
            case createTeam = "create_team"
            case joinTeam = "join_team"
            case sendMessage = "send_message"
            case createTransaction = "create_transaction"
            case updateProfile = "update_profile"
        }
    }
    
    private init() {
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access documents directory")
        }
        documentsDirectory = documentsDir
        setupOfflineStorage()
    }
    
    // MARK: - Setup
    
    private func setupOfflineStorage() {
        // Create offline data directory if it doesn't exist
        let offlineDirectory = documentsDirectory.appendingPathComponent("OfflineData")
        
        if !fileManager.fileExists(atPath: offlineDirectory.path) {
            try? fileManager.createDirectory(at: offlineDirectory, withIntermediateDirectories: true)
            print("📱 OfflineDataService: Created offline data directory")
        }
    }
    
    // MARK: - Caching Methods
    
    private func cache<T: Codable>(_ data: T, forKey key: CacheKey, expirationMinutes: Int = 60) {
        let expirationDate = Date().addingTimeInterval(TimeInterval(expirationMinutes * 60))
        let cachedData = CachedData(data: data, timestamp: Date(), expirationDate: expirationDate)
        
        do {
            let encoded = try JSONEncoder().encode(cachedData)
            userDefaults.set(encoded, forKey: key.rawValue)
            print("📱 OfflineDataService: Cached data for key: \(key.rawValue)")
        } catch {
            print("📱 OfflineDataService: Failed to cache data for key \(key.rawValue): \(error)")
        }
    }
    
    private func getCached<T: Codable>(_ type: T.Type, forKey key: CacheKey) -> T? {
        guard let data = userDefaults.data(forKey: key.rawValue) else { return nil }
        
        do {
            let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
            
            if cachedData.isExpired {
                removeCached(forKey: key)
                print("📱 OfflineDataService: Cache expired for key: \(key.rawValue)")
                return nil
            }
            
            print("📱 OfflineDataService: Retrieved cached data for key: \(key.rawValue)")
            return cachedData.data
        } catch {
            print("📱 OfflineDataService: Failed to decode cached data for key \(key.rawValue): \(error)")
            removeCached(forKey: key)
            return nil
        }
    }
    
    private func removeCached(forKey key: CacheKey) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
    
    // MARK: - Specific Data Caching
    
    func cacheWorkouts(_ workouts: [Workout]) {
        cache(workouts, forKey: .workouts, expirationMinutes: 30)
    }
    
    func getCachedWorkouts() -> [Workout]? {
        return getCached([Workout].self, forKey: .workouts)
    }
    
    func cacheTeams(_ teams: [Team]) {
        cache(teams, forKey: .teams, expirationMinutes: 15)
    }
    
    func getCachedTeams() -> [Team]? {
        return getCached([Team].self, forKey: .teams)
    }
    
    func cacheTransactions(_ transactions: [DatabaseTransaction]) {
        cache(transactions, forKey: .transactions, expirationMinutes: 60)
    }
    
    func getCachedTransactions() -> [DatabaseTransaction]? {
        return getCached([DatabaseTransaction].self, forKey: .transactions)
    }
    
    func cacheEvents(_ events: [CompetitionEvent]) {
        cache(events, forKey: .events, expirationMinutes: 30)
    }
    
    func getCachedEvents() -> [CompetitionEvent]? {
        return getCached([CompetitionEvent].self, forKey: .events)
    }
    
    func cacheLeaderboard(_ leaderboard: [LeaderboardUser]) {
        cache(leaderboard, forKey: .leaderboard, expirationMinutes: 10)
    }
    
    func getCachedLeaderboard() -> [LeaderboardUser]? {
        return getCached([LeaderboardUser].self, forKey: .leaderboard)
    }
    
    func cacheUserProfile(_ profile: UserProfile) {
        cache(profile, forKey: .userProfile, expirationMinutes: 120)
    }
    
    func getCachedUserProfile() -> UserProfile? {
        return getCached(UserProfile.self, forKey: .userProfile)
    }
    
    // MARK: - Pending Actions Queue
    
    func addPendingAction(_ action: PendingAction) {
        var queue = getPendingActions()
        queue.append(action)
        
        do {
            let encoded = try JSONEncoder().encode(queue)
            userDefaults.set(encoded, forKey: CacheKey.pendingActions.rawValue)
            print("📱 OfflineDataService: Added pending action: \(action.type.rawValue)")
        } catch {
            print("📱 OfflineDataService: Failed to save pending action: \(error)")
        }
    }
    
    func getPendingActions() -> [PendingAction] {
        guard let data = userDefaults.data(forKey: CacheKey.pendingActions.rawValue) else {
            return []
        }
        
        do {
            return try SupabaseService.shared.customJSONDecoder().decode([PendingAction].self, from: data)
        } catch {
            print("📱 OfflineDataService: Failed to decode pending actions: \(error)")
            return []
        }
    }
    
    func removePendingAction(withId id: String) {
        var queue = getPendingActions()
        queue.removeAll { $0.id == id }
        
        do {
            let encoded = try JSONEncoder().encode(queue)
            userDefaults.set(encoded, forKey: CacheKey.pendingActions.rawValue)
            print("📱 OfflineDataService: Removed pending action: \(id)")
        } catch {
            print("📱 OfflineDataService: Failed to update pending actions: \(error)")
        }
    }
    
    // MARK: - Sync Management
    
    func setLastSyncTime(_ time: Date) {
        userDefaults.set(time, forKey: CacheKey.lastSyncTime.rawValue)
    }
    
    func getLastSyncTime() -> Date? {
        return userDefaults.object(forKey: CacheKey.lastSyncTime.rawValue) as? Date
    }
    
    func shouldSync(minimumInterval: TimeInterval = 300) -> Bool { // 5 minutes default
        guard let lastSync = getLastSyncTime() else { return true }
        return Date().timeIntervalSince(lastSync) > minimumInterval
    }
    
    // MARK: - Offline Mode Detection
    
    private var isOfflineMode = false
    
    func setOfflineMode(_ offline: Bool) {
        isOfflineMode = offline
        
        if offline {
            print("📱 OfflineDataService: Entered offline mode - using cached data")
        } else {
            print("📱 OfflineDataService: Back online - will sync pending actions")
            Task {
                await processPendingActions()
            }
        }
    }
    
    func isOffline() -> Bool {
        return isOfflineMode
    }
    
    // MARK: - Data Sync Processing
    
    @MainActor
    func processPendingActions() async {
        let actions = getPendingActions()
        print("📱 OfflineDataService: Processing \(actions.count) pending actions")
        
        for action in actions {
            do {
                try await processAction(action)
                removePendingAction(withId: action.id)
            } catch {
                print("📱 OfflineDataService: Failed to process action \(action.type.rawValue): \(error)")
                
                // Increment retry count and re-queue if not exceeded
                if action.retryCount < 3 {
                    let retriedAction = PendingAction(
                        id: action.id,
                        type: action.type,
                        payload: action.payload,
                        timestamp: action.timestamp,
                        retryCount: action.retryCount + 1
                    )
                    
                    removePendingAction(withId: action.id)
                    addPendingAction(retriedAction)
                } else {
                    // Max retries exceeded, remove action
                    removePendingAction(withId: action.id)
                    print("📱 OfflineDataService: Max retries exceeded for action: \(action.id)")
                }
            }
        }
    }
    
    private func processAction(_ action: PendingAction) async throws {
        switch action.type {
        case .syncWorkout:
            let workout = try JSONDecoder().decode(Workout.self, from: action.payload)
            try await SupabaseService.shared.syncWorkout(workout)
            
        case .createTeam:
            let team = try JSONDecoder().decode(Team.self, from: action.payload)
            _ = try await SupabaseService.shared.createTeam(team)
            
        case .joinTeam:
            let joinData = try JSONDecoder().decode(JoinTeamData.self, from: action.payload)
            try await SupabaseService.shared.joinTeam(teamId: joinData.teamId, userId: joinData.userId)
            
        case .sendMessage:
            let messageData = try JSONDecoder().decode(SendMessageData.self, from: action.payload)
            try await SupabaseService.shared.sendTeamMessage(
                teamId: messageData.teamId,
                userId: messageData.userId,
                message: messageData.message,
                messageType: messageData.messageType
            )
            
        case .createTransaction:
            let transactionData = try JSONDecoder().decode(CreateTransactionData.self, from: action.payload)
            _ = try await SupabaseService.shared.createTransaction(
                userId: transactionData.userId,
                type: transactionData.type,
                amount: transactionData.amount,
                description: transactionData.description
            )
            
        case .updateProfile:
            let profile = try JSONDecoder().decode(UserProfile.self, from: action.payload)
            try await SupabaseService.shared.updateUserProfile(profile)
        }
        
        print("📱 OfflineDataService: Successfully processed \(action.type.rawValue)")
    }
    
    // MARK: - Cache Management
    
    func clearAllCache() {
        for key in [CacheKey.workouts, .teams, .transactions, .events, .leaderboard, .userProfile] {
            removeCached(forKey: key)
        }
        print("📱 OfflineDataService: Cleared all cached data")
    }
    
    func clearTeamsCache() {
        removeCached(forKey: .teams)
        print("📱 OfflineDataService: Teams cache cleared")
    }
    
    func getCacheInfo() -> String {
        let workoutCount = getCachedWorkouts()?.count ?? 0
        let teamCount = getCachedTeams()?.count ?? 0
        let transactionCount = getCachedTransactions()?.count ?? 0
        let eventCount = getCachedEvents()?.count ?? 0
        let leaderboardCount = getCachedLeaderboard()?.count ?? 0
        let pendingActionCount = getPendingActions().count
        let lastSync = getLastSyncTime()?.formatted() ?? "Never"
        
        return """
        Cache Status:
        • Workouts: \(workoutCount)
        • Teams: \(teamCount)
        • Transactions: \(transactionCount)
        • Events: \(eventCount)
        • Leaderboard: \(leaderboardCount)
        • Pending Actions: \(pendingActionCount)
        • Last Sync: \(lastSync)
        • Offline Mode: \(isOffline() ? "ON" : "OFF")
        """
    }
}

// MARK: - Helper Data Models

struct JoinTeamData: Codable {
    let teamId: String
    let userId: String
}

struct SendMessageData: Codable {
    let teamId: String
    let userId: String
    let message: String
    let messageType: String
}

struct CreateTransactionData: Codable {
    let userId: String
    let type: String
    let amount: Int
    let description: String
}

// MARK: - Convenience Extensions

extension OfflineDataService {
    
    func queueWorkoutSync(_ workout: Workout) {
        do {
            let payload = try JSONEncoder().encode(workout)
            let action = PendingAction(
                id: UUID().uuidString,
                type: .syncWorkout,
                payload: payload,
                timestamp: Date(),
                retryCount: 0
            )
            addPendingAction(action)
        } catch {
            print("📱 OfflineDataService: Failed to queue workout sync: \(error)")
        }
    }
    
    func queueTeamCreation(_ team: Team) {
        do {
            let payload = try JSONEncoder().encode(team)
            let action = PendingAction(
                id: UUID().uuidString,
                type: .createTeam,
                payload: payload,
                timestamp: Date(),
                retryCount: 0
            )
            addPendingAction(action)
        } catch {
            print("📱 OfflineDataService: Failed to queue team creation: \(error)")
        }
    }
    
    func queueMessage(teamId: String, userId: String, message: String) {
        do {
            let messageData = SendMessageData(
                teamId: teamId,
                userId: userId,
                message: message,
                messageType: "text"
            )
            let payload = try JSONEncoder().encode(messageData)
            let action = PendingAction(
                id: UUID().uuidString,
                type: .sendMessage,
                payload: payload,
                timestamp: Date(),
                retryCount: 0
            )
            addPendingAction(action)
        } catch {
            print("📱 OfflineDataService: Failed to queue message: \(error)")
        }
    }
}