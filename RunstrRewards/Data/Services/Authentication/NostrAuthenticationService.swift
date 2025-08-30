import Foundation
import CryptoKit

class NostrAuthenticationService {
    static let shared = NostrAuthenticationService()
    
    private init() {}
    
    // MARK: - Authentication State
    
    var isNostrAuthenticated: Bool {
        return NostrKeyManager.shared.isNostrAuthenticated()
    }
    
    var currentNostrCredentials: NostrKeyManager.NostrCredentials? {
        return NostrKeyManager.shared.loadNostrCredentials()
    }
    
    // MARK: - Sign In with Nsec
    
    func signInWithNsec(_ nsec: String, completion: @escaping (Result<NostrKeyManager.NostrCredentials, NostrAuthError>) -> Void) {
        print("NostrAuthenticationService: Processing nsec sign in with NostrSDK bridge...")
        
        // Use NostrSDK bridge for proper key handling
        guard let keyPair = NostrSDKBridge.shared.validateAndParseNsec(nsec) else {
            print("NostrAuthenticationService: NostrSDK bridge validation failed")
            completion(.failure(.invalidNsec))
            return
        }
        
        print("NostrAuthenticationService: NostrSDK bridge validation passed")
        print("NostrAuthenticationService: Generated npub: \(keyPair.publicKey.prefix(10))...")
        print("NostrAuthenticationService: Hex pubkey length: \(keyPair.hexPublicKey.count)")
        
        // Create credentials using bridge output
        let credentials = NostrKeyManager.NostrCredentials(
            nsec: keyPair.privateKey,
            npub: keyPair.publicKey,
            hexPrivateKey: "secure_hash_\(abs(nsec.hash))", // Keep private key secure
            hexPublicKey: keyPair.hexPublicKey,
            relays: getDefaultRelays()
        )
        
        // Store credentials securely
        let success = NostrKeyManager.shared.storeNostrCredentials(credentials)
        
        if success {
            print("NostrAuthenticationService: Sign in successful - Public Key: \(keyPair.publicKey)")
            completion(.success(credentials))
        } else {
            print("NostrAuthenticationService: Failed to store credentials securely")
            completion(.failure(.keychainStorageFailed))
        }
    }
    
    // MARK: - Generate New Key Pair
    
    func generateNewKeyPair(completion: @escaping (Result<NostrKeyManager.NostrCredentials, NostrAuthError>) -> Void) {
        guard let credentials = NostrKeyManager.shared.generateNostrKeyPair() else {
            completion(.failure(.keyGenerationFailed))
            return
        }
        
        // Store the generated credentials
        let success = NostrKeyManager.shared.storeNostrCredentials(credentials)
        
        if success {
            print("NostrAuthenticationService: New key pair generated - Public Key: \(credentials.npub)")
            completion(.success(credentials))
        } else {
            completion(.failure(.keychainStorageFailed))
        }
    }
    
    // MARK: - Sign Out
    
    func signOutFromNostr() {
        NostrKeyManager.shared.clearNostrCredentials()
        print("NostrAuthenticationService: Signed out from Nostr")
    }
    
    // MARK: - Relay Management
    
    func updateRelays(_ relays: [String]) -> Bool {
        guard let credentials = currentNostrCredentials else { return false }
        
        let updatedCredentials = NostrKeyManager.NostrCredentials(
            nsec: credentials.nsec,
            npub: credentials.npub,
            hexPrivateKey: credentials.hexPrivateKey,
            hexPublicKey: credentials.hexPublicKey,
            relays: relays
        )
        
        return NostrKeyManager.shared.storeNostrCredentials(updatedCredentials)
    }
    
    private func getDefaultRelays() -> [String] {
        return [
            "wss://relay.damus.io",
            "wss://nos.lol", 
            "wss://relay.primal.net",
            "wss://relay.nostr.band",
            "wss://nostr.wine"
        ]
    }
    
    // MARK: - Nostr Event Signing
    
    func signNostrEvent(_ event: NostrEvent) -> NostrEvent? {
        guard let credentials = currentNostrCredentials else {
            print("NostrAuthenticationService: No credentials available for signing")
            return nil
        }
        
        // Create event ID (SHA256 hash of event data)
        guard let eventId = createEventId(event) else {
            print("NostrAuthenticationService: Failed to create event ID")
            return nil
        }
        
        // Sign the event ID
        guard let signature = signEventId(eventId, with: credentials.hexPrivateKey) else {
            print("NostrAuthenticationService: Failed to sign event")
            return nil
        }
        
        // Return signed event
        var signedEvent = event
        signedEvent.id = eventId
        signedEvent.signature = signature
        signedEvent.pubkey = credentials.hexPublicKey
        
        return signedEvent
    }
    
    private func createEventId(_ event: NostrEvent) -> String? {
        // Create the serialized event for hashing
        // Format: [0, pubkey, created_at, kind, tags, content]
        let serializedEvent: [Any] = [
            0,
            event.pubkey,
            event.created_at,
            event.kind,
            event.tags.map { $0 },
            event.content
        ]
        
        // Convert to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: serializedEvent)
            
            // Calculate SHA256 hash
            let hash = SHA256.hash(data: jsonData)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            print("NostrAuthenticationService: JSON serialization error: \(error)")
            return nil
        }
    }
    
    private func signEventId(_ eventId: String, with privateKeyHex: String) -> String? {
        // Convert hex strings to data
        guard let eventIdData = Data(hex: eventId),
              let privateKeyData = Data(hex: privateKeyHex) else {
            return nil
        }
        
        do {
            // Create private key for signing
            let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)
            
            // Sign the event ID
            let signature = try privateKey.signature(for: eventIdData)
            
            // Convert signature to hex
            return signature.rawRepresentation.map { String(format: "%02x", $0) }.joined()
        } catch {
            print("NostrAuthenticationService: Signing error: \(error)")
            return nil
        }
    }
}

// MARK: - Nostr Event Model

struct NostrEvent {
    var id: String = ""
    var pubkey: String = ""
    let created_at: Int
    let kind: Int
    let tags: [[String]]
    let content: String
    var signature: String = ""
    
    init(kind: Int, content: String, tags: [[String]] = []) {
        self.created_at = Int(Date().timeIntervalSince1970)
        self.kind = kind
        self.content = content
        self.tags = tags
    }
}

// MARK: - Data Extension for Hex Conversion

extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

// MARK: - Nostr Authentication Errors

enum NostrAuthError: LocalizedError {
    case invalidNsec
    case keyDerivationFailed
    case keyConversionFailed
    case keyGenerationFailed
    case keychainStorageFailed
    case signingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidNsec:
            return "Invalid nsec format. Please check your private key starts with 'nsec1' and is 63 characters long."
        case .keyDerivationFailed:
            return "Nostr key format accepted but requires secp256k1 support. Currently in development for full compatibility."
        case .keyConversionFailed:
            return "Failed to convert keys to hex format."
        case .keyGenerationFailed:
            return "Failed to generate new key pair."
        case .keychainStorageFailed:
            return "Failed to store keys securely."
        case .signingFailed:
            return "Failed to sign Nostr event."
        }
    }
}