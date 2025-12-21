#!/bin/bash
# Build Midori and install to /Applications

set -e

cd "$(dirname "$0")/.."

# Build to temp location
TEMP_BUILD="$(mktemp -d)"
echo "🔨 Building Midori..."
xcodebuild -scheme Midori-Debug -configuration Debug \
    CONFIGURATION_BUILD_DIR="$TEMP_BUILD" \
    build 2>&1 | grep -E "^(Build|Compile|Link|Sign|error:|warning:.*error|✅|❌)" || true

# Check if build succeeded
if [ ! -d "$TEMP_BUILD/midori.app" ]; then
    echo "❌ Build failed"
    rm -rf "$TEMP_BUILD"
    exit 1
fi

# Kill running Midori if any
pkill -x midori 2>/dev/null || true

# Install to /Applications
echo "📦 Installing to /Applications..."
rm -rf /Applications/Midori.app
cp -R "$TEMP_BUILD/midori.app" /Applications/Midori.app

# Clean up temp build
rm -rf "$TEMP_BUILD"

echo "✅ Installed to /Applications/Midori.app"
echo ""
echo "To run: open /Applications/Midori.app"
