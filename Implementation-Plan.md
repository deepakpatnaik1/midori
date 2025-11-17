# Implementation Plan

**Last Updated**: 2025-11-17

---

## Overview

This is a high-level, chunk-by-chunk plan to transform Midori from its current state to the vision described in Requirements.md.

**Philosophy**: Surgical precision. Keep what works, fix what's broken, add what's missing.

---

## Phase 1: Fix Stability & AirPods Support

**Goal**: Make the app rock solid and work with AirPods

**Branch**: `feature/airpods-fix`

**Chunks**:

### Chunk 1.1: Add AirPods Device Detection
- Implement device enumeration in AudioRecorder
- Detect when AirPods are connected
- Automatically select AirPods microphone as input device

### Chunk 1.2: Fix Audio Engine Lifecycle
- Ensure proper cleanup when stopping recording
- Add error handling for engine start failures
- Fix potential race conditions in engine state

### Chunk 1.3: Fix Memory Leaks
- Review buffer storage strategy
- Implement buffer limits or pooling
- Use Instruments to verify no leaks

### Chunk 1.4: Test Pop Sound with AirPods
- Verify pop sound routing works with AirPods
- Ensure audio output goes to correct device

**Success Criteria**:
- ✅ AirPods microphone works automatically
- ✅ No crashes in 24-hour test
- ✅ Pop sound plays reliably with AirPods
- ✅ No memory leaks

---

## Phase 2: Replace Transcription Engine

**Goal**: Switch from Parakeet V2 to Apple Speech Framework

**Branch**: `feature/apple-speech`

**Chunks**:

### Chunk 2.1: Create AppleSpeechManager
- New file: `AppleSpeechManager.swift`
- Implement `SFSpeechRecognizer` setup
- Implement basic transcription (no custom vocab yet)
- Handle audio buffer processing
- Return transcribed text via callback

### Chunk 2.2: Integrate with AppDelegate
- Replace `TranscriptionManager` with `AppleSpeechManager`
- Update initialization in `applicationDidFinishLaunching`
- Update transcription call in `stopRecording()`
- Keep same callback interface

### Chunk 2.3: Test & Compare
- Test transcription accuracy
- Compare speed vs Parakeet V2
- Verify no regressions

### Chunk 2.4: Remove FluidAudio
- Delete `TranscriptionManager.swift`
- Delete `FluidAudio-Local/` directory
- Remove from Package.swift dependencies
- Clean build and verify

**Success Criteria**:
- ✅ Transcription works with Apple Speech
- ✅ Accuracy equal or better than Parakeet
- ✅ Speed acceptable (< 5s for 1min audio)
- ✅ No FluidAudio dependency

---

## Phase 3: UI/UX Improvements

**Goal**: Match the desired user experience exactly

**Branch**: `feature/ux-improvements`

**Chunks**:

### Chunk 3.1: Fix Waveform Base State
- Modify `WaveformView.swift`
- Add true base state (dots in straight line)
- Show base state when `audioLevel == 0.0`
- Return to base state on pause

### Chunk 3.2: Fix Timing
- Change delay from 1.0s to 0.5s in AppDelegate
- Move pop sound to play after 0.5s delay (not immediately)
- Test timing feels right

### Chunk 3.3: Add About Dialog
- Create `AboutWindow.swift`
- Standard macOS about dialog
- Show: Midori, version, © 2025 Deepak Patnaik
- Add "About" menu item in AppDelegate

### Chunk 3.4: Fix Restart Mechanism
- Replace deprecated `launchPath` with modern API
- Test restart works properly

### Chunk 3.5: Simplify State Management (Optional)
- Review nested async operations in AppDelegate
- Simplify if possible without breaking functionality
- Only if time permits and seems safe

**Success Criteria**:
- ✅ Waveform appears instantly in base state
- ✅ Double pop plays at exactly 0.5s
- ✅ Waveform dances responsively
- ✅ About dialog works
- ✅ Restart works
- ✅ UX matches Requirements.md

---

## Phase 4: Custom Dictionary Training

**Goal**: Implement custom vocabulary learning

**Branch**: `feature/custom-dictionary`

**Chunks**:

### Chunk 4.1: Create CustomLanguageModelManager
- New file: `CustomLanguageModelManager.swift`
- Store training audio samples
- Store ground truth text corrections
- Build `SFCustomLanguageModelData`
- Call `prepareCustomLanguageModel()`
- Save/load trained models from disk

### Chunk 4.2: Create Training UI - Data Model
- Create data structures for training phrases
- Each phrase has: multiple audio samples + ground truth
- Persistence layer (save/load training data)

### Chunk 4.3: Create Training UI - Window & Layout
- New file: `TrainingWindow.swift`
- Create NSWindow for training
- Basic layout structure

### Chunk 4.4: Create Training UI - Recording Interface
- New file: `TrainingView.swift`
- Plus button to add new phrase
- List of training phrases
- Record button for each sample
- Show live transcription
- Mini plus to add more samples
- Text field for ground truth
- Save/Delete buttons

### Chunk 4.5: Integrate Recording into Training
- Reuse AudioRecorder for training samples
- Store audio buffers for training
- Show what model currently transcribes

### Chunk 4.6: Build Custom Language Model
- Trigger model building from training data
- Show progress indicator (can take time)
- Save model file location

### Chunk 4.7: Integrate with AppleSpeechManager
- Load custom language model
- Attach to speech recognition requests
- Verify custom words are recognized

### Chunk 4.8: Add Train Menu Item
- Add "Train" button to menu bar in AppDelegate
- Opens training window
- Test end-to-end flow

