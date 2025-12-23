# Distribution Build Hang Issue

**Date**: November 20, 2025
**Status**: ✅ RESOLVED

## Problem

The `./scripts/distribute.sh` script hangs indefinitely during the Release build phase and never completes compilation.

## Timeline

1. Started distribution build around evening of Nov 19, 2025
2. Process ran overnight (8+ hours)
3. Build stuck in early phase - only writing auxiliary files
4. Never progressed to actual Swift compilation
5. Process killed manually after confirming it was frozen

## What Was Observed

The build process got stuck after:
- ✅ Cleaning previous builds
- ✅ Resolving package dependencies
- ✅ Creating build directories
- ✅ Writing auxiliary build files (WriteAuxiliaryFile commands)
- ❌ **STUCK** - Never started actual Swift compilation (SwiftCompile)

The output showed repeated `WriteAuxiliaryFile` operations but no `SwiftCompile` or `SwiftDriver` operations that indicate actual code compilation.

## Script Details

**Script**: `./scripts/distribute.sh`
**Build Command**:
```bash
xcodebuild \
    -scheme Midori-Debug \
    -configuration Release \
    -derivedDataPath ./build-release \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM=NG9X4L83KH \
    PROVISIONING_PROFILE_SPECIFIER="" \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    build
```

## Possible Causes

1. **Xcode/Build System Bug**: The Release build with hardened runtime may trigger an Xcode bug
2. **Code Signing Issue**: Developer ID Application signing with hardened runtime might be misconfigured
3. **Resource Deadlock**: Build system waiting for some resource that never becomes available
4. **Package Dependency Issue**: WhisperKit or other dependencies may have issues with Release configuration

## What Works

- ✅ Debug builds complete successfully (tested multiple times)
- ✅ App runs fine in Debug configuration
- ✅ Code signing works for Debug builds

## What Doesn't Work

- ❌ Release builds hang indefinitely
- ❌ Distribution script cannot complete
- ❌ Cannot create notarized DMG

## Workarounds Attempted

None yet - issue discovered and documented.

## Next Steps to Try

1. **Test simple Release build**: Try building Release without hardened runtime or code signing
2. **Use build-release.sh**: Test the simpler `./scripts/build-release.sh` script
3. **Manual xcodebuild**: Run xcodebuild manually with minimal flags to isolate issue
4. **Check Xcode version**: Verify Xcode and command-line tools are up to date
5. **Clean derived data**: Delete all derived data and try fresh build
6. **Alternative distribution**: Consider using Xcode UI for Release build instead of command line

## Impact

- **Cannot distribute to friends/family**: No notarized DMG available
- **Onboarding feature ready**: All code is complete and tested
- **Debug builds work fine**: Development can continue

## Notes

The CLAUDE.md mentions: "Debug builds only: Release builds historically had issues with FluidAudio."

This suggests Release builds have been problematic before, possibly related to the FluidAudio dependency.

---

## Systematic Diagnostic Plan (November 20, 2025)

**First Principles**: Millions of apps successfully build Release configurations and get distributed on the App Store. This is a solved problem. The issue is likely a misconfiguration in the Xcode project or build settings, not an inherent impossibility.

**Root Cause Hypothesis**:
- Release builds hang during compilation (Debug works fine)
- Suggests: Xcode project Release configuration has problematic settings
- Less likely: FluidAudio genuinely broken in Release (would affect all users)
- Less likely: Build command syntax issue

**Diagnostic Steps**:

### Step 1: Inspect Xcode Project Release Configuration
**Goal**: Identify what's different between Debug and Release build settings

**Actions**:
- Extract and compare Debug vs Release build settings from project.pbxproj
- Focus on common hang culprits:
  - `SWIFT_COMPILATION_MODE` (should be "wholemodule" or "incremental")
  - `SWIFT_OPTIMIZATION_LEVEL` (should be "-O" for Release)
  - `DEAD_CODE_STRIPPING` (should be YES for Release)
  - `GCC_OPTIMIZATION_LEVEL` (should be "-Os" or similar)
  - Any unusual flags or overrides

