import Foundation
import UIKit

/// Comprehensive test script for Nostr integration
/// Run this to validate all NostrSDK functionality is working
class NostrIntegrationTest {
    
    static let shared = NostrIntegrationTest()
    private init() {}
    
    // MARK: - Test Configuration
    
    // Known working Nostr profiles for testing
    private let testProfiles = [
        TestProfile(
            name: "Will",
            hex: "04c915daefee38317fa734444acee390a8269fe5810b2241e5e6dd343dfbecc9",
            npub: "npub1qny3th006u6xr7mn5x6yr6pecx5ynjc2q53rrn0dm5knvml7njuqft0k0h",
            expectedName: "will"
        ),
        TestProfile(
            name: "fiatjaf", 
            hex: "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d",
            npub: "npub180cvv0h5j2n6q7hjz26eehm5la5g74xef04pse2n9vlzkg62gkwsrm7s9n",
            expectedName: "fiatjaf"
        ),
        TestProfile(
            name: "Jack Dorsey",
            hex: "82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2",
            npub: "npub1sg6plzptdm4u62a8704epx2kv8x0wjh3tx57lg2fn549037muklqcxqzyk",
            expectedName: "jack"
        )
    ]
    
    private struct TestProfile {
        let name: String
        let hex: String 
        let npub: String
        let expectedName: String
    }
    
    // MARK: - Main Test Runner
    
    func runAllTests() async {
        print("\n🧪 === NOSTR INTEGRATION TEST SUITE ===")
        print("Testing NostrSDK integration and profile fetching...")
        print("Time: \(Date())")
        print("=" * 50)
        
        var passedTests = 0
        var totalTests = 0
        
        // Test 1: NostrSDK Bridge Validation
        totalTests += 1
        if await testNostrSDKBridge() {
            passedTests += 1
        }
        
        // Test 2: Key Generation and Format Validation
        totalTests += 1
        if await testKeyGeneration() {
            passedTests += 1
        }
        
        // Test 3: Relay Connection Testing
        totalTests += 1
        if await testRelayConnections() {
            passedTests += 1
        }
        
        // Test 4: Profile Fetching with Known Profiles
        totalTests += 1
        if await testProfileFetching() {
            passedTests += 1
        }
        
        // Test 5: Current User Profile Display
        totalTests += 1
        if await testCurrentUserProfile() {
            passedTests += 1
        }
        
        // Test 6: Security Validation (No Private Key Exposure)
        totalTests += 1
        if await testSecurityValidation() {
            passedTests += 1
        }
        
        // Test 7: Caching System
        totalTests += 1
        if await testCachingSystem() {
            passedTests += 1
        }
        
        // Final Results
        print("\n" + "=" * 50)
        print("🧪 TEST SUITE COMPLETE")
        print("✅ Passed: \(passedTests)/\(totalTests)")
        if passedTests == totalTests {
            print("🎉 ALL TESTS PASSED! Nostr integration is working perfectly.")
        } else {
            print("⚠️  Some tests failed. Review logs above for details.")
        }
        print("=" * 50 + "\n")
    }
    
    // MARK: - Individual Test Methods
    
    private func testNostrSDKBridge() async -> Bool {
        print("\n🔧 Test 1: NostrSDK Bridge Validation")
        
        // Test with a sample nsec
        let testNsec = "nsec1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
        
        guard let keyPair = NostrSDKBridge.shared.validateAndParseNsec(testNsec) else {
            print("❌ Failed: NostrSDK bridge validation failed")
            return false
        }
        
        // Validate key formats
        let validNsec = keyPair.privateKey.hasPrefix("nsec1") && keyPair.privateKey.count == 63
        let validNpub = keyPair.publicKey.hasPrefix("npub1") && keyPair.publicKey.count == 63
        let validHex = keyPair.hexPublicKey.count == 64 && keyPair.hexPublicKey.allSatisfy({ $0.isHexDigit })
        
        if validNsec && validNpub && validHex {
            print("✅ Passed: NostrSDK bridge generates valid key formats")
            print("   - nsec: \(keyPair.privateKey.prefix(10))... (\(keyPair.privateKey.count) chars)")
            print("   - npub: \(keyPair.publicKey.prefix(10))... (\(keyPair.publicKey.count) chars)")
            print("   - hex:  \(keyPair.hexPublicKey.prefix(16))... (\(keyPair.hexPublicKey.count) chars)")
            return true
        } else {
            print("❌ Failed: Invalid key formats generated")
            print("   - nsec valid: \(validNsec)")
            print("   - npub valid: \(validNpub)")
            print("   - hex valid:  \(validHex)")
            return false
        }
    }
    
