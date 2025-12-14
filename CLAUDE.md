# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Midori** is a macOS menu bar application for hands-free voice-to-text transcription. Hold Right Command, speak, release—text appears at cursor. Features on-device AI transcription (NVIDIA Parakeet V2), custom dictionary for corrections, and a beautiful purple-cyan waveform visualization.

**Tech Stack**: Swift/SwiftUI, macOS 14.0+, AVFoundation, FluidAudio (Parakeet V2), AppKit

---

## Build Commands

### Development
```bash
# Build app (Debug configuration)
./scripts/build.sh

# Run tests
./scripts/run-tests.sh

# Build release version
./scripts/build-release.sh

# Create distributable DMG (with notarization)
./scripts/distribute.sh

# Install locally to /Applications
./scripts/install-local.sh
```

### Testing
```bash
# Run all unit tests
./scripts/run-tests.sh

# Run single test file (via Xcode)
xcodebuild test -scheme Midori-Debug -only-testing:midoriTests/CorrectionLayerTests

# Run single test method
xcodebuild test -scheme Midori-Debug -only-testing:midoriTests/CorrectionLayerTests/testSimpleCorrection
```

### Build Output
- Debug builds: `/Users/d.patnaik/code/midori/build/midori.app`
- Release builds: `/Users/d.patnaik/code/midori/build-release/Build/Products/Release/Midori.app`

**Important**: The build location is intentionally fixed to preserve macOS permissions (Accessibility, Microphone) across rebuilds. Do not change `CONFIGURATION_BUILD_DIR` in build scripts.

---

## Architecture Overview

### Central Orchestrator Pattern
```
AppDelegate (midoriApp.swift)
    ├── KeyMonitor: Global Right Command key detection
    ├── AudioRecorder: AVAudioEngine audio capture
    ├── TranscriptionManager: FluidAudio + Parakeet V2
    ├── CorrectionLayer: Post-processing text corrections
    ├── WaveformWindow: Floating window container
    ├── WaveformView: 9-bar dancing visualization
    ├── TrainingWindow: Custom dictionary UI
    └── AboutWindow: Standard about dialog
```

### Key Components

**AppDelegate** (`midoriApp.swift`, ~365 lines)
- Central state machine with `DispatchQueue` for thread safety
- Manages recording lifecycle: Right Command press → 0.5s delay → double pop → record → transcribe → inject text
- Menu bar setup and management
- Text injection via pasteboard + simulated Cmd+V (requires Accessibility permission)

**AudioRecorder** (`AudioRecorder.swift`, ~333 lines)
- Captures audio at native sample rate (48kHz) using AVAudioEngine
- **IMPORTANT**: Intentionally forces built-in microphone (ignores AirPods) for reliability
- Real-time RMS audio level calculation for waveform
- Buffers audio in `[AVAudioPCMBuffer]` array (max 300 buffers ~10 seconds)

**TranscriptionManager** (`TranscriptionManager.swift`, ~151 lines)
- Integrates FluidAudio package for NVIDIA Parakeet V2 CoreML models
- Downloads models (~17MB) from HuggingFace on first run
- Downsamples 48kHz → 16kHz (3:1 stride) before transcription
- Async initialization—model may not be ready on first use

**CorrectionLayer** (`CorrectionLayer.swift`, ~91 lines)
- Post-processing correction layer for custom vocabulary
- Regex-based word boundary detection (`\b` anchors)
- Case-insensitive matching with case preservation
- Sorts corrections by length (longest first) to handle overlaps
- Applies sentence case (capitalize first letter, add period)

**DictionaryManager** (`DictionaryManager.swift`, ~69 lines)
- Manages custom dictionary storage and persistence
- UserDefaults-based with Codable
- Normalizes incorrect spellings (lowercase, no punctuation)
- Preserves correct spellings exactly as entered

**WaveformView** (`WaveformView.swift`, ~166 lines)
- Beautiful 9-bar visualization with purple-to-cyan gradient
- Base state: dots in straight line when silent
- Active state: bars dance with unique "personalities" (random max heights, sine wave combinations)
- 60fps animation, ultra-sensitive to soft speech (0.03 threshold)
- Exponential amplification: `pow(intensity * 12.0, 0.65)`

**TrainingWindow** (`TrainingWindow.swift`, ~463 lines)
- Custom dictionary management UI
- Record sample audio and see what Parakeet transcribes
- Manual entry option for corrections (no recording required)
- List view of all corrections with delete functionality

---

## Critical Implementation Details

### State Management
AppDelegate uses a bulletproof state machine:
```swift
private var isRecording = false
private var recordingStartTimer: DispatchWorkItem?
private let stateQueue = DispatchQueue(label: "com.midori.stateQueue")
```
**Never bypass the stateQueue**—all state changes must go through it to prevent race conditions.

### Recording Flow Timing
1. Right Command pressed → waveform appears instantly in base state
2. 0.5-second delay (not 1 second!)
3. Double pop sound (0.15s apart)
4. Recording starts
5. Right Command released → transcribe → inject text

**Critical**: The delay is 0.5 seconds, not 1 second. Pop sound plays after the delay, not immediately.

### Audio Device Selection
AudioRecorder intentionally forces the built-in microphone:
```swift
// Line ~121: Forces built-in mic, ignores AirPods
let format = input.outputFormat(forBus: 0)
```
This is a **deliberate design decision** for reliability. Do not "fix" this to auto-detect AirPods unless explicitly requested.

### Code Signing
The Xcode project is configured with:
- Team ID: `NG9X4L83KH`
- Certificate: Apple Development (Debug), Developer ID Application (Release)
- Sandboxing: **Disabled** (required for global key monitoring)
- **Entitlements**: `midori.entitlements` (REQUIRED for production builds with Hardened Runtime)

