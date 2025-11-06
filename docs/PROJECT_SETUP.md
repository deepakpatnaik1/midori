# Midori Project Setup Guide

**Last Updated**: 2025-11-05

This guide walks you through creating the Xcode project with the proper configuration for fixed build locations and debug workflow.

---

## Step 1: Create New Xcode Project

1. Open Xcode
2. File > New > Project
3. Select **macOS** > **App**
4. Configure project:
   - **Product Name**: `Midori`
   - **Team**: Your development team
   - **Organization Identifier**: `com.yourcompany` (or your preference)
   - **Bundle Identifier**: Will be `com.yourcompany.Midori`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Include Tests**: No (we'll add later if needed)
5. Save to: `/Users/d.patnaik/code/Midori/`
   - **Important**: Uncheck "Create Git repository on my Mac" (we'll manage this ourselves)

---

## Step 2: Configure Fixed Build Location

This is **CRITICAL** for solving the permission reset problem.

1. In Xcode, with project open:
   - **File > Project Settings** (or click "Midori" in the toolbar)
2. In "Project Settings" window:
   - Find **Derived Data** dropdown (currently says "Default")
   - Change to **"Project-relative Location"**
   - In the path field below, enter: `build`
   - Click outside the field to confirm
3. Close Project Settings window

**Verify**: You should now see `build/` appear in your project directory after first build.

**Why this matters**: This ensures every build goes to the same location, so macOS permissions persist between builds.

---

## Step 3: Create Midori-Debug Scheme

1. In Xcode toolbar (top), click the scheme selector (next to the play button)
2. Select **"Manage Schemes..."**
3. Click **"+"** to create new scheme
4. Configure:
   - **Name**: `Midori-Debug`
   - **Target**: Midori
   - Check **"Shared"** checkbox (very important!)
5. Click **"Close"**
6. Click **"Edit Scheme..."** for `Midori-Debug`
7. Lock all actions to Debug:
   - **Run** > Build Configuration: **Debug** ✓
   - **Test** > Build Configuration: **Debug**
   - **Profile** > Build Configuration: **Debug**
   - **Analyze** > Build Configuration: **Debug**
   - **Archive** > Build Configuration: **Debug**
8. Click **"Close"**

**Verify**:
- Toolbar should now show "Midori-Debug" as active scheme
- File `.xcodeproj/xcshareddata/xcschemes/Midori-Debug.xcscheme` should exist

---

## Step 4: Add Build Verification Script

This prevents accidental Release builds.

1. Select project in Project Navigator (top-left)
2. Select **Midori** target (not project)
3. Go to **Build Phases** tab
4. Click **"+"** > **"New Run Script Phase"**
5. Drag the new "Run Script" phase to be **first** (above "Dependencies")
6. Expand "Run Script" section
7. Name it: `Verify Debug Configuration`
8. In script area, paste:

```bash
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "error: Wrong configuration! Expected Debug, got ${CONFIGURATION}"
    exit 1
fi
echo "✓ Confirmed: Building in Debug configuration"
```

9. Save (Cmd+S)

**Verify**: Next build will show "✓ Confirmed: Building in Debug configuration" in build log.

---

## Step 5: Configure Build Settings

1. Select project in Project Navigator
2. Select **Midori** target
3. Go to **Build Settings** tab
4. Search for each setting and verify Debug configuration:

| Setting | Debug Value |
|---------|-------------|
| **Optimization Level** | `-O0` (None) |
| **Debug Information Format** | DWARF |
| **Swift Compilation Mode** | Incremental |
| **Enable Testability** | YES |

5. Go to **Build Settings** > **Swift Compiler - Custom Flags**
   - Add to **Other Swift Flags** (Debug): `-DDEBUG`

6. Go to **Build Settings** > **Apple Clang - Preprocessing**
   - Add to **Preprocessor Macros** (Debug): `DEBUG=1`

---

## Step 6: Run Setup Script

From terminal:

```bash
cd /Users/d.patnaik/code/Midori
./scripts/setup-project.sh
```

This will:
- Create `build/` directory
- Create/update `.gitignore`
- Verify configuration

---

## Step 7: Test Configuration

1. In Xcode, press **Cmd+B** to build
2. Check build log (Cmd+9):
   - Should see: `✓ Confirmed: Building in Debug configuration`
   - Should NOT see any configuration errors
3. Verify `build/` directory exists:
   ```bash
   ls -la build/
   ```

---

## Step 8: Configure App Info.plist

1. Select project > Target > Info tab
2. Add these keys:
   - **Privacy - Microphone Usage Description**:
     - Value: `Midori needs microphone access to record audio for transcription.`
   - **Privacy - Accessibility Usage Description**:
     - Value: `Midori needs accessibility access to monitor keyboard shortcuts and paste transcribed text.`

---

## Step 9: Initial Commit

```bash
git init
git add .
git commit -m "Initial Xcode project setup with fixed build location

- Project-relative build location (build/)
- Midori-Debug scheme (locked to Debug configuration)
- Build verification script
- Proper .gitignore
- Privacy usage descriptions"
```

---

## Verification Checklist

- ✅ Project builds successfully
- ✅ Build goes to `build/` directory (not DerivedData)
- ✅ `Midori-Debug` scheme is active
- ✅ Build log shows "✓ Confirmed: Building in Debug configuration"
- ✅ `.xcodeproj/xcshareddata/xcschemes/Midori-Debug.xcscheme` exists
- ✅ `.gitignore` includes `build/`
- ✅ Privacy descriptions added to Info.plist

---

## Common Issues

### "Can't find derived data"
- Make sure you set **Project-relative Location** in File > Project Settings
- Path should be `build` (not `build/` or `./build`)

### Scheme not shared
- Edit scheme, check "Shared" checkbox
- Commit `.xcodeproj/xcshareddata/xcschemes/` to git

### Build still goes to DerivedData
- Close Xcode
- Delete `~/Library/Developer/Xcode/DerivedData/Midori-*`
- Reopen Xcode
- Verify Project Settings again

---

## Next Steps

After setup is complete:
1. Review [BEST_PRACTICES.md](BEST_PRACTICES.md) for development workflow
2. Start implementing features following the requirements in [REQUIREMENTS.md](REQUIREMENTS.md)
3. Remember: Permissions will now persist between builds!
