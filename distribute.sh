#!/bin/bash

# Distribution script for Turkish Deasciifier
# Creates a universal binary that works on macOS 13+ and handles Gatekeeper

set -e

echo "📦 Creating distribution package for Turkish Deasciifier..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist
mkdir -p dist

# Build universal binary if needed
if [ ! -f "TurkishDeasciifier" ] || [ "$1" == "--rebuild" ]; then
    echo "🔨 Building universal binary..."
    ./build_universal.sh
fi

# Copy binary and pattern file to dist
cp TurkishDeasciifier dist/
echo "📄 Including pattern file for deasciification..."
cp Sources/turkish_patterns.json dist/

# Create a README for distribution
cat > dist/README.txt << 'EOF'
Turkish Deasciifier - Installation Instructions
================================================

This app converts ASCII Turkish text to proper Turkish characters.
Global hotkey: ⌥⌘T (Option+Command+T)

INSTALLATION:
-------------
1. Copy 'TurkishDeasciifier' to your Applications folder
2. IMPORTANT: Remove quarantine attribute (required for downloaded files):
   Open Terminal and run:
   xattr -cr /Applications/TurkishDeasciifier

3. First run:
   - Right-click on TurkishDeasciifier
   - Select "Open" from the menu
   - Click "Open" in the security dialog

4. Grant accessibility permissions when prompted
   (Required for global hotkey functionality)

TROUBLESHOOTING:
----------------
If the app doesn't run on macOS 15:
1. Make sure you've removed quarantine (step 2 above)
2. Check System Settings > Privacy & Security > Accessibility
3. Ensure TurkishDeasciifier is listed and enabled

If you get "damaged app" error:
Run in Terminal: xattr -cr /Applications/TurkishDeasciifier

SYSTEM REQUIREMENTS:
--------------------
- macOS 13.0 (Ventura) or later
- Works on both Intel and Apple Silicon Macs

USAGE:
------
- Click the "tü" icon in menu bar
- Select text anywhere and press ⌥⌘T to convert
- Type directly in the app window

For support, visit: https://github.com/armish/TurkishDeasciifier
EOF

# Create installation script
cat > dist/install.sh << 'EOF'
#!/bin/bash

echo "Installing Turkish Deasciifier..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
   echo "Please don't run this script as root/sudo"
   exit 1
fi

# Copy to Applications
if [ -f "TurkishDeasciifier" ] && [ -f "turkish_patterns.json" ]; then
    echo "📦 Copying to Applications folder..."
    cp TurkishDeasciifier /Applications/
    cp turkish_patterns.json /Applications/

    echo "🔓 Removing quarantine attribute..."
    xattr -cr /Applications/TurkishDeasciifier
    xattr -cr /Applications/turkish_patterns.json

    echo "✅ Installation complete!"
    echo ""
    echo "To run the app:"
    echo "1. Go to Applications folder"
    echo "2. Right-click TurkishDeasciifier → Open"
    echo "3. Grant accessibility permissions when prompted"
    echo ""
    echo "Global hotkey: ⌥⌘T (Option+Command+T)"
else
    echo "❌ Error: Required files not found"
    echo "Missing: TurkishDeasciifier binary or turkish_patterns.json"
    echo "Please run this script from the distribution folder"
    exit 1
fi
EOF

chmod +x dist/install.sh

# Create a ZIP archive
echo "📦 Creating distribution archive..."
cd dist
zip -r ../TurkishDeasciifier-Universal.zip . -x "*.DS_Store"
cd ..

# Final instructions
echo ""
echo "✅ Distribution package created successfully!"
echo ""
echo "📦 Files created:"
echo "   • TurkishDeasciifier-Universal.zip - Ready for distribution"
echo "   • dist/ folder contains individual files"
echo ""
echo "📝 The package includes:"
echo "   • Universal binary (Intel + Apple Silicon)"
echo "   • Installation instructions (README.txt)"
echo "   • Automated installation script"
echo ""
echo "🚀 To distribute:"
echo "   1. Share TurkishDeasciifier-Universal.zip"
echo "   2. Users unzip and run: ./install.sh"
echo "   3. Or manually follow README.txt instructions"
echo ""
echo "⚠️  Important for users:"
echo "   • Must remove quarantine: xattr -cr /Applications/TurkishDeasciifier"
echo "   • Right-click → Open on first run"
echo "   • Grant accessibility permissions"