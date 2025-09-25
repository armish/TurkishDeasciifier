#!/bin/bash

# Prepare Turkish Deasciifier for App Store submission
# This script helps set up the necessary structure for App Store submission

set -e

# Configuration
APP_NAME="TurkishDeasciifier"
BUNDLE_ID="com.turkishdeasciifier.app"
TEAM_ID="W97456DWR9"
VERSION="2.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 Preparing Turkish Deasciifier for App Store${NC}"
echo "=============================================="

# Function to create Info.plist for App Store
create_appstore_info_plist() {
    echo -e "${YELLOW}📝 Creating App Store Info.plist...${NC}"

    cat > "Info-AppStore.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Turkish Deasciifier</string>
    <key>CFBundleDisplayName</key>
    <string>Turkish Deasciifier</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Bulent Aksoy. All rights reserved.</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
</dict>
</plist>
EOF

    echo -e "${GREEN}✅ App Store Info.plist created${NC}"
}

# Function to create App Store entitlements
create_appstore_entitlements() {
    echo -e "${YELLOW}🔐 Creating App Store entitlements...${NC}"

    # The entitlements file already exists with proper App Store settings
    if [ ! -f "entitlements-appstore.plist" ]; then
        cat > "entitlements-appstore.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- App Sandbox - Required for Mac App Store -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Allow reading user-selected files (NOT executable) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>

    <!-- Allow printing -->
    <key>com.apple.security.print</key>
    <true/>

    <!-- Hardened Runtime -->
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
</dict>
</plist>
EOF
    fi

    echo -e "${GREEN}✅ App Store entitlements ready${NC}"
}

# Function to build App Store version
build_appstore_version() {
    echo -e "${YELLOW}🔨 Building App Store version...${NC}"

    # Clean previous builds
    rm -rf "${APP_NAME}-AppStore.app"

    # Build universal binary
    ./build_universal.sh

    # Create app bundle with App Store configuration
    ./create_simple_app.sh

    # Replace Info.plist with App Store version
    cp "Info-AppStore.plist" "${APP_NAME}.app/Contents/Info.plist"

    # Copy to App Store version
    cp -R "${APP_NAME}.app" "${APP_NAME}-AppStore.app"

    echo -e "${GREEN}✅ App Store version built${NC}"
}

# Function to sign for App Store
sign_for_appstore() {
    echo -e "${YELLOW}✍️  Signing for App Store...${NC}"

    local APP_BUNDLE="${APP_NAME}-AppStore.app"

    # Find App Store certificates
    echo -e "${YELLOW}🔍 Looking for App Store certificates...${NC}"

    # Check for 3rd Party Mac Developer certificates (for App Store)
    if security find-identity -v -p codesigning | grep -q "3rd Party Mac Developer Application"; then
        APP_STORE_SIGN="3rd Party Mac Developer Application: Bulent Aksoy (${TEAM_ID})"
        echo -e "${GREEN}✅ Found App Store signing certificate${NC}"
    elif security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
        APP_STORE_SIGN="Apple Distribution: Bulent Aksoy (${TEAM_ID})"
        echo -e "${GREEN}✅ Found Apple Distribution certificate${NC}"
    else
        echo -e "${RED}❌ No App Store signing certificate found${NC}"
        echo ""
        echo "You need to create certificates at:"
        echo "https://developer.apple.com/account/resources/certificates"
        echo ""
        echo "Required certificates for App Store:"
        echo "  • 3rd Party Mac Developer Application"
        echo "  • 3rd Party Mac Developer Installer"
        echo "     OR"
        echo "  • Apple Distribution"
        echo "  • Mac Installer Distribution"
        exit 1
    fi

    # Remove extended attributes
    xattr -cr "$APP_BUNDLE"

    # Sign the app
    codesign --force --deep --sign "$APP_STORE_SIGN" \
        --entitlements "entitlements-appstore.plist" \
        --options runtime \
        --timestamp \
        "$APP_BUNDLE"

    # Verify signature
    codesign -dv --verbose=4 "$APP_BUNDLE"

    echo -e "${GREEN}✅ App signed for App Store${NC}"
}

