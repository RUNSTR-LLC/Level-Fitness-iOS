import UIKit
import CoreGraphics

// MARK: - App Icon Generator
class IconGenerator {
    
    static func generateAppIcons() {
        let iconSizes = [
            ("AppIcon-20@2x", 40),      // iPhone notification 20pt @2x
            ("AppIcon-20@3x", 60),      // iPhone notification 20pt @3x
            ("AppIcon-29@2x", 58),      // iPhone settings 29pt @2x
            ("AppIcon-29@3x", 87),      // iPhone settings 29pt @3x
            ("AppIcon-40@2x", 80),      // iPhone spotlight 40pt @2x
            ("AppIcon-40@3x", 120),     // iPhone spotlight 40pt @3x
            ("AppIcon-60@2x", 120),     // iPhone app 60pt @2x
            ("AppIcon-60@3x", 180),     // iPhone app 60pt @3x
            ("AppIcon-20@1x", 20),      // iPad notification 20pt @1x
            ("AppIcon-20@2x-ipad", 40), // iPad notification 20pt @2x
            ("AppIcon-29@1x", 29),      // iPad settings 29pt @1x
            ("AppIcon-29@2x-ipad", 58), // iPad settings 29pt @2x
            ("AppIcon-40@1x", 40),      // iPad spotlight 40pt @1x
            ("AppIcon-40@2x-ipad", 80), // iPad spotlight 40pt @2x
            ("AppIcon-76@2x", 152),     // iPad app 76pt @2x
            ("AppIcon-83.5@2x", 167),   // iPad Pro app 83.5pt @2x
            ("AppIcon-1024", 1024)      // App Store 1024pt @1x
        ]
        
        for (name, size) in iconSizes {
            let image = createAppIcon(size: CGFloat(size))
            saveImageToDocuments(image: image, fileName: "\(name).png")
        }
        
        print("App icons generated! Check Documents folder.")
    }
    