**CRITICAL for Production Builds**: When building with Hardened Runtime (`ENABLE_HARDENED_RUNTIME=YES`), you MUST use the `midori.entitlements` file. Without it, macOS will block microphone access and the app will be non-functional (waveform appears but doesn't respond to audio).

Required entitlements:
- `com.apple.security.device.audio-input` = true (microphone access)
- `com.apple.security.cs.disable-library-validation` = true (global event monitoring)

See `Code-Signing-Setup.md` for details.

### Text Injection
Uses Accessibility API (requires permission):
```swift
// Copy to pasteboard, simulate Cmd+V
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(text, forType: .string)
// Create CGEvent for Cmd+V keypresses
```

---

## Testing

### Test Suite (40 tests, all passing)
- **DictionaryManagerTests**: 17 tests (persistence, normalization, edge cases)
- **CorrectionLayerTests**: 23 tests (corrections, punctuation, sentence case, regression, performance)

### Regression Tests
Two critical bugs are tested:
1. **Text corruption bug** ("MODIFIED CALL 2A"): Prevented by proper regex implementation
2. **Word fragmentation bug**: Prevented by word boundary detection

### Performance Tests
- Many corrections: 100+ corrections applied
- Long text: 100x repetition of text

See `TEST-COVERAGE.md` for full details.

---

## Common Patterns

### Adding New Corrections Programmatically
```swift
let correctionLayer = CorrectionLayer()
correctionLayer.addCorrection(incorrect: "clawed", correct: "Claude")
let result = correctionLayer.apply(to: "I used clawed today")
// Result: "I used Claude today."
```

### Accessing Components from AppDelegate
```swift
// In midoriApp.swift
self.audioRecorder?.startRecording()
self.transcriptionManager?.transcribe(audioData)
self.waveformWindow?.show()
```

### Testing Audio Recording
Audio recording requires actual hardware. For testing:
1. Grant Microphone permission in System Settings
2. Use built-in microphone (not AirPods)
3. Verify pop sound plays

---

## Dependencies

**External Package**: FluidAudio v0.7.9 (NVIDIA Parakeet V2)
```swift
// Package.swift
.package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.7.7")
// Package.resolved pins to v0.7.9
```

**Apple Frameworks**:
- SwiftUI (UI and waveform)
- AppKit (menu bar, windows, global event monitoring)
- AVFoundation (audio recording via AVAudioEngine)
- CoreAudio (low-level audio device management)
- ServiceManagement (auto-launch at login)
- Carbon (key code constants)
- AudioToolbox (system pop sound)

---

## Known Quirks and Design Decisions

1. **Fixed build location**: Build output goes to `build/` directory to prevent permission resets. Do not change.

2. **No sandboxing**: App sandbox is disabled because global key monitoring (NSEvent.addGlobalMonitorForEvents) doesn't work in sandboxed apps.

3. **Forced built-in mic**: Intentionally ignores AirPods for reliability. This is not a bug.

4. **0.5-second delay**: Recording doesn't start immediately—there's a 0.5s delay to prevent accidental triggers. This is user-requested behavior.

5. **Sentence case formatting**: CorrectionLayer automatically capitalizes the first letter and adds a period. This is intentional.

6. **UserDefaults for persistence**: Custom dictionary uses UserDefaults with JSON encoding. Simple and effective for this use case.

---

## Project Status

**Current State**: Production-ready for personal use
- ✅ 40 automated tests, all passing
- ✅ Custom dictionary with training UI
- ✅ On-device transcription (no cloud/API)
- ✅ Stable permissions (code signing configured)
- ✅ Comprehensive documentation

**Recent Work**:
- Custom dictionary implementation (Phase 2 complete)
- Training UI with manual entry option (Phase 4 complete)
- Comprehensive test suite (TEST-COVERAGE.md)

**Branch**: `main` (stable)

---

## Implementation Philosophy

From `Implementation-Plan.md`:
> **Philosophy**: Surgical precision. Keep what works, fix what's broken, add what's missing.

When making changes:
- Preserve existing working functionality
- Test thoroughly before moving to next phase
- Use the stateQueue for all state changes in AppDelegate
- Add regression tests for any bugs discovered
- Update documentation when architecture changes

---

## File Locations

### Source Code
All Swift source files: `midori/*.swift`

### Key Files
- `midori/midoriApp.swift`: Main app and AppDelegate (~365 lines)
- `midori/AudioRecorder.swift`: Audio capture (~333 lines)
- `midori/TranscriptionManager.swift`: Parakeet integration (~151 lines)
- `midori/CorrectionLayer.swift`: Text correction (~91 lines)
- `midori/WaveformView.swift`: Visualization (~166 lines)
- `midori/TrainingWindow.swift`: Dictionary UI (~463 lines)

### Documentation
- `Requirements.md`: User requirements and desired UX
- `Architecture.md`: Technical architecture (AS-IS and SHOULD-BE states)
- `Implementation-Plan.md`: Phase-by-phase development plan
- `TEST-COVERAGE.md`: Test suite documentation
- `Code-Signing-Setup.md`: Permission persistence setup

### Scripts
- `scripts/build.sh`: Debug build
- `scripts/build-release.sh`: Release build
- `scripts/run-tests.sh`: Run test suite
- `scripts/distribute.sh`: Create DMG with notarization
- `scripts/install-local.sh`: Install to /Applications

---

## Permissions Required

1. **Microphone**: For audio recording
2. **Accessibility**: For text injection (simulated Cmd+V keypress)

These permissions persist across builds thanks to:
- Fixed build location (`CONFIGURATION_BUILD_DIR`)
- Proper code signing with Apple Developer certificate (Team ID: NG9X4L83KH)

If permissions reset, see `Code-Signing-Setup.md`.
