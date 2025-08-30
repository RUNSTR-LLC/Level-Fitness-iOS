import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.levelfitness.ios"
    
    // Serial queue for thread-safe Keychain access
    private let keychainQueue = DispatchQueue(label: "com.levelfitness.keychain.queue", attributes: .concurrent)
    
    private init() {}
    
    enum KeychainKey: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case userEmail = "user_email"
        case bitcoinWalletKey = "bitcoin_wallet_key"
        case coinOSToken = "coinos_token"
        case coinOSUsername = "coinos_username"
        case coinOSPassword = "coinos_password"
        // Nostr keys
        case nostrPrivateKey = "nostr_private_key"
        case nostrPublicKey = "nostr_public_key"
        case nostrRelays = "nostr_relays"
    }
    
    // MARK: - Save
    
    @discardableResult
    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Use barrier flag for write operations to ensure thread safety
        return keychainQueue.sync(flags: .barrier) {
            // First, try to update existing item
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key.rawValue
            ]
            
            let updateQuery: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            var status = SecItemUpdate(searchQuery as CFDictionary, updateQuery as CFDictionary)
            
            if status == errSecItemNotFound {
                // Item doesn't exist, add it
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: key.rawValue,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ]
                
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }
            
            if status != errSecSuccess {
                print("KeychainService: Error saving \(key.rawValue) - Status: \(status)")
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Load
    
    func load(for key: KeychainKey) -> String? {
        // Use concurrent read for better performance
        return keychainQueue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key.rawValue,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            
            if status == errSecSuccess,
               let data = dataTypeRef as? Data,
               let value = String(data: data, encoding: .utf8) {
                return value
            }
            
            if status != errSecItemNotFound {
                print("KeychainService: Error loading \(key.rawValue) - Status: \(status)")
            }
            
            return nil
        }
    }
    
    // MARK: - Delete
    
    @discardableResult
    func delete(for key: KeychainKey) -> Bool {
        // Use barrier flag for write operations to ensure thread safety
        return keychainQueue.sync(flags: .barrier) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key.rawValue
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            
            if status != errSecSuccess && status != errSecItemNotFound {
                print("KeychainService: Error deleting \(key.rawValue) - Status: \(status)")
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        // Use barrier flag for write operations to ensure thread safety
        keychainQueue.sync(flags: .barrier) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            
            if status == errSecSuccess {
                print("KeychainService: All items cleared")
            } else if status != errSecItemNotFound {
                print("KeychainService: Error clearing all items - Status: \(status)")
            }
        }
    }
    
    // MARK: - Check if exists
    
    func exists(for key: KeychainKey) -> Bool {
        // Use concurrent read for better performance
        return keychainQueue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: key.rawValue,
                kSecReturnData as String: false
            ]
            
            let status = SecItemCopyMatching(query as CFDictionary, nil)
            return status == errSecSuccess
        }
    }
    
    // MARK: - Custom Key Methods (for team-specific storage)
    
    @discardableResult
    func saveCustom(_ value: String, for customKey: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Use barrier flag for write operations to ensure thread safety
        return keychainQueue.sync(flags: .barrier) {
            // First, try to update existing item
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: customKey
            ]
            
            let updateQuery: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            var status = SecItemUpdate(searchQuery as CFDictionary, updateQuery as CFDictionary)
            
            if status == errSecItemNotFound {
                // Item doesn't exist, create new one
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: customKey,
                    kSecValueData as String: data,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ]
                
                status = SecItemAdd(addQuery as CFDictionary, nil)
            }
            
            if status == errSecSuccess {
                print("KeychainService: ✅ Saved custom key '\(customKey)' successfully")
                return true
            } else {
                print("KeychainService: ❌ Failed to save custom key '\(customKey)' - Status: \(status)")
                return false
            }
        }
    }
    
    func loadCustom(for customKey: String) -> String? {
        // Use concurrent read for better performance
        return keychainQueue.sync {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: customKey,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            guard status == errSecSuccess,
                  let data = result as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                if status != errSecItemNotFound {
                    print("KeychainService: ❌ Failed to load custom key '\(customKey)' - Status: \(status)")
                }
                return nil
            }
            
            print("KeychainService: ✅ Loaded custom key '\(customKey)' successfully")
            return string
        }
    }
    
    @discardableResult
    func deleteCustom(for customKey: String) -> Bool {
        return keychainQueue.sync(flags: .barrier) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: customKey
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            
            if status == errSecSuccess || status == errSecItemNotFound {
                print("KeychainService: ✅ Deleted custom key '\(customKey)' successfully")
                return true
            } else {
                print("KeychainService: ❌ Failed to delete custom key '\(customKey)' - Status: \(status)")
                return false
            }
        }
    }
}