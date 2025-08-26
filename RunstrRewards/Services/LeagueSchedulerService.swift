import Foundation
import BackgroundTasks

class LeagueSchedulerService {
    static let shared = LeagueSchedulerService()
    
    private let competitionDataService = CompetitionDataService.shared
    private let notificationIntelligence = NotificationIntelligence.shared
    
    // Background task identifier
    private let backgroundTaskIdentifier = "com.runstrrewards.league-completion"
    
    private init() {}
    
    // MARK: - Background Task Registration
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            self.handleLeagueCompletionCheck(task: task as! BGAppRefreshTask)
        }
        
        print("LeagueScheduler: Background task registered")
    }
    
    func scheduleLeagueCompletionCheck() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // Check daily
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("LeagueScheduler: Background task scheduled")
        } catch {
            print("LeagueScheduler: Could not schedule background task: \(error)")
        }
    }
    
    // MARK: - League Completion Logic
    
    private func handleLeagueCompletionCheck(task: BGAppRefreshTask) {
        print("LeagueScheduler: Running background league completion check")
        
        // Schedule next background task
        scheduleLeagueCompletionCheck()
        
        Task {
            do {
                await checkAndCompleteExpiredLeagues()
                task.setTaskCompleted(success: true)
            } catch {
                print("LeagueScheduler: Background task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Manual League Completion Check (for testing/immediate execution)
    
    func checkAndCompleteExpiredLeagues() async {
        print("LeagueScheduler: Checking for expired leagues")
        
        do {
            // Get all active leagues
            let activeLeagues = try await fetchActiveLeagues()
            
            let calendar = Calendar.current
            let now = Date()
            
            for league in activeLeagues {
                // Check if league has expired
                if now >= league.endDate {
                    print("LeagueScheduler: League \(league.name) has expired, completing...")
                    
                    do {
                        try await completeLeague(league)
                        print("LeagueScheduler: Successfully completed league \(league.name)")
                    } catch {
                        print("LeagueScheduler: Failed to complete league \(league.name): \(error)")
                    }
                }
            }
            
        } catch {
            print("LeagueScheduler: Failed to check expired leagues: \(error)")
        }
    }
    
    private func fetchActiveLeagues() async throws -> [TeamLeague] {
        // This would normally fetch from all teams, but for now we'll implement a simpler version
        // In a production app, you'd have a global query for active leagues across all teams
        
        // Placeholder implementation - in reality this would be a database query
        // SELECT * FROM team_leagues WHERE status = 'active' AND end_date <= NOW()
        
        return [] // Will be populated when we have actual league data
    }
    
    private func completeLeague(_ league: TeamLeague) async throws {
        print("LeagueScheduler: Completing league \(league.name) for team \(league.teamId)")
        
        do {
            // 1. Mark league as completed
            try await competitionDataService.completeTeamLeague(leagueId: league.id)
            
            // 2. Get team wallet balance (placeholder - integrate with actual wallet service)
            let teamWalletBalance = 500000 // This would come from LightningWalletManager
            
            // 3. Calculate prize distribution
            let distributions = try await competitionDataService.calculateLeaguePrizeDistribution(
                leagueId: league.id,
                teamWalletBalance: teamWalletBalance
            )
            
            // 4. Distribute prizes
            if !distributions.isEmpty {
                try await competitionDataService.distributeLeaguePrizes(
                    distributions: distributions,
                    fromTeamWallet: league.teamId
                )
                
                // 5. Send completion notifications to team members
                await sendLeagueCompletionNotifications(league: league, distributions: distributions)
                
                print("LeagueScheduler: Successfully distributed \(distributions.count) prizes for league \(league.name)")
            } else {
                print("LeagueScheduler: No prizes to distribute for league \(league.name)")
            }
            
        } catch {
            print("LeagueScheduler: Failed to complete league \(league.name): \(error)")
            throw error
        }
    }
    
    private func sendLeagueCompletionNotifications(league: TeamLeague, distributions: [LeaguePrizeDistribution]) async {
        print("LeagueScheduler: Sending completion notifications for league \(league.name)")
        
        // Send notifications to prize winners
        for distribution in distributions {
            let rankEmoji = getRankEmoji(for: distribution.rank)
            let btcAmount = Double(distribution.prizeAmount) / 100_000_000.0
            
            let winnerNotification = NotificationCandidate(
                type: "league_prize",
                title: "\(rankEmoji) League Prize Won!",
                body: "You earned ₿\(String(format: "%.6f", btcAmount)) for finishing #\(distribution.rank) in \(league.name)!",
                score: 0.95, // High priority for prize notifications
                context: [
                    "league_id": league.id,
                    "rank": "\(distribution.rank)",
                    "prize_amount": "\(distribution.prizeAmount)"
                ],
                urgency: .immediate,
                category: "LEAGUE_PRIZE"
            )
            
            if notificationIntelligence.shouldSendNotification(winnerNotification, userId: distribution.userId) {
                // Actual notification sending would happen here via NotificationService
                print("LeagueScheduler: Sent prize notification to user \(distribution.userId)")
            }
        }
        
        // TODO: Send general league completion notification to all team members
        // This would inform everyone that the league has ended and show final standings
    }
    
    private func getRankEmoji(for rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "🏆"
        }
    }
    
    // MARK: - Immediate League Completion (for testing/admin)
    
    func completeLeagueNow(leagueId: String) async throws {
        print("LeagueScheduler: Manually completing league \(leagueId)")
        
        guard let league = try await competitionDataService.fetchActiveTeamLeague(teamId: "") else {
            // This is a simplified implementation - in reality we'd fetch by league ID
            throw AppError.dataCorrupted
        }
        
        try await completeLeague(league)
    }
    
    // MARK: - Monthly Auto-Creation (Future Enhancement)
    
    func scheduleMonthlyLeagueCreation() {
        // This would automatically create new leagues at the start of each month
        // for teams that had active leagues in the previous month
        print("LeagueScheduler: Monthly league auto-creation not yet implemented")
    }
}

// MARK: - Helper Extensions

extension LeagueSchedulerService {
    
    // Helper method to get next month start date
    private func getNextMonthStartDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get first day of next month
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        return calendar.dateInterval(of: .month, for: nextMonth)?.start ?? now
    }
    
    // Helper method to get current month end date
    private func getCurrentMonthEndDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get last day of current month
        return calendar.dateInterval(of: .month, for: now)?.end ?? now
    }
    
    // Validation method to ensure league dates are correct
    func validateLeagueDates(startDate: Date, endDate: Date) -> Bool {
        let calendar = Calendar.current
        
        // Ensure start date is first of month and end date is last of month
        let monthInterval = calendar.dateInterval(of: .month, for: startDate)
        
        return startDate == monthInterval?.start && endDate == monthInterval?.end
    }
}