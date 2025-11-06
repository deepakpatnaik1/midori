# Midori - Voice to Text for macOS

**A beautiful, minimal voice-to-text transcription app that lives in your menu bar.**

Press Right Command to record. Release to transcribe. Text appears at your cursor. That's it.

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/swift-5.0-orange)

## Features

- 🎤 **Voice Recording** - Hold Right Command key to record
- 🌊 **Visual Feedback** - Animated waveform with purple-to-cyan gradient
- ✨ **Instant Transcription** - Powered by Whisper AI
- 📝 **Smart Injection** - Text appears at your cursor in any app
- 🎯 **Menu Bar Native** - Always available, never intrusive
- ⚡️ **Zero Friction** - No clicking, no windows, no distractions

## Quick Start

### Run the App
```bash
./scripts/run.sh
```

### Use It
1. Press and **hold** Right Command key (⌘)
2. Wait 1 second (you'll hear a pop sound)
3. Speak your message while watching the animated waveform
4. **Release** Right Command when done
5. Watch pulsing dots while transcribing
6. Your text appears at the cursor!

## Project Status

**Development**: ✅ Complete
**Production Ready**: 🚧 Needs whisper.cpp integration

### What Works Now (Development Mode)
- ✅ Menu bar app with status icon
- ✅ Right Command key detection
- ✅ Animated waveform visualization
- ✅ User feedback sequence (pop sound, pulsing dots)
- ✅ Mock transcription (returns test phrases)
- ✅ Text injection simulation

### What's Next (Production)
- 🚧 Real whisper.cpp transcription
- 🚧 Real audio recording (code ready, needs testing)
- 🚧 Accessibility permission for text injection

See [TODO.md](TODO.md) for full production checklist.

## Documentation

- **[TESTING_GUIDE.md](TESTING_GUIDE.md)** - How to test the app
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Technical details
- **[TODO.md](TODO.md)** - Production roadmap
- **[PROJECT_STATUS.md](PROJECT_STATUS.md)** - Current status
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command cheat sheet

## Architecture

```
Menu Bar App
    ├── KeyMonitor (NSEvent) → Right Command detection
    ├── AudioRecorder (AVAudioEngine) → Audio capture
    ├── WaveformWindow (SwiftUI) → 9-bar visualization
    └── TranscriptionManager (whisper.cpp) → AI transcription
```

Clean separation of concerns with callback-based communication.

## Development

### Build System
```bash
# Verify configuration
./scripts/verify-setup.sh

# Build only
./scripts/build.sh

# Build and run
./scripts/run.sh

# Reset permissions (if needed)
./scripts/reset-permissions.sh
```

### Key Features
- **Fixed build location** - `build/Build/Products/Debug/midori.app`
- **No permission resets** - Same path = persistent permissions
- **Debug-only scheme** - Fast iteration with `-Onone`
- **Mock data pattern** - Test without permissions during dev

### Open in Xcode
```bash
open midori.xcodeproj
```

Select `Midori-Debug` scheme and press Cmd+R to run.
Press Cmd+Shift+Y to see console output.

## Requirements

- macOS 15.6+
- Xcode 16.1+
- Swift 5.0+

### Permissions (for production)
- **Microphone** - To record your voice
- **Accessibility** - To paste text at cursor

## Design Philosophy

**Inspired by the best tools**: Minimal, fast, invisible until needed.

- No windows to manage
- No clicking required
- No configuration needed
- Just press, speak, release

**Development philosophy**:
- Mock data during development (avoid permission dialogs)
- Real implementation ready but gated
- Full workflow testable end-to-end
- Zero-friction debugging

## Technical Highlights

- **NSEvent-based key monitoring** - No accessibility permissions during dev
- **SwiftUI + AppKit hybrid** - Best of both worlds
- **Callback architecture** - Clean, testable, maintainable
- **ObservableObject pattern** - Reactive UI updates
- **Fixed build location** - No more permission resets!

## File Structure

```
midori/
├── midori/
│   ├── midoriApp.swift          # Main app + AppDelegate
│   ├── KeyMonitor.swift         # Key detection
│   ├── AudioRecorder.swift      # Audio capture
│   ├── TranscriptionManager.swift # AI transcription
│   ├── WaveformView.swift       # 9-bar visualization
│   └── WaveformWindow.swift     # Floating window
├── scripts/                     # Automation scripts
├── docs/                        # Requirements & guidelines
└── build/                       # Built app (gitignored)
```

## Contributing

This is a personal project, but feedback and suggestions are welcome!

## Roadmap

- [x] Menu bar app infrastructure
- [x] Right Command key monitoring
- [x] Waveform visualization
- [x] User feedback sequence
- [x] Mock transcription
- [ ] whisper.cpp integration
- [ ] Real audio recording
- [ ] Model management UI
- [ ] Auto-launch at login
- [ ] Custom app icon
- [ ] Preferences window

## Credits

- **Whisper AI** by OpenAI - Speech recognition
- **whisper.cpp** by Georgi Gerganov - C++ implementation
- **Design** inspired by minimal, functional macOS tools

## License

Private project - All rights reserved.

---

**Built with ❤️ for productivity**

Press Right Command and start speaking! 🎤
