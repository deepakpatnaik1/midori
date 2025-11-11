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
DMG_DIR="./dmg-staging"
RELEASE_DIR="./release"
RELEASE_BUILD="./build/Build/Products/Release/${APP_NAME}.app"

# Clean up staging and release directories
echo "🧹 Cleaning staging directories..."
rm -rf "$DMG_DIR" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Check if Release build exists, otherwise build it
if [ ! -d "$RELEASE_BUILD" ]; then
    echo "⚠️  Release build not found at: $RELEASE_BUILD"
    echo "🔨 Building Release configuration..."
    xcodebuild clean -scheme Midori-Debug -configuration Release
    xcodebuild -scheme Midori-Debug -configuration Release -derivedDataPath ./build build

    if [ ! -d "$RELEASE_BUILD" ]; then
        echo "❌ Release build failed"
        exit 1
    fi
fi

echo "✅ Using Release build: $RELEASE_BUILD"
echo ""

# Use the Release build
BUILT_APP="$RELEASE_BUILD"

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

1. Drag "midori.app" to the "Applications" folder
2. Open Midori from Applications or Spotlight (⌘+Space → "Midori")
3. Grant permissions:
   • Microphone: Click "OK" when prompted
   • Accessibility: System Settings → Privacy & Security → Accessibility → Enable Midori

⚠️  FIRST LAUNCH (One-time setup):

• The app will download the AI model (~100MB) on first launch
• This happens automatically in the background
• Wait 1-2 minutes for download to complete
• Internet connection required for first launch only
• Model is cached locally for instant future use

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
✓ Ultra-sensitive to soft speaking voices

💡 TIPS:

• Look for the waveform icon in your menu bar
• To quit: Click menu bar icon → Quit
• To restart: Click menu bar icon → Restart
• Hold Right Command for 1+ second before speaking

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

# Clean up staging artifacts
rm -rf "$DMG_DIR"

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
