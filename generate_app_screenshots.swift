#!/usr/bin/env swift

import UIKit
import CoreGraphics

class AppScreenshotGenerator {
    
    struct ScreenshotSize {
        let name: String
        let width: CGFloat
        let height: CGFloat
        let logoScale: CGFloat  // Percentage of width/height for logo
    }
    
    static let screenshotSizes = [
        // iPhone 6.7" Display
        ScreenshotSize(name: "iphone_67_portrait_1320x2868", width: 1320, height: 2868, logoScale: 0.5),
        ScreenshotSize(name: "iphone_67_portrait_1290x2796", width: 1290, height: 2796, logoScale: 0.5),
        ScreenshotSize(name: "iphone_67_landscape_2868x1320", width: 2868, height: 1320, logoScale: 0.35),
        ScreenshotSize(name: "iphone_67_landscape_2796x1290", width: 2796, height: 1290, logoScale: 0.35),
        
        // iPhone 6.5" Display  
        ScreenshotSize(name: "iphone_65_portrait_1242x2688", width: 1242, height: 2688, logoScale: 0.5),
        ScreenshotSize(name: "iphone_65_portrait_1284x2778", width: 1284, height: 2778, logoScale: 0.5),
        ScreenshotSize(name: "iphone_65_landscape_2688x1242", width: 2688, height: 1242, logoScale: 0.35),
        ScreenshotSize(name: "iphone_65_landscape_2778x1284", width: 2778, height: 1284, logoScale: 0.35)
    ]
    
    static func generateScreenshots() {
        // Load the logo
        guard let logoImage = loadLogoImage() else {
            print("Failed to load logo image")
            return
        }
        
        for size in screenshotSizes {
            print("Generating \(size.name)...")
            generateScreenshot(logoImage: logoImage, size: size)
        }
        
        print("✅ All screenshots generated in AppStoreScreenshots/")
    }
    
    static func loadLogoImage() -> UIImage? {
        // Try to load the logo from the file system
        let logoPath = "/Users/dakotabrown/LevelFitness-IOS/RunstrRewards/Assets.xcassets/RunstrRewardsLogoLarge.imageset/logo-large@3x.png"
        return UIImage(contentsOfFile: logoPath)
    }
    
    static func generateScreenshot(logoImage: UIImage, size: ScreenshotSize) {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width, height: size.height))
        
        let screenshot = renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill with black background
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            // Calculate logo size and position
            let isPortrait = size.height > size.width
            let logoMaxDimension: CGFloat
            
            if isPortrait {
                logoMaxDimension = size.width * size.logoScale
            } else {
                logoMaxDimension = size.height * size.logoScale
            }
            
            // Maintain aspect ratio of the logo
            let logoAspectRatio = logoImage.size.width / logoImage.size.height
            var logoWidth: CGFloat
            var logoHeight: CGFloat
            
            if logoAspectRatio > 1 {
                // Logo is wider than tall
                logoWidth = logoMaxDimension
                logoHeight = logoMaxDimension / logoAspectRatio
            } else {
                // Logo is taller than wide or square
                logoHeight = logoMaxDimension
                logoWidth = logoMaxDimension * logoAspectRatio
            }
            
            // Center the logo
            let logoX = (size.width - logoWidth) / 2
            let logoY = (size.height - logoHeight) / 2
            
            // Draw the logo
            logoImage.draw(in: CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight))
        }
        
        // Save the screenshot
        saveScreenshot(image: screenshot, fileName: size.name)
    }
    
    static func saveScreenshot(image: UIImage, fileName: String) {
        guard let data = image.pngData() else {
            print("Failed to get PNG data for \(fileName)")
            return
        }
        
        let outputPath = "/Users/dakotabrown/LevelFitness-IOS/AppStoreScreenshots/\(fileName).png"
        let url = URL(fileURLWithPath: outputPath)
        
        do {
            try data.write(to: url)
            print("  ✓ Saved: \(fileName).png")
        } catch {
            print("  ✗ Error saving \(fileName): \(error)")
        }
    }
}

// Generate all screenshots
AppScreenshotGenerator.generateScreenshots()