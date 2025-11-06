#!/bin/bash
# Install Midori to a stable local location to avoid permission resets

set -e

cd "$(dirname "$0")/.."

echo "🔨 Building Midori..."
xcodebuild -scheme Midori-Debug -configuration Debug build

# Find the built app
DERIVED_DATA=$(xcodebuild -scheme Midori-Debug -showBuildSettings 2>/dev/null | grep "^\s*BUILD_DIR" | awk '{print $3}')
BUILT_APP="$DERIVED_DATA/Debug/midori.app"

# Create stable installation directory
INSTALL_DIR="$HOME/.local/midori"
mkdir -p "$INSTALL_DIR"

# Copy app to stable location
echo "📦 Installing to stable location..."
rm -rf "$INSTALL_DIR/midori.app"
cp -R "$BUILT_APP" "$INSTALL_DIR/midori.app"

# Also create symlink in build/ for convenience
mkdir -p build
rm -f build/midori.app
ln -sf "$INSTALL_DIR/midori.app" build/midori.app

echo "✅ Installed!"
echo "📍 App location: $INSTALL_DIR/midori.app"
echo ""
echo "⚠️  IMPORTANT: Grant accessibility permission to:"
echo "   $INSTALL_DIR/midori.app"
echo ""
echo "To run: open $INSTALL_DIR/midori.app"
