#!/bin/bash

# Notarize Turkish Deasciifier with Apple
# Requires: xcrun notarytool (Xcode 13+) and valid Developer ID

set -e

# Configuration - UPDATE THESE WITH YOUR VALUES
APP_NAME="TurkishDeasciifier"
APP_BUNDLE="${APP_NAME}.app"
BUNDLE_ID="com.turkishdeasciifier.app"

# Notarization credentials - UPDATE THESE
KEYCHAIN_PROFILE="turkish-deasciifier"  # Name for stored credentials
APPLE_ID="arman@aksoy.org"
TEAM_ID="W97456DWR9"

# File names
SIGNED_ZIP="${APP_NAME}-Signed.zip"
NOTARIZED_ZIP="${APP_NAME}-Notarized.zip"
NOTARIZED_DMG="${APP_NAME}.dmg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting notarization process for Turkish Deasciifier${NC}"

# Check if signed app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "${RED}❌ Error: $APP_BUNDLE not found. Run ./build_signed.sh first${NC}"
    exit 1
fi

if [ ! -f "$SIGNED_ZIP" ]; then
    echo -e "${YELLOW}📦 Creating ZIP for notarization...${NC}"
    ditto -c -k --keepParent "$APP_BUNDLE" "$SIGNED_ZIP"
fi

# Check if credentials are stored
if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" 2>/dev/null; then
    echo -e "${YELLOW}🔑 Keychain profile not found. Setting up credentials...${NC}"
    echo ""
    echo "You need to create an app-specific password:"
    echo "1. Go to https://appleid.apple.com/account/manage"
    echo "2. Sign in with your Apple ID"
    echo "3. In Security section, click 'Generate Password' under App-Specific Passwords"
    echo "4. Name it 'Turkish Deasciifier Notarization'"
    echo "5. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)"
    echo ""

    if [[ "$APPLE_ID" == *"your-apple-id"* ]]; then
        read -p "Enter your Apple ID email: " APPLE_ID
    fi

    if [[ "$TEAM_ID" == *"YOUR_TEAM_ID"* ]]; then
        echo "Find your Team ID at: https://developer.apple.com/account"
        read -p "Enter your Team ID: " TEAM_ID
    fi

    echo -e "${YELLOW}Storing credentials in keychain...${NC}"
    xcrun notarytool store-credentials "$KEYCHAIN_PROFILE" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID"

    echo -e "${GREEN}✅ Credentials stored successfully${NC}"
fi

# Submit for notarization
echo -e "${YELLOW}📤 Submitting $SIGNED_ZIP for notarization...${NC}"
echo "This may take 5-60 minutes. Please wait..."

SUBMISSION_OUTPUT=$(xcrun notarytool submit "$SIGNED_ZIP" \
    --keychain-profile "$KEYCHAIN_PROFILE" \
    --wait 2>&1)

echo "$SUBMISSION_OUTPUT"

# Check if notarization succeeded
if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
    echo -e "${GREEN}✅ Notarization successful!${NC}"

    # Extract submission ID for reference
    SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
    echo -e "${BLUE}Submission ID: $SUBMISSION_ID${NC}"

elif echo "$SUBMISSION_OUTPUT" | grep -q "status: Invalid"; then
    echo -e "${RED}❌ Notarization failed!${NC}"

    # Get the log for debugging
    SUBMISSION_ID=$(echo "$SUBMISSION_OUTPUT" | grep "id:" | head -1 | awk '{print $2}')
    echo -e "${YELLOW}Fetching detailed log...${NC}"
    xcrun notarytool log "$SUBMISSION_ID" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        developer_log.json

    echo -e "${RED}Check developer_log.json for details${NC}"
    exit 1
else
    echo -e "${RED}❌ Unexpected notarization status${NC}"
    exit 1
fi

# Staple the notarization ticket to the app
echo -e "${YELLOW}📎 Stapling notarization ticket to app...${NC}"
xcrun stapler staple "$APP_BUNDLE"

# Verify stapling
echo -e "${YELLOW}🔍 Verifying notarization...${NC}"
xcrun stapler validate "$APP_BUNDLE"
spctl -a -t exec -vv "$APP_BUNDLE"

# Create final distribution archive
echo -e "${YELLOW}📦 Creating final distribution archives...${NC}"

# Create notarized ZIP
ditto -c -k --keepParent "$APP_BUNDLE" "$NOTARIZED_ZIP"

# Optionally create DMG for more professional distribution
create_dmg() {
    echo -e "${YELLOW}💿 Creating DMG installer...${NC}"

    # Create temporary directory
    TEMP_DIR="dmg_temp"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"

    # Copy app to temp directory
    cp -R "$APP_BUNDLE" "$TEMP_DIR/"

    # Create symlink to Applications
    ln -s /Applications "$TEMP_DIR/Applications"

    # Create DMG
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$TEMP_DIR" \
        -ov -format UDZO \
        "$NOTARIZED_DMG"

    # Clean up
    rm -rf "$TEMP_DIR"

    # Sign the DMG
    codesign --sign "Developer ID Application: Bulent Aksoy (W97456DWR9)" \
        --timestamp \
        "$NOTARIZED_DMG"

    # Notarize the DMG (optional but recommended)
    # xcrun notarytool submit "$NOTARIZED_DMG" \
    #     --keychain-profile "$KEYCHAIN_PROFILE" \
    #     --wait

    # xcrun stapler staple "$NOTARIZED_DMG"

    echo -e "${GREEN}✅ DMG created: $NOTARIZED_DMG${NC}"
}

# Ask if user wants to create DMG
read -p "Create DMG installer? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    create_dmg
fi

# Final summary
echo ""
echo -e "${GREEN}🎉 Notarization complete!${NC}"
echo ""
echo -e "${GREEN}📋 Distribution Files Created:${NC}"
echo "  • ZIP: $NOTARIZED_ZIP (recommended for website downloads)"
if [ -f "$NOTARIZED_DMG" ]; then
    echo "  • DMG: $NOTARIZED_DMG (professional installer)"
fi
echo ""
echo -e "${GREEN}✅ These files can be distributed without any Gatekeeper warnings!${NC}"
echo ""
echo -e "${YELLOW}📊 Verification Commands:${NC}"
echo "  spctl -a -t exec -vv $APP_BUNDLE"
echo "  codesign -dv --verbose=4 $APP_BUNDLE"
echo "  xcrun stapler validate $APP_BUNDLE"
echo ""
echo -e "${GREEN}🚀 Your app is ready for distribution!${NC}"

# Clean up temporary files
rm -f "$SIGNED_ZIP"