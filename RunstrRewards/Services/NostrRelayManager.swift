import Foundation
import Network

class NostrRelayManager {
    static let shared = NostrRelayManager()
    
    private var webSocketTasks: [String: URLSessionWebSocketTask] = [:]
    private var urlSession: URLSession
    private let queue = DispatchQueue(label: "nostr.relay.manager", qos: .userInitiated)
    
    // Connection status tracking
    private var connectedRelays: Set<String> = []
    private var connectionAttempts: [String: Int] = [:]
    private let maxRetryAttempts = 3
    
    // Event publishing
    private var pendingEvents: [NostrEvent] = []
    private var publishedEventIds: Set<String> = []
    
    // 1301 Event subscriptions
    private var activeSubscriptions: [String: Subscription1301] = [:]
    
    struct Subscription1301 {
        let id: String
        let onEvent: ([String: Any]) -> Void
        let onComplete: () -> Void
        var isActive: Bool = true
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Connection Management
    
    func connectToRelays(_ relayUrls: [String]) {
        queue.async {
            for relayUrl in relayUrls {
                self.connectToRelay(relayUrl)
            }
        }
    }
    
    private func connectToRelay(_ relayUrl: String) {
        guard let url = URL(string: relayUrl) else {
            print("NostrRelayManager: Invalid relay URL: \(relayUrl)")
            return
        }
        
        // Close existing connection if any
        disconnectFromRelay(relayUrl)
        
        let webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTasks[relayUrl] = webSocketTask
        
        // Start listening for messages
        listenForMessages(from: webSocketTask, relayUrl: relayUrl)
        
        // Resume the connection
        webSocketTask.resume()
        
        print("NostrRelayManager: Connecting to relay: \(relayUrl)")
        
        // Monitor connection status
        monitorConnection(webSocketTask, relayUrl: relayUrl)
    }
    
    private func monitorConnection(_ webSocketTask: URLSessionWebSocketTask, relayUrl: String) {
        webSocketTask.resume()
        
        // Send a ping to check connection
        webSocketTask.sendPing { [weak self] error in
            if let error = error {
                print("NostrRelayManager: Connection failed to \(relayUrl): \(error)")
                self?.handleConnectionFailure(relayUrl)
            } else {
                print("NostrRelayManager: Connected to relay: \(relayUrl)")
                self?.queue.async {
                    self?.connectedRelays.insert(relayUrl)
                    self?.connectionAttempts[relayUrl] = 0
                    
                    // Process any pending events
                    self?.processPendingEvents()
                }
            }
        }
    }
    
    private func handleConnectionFailure(_ relayUrl: String) {
        queue.async {
            self.connectedRelays.remove(relayUrl)
            let attempts = self.connectionAttempts[relayUrl, default: 0] + 1
            self.connectionAttempts[relayUrl] = attempts
            
            if attempts < self.maxRetryAttempts {
                print("NostrRelayManager: Retrying connection to \(relayUrl) (attempt \(attempts))")
                
                // Retry after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(attempts * 2)) {
                    self.connectToRelay(relayUrl)
                }
            } else {
                print("NostrRelayManager: Max retry attempts reached for \(relayUrl)")
            }
        }
    }
    
    func disconnectFromRelay(_ relayUrl: String) {
        queue.async {
            if let webSocketTask = self.webSocketTasks[relayUrl] {
                webSocketTask.cancel(with: .goingAway, reason: nil)
                self.webSocketTasks.removeValue(forKey: relayUrl)
                self.connectedRelays.remove(relayUrl)
                print("NostrRelayManager: Disconnected from relay: \(relayUrl)")
            }
        }
    }
    
    func disconnectFromAllRelays() {
        queue.async {
            for (relayUrl, webSocketTask) in self.webSocketTasks {
                webSocketTask.cancel(with: .goingAway, reason: nil)
                print("NostrRelayManager: Disconnected from relay: \(relayUrl)")
            }
            
            self.webSocketTasks.removeAll()
            self.connectedRelays.removeAll()
            self.connectionAttempts.removeAll()
        }
    }
    
    // MARK: - Message Handling
    
    private func listenForMessages(from webSocketTask: URLSessionWebSocketTask, relayUrl: String) {
        webSocketTask.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message, from: relayUrl)
                
                // Continue listening
                if self?.connectedRelays.contains(relayUrl) == true {
                    self?.listenForMessages(from: webSocketTask, relayUrl: relayUrl)
                }
                
