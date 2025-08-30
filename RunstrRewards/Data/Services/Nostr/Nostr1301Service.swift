import Foundation
import HealthKit

class Nostr1301Service {
    static let shared = Nostr1301Service()
    
    private init() {}
    
    // MARK: - Data Models
    
    struct Nostr1301Event {
        let id: String
        let pubkey: String
        let createdAt: Date
        let content: Nostr1301Content
        let tags: [[String]]
        let signature: String
        
        // Computed properties
        var workoutId: String? {
            return tags.first { $0.first == "d" }?.dropFirst().first
        }
        
        var activityType: String? {
            return tags.first { $0.first == "activity" }?.dropFirst().first ?? content.type
        }
        
        var unitSystem: String? {
            return tags.first { $0.first == "unit" }?.dropFirst().first ?? "metric"
        }
        
        var location: String? {
            return tags.first { $0.first == "location" }?.dropFirst().first
        }
    }
    
    struct Nostr1301Content {
        let type: String
        let duration: TimeInterval
        let distance: Double?
        let pace: TimeInterval?
        let calories: Double?
        let elevationGain: Double?
        let averageHeartRate: Double?
        let maxHeartRate: Double?
        let route: [RoutePoint]?
        
        struct RoutePoint {
            let latitude: Double
            let longitude: Double
            let elevation: Double?
            let timestamp: Date?
        }
    }
    
    // MARK: - Workout Sync
    
    func syncWorkouts(for credentials: NostrKeyManager.NostrCredentials, since: Date? = nil, completion: @escaping (Result<[HealthKitWorkout], Nostr1301Error>) -> Void) {
        guard NostrRelayManager.shared.isConnectedToAnyRelay else {
            // Connect to relays first
            NostrRelayManager.shared.connectToRelays(credentials.relays)
            
            // Wait for connection and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.syncWorkouts(for: credentials, since: since, completion: completion)
            }
            return
        }
        
        print("Nostr1301Service: Starting workout sync for user: \(credentials.npub)")
        
