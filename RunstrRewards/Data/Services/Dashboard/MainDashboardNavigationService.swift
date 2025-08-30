import Foundation
import UIKit
import CoreImage

class MainDashboardNavigationService {
    static let shared = MainDashboardNavigationService()
    
    private init() {}
    
    convenience init(viewController: UIViewController) {
        self.init()
        // Store reference if needed
    }
    
    // MARK: - Navigation Methods
    
    func navigateToTeamsOrTeamDetail(userActiveTeam: TeamData?, from viewController: UIViewController) {
        if let team = userActiveTeam {
            showTeamNavigationOptions(currentTeam: team, from: viewController)
        } else {
            navigateToTeams(from: viewController)
        }
    }
    
    private func showTeamNavigationOptions(currentTeam: TeamData, from viewController: UIViewController) {
        let alert = UIAlertController(title: "Team Options", message: "Choose an option for your team", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "View \(currentTeam.name)", style: .default) { _ in
            self.navigateToTeamDetail(team: currentTeam, from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Browse All Teams", style: .default) { _ in
            self.navigateToTeams(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                                  y: viewController.view.bounds.midY,
                                                  width: 0, height: 0)
        }
        
        viewController.present(alert, animated: true)
    }
    
    private func navigateToTeamDetail(team: TeamData, from viewController: UIViewController) {
        let teamDetailVC = TeamDetailViewController(teamData: team)
        viewController.navigationController?.pushViewController(teamDetailVC, animated: true)
    }
    
    func navigateToTeams(from viewController: UIViewController) {
        let teamsVC = TeamsViewController()
        viewController.navigationController?.pushViewController(teamsVC, animated: true)
    }
    
    func navigateToWallet(from viewController: UIViewController) {
        let walletVC = EarningsViewController()
        viewController.navigationController?.pushViewController(walletVC, animated: true)
    }
    
    func navigateToProfile(from viewController: UIViewController) {
        let profileVC = ProfileViewController()
        viewController.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func navigateToLottery(from viewController: UIViewController) {
        let lotteryVC = LotteryComingSoonViewController()
        lotteryVC.modalPresentationStyle = .pageSheet
        if let sheet = lotteryVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        viewController.present(lotteryVC, animated: true)
    }
    
    func navigateToWorkouts(from viewController: UIViewController) {
        let workoutsVC = WorkoutsViewController()
        viewController.navigationController?.pushViewController(workoutsVC, animated: true)
    }
    
    func navigateToNotifications(from viewController: UIViewController) {
        let notificationsVC = NotificationInboxViewController()
        viewController.navigationController?.pushViewController(notificationsVC, animated: true)
    }
    
    func navigateToCompetitions(from viewController: UIViewController) {
        let competitionsVC = CompetitionsViewController()
        viewController.navigationController?.pushViewController(competitionsVC, animated: true)
    }
    
    func navigateToTeamCreation(from viewController: UIViewController) {
        let teamCreationVC = TeamCreationWizardViewController()
        let navController = UINavigationController(rootViewController: teamCreationVC)
        viewController.present(navController, animated: true)
    }
    
    func navigateToEventDetail(_ eventId: String, from viewController: UIViewController) {
        Task {
            do {
                // Create a temporary CompetitionEvent with the ID - EventDetailViewController should handle loading
                let tempEvent = CompetitionEvent(
                    id: eventId,
                    name: "Loading...",
                    description: nil,
                    type: "loading",
                    targetValue: 0,
                    unit: "none",
                    entryFee: 0,
                    prizePool: 0,
                    startDate: Date(),
                    endDate: Date(),
                    maxParticipants: nil,
                    participantCount: 0,
                    status: "active",
                    imageUrl: nil,
                    rules: nil,
                    createdAt: Date()
                )
                
                await MainActor.run {
                    let eventDetailVC = EventDetailViewController(event: tempEvent)
                    viewController.navigationController?.pushViewController(eventDetailVC, animated: true)
                }
            }
        }
    }
    
    func presentSettings(from viewController: UIViewController) {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        viewController.present(navController, animated: true)
    }
    
    // MARK: - Quick Actions
    
    func showTeamInviteFlow(for teamId: String, from viewController: UIViewController) {
        let alert = UIAlertController(title: "Invite Members", message: "Share your team with friends", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Show QR Code", style: .default) { _ in
            self.showQRCode(for: teamId, from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Share Link", style: .default) { _ in
            self.shareTeamLink(teamId, from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
    
    private func showQRCode(for teamId: String, from viewController: UIViewController) {
        Task {
            do {
                // Generate QR code for team
                let teamURL = "https://runstrrewards.com/teams/\(teamId)"
                let qrImage = generateQRCode(from: teamURL) ?? UIImage(systemName: "qrcode")!
                
                // Get team name - using placeholder for now
                let teamName = "Team"
                
                await MainActor.run {
                    let qrVC = QRCodeDisplayViewController(qrImage: qrImage, teamName: teamName, teamId: teamId)
                    viewController.present(qrVC, animated: true)
                }
            }
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    private func shareTeamLink(_ teamId: String, from viewController: UIViewController) {
        let shareURL = "https://runstrrewards.com/teams/\(teamId)"
        let activityVC = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
        viewController.present(activityVC, animated: true)
    }
}