#!/bin/bash

# Create iPad screenshots from iPhone screenshots
# Usage: Place your iPhone screenshots in the current directory and run this script

mkdir -p "iPad_Screenshots"

echo "Converting iPhone screenshots to iPad format (2048 × 2732px)..."

# Function to resize maintaining aspect ratio with black padding
convert_to_ipad() {
    local input="$1"
    local output="iPad_Screenshots/$(basename "$input" .png)_iPad.png"
    
    echo "Converting: $input"
    
    # Use sips to resize maintaining aspect ratio and add black padding
    sips --resampleHeightWidthMax 2048 "$input" --out "$output"
    sips --padToHeightWidth 2732 2048 --padColor 000000 "$output"
    
    echo "Created: $output"
}

# Process all PNG files in current directory
for file in *.png; do
    if [ -f "$file" ]; then
        convert_to_ipad "$file"
    fi
done

echo ""
echo "iPad screenshots created in iPad_Screenshots/ directory"
echo "These are sized for iPad 12.9\"/13\" displays (2048 × 2732px)"
echo ""
echo "Files created:"
ls -la iPad_Screenshots/