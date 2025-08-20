import Foundation
import UIKit

class TeamInvitationService {
    static let shared = TeamInvitationService()
    
    private let supabaseService = SupabaseService.shared
    private let authService = AuthenticationService.shared
    
    private init() {}
    
    // MARK: - Invitation Models
    
    struct TeamInvitation {
        let teamId: String
        let teamName: String
        let inviteCode: String
        let expiresAt: Date?
        let createdBy: String
    }
    
    struct InvitationResult {
        let success: Bool
        let message: String
        let team: Team?
    }
    
    // MARK: - QR Code Generation
    
    func generateTeamInviteQRCode(for teamId: String) -> UIImage? {
        let inviteLink = generateInviteLink(teamId: teamId)
        return generateQRCode(from: inviteLink)
    }
    
    func generateInviteLink(teamId: String) -> String {
        // Generate a unique invite code
        let inviteCode = UUID().uuidString.prefix(8).uppercased()
        
        // Store invite code in database (would need to be implemented)
        Task {
            await storeInviteCode(teamId: teamId, code: String(inviteCode))
        }
        
        // Return deep link URL
        return "runstrrewards://join-team/\(teamId)/\(inviteCode)"
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")
            
            if let outputImage = filter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledImage = outputImage.transformed(by: transform)
                
                let context = CIContext()
                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    let qrImage = UIImage(cgImage: cgImage)
                    
                    // Add branding overlay
                    return addBrandingToQRCode(qrImage)
                }
            }
        }
        
        return nil
    }
    
    private func addBrandingToQRCode(_ qrImage: UIImage) -> UIImage {
        let size = qrImage.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Draw QR code
            qrImage.draw(at: .zero)
            
            // Add center logo (optional)
            let logoSize = CGSize(width: size.width * 0.2, height: size.height * 0.2)
            let logoRect = CGRect(
                x: (size.width - logoSize.width) / 2,
                y: (size.height - logoSize.height) / 2,
                width: logoSize.width,
                height: logoSize.height
            )
            
            // Draw white background for logo
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: logoRect.insetBy(dx: -5, dy: -5))
            
            // Draw "R" logo
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: logoSize.width * 0.6, weight: .bold),
                .foregroundColor: IndustrialDesign.Colors.accentText,
                .paragraphStyle: paragraphStyle
            ]
            
            let text = "R"
            let textRect = CGRect(
                x: logoRect.origin.x,
                y: logoRect.origin.y + logoSize.height * 0.15,
                width: logoSize.width,
                height: logoSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    // MARK: - QR Code Processing
    
    func processScannedQRCode(_ code: String) async -> InvitationResult {
        print("Processing QR code: \(code)")
        
        // Parse the QR code
        guard let invitation = parseInviteLink(code) else {
            return InvitationResult(
                success: false,
                message: "Invalid QR code format",
                team: nil
            )
        }
        
        // Validate user is logged in
        guard let userId = authService.currentUserId else {
            return InvitationResult(
                success: false,
                message: "Please sign in to join a team",
                team: nil
            )
        }
        
        // Check if invite code is valid
        let isValid = await validateInviteCode(invitation.teamId, code: invitation.inviteCode)
        guard isValid else {
            return InvitationResult(
                success: false,
                message: "This invitation has expired or is invalid",
                team: nil
            )
        }
        
        // Check if user is already a member
        do {
            let isMember = try await supabaseService.isUserMemberOfTeam(
                userId: userId,
                teamId: invitation.teamId
            )
            
            if isMember {
                return InvitationResult(
                    success: false,
                    message: "You're already a member of this team",
                    team: nil
                )
            }
            
            // Get team details
            guard let team = try await supabaseService.getTeam(invitation.teamId) else {
                return InvitationResult(
                    success: false,
                    message: "Team not found",
                    team: nil
                )
            }
            
            // Join the team
            try await supabaseService.joinTeam(teamId: invitation.teamId, userId: userId)
            
            return InvitationResult(
                success: true,
                message: "Successfully joined \(team.name)!",
                team: team
            )
            
        } catch {
            print("Error processing team invitation: \(error)")
            return InvitationResult(
                success: false,
                message: "Failed to join team. Please try again.",
                team: nil
            )
        }
    }
    
    private func parseInviteLink(_ link: String) -> (teamId: String, inviteCode: String)? {
        // Parse deep link format: runstrrewards://join-team/{teamId}/{inviteCode}
        if link.hasPrefix("runstrrewards://join-team/") {
            let components = link.replacingOccurrences(of: "runstrrewards://join-team/", with: "").split(separator: "/")
            if components.count == 2 {
                return (String(components[0]), String(components[1]))
            }
        }
        
        // Parse web link format: https://runstrrewards.com/join/{teamId}/{inviteCode}
        if link.hasPrefix("https://runstrrewards.com/join/") {
            let components = link.replacingOccurrences(of: "https://runstrrewards.com/join/", with: "").split(separator: "/")
            if components.count == 2 {
                return (String(components[0]), String(components[1]))
            }
        }
        
        // Try to parse as raw team ID (backward compatibility)
        if link.count == 36 { // UUID length
            return (link, "DIRECT")
        }
        
        return nil
    }
    
    // MARK: - Database Operations
    
    private func storeInviteCode(teamId: String, code: String) async {
        // Store invite code in Supabase
        // This would need to be implemented in SupabaseService
        print("Storing invite code \(code) for team \(teamId)")
        
        // TODO: Implement database storage
        // await supabaseService.storeTeamInviteCode(teamId: teamId, code: code)
    }
    
    private func validateInviteCode(_ teamId: String, code: String) async -> Bool {
        // For now, accept all codes
        // In production, this would check the database
        print("Validating invite code \(code) for team \(teamId)")
        
        // TODO: Implement database validation
        // return await supabaseService.validateTeamInviteCode(teamId: teamId, code: code)
        
        return true
    }
    
    // MARK: - Deep Link Handling
    
    func handleDeepLink(_ url: URL) -> Bool {
        guard url.scheme == "runstrrewards",
              url.host == "join-team" else {
            return false
        }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 1 else { return false }
        
        let teamId = pathComponents[0]
        let inviteCode = pathComponents.count > 1 ? pathComponents[1] : "DIRECT"
        
        // Process the invitation
        Task {
            let link = "runstrrewards://join-team/\(teamId)/\(inviteCode)"
            let result = await processScannedQRCode(link)
            
            await MainActor.run {
                showInvitationResult(result)
            }
        }
        
        return true
    }
    
    private func showInvitationResult(_ result: InvitationResult) {
        guard let topViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        let alert = UIAlertController(
            title: result.success ? "Success!" : "Unable to Join",
            message: result.message,
            preferredStyle: .alert
        )
        
        if result.success, let team = result.team {
            alert.addAction(UIAlertAction(title: "View Team", style: .default) { _ in
                // Navigate to team detail
                navigateToTeam(team)
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        topViewController.present(alert, animated: true)
    }
    
    private func navigateToTeam(_ team: Team) {
        // This would navigate to the team detail view
        // Implementation depends on your navigation structure
        print("Navigating to team: \(team.name)")
        
        // Post notification for navigation
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToTeam"),
            object: nil,
            userInfo: ["team": team]
        )
    }
}