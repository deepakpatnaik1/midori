#!/bin/bash
# Verify Midori project setup according to best practices

echo "🔍 Verifying Midori project setup..."
echo ""

cd "$(dirname "$0")/.."

# Check 1: Build location configuration (now uses DerivedData for Swift Packages)
echo "✓ Checking build location configuration..."
if [ -f "midori.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings" ]; then
    if grep -q "UseAppPreferences" "midori.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings"; then
        echo "  ✅ Build location uses DerivedData (required for Swift Packages)"
    else
        echo "  ⚠️  Build location may not support Swift Packages"
    fi
else
    echo "  ❌ Build location not configured"
fi

# Check 2: Debug scheme exists
echo ""
echo "✓ Checking Debug scheme..."
if [ -f "midori.xcodeproj/xcshareddata/xcschemes/Midori-Debug.xcscheme" ]; then
    echo "  ✅ Midori-Debug scheme exists and is shared"
else
    echo "  ❌ Midori-Debug scheme not found"
fi

# Check 3: .gitignore configured
echo ""
echo "✓ Checking .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "build/" ".gitignore"; then
        echo "  ✅ .gitignore properly configured"
    else
        echo "  ⚠️  .gitignore exists but may be missing entries"
    fi
else
    echo "  ❌ .gitignore not found"
fi

# Check 4: App Sandbox disabled
echo ""
echo "✓ Checking App Sandbox setting..."
if grep -q "ENABLE_APP_SANDBOX = NO" "midori.xcodeproj/project.pbxproj"; then
    echo "  ✅ App Sandbox disabled (required for key monitoring)"
else
    echo "  ⚠️  App Sandbox may still be enabled"
fi

# Check 5: LSUIElement configured (menu bar app)
echo ""
echo "✓ Checking LSUIElement setting..."
if grep -q "INFOPLIST_KEY_LSUIElement = YES" "midori.xcodeproj/project.pbxproj"; then
    echo "  ✅ LSUIElement enabled (menu bar app mode)"
else
    echo "  ⚠️  LSUIElement not configured"
fi

# Check 6: Microphone permission description
echo ""
echo "✓ Checking microphone permission description..."
if grep -q "NSMicrophoneUsageDescription" "midori.xcodeproj/project.pbxproj"; then
    echo "  ✅ Microphone usage description configured"
else
    echo "  ⚠️  Microphone usage description missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup verification complete!"
echo ""
echo "Next steps:"
echo "  1. Open midori.xcodeproj in Xcode"
echo "  2. Select 'Midori-Debug' scheme in toolbar"
echo "  3. Build with Cmd+B or run with Cmd+R"
echo "  4. Binary will be at: build/midori.app (symlink to DerivedData)"
echo ""
echo "Useful scripts:"
echo "  ./scripts/build.sh         - Build the app"
echo "  ./scripts/run.sh           - Build and run the app"
echo "  ./scripts/reset-permissions.sh - Reset macOS permissions"
echo ""
echo "Note: Build now uses DerivedData (required for FluidAudio Swift Package)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
