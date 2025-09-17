#!/bin/bash

# Build and sign Turkish Deasciifier for official distribution
# Requires valid Apple Developer ID certificate

set -e

# Configuration - UPDATE THESE WITH YOUR VALUES
# Find your identity with: security find-identity -v -p codesigning
DEVELOPER_ID="Developer ID Application: YOUR_NAME (TEAM_ID)"
APP_NAME="TurkishDeasciifier"
APP_BUNDLE="${APP_NAME}.app"
ENTITLEMENTS="entitlements.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔐 Building Turkish Deasciifier with Developer ID signing...${NC}"

# Check if Developer ID is configured
if [[ "$DEVELOPER_ID" == *"YOUR_NAME"* ]]; then
    echo -e "${RED}❌ Error: Please update DEVELOPER_ID in this script with your certificate name${NC}"
    echo "Run this command to find your certificate:"
    echo "  security find-identity -v -p codesigning | grep 'Developer ID'"
    exit 1
fi

# Check if certificate exists
if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID"; then
    echo -e "${RED}❌ Error: Developer ID certificate not found: $DEVELOPER_ID${NC}"
    echo "Available certificates:"
    security find-identity -v -p codesigning
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf "$APP_BUNDLE"
rm -f "${APP_NAME}.zip"
rm -f "${APP_NAME}-Signed.zip"

# Build universal binary
echo -e "${YELLOW}🔨 Building universal binary...${NC}"
./build_universal.sh

# Create app bundle
echo -e "${YELLOW}📦 Creating app bundle...${NC}"
./create_simple_app.sh

# Remove quarantine attributes (just in case)
xattr -cr "$APP_BUNDLE"

# Sign all frameworks and libraries first (if any)
echo -e "${YELLOW}✍️  Signing frameworks and libraries...${NC}"
find "$APP_BUNDLE" -type f -name "*.dylib" -o -name "*.framework" | while read -r lib; do
    codesign --force --sign "$DEVELOPER_ID" \
        --options runtime \
        --timestamp \
        "$lib" 2>/dev/null || true
done

# Sign the main executable
echo -e "${YELLOW}✍️  Signing main executable...${NC}"
codesign --force --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS" \
    "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Sign the entire app bundle
echo -e "${YELLOW}✍️  Signing app bundle...${NC}"
codesign --force --deep --sign "$DEVELOPER_ID" \
    --options runtime \
    --timestamp \
    --entitlements "$ENTITLEMENTS" \
    "$APP_BUNDLE"

# Verify signature
echo -e "${YELLOW}🔍 Verifying signature...${NC}"
codesign -dv --verbose=4 "$APP_BUNDLE" 2>&1

# Verify with spctl
echo -e "${YELLOW}🔍 Verifying with Gatekeeper...${NC}"
if spctl -a -t exec -vv "$APP_BUNDLE" 2>&1 | grep -q "accepted"; then
    echo -e "${GREEN}✅ Signature verification passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Gatekeeper verification pending (will pass after notarization)${NC}"
fi

# Create ZIP for distribution
echo -e "${YELLOW}📦 Creating signed ZIP archive...${NC}"
ditto -c -k --keepParent "$APP_BUNDLE" "${APP_NAME}-Signed.zip"

echo -e "${GREEN}✅ Signed app bundle created successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Next Steps:${NC}"
echo "1. Run ./notarize.sh to submit for Apple notarization"
echo "2. After notarization, distribute ${APP_NAME}-Notarized.zip"
echo ""
echo -e "${YELLOW}📊 Build Summary:${NC}"
echo "  • App Bundle: $APP_BUNDLE"
echo "  • Signed ZIP: ${APP_NAME}-Signed.zip"
echo "  • Certificate: $DEVELOPER_ID"
echo "  • Entitlements: $ENTITLEMENTS"
echo ""
echo -e "${GREEN}🎉 Ready for notarization!${NC}"