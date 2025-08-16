import Foundation
import UIKit

class ClubService {
    static let shared = ClubService()
    
    private let supabaseService = SupabaseService.shared
    private let subscriptionService = SubscriptionService.shared
    private let notificationService = NotificationService.shared
    private let lightningWalletManager = LightningWalletManager.shared
    
    private init() {}
    
    // MARK: - Club Creation
    
    func createClub(_ clubData: ClubCreationData) async throws -> Club {
        // Verify club subscription
        guard await subscriptionService.canCreateClub() else {
            throw ClubError.subscriptionRequired
        }
        
        // Validate club data
        try validateClubData(clubData)
        
        // Generate unique club code
        let clubCode = generateClubCode()
        
        // Create club object
        let club = Club(
            id: UUID().uuidString,
            name: clubData.name,
            description: clubData.description,
            ownerId: clubData.ownerId,
            category: clubData.category,
            memberCount: 1, // Owner is first member
            maxMembers: subscriptionService.getMaxClubMembers(),
            monthlyFee: clubData.monthlyFee,
            currency: "USD",
            totalRevenue: 0,
            imageUrl: clubData.imageUrl,
            inviteCode: clubCode,
            isPublic: clubData.isPublic,
            isPremium: clubData.isPremium,
            features: clubData.features,
            rules: clubData.rules,
            status: "active",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Store in database
        // TODO: Implement actual Supabase storage
        print("ClubService: Creating club \(club.name)")
        
        // Add owner as first member
        try await addMember(userId: clubData.ownerId, to: club.id, role: .owner)
        
        // Send confirmation notification
        notificationService.scheduleClubCreationConfirmation(clubName: club.name)
        
        return club
    }
    
    // MARK: - Club Management
    
    func updateClub(_ clubId: String, updates: ClubUpdateData) async throws {
        // Verify ownership
        guard try await isClubOwner(clubId: clubId) else {
            throw ClubError.notAuthorized
        }
        
        // Apply updates
        // TODO: Implement actual Supabase update
        print("ClubService: Updating club \(clubId)")
    }
    
    func deleteClub(_ clubId: String) async throws {
        // Verify ownership
        guard try await isClubOwner(clubId: clubId) else {
            throw ClubError.notAuthorized
        }
        
        // Check for active members
        let memberCount = try await getClubMemberCount(clubId)
        if memberCount > 1 {
            throw ClubError.hasActiveMembers
        }
        
        // Delete club
        // TODO: Implement actual Supabase deletion
        print("ClubService: Deleting club \(clubId)")
    }
    
    // MARK: - Member Management
    
    func joinClub(clubId: String, userId: String) async throws {
        // Check if club exists and is active
        guard let club = try await fetchClub(clubId) else {
            throw ClubError.clubNotFound
        }
        
        // Check if club is full
        if club.memberCount >= club.maxMembers {
            throw ClubError.clubFull
        }
        
        // Check if premium club requires subscription
        if club.isPremium && !await subscriptionService.canJoinPremiumClubs() {
            throw ClubError.premiumSubscriptionRequired
        }
        
        // Check if user is already a member
        if try await isMember(userId: userId, clubId: clubId) {
            throw ClubError.alreadyMember
        }
        
        // Process membership fee if applicable
        if club.monthlyFee > 0 {
            try await processMembershipPayment(userId: userId, club: club)
        }
        
        // Add member
        try await addMember(userId: userId, to: clubId, role: .member)
        
        // Update member count
        try await incrementMemberCount(clubId)
        
        // Send welcome notification
        notificationService.scheduleClubWelcome(clubName: club.name, userId: userId)
        
        print("ClubService: User \(userId) joined club \(club.name)")
    }
    
    func leaveClub(clubId: String, userId: String) async throws {
        // Check if user is owner
        if try await isClubOwner(clubId: clubId, userId: userId) {
            throw ClubError.ownerCannotLeave
        }
        
        // Remove member
        try await removeMember(userId: userId, from: clubId)
        
        // Update member count
        try await decrementMemberCount(clubId)
        
        print("ClubService: User \(userId) left club \(clubId)")
    }
    
    func inviteMember(email: String, to clubId: String) async throws {
        // Verify permissions
        guard try await canInviteMembers(clubId: clubId) else {
            throw ClubError.notAuthorized
        }
        
        // Generate invitation
        let invitation = ClubInvitation(
            id: UUID().uuidString,
            clubId: clubId,
            invitedEmail: email,
            invitedBy: AuthenticationService.shared.currentUserId ?? "",
            status: "pending",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 86400) // 7 days
        )
        
        // Store invitation
        // TODO: Implement actual storage
        print("ClubService: Inviting \(email) to club \(clubId)")
        
        // Send invitation email/notification
        // TODO: Implement email service
    }
    
