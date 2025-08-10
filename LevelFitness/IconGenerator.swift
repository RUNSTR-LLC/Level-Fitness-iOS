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
            
            // Background gradient (dark industrial theme)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0).cgColor, // Darker than card background
                UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0).cgColor  // Match app background
            ]
            
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size, y: size),
                options: []
            )
            
            // Add subtle grid pattern for industrial look
            addGridPattern(to: cgContext, size: size)
            
            // Calculate scaling for logo based on icon size
            let logoScale = size / 120.0 // Base scale for 120pt logo
            
            // Center the logo
            let logoSize: CGFloat = 80 * logoScale
            let logoOrigin = CGPoint(x: (size - logoSize) / 2, y: (size - logoSize) / 2)
            
            // Draw the main "L" logo
            drawIndustrialL(in: cgContext, origin: logoOrigin, scale: logoScale)
            
            // Add small decorative elements for larger icons
            if size >= 120 {
                addSmallGears(in: cgContext, origin: logoOrigin, logoSize: logoSize, scale: logoScale)
            }
            
            // Add bitcoin orange accent for larger icons
            if size >= 180 {
                addBitcoinAccent(in: cgContext, origin: logoOrigin, logoSize: logoSize, scale: logoScale)
            }
        }
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
        
        // Main L shape (matching LoginViewController design)
        path.move(to: CGPoint(x: origin.x + 25 * adjustedScale, y: origin.y + 15 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 35 * adjustedScale, y: origin.y + 15 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 35 * adjustedScale, y: origin.y + 75 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 85 * adjustedScale, y: origin.y + 75 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 85 * adjustedScale, y: origin.y + 85 * adjustedScale))
        path.addLine(to: CGPoint(x: origin.x + 25 * adjustedScale, y: origin.y + 85 * adjustedScale))
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
}