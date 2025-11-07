# Midori - Future Enhancements

## Status: ✅ Production Ready

The app is complete and fully functional with all core features implemented. This document lists potential future enhancements and improvements.

## Completed Features ✅

### Core Functionality
- ✅ Menu bar app infrastructure
- ✅ Right Command key monitoring (global)
- ✅ Real audio recording (AVAudioEngine)
- ✅ Real transcription (NVIDIA Parakeet V2)
- ✅ Animated waveform visualization (9 bars, gradient)
- ✅ Pop sound feedback
- ✅ Text injection at cursor (Accessibility + Pasteboard)
- ✅ Auto-launch at login (ServiceManagement)
- ✅ Custom app icon (gradient waveform)
- ✅ DMG installer for distribution
- ✅ Error handling and user feedback
- ✅ Fixed build location (stable permissions)

## Potential Future Enhancements

### High Priority

#### 1. Permission Setup Helper
**Status**: Would improve first-run experience

**Description**:
Add a friendly first-run dialog that:
- Detects missing permissions (Microphone, Accessibility)
- Explains why each permission is needed
- Provides "Open Settings" button that opens the exact System Settings pane
- Shows visual step-by-step instructions

**Benefits**:
- Easier for non-technical users
- Reduces support questions
- Better first impression

**Implementation**:
- Create `PermissionHelper.swift`
- Check permissions on launch
- Show SwiftUI dialog if permissions missing
- Use `NSWorkspace` to open specific System Settings panes

---

#### 2. Model Management UI
**Status**: Currently uses default Parakeet V2 model

**Description**:
Add preferences window for:
- Viewing current model
- Downloading alternative models (if available)
- Showing model size and performance characteristics
- Clearing model cache

**Benefits**:
- More control for advanced users
- Better disk space management
- Future-proof for model updates

**Implementation**:
- Create `PreferencesWindow.swift`
- Add "Preferences..." menu item
- Show model info and download options

---

### Medium Priority

#### 3. Custom Keyboard Shortcuts
**Status**: Currently hardcoded to Right Command

**Description**:
Allow users to customize the recording hotkey:
- Change from Right Command to other keys
- Support modifier combinations (Shift+Option+R, etc.)
- Prevent conflicts with system shortcuts

**Benefits**:
- Accessibility for different keyboard layouts
- User preference flexibility
- Better ergonomics for some users

**Implementation**:
- Add hotkey recorder control
- Store in UserDefaults
- Update KeyMonitor to use custom key

---

#### 4. Recording Settings
**Status**: Currently uses automatic detection

**Description**:
Add configurable recording settings:
- Volume threshold for start detection
- Maximum recording duration
- Audio quality settings
- Silence detection sensitivity

**Benefits**:
- Better control in noisy environments
- Prevent accidental long recordings
- Optimize for user's environment

**Implementation**:
- Add settings to Preferences window
- Store in UserDefaults
- Update AudioRecorder to use settings

---

### Low Priority (Polish)

#### 5. Advanced Waveform Options
- Color customization (change gradient colors)
- Different visualization styles (bars, wave, circle)
- Size adjustment
- Opacity control

#### 6. Transcription History
- Keep history of recent transcriptions
- Allow re-use of previous transcriptions
- Search through history
- Export to text file

#### 7. Language Selection
- Support for multiple languages (if Parakeet supports)
- Auto-detect language
- Per-app language preferences

#### 8. Performance Monitoring
- Show transcription time in console
- Memory usage stats
- CPU usage monitoring
- Performance tips

#### 9. Export/Import Settings
- Export preferences to file
- Import settings from backup
- Share settings between machines

#### 10. Statistics Dashboard
- Words transcribed today/week/month
- Most active apps
- Average recording duration
- Accuracy metrics

---

## Known Limitations (Won't Fix)

### Debug Build Requirement
**Issue**: Release configuration breaks audio/transcription functionality
**Reason**: Swift compiler optimizations interfere with FluidAudio
**Impact**: Slightly larger app size (~17MB vs potential ~10MB)
**Status**: Won't fix - Debug build works perfectly

### Manual Permissions
**Issue**: Users must manually grant Accessibility permission
**Reason**: macOS security policy prevents automatic permission grants
**Impact**: Extra setup step for users
**Status**: Can't fix - system limitation

---

## Testing Checklist for Future Features

### Before Adding New Features
- [ ] Ensure backwards compatibility
- [ ] Don't break existing functionality
- [ ] Test on clean macOS install
- [ ] Verify permissions still work
- [ ] Check memory usage doesn't increase significantly
- [ ] Test with Debug configuration only

---

## Architecture Notes for Future Development

### Adding New Features
1. Follow callback-based architecture
2. Keep managers separate and testable
3. Use UserDefaults for preferences
4. Add proper error handling
5. Include console logging with emoji markers
6. Test without breaking existing workflow

### Code Organization
```
midori/
├── midori/
│   ├── Core/                    # Existing core functionality
│   │   ├── midoriApp.swift
│   │   ├── KeyMonitor.swift
│   │   ├── AudioRecorder.swift
│   │   ├── TranscriptionManager.swift
│   │   ├── WaveformView.swift
│   │   └── WaveformWindow.swift
│   │
│   ├── Features/                # New features (future)
│   │   ├── PermissionHelper.swift
│   │   ├── PreferencesWindow.swift
│   │   └── HistoryManager.swift
│   │
│   └── Resources/
│       └── Assets.xcassets/
```

---

## Contributing Notes

This is a personal project, but if you want to add features:

1. **Test thoroughly** - Don't break the core workflow
2. **Keep it simple** - Match the minimal design philosophy
3. **Document changes** - Update all relevant docs
4. **Debug builds only** - Don't try to fix Release builds
5. **Follow patterns** - Use existing callback architecture

---

## Priority Recommendation

**Most Valuable Next Feature**: Permission Setup Helper
- Biggest user experience improvement
- Reduces friction for non-technical users
- Addresses main distribution challenge

**Technical Interest**: Custom Keyboard Shortcuts
- Interesting technical challenge
- Good user flexibility
- Doesn't require UI/UX design

**Nice to Have**: Model Management UI
- Future-proof for model updates
- Advanced user feature
- Low immediate value

---

## Current Status Summary

**Production Ready**: ✅
**Core Features**: 100% Complete
**Polish Features**: Optional enhancements listed above
**Distribution**: Ready to share (DMG available)

The app is feature-complete for its core purpose: voice-to-text transcription with the Right Command key.

All items in this document are **optional enhancements** that would make the app even better, but are not required for it to be useful and functional.