    func removeMember(userId: String, from clubId: String) async throws {
        // Verify permissions
        guard try await canRemoveMembers(clubId: clubId) else {
            throw ClubError.notAuthorized
        }
        
        // Remove member
        // TODO: Implement actual Supabase deletion
        print("ClubService: Removing member \(userId) from club \(clubId)")
    }
    
    // MARK: - Virtual Events
    
    func createVirtualEvent(_ eventData: VirtualEventData) async throws -> VirtualEvent {
        // Verify club subscription
        guard await subscriptionService.canCreateVirtualEvents() else {
            throw ClubError.subscriptionRequired
        }
        
        // Verify club ownership
        guard try await isClubOwner(clubId: eventData.clubId) else {
            throw ClubError.notAuthorized
        }
        
        // Create event
        let event = VirtualEvent(
            id: UUID().uuidString,
            clubId: eventData.clubId,
            name: eventData.name,
            description: eventData.description,
            type: eventData.type,
            startDate: eventData.startDate,
            endDate: eventData.endDate,
            maxParticipants: eventData.maxParticipants,
            ticketPrice: eventData.ticketPrice,
            prizePool: eventData.prizePool,
            requirements: eventData.requirements,
            status: "upcoming",
            participantCount: 0,
            createdAt: Date()
        )
        
        // Store event
        // TODO: Implement actual Supabase storage
        print("ClubService: Creating virtual event \(event.name)")
        
        // Schedule reminder notifications
        notificationService.scheduleEventReminder(
            eventName: event.name,
            eventId: event.id,
            reminderDate: event.startDate.addingTimeInterval(-3600)
        )
        
        return event
    }
    
    func sellEventTicket(eventId: String, to userId: String) async throws -> EventTicket {
        // Fetch event
        guard let event = try await fetchEvent(eventId) else {
            throw ClubError.eventNotFound
        }
        
        // Check capacity
        if event.participantCount >= event.maxParticipants {
            throw ClubError.eventFull
        }
        
        // Check if user already has ticket
        if try await hasEventTicket(userId: userId, eventId: eventId) {
            throw ClubError.alreadyRegistered
        }
        
        // Process payment
        if event.ticketPrice > 0 {
            try await processTicketPayment(userId: userId, event: event)
        }
        
        // Create ticket
        let ticket = EventTicket(
            id: UUID().uuidString,
            eventId: eventId,
            userId: userId,
            ticketNumber: generateTicketNumber(),
            qrCode: generateQRCode(for: eventId, userId: userId),
            purchaseDate: Date(),
            status: "valid"
        )
        
        // Store ticket
        // TODO: Implement actual storage
        print("ClubService: Ticket sold for event \(event.name) to user \(userId)")
        
        // Update participant count
        try await incrementParticipantCount(eventId)
        
        // Send ticket confirmation
        notificationService.scheduleTicketConfirmation(
            eventName: event.name,
            ticketNumber: ticket.ticketNumber
        )
        
        return ticket
    }
    
    // MARK: - Revenue Management
    
    func calculateClubRevenue(clubId: String) async throws -> ClubRevenue {
        guard let club = try await fetchClub(clubId) else {
            throw ClubError.clubNotFound
        }
        
        // Calculate monthly subscription revenue
        let monthlySubscriptionRevenue = Double(club.memberCount - 1) * club.monthlyFee
        
        // Calculate event ticket revenue
        let eventRevenue = try await calculateEventRevenue(clubId: clubId)
        
        // Calculate platform fee (20%)
        let platformFee = (monthlySubscriptionRevenue + eventRevenue) * 0.20
        
        // Calculate net revenue
        let netRevenue = (monthlySubscriptionRevenue + eventRevenue) - platformFee
        
        return ClubRevenue(
            clubId: clubId,
            monthlySubscriptions: monthlySubscriptionRevenue,
            eventTickets: eventRevenue,
            platformFee: platformFee,
            netRevenue: netRevenue,
            lastPayout: Date(),
            nextPayout: Date().addingTimeInterval(30 * 86400)
        )
    }
    
