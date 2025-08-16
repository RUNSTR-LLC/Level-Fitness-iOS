import UIKit

// MARK: - Industrial Design System
struct IndustrialDesign {
    
    // MARK: - Colors
    struct Colors {
        static let background = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0) // #0a0a0a
        static let cardBackground = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // #1a1a1a
        static let cardBorder = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0) // #2a2a2a
        static let cardBorderHover = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 1.0) // #444
        
        static let primaryText = UIColor.white
        static let secondaryText = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) // #666
        static let accentText = UIColor(red: 0.53, green: 0.53, blue: 0.53, alpha: 1.0) // #888
        
        static let gridOverlay = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.03)
        static let gearBackground = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.02)
        
        static let bitcoin = UIColor(red: 0.97, green: 0.58, blue: 0.1, alpha: 1.0) // #f7931a
        
        // Gradients
        static let logoGradient = [
            UIColor.white.cgColor,
            UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0).cgColor
        ]
        
        static let cardGradient = [
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).cgColor,
            UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0).cgColor
        ]
    }
    
    // MARK: - Typography
    struct Typography {
        static let logoFont = UIFont.systemFont(ofSize: 36, weight: .heavy)
        static let taglineFont = UIFont.systemFont(ofSize: 19, weight: .semibold)
        static let navTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let navSubtitleFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        static let usernameFont = UIFont.systemFont(ofSize: 18, weight: .medium)
        static let statValueFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        static let statLabelFont = UIFont.systemFont(ofSize: 11, weight: .semibold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 40
    }
    
    // MARK: - Sizing
    struct Sizing {
        static let avatarSize: CGFloat = 40
        static let iconSize: CGFloat = 48
        static let gearIconSize: CGFloat = 40
        static let cardMinHeight: CGFloat = 140
        static let cardCornerRadius: CGFloat = 12
        static let boltSize: CGFloat = 8
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

// MARK: - CAGradientLayer Extensions
extension CAGradientLayer {
    static func industrial() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = IndustrialDesign.Colors.cardGradient
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }
    
    static func logo() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = IndustrialDesign.Colors.logoGradient
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        return gradient
    }
}