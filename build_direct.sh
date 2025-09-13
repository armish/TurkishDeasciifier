#!/bin/bash

# Direct build script that bypasses Swift Package Manager
# Workaround for xcrun SDK issues

echo "🔨 Building Turkish Deasciifier (Direct Method)..."

# Build with swiftc directly
cd Sources
swiftc -o ../TurkishDeasciifier \
    TurkishDeasciifierApp.swift \
    ContentView.swift \
    TurkishDeasciifier.swift \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -O

cd ..

if [ -f "TurkishDeasciifier" ]; then
    echo "✅ Build successful!"
    echo "📱 Run with: ./TurkishDeasciifier"
    echo "📊 Test accuracy with: swift debug_accuracy.swift"
else
    echo "❌ Build failed!"
    exit 1
fi