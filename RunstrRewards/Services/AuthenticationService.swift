import Foundation
import AuthenticationServices
import CryptoKit
import Supabase

class AuthenticationService: NSObject {
    static let shared = AuthenticationService()
    
    private var currentNonce: String?
    private var signInCompletion: ((Result<UserSession, Error>) -> Void)?
    
    var currentUserId: String? {
        return KeychainService.shared.load(for: .userId)
    }
    
    private override init() {
        super.init()
        
        // One-time migration to fix stored user IDs with quotes
        migrateStoredUserIdIfNeeded()
    }
    
    private func migrateStoredUserIdIfNeeded() {
        // Check if we have a stored user ID that needs conversion
        if let storedUserId = KeychainService.shared.load(for: .userId) {
            // Remove any quotes first
            let cleanUserId = storedUserId.replacingOccurrences(of: "\"", with: "")
            
            // Check if this is an Apple ID format (contains dots but not a valid UUID)
            if cleanUserId.contains(".") && !isValidUUID(cleanUserId) {
                // Convert Apple ID to a deterministic UUID
                let uuid = generateUUIDFromAppleId(cleanUserId)
                print("AuthenticationService: Converting Apple ID to UUID")
                print("  From: \(cleanUserId)")
                print("  To: \(uuid)")
                KeychainService.shared.save(uuid, for: .userId)
            } else if cleanUserId != storedUserId {
                // Just needed quote cleaning
                print("AuthenticationService: Cleaning user ID quotes")
                KeychainService.shared.save(cleanUserId, for: .userId)
            }
        }
    }
    
    private func isValidUUID(_ string: String) -> Bool {
        return UUID(uuidString: string) != nil
    }
    
    private func generateUUIDFromAppleId(_ appleId: String) -> String {
        // Generate a deterministic UUID from the Apple ID using SHA256
        // This ensures the same Apple ID always maps to the same UUID
        guard let data = appleId.data(using: .utf8) else {
            return UUID().uuidString
        }
        
        // Create SHA256 hash of the Apple ID
        let hash = SHA256.hash(data: data)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Take first 32 characters and format as UUID
        let hex = String(hashString.prefix(32))
        
        // Format as a valid UUID (8-4-4-4-12)
        let uuid = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
        
        // Verify it's a valid UUID
        if UUID(uuidString: uuid) != nil {
            return uuid.lowercased()
        }
        
        // Fallback to a new UUID if something went wrong
        return UUID().uuidString
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple(presentingViewController: UIViewController, completion: @escaping (Result<UserSession, Error>) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce
        signInCompletion = completion
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Session Management
    
    func saveSession(_ session: UserSession) {
        // Clean the user ID of any quotes or invalid characters
        var finalUserId = session.id.replacingOccurrences(of: "\"", with: "")
        
        // If this is an Apple ID format, convert it to UUID
        if finalUserId.contains(".") && !isValidUUID(finalUserId) {
            finalUserId = generateUUIDFromAppleId(finalUserId)
            print("AuthenticationService: Converting Apple ID to UUID during save: \(finalUserId)")
        }
        
        KeychainService.shared.save(session.accessToken, for: .accessToken)
        KeychainService.shared.save(session.refreshToken, for: .refreshToken)
        KeychainService.shared.save(finalUserId, for: .userId)
        
        if let email = session.email {
            KeychainService.shared.save(email, for: .userEmail)
        }
        
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        print("AuthenticationService: Session saved with user ID: \(finalUserId)")
    }
    
    func loadSession() -> UserSession? {
        guard UserDefaults.standard.bool(forKey: "isAuthenticated"),
              let accessToken = KeychainService.shared.load(for: .accessToken),
              let refreshToken = KeychainService.shared.load(for: .refreshToken),
              let userId = KeychainService.shared.load(for: .userId) else {
            return nil
        }
        
        // Clean the user ID of any quotes that might have been stored incorrectly
        var finalUserId = userId.replacingOccurrences(of: "\"", with: "")
        
        // Check if this is an Apple ID format that needs conversion to UUID
        if finalUserId.contains(".") && !isValidUUID(finalUserId) {
            finalUserId = generateUUIDFromAppleId(finalUserId)
            print("AuthenticationService: Converting Apple ID to UUID for session")
            KeychainService.shared.save(finalUserId, for: .userId)
        } else if finalUserId != userId {
            // Just needed quote cleaning
            print("AuthenticationService: Cleaned user ID quotes")
            KeychainService.shared.save(finalUserId, for: .userId)
        }
        
        let email = KeychainService.shared.load(for: .userEmail)
        
        // Restore Supabase session if we have real tokens (not temp tokens)
        if accessToken != "temp_token" && refreshToken != "temp_refresh_token" {
            Task {
                do {
                    try await SupabaseService.shared.restoreSession(accessToken: accessToken, refreshToken: refreshToken)
                    print("AuthenticationService: Supabase session restored successfully")
                } catch {
                    print("AuthenticationService: Failed to restore Supabase session: \(error)")
                    
                    // Check if this is a token expiration error
                    if error.localizedDescription.contains("refresh_token_already_used") {
                        print("AuthenticationService: Refresh token expired, clearing session")
                        
                        // Clear the expired session
                        DispatchQueue.main.async {
                            self.clearSession()
                            
                            // Navigate to login screen
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                let loginViewController = LoginViewController()
                                let navigationController = UINavigationController(rootViewController: loginViewController)
                                
                                UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
                                    window.rootViewController = navigationController
                                }, completion: nil)
                                
                                window.makeKeyAndVisible()
                            }
                        }
                    }
                }
            }
        }
        
