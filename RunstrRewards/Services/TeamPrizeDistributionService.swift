import Foundation

// MARK: - Prize Distribution Models

struct PrizeDistribution {
    let distributionId: String
    let eventId: String
    let teamId: String
    let totalPrize: Double
    let distributionMethod: DistributionMethod
    let recipients: [PrizeRecipient]
    let status: DistributionStatus
    let createdDate: Date
    let executedDate: Date?
    let createdBy: String // Captain user ID
    let notes: String?
}

struct PrizeRecipient {
    let userId: String
    let username: String
    let allocation: Double      // Amount in sats
    let percentage: Double      // Percentage of total prize
    let reason: String          // Reason for this allocation
    let performance: PerformanceMetrics?
    let payoutStatus: PayoutStatus
    let payoutDate: Date?
    let transactionId: String?
}

struct PerformanceMetrics {
    let totalDistance: Double
    let totalWorkouts: Int
    let points: Int
    let rank: Int
    let participation: Double   // Participation rate 0.0-1.0
    let consistency: Double     // Consistency score 0.0-1.0
}

enum DistributionMethod {
    case equal                  // Equal split among all members
    case performance           // Based on performance metrics
    case custom                // Custom amounts set by captain
    case hybrid                // Combination of performance and equal
    case topPerformers         // Only top N performers
}

enum DistributionStatus {
    case draft
    case pending
    case approved
    case executing
    case completed
    case failed
    case cancelled
}

enum PayoutStatus {
    case pending
    case processing
    case completed
    case failed
}

struct TeamWalletBalance {
    let teamId: String
    let totalBalance: Double
    let availableBalance: Double
    let pendingDistributions: Double
    let lastUpdated: Date
    let transactions: [TeamTransaction]
}

struct TeamTransaction {
    let transactionId: String
    let type: TeamTransactionType
    let amount: Double
    let description: String
    let timestamp: Date
    let userId: String?
    let eventId: String?
}

enum TeamTransactionType {
    case prizeReceived
    case prizeDistributed
    case memberContribution
    case feeDeducted
}

// MARK: - TeamPrizeDistributionService

class TeamPrizeDistributionService {
    static let shared = TeamPrizeDistributionService()
    
    private var distributions: [String: PrizeDistribution] = [:]
    private var teamWallets: [String: TeamWalletBalance] = [:]
    private let lightningWalletManager = LightningWalletManager.shared
    private let eventNotificationService = EventNotificationService.shared
    
    private init() {
        initializeTeamWallets()
        observeEventCompletions()
    }
    
    // MARK: - Setup
    
    private func initializeTeamWallets() {
        // Initialize team wallets with sample data
        teamWallets["team_1"] = TeamWalletBalance(
            teamId: "team_1",
            totalBalance: 25000, // 25k sats
            availableBalance: 25000,
            pendingDistributions: 0,
            lastUpdated: Date(),
            transactions: []
        )
    }
    
