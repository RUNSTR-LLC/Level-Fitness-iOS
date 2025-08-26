import Foundation

// Helper script to clean up test teams
// Add this function temporarily to your TeamsViewController or run it in a test

func cleanupTestTeams() {
    Task {
        do {
            // Fetch all teams
            let teams = try await TeamDataService.shared.fetchTeams()
            print("Found \(teams.count) teams in database:")
            
            for team in teams {
                print("- Team: \(team.name) (ID: \(team.id))")
                print("  Captain: \(team.captainId)")
                print("  Members: \(team.memberCount)")
                print("  Created: \(team.createdAt)")
                print("---")
            }
            
            // Get current user ID
            guard let currentUserId = AuthenticationService.shared.currentUserId else {
                print("No user logged in")
                return
            }
            
            print("\nYour user ID: \(currentUserId)")
            
            // Find teams where current user is captain
            let myTeams = teams.filter { $0.captainId == currentUserId }
            
            if myTeams.isEmpty {
                print("You are not a captain of any teams")
            } else {
                print("\nYou are captain of \(myTeams.count) team(s):")
                for team in myTeams {
                    print("- \(team.name) (ID: \(team.id))")
                }
                
                // Uncomment the lines below to actually delete your teams
                // WARNING: This will permanently delete the teams!
                /*
                for team in myTeams {
                    print("Deleting team: \(team.name)...")
                    try await TeamDataService.shared.deleteTeam(teamId: team.id)
                    print("✅ Deleted team: \(team.name)")
                }
                */
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}

// To use this:
// 1. Add this function to your TeamsViewController
// 2. Call it from viewDidLoad() temporarily: cleanupTestTeams()
// 3. Run the app to see all teams
// 4. Uncomment the delete lines if you want to delete your teams
// 5. Remove the function when done