        return UserSession(
            id: finalUserId,
            email: email,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
    
    func clearSession() {
        KeychainService.shared.delete(for: .accessToken)
        KeychainService.shared.delete(for: .refreshToken)
        KeychainService.shared.delete(for: .userId)
        KeychainService.shared.delete(for: .userEmail)
        
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        print("AuthenticationService: Session cleared")
    }
    
    func clearTemporaryTokenSessions() {
        // Check if current session has temporary tokens and clear it
        if let accessToken = KeychainService.shared.load(for: .accessToken),
           let refreshToken = KeychainService.shared.load(for: .refreshToken) {
            
            // Clear any temp tokens, local tokens, or malformed access tokens
            // Note: Only validate access token as JWT - refresh tokens can have different formats
            let hasInvalidTokens = accessToken == "temp_token" || 
                                  refreshToken == "temp_refresh_token" ||
                                  refreshToken.hasPrefix("local_") ||
                                  !isValidJWT(accessToken)
            
            if hasInvalidTokens {
                print("AuthenticationService: Clearing session with invalid tokens - access: \(accessToken.prefix(10))..., refresh: \(refreshToken.prefix(10))...")
                clearSession()
            }
        }
    }
    
    private func isValidJWT(_ token: String) -> Bool {
        // Basic JWT validation - should have 3 parts separated by dots
        let parts = token.split(separator: ".")
        return parts.count == 3 && token.count > 50 && !token.hasPrefix("local_") && token != "temp_token" && token != "temp_refresh_token"
    }
    
    func signOut() async {
        do {
            // Sign out from Supabase first
            try await SupabaseService.shared.signOut()
            print("AuthenticationService: Successfully signed out from Supabase")
        } catch {
            print("AuthenticationService: Supabase sign out error: \(error)")
        }
        
        // Always clear local session
        clearSession()
        
        // Clear profile data
        clearProfileData()
        
        print("AuthenticationService: Local session cleared successfully")
    }
    
    // MARK: - Profile Management
    
    func saveProfileData(_ profile: UserProfileData) {
        UserDefaults.standard.set(profile.username, forKey: "userName")
        UserDefaults.standard.set(profile.fitnessGoals, forKey: "fitnessGoals")
        UserDefaults.standard.set(profile.preferredWorkoutTypes, forKey: "preferredWorkoutTypes")
        
        // Save profile image to documents directory if provided
        if let profileImage = profile.profileImage {
            saveProfileImageToDocuments(profileImage)
        }
        
        print("AuthenticationService: Profile data saved locally for user: \(profile.username)")
        
        // Sync profile data to Supabase
        Task {
            await syncProfileToSupabase(profile)
        }
    }
    
    private func syncProfileToSupabase(_ profile: UserProfileData) async {
        guard let currentSession = loadSession() else {
            print("AuthenticationService: No session found, cannot sync profile to Supabase")
            return
        }
        
        do {
            // Use profile.username as both username and fullName for now
            // This ensures team members display properly with the name the user provided
            try await SupabaseService.shared.syncLocalProfileToSupabase(
                userId: currentSession.id,
                username: profile.username,
                fullName: profile.username
            )
            print("AuthenticationService: Profile synced to Supabase successfully")
        } catch {
            print("AuthenticationService: Error syncing profile to Supabase: \(error)")
            // Don't throw error - local save should still succeed even if remote sync fails
        }
    }
    
    func migrateProfileToSupabaseIfNeeded() async {
        guard let profileData = loadProfileData(),
              let currentSession = loadSession() else {
            print("AuthenticationService: No profile data or session found for migration")
            return
        }
        
        // Check if we've already migrated this user's profile
        let migrationKey = "profile_migrated_\(currentSession.id)"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("AuthenticationService: Profile already migrated for user \(currentSession.id)")
            return
        }
        
        print("AuthenticationService: Starting profile migration for user \(currentSession.id)")
        
        do {
            // Sync the local profile data to Supabase
            try await SupabaseService.shared.syncLocalProfileToSupabase(
                userId: currentSession.id,
                username: profileData.username,
                fullName: profileData.username
            )
            
            // Mark as migrated
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("AuthenticationService: Profile migration completed successfully")
        } catch {
            print("AuthenticationService: Profile migration failed: \(error)")
            // Don't mark as migrated if it failed - we'll try again next time
        }
    }
    