    func distributeClubRevenue(clubId: String) async throws {
        // Calculate revenue
        let revenue = try await calculateClubRevenue(clubId: clubId)
        
        // Get club owner
        guard let club = try await fetchClub(clubId) else {
            throw ClubError.clubNotFound
        }
        
        // Convert to satoshis (assuming 1 USD = 3000 sats for example)
        let satoshiAmount = Int(revenue.netRevenue * 3000)
        
        // Distribute via Lightning
        try await lightningWalletManager.distributeWorkoutReward(
            userId: club.ownerId,
            workoutType: "club_revenue",
            points: satoshiAmount / 10 // Convert to points
        )
        
        print("ClubService: Distributed \(satoshiAmount) sats to club owner \(club.ownerId)")
    }
    
    // MARK: - Search and Discovery
    
    func searchClubs(query: String, category: ClubCategory? = nil) async throws -> [Club] {
        // TODO: Implement actual search
        print("ClubService: Searching clubs with query: \(query)")
        return []
    }
    
    func fetchTrendingClubs(limit: Int = 10) async throws -> [Club] {
        // TODO: Implement actual fetch
        print("ClubService: Fetching trending clubs")
        return []
    }
    
    func fetchUserClubs(userId: String) async throws -> [Club] {
        // TODO: Implement actual fetch
        print("ClubService: Fetching clubs for user \(userId)")
        return []
    }
    
    // MARK: - Helper Methods
    
    private func validateClubData(_ data: ClubCreationData) throws {
        if data.name.count < 3 || data.name.count > 50 {
            throw ClubError.invalidName
        }
        
        if data.description.count < 10 || data.description.count > 500 {
            throw ClubError.invalidDescription
        }
        
        if data.monthlyFee < 0 || data.monthlyFee > 100 {
            throw ClubError.invalidFee
        }
    }
    
    private func generateClubCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    private func generateTicketNumber() -> String {
        return "TKT\(Int.random(in: 100000...999999))"
    }
    
    private func generateQRCode(for eventId: String, userId: String) -> String {
        // Generate QR code data
        return "levelfitness://ticket/\(eventId)/\(userId)"
    }
    
    private func isClubOwner(clubId: String, userId: String? = nil) async throws -> Bool {
        let checkUserId = userId ?? AuthenticationService.shared.currentUserId ?? ""
        // TODO: Implement actual check
        return true // Placeholder
    }
    
    private func isMember(userId: String, clubId: String) async throws -> Bool {
        // TODO: Implement actual check
        return false // Placeholder
    }
    
    private func canInviteMembers(clubId: String) async throws -> Bool {
        // Check if user is owner or admin
        // TODO: Implement actual check
        return true // Placeholder
    }
    
    private func canRemoveMembers(clubId: String) async throws -> Bool {
        // Check if user is owner or admin
        // TODO: Implement actual check
        return true // Placeholder
    }
    
    private func hasEventTicket(userId: String, eventId: String) async throws -> Bool {
        // TODO: Implement actual check
        return false // Placeholder
    }
    
    private func fetchClub(_ clubId: String) async throws -> Club? {
        // TODO: Implement actual fetch
        return nil // Placeholder
    }
    
    private func fetchEvent(_ eventId: String) async throws -> VirtualEvent? {
        // TODO: Implement actual fetch
        return nil // Placeholder
    }
    
    private func getClubMemberCount(_ clubId: String) async throws -> Int {
        // TODO: Implement actual count
        return 1 // Placeholder
    }
    
    private func incrementMemberCount(_ clubId: String) async throws {
        // TODO: Implement actual increment
    }
    
    private func decrementMemberCount(_ clubId: String) async throws {
        // TODO: Implement actual decrement
    }
    
    private func incrementParticipantCount(_ eventId: String) async throws {
        // TODO: Implement actual increment
    }
    
    private func calculateEventRevenue(clubId: String) async throws -> Double {
        // TODO: Implement actual calculation
        return 0.0 // Placeholder
    }
    
    private func addMember(userId: String, to clubId: String, role: ClubMemberRole) async throws {
        // TODO: Implement actual addition
        print("ClubService: Adding member \(userId) to club \(clubId) as \(role)")
    }
    
    private func processMembershipPayment(userId: String, club: Club) async throws {
        // TODO: Implement payment processing
        print("ClubService: Processing \(club.monthlyFee) USD payment for club \(club.name)")
    }
    
    private func processTicketPayment(userId: String, event: VirtualEvent) async throws {
        // TODO: Implement payment processing
        print("ClubService: Processing \(event.ticketPrice) USD ticket payment")
    }
}

// MARK: - Data Models

struct Club: Codable {
    let id: String
    let name: String
    let description: String
    let ownerId: String
    let category: ClubCategory
    var memberCount: Int
    let maxMembers: Int
    let monthlyFee: Double
    let currency: String
    var totalRevenue: Double
    let imageUrl: String?
    let inviteCode: String
    let isPublic: Bool
    let isPremium: Bool
    let features: [String]
    let rules: [String]
    let status: String
    let createdAt: Date
    let updatedAt: Date
}

