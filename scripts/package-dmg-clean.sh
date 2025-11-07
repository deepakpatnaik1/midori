#!/bin/bash

# Create DMG from the working DEBUG build
# This ensures we package exactly what's working in ~/.local/midori/

set -e

echo "📦 Creating Midori DMG from working debug build..."
echo ""

# Configuration
APP_NAME="Midori"
DMG_NAME="Midori-Installer"
DMG_DIR="./dmg-staging"
RELEASE_DIR="./release"
SOURCE_APP="$HOME/.local/midori/midori.app"

# Verify source exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "❌ Source app not found at $SOURCE_APP"
    echo "Run ./scripts/install-local.sh first"
    exit 1
fi

# Clean up
echo "🧹 Cleaning previous builds..."
rm -rf "$DMG_DIR" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Copy the WORKING debug build
echo "📋 Copying working app from ~/.local/midori/..."
cp -R "$SOURCE_APP" "$DMG_DIR/Midori.app"

# Create Applications symlink
ln -s /Applications "$DMG_DIR/Applications"

# Create install instructions
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

# Clean up staging
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
echo "This DMG contains the EXACT working build from:"
echo "  $SOURCE_APP"
echo ""
echo "Share via:"
echo "  • Email, AirDrop, or cloud storage"
echo ""
echo "🧪 To test:"
echo "  open $RELEASE_DIR/${DMG_NAME}.dmg"
echo ""
