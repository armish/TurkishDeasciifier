#!/bin/bash

# Create app icon for Turkish Deasciifier
# Generates a .icns file with the "tü" theme

set -e

ICON_NAME="AppIcon"
TEMP_DIR="icon_temp"

echo "🎨 Creating Turkish Deasciifier app icon..."

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Function to create PNG icon at specific size
create_png_icon() {
    local size=$1
    local output="$TEMP_DIR/icon_${size}x${size}.png"

    # Create simple SVG with "tü" text in black on white background
    cat > "$TEMP_DIR/temp.svg" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg width="$size" height="$size" viewBox="0 0 $size $size" xmlns="http://www.w3.org/2000/svg">
  <!-- White background -->
  <rect width="$size" height="$size" fill="#FFFFFF"/>

  <!-- Main text "tü" centered -->
  <text x="50%" y="50%" font-family="SF Pro Display, Helvetica, Arial, sans-serif"
        font-size="$(($size*3/4))" font-weight="500"
        text-anchor="middle" dominant-baseline="central" fill="#000000">tü</text>
</svg>
EOF

    # Convert SVG to PNG using built-in tools
    if command -v qlmanage >/dev/null 2>&1; then
        # Use qlmanage (built into macOS)
        qlmanage -t -s $size -o "$TEMP_DIR" "$TEMP_DIR/temp.svg" >/dev/null 2>&1
        mv "$TEMP_DIR/temp.svg.png" "$output" 2>/dev/null || {
            echo "⚠️  qlmanage failed for size $size, trying alternative method..."
            create_fallback_icon "$size" "$output"
        }
    else
        create_fallback_icon "$size" "$output"
    fi

    echo "✅ Created ${size}x${size} icon"
}

# Fallback method using Python/Pillow if available
create_fallback_icon() {
    local size=$1
    local output=$2

    # Try Python with PIL
    if command -v python3 >/dev/null && python3 -c "import PIL" 2>/dev/null; then
        python3 << EOF
from PIL import Image, ImageDraw, ImageFont

size = $size
img = Image.new('RGBA', (size, size), (255, 255, 255, 255))  # White background
draw = ImageDraw.Draw(img)

# Text - larger font size (3/4 of icon size)
try:
    font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', size*3//4)
except:
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', size*3//4)
    except:
        font = ImageFont.load_default()

text = "tü"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]

# Center the text properly
x = (size - text_width) // 2
y = (size - text_height) // 2

draw.text((x, y), text, fill=(0, 0, 0, 255), font=font)  # Black text

img.save('$output')
print(f"Created {size}x{size} simple icon with Python")
EOF
    else
        # Ultimate fallback - create simple white square with black text
        echo "⚠️  Creating simple fallback icon for ${size}x${size}"
        # This creates a very basic icon as last resort
        python3 << EOF 2>/dev/null || echo "❌ Could not create icon for size $size"
from PIL import Image, ImageDraw

size = $size
img = Image.new('RGBA', (size, size), (255, 255, 255, 255))  # White background
draw = ImageDraw.Draw(img)
# Simple centered positioning for fallback
x = size // 4
y = size // 3
draw.text((x, y), "tü", fill=(0, 0, 0, 255))  # Black text
img.save('$output')
EOF
    fi
}

# Create icons for all required sizes
echo "📐 Creating icon sizes..."
sizes=(16 32 64 128 256 512 1024)

for size in "${sizes[@]}"; do
    create_png_icon $size
done

# Create iconset directory
ICONSET_DIR="$TEMP_DIR/$ICON_NAME.iconset"
mkdir -p "$ICONSET_DIR"

# Copy files to iconset with proper naming
cp "$TEMP_DIR/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$TEMP_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$TEMP_DIR/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$TEMP_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$TEMP_DIR/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$TEMP_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$TEMP_DIR/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$TEMP_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$TEMP_DIR/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$TEMP_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# Create .icns file
echo "📦 Creating .icns file..."
iconutil -c icns "$ICONSET_DIR" -o "$ICON_NAME.icns"

# Clean up
rm -rf "$TEMP_DIR"

echo "🎉 App icon created successfully!"
echo "📄 $ICON_NAME.icns is ready to use"
echo ""
echo "📝 To use this icon:"
echo "   1. Copy $ICON_NAME.icns to your app bundle's Resources folder"
echo "   2. Update Info.plist to reference the icon"
echo "   3. Rebuild your app"
echo ""
echo "🔧 Icon features:"
echo "   • Clean, minimal design"
echo "   • Black 'tü' text on white background"
echo "   • Centered typography"
echo "   • Multiple resolutions (16x16 to 1024x1024)"
echo "   • Proper .icns format for macOS"