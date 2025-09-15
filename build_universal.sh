#!/bin/bash

# Turkish Deasciifier Universal Binary Build Script
# Creates a universal binary that runs on both Intel and Apple Silicon Macs

set -e

echo "🔨 Building Turkish Deasciifier Universal Binary..."

# Clean previous builds
rm -rf .build
rm -f TurkishDeasciifier
rm -f TurkishDeasciifier_x86_64
rm -f TurkishDeasciifier_arm64

# Set deployment target for broader compatibility (macOS 13+)
export MACOSX_DEPLOYMENT_TARGET=13.0

# Build for Intel (x86_64)
echo "📦 Building for Intel (x86_64)..."
swiftc -o TurkishDeasciifier_x86_64 \
    Sources/TurkishDeasciifierApp.swift \
    Sources/ContentView.swift \
    Sources/TurkishDeasciifier.swift \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -target x86_64-apple-macos13.0 \
    -O

# Build for Apple Silicon (arm64)
echo "📦 Building for Apple Silicon (arm64)..."
swiftc -o TurkishDeasciifier_arm64 \
    Sources/TurkishDeasciifierApp.swift \
    Sources/ContentView.swift \
    Sources/TurkishDeasciifier.swift \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -target arm64-apple-macos13.0 \
    -O

# Create universal binary
echo "🔗 Creating universal binary..."
lipo -create -output TurkishDeasciifier \
    TurkishDeasciifier_x86_64 \
    TurkishDeasciifier_arm64

# Clean up intermediate files
rm -f TurkishDeasciifier_x86_64
rm -f TurkishDeasciifier_arm64

# Ad-hoc sign the binary (allows running on other machines without full notarization)
echo "✍️ Code signing with ad-hoc signature..."
codesign --force --sign - TurkishDeasciifier

# Verify the universal binary
echo "✅ Verifying universal binary..."
file TurkishDeasciifier
lipo -info TurkishDeasciifier

# Check code signature
echo "🔐 Code signature info:"
codesign -dv TurkishDeasciifier 2>&1 | head -3

echo ""
echo "🎉 Universal binary created successfully!"
echo "📱 This binary will run on:"
echo "   • Intel Macs (x86_64)"
echo "   • Apple Silicon Macs (arm64)"
echo "   • macOS 13.0 (Ventura) and later"
echo ""
echo "🚀 Run with: ./TurkishDeasciifier"
echo ""
echo "📝 Note: For distribution to other users:"
echo "   1. They may need to right-click → Open on first run"
echo "   2. Or remove quarantine: xattr -cr TurkishDeasciifier"
echo "   3. For App Store distribution, full code signing with Developer ID is required"