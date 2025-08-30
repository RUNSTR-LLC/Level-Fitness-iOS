import Foundation
import Network

// MARK: - NostrProfile Data Model

struct NostrProfile: Codable {
    let displayName: String?    // User's display name (username)
    let about: String?         // Bio/description 
    let picture: String?       // Avatar image URL
    let banner: String?        // Banner image URL
    let nip05: String?         // NIP-05 verification (like email)
    
    var effectiveDisplayName: String {
        return displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false 
            ? displayName! 
            : "Nostr User"
    }
}

// MARK: - Profile Cache Manager

class NostrCacheManager {
    static let shared = NostrCacheManager()
    
    private struct CachedProfile: Codable {
        let profile: NostrProfile
        let timestamp: Date
    }
    
    private var profileCache: [String: CachedProfile] = [:]
    private let cacheExpirationInterval: TimeInterval = 4 * 60 * 60 // 4 hours
    
    private init() {}
    
    func getCachedProfile(pubkey: String) -> NostrProfile? {
        // Check in-memory cache first
        if let cached = profileCache[pubkey] {
            if !isCacheExpired(cached.timestamp) {
                print("NostrCacheManager: Cache hit for \(pubkey.prefix(8))")
                return cached.profile
            } else {
                profileCache.removeValue(forKey: pubkey)
                print("NostrCacheManager: Expired cache removed for \(pubkey.prefix(8))")
            }
        }
        
        // Check persistent storage
        return loadFromPersistentStorage(pubkey: pubkey)
    }
    