    func loadProfileData() -> UserProfileData? {
        guard let username = UserDefaults.standard.object(forKey: "userName") as? String else {
            return nil
        }
        
        let fitnessGoals = UserDefaults.standard.array(forKey: "fitnessGoals") as? [String] ?? []
        let preferredWorkoutTypes = UserDefaults.standard.array(forKey: "preferredWorkoutTypes") as? [String] ?? []
        let profileImage = loadProfileImageFromDocuments()
        
        return UserProfileData(
            username: username,
            profileImage: profileImage,
            fitnessGoals: fitnessGoals,
            preferredWorkoutTypes: preferredWorkoutTypes
        )
    }
    
    func updateUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: "userName")
        print("AuthenticationService: Username updated to: \(username)")
    }
    
    func updateProfileImage(_ image: UIImage) {
        saveProfileImageToDocuments(image)
        print("AuthenticationService: Profile image updated")
    }
    
    func clearProfileData() {
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "fitnessGoals")
        UserDefaults.standard.removeObject(forKey: "preferredWorkoutTypes")
        deleteProfileImageFromDocuments()
        print("AuthenticationService: Profile data cleared")
    }
    
    // MARK: - Profile Image Management
    
    private func saveProfileImageToDocuments(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("profile_image.jpg")
        
        do {
            try data.write(to: imagePath)
            UserDefaults.standard.set(imagePath.path, forKey: "profileImagePath")
            print("AuthenticationService: Profile image saved to: \(imagePath.path)")
        } catch {
            print("AuthenticationService: Error saving profile image: \(error)")
        }
    }
    
    private func loadProfileImageFromDocuments() -> UIImage? {
        guard let imagePath = UserDefaults.standard.string(forKey: "profileImagePath") else {
            return nil
        }
        
        let imageURL = URL(fileURLWithPath: imagePath)
        guard FileManager.default.fileExists(atPath: imagePath) else {
            return nil
        }
        
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    private func deleteProfileImageFromDocuments() {
        guard let imagePath = UserDefaults.standard.string(forKey: "profileImagePath") else {
            return
        }
        
        let imageURL = URL(fileURLWithPath: imagePath)
        try? FileManager.default.removeItem(at: imageURL)
        UserDefaults.standard.removeObject(forKey: "profileImagePath")
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard currentNonce != nil else {
                print("AuthenticationService: Invalid state - no login request")
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("AuthenticationService: Unable to fetch identity token")
                signInCompletion?(.failure(AuthError.missingToken))
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("AuthenticationService: Unable to serialize token string")
                signInCompletion?(.failure(AuthError.invalidToken))
                return
            }
            
            // Get user info
            let appleUserId = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // Convert Apple ID to UUID format for database compatibility
            let userId = generateUUIDFromAppleId(appleUserId)
            print("AuthenticationService: Converting Apple ID '\(appleUserId)' to UUID '\(userId)'")
            
            // Store user info if this is first sign in
            if let email = email {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
            
            if let fullName = fullName {
                let name = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                if !name.isEmpty {
                    UserDefaults.standard.set(name, forKey: "userName")
                }
            }
            
            // Sign in with Supabase using Apple credentials
            Task {
                do {
                    guard let nonce = self.currentNonce else {
                        throw AuthError.missingToken
                    }
                    
                    // Sign in with Supabase
                    let supabaseSession = try await SupabaseService.shared.signInWithApple(
                        idToken: idTokenString,
                        nonce: nonce
                    )
                    
                    await MainActor.run {
                        if let supabaseSession = supabaseSession {
                            self.saveSession(supabaseSession)
                            
                            // Set up Lightning wallet for new users
                            Task {
                                await self.setupLightningWalletIfNeeded(userId: supabaseSession.id)
                            }
                            
                            self.signInCompletion?(.success(supabaseSession))
                            print("AuthenticationService: Successfully signed in with Supabase")
                        } else {
                            // Don't create fake tokens - fail properly
                            let authError = AuthError.supabaseError("Failed to authenticate with backend. Please check your internet connection and try again.")
                            self.signInCompletion?(.failure(authError))
                            print("AuthenticationService: Supabase returned nil session - authentication failed")
                        }
                    }
                } catch {
                    print("AuthenticationService: Supabase sign in failed: \(error)")
                    
                    await MainActor.run {
                        // Don't create fake tokens - fail properly
                        let errorMessage: String
                        if let apiError = error as NSError?,
                           let message = apiError.userInfo["message"] as? String {
                            errorMessage = message
                        } else {
                            errorMessage = error.localizedDescription
                        }
                        
                        let authError = AuthError.supabaseError("Authentication failed: \(errorMessage)")
                        self.signInCompletion?(.failure(authError))
                        print("AuthenticationService: Authentication failed - not creating fake session")
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("AuthenticationService: Sign in with Apple error: \(error)")
        signInCompletion?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            fatalError("No key window found")
        }
        
        return window
    }
    
    // MARK: - Lightning Wallet Setup
    
    private func setupLightningWalletIfNeeded(userId: String) async {
        let lightningWalletManager = LightningWalletManager.shared
        
        // Check if user already has a wallet configured
        let walletExists = await lightningWalletManager.isWalletSetup(for: userId)
        
        if !walletExists {
            do {
                print("AuthenticationService: Setting up Lightning wallet for new user \(userId)")
                try await lightningWalletManager.setupWalletForNewUser(userId)
                print("AuthenticationService: Lightning wallet setup completed successfully")
            } catch {
                print("AuthenticationService: Failed to setup Lightning wallet: \(error)")
                // Don't fail authentication if wallet setup fails
                // User can set it up later through the app
            }
        } else {
            print("AuthenticationService: User \(userId) already has Lightning wallet configured")
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingToken
    case invalidToken
    case signInFailed
    case userNotFound
    case supabaseError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Unable to fetch identity token"
        case .invalidToken:
            return "Invalid identity token"
        case .signInFailed:
            return "Sign in failed"
        case .userNotFound:
            return "User not found"
        case .supabaseError(let message):
            return message
        }
    }
}