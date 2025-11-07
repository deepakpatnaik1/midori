#!/bin/bash

# Build Release version of Midori and install to /Applications
# This creates a production-ready build optimized for distribution

set -e

echo "🔨 Building Midori (Release configuration)..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
xcodebuild clean -scheme Midori-Debug -configuration Release

# Build Release configuration
echo "📦 Building Release..."
xcodebuild \
    -scheme Midori-Debug \
    -configuration Release \
    -derivedDataPath ./build \
    build

# Find the built app
BUILT_APP="./build/Build/Products/Release/midori.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at $BUILT_APP"
    exit 1
fi

echo "✅ Build successful!"
echo ""
echo "📍 Built app location: $BUILT_APP"
echo ""

# Install to /Applications
echo "📲 Installing to /Applications..."

# Kill any running instance
killall -9 midori 2>/dev/null || true
sleep 1

# Remove old version from /Applications if it exists
if [ -d "/Applications/Midori.app" ]; then
    echo "🗑️  Removing old version from /Applications..."
    rm -rf "/Applications/Midori.app"
fi

# Copy new version to /Applications
echo "📋 Copying Midori.app to /Applications..."
cp -R "$BUILT_APP" "/Applications/Midori.app"

echo ""
echo "✅ Installation complete!"
echo ""
echo "🚀 To launch: open /Applications/Midori.app"
echo "🎯 Or use Spotlight: press Cmd+Space and type 'Midori'"
echo ""
echo "ℹ️  Midori will:"
echo "   • Auto-launch at login"
echo "   • Run in background (no Dock icon)"
echo "   • Show menu bar icon for control"
echo ""