    func cacheProfile(pubkey: String, profile: NostrProfile) {
        let cached = CachedProfile(profile: profile, timestamp: Date())
        
        // Store in memory
        profileCache[pubkey] = cached
        
        // Store persistently
        saveToPersistentStorage(pubkey: pubkey, cached: cached)
        
        print("NostrCacheManager: Cached profile for \(pubkey.prefix(8)) - \(profile.effectiveDisplayName)")
    }
    
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        return Date().timeIntervalSince(timestamp) > cacheExpirationInterval
    }
    
    private func loadFromPersistentStorage(pubkey: String) -> NostrProfile? {
        let key = "nostr_profile_\(pubkey)"
        
        guard let data = UserDefaults.standard.data(forKey: key),
              let cached = try? JSONDecoder().decode(CachedProfile.self, from: data) else {
            return nil
        }
        
        if !isCacheExpired(cached.timestamp) {
            print("NostrCacheManager: Persistent cache hit for \(pubkey.prefix(8))")
            return cached.profile
        } else {
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }
    
    private func saveToPersistentStorage(pubkey: String, cached: CachedProfile) {
        let key = "nostr_profile_\(pubkey)"
        
        if let data = try? JSONEncoder().encode(cached) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - WebSocket Relay Connection

class NostrRelayConnection: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let relayURL: URL
    private var subscriptions: [String: (NostrProfile) -> Void] = [:]
    private let urlSession: URLSession
    
    init(relayURL: URL) {
        self.relayURL = relayURL
        self.urlSession = URLSession(configuration: .default)
        super.init()
    }
    
    func connect() async -> Bool {
        print("NostrRelayConnection: Connecting to \(relayURL.absoluteString)")
        
        webSocketTask = urlSession.webSocketTask(with: relayURL)
        webSocketTask?.resume()
        
        // Start listening for messages
        Task {
            await listenForMessages()
        }
        
        // Wait longer for connection to establish
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        print("NostrRelayConnection: Connection attempt completed for \(relayURL.absoluteString)")
        
        return webSocketTask?.state == .running
    }
    
    func fetchProfile(pubkeyHex: String, subscriptionId: String, completion: @escaping (NostrProfile?) -> Void) {
        subscriptions[subscriptionId] = completion
        
        print("NostrRelayConnection: Requesting profile for pubkey: \(pubkeyHex.prefix(16))...")
        
        // Create subscription request for Kind 0 events (profile metadata)
        let subscriptionRequest: [Any] = [
            "REQ",
            subscriptionId,
            [
                "kinds": [0],           // Profile metadata events
                "authors": [pubkeyHex], // Specific user's pubkey
                "limit": 1              // Latest profile only
            ]
        ]
        
        print("NostrRelayConnection: Sending subscription request: REQ \(subscriptionId) for kinds:[0]")
        sendMessage(subscriptionRequest)
    }
    
    private func sendMessage(_ message: [Any]) {
        guard let webSocketTask = webSocketTask else { 
            print("NostrRelayConnection: No WebSocket task available")
            return 
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            print("NostrRelayConnection: Sending message: \(jsonString)")
            
            let message = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask.send(message) { error in
                if let error = error {
                    print("NostrRelayConnection: Send error: \(error)")
                } else {
                    print("NostrRelayConnection: Message sent successfully")
                }
            }
        } catch {
            print("NostrRelayConnection: JSON serialization error: \(error)")
        }
    }
    
    private func listenForMessages() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            let message = try await webSocketTask.receive()
            
            switch message {
            case .string(let text):
                handleMessage(text)
            case .data(let data):
                if let text = String(data: data, encoding: .utf8) {
                    handleMessage(text)
                }
            @unknown default:
                break
            }
            
            // Continue listening
            await listenForMessages()
        } catch {
            print("NostrRelayConnection: Receive error: \(error)")
        }
    }
    
    private func handleMessage(_ text: String) {
        print("NostrRelayConnection: Received message: \(text.prefix(200))...")
        
        guard let data = text.data(using: .utf8),
              let messageArray = try? JSONSerialization.jsonObject(with: data) as? [Any],
              messageArray.count >= 2,
              let messageType = messageArray[0] as? String else {
            print("NostrRelayConnection: Failed to parse message as JSON array")
            return
        }
        
        print("NostrRelayConnection: Message type: \(messageType)")
        
        switch messageType {
        case "EVENT":
            if messageArray.count >= 3,
               let subscriptionId = messageArray[1] as? String,
               let eventDict = messageArray[2] as? [String: Any] {
                print("NostrRelayConnection: Processing EVENT for subscription \(subscriptionId)")
                handleProfileEvent(subscriptionId: subscriptionId, event: eventDict)
            } else {
                print("NostrRelayConnection: EVENT message malformed")
            }
        case "EOSE":
            if let subscriptionId = messageArray[1] as? String {
                print("NostrRelayConnection: End of stored events for subscription \(subscriptionId)")
            }
        case "OK":
            print("NostrRelayConnection: Received OK response")
        case "NOTICE":
            if let notice = messageArray[1] as? String {
                print("NostrRelayConnection: Notice from relay: \(notice)")
            }
        default:
            print("NostrRelayConnection: Unknown message type: \(messageType)")
        }
    }
    
    private func handleProfileEvent(subscriptionId: String, event: [String: Any]) {
        print("NostrRelayConnection: Parsing profile event: \(event)")
        
        guard let profile = parseProfileEvent(event) else {
            print("NostrRelayConnection: Failed to parse profile from event")
            return
        }
        
        guard let completion = subscriptions[subscriptionId] else {
            print("NostrRelayConnection: No completion handler found for subscription \(subscriptionId)")
            return
        }
        
        print("NostrRelayConnection: Successfully parsed profile: \(profile.effectiveDisplayName)")
        completion(profile)
        subscriptions.removeValue(forKey: subscriptionId)
    }
    
    private func parseProfileEvent(_ event: [String: Any]) -> NostrProfile? {
        // Verify Kind 0 event
        guard let kind = event["kind"] as? Int, kind == 0,
              let content = event["content"] as? String else {
            return nil
        }
        
        // Parse JSON content
        guard let contentData = content.data(using: .utf8),
              let profileDict = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            return nil
        }
        
        // Extract profile fields with fallbacks
        let displayName = profileDict["name"] as? String ??
                         profileDict["display_name"] as? String
        let about = profileDict["about"] as? String
        let picture = profileDict["picture"] as? String
        let banner = profileDict["banner"] as? String
        let nip05 = profileDict["nip05"] as? String
        
        return NostrProfile(
            displayName: displayName,
            about: about,
            picture: picture,
            banner: banner,
            nip05: nip05
        )
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        subscriptions.removeAll()
    }
}

