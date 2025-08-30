import Foundation

class TeamWalletAccessController {
    static let shared = TeamWalletAccessController()
    
    private let authenticationService = AuthenticationService.shared
    private let supabaseService = SupabaseService.shared
    
    // Captain verification cache with TTL
    private var captainCache: [String: CaptainCacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "captain-verification-cache", attributes: .concurrent)
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Cache Data Structures
    
    private struct CaptainCacheEntry {
        let isCaptain: Bool
        let timestamp: Date
    }
    
    // MARK: - Cache Methods
    
    private func getCachedResult(for key: String) -> Bool? {
        guard let entry = captainCache[key] else { return nil }
        
        let age = Date().timeIntervalSince(entry.timestamp)
        if age > cacheTTL {
            captainCache.removeValue(forKey: key)
            print("TeamWalletAccessController: 🗑️ Cache entry expired for \(key)")
            return nil
        }
        
        print("TeamWalletAccessController: 📦 Cache hit for \(key), age: \(Int(age))s")
        return entry.isCaptain
    }
    
    private func cacheResult(_ result: Bool, for key: String) {
        let entry = CaptainCacheEntry(isCaptain: result, timestamp: Date())
        captainCache[key] = entry
        print("TeamWalletAccessController: 📦 Cached result \(result) for \(key)")
        
        // Cleanup old entries periodically
        if captainCache.count > 100 {
            cleanupExpiredEntries()
        }
    }
    
    private func cleanupExpiredEntries() {
        let now = Date()
        let expiredKeys = captainCache.compactMap { key, entry in
            now.timeIntervalSince(entry.timestamp) > cacheTTL ? key : nil
        }
        
        for key in expiredKeys {
            captainCache.removeValue(forKey: key)
        }
        
        print("TeamWalletAccessController: 🧹 Cleaned up \(expiredKeys.count) expired cache entries")
    }
    
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.captainCache.removeAll()
            print("TeamWalletAccessController: 🗑️ Cache cleared")
        }
    }
    
    // MARK: - Team Wallet Access Control
    
    func canUserAccessTeamWallet(teamId: String, userId: String) async -> Bool {
        do {
            // Check if user is authenticated
            guard authenticationService.loadSession() != nil else {
                print("TeamWalletAccessController: ❌ User not authenticated for team wallet access")
                return false
            }
            
            print("TeamWalletAccessController: 🔍 Checking team wallet access for user: \(userId) on team: \(teamId)")
            
            // Check if user is a team member
            let isMember = try await supabaseService.isUserMemberOfTeam(userId: userId, teamId: teamId)
            print("TeamWalletAccessController: Team membership result: \(isMember)")
            
            return isMember
        } catch {
            print("TeamWalletAccessController: Error checking team wallet access: \(error)")
            return false
        }
    }
    
    func canUserManageTeamWallet(teamId: String, userId: String) async -> Bool {
        // Check cache first
        let cacheKey = "manage:\(teamId):\(userId)"
        
        if let cachedResult = cacheQueue.sync(execute: { getCachedResult(for: cacheKey) }) {
            print("TeamWalletAccessController: ✅ Using cached captain verification result: \(cachedResult)")
            return cachedResult
        }
        
        do {
            // Check if user is authenticated
            guard authenticationService.loadSession() != nil else {
                print("TeamWalletAccessController: ❌ User not authenticated")
                return false
            }
            
            // Check if user is team captain
            guard let team = try await supabaseService.getTeam(teamId) else {
                print("TeamWalletAccessController: ❌ Team not found: \(teamId)")
                cacheQueue.async(flags: .barrier) { self.cacheResult(false, for: cacheKey) }
                return false
            }
            
            print("TeamWalletAccessController: 🔍 Checking captain access for user: \(userId)")
            print("TeamWalletAccessController: 🔍 Team captain_id: \(team.captainId)")
            
            let isCaptain = team.captainId.lowercased() == userId.lowercased()
            print("TeamWalletAccessController: Captain access result: \(isCaptain)")
            
            // Cache the result
            cacheQueue.async(flags: .barrier) {
                self.cacheResult(isCaptain, for: cacheKey)
            }
            
            return isCaptain
        } catch {
            print("TeamWalletAccessController: Error checking team wallet management access: \(error)")
            cacheQueue.async(flags: .barrier) { self.cacheResult(false, for: cacheKey) }
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

// Note: Types moved to TeamWalletModels.swift for better organization