#!/bin/bash
# Build and run Midori

set -e

cd "$(dirname "$0")/.."

echo "🔨 Building Midori..."
xcodebuild -scheme Midori-Debug -configuration Debug build

# Find the DerivedData location
DERIVED_DATA=$(xcodebuild -scheme Midori-Debug -showBuildSettings 2>/dev/null | grep "^\s*BUILD_DIR" | awk '{print $3}')
APP_PATH="$DERIVED_DATA/Debug/midori.app"

# Create symlink for stable access
mkdir -p build
rm -f build/midori.app
ln -sf "$APP_PATH" build/midori.app

echo "🚀 Launching Midori..."
open "$APP_PATH"

echo "✅ Midori launched!"
echo "💡 Use 'Console.app' or Xcode console to view logs"
