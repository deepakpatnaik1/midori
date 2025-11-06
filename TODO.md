# Midori - Production TODO List

## Status: Development Complete ✅ | Production Ready 🚧

The app is fully functional with mock data. To move to production, complete the following tasks.

## High Priority (Required for Production)

### 1. whisper.cpp Integration
**Status**: 🚧 Structure ready, needs implementation

**Steps**:
1. Add whisper.cpp dependency
   - Option A: Swift Package Manager (if available)
   - Option B: Direct integration of C++ library with bridging header
   - Option C: Use pre-built whisper.cpp dynamic library

2. Implement real transcription in [TranscriptionManager.swift](midori/TranscriptionManager.swift)
   - Replace `realTranscribe()` mock implementation
   - Convert audio data to whisper.cpp format (16kHz, 16-bit PCM)
   - Call whisper.cpp API
   - Extract transcribed text

3. Download Whisper model on first launch
   - Implement `downloadModel()` in TranscriptionManager
   - Store in user-specified directory (per requirements)
   - Start with "small" model as specified

**Files to modify**:
- `midori/TranscriptionManager.swift` - Lines 60-68 (realTranscribe)
- `midori/TranscriptionManager.swift` - Lines 72-77 (downloadModel)

**Reference**:
- whisper.cpp repo: https://github.com/ggerganov/whisper.cpp
- Model download: Hugging Face or official Whisper models

---

### 2. Real Audio Recording
**Status**: 🚧 Code ready, gated behind DEBUG flag

**Steps**:
1. Test real audio recording path
   - Build in Release mode or remove `#if DEBUG` blocks
   - Grant microphone permission when prompted
   - Verify audio capture works

2. Test audio buffer extraction
   - Implement `getAudioData()` properly in [AudioRecorder.swift](midori/AudioRecorder.swift)
   - Return proper audio format for whisper.cpp

**Files to modify**:
- `midori/AudioRecorder.swift` - Lines 32-37 (remove DEBUG blocks)
- `midori/AudioRecorder.swift` - Lines 51-56 (getAudioData implementation)

---

### 3. Text Injection Testing
**Status**: 🚧 Code ready, needs accessibility permission

**Steps**:
1. Grant accessibility permission
   ```bash
   open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
   ```

2. Test text injection in various apps:
   - TextEdit
   - Terminal
   - Slack
   - VS Code
   - Notes
   - Web browsers (Chrome, Safari)

3. Verify cursor position preservation
4. Test with existing clipboard contents

**Files to verify**:
- `midori/midoriApp.swift` - Lines 129-176 (injectText)

---

## Medium Priority (UX Improvements)

### 4. Auto-Launch at Login
**Status**: ❌ Not implemented

**Steps**:
1. Add SMLoginItemSetEnabled to project
2. Add menu item to toggle auto-launch
3. Persist preference in UserDefaults
4. Test launch behavior after restart

**New code needed**:
- Add launch agent configuration
- Update menu bar menu with toggle

---

### 5. Model Management
**Status**: ❌ Not implemented

**Steps**:
1. Create preferences window/dialog
2. Allow user to specify model storage directory
3. Add ability to download different models (tiny, base, small, medium)
4. Show model file size and estimated performance
5. Add model switching capability

**New files needed**:
- `midori/PreferencesWindow.swift` (or similar)

---

### 6. App Icon
**Status**: ❌ Using system icon

**Steps**:
1. Convert [docs/voice.png](docs/voice.png) to .icns format
   ```bash
   # Use iconutil or third-party tool
   ```
2. Add to Assets.xcassets
3. Update app icon reference

---

## Low Priority (Polish)

### 7. Error Recovery
- Add retry logic for failed transcriptions
- Show user-friendly error messages
- Add "Report Issue" option in error dialogs

### 8. Performance Optimization
- Profile memory usage during long recordings
- Optimize waveform animation frame rate if needed
- Test with different Whisper models

### 9. Preferences/Settings
- Custom keyboard shortcut (instead of Right Command)
- Volume threshold for recording
- Language selection (currently English only)
- Waveform color customization

### 10. Status Feedback
- Show recording duration in menu bar
- Add keyboard shortcut indicator
- Show transcription progress percentage

---

## Testing Checklist

### Before Production Release
- [ ] Real audio recording works
- [ ] whisper.cpp transcription produces accurate results
- [ ] Text injection works in all major apps
- [ ] App survives system restart
- [ ] Auto-launch works (if implemented)
- [ ] Permissions prompt properly
- [ ] No memory leaks during extended use
- [ ] CPU usage acceptable during transcription
- [ ] Error messages are user-friendly

---

## Documentation Updates Needed

### When Production Ready
- [ ] Update README with installation instructions
- [ ] Add user guide with screenshots
- [ ] Document model download process
- [ ] Add troubleshooting section for common issues
- [ ] Create demo video

---

## Current Development Status

### ✅ Complete
- Menu bar app infrastructure
- Right Command key monitoring
- Audio recording (mock data)
- Waveform visualization
- User feedback sequence (pop sound, dots)
- Text injection (accessibility)
- Error handling
- Build system automation
- Development workflow

### 🚧 In Progress
- whisper.cpp integration (structure ready)
- Real audio recording (code ready, needs testing)
- Accessibility permission testing

### ❌ Not Started
- Auto-launch at login
- Model management UI
- App icon conversion
- Preferences window
- Advanced features

---

## How to Get Started on Production Tasks

### Option 1: whisper.cpp Integration
```bash
# Research whisper.cpp Swift integration
# Look for existing Swift packages or create bridging header
# Start with TranscriptionManager.swift modifications
```

### Option 2: Real Audio Testing
```bash
# Remove DEBUG flags from AudioRecorder.swift
# Build and test with microphone permission
# Verify audio buffer extraction
```

### Option 3: Accessibility Testing
```bash
# Grant accessibility permission
# Test text injection in various apps
# Document any edge cases or issues
```

---

## Notes

- **Mock data approach** followed best practices to avoid permission issues during development
- **Architecture is production-ready** - just needs real implementations
- **All core functionality works** end-to-end with mock data
- **Code is well-documented** with TODO comments where production work is needed

---

## Priority Recommendation

**Start with whisper.cpp integration** - This is the most complex task and core to the app's functionality. Once transcription works, the rest is polish and testing.

**Next**: Real audio recording and text injection testing

**Finally**: UX improvements like auto-launch and preferences