        // Query for 1301 events
        query1301Events(pubkey: credentials.hexPublicKey, since: since) { [weak self] result in
            switch result {
            case .success(let events):
                print("Nostr1301Service: Found \(events.count) workout events")
                
                // Convert to HealthKitWorkout objects
                let workouts = self?.convertToHealthKitWorkouts(events) ?? []
                
                DispatchQueue.main.async {
                    completion(.success(workouts))
                }
                
            case .failure(let error):
                print("Nostr1301Service: Sync failed: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Event Querying
    
    private func query1301Events(pubkey: String, since: Date?, completion: @escaping (Result<[Nostr1301Event], Nostr1301Error>) -> Void) {
        // Create query filter for 1301 events
        var filter: [String: Any] = [
            "kinds": [1301],
            "authors": [pubkey],
            "limit": 100
        ]
        
        if let since = since {
            filter["since"] = Int(since.timeIntervalSince1970)
        }
        
        // Send query to all connected relays
        let query: [Any] = ["REQ", generateSubscriptionId(), filter]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: query)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            var collectedEvents: [Nostr1301Event] = []
            var responsesReceived = 0
            let expectedResponses = NostrRelayManager.shared.getConnectedRelayCount()
            
            // Subscribe to relay responses
            let subscriptionId = UUID().uuidString
            NostrRelayManager.shared.subscribe1301Events(subscriptionId: subscriptionId) { [weak self] event in
                if let parsedEvent = self?.parseNostr1301Event(event) {
                    collectedEvents.append(parsedEvent)
                }
            } onComplete: {
                responsesReceived += 1
                
                if responsesReceived >= expectedResponses {
                    // Remove duplicates based on event ID
                    let uniqueEvents = Array(Set(collectedEvents.map { $0.id })).compactMap { id in
                        collectedEvents.first { $0.id == id }
                    }
                    
                    completion(.success(uniqueEvents))
                }
            }
            
            // Send query to relays
            NostrRelayManager.shared.sendQuery(jsonString) { success, errors in
                if !success {
                    completion(.failure(.queryFailed(errors.joined(separator: ", "))))
                }
            }
            
            // Timeout after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                if responsesReceived < expectedResponses {
                    print("Nostr1301Service: Query timeout, proceeding with \(collectedEvents.count) events")
                    completion(.success(collectedEvents))
                }
            }
            
        } catch {
            completion(.failure(.querySerializationFailed(error.localizedDescription)))
        }
    }
    
    // MARK: - Event Parsing
    
    private func parseNostr1301Event(_ rawEvent: [String: Any]) -> Nostr1301Event? {
        guard let id = rawEvent["id"] as? String,
              let pubkey = rawEvent["pubkey"] as? String,
              let createdAtTimestamp = rawEvent["created_at"] as? Int,
              let contentString = rawEvent["content"] as? String,
              let tagsArray = rawEvent["tags"] as? [[String]],
              let signature = rawEvent["sig"] as? String else {
            print("Nostr1301Service: Invalid event format")
            return nil
        }
        
        // Parse content JSON
        guard let content = parseNostr1301Content(contentString) else {
            print("Nostr1301Service: Failed to parse content")
            return nil
        }
        
        let createdAt = Date(timeIntervalSince1970: TimeInterval(createdAtTimestamp))
        
        return Nostr1301Event(
            id: id,
            pubkey: pubkey,
            createdAt: createdAt,
            content: content,
            tags: tagsArray,
            signature: signature
        )
    }
    
    private func parseNostr1301Content(_ contentString: String) -> Nostr1301Content? {
        guard let data = contentString.data(using: .utf8) else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let type = json?["type"] as? String,
                  let duration = json?["duration"] as? Double else {
                return nil
            }
            
            let distance = json?["distance"] as? Double
            let pace = json?["pace"] as? Double
            let calories = json?["calories"] as? Double
            let elevationGain = json?["elevation_gain"] as? Double ?? json?["elevationGain"] as? Double
            let avgHeartRate = json?["average_heart_rate"] as? Double ?? json?["avgHeartRate"] as? Double
            let maxHeartRate = json?["max_heart_rate"] as? Double ?? json?["maxHeartRate"] as? Double
            
            // Parse route if present
            var route: [Nostr1301Content.RoutePoint]?
            if let routeArray = json?["route"] as? [[String: Any]] {
                route = routeArray.compactMap { point in
                    guard let lat = point["lat"] as? Double ?? point["latitude"] as? Double,
                          let lon = point["lon"] as? Double ?? point["longitude"] as? Double else {
                        return nil
                    }
                    
                    let elevation = point["elevation"] as? Double ?? point["alt"] as? Double
                    let timestamp = (point["timestamp"] as? Int).map { Date(timeIntervalSince1970: TimeInterval($0)) }
                    
                    return Nostr1301Content.RoutePoint(
                        latitude: lat,
                        longitude: lon,
                        elevation: elevation,
                        timestamp: timestamp
                    )
                }
            }
            
            return Nostr1301Content(
                type: type,
                duration: TimeInterval(duration),
                distance: distance,
                pace: pace.map { TimeInterval($0) },
                calories: calories,
                elevationGain: elevationGain,
                averageHeartRate: avgHeartRate,
                maxHeartRate: maxHeartRate,
                route: route
            )
            
        } catch {
            print("Nostr1301Service: JSON parsing error: \(error)")
            return nil
        }
    }
    
    // MARK: - HealthKit Conversion
    
    private func convertToHealthKitWorkouts(_ events: [Nostr1301Event]) -> [HealthKitWorkout] {
        return events.compactMap { event in
            convertToHealthKitWorkout(event)
        }
    }
    
    private func convertToHealthKitWorkout(_ event: Nostr1301Event) -> HealthKitWorkout? {
        // Convert activity type
        guard let hkActivityType = convertActivityType(event.content.type) else {
            print("Nostr1301Service: Unsupported activity type: \(event.content.type)")
            return nil
        }
        
        // Calculate end date
        let endDate = event.createdAt.addingTimeInterval(-event.content.duration)
        let startDate = endDate.addingTimeInterval(-event.content.duration)
        
        // Convert distance (assume meters if present)
        let totalDistance = event.content.distance
        
        return HealthKitWorkout(
            id: event.workoutId ?? event.id,
            activityType: hkActivityType,
            startDate: startDate,
            endDate: endDate,
            duration: event.content.duration,
            totalDistance: totalDistance,
            totalEnergyBurned: event.content.calories,
            // Additional Nostr metadata
            syncSource: .nostr,
            nostrEventId: event.id,
            nostrPubkey: event.pubkey,
            rawNostrContent: convertContentToDictionary(event.content)
        )
    }
    
    private func convertContentToDictionary(_ content: Nostr1301Content) -> [String: Any] {
        var dict: [String: Any] = [
            "type": content.type,
            "duration": content.duration
        ]
        
        if let distance = content.distance {
            dict["distance"] = distance
        }
        
        if let pace = content.pace {
            dict["pace"] = pace
        }
        
        if let calories = content.calories {
            dict["calories"] = calories
        }
        
        if let elevationGain = content.elevationGain {
            dict["elevationGain"] = elevationGain
        }
        
        if let averageHeartRate = content.averageHeartRate {
            dict["averageHeartRate"] = averageHeartRate
        }
        
        if let maxHeartRate = content.maxHeartRate {
            dict["maxHeartRate"] = maxHeartRate
        }
        
        return dict
    }
    
    private func convertActivityType(_ type: String) -> HKWorkoutActivityType? {
        switch type.lowercased() {
        case "run", "running":
            return .running
        case "walk", "walking":
            return .walking
        case "bike", "biking", "cycling":
            return .cycling
        case "swim", "swimming":
            return .swimming
        case "hike", "hiking":
            return .hiking
        case "yoga":
            return .yoga
        case "strength", "weightlifting", "weights":
            return .functionalStrengthTraining
        case "dance", "dancing":
            return .dance
        case "tennis":
            return .tennis
        case "basketball":
            return .basketball
        case "soccer", "football":
            return .soccer
        case "golf":
            return .golf
        case "rowing":
            return .rowing
        case "boxing", "kickboxing":
            return .kickboxing
        case "hiit", "crossfit", "cross_training":
            return .crossTraining
        default:
            return .other
        }
    }
    
    // MARK: - Real-time Subscription
    
    private var liveSubscriptions: [String: String] = [:] // subscriptionId -> pubkey
    private var liveWorkoutHandlers: [String: (HealthKitWorkout) -> Void] = [:]
    
    func subscribeToLiveWorkouts(for credentials: NostrKeyManager.NostrCredentials, onNewWorkout: @escaping (HealthKitWorkout) -> Void) -> String {
        guard NostrRelayManager.shared.isConnectedToAnyRelay else {
            print("Nostr1301Service: Cannot subscribe - no relay connection")
            return ""
        }
        
        let subscriptionId = "live_workouts_\(UUID().uuidString.prefix(8))"
        
        // Store subscription details
        liveSubscriptions[subscriptionId] = credentials.hexPublicKey
        liveWorkoutHandlers[subscriptionId] = onNewWorkout
        
        // Create subscription filter for real-time events
        let filter: [String: Any] = [
            "kinds": [1301],
            "authors": [credentials.hexPublicKey],
            "since": Int(Date().timeIntervalSince1970)
        ]
        
        let query: [Any] = ["REQ", subscriptionId, filter]
        
        // Send subscription to relays
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: query)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            // Subscribe to events
            NostrRelayManager.shared.subscribe1301Events(subscriptionId: subscriptionId) { [weak self] event in
                self?.handleLiveWorkoutEvent(subscriptionId: subscriptionId, event: event)
            } onComplete: {
                print("Nostr1301Service: Live subscription established for \(subscriptionId)")
            }
            
            // Send query to relays
            NostrRelayManager.shared.sendQuery(jsonString) { success, errors in
                if success {
                    print("Nostr1301Service: Live workout subscription active: \(subscriptionId)")
                } else {
                    print("Nostr1301Service: Failed to establish live subscription: \(errors)")
                }
            }
            
        } catch {
            print("Nostr1301Service: Failed to serialize live subscription query: \(error)")
            return ""
        }
        
        return subscriptionId
    }
    
    func unsubscribeFromLiveWorkouts(_ subscriptionId: String) {
        guard !subscriptionId.isEmpty else { return }
        
        print("Nostr1301Service: Unsubscribing from live workouts: \(subscriptionId)")
        
        // Remove from tracking
        liveSubscriptions.removeValue(forKey: subscriptionId)
        liveWorkoutHandlers.removeValue(forKey: subscriptionId)
        
        // Send unsubscribe to relays
        NostrRelayManager.shared.unsubscribe1301Events(subscriptionId: subscriptionId)
    }
    
    private func handleLiveWorkoutEvent(subscriptionId: String, event: [String: Any]) {
        guard let handler = liveWorkoutHandlers[subscriptionId] else {
            print("Nostr1301Service: No handler found for subscription: \(subscriptionId)")
            return
        }
        
        guard let parsedEvent = parseNostr1301Event(event),
              let workout = convertToHealthKitWorkout(parsedEvent) else {
            print("Nostr1301Service: Failed to parse live workout event")
            return
        }
        
        // Check if this is actually a new workout (not older than 1 minute)
        let eventAge = Date().timeIntervalSince(parsedEvent.createdAt)
        guard eventAge < 60 else {
            print("Nostr1301Service: Ignoring old workout event (age: \(eventAge)s)")
            return
        }
        
        print("Nostr1301Service: Processing new live workout: \(workout.activityType.displayName)")
        
        DispatchQueue.main.async {
            handler(workout)
        }
    }
    
    // MARK: - Subscription Management
    
    func getActiveSubscriptions() -> [String] {
        return Array(liveSubscriptions.keys)
    }
    
    func unsubscribeFromAll() {
        for subscriptionId in liveSubscriptions.keys {
            unsubscribeFromLiveWorkouts(subscriptionId)
        }
        print("Nostr1301Service: Unsubscribed from all live workout subscriptions")
    }
    
    // MARK: - Helper Methods
    
    private func generateSubscriptionId() -> String {
        return "workout_sync_\(UUID().uuidString.prefix(8))"
    }
    
    func getLastSyncDate() -> Date? {
        return UserDefaults.standard.object(forKey: "nostr_1301_last_sync") as? Date
    }
    
    func updateLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "nostr_1301_last_sync")
    }
    
    func getSyncedWorkoutCount() -> Int {
        return UserDefaults.standard.integer(forKey: "nostr_1301_workout_count")
    }
    
    func updateSyncedWorkoutCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: "nostr_1301_workout_count")
    }
}

// MARK: - Nostr 1301 Errors

enum Nostr1301Error: LocalizedError {
    case notAuthenticated
    case noRelayConnection
    case queryFailed(String)
    case querySerializationFailed(String)
    case parsingFailed(String)
    case conversionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated with Nostr"
        case .noRelayConnection:
            return "No connection to Nostr relays"
        case .queryFailed(let details):
            return "Failed to query workout events: \(details)"
        case .querySerializationFailed(let details):
            return "Failed to serialize query: \(details)"
        case .parsingFailed(let details):
            return "Failed to parse workout data: \(details)"
        case .conversionFailed(let details):
            return "Failed to convert to HealthKit format: \(details)"
        }
    }
}