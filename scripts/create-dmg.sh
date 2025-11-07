#!/bin/bash

# Create distributable DMG for Midori
# Users can double-click the DMG, drag Midori to Applications, and start using it

set -e

echo "📦 Creating Midori.dmg installer..."
echo ""

# Configuration
APP_NAME="Midori"
DMG_NAME="Midori-Installer"
BUILD_DIR="./build"
DMG_DIR="./dmg-build"
RELEASE_DIR="./release"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DMG_DIR" "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build Release configuration
echo "🔨 Building Midori (Release)..."
xcodebuild \
    -scheme Midori-Debug \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build

# Find the built app
BUILT_APP="$BUILD_DIR/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at $BUILT_APP"
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Create DMG staging directory
echo "📁 Creating DMG staging directory..."
mkdir -p "$DMG_DIR"

# Copy app to staging
cp -R "$BUILT_APP" "$DMG_DIR/"

# Create Applications symlink for drag-and-drop
ln -s /Applications "$DMG_DIR/Applications"

# Create a README for the DMG
cat > "$DMG_DIR/README.txt" << 'EOF'
Midori - Voice to Text for macOS

INSTALLATION:
1. Drag Midori.app to the Applications folder
2. Open Midori from Applications or Spotlight (Cmd+Space, type "Midori")
3. Grant permissions when prompted:
   - Microphone: Click "OK" when asked
   - Accessibility: Go to System Settings → Privacy & Security → Accessibility
     and enable Midori

USAGE:
- Press and hold Right Command key to record
- Release to transcribe
- Text appears at your cursor automatically

FEATURES:
✓ Auto-launches at login
✓ Always running in background
✓ Menu bar icon for control
✓ Fast AI transcription (NVIDIA Parakeet V2)
✓ Works in any app

Enjoy!
EOF

echo "💿 Creating DMG..."

# Create temporary DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDRW \
    -fs HFS+ \
    "$RELEASE_DIR/temp.dmg"

# Mount the DMG
echo "🔧 Configuring DMG appearance..."
MOUNT_DIR="/Volumes/${APP_NAME}"
hdiutil attach "$RELEASE_DIR/temp.dmg" -mountpoint "$MOUNT_DIR"

# Wait for mount
sleep 2

# Set DMG window properties using AppleScript
osascript << EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 800, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"

        -- Position icons
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "README.txt" of container window to {300, 350}

        update without registering applications
        delay 2
    end tell
end tell
EOF

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to compressed, read-only DMG
echo "🗜️  Compressing DMG..."
hdiutil convert "$RELEASE_DIR/temp.dmg" \
    -format UDZO \
    -o "$RELEASE_DIR/${DMG_NAME}.dmg"

# Clean up
rm "$RELEASE_DIR/temp.dmg"
rm -rf "$DMG_DIR" "$BUILD_DIR"

echo ""
echo "✅ DMG created successfully!"
echo ""
echo "📍 Location: $RELEASE_DIR/${DMG_NAME}.dmg"
echo ""
echo "🎁 Ready to share!"
echo ""
echo "To test:"
echo "  1. Double-click $RELEASE_DIR/${DMG_NAME}.dmg"
echo "  2. Drag Midori to Applications"
echo "  3. Open Midori and grant permissions"
echo ""
