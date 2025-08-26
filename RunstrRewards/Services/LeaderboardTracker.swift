import Foundation
import UserNotifications

// MARK: - Position Tracking Data Models

struct LeaderboardPosition: Codable {
    let userId: String
    let leaderboardType: LeaderboardType
    let leaderboardId: String?
    let position: Int
    let previousPosition: Int?
    let score: Double
    let previousScore: Double?
    let lastUpdated: Date
    let context: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case leaderboardType = "leaderboard_type"
        case leaderboardId = "leaderboard_id"
        case position
        case previousPosition = "previous_position"
        case score
        case previousScore = "previous_score"
        case lastUpdated = "last_updated"
        case context
    }
    
    var positionChange: Int? {
        guard let previousPosition = previousPosition else { return nil }
        return previousPosition - position // Positive = moved up, negative = moved down
    }
    
    var hasSignificantChange: Bool {
        guard let change = positionChange else { return true } // First time is significant
        return abs(change) >= 3 // Only notify for changes of 3+ positions
    }
}

enum LeaderboardType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
    case team = "team"
    case event = "event"
    case challenge = "challenge"
}

struct PositionChangeEvent {
    let userId: String
    let leaderboardPosition: LeaderboardPosition
    let changeType: PositionChangeType
    let notificationPriority: NotificationPriority
}

enum PositionChangeType {
    case firstEntry
    case movedUp(positions: Int)
    case movedDown(positions: Int)
    case noChange
    case newHighScore
    case milestone(position: Int)
}

// Note: NotificationPriority enum is defined in EventNotificationService.swift
// We map LeaderboardTracker priorities to EventNotificationService priorities:
// medium -> normal, none -> low

// MARK: - Leaderboard Tracker Service

class LeaderboardTracker {
    static let shared = LeaderboardTracker()
    
    private var cachedPositions: [String: LeaderboardPosition] = [:]
    private let supabaseService = SupabaseService.shared
    private let notificationService = NotificationService.shared
    private let notificationIntelligence = NotificationIntelligence.shared
    
    private let positionCacheKey = "leaderboard_positions_cache"
    
    private init() {
        loadCachedPositions()
    }
    
    // MARK: - Cache Management
    
    private func loadCachedPositions() {
        if let data = UserDefaults.standard.data(forKey: positionCacheKey),
           let positions = try? JSONDecoder().decode([String: LeaderboardPosition].self, from: data) {
            cachedPositions = positions
            print("LeaderboardTracker: Loaded \(positions.count) cached positions")
        }
    }
    
    private func saveCachedPositions() {
        if let data = try? JSONEncoder().encode(cachedPositions) {
            UserDefaults.standard.set(data, forKey: positionCacheKey)
        }
    }
    
    // MARK: - Position Tracking
    
    func trackUserPositions(userId: String) async -> [PositionChangeEvent] {
        var changeEvents: [PositionChangeEvent] = []
        
        // Track different leaderboard types
        for leaderboardType in LeaderboardType.allCases {
            let events = await trackLeaderboardType(leaderboardType, userId: userId)
            changeEvents.append(contentsOf: events)
        }
        
        // Save updated positions
        saveCachedPositions()
        
        return changeEvents
    }
    
    private func trackLeaderboardType(_ type: LeaderboardType, userId: String) async -> [PositionChangeEvent] {
        var events: [PositionChangeEvent] = []
        
        do {
            switch type {
            case .weekly:
                events.append(contentsOf: await trackWeeklyLeaderboard(userId: userId))
            case .monthly:
                events.append(contentsOf: await trackMonthlyLeaderboard(userId: userId))
            case .allTime:
                events.append(contentsOf: await trackAllTimeLeaderboard(userId: userId))
            case .team:
                events.append(contentsOf: await trackTeamLeaderboards(userId: userId))
            case .event:
                events.append(contentsOf: await trackEventLeaderboards(userId: userId))
            case .challenge:
                events.append(contentsOf: await trackChallengeLeaderboards(userId: userId))
            }
        } catch {
            print("LeaderboardTracker: Error tracking \(type.rawValue) leaderboard: \(error)")
        }
        
        return events
    }
    
    // MARK: - Specific Leaderboard Tracking
    
