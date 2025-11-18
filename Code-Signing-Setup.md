# Code Signing Setup - Midori

**Date**: 2025-11-18

---

## Problem

After joining the Apple Developer Program ($99/year) and obtaining a Developer certificate, the app was still being built with **adhoc signing** instead of using the paid certificate. This caused macOS to reset permissions (Accessibility, Microphone) on every build, requiring manual re-authorization through System Settings.

---

## Root Cause

The Xcode project had:
- `CODE_SIGN_STYLE = Automatic`
- **No `DEVELOPMENT_TEAM` set**

This configuration caused Xcode to fall back to adhoc signing, which macOS treats as a different app identity on each build.

---

## Diagnosis Steps

### 1. Check Current Signing Status

```bash
codesign -dvv /Users/d.patnaik/code/midori/build/midori.app
```

**Before fix:**
```
Signature=adhoc
TeamIdentifier=not set
```

### 2. Find Your Developer Certificate

```bash
security find-identity -v -p codesigning
```

**Output:**
```
1) 8A3FCC685825F89DA071A35DA224C7DB459BDB07 "Apple Development: deepakpatnaik1.appleid@gmail.com (XBH284RST9)"
```

### 3. Get Your Team ID

```bash
security find-certificate -a -c "Apple Development" -p | openssl x509 -noout -text | grep -A 3 "Subject:"
```

**Output:**
```
Subject: UID=Z7WMZNSN2E, CN=Apple Development: deepakpatnaik1.appleid@gmail.com (XBH284RST9), OU=NG9X4L83KH, O=Deepak Patnaik, C=US
```

**Team ID:** `NG9X4L83KH` (the `OU` field)

---

## Solution

### Edit Xcode Project File

File: `midori.xcodeproj/project.pbxproj`

**Add these two lines** to both Debug and Release build configurations:

```
CODE_SIGN_IDENTITY = "Apple Development";
DEVELOPMENT_TEAM = NG9X4L83KH;
```

### Exact Changes

**Debug configuration (line 259-291):**
```
BDEED7FD2EBC80BB0003B899 /* Debug */ = {
    isa = XCBuildConfiguration;
    buildSettings = {
        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        CODE_SIGN_IDENTITY = "Apple Development";        // ← ADDED
        CODE_SIGN_STYLE = Automatic;
        COMBINE_HIDPI_IMAGES = YES;
        CURRENT_PROJECT_VERSION = 1;
        DEVELOPMENT_TEAM = NG9X4L83KH;                   // ← ADDED
        ENABLE_APP_SANDBOX = NO;
        // ... rest of settings
    };
    name = Debug;
};
```

**Release configuration (line 292-329):**
```
BDEED7FE2EBC80BB0003B899 /* Release */ = {
    isa = XCBuildConfiguration;
    buildSettings = {
        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
        CODE_SIGN_IDENTITY = "Apple Development";        // ← ADDED
        CODE_SIGN_STYLE = Automatic;
        COMBINE_HIDPI_IMAGES = YES;
        CURRENT_PROJECT_VERSION = 1;
        DEVELOPMENT_TEAM = NG9X4L83KH;                   // ← ADDED
        ENABLE_APP_SANDBOX = NO;
        // ... rest of settings
    };
    name = Release;
};
```

---

## Build and Verify

### 1. Clean Build with Proper Signing

```bash
rm -rf build/midori.app
./scripts/build.sh
```

### 2. Verify Proper Signing

```bash
codesign -dvv /Users/d.patnaik/code/midori/build/midori.app
```

**After fix:**
```
Authority=Apple Development: deepakpatnaik1.appleid@gmail.com (XBH284RST9)
Authority=Apple Worldwide Developer Relations Certification Authority
Authority=Apple Root CA
TeamIdentifier=NG9X4L83KH
```

### 3. Remove Old Builds

```bash
# Remove any old adhoc-signed builds
rm -rf /Users/d.patnaik/Library/Developer/Xcode/DerivedData/midori-*/Index.noindex/Build/Products/Debug/midori.app
```

---

## Result

**Before:**
- Every build created a new app identity (adhoc signing)
- macOS reset Accessibility and Microphone permissions on every build
- Had to manually remove and re-add app in System Settings

**After:**
- App consistently signed with same Apple Developer certificate
- macOS recognizes app identity across builds
- Permissions persist through code changes and rebuilds
- No more System Settings → Privacy & Security → Accessibility dance

---

## Fixed Build Location

The project was already configured with a fixed build location to help with permission persistence:

**Build script:** `scripts/build.sh`
```bash
BUILD_DIR="$(pwd)/build"
xcodebuild -scheme Midori-Debug -configuration Debug \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
    build
```

**Final build location:** `/Users/d.patnaik/code/midori/build/midori.app`

This ensures the app binary stays in the same location across builds, which combined with proper code signing, eliminates permission reset issues.

---

## Summary

**Two changes needed for permission persistence:**

1. ✅ **Fixed build location** - Already implemented in `scripts/build.sh`
2. ✅ **Proper code signing** - Fixed by adding `DEVELOPMENT_TEAM` to Xcode project

Both are now in place. Permissions should persist across all future builds.
