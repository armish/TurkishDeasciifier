#!/bin/bash

# Create macOS app bundle for Turkish Deasciifier
# This creates a proper .app structure that's easier to distribute

set -e

APP_NAME="TurkishDeasciifier"
BUNDLE_NAME="${APP_NAME}.app"

echo "📦 Creating macOS app bundle..."

# First build the universal binary
if [ ! -f "TurkishDeasciifier" ] || [ "$1" == "--rebuild" ]; then
    echo "🔨 Building universal binary first..."
    ./build_universal.sh
fi

# Remove old bundle if exists
rm -rf "$BUNDLE_NAME"

# Create app bundle structure
echo "📁 Creating bundle structure..."
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# Copy executable
cp TurkishDeasciifier "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"

# Copy pattern file to Resources (essential for deasciification to work)
echo "📄 Including pattern file..."
cp Sources/turkish_patterns.json "${BUNDLE_NAME}/Contents/Resources/"

# Create app icon if it doesn't exist
if [ ! -f "AppIcon.icns" ]; then
    echo "🎨 Creating app icon..."
    ./create_icon.sh
fi

# Copy app icon to Resources
if [ -f "AppIcon.icns" ]; then
    echo "🖼️  Including app icon..."
    cp AppIcon.icns "${BUNDLE_NAME}/Contents/Resources/"
fi

# Create Info.plist
cat > "${BUNDLE_NAME}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TurkishDeasciifier</string>
    <key>CFBundleIdentifier</key>
    <string>com.turkishdeasciifier.app</string>
    <key>CFBundleName</key>
    <string>Turkish Deasciifier</string>
    <key>CFBundleDisplayName</key>
    <string>Turkish Deasciifier</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
</dict>
</plist>
EOF

# Note: Icon creation skipped - add a real .icns file later if needed
# echo "🎨 Creating placeholder icon..."
# You can add a real icon by copying an .icns file to Resources/AppIcon.icns

# Sign the app bundle (sign the executable directly first)
echo "✍️ Signing app bundle..."
codesign --force --sign - "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"
codesign --force --sign - "${BUNDLE_NAME}"

# Verify the bundle
echo "✅ Verifying app bundle..."
codesign -dv "${BUNDLE_NAME}" 2>&1 | head -5

# Create a ZIP for distribution
echo "📦 Creating distribution ZIP..."
zip -r "${APP_NAME}.zip" "${BUNDLE_NAME}" -x "*.DS_Store"

echo ""
echo "🎉 App bundle created successfully!"
echo ""
echo "📱 ${BUNDLE_NAME} is ready for distribution"
echo "📦 ${APP_NAME}.zip created for easy sharing"
echo ""
echo "📝 Installation instructions for users:"
echo "   1. Download and unzip ${APP_NAME}.zip"
echo "   2. Drag ${BUNDLE_NAME} to Applications folder"
echo "   3. On first run: Right-click → Open (to bypass Gatekeeper)"
echo "   4. Grant accessibility permissions when prompted"
echo ""
echo "🔐 To remove quarantine after download:"
echo "   xattr -cr ${BUNDLE_NAME}"