    private func trackWeeklyLeaderboard(userId: String) async -> [PositionChangeEvent] {
        do {
            let leaderboard = try await supabaseService.fetchWeeklyLeaderboard()
            
            if let userEntry = leaderboard.first(where: { $0.userId == userId }) {
                let cacheKey = "weekly_global"
                let newPosition = createLeaderboardPosition(
                    userId: userId,
                    type: .weekly,
                    leaderboardId: nil,
                    position: userEntry.rank,
                    score: Double(userEntry.points),
                    context: ["metric": "points"]
                )
                
                return [processPositionChange(cacheKey: cacheKey, newPosition: newPosition)]
            }
        } catch {
            print("LeaderboardTracker: Failed to fetch weekly leaderboard: \(error)")
        }
        
        return []
    }
    
    private func trackMonthlyLeaderboard(userId: String) async -> [PositionChangeEvent] {
        // Similar to weekly but for monthly timeframe
        // For now, return empty as monthly leaderboard isn't implemented
        return []
    }
    
    private func trackAllTimeLeaderboard(userId: String) async -> [PositionChangeEvent] {
        // Similar to weekly but for all-time stats
        // For now, return empty as all-time leaderboard isn't implemented
        return []
    }
    
    private func trackTeamLeaderboards(userId: String) async -> [PositionChangeEvent] {
        var events: [PositionChangeEvent] = []
        
        do {
            // Get user's teams
            let teams = try await supabaseService.fetchUserTeams(userId: userId)
            
            for team in teams {
                // Get team leaderboard
                let teamLeaderboard = try await supabaseService.fetchTeamLeaderboard(
                    teamId: team.id,
                    type: "distance",
                    period: "weekly"
                )
                
                if let userEntry = teamLeaderboard.first(where: { $0.userId == userId }) {
                    let cacheKey = "team_\(team.id)_weekly"
                    let newPosition = createLeaderboardPosition(
                        userId: userId,
                        type: .team,
                        leaderboardId: team.id,
                        position: userEntry.rank,
                        score: userEntry.totalDistance,
                        context: ["team_name": team.name, "metric": "distance"]
                    )
                    
                    events.append(processPositionChange(cacheKey: cacheKey, newPosition: newPosition))
                }
            }
        } catch {
            print("LeaderboardTracker: Failed to track team leaderboards: \(error)")
        }
        
        return events
    }
    
    private func trackEventLeaderboards(userId: String) async -> [PositionChangeEvent] {
        var events: [PositionChangeEvent] = []
        
        do {
            let activeEvents = try await supabaseService.fetchEvents(status: "active")
            
            for event in activeEvents {
                let participants = try await supabaseService.fetchEventParticipants(eventId: event.id)
                
                // Sort participants by progress to get ranking
                let sortedParticipants = participants.sorted { $0.progress > $1.progress }
                
                if let userParticipant = sortedParticipants.first(where: { $0.userId == userId }) {
                    let position = (sortedParticipants.firstIndex(where: { $0.userId == userId }) ?? 0) + 1
                    
                    let cacheKey = "event_\(event.id)"
                    let newPosition = createLeaderboardPosition(
                        userId: userId,
                        type: .event,
                        leaderboardId: event.id,
                        position: position,
                        score: userParticipant.progress,
                        context: ["event_name": event.name, "metric": "progress"]
                    )
                    
                    events.append(processPositionChange(cacheKey: cacheKey, newPosition: newPosition))
                }
            }
        } catch {
            print("LeaderboardTracker: Failed to track event leaderboards: \(error)")
        }
        
        return events
    }
    
    private func trackChallengeLeaderboards(userId: String) async -> [PositionChangeEvent] {
        // Similar to events but for challenges
        // For now, return empty as challenge leaderboard tracking isn't fully implemented
        return []
    }
    
    // MARK: - Position Processing
    
    private func createLeaderboardPosition(
        userId: String,
        type: LeaderboardType,
        leaderboardId: String?,
        position: Int,
        score: Double,
        context: [String: String]?
    ) -> LeaderboardPosition {
        return LeaderboardPosition(
            userId: userId,
            leaderboardType: type,
            leaderboardId: leaderboardId,
            position: position,
            previousPosition: nil, // Will be set in processPositionChange
            score: score,
            previousScore: nil, // Will be set in processPositionChange
            lastUpdated: Date(),
            context: context
        )
    }
    
    private func processPositionChange(cacheKey: String, newPosition: LeaderboardPosition) -> PositionChangeEvent {
        var updatedPosition = newPosition
        
        // Get previous position if it exists
        if let previousPosition = cachedPositions[cacheKey] {
            updatedPosition = LeaderboardPosition(
                userId: newPosition.userId,
                leaderboardType: newPosition.leaderboardType,
                leaderboardId: newPosition.leaderboardId,
                position: newPosition.position,
                previousPosition: previousPosition.position,
                score: newPosition.score,
                previousScore: previousPosition.score,
                lastUpdated: newPosition.lastUpdated,
                context: newPosition.context
            )
        }
        
        // Update cache
        cachedPositions[cacheKey] = updatedPosition
        
        // Determine change type and priority
        let changeType = determineChangeType(updatedPosition)
        let priority = determineNotificationPriority(updatedPosition, changeType: changeType)
        
        return PositionChangeEvent(
            userId: updatedPosition.userId,
            leaderboardPosition: updatedPosition,
            changeType: changeType,
            notificationPriority: priority
        )
    }
    