    static func createAppIcon(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Clean white background for the new design
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // Calculate scaling for logo based on icon size
            let logoScale = size / 120.0 // Base scale for 120pt logo
            
            // Center the logo
            let logoSize: CGFloat = 100 * logoScale
            let logoOrigin = CGPoint(x: (size - logoSize) / 2, y: (size - logoSize) / 2)
            
            // Draw the Runstr Rewards logo
            drawRunstrRewardsLogo(in: cgContext, origin: logoOrigin, size: logoSize, scale: logoScale, iconSize: size)
        }
    }
    
    static func drawRunningFigure(in context: CGContext, origin: CGPoint, size: CGFloat, scale: CGFloat) {
        // Set line drawing properties for clean line art
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(2.0 * scale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        let figureWidth = size
        let figureHeight = size * 0.8
        let centerX = origin.x + figureWidth / 2
        let centerY = origin.y + figureHeight / 2
        
        // Create the running figure path based on the provided image
        let path = CGMutablePath()
        
        // Head (circular)
        let headRadius = figureWidth * 0.08
        let headCenter = CGPoint(x: centerX + figureWidth * 0.15, y: centerY - figureHeight * 0.35)
        path.addEllipse(in: CGRect(
            x: headCenter.x - headRadius,
            y: headCenter.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        ))
        
        // Body/torso (curved line)
        path.move(to: CGPoint(x: headCenter.x, y: headCenter.y + headRadius))
        path.addCurve(
            to: CGPoint(x: centerX + figureWidth * 0.1, y: centerY + figureHeight * 0.1),
            control1: CGPoint(x: centerX + figureWidth * 0.12, y: centerY - figureHeight * 0.15),
            control2: CGPoint(x: centerX + figureWidth * 0.11, y: centerY - figureHeight * 0.05)
        )
        
        // Leading arm (extended forward)
        path.move(to: CGPoint(x: centerX + figureWidth * 0.12, y: centerY - figureHeight * 0.1))
        path.addCurve(
            to: CGPoint(x: centerX + figureWidth * 0.35, y: centerY - figureHeight * 0.05),
            control1: CGPoint(x: centerX + figureWidth * 0.25, y: centerY - figureHeight * 0.15),
            control2: CGPoint(x: centerX + figureWidth * 0.3, y: centerY - figureHeight * 0.1)
        )
        
        // Trailing arm (bent back)
        path.move(to: CGPoint(x: centerX + figureWidth * 0.08, y: centerY - figureHeight * 0.05))
        path.addCurve(
            to: CGPoint(x: centerX - figureWidth * 0.1, y: centerY + figureHeight * 0.05),
            control1: CGPoint(x: centerX - figureWidth * 0.02, y: centerY),
            control2: CGPoint(x: centerX - figureWidth * 0.08, y: centerY + figureHeight * 0.02)
        )
        
        // Leading leg (extended forward, foot on ground)
        path.move(to: CGPoint(x: centerX + figureWidth * 0.1, y: centerY + figureHeight * 0.1))
        path.addCurve(
            to: CGPoint(x: centerX + figureWidth * 0.25, y: centerY + figureHeight * 0.4),
            control1: CGPoint(x: centerX + figureWidth * 0.2, y: centerY + figureHeight * 0.2),
            control2: CGPoint(x: centerX + figureWidth * 0.22, y: centerY + figureHeight * 0.3)
        )
        
        // Trailing leg (lifted, knee high)
        path.move(to: CGPoint(x: centerX + figureWidth * 0.08, y: centerY + figureHeight * 0.12))
        path.addCurve(
            to: CGPoint(x: centerX - figureWidth * 0.08, y: centerY + figureHeight * 0.05),
            control1: CGPoint(x: centerX + figureWidth * 0.02, y: centerY + figureHeight * 0.15),
            control2: CGPoint(x: centerX - figureWidth * 0.02, y: centerY + figureHeight * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: centerX - figureWidth * 0.15, y: centerY + figureHeight * 0.25),
            control1: CGPoint(x: centerX - figureWidth * 0.1, y: centerY + figureHeight * 0.1),
            control2: CGPoint(x: centerX - figureWidth * 0.12, y: centerY + figureHeight * 0.18)
        )
        
        // Ground line
        path.move(to: CGPoint(x: origin.x - figureWidth * 0.1, y: centerY + figureHeight * 0.4))
        path.addLine(to: CGPoint(x: origin.x + figureWidth * 1.1, y: centerY + figureHeight * 0.4))
        
        // Motion lines (speed trails)
        drawMotionLines(in: context, origin: origin, size: size, scale: scale)
        
        // Draw the main figure path
        context.addPath(path)
        context.strokePath()
    }
    
    static func drawMotionLines(in context: CGContext, origin: CGPoint, size: CGFloat, scale: CGFloat) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5 * scale)
        context.setLineCap(.round)
        
        let centerY = origin.y + size * 0.4
        let lineSpacing = size * 0.05
        
        // Create motion lines behind the runner
        let motionLines = [
            (CGPoint(x: origin.x - size * 0.3, y: centerY - lineSpacing * 2), CGPoint(x: origin.x - size * 0.15, y: centerY - lineSpacing * 1.5)),
            (CGPoint(x: origin.x - size * 0.35, y: centerY - lineSpacing), CGPoint(x: origin.x - size * 0.2, y: centerY - lineSpacing * 0.5)),
            (CGPoint(x: origin.x - size * 0.4, y: centerY), CGPoint(x: origin.x - size * 0.25, y: centerY + lineSpacing * 0.5)),
            (CGPoint(x: origin.x - size * 0.35, y: centerY + lineSpacing), CGPoint(x: origin.x - size * 0.2, y: centerY + lineSpacing * 1.5)),
            (CGPoint(x: origin.x - size * 0.3, y: centerY + lineSpacing * 2), CGPoint(x: origin.x - size * 0.15, y: centerY + lineSpacing * 2.5))
        ]
        
        for (start, end) in motionLines {
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
    }
    
    static func drawRunstrRewardsText(in context: CGContext, origin: CGPoint, size: CGFloat, scale: CGFloat) {
        let fontSize = size * 0.15
        let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        
        // Set up text attributes for outline text
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0 * scale)
        context.setTextDrawingMode(.stroke)
        
        // "RUNSTR" text
        let runstrAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.clear,
            .strokeColor: UIColor.black,
            .strokeWidth: 2.0
        ]
        
        let runstrText = "RUNSTR"
        let runstrString = NSAttributedString(string: runstrText, attributes: runstrAttributes)
        let runstrSize = runstrString.size()
        let runstrOrigin = CGPoint(
            x: origin.x + (size - runstrSize.width) / 2,
            y: origin.y
        )
        runstrString.draw(at: runstrOrigin)
        
        // "REWARDS" text
        let rewardsText = "REWARDS"
        let rewardsString = NSAttributedString(string: rewardsText, attributes: runstrAttributes)
        let rewardsSize = rewardsString.size()
        let rewardsOrigin = CGPoint(
            x: origin.x + (size - rewardsSize.width) / 2,
            y: origin.y + fontSize * 1.2
        )
        rewardsString.draw(at: rewardsOrigin)
    }
    
    static func drawRRText(in context: CGContext, origin: CGPoint, size: CGFloat, scale: CGFloat) {
        let fontSize = size * 0.8
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black,
            .strokeColor: UIColor.black,
            .strokeWidth: 1.0
        ]
        
        let text = "RR"
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        let textOrigin = CGPoint(
            x: origin.x + (size - textSize.width) / 2,
            y: origin.y + (size - textSize.height) / 2
        )
        
        attributedString.draw(at: textOrigin)
    }
    
    static func addGridPattern(to context: CGContext, size: CGFloat) {
        context.setStrokeColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.015).cgColor)
        context.setLineWidth(0.5)
        
        let gridSpacing: CGFloat = max(4, size / 32) // Adaptive grid spacing
        
        for i in stride(from: 0, to: size, by: gridSpacing) {
            // Vertical lines
            context.move(to: CGPoint(x: i, y: 0))
            context.addLine(to: CGPoint(x: i, y: size))
            
            // Horizontal lines
            context.move(to: CGPoint(x: 0, y: i))
            context.addLine(to: CGPoint(x: size, y: i))
        }
        
        context.strokePath()
    }
    
    static func drawRunstrRewardsLogo(in context: CGContext, origin: CGPoint, size: CGFloat, scale: CGFloat, iconSize: CGFloat) {
        // Draw the running figure
        drawRunningFigure(in: context, origin: origin, size: size * 0.6, scale: scale)
        
        // For larger icons, add text below the figure
        if iconSize >= 180 {
            let textOrigin = CGPoint(x: origin.x, y: origin.y + size * 0.75)
            drawRunstrRewardsText(in: context, origin: textOrigin, size: size, scale: scale)
        } else if iconSize >= 60 {
            // For medium icons, just add "RR" text
            let textOrigin = CGPoint(x: origin.x, y: origin.y + size * 0.75)
            drawRRText(in: context, origin: textOrigin, size: size * 0.4, scale: scale)
        }
    }
    
    static func drawIndustrialL(in context: CGContext, origin: CGPoint, scale: CGFloat) {
        let path = createIndustrialLPath(origin: origin, scale: scale)
        
        // Fill with white
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
        
        // Add subtle inner shadow effect
        context.setShadow(offset: CGSize(width: 0, height: 1 * scale), blur: 2 * scale, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
        
        // Add bolt holes for industrial look
        addBoltHoles(to: context, origin: origin, scale: scale)
    }
    
    static func createIndustrialLPath(origin: CGPoint, scale: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let adjustedScale = scale * 0.8 // Make L slightly smaller to fit better
        
        // Create a correct L shape: vertical stroke on left, horizontal stroke at bottom
        path.move(to: CGPoint(x: origin.x + 25 * adjustedScale, y: origin.y + 15 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 35 * adjustedScale, y: origin.y + 15 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 35 * adjustedScale, y: origin.y + 85 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 85 * adjustedScale, y: origin.y + 85 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 85 * adjustedScale, y: origin.y + 75 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 25 * adjustedScale, y: origin.y + 75 * adjustedScale))
        path.close()
        
        return path
    }
    
    static func addBoltHoles(to context: CGContext, origin: CGPoint, scale: CGFloat) {
        let adjustedScale = scale * 0.8
        let boltPositions = [
            CGPoint(x: origin.x + 45 * adjustedScale, y: origin.y + 35 * adjustedScale),
            CGPoint(x: origin.x + 45 * adjustedScale, y: origin.y + 55 * adjustedScale),
            CGPoint(x: origin.x + 65 * adjustedScale, y: origin.y + 90 * adjustedScale)
        ]
        
        let boltRadius: CGFloat = 2 * adjustedScale
        
        for position in boltPositions {
            // Dark hole
            context.setFillColor(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4).cgColor)
            context.fillEllipse(in: CGRect(
                x: position.x - boltRadius,
                y: position.y - boltRadius,
                width: boltRadius * 2,
                height: boltRadius * 2
            ))
            
            // Highlight
            context.setFillColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2).cgColor)
            context.fillEllipse(in: CGRect(
                x: position.x - boltRadius * 0.5,
                y: position.y - boltRadius * 0.5,
                width: boltRadius,
                height: boltRadius
            ))
        }
    }
    
    static func addSmallGears(in context: CGContext, origin: CGPoint, logoSize: CGFloat, scale: CGFloat) {
        let gearSize: CGFloat = 12 * scale
        
        // Top right gear
        let gear1Position = CGPoint(
            x: origin.x + logoSize - gearSize/2,
            y: origin.y - gearSize/2
        )
        
        drawSmallGear(in: context, center: gear1Position, radius: gearSize/2)
        
        // Bottom left gear
        let gear2Position = CGPoint(
            x: origin.x - gearSize/2,
            y: origin.y + logoSize - gearSize/2
        )
        
        drawSmallGear(in: context, center: gear2Position, radius: gearSize/2 * 0.7)
    }
    
    static func drawSmallGear(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let teeth = 8
        let innerRadius = radius * 0.6
        
        context.setFillColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1).cgColor)
        context.setStrokeColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3).cgColor)
        context.setLineWidth(0.5)
        
        let path = CGMutablePath()
        
        for i in 0..<teeth * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(teeth)
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + cos(angle) * currentRadius,
                y: center.y + sin(angle) * currentRadius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        context.addPath(path)
        context.drawPath(using: .fillStroke)
        
        // Center hole
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.fillEllipse(in: CGRect(
            x: center.x - radius * 0.2,
            y: center.y - radius * 0.2,
            width: radius * 0.4,
            height: radius * 0.4
        ))
    }
    
    static func addBitcoinAccent(in context: CGContext, origin: CGPoint, logoSize: CGFloat, scale: CGFloat) {
        // Small bitcoin orange accent in top right corner of the L
        let accentSize: CGFloat = 4 * scale
        let accentPosition = CGPoint(
            x: origin.x + logoSize * 0.7,
            y: origin.y + logoSize * 0.2
        )
        
        context.setFillColor(IndustrialDesign.Colors.bitcoin.cgColor)
        context.fillEllipse(in: CGRect(
            x: accentPosition.x - accentSize/2,
            y: accentPosition.y - accentSize/2,
            width: accentSize,
            height: accentSize
        ))
        
        // Glow effect
        context.setShadow(
            offset: CGSize.zero,
            blur: 2 * scale,
            color: IndustrialDesign.Colors.bitcoin.withAlphaComponent(0.6).cgColor
        )
        context.fillEllipse(in: CGRect(
            x: accentPosition.x - accentSize/2,
            y: accentPosition.y - accentSize/2,
            width: accentSize,
            height: accentSize
        ))
    }
    
    static func saveImageToDocuments(image: UIImage, fileName: String) {
        guard let data = image.pngData() else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documentsPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            print("Saved: \(fileName) to \(url.path)")
        } catch {
            print("Error saving \(fileName): \(error)")
        }
    }
    
    // MARK: - Logo Asset Generator
    static func generateLogoAssets() {
        let logoSizes = [
            ("logo", 64),           // Standard logo
            ("logo@2x", 128),       // @2x logo
            ("logo@3x", 192),       // @3x logo
            ("logo-small", 32),     // Small logo
            ("logo-small@2x", 64),  // Small @2x logo
            ("logo-small@3x", 96),  // Small @3x logo
            ("logo-large", 128),    // Large logo
            ("logo-large@2x", 256), // Large @2x logo
            ("logo-large@3x", 384)  // Large @3x logo
        ]
        
        for (name, size) in logoSizes {
            let image = createLogoAsset(size: CGFloat(size))
            saveImageToDocuments(image: image, fileName: "\(name).png")
        }
        
        print("Logo assets generated! Check Documents folder.")
        print("Copy these files to:")
        print("- RunstrRewardsLogo.imageset/")
        print("- RunstrRewardsLogoSmall.imageset/") 
        print("- RunstrRewardsLogoLarge.imageset/")
    }
    
    static func createLogoAsset(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Transparent background for logo assets
            cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
            
            // Calculate scaling for logo based on size
            let logoScale = size / 64.0 // Base scale for 64pt logo
            
            // Center the logo
            let logoSize: CGFloat = 48 * logoScale
            let logoOrigin = CGPoint(x: (size - logoSize) / 2, y: (size - logoSize) / 2)
            
            // Draw Runstr Rewards logo for assets
            drawRunstrRewardsLogo(in: cgContext, origin: logoOrigin, size: logoSize, scale: logoScale, iconSize: size)
        }
    }
    
    static func drawLogoL(in context: CGContext, origin: CGPoint, scale: CGFloat) {
        let path = createLogoLPath(origin: origin, scale: scale)
        
        // Fill with solid white
        context.setFillColor(UIColor.white.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
        
        // Add subtle shadow for depth
        context.setShadow(offset: CGSize(width: 0, height: 1 * scale), blur: 2 * scale, color: UIColor.black.withAlphaComponent(0.2).cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
        
        // Add bolt holes for industrial look
        addLogoBoltHoles(to: context, origin: origin, scale: scale)
    }
    
    static func createLogoLPath(origin: CGPoint, scale: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        
        // Create correct L shape - optimized for smaller sizes
        path.move(to: CGPoint(x: origin.x + 10 * scale, y: origin.y + 8 * scale))   // Top-left of vertical
        path.addLine(to: CGPoint(x: origin.x + 18 * scale, y: origin.y + 8 * scale)) // Top-right of vertical  
        path.addLine(to: CGPoint(x: origin.x + 18 * scale, y: origin.y + 40 * scale)) // Down to bottom of vertical
        path.addLine(to: CGPoint(x: origin.x + 38 * scale, y: origin.y + 40 * scale)) // Right across horizontal
        path.addLine(to: CGPoint(x: origin.x + 38 * scale, y: origin.y + 32 * scale)) // Up to top of horizontal 
        path.addLine(to: CGPoint(x: origin.x + 10 * scale, y: origin.y + 32 * scale)) // Left to inner corner
        path.close()
        
        return path
    }
    
    static func addLogoBoltHoles(to context: CGContext, origin: CGPoint, scale: CGFloat) {
        let boltPositions = [
            CGPoint(x: origin.x + 22 * scale, y: origin.y + 15 * scale),
            CGPoint(x: origin.x + 22 * scale, y: origin.y + 25 * scale),
            CGPoint(x: origin.x + 30 * scale, y: origin.y + 36 * scale)
        ]
        
        let boltRadius: CGFloat = 1.5 * scale
        
        for position in boltPositions {
            // Dark hole
            context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
            context.fillEllipse(in: CGRect(
                x: position.x - boltRadius,
                y: position.y - boltRadius,
                width: boltRadius * 2,
                height: boltRadius * 2
            ))
        }
    }
}