#!/bin/bash
# Build and run Midori

set -e

cd "$(dirname "$0")/.."

# Fixed build location for permission persistence
BUILD_DIR="$(pwd)/build"
APP_PATH="$BUILD_DIR/midori.app"

echo "🔨 Building Midori..."
./scripts/build.sh

echo "🚀 Launching Midori..."
open "$APP_PATH"

echo "✅ Midori launched!"
echo "💡 Use 'Console.app' or Xcode console to view logs"