    private func determineChangeType(_ position: LeaderboardPosition) -> PositionChangeType {
        guard let positionChange = position.positionChange else {
            return .firstEntry
        }
        
        if positionChange == 0 {
            // Check for new high score
            if let previousScore = position.previousScore, position.score > previousScore {
                return .newHighScore
            }
            return .noChange
        } else if positionChange > 0 {
            return .movedUp(positions: positionChange)
        } else {
            return .movedDown(positions: abs(positionChange))
        }
    }
    
    private func determineNotificationPriority(_ position: LeaderboardPosition, changeType: PositionChangeType) -> NotificationPriority {
        switch changeType {
        case .firstEntry:
            return position.position <= 10 ? .high : .normal
            
        case .movedUp(let positions):
            if position.position <= 3 {
                return .high // Top 3 positions
            } else if position.position <= 10 || positions >= 5 {
                return .normal // Top 10 or significant improvement
            } else if positions >= 3 {
                return .low // Minor but notable improvement
            } else {
                return .low // Very small improvement
            }
            
        case .movedDown(let positions):
            if positions >= 10 {
                return .normal // Significant drop
            } else if positions >= 5 {
                return .low // Moderate drop
            } else {
                return .low // Minor drop
            }
            
        case .newHighScore:
            return .normal
            
        case .milestone(let milestonePosition):
            return milestonePosition <= 10 ? .high : .normal
            
        case .noChange:
            return .low
        }
    }
    
    // MARK: - Notification Generation
    
    func processPositionChanges(_ events: [PositionChangeEvent]) async {
        for event in events {
            if event.notificationPriority != .low {
                await generateNotification(for: event)
            }
        }
    }
    
    private func generateNotification(for event: PositionChangeEvent) async {
        let position = event.leaderboardPosition
        
        // Get team name for team-branded notifications
        do {
            let teamName = try await getTeamNameForLeaderboard(position: position)
            let (title, message) = await generateTeamBrandedNotificationContent(event: event, teamName: teamName)
            
            // Create intelligent notification candidate with team branding
            if let candidate = notificationIntelligence.createLeaderboardChangeNotification(
                position: position.position,
                previousPosition: position.previousPosition,
                leaderboardName: teamName,
                userId: position.userId
            ) {
                // Override with team-branded content
                let teamBrandedCandidate = NotificationCandidate(
                    type: candidate.type,
                    title: title,
                    body: message,
                    score: candidate.score,
                    context: candidate.context,
                    urgency: candidate.urgency,
                    category: candidate.category
                )
                
                // Check if notification should be sent
                if notificationIntelligence.shouldSendNotification(teamBrandedCandidate, userId: position.userId) {
                    await MainActor.run {
                        // Schedule notification using public NotificationService method
                        let identifier = "leaderboard_\(position.leaderboardType.rawValue)_\(UUID().uuidString)"
                        notificationService.schedulePositionChangeNotification(
                            title: title,
                            message: message,
                            identifier: identifier
                        )
                        print("LeaderboardTracker: 📣 Sent team-branded notification: \(title)")
                    }
                } else {
                    print("LeaderboardTracker: 🤖 Intelligent notification system blocked leaderboard notification")
                }
            }
        } catch {
            print("LeaderboardTracker: Failed to get team name for notification: \(error)")
            // Fallback to original notification system
            let leaderboardName = getLeaderboardDisplayName(position)
            if let candidate = notificationIntelligence.createLeaderboardChangeNotification(
                position: position.position,
                previousPosition: position.previousPosition,
                leaderboardName: leaderboardName,
                userId: position.userId
            ) {
                if notificationIntelligence.shouldSendNotification(candidate, userId: position.userId) {
                    await MainActor.run {
                        let identifier = "leaderboard_\(position.leaderboardType.rawValue)_\(UUID().uuidString)"
                        notificationService.schedulePositionChangeNotification(
                            title: candidate.title,
                            message: candidate.body,
                            identifier: identifier
                        )
                        print("LeaderboardTracker: 📣 Sent fallback notification: \(candidate.title)")
                    }
                }
            }
        }
    }
    
