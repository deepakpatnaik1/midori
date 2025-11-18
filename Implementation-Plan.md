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

## Phase 2: Implement Correction Layer

**Goal**: Add post-processing correction for custom vocabulary

**Branch**: `feature/midori-v1` (current branch)

---

### **LEARNINGS FROM FIRST ATTEMPT (2025-11-18)**

**Mistake**: Split the core correction logic into artificial chunks (basic replacement → case preservation → word boundaries). This created a broken intermediate state.

**Key Insight**: The correction logic must be built as a complete unit because:
- Simple `replacingOccurrences()` without word boundaries is dangerously broken ("clawed" matches "unclawed")
- Case preservation isn't a "nice to have" - it's essential ("CLAWED" should become "CLAUDE", not "Claude")
- These features are interdependent and can't be meaningfully separated

**Corrected Approach**: Build the core correction engine in one chunk with all essential features, then add persistence and integration separately.

---

**Chunks** (REVISED):

### Chunk 2.1: Create Complete CorrectionLayer Core
- New file: `CorrectionLayer.swift`
- Implement dictionary-based text replacement WITH:
  - ✅ Word boundary detection (regex with `\b`)
  - ✅ Case-insensitive matching
  - ✅ Case preservation (all-caps → all-caps, capitalized → capitalized)
  - ✅ Multi-word phrase support
- Basic API: `addCorrection()`, `removeCorrection()`, `getAllCorrections()`, `clearAll()`, `apply(to:)`
- **Lines**: ~120-150 lines
- **Test inline**: "clawed" → "Claude", "CLAWED" → "CLAUDE", "unclawed" stays "unclawed"

### Chunk 2.2: Add Persistence
- Store corrections dictionary to disk (UserDefaults with JSON encoding)
- Load corrections on init
- Save corrections when modified
- **Lines**: +30 lines
- **Test**: Add correction, restart app, verify it persists

### Chunk 2.3: Integrate with AppDelegate
- Create `CorrectionLayer` instance in AppDelegate
- Apply corrections after `transcriptionManager.transcribe()` completes
- Insert between transcription and text injection
- **Lines**: ~10 lines modified in midoriApp.swift
- **Test**: Add correction programmatically, record audio, verify correction works

### Chunk 2.4: End-to-End Testing
- Test multiple corrections
- Test edge cases (overlapping phrases, punctuation)
- Test persistence across restarts
- Verify no performance impact

**Success Criteria**:
- ✅ CorrectionLayer applies corrections accurately
- ✅ Word boundaries work (doesn't break compound words)
- ✅ Case preservation works correctly
- ✅ Corrections persist across app restarts
- ✅ Multi-word phrase corrections work
- ✅ Integration with transcription pipeline works seamlessly

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

## Phase 4: Custom Dictionary UI

**Goal**: Implement UI for managing corrections

**Branch**: `feature/custom-dictionary-ui`

**Chunks**:

### Chunk 4.1: Create Training UI - Data Model
- Create data structures for corrections
- Each correction has: sample transcription + correct text
- Persistence layer (integrate with CorrectionLayer)

### Chunk 4.2: Create Training UI - Window & Layout
- New file: `TrainingWindow.swift`
- Create NSWindow for training
- Basic layout structure

### Chunk 4.3: Create Training UI - Correction Interface
- New file: `TrainingView.swift`
- Plus button to add new correction
- List of corrections
- Record button to capture sample
- Show what Parakeet transcribes
- Text field for correct text
- Save/Delete buttons

### Chunk 4.4: Integrate Recording into Training
- Reuse AudioRecorder for test samples
- Show live transcription from Parakeet
- Let user see what needs correcting

### Chunk 4.5: Connect to CorrectionLayer
- Save new corrections to CorrectionLayer
- Update corrections when edited
- Delete corrections when removed
- Trigger CorrectionLayer reload

### Chunk 4.6: Add Train Menu Item
- Add "Train" button to menu bar in AppDelegate
- Opens training window
- Test end-to-end flow

**Success Criteria**:
- ✅ Train menu opens training UI
- ✅ Can add new corrections easily
- ✅ Can see what Parakeet transcribes
- ✅ Can provide correct text
- ✅ "Claude" corrects properly after adding
- ✅ Corrections persist across restarts

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

### Phase 2: Implement Correction Layer
**Complexity**: Low (simple string processing)
**Estimated Time**: 1-2 hours
**Risk**: Low

### Phase 3: UI/UX Improvements
**Complexity**: Low-Medium (mostly tweaks)
**Estimated Time**: 1-2 hours
**Risk**: Low

### Phase 4: Custom Dictionary UI
**Complexity**: Medium (UI development)
**Estimated Time**: 3-4 hours
**Risk**: Low-Medium

### Phase 5: Polish & Release
**Complexity**: Low (cleanup and testing)
**Estimated Time**: 1-2 hours
**Risk**: Low

**Total Estimated Time**: 8-14 hours of focused development

---

## Dependencies Between Phases

```
Phase 1 (Stability)
    ↓
Phase 2 (Correction Layer) ← Can start after Phase 1
    ↓
Phase 3 (UX) ← Can start anytime, independent
    ↓
Phase 4 (Custom Dictionary UI) ← Requires Phase 2 complete
    ↓
Phase 5 (Polish)
```

**Phase 1 must be done first** (foundation for stability)
**Phase 2 and 3 can be done in parallel** (different files, independent)
**Phase 4 requires Phase 2** (needs CorrectionLayer functionality)

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
- Phase 2 + Phase 4.1-4.2 concurrently (build UI skeleton while correction layer is in progress)
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
- ➕ `CorrectionLayer.swift` (new)
- ✏️ `midoriApp.swift` (minor - integrate correction layer)

### Phase 3
- ✏️ `WaveformView.swift` (minor - base state)
- ✏️ `midoriApp.swift` (minor - timing, menu)
- ➕ `AboutWindow.swift` (new)

### Phase 4
- ➕ `TrainingWindow.swift` (new)
- ➕ `TrainingView.swift` (new)
- ✏️ `midoriApp.swift` (minor - Train menu item)
- ✏️ `CorrectionLayer.swift` (minor - UI integration)

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
