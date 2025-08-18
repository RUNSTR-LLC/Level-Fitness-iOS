import Foundation

class TeamWalletAccessController {
    static let shared = TeamWalletAccessController()
    
    private let authenticationService = AuthenticationService.shared
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Team Wallet Access Control
    
    func canUserAccessTeamWallet(teamId: String, userId: String) async -> Bool {
        do {
            // Check if user is authenticated
            guard authenticationService.loadSession() != nil else {
                return false
            }
            
            // Check if user is a team member
            return try await supabaseService.isUserMemberOfTeam(userId: userId, teamId: teamId)
        } catch {
            print("TeamWalletAccessController: Error checking team wallet access: \(error)")
            return false
        }
    }
    
    func canUserManageTeamWallet(teamId: String, userId: String) async -> Bool {
        do {
            // Check if user is authenticated
            guard authenticationService.loadSession() != nil else {
                return false
            }
            
            // Check if user is team captain
            guard let team = try await supabaseService.getTeam(teamId) else {
                return false
            }
            
            return team.captainId == userId
        } catch {
            print("TeamWalletAccessController: Error checking team wallet management access: \(error)")
            return false
        }
    }
    
    func canUserDistributeRewards(teamId: String, userId: String) async -> Bool {
        // For now, only team captains can distribute rewards
        return await canUserManageTeamWallet(teamId: teamId, userId: userId)
    }
    
    func requireTeamAccess(teamId: String, userId: String? = nil) async throws {
        let requestingUserId = userId ?? authenticationService.loadSession()?.id
        guard let requestingUserId = requestingUserId else {
            throw TeamWalletAccessError.notAuthenticated
        }
        
        let hasAccess = await canUserAccessTeamWallet(teamId: teamId, userId: requestingUserId)
        guard hasAccess else {
            throw TeamWalletAccessError.accessDenied
        }
    }
    
    func getUserRoleInTeam(teamId: String, userId: String) async throws -> TeamRole {
        // Check if user is authenticated
        guard authenticationService.loadSession() != nil else {
            return .none
        }
        
        // Check if user is team captain
        if await canUserManageTeamWallet(teamId: teamId, userId: userId) {
            return .captain
        }
        
        // Check if user is team member
        if await canUserAccessTeamWallet(teamId: teamId, userId: userId) {
            return .member
        }
        
        return .none
    }
    
    func validateTeamWalletAccess(teamId: String, userId: String, accessType: TeamWalletAccessType) async throws {
        switch accessType {
        case .view:
            let hasAccess = await canUserAccessTeamWallet(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw TeamWalletAccessError.accessDenied
            }
        case .manage:
            let hasAccess = await canUserManageTeamWallet(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw TeamWalletAccessError.accessDenied
            }
        }
    }
    
    func validateTeamWalletOperation(teamId: String, userId: String, operation: TeamWalletOperation) async throws {
        switch operation {
        case .fundWallet, .distributeReward:
            let hasAccess = await canUserManageTeamWallet(teamId: teamId, userId: userId)
            guard hasAccess else {
                throw TeamWalletAccessError.accessDenied
            }
        }
    }
}

// MARK: - Data Models

enum TeamRole {
    case captain
    case member
    case none
    
    var description: String {
        switch self {
        case .captain: return "Team Captain"
        case .member: return "Team Member"
        case .none: return "Not a team member"
        }
    }
}

enum TeamWalletOperation {
    case fundWallet
    case distributeReward
}

// MARK: - Simplified Error Handling

enum TeamWalletAccessError: LocalizedError {
    case notAuthenticated
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Authentication required to access team wallet"
        case .accessDenied:
            return "Access denied for team wallet operation"
        }
    }
}