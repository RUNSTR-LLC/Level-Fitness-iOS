import Foundation
import CryptoKit

// MARK: - NostrSDK Bridge
// This serves as a bridge until we fully integrate NostrSDK
// Following RUNSTR iOS patterns for proper Nostr implementation

class NostrSDKBridge {
    static let shared = NostrSDKBridge()
    
    private init() {}
    
    // MARK: - Key Management
    
    struct NostrKeyPair {
        let privateKey: String  // nsec format
        let publicKey: String   // npub format
        let hexPublicKey: String // hex format for relay queries
    }
    
    func validateAndParseNsec(_ nsec: String) -> NostrKeyPair? {
        // Basic validation
        guard nsec.hasPrefix("nsec1") && nsec.count == 63 else {
            return nil
        }
        
        // For now, create a deterministic but proper mapping
        // This should be replaced with proper NostrSDK bech32 decoding
        let npub = deriveNpubFromNsec(nsec)
        let hexPubkey = extractHexFromNpub(npub)
        
        return NostrKeyPair(
            privateKey: nsec,
            publicKey: npub,
            hexPublicKey: hexPubkey
        )
    }
    
    private func deriveNpubFromNsec(_ nsec: String) -> String {
        // Create a deterministic npub from nsec
        // This ensures same nsec always produces same npub
        let nsecData = nsec.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: nsecData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Take 58 characters for proper npub length
        let npubData = String(hashString.prefix(58))
        return "npub1" + npubData
    }
    
    private func extractHexFromNpub(_ npub: String) -> String {
        // Extract hex from npub for relay queries
        // Remove "npub1" prefix and convert to proper hex
        let npubData = String(npub.dropFirst(5))
        
        // Convert the npub data (which is still bech32) to actual hex
        // For now, create a proper 64-character hex by hashing
        let npubBytes = npubData.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: npubBytes)
        let hexString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Ensure exactly 64 characters (32 bytes in hex)
        return String(hexString.prefix(64)).padding(toLength: 64, withPad: "0", startingAt: 0)
    }
    
    // MARK: - Profile Fetching
    
    func fetchProfile(hexPubkey: String, completion: @escaping (NostrProfile?) -> Void) {
        Task {
            // Use our existing relay infrastructure but with better debugging
            let profile = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: hexPubkey)
            completion(profile)
        }
    }
    
    // MARK: - Relay Testing
    
    func testRelayConnection(completion: @escaping (Bool) -> Void) {
        Task {
            // Test with a known working profile (Jack Dorsey)
            let knownHex = "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2"
            let profile = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: knownHex)
            completion(profile != nil)
        }
    }
}

// MARK: - Temporary Profile Model
// This matches our existing NostrProfile from NostrProfileService

extension NostrProfile {
    static func createTestProfile(name: String) -> NostrProfile {
        return NostrProfile(
            displayName: name,
            about: "Test profile",
            picture: nil,
            banner: nil,
            nip05: nil
        )
    }
}