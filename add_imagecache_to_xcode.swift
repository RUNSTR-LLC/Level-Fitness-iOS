#!/usr/bin/swift

// This script will help you add ImageCacheService.swift to your Xcode project

import Foundation

print("""
==============================================
ADD ImageCacheService.swift TO XCODE PROJECT
==============================================

Please follow these steps in Xcode:

1. Open your RunstrRewards.xcodeproj in Xcode

2. In the Project Navigator (left sidebar):
   - Find any existing Swift file in the Services folder
   - For example: SupabaseService.swift or AuthenticationService.swift
   
3. Right-click on that file and select "Show in Finder"
   - This will open the Services folder in Finder

4. You'll see ImageCacheService.swift in that folder

5. Drag ImageCacheService.swift from Finder into Xcode:
   - Drag it to the Services group in the Project Navigator
   - When the dialog appears:
     ✓ Make sure "Copy items if needed" is UNCHECKED
     ✓ Make sure "RunstrRewards" target is CHECKED
     ✓ Click "Finish"

6. Clean and Build:
   - Press Shift+Cmd+K (Clean Build Folder)
   - Press Cmd+B (Build)

That's it! The file will be properly added to your project.

==============================================
File location: /Users/dakotabrown/LevelFitness-IOS/RunstrRewards/Services/ImageCacheService.swift
==============================================
""")