    private func observeEventCompletions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEventCompleted),
            name: NSNotification.Name("EventCompleted"),
            object: nil
        )
    }
    
    // MARK: - Prize Distribution Creation
    
    func createDistribution(
        eventId: String,
        teamId: String,
        method: DistributionMethod,
        totalPrize: Double,
        captainUserId: String,
        notes: String? = nil
    ) -> Result<PrizeDistribution, DistributionError> {
        
        // Validate team wallet has sufficient balance
        guard let wallet = teamWallets[teamId] else {
            return .failure(.teamWalletNotFound)
        }
        
        guard wallet.availableBalance >= totalPrize else {
            return .failure(.insufficientBalance)
        }
        
        // Get team members and their performance
        guard let teamMembers = getTeamMembers(teamId: teamId) else {
            return .failure(.teamMembersNotFound)
        }
        
        let performanceMetrics = getPerformanceMetrics(eventId: eventId, teamMembers: teamMembers)
        
        // Calculate distribution based on method
        guard let recipients = calculateDistribution(
            method: method,
            totalPrize: totalPrize,
            teamMembers: teamMembers,
            performanceMetrics: performanceMetrics
        ) else {
            return .failure(.distributionCalculationFailed)
        }
        
        // Create distribution
        let distribution = PrizeDistribution(
            distributionId: UUID().uuidString,
            eventId: eventId,
            teamId: teamId,
            totalPrize: totalPrize,
            distributionMethod: method,
            recipients: recipients,
            status: .draft,
            createdDate: Date(),
            executedDate: nil,
            createdBy: captainUserId,
            notes: notes
        )
        
        distributions[distribution.distributionId] = distribution
        
        // Update team wallet to reserve funds
        reserveFunds(teamId: teamId, amount: totalPrize)
        
        print("💰 Distribution: Created distribution \(distribution.distributionId) for team \(teamId): ₿\(Int(totalPrize))")
        
        return .success(distribution)
    }
    
    private func calculateDistribution(
        method: DistributionMethod,
        totalPrize: Double,
        teamMembers: [String],
        performanceMetrics: [String: PerformanceMetrics]
    ) -> [PrizeRecipient]? {
        
        var recipients: [PrizeRecipient] = []
        
        switch method {
        case .equal:
            let amountPerMember = totalPrize / Double(teamMembers.count)
            let percentagePerMember = 100.0 / Double(teamMembers.count)
            
            for userId in teamMembers {
                recipients.append(PrizeRecipient(
                    userId: userId,
                    username: getUserDisplayName(userId: userId),
                    allocation: amountPerMember,
                    percentage: percentagePerMember,
                    reason: "Equal distribution among all team members",
                    performance: performanceMetrics[userId],
                    payoutStatus: .pending,
                    payoutDate: nil,
                    transactionId: nil
                ))
            }
            
        case .performance:
            let totalPoints = performanceMetrics.values.reduce(0) { $0 + $1.points }
            guard totalPoints > 0 else { return nil }
            
            for userId in teamMembers {
                guard let metrics = performanceMetrics[userId] else { continue }
                
                let percentage = Double(metrics.points) / Double(totalPoints) * 100.0
                let allocation = (Double(metrics.points) / Double(totalPoints)) * totalPrize
                
                recipients.append(PrizeRecipient(
                    userId: userId,
                    username: getUserDisplayName(userId: userId),
                    allocation: allocation,
                    percentage: percentage,
                    reason: "Performance-based: \(metrics.points) points, rank #\(metrics.rank)",
                    performance: metrics,
                    payoutStatus: .pending,
                    payoutDate: nil,
                    transactionId: nil
                ))
            }
            
        case .topPerformers:
            // Only distribute to top 50% of performers
            let sortedMembers = teamMembers.compactMap { userId in
                performanceMetrics[userId].map { (userId, $0) }
            }.sorted { $0.1.points > $1.1.points }
            
            let topCount = max(1, sortedMembers.count / 2)
            let topPerformers = Array(sortedMembers.prefix(topCount))
            
            let totalTopPoints = topPerformers.reduce(0) { $0 + $1.1.points }
            guard totalTopPoints > 0 else { return nil }
            
            for (userId, metrics) in topPerformers {
                let percentage = Double(metrics.points) / Double(totalTopPoints) * 100.0
                let allocation = (Double(metrics.points) / Double(totalTopPoints)) * totalPrize
                
                recipients.append(PrizeRecipient(
                    userId: userId,
                    username: getUserDisplayName(userId: userId),
                    allocation: allocation,
                    percentage: percentage,
                    reason: "Top performer: #\(metrics.rank) with \(metrics.points) points",
                    performance: metrics,
                    payoutStatus: .pending,
                    payoutDate: nil,
                    transactionId: nil
                ))
            }
            
        case .hybrid:
            // 50% equal, 50% performance-based
            let equalPortion = totalPrize * 0.5
            let performancePortion = totalPrize * 0.5
            
            let equalPerMember = equalPortion / Double(teamMembers.count)
            let totalPoints = performanceMetrics.values.reduce(0) { $0 + $1.points }
            
            for userId in teamMembers {
                guard let metrics = performanceMetrics[userId] else { continue }
                
                let performanceAllocation = totalPoints > 0 ? 
                    (Double(metrics.points) / Double(totalPoints)) * performancePortion : 0
                
                let totalAllocation = equalPerMember + performanceAllocation
                let percentage = (totalAllocation / totalPrize) * 100.0
                
                recipients.append(PrizeRecipient(
                    userId: userId,
                    username: getUserDisplayName(userId: userId),
                    allocation: totalAllocation,
                    percentage: percentage,
                    reason: "Hybrid: 50% equal + 50% performance (\(metrics.points) pts)",
                    performance: metrics,
                    payoutStatus: .pending,
                    payoutDate: nil,
                    transactionId: nil
                ))
            }
            
        case .custom:
            // Custom allocations would be set by the captain in the UI
            // For now, return nil to indicate captain must set custom amounts
            return nil
        }
        
        return recipients
    }
    
    // MARK: - Distribution Execution
    
    func executeDistribution(distributionId: String) -> Result<Void, DistributionError> {
        guard var distribution = distributions[distributionId] else {
            return .failure(.distributionNotFound)
        }
        
        guard distribution.status == .approved || distribution.status == .draft else {
            return .failure(.invalidDistributionStatus)
        }
        
        // Update status to executing
        distribution = PrizeDistribution(
            distributionId: distribution.distributionId,
            eventId: distribution.eventId,
            teamId: distribution.teamId,
            totalPrize: distribution.totalPrize,
            distributionMethod: distribution.distributionMethod,
            recipients: distribution.recipients,
            status: .executing,
            createdDate: distribution.createdDate,
            executedDate: Date(),
            createdBy: distribution.createdBy,
            notes: distribution.notes
        )
        
        distributions[distributionId] = distribution
        
        // Execute payouts to each recipient
        var updatedRecipients: [PrizeRecipient] = []
        var executionSuccess = true
        
        for recipient in distribution.recipients {
            let payoutResult = executePayoutToMember(
                recipient: recipient,
                teamId: distribution.teamId
            )
            
            switch payoutResult {
            case .success(let updatedRecipient):
                updatedRecipients.append(updatedRecipient)
                
                // Send prize notification
                eventNotificationService.createPrizeNotification(
                    eventId: distribution.eventId,
                    userId: recipient.userId,
                    prizeAmount: recipient.allocation
                )
                
            case .failure(let error):
                print("💰 Distribution: Payout failed for user \(recipient.userId): \(error)")
                
                // Keep original recipient with failed status
                var failedRecipient = recipient
                failedRecipient = PrizeRecipient(
                    userId: failedRecipient.userId,
                    username: failedRecipient.username,
                    allocation: failedRecipient.allocation,
                    percentage: failedRecipient.percentage,
                    reason: failedRecipient.reason,
                    performance: failedRecipient.performance,
                    payoutStatus: .failed,
                    payoutDate: nil,
                    transactionId: nil
                )
                
                updatedRecipients.append(failedRecipient)
                executionSuccess = false
            }
        }
        
        // Update distribution with results
        let finalStatus: DistributionStatus = executionSuccess ? .completed : .failed
        
        let finalDistribution = PrizeDistribution(
            distributionId: distribution.distributionId,
            eventId: distribution.eventId,
            teamId: distribution.teamId,
            totalPrize: distribution.totalPrize,
            distributionMethod: distribution.distributionMethod,
            recipients: updatedRecipients,
            status: finalStatus,
            createdDate: distribution.createdDate,
            executedDate: Date(),
            createdBy: distribution.createdBy,
            notes: distribution.notes
        )
        
        distributions[distributionId] = finalDistribution
        
        // Update team wallet
        updateTeamWalletAfterDistribution(
            teamId: distribution.teamId,
            amount: distribution.totalPrize,
            distributionId: distributionId,
            success: executionSuccess
        )
        
        print("💰 Distribution: Execution completed for \(distributionId): \(executionSuccess ? "Success" : "Partial failure")")
        
        return executionSuccess ? .success(()) : .failure(.payoutExecutionFailed)
    }
    
    private func executePayoutToMember(
        recipient: PrizeRecipient,
        teamId: String
    ) -> Result<PrizeRecipient, DistributionError> {
        
        // In a real implementation, this would use the Lightning Network
        // For now, simulate the payout process
        
        let success = simulatePayoutTransaction(
            userId: recipient.userId,
            amount: recipient.allocation
        )
        
        if success {
            let transactionId = UUID().uuidString
            
            let updatedRecipient = PrizeRecipient(
                userId: recipient.userId,
                username: recipient.username,
                allocation: recipient.allocation,
                percentage: recipient.percentage,
                reason: recipient.reason,
                performance: recipient.performance,
                payoutStatus: .completed,
                payoutDate: Date(),
                transactionId: transactionId
            )
            
            return .success(updatedRecipient)
        } else {
            return .failure(.payoutExecutionFailed)
        }
    }
    
    private func simulatePayoutTransaction(userId: String, amount: Double) -> Bool {
        // Simulate Lightning Network transaction with 95% success rate
        let success = Int.random(in: 1...100) <= 95
        
        if success {
            print("💰 Payout: Successfully sent ₿\(Int(amount)) to user \(userId)")
            
            // Send prize distribution notification to the user
            Task {
                await MainActor.run {
                    NotificationService.shared.schedulePrizeDistributionNotification(
                        amount: Int(amount),
                        reason: "league performance",  // This should be passed from context
                        teamName: "Your Team"          // This should be passed from context
                    )
                }
            }
            
        } else {
            print("💰 Payout: Failed to send ₿\(Int(amount)) to user \(userId)")
        }
        
        return success
    }
    
    // MARK: - Team Wallet Management
    
    private func reserveFunds(teamId: String, amount: Double) {
        guard var wallet = teamWallets[teamId] else { return }
        
        wallet = TeamWalletBalance(
            teamId: wallet.teamId,
            totalBalance: wallet.totalBalance,
            availableBalance: wallet.availableBalance - amount,
            pendingDistributions: wallet.pendingDistributions + amount,
            lastUpdated: Date(),
            transactions: wallet.transactions
        )
        
        teamWallets[teamId] = wallet
    }
    
    private func updateTeamWalletAfterDistribution(
        teamId: String,
        amount: Double,
        distributionId: String,
        success: Bool
    ) {
        guard var wallet = teamWallets[teamId] else { return }
        
        let transaction = TeamTransaction(
            transactionId: UUID().uuidString,
            type: .prizeDistributed,
            amount: -amount,
            description: "Prize distribution \(success ? "completed" : "failed"): \(distributionId)",
            timestamp: Date(),
            userId: nil,
            eventId: nil
        )
        
        var transactions = wallet.transactions
        transactions.append(transaction)
        
        if success {
            // Remove from total balance and pending
            wallet = TeamWalletBalance(
                teamId: wallet.teamId,
                totalBalance: wallet.totalBalance - amount,
                availableBalance: wallet.availableBalance,
                pendingDistributions: wallet.pendingDistributions - amount,
                lastUpdated: Date(),
                transactions: transactions
            )
        } else {
            // Return funds to available balance
            wallet = TeamWalletBalance(
                teamId: wallet.teamId,
                totalBalance: wallet.totalBalance,
                availableBalance: wallet.availableBalance + amount,
                pendingDistributions: wallet.pendingDistributions - amount,
                lastUpdated: Date(),
                transactions: transactions
            )
        }
        
        teamWallets[teamId] = wallet
    }
    
    func addPrizeToTeamWallet(teamId: String, amount: Double, eventId: String) {
        guard var wallet = teamWallets[teamId] else { return }
        
        let transaction = TeamTransaction(
            transactionId: UUID().uuidString,
            type: .prizeReceived,
            amount: amount,
            description: "Prize received from event: \(eventId)",
            timestamp: Date(),
            userId: nil,
            eventId: eventId
        )
        
        var transactions = wallet.transactions
        transactions.append(transaction)
        
        wallet = TeamWalletBalance(
            teamId: wallet.teamId,
            totalBalance: wallet.totalBalance + amount,
            availableBalance: wallet.availableBalance + amount,
            pendingDistributions: wallet.pendingDistributions,
            lastUpdated: Date(),
            transactions: transactions
        )
        
        teamWallets[teamId] = wallet
        
        print("💰 TeamWallet: Added ₿\(Int(amount)) prize to team \(teamId) from event \(eventId)")
    }
    
    // MARK: - Event Handlers
    
    @objc private func handleEventCompleted(_ notification: Notification) {
        guard let eventId = notification.userInfo?["eventId"] as? String,
              let prizeAmount = notification.userInfo?["prizeAmount"] as? Double,
              let winningTeamId = notification.userInfo?["winningTeamId"] as? String else {
            return
        }
        
        // Add prize to winning team's wallet
        addPrizeToTeamWallet(teamId: winningTeamId, amount: prizeAmount, eventId: eventId)
        
        print("💰 Distribution: Event \(eventId) completed, prize added to team \(winningTeamId)")
    }
    
    // MARK: - Data Access
    
    func getDistribution(distributionId: String) -> PrizeDistribution? {
        return distributions[distributionId]
    }
    
    func getDistributionsForTeam(teamId: String) -> [PrizeDistribution] {
        return distributions.values.filter { $0.teamId == teamId }
            .sorted { $0.createdDate > $1.createdDate }
    }
    
    func getTeamWallet(teamId: String) -> TeamWalletBalance? {
        return teamWallets[teamId]
    }
    
    func approveDistribution(distributionId: String) -> Bool {
        guard var distribution = distributions[distributionId] else { return false }
        
        distribution = PrizeDistribution(
            distributionId: distribution.distributionId,
            eventId: distribution.eventId,
            teamId: distribution.teamId,
            totalPrize: distribution.totalPrize,
            distributionMethod: distribution.distributionMethod,
            recipients: distribution.recipients,
            status: .approved,
            createdDate: distribution.createdDate,
            executedDate: distribution.executedDate,
            createdBy: distribution.createdBy,
            notes: distribution.notes
        )
        
        distributions[distributionId] = distribution
        return true
    }
    
    func cancelDistribution(distributionId: String) -> Bool {
        guard var distribution = distributions[distributionId] else { return false }
        guard distribution.status == .draft || distribution.status == .approved else { return false }
        
        // Return reserved funds to available balance
        if let wallet = teamWallets[distribution.teamId] {
            var updatedWallet = wallet
            updatedWallet = TeamWalletBalance(
                teamId: wallet.teamId,
                totalBalance: wallet.totalBalance,
                availableBalance: wallet.availableBalance + distribution.totalPrize,
                pendingDistributions: wallet.pendingDistributions - distribution.totalPrize,
                lastUpdated: Date(),
                transactions: wallet.transactions
            )
            teamWallets[distribution.teamId] = updatedWallet
        }
        
        distribution = PrizeDistribution(
            distributionId: distribution.distributionId,
            eventId: distribution.eventId,
            teamId: distribution.teamId,
            totalPrize: distribution.totalPrize,
            distributionMethod: distribution.distributionMethod,
            recipients: distribution.recipients,
            status: .cancelled,
            createdDate: distribution.createdDate,
            executedDate: distribution.executedDate,
            createdBy: distribution.createdBy,
            notes: distribution.notes
        )
        
        distributions[distributionId] = distribution
        return true
    }
    
    // MARK: - Helper Methods
    
    private func getTeamMembers(teamId: String) -> [String]? {
        // In a real implementation, this would fetch from team service
        return ["user_1", "user_2", "user_3", "user_4", "user_5"]
    }
    
    private func getPerformanceMetrics(eventId: String, teamMembers: [String]) -> [String: PerformanceMetrics] {
        var metrics: [String: PerformanceMetrics] = [:]
        
        for userId in teamMembers {
            if let progress = EventProgressTracker.shared.getProgress(eventId: eventId, userId: userId) {
                metrics[userId] = PerformanceMetrics(
                    totalDistance: progress.currentValue,
                    totalWorkouts: progress.recentWorkouts.count,
                    points: progress.recentWorkouts.reduce(0) { $0 + $1.points },
                    rank: progress.rank,
                    participation: progress.recentWorkouts.isEmpty ? 0.0 : 1.0,
                    consistency: calculateConsistency(workouts: progress.recentWorkouts)
                )
            } else {
                // Default metrics for non-participating members
                metrics[userId] = PerformanceMetrics(
                    totalDistance: 0,
                    totalWorkouts: 0,
                    points: 0,
                    rank: teamMembers.count,
                    participation: 0.0,
                    consistency: 0.0
                )
            }
        }
        
        return metrics
    }
    
    private func calculateConsistency(workouts: [ProgressWorkout]) -> Double {
        guard !workouts.isEmpty else { return 0.0 }
        
        // Simple consistency calculation based on workout frequency
        let sortedWorkouts = workouts.sorted { $0.date < $1.date }
        
        if sortedWorkouts.count < 2 {
            return 0.5
        }
        
        let totalDays = sortedWorkouts.last!.date.timeIntervalSince(sortedWorkouts.first!.date) / (24 * 3600)
        let workoutDays = Double(sortedWorkouts.count)
        
        return min(workoutDays / max(totalDays, 1.0), 1.0)
    }
    
    private func getUserDisplayName(userId: String) -> String {
        // In a real implementation, this would fetch from user service
        return "User \(userId.prefix(8))"
    }
    
    func getPendingDistributions(teamId: String) async throws -> [PrizeDistribution] {
        // Return pending distributions for the team
        return distributions.values.filter { distribution in
            distribution.teamId == teamId && distribution.status == .pending
        }
    }
}

// MARK: - Distribution Errors

enum DistributionError: Error, LocalizedError {
    case teamWalletNotFound
    case insufficientBalance
    case teamMembersNotFound
    case distributionCalculationFailed
    case distributionNotFound
    case invalidDistributionStatus
    case payoutExecutionFailed
    
    var errorDescription: String? {
        switch self {
        case .teamWalletNotFound:
            return "Team wallet not found"
        case .insufficientBalance:
            return "Insufficient balance in team wallet"
        case .teamMembersNotFound:
            return "Unable to find team members"
        case .distributionCalculationFailed:
            return "Failed to calculate prize distribution"
        case .distributionNotFound:
            return "Distribution not found"
        case .invalidDistributionStatus:
            return "Distribution is not in a valid state for this operation"
        case .payoutExecutionFailed:
            return "Failed to execute one or more payouts"
        }
    }
}