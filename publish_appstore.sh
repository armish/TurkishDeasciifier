#!/bin/bash

# Publish Turkish Deasciifier to Mac App Store
# Requires: Xcode, valid App Store distribution certificates, and App Store Connect setup

set -e

# Configuration - UPDATE THESE WITH YOUR VALUES
APP_NAME="TurkishDeasciifier"
BUNDLE_ID="com.turkishdeasciifier.app"
TEAM_ID="W97456DWR9"
APP_STORE_CONNECT_API_KEY_ID="YOUR_API_KEY_ID"
APP_STORE_CONNECT_ISSUER_ID="YOUR_ISSUER_ID"

# Build configuration
SCHEME="${APP_NAME}"
WORKSPACE="${APP_NAME}.xcworkspace"  # or .xcodeproj
PROJECT="${APP_NAME}.xcodeproj"
CONFIGURATION="Release"
ARCHIVE_PATH="build/${APP_NAME}.xcarchive"
EXPORT_PATH="build/AppStore"
EXPORT_OPTIONS_PLIST="ExportOptions.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 Starting App Store submission process for Turkish Deasciifier${NC}"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}❌ Xcode is not installed. Please install Xcode from the Mac App Store${NC}"
        exit 1
    fi

    # Check for valid signing certificates
    echo -e "${YELLOW}🔐 Checking App Store certificates...${NC}"
    if ! security find-identity -v -p codesigning | grep -q "Apple Distribution"; then
        echo -e "${RED}❌ No Apple Distribution certificate found${NC}"
        echo "Please create one at https://developer.apple.com/account/resources/certificates"
        exit 1
    fi

    if ! security find-identity -v -p codesigning | grep -q "Mac Installer Distribution"; then
        echo -e "${YELLOW}⚠️  No Mac Installer Distribution certificate found (may be needed)${NC}"
    fi

    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

# Create Xcode project if it doesn't exist
setup_xcode_project() {
    if [ ! -d "$PROJECT" ] && [ ! -d "$WORKSPACE" ]; then
        echo -e "${YELLOW}📱 No Xcode project found. Creating one...${NC}"

        # Since this is a Swift app, we'll need to create an Xcode project
        # This is a manual step typically done in Xcode
        echo -e "${RED}❌ Xcode project not found!${NC}"
        echo ""
        echo "To submit to the App Store, you need an Xcode project. Please:"
        echo "1. Open Xcode"
        echo "2. Create a new macOS app project"
        echo "3. Set Bundle ID to: ${BUNDLE_ID}"
        echo "4. Add your existing Swift files to the project"
        echo "5. Configure app capabilities and entitlements"
        echo "6. Run this script again"
        exit 1
    fi
}

# Create Export Options plist for App Store
create_export_options() {
    echo -e "${YELLOW}📝 Creating Export Options plist...${NC}"

    cat > "$EXPORT_OPTIONS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict>
        <key>${BUNDLE_ID}</key>
        <string>Mac App Store Provisioning Profile</string>
    </dict>
</dict>
</plist>
EOF

    echo -e "${GREEN}✅ Export options created${NC}"
}

# Build and archive the app
build_archive() {
    echo -e "${YELLOW}🔨 Building and archiving app...${NC}"

    # Clean build folder
    rm -rf build
    mkdir -p build

    # Determine if we're using workspace or project
    if [ -d "$WORKSPACE" ]; then
        BUILD_TARGET="-workspace $WORKSPACE"
    else
        BUILD_TARGET="-project $PROJECT"
    fi

    # Build and archive
    xcodebuild archive \
        $BUILD_TARGET \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "$ARCHIVE_PATH" \
        -allowProvisioningUpdates \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_STYLE="Automatic"

    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo -e "${RED}❌ Archive failed!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Archive created successfully${NC}"
}

# Export archive for App Store
export_archive() {
    echo -e "${YELLOW}📦 Exporting archive for App Store...${NC}"

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        -allowProvisioningUpdates

    if [ ! -d "$EXPORT_PATH" ]; then
        echo -e "${RED}❌ Export failed!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Export completed successfully${NC}"
}

# Validate the app
validate_app() {
    echo -e "${YELLOW}🔍 Validating app with App Store...${NC}"

    xcrun altool --validate-app \
        -f "$EXPORT_PATH/${APP_NAME}.pkg" \
        -t macos \
        --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
        --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
        --verbose

    echo -e "${GREEN}✅ Validation passed${NC}"
}

