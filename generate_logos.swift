#!/usr/bin/env swift

import UIKit
import CoreGraphics

// Copy the relevant code from IconGenerator
class LogoGenerator {
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
            saveImageToCurrentDirectory(image: image, fileName: "\(name).png")
        }
        
        print("Logo assets generated!")
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
            
            // Draw the main "L" logo with white fill
            drawLogoL(in: cgContext, origin: logoOrigin, scale: logoScale)
            
            // Add small decorative elements for larger logos
            if size >= 96 {
                addSmallGears(in: cgContext, origin: logoOrigin, logoSize: logoSize, scale: logoScale)
            }
            
            // Add bitcoin orange accent for larger logos
            if size >= 128 {
                addBitcoinAccent(in: cgContext, origin: logoOrigin, logoSize: logoSize, scale: logoScale)
            }
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
        
        // Main L shape - optimized for smaller sizes
        path.move(to: CGPoint(x: origin.x + 10 * scale, y: origin.y + 8 * scale))
        path.addLine(to: CGPoint(x: origin.x + 18 * scale, y: origin.y + 8 * scale))
        path.addLine(to: CGPoint(x: origin.x + 18 * scale, y: origin.y + 32 * scale))
        path.addLine(to: CGPoint(x: origin.x + 38 * scale, y: origin.y + 32 * scale))
        path.addLine(to: CGPoint(x: origin.x + 38 * scale, y: origin.y + 40 * scale))
        path.addLine(to: CGPoint(x: origin.x + 10 * scale, y: origin.y + 40 * scale))
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
        
        let bitcoinColor = UIColor(red: 0.97, green: 0.58, blue: 0.10, alpha: 1.0) // Bitcoin orange
        
        context.setFillColor(bitcoinColor.cgColor)
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
            color: bitcoinColor.withAlphaComponent(0.6).cgColor
        )
        context.fillEllipse(in: CGRect(
            x: accentPosition.x - accentSize/2,
            y: accentPosition.y - accentSize/2,
            width: accentSize,
            height: accentSize
        ))
    }
    
    static func saveImageToCurrentDirectory(image: UIImage, fileName: String) {
        guard let data = image.pngData() else { 
            print("Failed to get PNG data for \(fileName)")
            return 
        }
        
        let url = URL(fileURLWithPath: fileName)
        
        do {
            try data.write(to: url)
            print("Saved: \(fileName)")
        } catch {
            print("Error saving \(fileName): \(error)")
        }
    }
}

// Generate the logos
LogoGenerator.generateLogoAssets()