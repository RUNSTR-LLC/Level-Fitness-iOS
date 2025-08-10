import Foundation
import AuthenticationServices
import CryptoKit

class AuthenticationService: NSObject {
    static let shared = AuthenticationService()
    
    private var currentNonce: String?
    private var signInCompletion: ((Result<UserSession, Error>) -> Void)?
    
    private override init() {
        super.init()
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
        KeychainService.shared.save(session.accessToken, for: .accessToken)
        KeychainService.shared.save(session.refreshToken, for: .refreshToken)
        KeychainService.shared.save(session.id, for: .userId)
        
        if let email = session.email {
            KeychainService.shared.save(email, for: .userEmail)
        }
        
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        print("AuthenticationService: Session saved")
    }
    
    func loadSession() -> UserSession? {
        guard UserDefaults.standard.bool(forKey: "isAuthenticated"),
              let accessToken = KeychainService.shared.load(for: .accessToken),
              let refreshToken = KeychainService.shared.load(for: .refreshToken),
              let userId = KeychainService.shared.load(for: .userId) else {
            return nil
        }
        
        let email = KeychainService.shared.load(for: .userEmail)
        
        return UserSession(
            id: userId,
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
    
    func signOut() async {
        // Clear local session (bypassing Supabase for now)
        clearSession()
        print("AuthenticationService: Local session cleared successfully")
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
            let userId = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
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
            
            // Create local session (bypassing Supabase for now)
            let session = UserSession(
                id: userId,
                email: email ?? UserDefaults.standard.string(forKey: "userEmail"),
                accessToken: idTokenString,
                refreshToken: "local_refresh_token_\(UUID().uuidString)"
            )
            
            saveSession(session)
            signInCompletion?(.success(session))
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
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingToken
    case invalidToken
    case signInFailed
    case userNotFound
    
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
        }
    }
}