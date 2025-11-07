# Midori - Production Build Guide

## Overview
Midori is now configured as a production-ready macOS application that can be installed in `/Applications` and will auto-launch at login.

## Production Features

### Auto-Launch at Login
- ✅ Uses macOS `ServiceManagement` framework
- ✅ Automatically registers on first launch
- ✅ Survives system restarts
- ✅ User can manage via System Settings → General → Login Items

### Background Operation
- ✅ No Dock icon (LSUIElement)
- ✅ Runs as accessory app
- ✅ Menu bar icon for control
- ✅ Minimal resource usage

### Distribution-Ready
- ✅ Release build optimization
- ✅ Proper bundle identifier: `com.deepakpatnaik.midori`
- ✅ Version: 1.0
- ✅ Code signing configured

## Building for Production

### Quick Build & Install
```bash
./scripts/build-release.sh
```

This script will:
1. Clean previous builds
2. Build Release configuration
3. Kill any running Midori instance
4. Install to `/Applications/Midori.app`

### Manual Build Steps
```bash
# Build Release configuration
xcodebuild -scheme Midori-Debug -configuration Release build

# Install to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/midori-*/Build/Products/Release/midori.app /Applications/Midori.app

# Launch
open /Applications/Midori.app
```

## Installation

### First-Time Setup
1. **Build and Install**:
   ```bash
   cd /Users/d.patnaik/code/midori
   ./scripts/build-release.sh
   ```

2. **Launch the App**:
   ```bash
   open /Applications/Midori.app
   ```
   Or press `Cmd+Space` and type "Midori"

3. **Grant Permissions**:
   - **Microphone**: Will prompt automatically on first use
   - **Accessibility**: Required for text injection and key monitoring
     - Go to: System Settings → Privacy & Security → Accessibility
     - Enable Midori

4. **Verify Launch at Login**:
   - Go to: System Settings → General → Login Items
   - You should see "Midori" listed

### Usage
- **Press and hold Right Command key** to record
- **Release** to stop and transcribe
- Text appears at cursor position
- Menu bar icon shows app status

## Project Structure

```
midori/
├── midori/
│   ├── midoriApp.swift          # Main app with auto-launch
│   ├── KeyMonitor.swift         # Right Command monitoring
│   ├── AudioRecorder.swift      # Microphone recording
│   ├── TranscriptionManager.swift  # Parakeet V2 integration
│   ├── WaveformWindow.swift     # Waveform container
│   └── WaveformView.swift       # Dancing bars visualization
├── scripts/
│   ├── build-release.sh         # Production build script ⭐ NEW
│   ├── install-local.sh         # Development build
│   └── verify-setup.sh          # Setup verification
└── docs/
    └── REQUIREMENTS.md          # Original requirements
```

## Development vs Production

### Development Build (`~/.local/midori/`)
```bash
./scripts/install-local.sh && open ~/.local/midori/midori.app
```
- Used during development
- Debug symbols included
- Faster iteration

### Production Build (`/Applications/`)
```bash
./scripts/build-release.sh
```
- Optimized Release configuration
- Smaller binary size
- Auto-launch enabled
- Ready for distribution

## Uninstallation

To remove Midori:

```bash
# Quit the app
killall midori

# Remove from Applications
rm -rf /Applications/Midori.app

# Remove login item (automatic on next boot)
# Or manually via System Settings → General → Login Items
```

## Permissions Required

| Permission | Purpose | When Prompted |
|------------|---------|---------------|
| **Microphone** | Record voice for transcription | On first Right Command press |
| **Accessibility** | Text injection via Cmd+V simulation | Manually in System Settings |
| **Accessibility** | Monitor Right Command key globally | Manually in System Settings |

## Troubleshooting

### App Doesn't Launch at Login
1. Check System Settings → General → Login Items
2. Remove and re-add Midori if needed
3. Rebuild and reinstall: `./scripts/build-release.sh`

### Text Not Injecting
- Verify Accessibility permission granted
- Go to: System Settings → Privacy & Security → Accessibility
- Ensure Midori is enabled

### Right Command Not Working
- Verify Accessibility permission granted
- Restart the app via menu bar icon

### Multiple Instances Running
```bash
ps aux | grep "[m]idori"  # Check running instances
killall -9 midori         # Kill all instances
open /Applications/Midori.app  # Restart single instance
```

## Technical Details

### Launch at Login Implementation
Uses modern macOS `SMAppService` API:
```swift
import ServiceManagement

try SMAppService.mainApp.register()
```

No helper apps or LaunchAgents needed - fully integrated.

### Build Configuration
- **Scheme**: Midori-Debug (naming legacy, runs Release config)
- **Configuration**: Release
- **Optimization**: `-O` (speed)
- **Architecture**: arm64 (Apple Silicon)
- **Deployment Target**: macOS 15.6+

### Bundle Details
- **Identifier**: `com.deepakpatnaik.midori`
- **Version**: 1.0
- **Copyright**: None specified
- **Category**: Utility (Accessory)

## Next Steps

### For Daily Use
1. Build and install once: `./scripts/build-release.sh`
2. Grant permissions
3. Restart Mac to verify auto-launch
4. Use Right Command key to transcribe

### For Distribution
If sharing with others:
1. Add proper code signing identity
2. Consider notarization for Gatekeeper
3. Create DMG or PKG installer
4. Add app icon (currently uses system symbol)

## Status

✅ **Production-Ready Features Implemented:**
- Auto-launch at login
- Background operation (no Dock icon)
- Menu bar control
- Release build script
- /Applications installation

✅ **Working Core Features:**
- Push-to-talk with Right Command
- Real-time waveform visualization
- NVIDIA Parakeet V2 transcription
- Automatic text injection
- Silent failure handling

🎉 **Ready for daily use!**
