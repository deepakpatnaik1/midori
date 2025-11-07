#!/bin/bash

# Simple DMG creator for Midori - Easy to share with friends and family
# Double-click the DMG, drag Midori to Applications, done!

set -e

cd "$(dirname "$0")/.."

echo "📦 Creating Midori installer DMG..."
echo ""

# Configuration
APP_NAME="Midori"
DMG_NAME="Midori-Installer"
BUILD_DIR="./build"
DMG_DIR="./dmg-staging"
RELEASE_DIR="./release"

# Clean up completely - including DerivedData cache
echo "🧹 Cleaning ALL build caches..."
rm -rf "$BUILD_DIR" "$DMG_DIR" "$RELEASE_DIR"
rm -rf ~/Library/Developer/Xcode/DerivedData/midori-*
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Build Debug configuration (optimizations break functionality)
echo "🔨 Building Midori (Debug) - Clean build in ./build only..."
xcodebuild \
    -scheme Midori-Debug \
    -configuration Debug \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | grep -E "(Build|error|warning|✓)" || true

# Find built app
BUILT_APP="$BUILD_DIR/Build/Products/Debug/${APP_NAME}.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found"
    exit 1
fi

echo "✅ Build complete!"
echo ""

# Stage DMG contents
echo "📋 Preparing DMG contents..."
cp -R "$BUILT_APP" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create helpful README
cat > "$DMG_DIR/INSTALL.txt" << 'EOF'
═══════════════════════════════════════════════
  Midori - Voice to Text for macOS
═══════════════════════════════════════════════

📥 INSTALLATION (3 steps):

1. Drag "Midori.app" to the "Applications" folder
2. Open Midori from Applications or Spotlight (⌘+Space → "Midori")
3. Grant permissions:
   • Microphone: Click "OK" when prompted
   • Accessibility: System Settings → Privacy & Security → Accessibility → Enable Midori

🎤 USAGE:

• Press and hold RIGHT COMMAND key to record
• Release to stop and transcribe
• Text automatically appears at your cursor
• Works in ANY app (Notes, Messages, browsers, etc.)

✨ FEATURES:

✓ Launches automatically at login
✓ Always ready in the background (no Dock icon)
✓ Menu bar icon to quit/restart
✓ Fast AI transcription (NVIDIA Parakeet V2)
✓ Beautiful waveform visualization while recording

💡 TIPS:

• Look for the waveform icon in your menu bar
• To quit: Click menu bar icon → Quit
• To restart: Click menu bar icon → Restart

Enjoy hands-free transcription! 🎉
EOF

# Create DMG
echo "💿 Creating DMG file..."
hdiutil create \
    -volname "Midori Installer" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$RELEASE_DIR/${DMG_NAME}.dmg"

# Get file size
DMG_SIZE=$(du -h "$RELEASE_DIR/${DMG_NAME}.dmg" | cut -f1)

# Clean up build artifacts
rm -rf "$DMG_DIR" "$BUILD_DIR"

echo ""
echo "════════════════════════════════════════════"
echo "✅ DMG created successfully!"
echo "════════════════════════════════════════════"
echo ""
echo "📍 File: $RELEASE_DIR/${DMG_NAME}.dmg"
echo "📦 Size: $DMG_SIZE"
echo ""
echo "🎁 READY TO SHARE!"
echo ""
echo "Share this DMG with:"
echo "  • Email attachment"
echo "  • AirDrop"
echo "  • Cloud storage (Dropbox, Google Drive, etc.)"
echo ""
echo "Recipients just need to:"
echo "  1. Double-click the DMG"
echo "  2. Drag Midori to Applications"
echo "  3. Open and grant permissions"
echo ""
echo "🧪 To test the installer yourself:"
echo "  open $RELEASE_DIR/${DMG_NAME}.dmg"
echo ""