**Success Criteria**:
- ✅ Train menu opens training UI
- ✅ Can record multiple samples of phrase
- ✅ Can provide ground truth text
- ✅ Model builds successfully
- ✅ "Claude" transcribes correctly after training
- ✅ Trained model persists across restarts

---

## Phase 5: Polish & Release

**Goal**: Final polish and prepare for daily use

**Branch**: `feature/polish`

**Chunks**:

### Chunk 5.1: App Icon
- Verify app icon matches waveform design
- Ensure icon appears in Applications folder
- Test Spotlight search finds app

### Chunk 5.2: Menu Bar Icon
- Consider updating menu bar icon to match waveform
- Or keep current waveform symbol

### Chunk 5.3: Error Handling Polish
- Review all error cases
- Ensure user-friendly error messages
- No silent failures

### Chunk 5.4: Documentation Update
- Update Requirements.md status (mark features as complete)
- Update Architecture.md to reflect final state
- Clean up any outdated documentation

### Chunk 5.5: Final Testing
- Test all features end-to-end
- Test edge cases (no mic, no accessibility, etc.)
- 24-hour stability test
- Memory leak test with Instruments

### Chunk 5.6: Build Release Version
- Switch from Debug to Release build
- Test Release build works (no Parakeet constraints anymore)
- Create new DMG installer if needed

**Success Criteria**:
- ✅ All features working perfectly
- ✅ No crashes, no bugs
- ✅ Ready for daily use
- ✅ Clean, maintainable codebase

---

## Estimated Timeline

### Phase 1: Fix Stability & AirPods
**Complexity**: High (audio subsystem is tricky)
**Estimated Time**: 2-4 hours of focused work
**Risk**: Medium-High

### Phase 2: Replace Transcription Engine
**Complexity**: Medium (new API but well documented)
**Estimated Time**: 2-3 hours
**Risk**: Medium

### Phase 3: UI/UX Improvements
**Complexity**: Low-Medium (mostly tweaks)
**Estimated Time**: 1-2 hours
**Risk**: Low

### Phase 4: Custom Dictionary Training
**Complexity**: Medium-High (most code to write)
**Estimated Time**: 4-6 hours
**Risk**: Medium

### Phase 5: Polish & Release
**Complexity**: Low (cleanup and testing)
**Estimated Time**: 1-2 hours
**Risk**: Low

**Total Estimated Time**: 10-17 hours of focused development

---

## Dependencies Between Phases

```
Phase 1 (Stability)
    ↓
Phase 2 (Apple Speech) ← Must have stable audio first
    ↓
Phase 3 (UX) ← Can start anytime, but easier after Phase 2
    ↓
Phase 4 (Custom Dictionary) ← Requires Phase 2 complete
    ↓
Phase 5 (Polish)
```

**Phases 1 and 2 are sequential** (must be done in order)
**Phase 3 can be done anytime** (independent of transcription)
**Phase 4 requires Phase 2** (needs Apple Speech Framework)

---

## Parallelization Opportunities

If we want to go faster, we can work on multiple phases concurrently:

### Scenario 1: Slow & Safe
- Do phases strictly in order
- Test thoroughly between each phase
- Lowest risk

### Scenario 2: Moderate Parallelization
- Phase 1 + Phase 3 can be done together (different files)
- Then Phase 2
- Then Phase 4
- Moderate risk

### Scenario 3: Aggressive Parallelization
- Phase 1 + Phase 3 concurrently
- Phase 2 + Phase 4.1-4.2 concurrently (build UI while transcription is in progress)
- Higher risk, faster completion

**Recommendation**: Start with Scenario 1 (slow & safe) for Phase 1. If it goes smoothly, consider parallelization for later phases.

---

## Current Status

**Completed Phases**: None (planning complete)

**Next Action**: Begin Phase 1, Chunk 1.1 (Add AirPods Device Detection)

**Current Branch**: `main`

**Stable Build**: Working (except AirPods and custom dictionary)

---

## Notes

- Each chunk should be a single focused change
- Commit after each chunk completes
- Test after each chunk if possible
- Don't move to next chunk until current chunk works
- User can continue using stable app during all development
- Rollback to main anytime if things break

---

## Quick Reference: What Gets Modified

### Phase 1
- ✏️ `AudioRecorder.swift` (major fixes)

### Phase 2
- ➕ `AppleSpeechManager.swift` (new)
- ✏️ `midoriApp.swift` (minor - swap managers)
- ❌ `TranscriptionManager.swift` (delete)
- ❌ `FluidAudio-Local/` (delete)

### Phase 3
- ✏️ `WaveformView.swift` (minor - base state)
- ✏️ `midoriApp.swift` (minor - timing, menu)
- ➕ `AboutWindow.swift` (new)

### Phase 4
- ➕ `CustomLanguageModelManager.swift` (new)
- ➕ `TrainingWindow.swift` (new)
- ➕ `TrainingView.swift` (new)
- ✏️ `midoriApp.swift` (minor - Train menu item)
- ✏️ `AppleSpeechManager.swift` (minor - load custom model)

### Phase 5
- 📝 Documentation updates
- 🧪 Testing
- 📦 Release build

**Legend**:
- ✏️ Modify existing file
- ➕ Create new file
- ❌ Delete file
- 📝 Documentation
- 🧪 Testing
- 📦 Build/Release

---

## Let's Build This!

Ready to start Phase 1 when you are. Remember: your current app keeps running until you're ready to test the new version.
