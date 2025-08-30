import Foundation

// MARK: - Challenge Model
// Maps to the 'challenges' table in the database

struct Challenge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let status: String
    let prizePool: Int
    let entryFee: Int
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int?
    let participantCount: Int
    let createdBy: String
    let teamId: String?
    let rules: [String: String]?
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, status, rules
        case prizePool = "prize_pool"
        case entryFee = "entry_fee"
        case startDate = "start_date"
        case endDate = "end_date"
        case maxParticipants = "max_participants"
        case participantCount = "participant_count"
        case createdBy = "created_by"
        case teamId = "team_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Challenge Types
    
    static let supportedTypes = [
        "distance",
        "duration",
        "calories",
        "steps",
        "streak"
    ]
    
    // MARK: - Computed Properties
    
    var isActive: Bool {
        return status == "active"
    }
    
    var isCompleted: Bool {
        return status == "completed"
    }
    
    var isPending: Bool {
        return status == "pending"
    }
    
    var durationDays: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var isTeamChallenge: Bool {
        return teamId != nil
    }
    
    // MARK: - Challenge Status Validation
    
    func canJoin(userId: String) -> Bool {
        guard status == "pending" || status == "active" else { return false }
        guard Date() < endDate else { return false }
        
        if let maxParticipants = maxParticipants {
            return participantCount < maxParticipants
        }
        
        return true
    }
    
    func canStart() -> Bool {
        return status == "pending" && Date() >= startDate
    }
    
    func shouldEnd() -> Bool {
        return status == "active" && Date() >= endDate
    }
}