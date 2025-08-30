import Foundation
import UIKit
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
        
        let userSession = UserSession(
            id: response.user.id.uuidString,
            email: response.user.email,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken
        )
        
        // Ensure profile exists for new users
        Task.detached {
            do {
                try await self.ensureProfileExists(for: userSession)
            } catch {
                print("AuthDataService: Warning - Failed to ensure profile exists: \(error)")
            }
        }
        
        return userSession
    }
    
    private func ensureProfileExists(for session: UserSession) async throws {
        // Check if profile already exists
        let existingProfile = try? await fetchUserProfile(userId: session.id)
        
        if existingProfile == nil {
            print("AuthDataService: Creating initial profile for new user: \(session.id)")
            
            // Extract username from email if available
            var initialUsername: String? = nil
            if let email = session.email {
                initialUsername = email.components(separatedBy: "@").first
            }
            
            // Create basic profile structure
            try await syncLocalProfileToSupabase(
                userId: session.id,
                username: initialUsername,
                fullName: initialUsername
            )
        }
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
        try await syncLocalProfileToSupabase(userId: userId, username: username, fullName: fullName, avatarUrl: nil)
    }
    
    func syncLocalProfileToSupabase(userId: String, username: String?, fullName: String?, avatarUrl: String?) async throws {
        print("AuthDataService: Syncing local profile data to Supabase for user: \(userId)")
        
        // First check if profile exists
        let existingProfile = try? await fetchUserProfile(userId: userId)
        
        if existingProfile == nil {
            // Profile doesn't exist, create it with upsert
            print("AuthDataService: Profile doesn't exist, creating new profile for user: \(userId)")
            
            struct ProfileUpsert: Encodable {
                let id: String
                let username: String?
                let fullName: String?
                let email: String?
                let avatarUrl: String?
                let createdAt: String
                let updatedAt: String
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case username
                    case fullName = "full_name"
                    case email
                    case avatarUrl = "avatar_url"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                }
            }
            
            // Try to get email from current session
            let currentUser = try? await getCurrentUser()
            let userEmail = currentUser?.email
            
            let newProfile = ProfileUpsert(
                id: userId,
                username: username?.isEmpty == false ? username : nil,
                fullName: fullName?.isEmpty == false ? fullName : nil,
                email: userEmail,
                avatarUrl: avatarUrl,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await client
                .from("profiles")
                .upsert(newProfile)
                .execute()
                
            print("AuthDataService: Successfully created new profile for user: \(userId)")
        } else {
            // Profile exists, update it
            print("AuthDataService: Profile exists, updating profile for user: \(userId)")
            
            struct ProfileUpdate: Encodable {
                let username: String?
                let fullName: String?
                let avatarUrl: String?
                let updatedAt: String
                
                enum CodingKeys: String, CodingKey {
                    case username
                    case fullName = "full_name"
                    case avatarUrl = "avatar_url"
                    case updatedAt = "updated_at"
                }
            }
            
            let updateData = ProfileUpdate(
                username: username?.isEmpty == false ? username : nil,
                fullName: fullName?.isEmpty == false ? fullName : nil,
                avatarUrl: avatarUrl,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await client
                .from("profiles")
                .update(updateData)
                .eq("id", value: userId)
                .execute()
                
            print("AuthDataService: Successfully updated profile for user: \(userId)")
        }
    }
    
    // MARK: - Profile Image Upload Methods
    
    func uploadProfileImage(_ imageData: Data, userId: String) async throws -> String {
        // Validate and compress image data
        let processedImageData = try validateAndCompressImage(imageData)
        
        // Generate unique filename with timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "avatar_\(timestamp).jpg"
        
        // Upload to Supabase Storage
        let avatarUrl = try await SupabaseService.shared.uploadProfileImage(processedImageData, userId: userId, fileName: fileName)
        
        // Update user profile with new avatar URL
        try await syncLocalProfileToSupabase(userId: userId, username: nil, fullName: nil, avatarUrl: avatarUrl)
        
        print("AuthDataService: Profile image uploaded and profile updated with URL: \(avatarUrl)")
        return avatarUrl
    }
    
    private func validateAndCompressImage(_ imageData: Data) throws -> Data {
        // Validate file size (max 5MB)
        let maxSizeBytes = 5 * 1024 * 1024
        if imageData.count > maxSizeBytes {
            throw ProfileImageError.fileTooLarge
        }
        
        // Validate that it's actually an image
        guard let image = UIImage(data: imageData) else {
            throw ProfileImageError.invalidImageFormat
        }
        
        // Validate minimum dimensions (at least 50x50)
        if image.size.width < 50 || image.size.height < 50 {
            throw ProfileImageError.imageTooSmall
        }
        
        // Resize and compress for optimal storage
        let resizedImage = resizeImageForProfile(image)
        guard let compressedData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw ProfileImageError.compressionFailed
        }
        
        print("AuthDataService: Image processed - original: \(imageData.count) bytes, compressed: \(compressedData.count) bytes")
        return compressedData
    }
    
    private func resizeImageForProfile(_ image: UIImage) -> UIImage {
        // Target size for profile images (512x512 max)
        let targetSize = CGSize(width: 512, height: 512)
        
        // Only resize if image is larger than target
        if image.size.width <= targetSize.width && image.size.height <= targetSize.height {
            return image
        }
        
        // Calculate aspect ratio and new size
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if aspectRatio > 1 {
            // Landscape
            newSize = CGSize(width: targetSize.width, height: targetSize.width / aspectRatio)
        } else {
            // Portrait or square
            newSize = CGSize(width: targetSize.height * aspectRatio, height: targetSize.height)
        }
        
        // Ensure minimum size
        if newSize.width < 128 { newSize.width = 128 }
        if newSize.height < 128 { newSize.height = 128 }
        
        // Create resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    func updateProfileWithImage(userId: String, username: String?, fullName: String?, imageData: Data?) async throws -> String? {
        var avatarUrl: String?
        
        // Upload image if provided
        if let imageData = imageData {
            avatarUrl = try await uploadProfileImage(imageData, userId: userId)
        }
        
        // Update profile with all data
        try await syncLocalProfileToSupabase(userId: userId, username: username, fullName: fullName, avatarUrl: avatarUrl)
        
        return avatarUrl
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

// MARK: - Profile Image Errors

enum ProfileImageError: LocalizedError {
    case fileTooLarge
    case invalidImageFormat
    case imageTooSmall
    case compressionFailed
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "Profile image file is too large. Please choose an image smaller than 5MB."
        case .invalidImageFormat:
            return "Invalid image format. Please choose a JPEG or PNG image."
        case .imageTooSmall:
            return "Image is too small. Please choose an image that's at least 50x50 pixels."
        case .compressionFailed:
            return "Failed to process image. Please try a different image."
        case .uploadFailed(let message):
            return "Failed to upload image: \(message)"
        }
    }
}