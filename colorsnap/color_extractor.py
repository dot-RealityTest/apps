#!/usr/bin/env python3
"""
ColorSnap - Quick Color Extractor
Drop any image → get dominant colors as hex codes
"""

from PIL import Image
import sys
import json


def extract_dominant_colors(image_path, num_colors=6):
    """Extract dominant colors from an image."""
    try:
        img = Image.open(image_path)
        
        # Convert to RGB if necessary (handle RGBA, P, etc.)
        if img.mode in ('RGBA', 'LA', 'P'):
            # Create white background for transparent images
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Resize for speed
        img.thumbnail((200, 200))
        
        # Get colors
        colors = img.getcolors(200 * 200)
        if colors is None:
            return []
        
        # Sort by frequency
        sorted_colors = sorted(colors, reverse=True)
        
        # Extract top colors, skip near-duplicates
        result = []
        seen_colors = set()
        
        for count, color in sorted_colors:
            if len(result) >= num_colors:
                break
            
            r, g, b = color
            
            # Skip very dark or very light colors (often artifacts)
            brightness = (r + g + b) / 3
            if brightness < 10 or brightness > 245:
                continue
            
            # Skip near-duplicates
            color_key = (r // 20, g // 20, b // 20)
            if color_key in seen_colors:
                continue
            
            seen_colors.add(color_key)
            hex_code = f"#{r:02x}{g:02x}{b:02x}"
            result.append({
                'hex': hex_code,
                'rgb': (r, g, b),
                'frequency': count
            })
        
        return result
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return []


def main():
    if len(sys.argv) < 2:
        print("Usage: color_extractor.py <image_path> [num_colors]")
        sys.exit(1)
    
    image_path = sys.argv[1]
    num_colors = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    
    colors = extract_dominant_colors(image_path, num_colors)
    
    if colors:
        # Output as JSON for SwiftUI app to parse
        print(json.dumps(colors))
    else:
        print("[]")
        sys.exit(1)


if __name__ == "__main__":
    main()
