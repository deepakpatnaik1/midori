# Midori - Voice to Text for macOS

**A beautiful, minimal voice-to-text transcription app that lives in your menu bar.**

Press Right Command to record. Release to transcribe. Text appears at your cursor. That's it.

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/swift-5.0-orange)

## Features

- 🎤 **Voice Recording** - Hold Right Command key to record
- 🌊 **Visual Feedback** - Animated waveform with purple-to-cyan gradient
- ✨ **Real-time Transcription** - Powered by NVIDIA Parakeet V2
- 📝 **Smart Injection** - Text appears at your cursor in any app
- 🎯 **Menu Bar Native** - Always available, never intrusive
- 🚀 **Auto-launch** - Starts automatically at login
- ⚡️ **Zero Friction** - No clicking, no windows, no distractions

## Quick Start

### For End Users

1. Download `Midori-Installer.dmg`
2. Double-click to mount the DMG
3. Drag `Midori.app` to the `Applications` folder
4. Launch Midori from Applications or Spotlight (⌘+Space → "Midori")
5. Grant permissions when prompted:
   - **Microphone**: Click "OK" when prompted
   - **Accessibility**: System Settings → Privacy & Security → Accessibility → Enable Midori

### Use It

1. Press and **hold** Right Command key (⌘)
2. Wait for the pop sound
3. Speak your message while watching the animated waveform
4. **Release** Right Command when done
5. Watch the transcription appear at your cursor!

## Project Status

**Status**: ✅ **PRODUCTION READY**

### Completed Features
- ✅ Menu bar app with waveform icon
- ✅ Right Command key detection
- ✅ Real audio recording with AVAudioEngine
- ✅ Animated 9-bar waveform visualization
- ✅ Pop sound feedback
- ✅ Real transcription with NVIDIA Parakeet V2
- ✅ Text injection at cursor position
- ✅ Auto-launch at login
- ✅ Custom app icon (gradient waveform)
- ✅ Production DMG installer

## Installation for Development

### Build and Install Locally
```bash
./scripts/install-local.sh
```

This installs to `~/.local/midori/midori.app` for stable permissions.

### Create Production DMG
```bash
./scripts/package-dmg.sh
```

This creates `release/Midori-Installer.dmg` ready for distribution.

## Documentation

- **[PRODUCTION.md](PRODUCTION.md)** - Production build and distribution
- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - How to test the app
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Technical details
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Current status
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheat sheet

## Architecture

```
Menu Bar App
    ├── KeyMonitor (NSEvent) → Right Command detection
    ├── AudioRecorder (AVAudioEngine) → Real audio capture
    ├── WaveformWindow (SwiftUI) → 9-bar gradient visualization
    └── TranscriptionManager (FluidAudio/Parakeet) → AI transcription
```

Clean separation of concerns with callback-based communication.

## Development

### Build System
```bash
# Install locally for development
./scripts/install-local.sh

# Create production DMG
./scripts/package-dmg.sh

# Verify setup
./scripts/verify-setup.sh
```

### Key Features
- **Fixed build location** - `build/Build/Products/Debug/midori.app`
- **No permission resets** - Same path = persistent permissions
- **Debug configuration** - Release optimizations break audio/transcription
- **Local package** - FluidAudio integrated via local Swift package

### Open in Xcode
```bash
open midori.xcodeproj
```

Select `Midori-Debug` scheme and press Cmd+R to run.

## Requirements

- macOS 14.0+
- Xcode 16.1+
- Swift 5.0+
- Apple Silicon (arm64) or Intel (x86_64)

### Required Permissions
- **Microphone** - To record your voice
- **Accessibility** - To paste text at cursor

## Design Philosophy

**Inspired by the best tools**: Minimal, fast, invisible until needed.

- No windows to manage
- No clicking required
- No configuration needed
- Just press, speak, release

**Technical philosophy**:
- Real audio recording with AVAudioEngine
- State-of-the-art transcription with Parakeet V2
- Native macOS integration (menu bar, key monitoring)
- Zero-friction user experience

## Technical Highlights

- **NSEvent-based key monitoring** - Global Right Command detection
- **SwiftUI + AppKit hybrid** - Best of both worlds
- **Callback architecture** - Clean, testable, maintainable
- **ObservableObject pattern** - Reactive UI updates
- **FluidAudio package** - NVIDIA Parakeet V2 transcription
- **Fixed build location** - Stable permissions

## File Structure

```
midori/
├── midori/
│   ├── midoriApp.swift          # Main app + AppDelegate
│   ├── KeyMonitor.swift         # Key detection
│   ├── AudioRecorder.swift      # Audio capture
│   ├── TranscriptionManager.swift # AI transcription
│   ├── WaveformView.swift       # 9-bar visualization
│   ├── WaveformWindow.swift     # Floating window
│   └── ContentView.swift        # (unused)
├── FluidAudio-Local/            # Local Swift package
├── scripts/                     # Build & install scripts
├── docs/                        # Requirements & guidelines
├── build/                       # Built app (gitignored)
└── release/                     # Production DMG
```

## Distribution

The app is distributed as a DMG installer:
- **File**: `release/Midori-Installer.dmg`
- **Size**: ~17 MB
- **Configuration**: Debug (Release optimizations break functionality)
- **Contents**: App + Instructions + Applications symlink

Recipients just need to:
1. Double-click the DMG
2. Drag to Applications
3. Grant permissions on first launch

## Known Limitations

- **Debug build required**: Swift Release optimizations break audio/transcription functionality
- **Manual permissions**: macOS requires users to manually grant Accessibility and Microphone permissions
- **Apple Silicon optimized**: Primarily tested on Apple Silicon Macs

## Roadmap

- [x] Menu bar app infrastructure
- [x] Right Command key monitoring
- [x] Waveform visualization
- [x] Pop sound feedback
- [x] Real audio recording
- [x] Real transcription (Parakeet V2)
- [x] Text injection at cursor
- [x] Auto-launch at login
- [x] Custom app icon
- [x] Production DMG installer
- [ ] Permission setup helper UI
- [ ] Model management UI
- [ ] Preferences window
- [ ] Custom keyboard shortcuts

## Credits

- **NVIDIA Parakeet V2** - Speech recognition model
- **FluidAudio** - Audio processing and transcription library
- **Design** inspired by minimal, functional macOS tools

## License

Private project - All rights reserved.

---

**Built with ❤️ for productivity**

Press Right Command and start speaking! 🎤
