#!/bin/bash

# One-click script to create distributable Midori DMG
# Creates a Release build and packages it into a DMG installer

set -e

cd "$(dirname "$0")/.."

echo "🚀 Creating distributable Midori DMG..."
echo ""

# Configuration
APP_NAME="Midori"
DMG_NAME="Midori-Installer"
DMG_DIR="./dmg-staging"
RELEASE_DIR="./release"
BUILD_DIR="./build-release"

# Step 1: Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$DMG_DIR" "$RELEASE_DIR" "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"

# Step 2: Build Release configuration
echo ""
echo "🔨 Building Midori (Release configuration)..."
echo "   • Using Developer ID Application certificate"
echo "   • Hardened Runtime enabled"
echo "   • Secure timestamp enabled"
echo ""
xcodebuild \
    -scheme Midori-Debug \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=NG9X4L83KH \
    PROVISIONING_PROFILE_SPECIFIER="" \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    build

# Find the built app
BUILT_APP="$BUILD_DIR/Build/Products/Release/midori.app"

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Build failed - app not found at $BUILT_APP"
    exit 1
fi

echo "✅ Build successful!"

# Step 3: Copy app to DMG staging area
echo ""
echo "📋 Preparing DMG contents..."
cp -R "$BUILT_APP" "$DMG_DIR/Midori.app"

# Create Applications symlink for drag-to-install
ln -s /Applications "$DMG_DIR/Applications"

# Step 4: Notarize the app bundle first
echo ""
echo "📝 Notarizing app with Apple..."
echo "   (This uploads to Apple for automated security scanning)"
echo ""

# Create a zip for notarization (required format)
NOTARIZE_ZIP="$RELEASE_DIR/Midori-notarize.zip"
ditto -c -k --keepParent "$BUILT_APP" "$NOTARIZE_ZIP"

# Submit for notarization
echo "⬆️  Uploading to Apple..."
xcrun notarytool submit "$NOTARIZE_ZIP" \
    --keychain-profile "notarytool-password" \
    --wait

# Check if notarization succeeded
if [ $? -eq 0 ]; then
    echo "✅ Notarization successful!"

    # Staple the notarization ticket to the app
    echo "📎 Stapling notarization ticket..."
    xcrun stapler staple "$BUILT_APP"

    # Clean up zip
    rm "$NOTARIZE_ZIP"
else
    echo "❌ Notarization failed!"
    echo "Check the logs with: xcrun notarytool log <submission-id> --keychain-profile notarytool-password"
    exit 1
fi

# Step 5: Create DMG
echo ""
echo "💿 Creating DMG installer..."
hdiutil create \
    -volname "Midori Installer" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$RELEASE_DIR/${DMG_NAME}.dmg"

# Step 6: Notarize the DMG
echo ""
echo "📝 Notarizing DMG..."
xcrun notarytool submit "$RELEASE_DIR/${DMG_NAME}.dmg" \
    --keychain-profile "notarytool-password" \
    --wait

if [ $? -eq 0 ]; then
    echo "✅ DMG notarization successful!"

    # Staple the notarization ticket to the DMG
    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "$RELEASE_DIR/${DMG_NAME}.dmg"
else
    echo "❌ DMG notarization failed!"
    exit 1
fi

# Get file size
DMG_SIZE=$(du -h "$RELEASE_DIR/${DMG_NAME}.dmg" | cut -f1)

# Clean up staging and build directories
rm -rf "$DMG_DIR" "$BUILD_DIR"

# Success!
echo ""
echo "════════════════════════════════════════════"
echo "✅ Notarized DMG created successfully!"
echo "════════════════════════════════════════════"
echo ""
echo "📍 Location: $RELEASE_DIR/${DMG_NAME}.dmg"
echo "📦 Size: $DMG_SIZE"
echo "🔐 Status: Notarized by Apple"
echo ""
echo "🎁 READY TO SHARE WITH FRIENDS & FAMILY!"
echo ""
echo "Your friends can:"
echo "  1. Double-click ${DMG_NAME}.dmg"
echo "  2. Drag Midori.app to Applications folder"
echo "  3. Open Midori - NO WARNINGS!"
echo "  4. Grant Microphone + Accessibility permissions"
echo ""
echo "✨ The app will open without any security warnings!"
echo ""
echo "🧪 To test the installer yourself:"
echo "  open $RELEASE_DIR/${DMG_NAME}.dmg"
echo ""