struct ClubCreationData {
    let name: String
    let description: String
    let ownerId: String
    let category: ClubCategory
    let monthlyFee: Double
    let imageUrl: String?
    let isPublic: Bool
    let isPremium: Bool
    let features: [String]
    let rules: [String]
}

struct ClubUpdateData {
    let name: String?
    let description: String?
    let monthlyFee: Double?
    let imageUrl: String?
    let isPublic: Bool?
    let features: [String]?
    let rules: [String]?
}

struct ClubInvitation: Codable {
    let id: String
    let clubId: String
    let invitedEmail: String
    let invitedBy: String
    let status: String
    let createdAt: Date
    let expiresAt: Date
}

struct VirtualEvent: Codable {
    let id: String
    let clubId: String
    let name: String
    let description: String
    let type: EventType
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int
    let ticketPrice: Double
    let prizePool: Double
    let requirements: [String]
    let status: String
    var participantCount: Int
    let createdAt: Date
}

struct VirtualEventData {
    let clubId: String
    let name: String
    let description: String
    let type: EventType
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int
    let ticketPrice: Double
    let prizePool: Double
    let requirements: [String]
}

struct EventTicket: Codable {
    let id: String
    let eventId: String
    let userId: String
    let ticketNumber: String
    let qrCode: String
    let purchaseDate: Date
    let status: String
}

struct ClubRevenue {
    let clubId: String
    let monthlySubscriptions: Double
    let eventTickets: Double
    let platformFee: Double
    let netRevenue: Double
    let lastPayout: Date
    let nextPayout: Date
}

enum ClubCategory: String, Codable, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
    case fitness = "Fitness"
    case yoga = "Yoga"
    case crossfit = "CrossFit"
    case swimming = "Swimming"
    case hiking = "Hiking"
    case sports = "Sports"
    case wellness = "Wellness"
    case other = "Other"
}

enum EventType: String, Codable {
    case marathon = "Marathon"
    case race = "Race"
    case challenge = "Challenge"
    case workout = "Workout"
    case competition = "Competition"
    case training = "Training"
}

enum ClubMemberRole: String, Codable {
    case owner = "owner"
    case admin = "admin"
    case moderator = "moderator"
    case member = "member"
}

// MARK: - Errors

enum ClubError: LocalizedError {
    case subscriptionRequired
    case premiumSubscriptionRequired
    case notAuthorized
    case clubNotFound
    case clubFull
    case alreadyMember
    case ownerCannotLeave
    case hasActiveMembers
    case invalidName
    case invalidDescription
    case invalidFee
    case eventNotFound
    case eventFull
    case alreadyRegistered
    
    var errorDescription: String? {
        switch self {
        case .subscriptionRequired:
            return "Club subscription required to create clubs"
        case .premiumSubscriptionRequired:
            return "Member subscription required to join premium clubs"
        case .notAuthorized:
            return "Not authorized to perform this action"
        case .clubNotFound:
            return "Club not found"
        case .clubFull:
            return "Club has reached maximum capacity"
        case .alreadyMember:
            return "Already a member of this club"
        case .ownerCannotLeave:
            return "Club owner cannot leave. Transfer ownership first"
        case .hasActiveMembers:
            return "Cannot delete club with active members"
        case .invalidName:
            return "Club name must be 3-50 characters"
        case .invalidDescription:
            return "Club description must be 10-500 characters"
        case .invalidFee:
            return "Monthly fee must be between $0-100"
        case .eventNotFound:
            return "Event not found"
        case .eventFull:
            return "Event has reached maximum capacity"
        case .alreadyRegistered:
            return "Already registered for this event"
        }
    }
}

// MARK: - NotificationService Extensions

extension NotificationService {
    func scheduleClubCreationConfirmation(clubName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Club Created! 🎉"
        content.body = "\(clubName) is now live. Start inviting members!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "club_creation",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request, completionHandler: nil)
    }
    
    func scheduleClubWelcome(clubName: String, userId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Welcome to \(clubName)! 👋"
        content.body = "You're now a member. Check out upcoming events and challenges!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "club_welcome_\(userId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request, completionHandler: nil)
    }
    
    func scheduleTicketConfirmation(eventName: String, ticketNumber: String) {
        let content = UNMutableNotificationContent()
        content.title = "Ticket Confirmed! 🎟️"
        content.body = "Your ticket (\(ticketNumber)) for \(eventName) is ready"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "ticket_\(ticketNumber)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request, completionHandler: nil)
    }
}