# Upload to App Store Connect
upload_to_appstore() {
    echo -e "${YELLOW}📤 Uploading to App Store Connect...${NC}"

    # Check if we should use altool or notarytool
    if [[ "$APP_STORE_CONNECT_API_KEY_ID" == *"YOUR_API_KEY_ID"* ]]; then
        echo -e "${YELLOW}⚠️  App Store Connect API credentials not configured${NC}"
        echo ""
        echo "You have two options to upload:"
        echo ""
        echo -e "${BLUE}Option 1: Use Xcode (Recommended)${NC}"
        echo "1. Open Xcode"
        echo "2. Open Window > Organizer"
        echo "3. Select your archive"
        echo "4. Click 'Distribute App'"
        echo "5. Follow the upload wizard"
        echo ""
        echo -e "${BLUE}Option 2: Configure API Key${NC}"
        echo "1. Go to https://appstoreconnect.apple.com/access/api"
        echo "2. Create a new API key with 'App Manager' role"
        echo "3. Download the .p8 key file"
        echo "4. Update this script with your API Key ID and Issuer ID"
        echo "5. Place the .p8 file in ~/.appstoreconnect/private_keys/"
        echo ""
        read -p "Open Xcode Organizer now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            open "$ARCHIVE_PATH"
            echo -e "${GREEN}✅ Archive opened in Xcode. Use 'Distribute App' to upload.${NC}"
        fi
    else
        # Upload using API key
        xcrun altool --upload-app \
            -f "$EXPORT_PATH/${APP_NAME}.pkg" \
            -t macos \
            --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
            --apiIssuer "$APP_STORE_CONNECT_ISSUER_ID" \
            --verbose

        echo -e "${GREEN}✅ Upload completed successfully!${NC}"
    fi
}

# Alternative: Use Transporter app
use_transporter() {
    echo -e "${YELLOW}📱 Using Transporter app...${NC}"

    if [ ! -d "/Applications/Transporter.app" ]; then
        echo -e "${YELLOW}Transporter not installed. Download from Mac App Store.${NC}"
        open "macappstore://apps.apple.com/app/transporter/id1450874784"
        exit 1
    fi

    # Open Transporter with the package
    open -a Transporter "$EXPORT_PATH/${APP_NAME}.pkg"
    echo -e "${GREEN}✅ Transporter opened. Sign in and deliver your app.${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}🚀 Mac App Store Publishing Script${NC}"
    echo "========================================"

    # Check prerequisites
    check_prerequisites

    # Check for Xcode project
    setup_xcode_project

    # Create export options
    create_export_options

    # Build and archive
    echo ""
    read -p "Build and archive the app? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        build_archive
        export_archive
    fi

    # Validate
    echo ""
    read -p "Validate the app with App Store? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        validate_app
    fi

    # Upload
    echo ""
    echo -e "${YELLOW}Choose upload method:${NC}"
    echo "1) Xcode Organizer (recommended)"
    echo "2) Command line with API key"
    echo "3) Transporter app"
    read -p "Select option (1-3): " upload_choice

    case $upload_choice in
        1)
            open "$ARCHIVE_PATH"
            echo -e "${GREEN}✅ Archive opened in Xcode Organizer${NC}"
            echo "Click 'Distribute App' and follow the wizard"
            ;;
        2)
            upload_to_appstore
            ;;
        3)
            use_transporter
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    # Final instructions
    echo ""
    echo -e "${GREEN}📋 Next Steps in App Store Connect:${NC}"
    echo "1. Go to https://appstoreconnect.apple.com"
    echo "2. Select your app"
    echo "3. Complete app information:"
    echo "   • App description and keywords"
    echo "   • Screenshots for different screen sizes"
    echo "   • App category and age rating"
    echo "   • Pricing and availability"
    echo "4. Select the build you just uploaded"
    echo "5. Submit for review"
    echo ""
    echo -e "${YELLOW}📊 Required App Store Assets:${NC}"
    echo "   • App Icon: 1024x1024px"
    echo "   • Screenshots: At least one for each supported display size"
    echo "   • Description: Up to 4000 characters"
    echo "   • Keywords: Up to 100 characters"
    echo "   • Support URL and Privacy Policy URL"
    echo ""
    echo -e "${GREEN}🎉 Good luck with your App Store submission!${NC}"
}

# Run main function
main