            case .failure(let error):
                print("NostrRelayManager: Message receive error from \(relayUrl): \(error)")
                self?.handleConnectionFailure(relayUrl)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message, from relayUrl: String) {
        switch message {
        case .string(let text):
            print("NostrRelayManager: Received message from \(relayUrl): \(text)")
            
            // Parse Nostr message
            if let data = text.data(using: .utf8) {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [Any],
                       let messageType = jsonArray.first as? String {
                        
                        switch messageType {
                        case "OK":
                            handleOKMessage(jsonArray, from: relayUrl)
                        case "NOTICE":
                            handleNoticeMessage(jsonArray, from: relayUrl)
                        case "EVENT":
                            handleEventMessage(jsonArray, from: relayUrl)
                        case "EOSE":
                            handleEOSEMessage(jsonArray, from: relayUrl)
                        default:
                            print("NostrRelayManager: Unknown message type: \(messageType)")
                        }
                    }
                } catch {
                    print("NostrRelayManager: JSON parsing error: \(error)")
                }
            }
            
        case .data(let data):
            print("NostrRelayManager: Received binary data from \(relayUrl): \(data.count) bytes")
            
        @unknown default:
            print("NostrRelayManager: Unknown message type from \(relayUrl)")
        }
    }
    
    private func handleOKMessage(_ jsonArray: [Any], from relayUrl: String) {
        // OK message format: ["OK", <event_id>, <true/false>, <message>]
        guard jsonArray.count >= 3,
              let eventId = jsonArray[1] as? String,
              let success = jsonArray[2] as? Bool else {
            return
        }
        
        let message = jsonArray.count > 3 ? jsonArray[3] as? String : nil
        
        if success {
            print("NostrRelayManager: Event \(eventId) successfully published to \(relayUrl)")
            publishedEventIds.insert(eventId)
        } else {
            print("NostrRelayManager: Event \(eventId) failed to publish to \(relayUrl): \(message ?? "Unknown error")")
        }
    }
    
    private func handleNoticeMessage(_ jsonArray: [Any], from relayUrl: String) {
        // NOTICE message format: ["NOTICE", <message>]
        guard jsonArray.count >= 2,
              let notice = jsonArray[1] as? String else {
            return
        }
        
        print("NostrRelayManager: Notice from \(relayUrl): \(notice)")
    }
    
    private func handleEventMessage(_ jsonArray: [Any], from relayUrl: String) {
        // EVENT message format: ["EVENT", <subscription_id>, <event_object>]
        guard jsonArray.count >= 3,
              let subscriptionId = jsonArray[1] as? String,
              let eventObject = jsonArray[2] as? [String: Any] else {
            return
        }
        
        // Check if this is a 1301 event
        if let kind = eventObject["kind"] as? Int, kind == 1301 {
            print("NostrRelayManager: Received 1301 event from \(relayUrl)")
            
            // Find matching subscription
            if let subscription = activeSubscriptions[subscriptionId] {
                subscription.onEvent(eventObject)
            }
        }
    }
    
    private func handleEOSEMessage(_ jsonArray: [Any], from relayUrl: String) {
        // EOSE message format: ["EOSE", <subscription_id>]
        guard jsonArray.count >= 2,
              let subscriptionId = jsonArray[1] as? String else {
            return
        }
        
        print("NostrRelayManager: End of stored events for subscription \(subscriptionId) from \(relayUrl)")
        
        // Notify subscription completion
        if let subscription = activeSubscriptions[subscriptionId] {
            subscription.onComplete()
        }
    }
    
    // MARK: - Event Publishing
    
    func publishEvent(_ event: NostrEvent, completion: @escaping (Bool, [String]) -> Void) {
        queue.async {
            guard !self.connectedRelays.isEmpty else {
                print("NostrRelayManager: No connected relays available")
                DispatchQueue.main.async {
                    completion(false, ["No connected relays"])
                }
                return
            }
            
            // Sign the event if not already signed
            var eventToPublish = event
            if eventToPublish.signature.isEmpty {
                guard let signedEvent = NostrAuthenticationService.shared.signNostrEvent(event) else {
                    print("NostrRelayManager: Failed to sign event")
                    DispatchQueue.main.async {
                        completion(false, ["Failed to sign event"])
                    }
                    return
                }
                eventToPublish = signedEvent
            }
            
            // Convert event to JSON
            do {
                let eventDict: [String: Any] = [
                    "id": eventToPublish.id,
                    "pubkey": eventToPublish.pubkey,
                    "created_at": eventToPublish.created_at,
                    "kind": eventToPublish.kind,
                    "tags": eventToPublish.tags,
                    "content": eventToPublish.content,
                    "sig": eventToPublish.signature
                ]
                
                let eventMessage = ["EVENT", eventDict]
                let jsonData = try JSONSerialization.data(withJSONObject: eventMessage)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                
                var publishedRelays: [String] = []
                var errors: [String] = []
                
                // Publish to all connected relays
                let group = DispatchGroup()
                
                for relayUrl in self.connectedRelays {
                    if let webSocketTask = self.webSocketTasks[relayUrl] {
                        group.enter()
                        
                        webSocketTask.send(.string(jsonString)) { error in
                            if let error = error {
                                print("NostrRelayManager: Failed to send to \(relayUrl): \(error)")
                                errors.append("Failed to send to \(relayUrl): \(error.localizedDescription)")
                            } else {
                                print("NostrRelayManager: Event sent to \(relayUrl)")
                                publishedRelays.append(relayUrl)
                            }
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: DispatchQueue.main) {
                    let success = !publishedRelays.isEmpty
                    completion(success, errors)
                }
                
            } catch {
                print("NostrRelayManager: JSON serialization error: \(error)")
                DispatchQueue.main.async {
                    completion(false, ["JSON serialization error: \(error.localizedDescription)"])
                }
            }
        }
    }
    
    private func processPendingEvents() {
        guard !pendingEvents.isEmpty && !connectedRelays.isEmpty else { return }
        
        print("NostrRelayManager: Processing \(pendingEvents.count) pending events")
        
        let eventsToProcess = pendingEvents
        pendingEvents.removeAll()
        
        for event in eventsToProcess {
            publishEvent(event) { success, errors in
                if !success {
                    print("NostrRelayManager: Failed to publish pending event: \(errors)")
                }
            }
        }
    }
    
    // MARK: - Connection Status
    
    var isConnectedToAnyRelay: Bool {
        return !connectedRelays.isEmpty
    }
    
    var connectionStatus: [String: Bool] {
        var status: [String: Bool] = [:]
        for (relayUrl, _) in webSocketTasks {
            status[relayUrl] = connectedRelays.contains(relayUrl)
        }
        return status
    }
    
    func getConnectedRelayCount() -> Int {
        return connectedRelays.count
    }
    
    // MARK: - 1301 Event Subscriptions
    
    func subscribe1301Events(subscriptionId: String, onEvent: @escaping ([String: Any]) -> Void, onComplete: @escaping () -> Void) {
        let subscription = Subscription1301(
            id: subscriptionId,
            onEvent: onEvent,
            onComplete: onComplete
        )
        
        activeSubscriptions[subscriptionId] = subscription
        print("NostrRelayManager: Registered 1301 subscription: \(subscriptionId)")
    }
    
    func unsubscribe1301Events(subscriptionId: String) {
        activeSubscriptions.removeValue(forKey: subscriptionId)
        
        // Send CLOSE message to relays
        let closeMessage = ["CLOSE", subscriptionId]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: closeMessage)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            for (relayUrl, webSocketTask) in webSocketTasks {
                if connectedRelays.contains(relayUrl) {
                    webSocketTask.send(.string(jsonString)) { error in
                        if let error = error {
                            print("NostrRelayManager: Failed to send CLOSE to \(relayUrl): \(error)")
                        }
                    }
                }
            }
        } catch {
            print("NostrRelayManager: Failed to serialize CLOSE message: \(error)")
        }
        
        print("NostrRelayManager: Unsubscribed from 1301 events: \(subscriptionId)")
    }
    
    func sendQuery(_ query: String, completion: @escaping (Bool, [String]) -> Void) {
        var successfulRelays: [String] = []
        var errors: [String] = []
        let group = DispatchGroup()
        
        for (relayUrl, webSocketTask) in webSocketTasks {
            if connectedRelays.contains(relayUrl) {
                group.enter()
                
                webSocketTask.send(.string(query)) { error in
                    if let error = error {
                        errors.append("Failed to query \(relayUrl): \(error.localizedDescription)")
                    } else {
                        successfulRelays.append(relayUrl)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            let success = !successfulRelays.isEmpty
            completion(success, errors)
        }
    }
}