// MARK: - Profile Fetcher Service

class NostrProfileFetcher {
    static let shared = NostrProfileFetcher()
    
    private let relayUrls = [
        "wss://relay.damus.io",
        "wss://nos.lol", 
        "wss://relay.primal.net"
    ]
    
    private var activeConnections: [NostrRelayConnection] = []
    private let fetchTimeout: TimeInterval = 15.0  // Increased timeout for better reliability
    
    private init() {}
    
    func fetchProfile(pubkeyHex: String) async -> NostrProfile? {
        print("NostrProfileFetcher: Fetching profile for \(pubkeyHex.prefix(8))...")
        
        return await withTimeout(fetchTimeout) {
            await self.fetchFromRelays(pubkeyHex: pubkeyHex)
        }
    }
    
    private func fetchFromRelays(pubkeyHex: String) async -> NostrProfile? {
        // Try each relay sequentially
        for relayUrlString in relayUrls {
            guard let relayURL = URL(string: relayUrlString) else { continue }
            
            print("NostrProfileFetcher: Trying relay \(relayUrlString)")
            
            let connection = NostrRelayConnection(relayURL: relayURL)
            
            if await connection.connect() {
                let profile = await fetchFromConnection(connection: connection, pubkeyHex: pubkeyHex)
                connection.disconnect()
                
                if let profile = profile {
                    print("NostrProfileFetcher: Successfully fetched profile from \(relayUrlString)")
                    return profile
                }
            }
        }
        
        print("NostrProfileFetcher: No profile found in any relay")
        return nil
    }
    
    private func fetchFromConnection(connection: NostrRelayConnection, pubkeyHex: String) async -> NostrProfile? {
        return await withTimeout(10.0) { // 10 second timeout per connection
            await withCheckedContinuation { continuation in
                let subscriptionId = UUID().uuidString
                
                connection.fetchProfile(pubkeyHex: pubkeyHex, subscriptionId: subscriptionId) { profile in
                    continuation.resume(returning: profile)
                }
            }
        }
    }
    
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async -> T?) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
}

// MARK: - Main Profile Display Service

@MainActor
class NostrProfileDisplayService: ObservableObject {
    static let shared = NostrProfileDisplayService()
    
    @Published private(set) var profiles: [String: NostrProfile] = [:]
    @Published private(set) var isLoading: [String: Bool] = [:]
    
    private let cacheManager = NostrCacheManager.shared
    private let profileFetcher = NostrProfileFetcher.shared
    
    private init() {}
    
    /// Get display name for pubkey with caching
    func getDisplayName(for pubkey: String) -> String {
        // Check cache first
        if let profile = cacheManager.getCachedProfile(pubkey: pubkey),
           let displayName = profile.displayName, !displayName.isEmpty {
            return displayName
        }
        
        // Trigger background fetch if not cached
        if isLoading[pubkey] != true {
            Task {
                await fetchProfile(for: pubkey)
            }
        }
        
        // Return fallback while loading
        return "npub1" + String(pubkey.prefix(8)) + "..." // Show first 8 chars of pubkey
    }
    
    /// Get avatar URL for pubkey with caching
    func getAvatarURL(for pubkey: String) -> String? {
        if let profile = cacheManager.getCachedProfile(pubkey: pubkey) {
            return profile.picture
        }
        
        // Trigger background fetch
        if isLoading[pubkey] != true {
            Task {
                await fetchProfile(for: pubkey)
            }
        }
        
        return nil // No avatar available yet
    }
    
    /// Fetch profile data from Nostr relays
    private func fetchProfile(for pubkey: String) async {
        // Avoid duplicate fetches
        if isLoading[pubkey] == true {
            return
        }
        
        isLoading[pubkey] = true
        
        // Use hex pubkey directly (assuming it's already in hex format)
        let hexPubkey = pubkey
        
        // Fetch from relays
        if let profile = await profileFetcher.fetchProfile(pubkeyHex: hexPubkey) {
            // Cache the result
            cacheManager.cacheProfile(pubkey: pubkey, profile: profile)
            
            // Update UI
            profiles[pubkey] = profile
        }
        
        isLoading[pubkey] = false
    }
}