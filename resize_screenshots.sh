#!/bin/bash

# Script to resize iPhone screenshots to iPad dimensions
# Target: iPad 12.9"/13" display (2048 × 2732px portrait)

echo "Creating iPad-sized screenshots..."

# Create output directory
mkdir -p "/Users/dakotabrown/LevelFitness-IOS/iPad_Screenshots"

# Function to resize image maintaining aspect ratio with padding
resize_for_ipad() {
    local input_file="$1"
    local output_file="$2"
    
    echo "Processing: $input_file"
    
    # First, get the original dimensions
    width=$(sips --getProperty pixelWidth "$input_file" | tail -1 | awk '{print $2}')
    height=$(sips --getProperty pixelHeight "$input_file" | tail -1 | awk '{print $2}')
    
    echo "Original size: ${width}x${height}"
    
    # Calculate scaling to fit within iPad dimensions while maintaining aspect ratio
    # Target: 2048 × 2732 (portrait)
    target_width=2048
    target_height=2732
    
    # Calculate scale factors
    scale_w=$(echo "scale=6; $target_width / $width" | bc)
    scale_h=$(echo "scale=6; $target_height / $height" | bc)
    
    # Use the smaller scale to ensure it fits
    if (( $(echo "$scale_w < $scale_h" | bc -l) )); then
        scale=$scale_w
    else
        scale=$scale_h
    fi
    
    # Calculate new dimensions
    new_width=$(echo "$width * $scale" | bc | cut -d. -f1)
    new_height=$(echo "$height * $scale" | bc | cut -d. -f1)
    
    echo "Scaled size: ${new_width}x${new_height}"
    
    # Resize the image
    sips --resampleWidth $new_width --resampleHeight $new_height "$input_file" --out "$output_file"
    
    # Add padding to center the image in iPad dimensions
    sips --padToHeightWidth $target_height $target_width --padColor 000000 "$output_file"
    
    echo "Final iPad size: ${target_width}x${target_height}"
    echo "Saved to: $output_file"
    echo "---"
}

# You'll need to add your screenshot files here
# Example usage (uncomment and modify paths as needed):
# resize_for_ipad "/path/to/screenshot1.png" "/Users/dakotabrown/LevelFitness-IOS/iPad_Screenshots/login_screen.png"
# resize_for_ipad "/path/to/screenshot2.png" "/Users/dakotabrown/LevelFitness-IOS/iPad_Screenshots/main_dashboard.png" 
# resize_for_ipad "/path/to/screenshot3.png" "/Users/dakotabrown/LevelFitness-IOS/iPad_Screenshots/team_detail.png"

echo "Script ready. Add your screenshot file paths and run the resize_for_ipad function."
echo "iPad target dimensions: 2048 × 2732px (portrait)"
echo "Alternative: 2732 × 2048px (landscape)"