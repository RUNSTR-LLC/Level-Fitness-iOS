import Foundation
import UIKit

// MARK: - Prize Pool Models

struct PrizePoolData {
    let eventId: String
    let eventName: String
    let totalPool: Double
    let contributionSources: [PrizeContribution]
    let distributionPlan: PrizeDistributionPlan?
    let status: PrizePoolStatus
    let participantCount: Int
    let projectedRewards: [ProjectedReward]
    let milestones: [PrizePoolMilestone]
}

struct PrizeContribution {
    let source: ContributionSource
    let amount: Double
    let percentage: Double
    let timestamp: Date
    let description: String
}

struct PrizeDistributionPlan {
    let method: DistributionMethod
    let topPerformerShare: Double    // Percentage for top performers
    let participationShare: Double   // Percentage for all participants
    let minimumPayout: Double        // Minimum payout per person
}

struct ProjectedReward {
    let rank: Int
    let estimatedAmount: Double
    let probability: Double // 0.0 - 1.0, likelihood of achieving this rank
}

struct PrizePoolMilestone {
    let threshold: Double
    let description: String
    let achieved: Bool
    let achievedDate: Date?
    let bonusMultiplier: Double?
}

enum ContributionSource {
    case teamFund
    case eventTickets
    case sponsorship
    case bonus
    case rollover
}

enum PrizePoolStatus {
    case building
    case ready
    case distributed
    case expired
}

struct PieChartData {
    let value: Double
    let color: UIColor
    let label: String
}

// MARK: - Extensions

extension PrizePoolStatus {
    var displayName: String {
        switch self {
        case .building: return "Building"
        case .ready: return "Ready"
        case .distributed: return "Distributed"
        case .expired: return "Expired"
        }
    }
    
    var color: UIColor {
        switch self {
        case .building: return UIColor.systemOrange
        case .ready: return UIColor.systemGreen
        case .distributed: return UIColor.systemBlue
        case .expired: return UIColor.systemGray
        }
    }
}

extension ContributionSource {
    var displayName: String {
        switch self {
        case .teamFund: return "Team Fund"
        case .eventTickets: return "Event Tickets"
        case .sponsorship: return "Sponsorship"
        case .bonus: return "Bonus"
        case .rollover: return "Previous Event Rollover"
        }
    }
    
    var color: UIColor {
        switch self {
        case .teamFund: return UIColor.systemBlue
        case .eventTickets: return UIColor.systemOrange
        case .sponsorship: return UIColor.systemPurple
        case .bonus: return UIColor.systemGreen
        case .rollover: return UIColor.systemTeal
        }
    }
}

