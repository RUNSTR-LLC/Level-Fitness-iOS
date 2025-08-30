import Foundation
import UIKit

class MainDashboardDataService {
    static let shared = MainDashboardDataService()
    
    // MARK: - Properties
    weak var delegate: MainDashboardDataDelegate?
    
    init() {}
    
    // MARK: - Public Methods
    
    func loadRealUserStats() {
        Task {
            await loadUserTeam()
            await loadWalletBalance()
        }
    }
    
    func loadUserTeam() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else {
                print("🏭 RUNSTR: No user session found for team loading")
                return
            }
            
            // Fetch user's teams from Supabase
            let teams = try await SupabaseService.shared.fetchUserTeams(userId: userSession.id)
            
            if let firstTeam = teams.first {
                let teamData = TeamData(
                    id: firstTeam.id,
                    name: firstTeam.name,
                    captain: firstTeam.captainId,
                    captainId: firstTeam.captainId,
                    members: firstTeam.memberCount,
                    prizePool: String(format: "%.0f", firstTeam.currentPrizePool),
                    activities: ["Running", "Cycling"],
                    isJoined: true
                )
                
                await MainActor.run {
                    delegate?.didLoadUserTeam(teamData)
                }
                
                print("🏭 RUNSTR: Loaded user's primary team: \(firstTeam.name)")
            } else {
                await MainActor.run {
                    delegate?.didLoadUserTeam(nil)
                }
                print("🏭 RUNSTR: User has no teams")
            }
            
        } catch {
            print("🏭 RUNSTR: Failed to load user team: \(error)")
            await MainActor.run {
                delegate?.didFailToLoadUserTeam(error)
            }
        }
    }
    
    func loadWalletBalance() async {
        do {
            // Load wallet balance from CoinOS
            let balance = try await CoinOSService.shared.getBalance()
            
            await MainActor.run {
                delegate?.didLoadWalletBalance(balance.total)
            }
            
            print("🏭 RUNSTR: Loaded wallet balance: \(balance.total) sats")
            
        } catch {
            print("🏭 RUNSTR: Failed to load wallet balance: \(error)")
            await MainActor.run {
                delegate?.didFailToLoadWalletBalance(error)
            }
        }
    }
    
    func loadWorkoutStats() async {
        do {
            guard let userSession = AuthenticationService.shared.loadSession() else { return }
            
            // Fetch user's recent workouts
            let workouts = try await WorkoutDataService.shared.fetchUserWorkouts(
                userId: userSession.id,
                limit: 30
            )
            
            let weeklyWorkouts = workouts.filter { workout in
                let workoutDate = workout.startedAt
                return workoutDate.timeIntervalSinceNow > -7 * 24 * 3600 // Last 7 days
            }
            
            let thisWeekCount = weeklyWorkouts.count
            let totalCalories = weeklyWorkouts.reduce(0) { $0 + ($1.calories ?? 0) }
            
            await MainActor.run {
                delegate?.didLoadWorkoutStats(weeklyCount: thisWeekCount, totalCalories: Int(totalCalories))
            }
            
            print("🏭 RUNSTR: Loaded workout stats - This week: \(thisWeekCount), Calories: \(totalCalories)")
            
        } catch {
            print("🏭 RUNSTR: Failed to load workout stats: \(error)")
            await MainActor.run {
                delegate?.didFailToLoadWorkoutStats(error)
            }
        }
    }
    
    func loadHealthKitWorkoutStats() async {
        do {
            // Fetch recent workouts from HealthKit
            let healthKitWorkouts = try await HealthKitService.shared.fetchRecentWorkouts(limit: 50)
            
            // Filter to this week
            let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let thisWeekWorkouts = healthKitWorkouts.filter { $0.startDate >= weekStart }
            
            let thisWeekCount = thisWeekWorkouts.count
            let totalCalories = thisWeekWorkouts.reduce(0) { $0 + Int($1.totalEnergyBurned ?? 0) }
            
            await MainActor.run {
                delegate?.didLoadHealthKitWorkoutStats(weeklyCount: thisWeekCount, totalCalories: totalCalories)
            }
            
            print("🏭 RUNSTR: Loaded HealthKit stats - This week: \(thisWeekCount), Calories: \(totalCalories)")
            
        } catch {
            print("🏭 RUNSTR: Failed to load HealthKit workout stats: \(error)")
        }
    }
}

// MARK: - Delegate Protocol

protocol MainDashboardDataDelegate: AnyObject {
    func didLoadUserTeam(_ team: TeamData?)
    func didFailToLoadUserTeam(_ error: Error)
    func didLoadWalletBalance(_ balance: Int)
    func didFailToLoadWalletBalance(_ error: Error)
    func didLoadWorkoutStats(weeklyCount: Int, totalCalories: Int)
    func didFailToLoadWorkoutStats(_ error: Error)
    func didLoadHealthKitWorkoutStats(weeklyCount: Int, totalCalories: Int)
}