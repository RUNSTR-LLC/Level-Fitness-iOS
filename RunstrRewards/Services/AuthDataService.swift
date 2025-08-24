import Foundation
import Supabase

class AuthDataService {
    static let shared = AuthDataService()
    
    private var client: SupabaseClient {
        return SupabaseService.shared.client
    }
    
    private init() {}
    
    // MARK: - Authentication Methods
    
    func signInWithApple(idToken: String, nonce: String) async throws -> UserSession? {
        let response = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        
        // Use real Supabase session tokens for proper authentication
        return UserSession(
            id: response.user.id.uuidString,
            email: response.user.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> UserSession? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        
        let user = try await client.auth.user()
        
        return UserSession(
            id: user.id.uuidString,
            email: user.email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
    }
    
    func restoreSession(accessToken: String, refreshToken: String) async throws {
        // Restore the Supabase session using stored tokens
        print("AuthDataService: Attempting to restore session with tokens: \(accessToken.prefix(10))..., \(refreshToken.prefix(10))...")
        try await client.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
        print("AuthDataService: Session restored successfully")
        
        // Verify the session was restored
        if let session = try? await client.auth.session {
            print("AuthDataService: Verified session exists for user: \(session.user.id)")
        } else {
            print("AuthDataService: Warning - No session found after restoration")
        }
    }
    
    // MARK: - User Profile Methods
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        // Clean the user ID of any quotes that might have been passed incorrectly
        let cleanUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Try cached data first if offline
        if !NetworkMonitorService.shared.isCurrentlyConnected() {
            if let cached = OfflineDataService.shared.getCachedUserProfile() {
                print("AuthDataService: Using cached user profile (offline)")
                return cached
            }
            throw AppError.networkUnavailable
        }
        
        do {
            let response = try await client
                .from("profiles")
                .select()
                .eq("id", value: cleanUserId)
                .single()
                .execute()
            
            let data = response.data
            let decoder = SupabaseService.shared.customJSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: data)
            
            // Cache the result
            OfflineDataService.shared.cacheUserProfile(profile)
            
            return profile
        } catch {
            ErrorHandlingService.shared.logError(error, context: "fetchUserProfile", userId: userId)
            
            // Try to return cached data as fallback
            if let cached = OfflineDataService.shared.getCachedUserProfile() {
                print("AuthDataService: Using cached user profile (error fallback)")
                return cached
            }
            
            throw error
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        try await client
            .from("profiles")
            .update(profile)
            .eq("id", value: profile.id)
            .execute()
    }
    
    func syncLocalProfileToSupabase(userId: String, username: String?, fullName: String?) async throws {
        print("AuthDataService: Syncing local profile data to Supabase for user: \(userId)")
        
        // Create a proper Encodable struct for the update
        struct ProfileUpdate: Encodable {
            let username: String?
            let fullName: String?
            let updatedAt: String
            
            enum CodingKeys: String, CodingKey {
                case username
                case fullName = "full_name"
                case updatedAt = "updated_at"
            }
        }
        
        let updateData = ProfileUpdate(
            username: username?.isEmpty == false ? username : nil,
            fullName: fullName?.isEmpty == false ? fullName : nil,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("profiles")
            .update(updateData)
            .eq("id", value: userId)
            .execute()
        
        print("AuthDataService: Successfully synced profile data for user: \(userId)")
    }
}

// MARK: - Data Models

struct UserSession: Codable, Sendable {
    let id: String
    let email: String?
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

struct UserProfile: Codable, Sendable {
    let id: String
    let email: String?
    let username: String?
    let fullName: String?
    let avatarUrl: String?
    let totalWorkouts: Int?
    let totalDistance: Double?
    let totalEarnings: Double?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case totalWorkouts = "total_workouts"
        case totalDistance = "total_distance"
        case totalEarnings = "total_earnings"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}