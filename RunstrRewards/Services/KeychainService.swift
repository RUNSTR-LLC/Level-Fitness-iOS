import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.levelfitness.ios"
    
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
    }
    
    // MARK: - Save
    
    @discardableResult
    func save(_ value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing value
        delete(for: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("KeychainService: Error saving \(key.rawValue) - Status: \(status)")
            return false
        }
        
        return true
    }
    
    // MARK: - Load
    
    func load(for key: KeychainKey) -> String? {
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
    
    // MARK: - Delete
    
    @discardableResult
    func delete(for key: KeychainKey) -> Bool {
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
    
    // MARK: - Clear All
    
    func clearAll() {
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
    
    // MARK: - Check if exists
    
    func exists(for key: KeychainKey) -> Bool {
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