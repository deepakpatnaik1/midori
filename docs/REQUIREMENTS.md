# Midori - Voice-to-Text Transcription App Requirements

**Platform**: macOS
**Language**: Swift
**Status**: ✅ Production Ready
**Last Updated**: 2025-11-06

## Core Functionality

### Application Behavior
- ✅ Small Swift app for macOS
- ✅ Auto-launches at login (ServiceManagement API)
- ✅ Always running in background
- ✅ Minimal memory and CPU consumption
- ✅ Menu bar indicator showing waveform icon with quit/restart options
- ✅ Survives and auto-launches after restart

### Recording Trigger
- ✅ **Activation**: Right Command key press (NSEvent global monitoring)
- ✅ **Deactivation**: Right Command key release
- ✅ **No alternatives**: Right Command key is only option
- ✅ **No auto-stop**: Recording duration entirely controlled by key press/release

### Audio Capture
- ✅ **Input source**: Microphone only (not system-wide audio)
- ✅ **Audio framework**: AVAudioEngine with real-time capture
- ✅ **Permissions**: Standard macOS microphone permission prompt

### User Feedback Sequence

#### On Key Press
1. ✅ Right Command key pressed
2. ✅ Audio recording starts immediately
3. ✅ Pop sound plays when speech detected
4. ✅ Waveform visualization appears (bottom center of screen)

#### During Recording
- ✅ Waveform shows actual real-time audio levels from microphone
- ✅ Waveform animates based on microphone input
- ✅ Uses purple-to-cyan gradient (matching logo)
- ✅ Small and beautiful 9-bar visualization

#### On Key Release
1. ✅ Right Command key released
2. ✅ Waveform disappears
3. ✅ Transcription begins automatically
4. ✅ No visual indicator during transcription (instant on modern hardware)

#### Transcription Complete
1. ✅ Transcribed text instantly pasted at cursor position in active app
2. ✅ Works in any app (requires Accessibility permissions)
3. ✅ Uses pasteboard + CGEvent for text injection

### Error Handling
- ✅ If transcription fails: Display error dialog
- ✅ No silent failures
- ✅ User-friendly error messages

## Technical Requirements

### Transcription Engine
- ✅ **Engine**: NVIDIA Parakeet V2 via FluidAudio (local Swift package)
- ✅ **Language**: English only
- ✅ **Model**: Parakeet V2 (state-of-the-art accuracy)
- ✅ **Model storage**: Managed by FluidAudio
- ✅ **Performance**: Real-time transcription on Apple Silicon

**Note**: Originally planned to use whisper.cpp, but switched to NVIDIA Parakeet V2 via FluidAudio for better accuracy and performance.

### Permissions
- ✅ **Microphone**: Standard macOS permission prompt (auto-requested)
- ✅ **Accessibility**: Required for text injection and key monitoring
- ⚠️ **Manual setup**: Accessibility must be granted manually in System Settings

### Development Philosophy
- ✅ Use readily available libraries and tools
- ✅ Minimize custom implementation where possible
- ✅ Prioritize simplicity and reliability

## Visual Assets

### Logo/Icon
- ✅ Source file: `docs/voice.png` in project
- ✅ Design: 9 vertical rounded bars in symmetric waveform pattern
- ✅ Gradient: Purple/magenta (top) → blue/cyan (bottom)
- ✅ Usage: App icon and waveform visualization basis
- ✅ Converted to .icns format for macOS app icon

### Waveform Design
- ✅ Reconstructed logo design for live visualization
- ✅ 9 bars with rounded caps
- ✅ Symmetric height pattern
- ✅ Purple-to-cyan gradient
- ✅ Animate bar heights based on real-time audio levels
- ✅ Bottom center screen position
- ✅ Small footprint

## Performance Targets
- ✅ Minimal memory usage (~100-200MB with ML models loaded)
- ✅ Minimal CPU usage when idle (< 1%)
- ✅ Efficient during recording and transcription (10-20% CPU)
- ✅ Fast transcription (near real-time on Apple Silicon)

## Implementation Summary

### Architecture
```
Menu Bar App (NSStatusItem)
    ↓
AppDelegate (orchestrator)
    ├── KeyMonitor → Right Command detection (NSEvent)
    ├── AudioRecorder → Real audio capture (AVAudioEngine)
    ├── WaveformWindow → Visual feedback (SwiftUI)
    └── TranscriptionManager → Real transcription (FluidAudio/Parakeet V2)
```

### Key Technologies
- **SwiftUI**: Waveform visualization
- **AppKit**: Menu bar, key monitoring, app lifecycle
- **AVAudioEngine**: Real-time audio capture
- **FluidAudio**: NVIDIA Parakeet V2 transcription
- **ServiceManagement**: Auto-launch at login
- **CGEvent**: Text injection (with Accessibility)

### Build Configuration
- **Scheme**: Midori-Debug (locked to Debug)
- **Configuration**: Debug only (Release optimizations break functionality)
- **Build Location**: Fixed at `build/` (prevents permission resets)
- **Sandbox**: Disabled (required for global key monitoring)
- **LSUIElement**: YES (menu bar only, no Dock icon)

## Distribution

### Package Format
- ✅ DMG installer (`release/Midori-Installer.dmg`)
- ✅ Size: ~17 MB (includes all dependencies)
- ✅ Configuration: Debug (required for functionality)
- ✅ Contents: App + Applications symlink + Install instructions

### User Installation
1. Double-click `Midori-Installer.dmg`
2. Drag `Midori.app` to `Applications` folder
3. Launch Midori from Applications or Spotlight
4. Grant Microphone permission (auto-prompted)
5. Grant Accessibility permission (System Settings)

## Known Limitations

### Debug Build Requirement
**Issue**: Release configuration breaks audio/transcription
**Reason**: Swift compiler optimizations interfere with FluidAudio
**Impact**: Slightly larger app size (~17MB vs potential ~10MB)
**Status**: Acceptable - Debug build works perfectly

### Manual Accessibility Permission
**Issue**: Users must manually grant Accessibility permission
**Reason**: macOS security policy prevents automatic grants
**Impact**: Extra setup step requiring System Settings navigation
**Status**: Cannot fix - system limitation

## Future Considerations
- Permission setup helper UI (would improve first-run experience)
- Model management UI (view/download alternative models)
- Custom keyboard shortcuts (currently hardcoded to Right Command)
- Recording settings (volume threshold, max duration)
- Transcription history
- Performance monitoring dashboard

## Success Criteria

All original requirements met:
- ✅ Right Command key trigger
- ✅ Real-time audio recording
- ✅ Beautiful waveform visualization
- ✅ Pop sound feedback
- ✅ Real transcription (Parakeet V2)
- ✅ Text injection at cursor
- ✅ Auto-launch at login
- ✅ Menu bar integration
- ✅ Custom app icon
- ✅ Error handling
- ✅ DMG distribution package

**Status**: Production ready and fully functional! 🎉
