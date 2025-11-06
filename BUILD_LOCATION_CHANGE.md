# Build Location Change

## What Changed

The project build location has changed from a fixed custom location to using Xcode's default DerivedData location.

### Before (Fixed Build Location)
- Build output: `build/Build/Products/Debug/midori.app`
- Configuration: `WorkspaceRelativePath` with custom `SYMROOT` and `CONFIGURATION_BUILD_DIR`
- Problem: **Incompatible with Swift Package Manager**

### After (DerivedData Location)
- Build output: `~/Library/Developer/Xcode/DerivedData/midori-*/Build/Products/Debug/midori.app`
- Stable symlink: `build/midori.app` → DerivedData location
- Configuration: `UseAppPreferences` (standard Xcode behavior)
- Benefit: **Swift Packages (FluidAudio) now work!**

## Why the Change?

Swift Package Manager **does not support** custom "legacy" build locations. When we added FluidAudio as a Swift Package dependency, Xcode refused to build with this error:

```
Packages are not supported when using legacy build locations,
but the current project has them enabled.
```

The only solution was to use the default DerivedData location.

## Impact on Your Workflow

### ✅ What Still Works
- All scripts updated and working: `build.sh`, `run.sh`, `verify-setup.sh`
- Stable access via symlink: `build/midori.app`
- Permissions persist (DerivedData path is stable across builds)
- All automation scripts reference the symlink, not the raw DerivedData path

### ⚠️ What Changed
- The actual binary location now includes a hash in the path
- You cannot manually set the build location in Xcode settings
- The `build/` directory now only contains a symlink, not the actual app

## Testing

Build and verify the symlink works:

```bash
./scripts/build.sh
ls -la build/midori.app
open build/midori.app
```

The symlink is automatically created/updated by the build script.

## Key Files Modified

1. **Workspace Settings**
   - `midori.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`
   - `midori.xcodeproj/project.xcworkspace/xcuserdata/*/WorkspaceSettings.xcsettings`
   - Changed `BuildLocationStyle` from `UseTargetSettings`/`WorkspaceRelativePath` to `UseAppPreferences`

2. **Project Settings**
   - `midori.xcodeproj/project.pbxproj`
   - Removed custom `SYMROOT` and `CONFIGURATION_BUILD_DIR` from Debug configuration
   - Added FluidAudio local package reference

3. **Build Scripts**
   - `scripts/build.sh` - Now creates symlink after build
   - `scripts/run.sh` - Uses symlink to launch app
   - `scripts/verify-setup.sh` - Updated to check for DerivedData configuration

## Permissions Behavior

Good news: **Permissions should still persist!**

- The DerivedData path hash (`midori-cddvkunevsaircdjmwzzakgjbxdw`) is stable
- It's based on the project path and configuration
- As long as you don't move the project, the hash stays the same
- Therefore, macOS permissions (Microphone, Accessibility) remain granted

## Reverting (Not Recommended)

If you need to revert to a fixed build location (losing Swift Package support):

1. Remove FluidAudio package from project
2. Change WorkspaceSettings back to `WorkspaceRelativePath`
3. Add `SYMROOT` and `CONFIGURATION_BUILD_DIR` back to project.pbxproj

But you'll lose FluidAudio + Parakeet V2 transcription!

## Summary

- ✅ FluidAudio Swift Package now works
- ✅ Real Parakeet V2 AI transcription functional
- ✅ Scripts updated and working
- ✅ Stable symlink at `build/midori.app`
- ✅ Permissions persist across builds
- ⚠️ Build location no longer customizable (Xcode/SPM limitation)