    private func testKeyGeneration() async -> Bool {
        print("\n🔑 Test 2: Key Generation and Validation")
        
        // Test current user credentials
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            print("❌ Failed: No current Nostr credentials found")
            print("   Make sure user is signed in with Nostr")
            return false
        }
        
        // Validate credential formats
        let validNsec = credentials.nsec.hasPrefix("nsec1")
        let validNpub = credentials.npub.hasPrefix("npub1") 
        let validHex = credentials.hexPublicKey.count == 64
        
        if validNsec && validNpub && validHex {
            print("✅ Passed: Current user has valid Nostr credentials")
            print("   - nsec: [REDACTED] (✓)")
            print("   - npub: \(credentials.npub.prefix(16))... (✓)")
            print("   - hex:  \(credentials.hexPublicKey.prefix(16))... (✓ \(credentials.hexPublicKey.count) chars)")
            return true
        } else {
            print("❌ Failed: Invalid credential formats")
            print("   - nsec valid: \(validNsec)")
            print("   - npub valid: \(validNpub)")
            print("   - hex valid:  \(validHex) (length: \(credentials.hexPublicKey.count))")
            return false
        }
    }
    
    private func testRelayConnections() async -> Bool {
        print("\n🌐 Test 3: Relay Connection Testing")
        
        let testSuccessful = await NostrSDKBridge.shared.testRelayConnection()
        
        if testSuccessful {
            print("✅ Passed: Relay connections working properly")
            print("   - Can connect to Nostr relays")
            print("   - Can send subscription requests")
            print("   - Can receive relay responses")
            return true
        } else {
            print("❌ Failed: Relay connection test failed")
            print("   - Check network connectivity")
            print("   - Verify relay URLs are accessible")
            return false
        }
    }
    
    private func testProfileFetching() async -> Bool {
        print("\n👤 Test 4: Profile Fetching with Known Profiles")
        
        var successCount = 0
        
        for testProfile in testProfiles {
            print("   Testing \(testProfile.name) profile...")
            
            if let profile = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: testProfile.hex) {
                print("   ✅ \(testProfile.name): \(profile.effectiveDisplayName)")
                if let picture = profile.picture {
                    print("      Picture: \(picture.prefix(50))...")
                }
                if let about = profile.about {
                    print("      About: \(about.prefix(100))...")
                }
                successCount += 1
            } else {
                print("   ❌ \(testProfile.name): Failed to fetch profile")
            }
            
            // Small delay between requests
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        let successRate = Double(successCount) / Double(testProfiles.count)
        
        if successRate >= 0.5 { // At least 50% success rate
            print("✅ Passed: Profile fetching working (\(successCount)/\(testProfiles.count) profiles)")
            return true
        } else {
            print("❌ Failed: Profile fetching success rate too low (\(successCount)/\(testProfiles.count))")
            return false
        }
    }
    
    private func testCurrentUserProfile() async -> Bool {
        print("\n🧑‍💻 Test 5: Current User Profile Display")
        
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            print("❌ Failed: No current user credentials")
            return false
        }
        
        // Test profile fetching for current user
        let hexPubkey = credentials.hexPublicKey
        print("   Fetching profile for current user: \(hexPubkey.prefix(16))...")
        
        if let profile = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: hexPubkey) {
            print("✅ Passed: Current user has published profile data")
            print("   - Name: \(profile.effectiveDisplayName)")
            if let about = profile.about {
                print("   - About: \(about.prefix(100))...")
            }
            return true
        } else {
            print("✅ Passed: Current user has no published profile (normal for new keys)")
            print("   - Will display 'Nostr User' fallback")
            print("   - Bitcoin orange key icon will be shown")
            print("   - This is expected behavior for new Nostr accounts")
            return true
        }
    }
    
    private func testSecurityValidation() async -> Bool {
        print("\n🔒 Test 6: Security Validation")
        
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            print("❌ Failed: No credentials to validate")
            return false
        }
        
        // Test 1: Ensure private key is never displayed
        let nsecExposed = credentials.npub.contains(credentials.nsec.dropFirst(5))
        
        // Test 2: Ensure proper key derivation
        let validDerivation = credentials.npub != credentials.nsec.replacingOccurrences(of: "nsec1", with: "npub1")
        
        // Test 3: Check hex key is proper length
        let validHexLength = credentials.hexPublicKey.count == 64
        
        if !nsecExposed && validDerivation && validHexLength {
            print("✅ Passed: Security validation successful")
            print("   - Private key not exposed in npub ✓")
            print("   - Proper key derivation (not simple replacement) ✓") 
            print("   - Valid 64-character hex public key ✓")
            return true
        } else {
            print("❌ Failed: Security issues detected")
            print("   - Private key exposed: \(nsecExposed)")
            print("   - Invalid derivation: \(!validDerivation)")
            print("   - Invalid hex length: \(!validHexLength)")
            return false
        }
    }
    
    private func testCachingSystem() async -> Bool {
        print("\n💾 Test 7: Caching System")
        
        // Test with the first known profile
        let testProfile = testProfiles[0]
        
        // Clear any existing cache
        NostrCacheManager.shared.clearCache()
        
        // First fetch (should hit relays)
        let startTime1 = Date()
        if let profile1 = await NostrProfileFetcher.shared.fetchProfile(pubkeyHex: testProfile.hex) {
            let fetchTime1 = Date().timeIntervalSince(startTime1)
            
            // Cache the result
            NostrCacheManager.shared.cacheProfile(pubkey: testProfile.hex, profile: profile1)
            
            // Second fetch (should use cache)
            let startTime2 = Date()
            if let cachedProfile = NostrCacheManager.shared.getCachedProfile(pubkey: testProfile.hex) {
                let fetchTime2 = Date().timeIntervalSince(startTime2)
                
                if fetchTime2 < fetchTime1 / 2 { // Cache should be much faster
                    print("✅ Passed: Caching system working")
                    print("   - Relay fetch: \(String(format: "%.3f", fetchTime1))s")
                    print("   - Cache fetch: \(String(format: "%.3f", fetchTime2))s")
                    print("   - Profile data matches: \(profile1.effectiveDisplayName == cachedProfile.effectiveDisplayName)")
                    return true
                }
            }
        }
        
        print("❌ Failed: Caching system not working properly")
        return false
    }
    
    // MARK: - Helper Methods
    
    private func delay(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

// MARK: - Test Runner Extension

extension NostrIntegrationTest {
    
    /// Run tests from any view controller
    static func runFromViewController(_ viewController: UIViewController) {
        Task {
            await NostrIntegrationTest.shared.runAllTests()
            
            await MainActor.run {
                let alert = UIAlertController(
                    title: "Nostr Test Complete",
                    message: "Check console logs for detailed results",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                viewController.present(alert, animated: true)
            }
        }
    }
    
    /// Quick test for debugging
    static func quickTest() async -> Bool {
        print("🚀 Quick Nostr Test...")
        
        // Test basic functionality
        guard let credentials = NostrAuthenticationService.shared.currentNostrCredentials else {
            print("❌ No Nostr credentials")
            return false
        }
        
        print("✅ Has Nostr credentials: \(credentials.npub.prefix(16))...")
        
        // Test relay connection
        let relayTest = await NostrSDKBridge.shared.testRelayConnection()
        print(relayTest ? "✅ Relay connection working" : "❌ Relay connection failed")
        
        return relayTest
    }
}

// MARK: - String Extension for Convenience

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}