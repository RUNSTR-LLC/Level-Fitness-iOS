import Foundation

class TeamWalletDataService {
    
    // MARK: - Properties
    weak var delegate: TeamWalletDataDelegate?
    private let teamWalletManager = TeamWalletManager.shared
    private let prizeDistributionService = TeamPrizeDistributionService.shared
    
    // MARK: - Public Methods
    
    func verifyAccessAndLoadData(for teamData: TeamData, userId: String) async {
        do {
            // Check captain access first
            let isCaptain = try await checkCaptainAccess(teamId: teamData.id, userId: userId)
            
            await MainActor.run {
                delegate?.didUpdateCaptainStatus(isCaptain)
            }
            
            if !isCaptain {
                await MainActor.run {
                    delegate?.didFailWithError("Only team captains can access wallet management")
                }
                return
            }
            
            // Load wallet data if user is captain
            await loadWalletData(for: teamData.id)
            
        } catch {
            print("❌ TeamWalletDataService: Failed to verify access: \(error)")
            await MainActor.run {
                delegate?.didFailWithError("Failed to verify wallet access: \(error.localizedDescription)")
            }
        }
    }
    
    func loadWalletData(for teamId: String) async {
        do {
            await MainActor.run {
                delegate?.didStartLoading()
            }
            
            // Load wallet balance and transactions in parallel
            async let walletTask = teamWalletManager.getTeamWalletBalance(teamId: teamId)
            async let transactionsTask = TransactionDataService.shared.getTeamTransactions(teamId: teamId, limit: 10)
            
            let walletBalance = try await walletTask
            let transactions = try await transactionsTask
            
            // Convert WalletBalance to TeamWalletBalance
            let teamBalance = TeamWalletBalance(
                teamId: teamId,
                totalBalance: Double(walletBalance.total),
                availableBalance: Double(walletBalance.lightning),
                pendingDistributions: 0,  // This would come from a separate query if needed
                lastUpdated: Date(),
                transactions: transactions
            )
            
            await MainActor.run {
                delegate?.didLoadWalletData(balance: teamBalance, transactions: transactions)
                delegate?.didStopLoading()
            }
            
            print("✅ TeamWalletDataService: Successfully loaded wallet data")
            
        } catch {
            print("❌ TeamWalletDataService: Failed to load wallet data: \(error)")
            await MainActor.run {
                delegate?.didStopLoading()
                delegate?.didFailWithError("Failed to load wallet data: \(error.localizedDescription)")
            }
        }
    }
    
    func loadPendingDistributions(for teamId: String) async {
        do {
            let distributions = try await prizeDistributionService.getPendingDistributions(teamId: teamId)
            
            await MainActor.run {
                delegate?.didLoadPendingDistributions(distributions)
            }
            
            print("✅ TeamWalletDataService: Loaded \(distributions.count) pending distributions")
            
        } catch {
            print("❌ TeamWalletDataService: Failed to load pending distributions: \(error)")
        }
    }
    
    func processRewardDistribution(for teamId: String) async {
        do {
            await MainActor.run {
                delegate?.didStartDistribution()
            }
            
            let result = try await prizeDistributionService.distributeTeamRewards(teamId: teamId)
            
            await MainActor.run {
                delegate?.didCompleteDistribution(result)
            }
            
            // Reload wallet data after distribution
            await loadWalletData(for: teamId)
            
            print("✅ TeamWalletDataService: Distribution completed successfully")
            
        } catch {
            print("❌ TeamWalletDataService: Distribution failed: \(error)")
            await MainActor.run {
                delegate?.didFailDistribution(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkCaptainAccess(teamId: String, userId: String) async throws -> Bool {
        let teamDetail = try await SupabaseService.shared.fetchTeamDetail(teamId: teamId)
        return teamDetail.captainId == userId
    }
}

// MARK: - Delegate Protocol

protocol TeamWalletDataDelegate: AnyObject {
    func didUpdateCaptainStatus(_ isCaptain: Bool)
    func didStartLoading()
    func didStopLoading()
    func didLoadWalletData(balance: TeamWalletBalance, transactions: [TeamTransaction])
    func didLoadPendingDistributions(_ distributions: [PrizeDistribution])
    func didStartDistribution()
    func didCompleteDistribution(_ result: DistributionResult)
    func didFailDistribution(_ error: String)
    func didFailWithError(_ message: String)
}