    private func generateNotificationContent(_ event: PositionChangeEvent, leaderboardName: String) -> (title: String, message: String) {
        let position = event.leaderboardPosition
        
        switch event.changeType {
        case .firstEntry:
            return (
                title: "🎯 You're on the league!",
                message: "You're ranked #\(position.position) on the \(leaderboardName) league!"
            )
            
        case .movedUp(let positions):
            let emoji = position.position <= 3 ? "🏆" : position.position <= 10 ? "🔥" : "📈"
            return (
                title: "\(emoji) You moved up \(positions) spots!",
                message: "Now ranked #\(position.position) on the \(leaderboardName) league"
            )
            
        case .movedDown(_):
            return (
                title: "📉 Position update",
                message: "You're now #\(position.position) on the \(leaderboardName) league"
            )
            
        case .newHighScore:
            return (
                title: "🎉 New personal best!",
                message: "You set a new high score on the \(leaderboardName) league!"
            )
            
        case .milestone(let milestonePosition):
            let emoji = milestonePosition <= 10 ? "🏆" : "🎯"
            return (
                title: "\(emoji) Milestone reached!",
                message: "You've reached #\(milestonePosition) on the \(leaderboardName) league!"
            )
            
        case .noChange:
            return (title: "", message: "")
        }
    }
    
    private func getLeaderboardDisplayName(_ position: LeaderboardPosition) -> String {
        let typeName = position.leaderboardType.rawValue.capitalized
        
        if let context = position.context {
            if let teamName = context["team_name"] {
                return "\(teamName) \(typeName)"
            } else if let eventName = context["event_name"] {
                return "\(eventName)"
            }
        }
        
        return "\(typeName) Global"
    }
    
    // MARK: - Team-Branded Notification Helpers
    
    private func getTeamNameForLeaderboard(position: LeaderboardPosition) async throws -> String {
        // Check if team name is already in context
        if let context = position.context, let teamName = context["team_name"] {
            return teamName
        }
        
        // For team leaderboards, get team name from leaderboardId
        if position.leaderboardType == .team, let teamId = position.leaderboardId {
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: position.userId)
            if let team = teams.first(where: { $0.id == teamId }) {
                return team.name
            }
        }
        
        // For user-based leaderboards, get user's primary team
        let userTeams = try await SupabaseService.shared.fetchUserTeams(userId: position.userId)
        if let primaryTeam = userTeams.first {
            return primaryTeam.name
        }
        
        return "RunstrRewards" // Fallback if no team found
    }
    
    private func generateTeamBrandedNotificationContent(event: PositionChangeEvent, teamName: String) async -> (title: String, message: String) {
        let position = event.leaderboardPosition
        
        switch event.changeType {
        case .firstEntry:
            return (
                title: "\(teamName): You're on the leaderboard! 🎯",
                message: "You're ranked #\(position.position) in the team!"
            )
            
        case .movedUp(let positions):
            let emoji = position.position <= 3 ? "🏆" : position.position <= 10 ? "🔥" : "📈"
            return (
                title: "\(teamName): You moved up \(positions) spots! \(emoji)",
                message: "Now ranked #\(position.position) on the leaderboard"
            )
            
        case .movedDown(_):
            return (
                title: "\(teamName): Position update 📉",
                message: "You're now #\(position.position) on the leaderboard"
            )
            
        case .newHighScore:
            return (
                title: "\(teamName): New personal best! 🎉",
                message: "You set a new high score on the team leaderboard!"
            )
            
        case .milestone(let milestonePosition):
            let emoji = milestonePosition <= 10 ? "🏆" : "🎯"
            return (
                title: "\(teamName): Milestone reached! \(emoji)",
                message: "You've reached #\(milestonePosition) on the leaderboard!"
            )
            
        case .noChange:
            return (title: "", message: "")
        }
    }
    
    // MARK: - Public Interface
    
    func getUserPosition(userId: String, leaderboardType: LeaderboardType, leaderboardId: String? = nil) -> LeaderboardPosition? {
        let cacheKey = generateCacheKey(type: leaderboardType, id: leaderboardId)
        return cachedPositions[cacheKey]
    }
    
    func clearCache() {
        cachedPositions.removeAll()
        UserDefaults.standard.removeObject(forKey: positionCacheKey)
    }
    
    private func generateCacheKey(type: LeaderboardType, id: String?) -> String {
        if let id = id {
            return "\(type.rawValue)_\(id)"
        } else {
            return "\(type.rawValue)_global"
        }
    }
}