import Foundation

// MARK: - CompetitionEvent Model
// Maps to the 'events' table in the database

struct CompetitionEvent: Codable {
    let id: String
    let name: String
    let description: String?
    let type: String
    let targetValue: Double
    let unit: String
    let entryFee: Int
    let prizePool: Int
    let startDate: Date
    let endDate: Date
    let maxParticipants: Int?
    let participantCount: Int
    let status: String
    let imageUrl: String?
    let rules: [String: Any]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, unit, status
        case createdAt = "created_at"
        case targetValue = "target_value"
        case entryFee = "entry_fee"
        case prizePool = "prize_pool"
        case startDate = "start_date"
        case endDate = "end_date"
        case maxParticipants = "max_participants"
        case participantCount = "participant_count"
        case imageUrl = "image_url"
        case rules
    }
    
    // MARK: - Custom Codable Implementation for rules JSONB
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decode(String.self, forKey: .type)
        targetValue = try container.decode(Double.self, forKey: .targetValue)
        unit = try container.decode(String.self, forKey: .unit)
        entryFee = try container.decode(Int.self, forKey: .entryFee)
        prizePool = try container.decode(Int.self, forKey: .prizePool)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        maxParticipants = try container.decodeIfPresent(Int.self, forKey: .maxParticipants)
        participantCount = try container.decode(Int.self, forKey: .participantCount)
        status = try container.decode(String.self, forKey: .status)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Handle JSONB rules field
        if let rulesData = try container.decodeIfPresent(Data.self, forKey: .rules) {
            rules = try JSONSerialization.jsonObject(with: rulesData) as? [String: Any]
        } else {
            rules = nil
        }
    }
    
    // Custom initializer for creating temporary events
    init(id: String, name: String, description: String?, type: String, targetValue: Double, unit: String, entryFee: Int, prizePool: Int, startDate: Date, endDate: Date, maxParticipants: Int?, participantCount: Int, status: String, imageUrl: String?, rules: [String: Any]?, createdAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.targetValue = targetValue
        self.unit = unit
        self.entryFee = entryFee
        self.prizePool = prizePool
        self.startDate = startDate
        self.endDate = endDate
        self.maxParticipants = maxParticipants
        self.participantCount = participantCount
        self.status = status
        self.imageUrl = imageUrl
        self.rules = rules
        self.createdAt = createdAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(type, forKey: .type)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encode(unit, forKey: .unit)
        try container.encode(entryFee, forKey: .entryFee)
        try container.encode(prizePool, forKey: .prizePool)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encodeIfPresent(maxParticipants, forKey: .maxParticipants)
        try container.encode(participantCount, forKey: .participantCount)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Handle JSONB rules field
        if let rules = rules {
            let rulesData = try JSONSerialization.data(withJSONObject: rules)
            try container.encode(rulesData, forKey: .rules)
        }
    }
}
