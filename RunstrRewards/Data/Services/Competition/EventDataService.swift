import Foundation

class EventDataService {
    static let shared = EventDataService()
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Event Management
    
    func fetchEvents(status: String = "active") async throws -> [CompetitionEvent] {
        do {
            let response = try await supabase.client
                .from("competition_events")
                .select("*")
                .eq("status", value: status)
                .order("created_at", ascending: false)
                .execute()
            
            let events = try JSONDecoder().decode([CompetitionEvent].self, from: response.data)
            print("EventDataService: ✅ Fetched \(events.count) events")
            return events
            
        } catch {
            print("EventDataService: ❌ Failed to fetch events: \(error)")
            throw error
        }
    }
    
    func createEvent(_ event: CompetitionEvent) async throws -> CompetitionEvent {
        do {
            let response = try await supabase.client
                .from("competition_events")
                .insert(event)
                .select()
                .single()
                .execute()
            
            let createdEvent = try JSONDecoder().decode(CompetitionEvent.self, from: response.data)
            print("EventDataService: ✅ Created event \(createdEvent.id)")
            return createdEvent
            
        } catch {
            print("EventDataService: ❌ Failed to create event: \(error)")
            throw error
        }
    }
    
    func joinEvent(eventId: String, userId: String) async throws {
        do {
            let participation = EventParticipation(
                eventId: eventId,
                userId: userId,
                joinedAt: Date(),
                isActive: true
            )
            
            try await supabase.client
                .from("event_participants")
                .insert(participation)
                .execute()
            
            print("EventDataService: ✅ User \(userId) joined event \(eventId)")
            
        } catch {
            print("EventDataService: ❌ Failed to join event: \(error)")
            throw error
        }
    }
    
    func fetchEventParticipants(eventId: String) async throws -> [EventParticipant] {
        do {
            let response = try await supabase.client
                .from("event_participants")
                .select("""
                    user_id, joined_at, progress, is_active,
                    profiles!inner(full_name, avatar_url)
                """)
                .eq("event_id", value: eventId)
                .eq("is_active", value: true)
                .execute()
            
            let participants = try parseEventParticipants(from: response.data)
            print("EventDataService: ✅ Fetched \(participants.count) participants")
            return participants
            
        } catch {
            print("EventDataService: ❌ Failed to fetch participants: \(error)")
            throw error
        }
    }
    
    func registerUserForEvent(eventId: String, userId: String) async throws {
        try await joinEvent(eventId: eventId, userId: userId)
    }
    
    func updateEventProgress(eventId: String, userId: String, progress: Double) async throws {
        do {
            let update = EventProgressUpdate(
                progress: progress,
                lastUpdated: Date()
            )
            
            try await supabase.client
                .from("event_participants")
                .update(update)
                .eq("event_id", value: eventId)
                .eq("user_id", value: userId)
                .execute()
            
            print("EventDataService: ✅ Updated progress for user \(userId) in event \(eventId)")
            
        } catch {
            print("EventDataService: ❌ Failed to update event progress: \(error)")
            throw error
        }
    }
    
    // MARK: - Challenge Management
    
    func fetchChallenges(teamId: String? = nil) async throws -> [Challenge] {
        var query = supabase.client
            .from("challenges")
            .select("*")
            .order("created_at", ascending: false)
        
        if let teamId = teamId {
            query = query.eq("team_id", value: teamId)
        }
        
        do {
            let response = try await query.execute()
            let challenges = try JSONDecoder().decode([Challenge].self, from: response.data)
            print("EventDataService: ✅ Fetched \(challenges.count) challenges")
            return challenges
            
        } catch {
            print("EventDataService: ❌ Failed to fetch challenges: \(error)")
            throw error
        }
    }
    
    func createChallenge(_ challenge: Challenge) async throws -> Challenge {
        do {
            let response = try await supabase.client
                .from("challenges")
                .insert(challenge)
                .select()
                .single()
                .execute()
            
            let createdChallenge = try JSONDecoder().decode(Challenge.self, from: response.data)
            print("EventDataService: ✅ Created challenge \(createdChallenge.id)")
            return createdChallenge
            
        } catch {
            print("EventDataService: ❌ Failed to create challenge: \(error)")
            throw error
        }
    }
    
    func joinChallenge(challengeId: String, userId: String) async throws {
        try await joinEvent(eventId: challengeId, userId: userId)
    }
    
    func fetchChallengeParticipants(challengeId: String) async throws -> [ChallengeParticipantDisplay] {
        let participants = try await fetchEventParticipants(eventId: challengeId)
        return participants.map { ChallengeParticipantDisplay(from: $0) }
    }
    
    func updateChallengeProgress(challengeId: String, userId: String, progress: Double) async throws {
        try await updateEventProgress(eventId: challengeId, userId: userId, progress: progress)
    }
    
    // MARK: - Event Analytics
    
    func getEventAnalytics(eventId: String) async throws -> EventAnalytics {
        do {
            let participantsResponse = try await supabase.client
                .from("event_participants")
                .select("*", head: true, count: .exact)
                .eq("event_id", value: eventId)
                .execute()
            
            let activeResponse = try await supabase.client
                .from("event_participants")
                .select("*", head: true, count: .exact)
                .eq("event_id", value: eventId)
                .eq("is_active", value: true)
                .execute()
            
            return EventAnalytics(
                eventId: eventId,
                totalParticipants: participantsResponse.count ?? 0,
                activeParticipants: activeResponse.count ?? 0,
                completionRate: calculateCompletionRate(eventId: eventId)
            )
            
        } catch {
            print("EventDataService: ❌ Failed to get event analytics: \(error)")
            throw error
        }
    }
    
    private func calculateCompletionRate(eventId: String) async -> Double {
        // Implementation for completion rate calculation
        return 0.0
    }
    
    // MARK: - Helper Methods
    
    private func parseEventParticipants(from data: Data) throws -> [EventParticipant] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([EventParticipant].self, from: data)
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToEventUpdates(eventId: String, completion: @escaping (CompetitionEvent) -> Void) {
        print("EventDataService: Setting up real-time updates for event \(eventId)")
    }
    
    func unsubscribeFromEventUpdates(eventId: String) {
        print("EventDataService: Unsubscribing from event \(eventId) updates")
    }
}

// MARK: - Data Models

struct EventParticipation: Codable {
    let eventId: String
    let userId: String
    let joinedAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
        case isActive = "is_active"
    }
}

struct EventProgressUpdate: Codable {
    let progress: Double
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case progress
        case lastUpdated = "last_updated"
    }
}

struct EventAnalytics {
    let eventId: String
    let totalParticipants: Int
    let activeParticipants: Int
    let completionRate: Double
}

struct ChallengeParticipantDisplay {
    let userId: String
    let fullName: String?
    let avatarUrl: String?
    let progress: Double
    let isActive: Bool
    
    init(from participant: EventParticipant) {
        self.userId = participant.userId
        self.fullName = participant.fullName ?? ""
        self.avatarUrl = participant.userId // This needs to be fixed with proper avatar URL logic
        self.progress = participant.currentScore
        self.isActive = participant.isActive
    }
}