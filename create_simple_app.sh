#!/bin/bash

# Create a simple .app bundle without problematic codesigning

set -e

APP_NAME="TurkishDeasciifier"
BUNDLE_NAME="${APP_NAME}.app"

echo "📦 Creating simple .app bundle for distribution..."

# First build the universal binary if needed
if [ ! -f "TurkishDeasciifier" ] || [ "$1" == "--rebuild" ]; then
    echo "🔨 Building universal binary first..."
    ./build_universal.sh
fi

# Remove old bundle
rm -rf "$BUNDLE_NAME"

# Create app bundle structure
echo "📁 Creating bundle structure..."
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

# Copy executable
echo "📱 Copying executable..."
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
echo "📝 Creating Info.plist..."
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

# Make executable file executable
chmod +x "${BUNDLE_NAME}/Contents/MacOS/${APP_NAME}"

# Create a ZIP for distribution
echo "📦 Creating distribution ZIP..."
zip -r "${APP_NAME}.zip" "${BUNDLE_NAME}" -x "*.DS_Store"

# Verify the bundle contents
echo ""
echo "✅ App bundle created successfully!"
echo ""
echo "📁 Bundle structure:"
find "${BUNDLE_NAME}" -type f | head -10
echo ""
echo "📦 ${APP_NAME}.zip created for distribution"
echo ""
echo "🚀 Testing app launch (Cmd+C to quit)..."
echo "   If patterns load successfully, you should see debug output"
echo ""
echo "📝 Installation instructions for users:"
echo "   1. Download and unzip ${APP_NAME}.zip"
echo "   2. Right-click ${BUNDLE_NAME} → Open (bypass Gatekeeper)"
echo "   3. Grant accessibility permissions when prompted"
echo "   4. The pattern file should load automatically"
echo ""
echo "🔧 If users get 'damaged app' error:"
echo "   xattr -cr ${BUNDLE_NAME}"