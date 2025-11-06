#!/bin/bash
# Reset macOS permissions for Midori app

echo "🧹 Cleaning up permissions and rebuilding..."

# Kill existing app instances
killall midori 2>/dev/null || true

# Clear the app from accessibility and microphone databases
tccutil reset Accessibility com.deepakpatnaik.midori 2>/dev/null || true
tccutil reset Microphone com.deepakpatnaik.midori 2>/dev/null || true

# Clean build
cd "$(dirname "$0")/.."
xcodebuild -scheme Midori-Debug -configuration Debug clean build

echo "✅ Clean build complete"
echo "📋 Now grant permissions in System Settings"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