# Function to create installer package
create_installer_package() {
    echo -e "${YELLOW}📦 Creating installer package...${NC}"

    local APP_BUNDLE="${APP_NAME}-AppStore.app"
    local PKG_NAME="${APP_NAME}-AppStore.pkg"

    # Check for installer certificate (don't filter by codesigning)
    if security find-identity -v | grep -q "3rd Party Mac Developer Installer"; then
        INSTALLER_SIGN="3rd Party Mac Developer Installer: Bulent Aksoy (${TEAM_ID})"
        echo -e "${GREEN}✅ Found installer certificate${NC}"
    elif security find-identity -v | grep -q "Mac Installer Distribution"; then
        INSTALLER_SIGN="Mac Installer Distribution: Bulent Aksoy (${TEAM_ID})"
        echo -e "${GREEN}✅ Found installer certificate${NC}"
    else
        echo -e "${RED}❌ No installer certificate found${NC}"
        echo "Please create one at https://developer.apple.com/account/resources/certificates"
        exit 1
    fi

    # Build the installer package
    productbuild --component "$APP_BUNDLE" /Applications \
        --sign "$INSTALLER_SIGN" \
        --product "$APP_BUNDLE/Contents/Info.plist" \
        "$PKG_NAME"

    if [ -f "$PKG_NAME" ]; then
        echo -e "${GREEN}✅ Installer package created: $PKG_NAME${NC}"
    else
        echo -e "${RED}❌ Failed to create installer package${NC}"
        exit 1
    fi
}

# Function to validate with App Store
validate_package() {
    echo -e "${YELLOW}🔍 Validating package...${NC}"

    local PKG_NAME="${APP_NAME}-AppStore.pkg"

    # Try using xcrun altool (deprecated but might still work)
    echo "Attempting validation with altool..."
    echo "Note: You'll need to provide your Apple ID credentials"

    xcrun altool --validate-app \
        -f "$PKG_NAME" \
        -t macos \
        --username "arman@aksoy.org" \
        --password "@keychain:AC_PASSWORD" || {
        echo -e "${YELLOW}⚠️  altool validation failed or not available${NC}"
        echo "You can validate later during upload"
    }
}

# Function to show upload instructions
show_upload_instructions() {
    echo ""
    echo -e "${GREEN}📋 App Store Submission Instructions${NC}"
    echo "========================================"
    echo ""
    echo -e "${BLUE}Option 1: Using Transporter (Easiest)${NC}"
    echo "1. Download Transporter from Mac App Store:"
    echo "   https://apps.apple.com/app/transporter/id1450874784"
    echo "2. Open Transporter and sign in with your Apple ID"
    echo "3. Drag ${APP_NAME}-AppStore.pkg into Transporter"
    echo "4. Click 'Deliver' to upload to App Store Connect"
    echo ""
    echo -e "${BLUE}Option 2: Using xcrun altool${NC}"
    echo "Run this command:"
    echo "  xcrun altool --upload-app -f ${APP_NAME}-AppStore.pkg -t macos -u arman@aksoy.org"
    echo ""
    echo -e "${BLUE}Option 3: Create Xcode Project${NC}"
    echo "For full App Store integration, create an Xcode project:"
    echo "1. Open Xcode > Create New Project > macOS > App"
    echo "2. Set Product Name: ${APP_NAME}"
    echo "3. Set Bundle ID: ${BUNDLE_ID}"
    echo "4. Set Team: ${TEAM_ID}"
    echo "5. Add your Swift files to the project"
    echo "6. Use Product > Archive > Distribute App"
    echo ""
    echo -e "${GREEN}📱 App Store Connect Setup${NC}"
    echo "1. Go to https://appstoreconnect.apple.com"
    echo "2. Click 'My Apps' > '+' > 'New macOS App'"
    echo "3. Fill in app information:"
    echo "   • Name: Turkish Deasciifier"
    echo "   • Primary Language: English"
    echo "   • Bundle ID: ${BUNDLE_ID}"
    echo "   • SKU: ${APP_NAME}-001"
    echo ""
    echo -e "${YELLOW}📊 Required Assets:${NC}"
    echo "   • App Icon: 512x512px and 1024x1024px"
    echo "   • Screenshots: 1280x800, 1440x900, 2560x1600, 2880x1800"
    echo "   • Description (up to 4000 characters)"
    echo "   • Keywords (up to 100 characters)"
    echo "   • Support URL"
    echo "   • Marketing URL (optional)"
    echo "   • Privacy Policy URL"
    echo ""
    echo -e "${GREEN}✅ Your package is ready: ${APP_NAME}-AppStore.pkg${NC}"
}

# Main execution
main() {
    echo ""

    # Create App Store configuration files
    create_appstore_info_plist
    create_appstore_entitlements

    # Build App Store version
    echo ""
    read -p "Build App Store version? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_appstore_version
        sign_for_appstore
    fi

    # Create installer package
    echo ""
    read -p "Create installer package (.pkg)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_installer_package
    fi

    # Validate package
    echo ""
    read -p "Validate package with App Store? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        validate_package
    fi

    # Show upload instructions
    show_upload_instructions

    # Open Transporter if requested
    echo ""
    read -p "Open Transporter app? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "/Applications/Transporter.app" ]; then
            open -a Transporter "${APP_NAME}-AppStore.pkg"
        else
            echo "Opening Mac App Store to download Transporter..."
            open "macappstore://apps.apple.com/app/transporter/id1450874784"
        fi
    fi
}

# Run main function
main