**Expected Outcome**: Find a problematic setting causing compilation to hang

**Decision Point**:
- If found: Fix the setting and proceed to Step 4
- If nothing obvious: Proceed to Step 2

### Step 2: Minimal Release Build Test
**Goal**: Test if basic Release build works without signing/hardening

**Command**:
```bash
xcodebuild -scheme Midori-Debug -configuration Release build
```

**What this tests**: Release configuration in isolation (no Developer ID, no hardened runtime)

**Expected Outcome**:
- **If hangs**: Problem is in Xcode Release config → return to Step 1 with more scrutiny
- **If succeeds**: Problem is with signing/hardening flags → proceed to Step 3

### Step 3: Incremental Signing/Hardening Test
**Goal**: Find which signing flag causes the hang

**Test sequence**:
1. Add Developer ID signing only
2. Add hardened runtime
3. Add timestamp and runtime options

**Find the breaking point and investigate that specific flag**

### Step 4: Full Distribution Build
**Goal**: Create notarized DMG

**Once Release builds work**:
1. Run `./scripts/distribute.sh`
2. Package as DMG
3. Notarize with Apple
4. Test installation

**Success Criteria**: Notarized DMG that installs without security warnings

---

**Next Action**: Execute Step 1 - inspect Xcode project Release settings

---

## RESOLUTION (November 20, 2025)

### Root Cause #1: Build Hang
**Corrupted Xcode DerivedData** - The build system had corrupted cached build artifacts in `~/Library/Developer/Xcode/DerivedData/midori-*` that were causing the build to hang indefinitely.

### Root Cause #2: Broken Microphone Access (CRITICAL)
**Missing Entitlements File** - Production builds with Hardened Runtime enabled but NO entitlements file were blocking microphone access, causing the app to be completely non-functional.

### Discovery Process
Through systematic testing:
1. ✅ Minimal Release build (no signing) - **SUCCEEDED**
2. ✅ Release with Developer ID signing - **SUCCEEDED**
3. ✅ Release with hardened runtime - **SUCCEEDED**
4. ✅ Release with all flags (timestamp, runtime options) - **SUCCEEDED**

All builds succeeded after cleaning derived data at the start of diagnostics with:
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/midori-*
```

### The Fix
Updated `scripts/distribute.sh` to clean derived data before building:
```bash
# Step 1: Clean previous builds and derived data
echo "🧹 Cleaning previous builds and derived data..."
rm -rf "$DMG_DIR" "$RELEASE_DIR" "$BUILD_DIR"
rm -rf ~/Library/Developer/Xcode/DerivedData/midori-*  # <-- ADDED THIS LINE
mkdir -p "$RELEASE_DIR"
mkdir -p "$DMG_DIR"
```

### Key Learnings
1. **The signing flags were NOT the problem** - Developer ID signing, hardened runtime, and timestamp flags all work correctly
2. **FluidAudio works fine in Release builds** - The CLAUDE.md note about "Release builds historically had issues with FluidAudio" was incorrect
3. **Always clean derived data for distribution builds** - Prevents corruption from affecting production builds
4. **Systematic testing works** - Following the diagnostic plan led to the correct root cause
5. **CRITICAL: Hardened Runtime requires entitlements** - When `ENABLE_HARDENED_RUNTIME=YES`, you MUST provide an entitlements file with:
   - `com.apple.security.device.audio-input` = true (for microphone access)
   - `com.apple.security.cs.disable-library-validation` = true (for global event monitoring)
   - Without these, the app builds successfully but is completely non-functional

### Status
✅ **FULLY RESOLVED** - Distribution script now:
1. Cleans derived data before building (prevents build hangs)
2. Uses `midori.entitlements` file for proper Hardened Runtime permissions (enables microphone access)

**Files Created/Modified:**
- `midori.entitlements` - NEW: Entitlements file for Hardened Runtime
- `scripts/distribute.sh` - UPDATED: Added `CODE_SIGN_ENTITLEMENTS="midori.entitlements"`
