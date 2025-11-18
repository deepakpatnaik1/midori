#!/bin/bash
# Build script for Midori (Debug configuration only)

set -e

cd "$(dirname "$0")/.."

# Fixed build location for permission persistence
BUILD_DIR="$(pwd)/build"
mkdir -p "$BUILD_DIR"

echo "🔨 Building Midori in Debug configuration..."
xcodebuild -scheme Midori-Debug -configuration Debug \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    build

echo "✅ Build complete!"
echo "📍 Binary location: $BUILD_DIR/midori.app"
