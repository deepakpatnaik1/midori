# Midori - Architecture Documentation

**Last Updated**: 2025-11-17

---

## Current Architecture (AS-IS)

### High-Level Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      macOS Menu Bar                         │
│                    (NSStatusItem)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   AppDelegate                               │
│              (Central Orchestrator)                         │
│                                                             │
│  • State Management (isRecording, timers)                   │
│  • Lifecycle Management                                     │
│  • Component Coordination                                   │
└─┬───────┬────────┬───────────┬──────────────────────────────┘
  │       │        │           │
  ▼       ▼        ▼           ▼
┌────┐ ┌────┐  ┌─────┐  ┌──────────┐
│Key │ │Audio│  │Wave │  │Transcribe│
│Mon │ │Rec  │  │form │  │Manager   │
└────┘ └────┘  └─────┘  └──────────┘
```

---

### Component Breakdown

#### 1. **midoriApp.swift** + **AppDelegate**
**Lines of Code**: 350 lines
**Role**: Central orchestrator and application entry point

**Current Responsibilities**:
- App lifecycle management
- Menu bar setup (status item, menu items)
- Right Command key press/release handling
- Recording state management (bulletproof state machine)
- Timer management (1-second delay before recording)
- Pop sound playback (dual pop with 0.15s delay)
- Text injection via pasteboard + Cmd+V
- Launch at login management (ServiceManagement)
- Restart/Quit functionality

**Key State Variables**:
```swift
private var isRecording = false
private var recordingStartTimer: DispatchWorkItem?
private let stateQueue = DispatchQueue(label: "com.midori.stateQueue")
```

**Current Flow**:
1. User presses Right Command → `handleRightCommandKey(isPressed: true)`
2. `initiateRecording()` → Creates 1-second timer
3. Timer fires → `startRecording()`
   - Plays dual pop sound (0.15s apart)
   - Shows waveform
   - Starts audio recording
4. User releases Right Command → `handleRightCommandKey(isPressed: false)`
5. `initiateStop()` → `stopRecording()`
   - Stops recording
   - Hides waveform
   - Gets audio data
   - Calls transcription
   - Injects text at cursor

**Issues**:
- ⚠️ Complex nested async operations (stateQueue → main → stateQueue)
- ⚠️ 1-second delay hardcoded (should be 0.5s per requirements)
- ⚠️ Pop sound plays immediately on recording start (should wait 0.5s)
- ⚠️ No "About" or "Train" menu items
- ⚠️ Restart logic uses deprecated `launchPath` (line 340)

---

#### 2. **KeyMonitor.swift**
**Lines of Code**: 69 lines
**Role**: Global keyboard monitoring for Right Command key

**Current Implementation**:
- Uses `NSEvent` global and local monitors
- Detects Right Command key (keyCode 54)
- Callback-based: `onRightCommandPressed: ((Bool) -> Void)?`
- State tracking: `isRightCommandPressed`
- Works in background (no Accessibility permission needed for detection)

**Key Code**:
```swift
globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)
localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged)
```

**Verdict**: ✅ **PERFECT - NO CHANGES NEEDED**

---

#### 3. **AudioRecorder.swift**
**Lines of Code**: 239 lines
**Role**: Audio capture using AVAudioEngine

**Current Implementation**:
- Uses `AVAudioEngine` + `AVAudioInputNode`
- Captures at native device sample rate (typically 48kHz)
- Buffers audio in `[AVAudioPCMBuffer]` array
- Real-time audio level calculation (RMS)
- Callback: `onAudioLevelUpdate: ((Float) -> Void)?`

**Key Issues**:
```swift
// Line 121: "Don't try to override the device - just use whatever is default"
let format = input.outputFormat(forBus: 0)
```

**Problems**:
- ❌ No device selection logic - uses system default
- ❌ `findBuiltInMicrophone()` function exists (lines 136-204) but **never called**
- ❌ AirPods not detected or switched to
- ⚠️ Potential memory leaks in buffer storage (`recordedBuffers.append(copy)`)
- ⚠️ Engine lifecycle might not be properly cleaned up
- ⚠️ No error handling for engine.start() failures beyond logging

**What Works**:
- ✅ Audio level calculation for waveform is accurate
- ✅ Buffer copying prevents data corruption
- ✅ RMS calculation is solid (lines 228-236)

---

#### 4. **TranscriptionManager.swift**
**Lines of Code**: 147 lines
**Role**: Transcription using FluidAudio + NVIDIA Parakeet V2

**Current Implementation**:
```swift
import FluidAudio

private var asrManager: AsrManager?

// Async initialization
let models = try await AsrModels.downloadAndLoad(version: .v2)
asrManager = AsrManager(config: .default)
try await asrManager?.initialize(models: models)

// Transcription
let samples = try convertAudioTo16kHzMono(audioData: audioData)
let result = try await manager.transcribe(samples)
```

**Audio Processing**:
- Extracts Float32 samples from raw audio data
- Downsamples 48kHz → 16kHz (3:1 ratio, simple stride)
- Feeds to Parakeet V2 CoreML model

**Issues**:
- ⚠️ Async initialization might not be ready on first use
- ⚠️ Simple downsampling (stride) - no proper resampling filter
- ⚠️ No custom vocabulary support (will need separate correction layer)
- ⚠️ External dependency (FluidAudio-Local package)
- ⚠️ 500ms sleep while waiting for init (line 81) is hacky

**Verdict**: ✅ **KEEP** - Parakeet V2 provides better quality than Apple Speech Framework

---

#### 5. **WaveformView.swift**
**Lines of Code**: 166 lines
**Role**: Beautiful 9-bar dancing visualization

**Current Implementation**:
- 9 bars with individual "personalities" (random max heights)
- Purple-to-cyan gradient (hot magenta → pure cyan)
- 60fps animation using Timer
- Sine wave patterns (3 waves combined per bar)
- Ultra-sensitive audio detection (0.03 threshold)
- Exponential amplification: `pow(intensity * 12.0, 0.65)`

**Visual Design**:
```swift
let barColors: [Color] = [
    Color(red: 1.0, green: 0.0, blue: 1.0),     // Hot Magenta (leftmost)
    ...
    Color(red: 0.0, green: 1.0, blue: 1.0)      // Pure Cyan (rightmost)
]
```

**Current Behavior**:
- Silent (intensity ≤ 0.03): Bars shrink to tiny circles (0.22-0.24 height)
- Speaking: Bars dance with unique frequencies, amplitudes based on personality

**Missing**:
- ❌ No true "base state" (dots in straight line) - they're slightly random
- ❌ Doesn't return to base state on pause (stays as small circles)

**Verdict**: ✅ **KEEP 95%** - Add true base state, preserve dancing logic

---

#### 6. **WaveformWindow.swift**
**Lines of Code**: 129 lines
**Role**: Floating window container for waveform

**Current Implementation**:
- NSPanel-based borderless window
- Bottom center positioning (100pt from bottom)
- `.floating` level (always on top)
- `.canJoinAllSpaces` (visible on all desktops)
- `ignoresMouseEvents = true` (click-through)
- ObservableObject pattern for state management

**State Management**:
```swift
class WaveformWindowState: ObservableObject {
    @Published var audioLevel: Float = 0.5
    @Published var showingWaveform = false
    @Published var showingDots = false
}
```

**Verdict**: ✅ **KEEP 100%** - Solid foundation, no changes needed

---

## Data Flow (AS-IS)

### Recording Flow

```
1. Right Command Pressed
   ↓
2. KeyMonitor detects (keyCode 54)
   ↓
3. Callback → AppDelegate.handleRightCommandKey(true)
   ↓
4. initiateRecording()
   • Cancel pending timers
   • Check if already recording
   • Create 1-second DispatchWorkItem timer
   ↓
5. [1 second passes]
   ↓
6. startRecording()
   • Set isRecording = true
   • Play pop sound 1
   • Play pop sound 2 (0.15s delay)
   • Show waveform window
   • Start audio recording
   ↓
7. Audio Recording Active
   • AVAudioEngine captures audio at 48kHz
   • installTap processes buffers
   • Calculate RMS audio level
   • Update waveform via callback
   • Store buffers in array
```

### Stop & Transcription Flow

```
8. Right Command Released
   ↓
9. KeyMonitor detects release
   ↓
10. Callback → AppDelegate.handleRightCommandKey(false)
    ↓
11. initiateStop()
    • Cancel timer if released < 1s (abort recording)
    • Check if actually recording
    ↓
12. stopRecording()
    • Set isRecording = false
    • Stop AVAudioEngine
    • Hide waveform
    • Get combined audio data from buffers
    ↓
13. TranscriptionManager.transcribe()
    • Wait for model initialization (if needed)
    • Extract Float32 samples from Data
    • Downsample 48kHz → 16kHz
    • Call Parakeet V2 model
    • Return transcribed text
    ↓
14. injectText()
    • Check AXIsProcessTrusted()
    • Copy text to NSPasteboard
    • Simulate Cmd+V keypresses via CGEvent
    • Text appears at cursor
```

---

## Current Dependencies

### External Packages
- **FluidAudio-Local** (local Swift package)
  - NVIDIA Parakeet V2 CoreML models
  - Automatic model downloading from HuggingFace
  - ~17MB total size

### Apple Frameworks
- **SwiftUI** - Waveform visualization
- **AppKit** - Menu bar, windows, events
- **AVFoundation** - Audio recording (AVAudioEngine)
- **CoreAudio** - Low-level audio device management
- **ServiceManagement** - Auto-launch at login
- **Carbon** - Key code constants
- **AudioToolbox** - System sounds (pop sound)

### Build Configuration
- **Scheme**: Midori-Debug
- **Configuration**: Debug only (Release breaks FluidAudio)
- **Build Location**: Fixed at `build/` (prevents permission resets)
- **Sandbox**: Disabled (required for key monitoring)
- **LSUIElement**: YES (menu bar only)

---

## Known Issues (AS-IS)

### Critical Issues

#### 1. Stability Problems
**Symptoms**: Frequent crashes, requires restarts
**Potential Causes**:
- AVAudioEngine lifecycle not properly managed
- Memory leaks in buffer storage (`recordedBuffers` array)
- Race conditions in nested async operations
- FluidAudio model initialization issues

#### 2. AirPods Support Broken
**Symptoms**: Must manually switch to Mac mic in System Settings
**Root Cause**: Line 121 in AudioRecorder.swift
```swift
// Don't try to override the device - just use whatever is default
let format = input.outputFormat(forBus: 0)
```
- No device detection logic implemented
- `findBuiltInMicrophone()` exists but unused

#### 3. Pop Sound Unreliable with AirPods
**Symptoms**: Pop sound doesn't play when using AirPods
**Root Cause**: Audio output routing issues when AirPods connected

### Minor Issues

#### 4. Timing Mismatches
- Current: 1-second delay before recording (line 138)
- Required: 0.5-second delay
- Current: Pop sound plays immediately
- Required: Pop sound plays after 0.5s

#### 5. Missing Features
- No "About" menu item
- No "Train" menu item (custom dictionary UI)
- No custom vocabulary support
- Waveform doesn't show true "base state" (dots in line)

---

## Future Architecture (SHOULD-BE)

### High-Level Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      macOS Menu Bar                         │
│         About | Train | Restart | Quit                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   AppDelegate                               │
│         (Simplified Orchestrator)                           │
│                                                             │
│  • Simplified State Machine                                 │
│  • 0.5s Delay Timer                                         │
│  • Menu Actions (About, Train)                              │
└─┬───────┬────────┬───────────┬──────────────────────────────┘
  │       │        │           │
  ▼       ▼        ▼           ▼
┌────┐ ┌────┐  ┌─────┐  ┌──────────────┐
│Key │ │Audio│  │Wave │  │Transcription │
│Mon │ │Rec  │  │form │  │Manager       │
│    │ │(UPD)│  │(UPD)│  │(Parakeet V2) │
└────┘ └────┘  └─────┘  └──────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │Correction       │
                    │Layer            │
                    │(NEW)            │
                    └─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │TrainingUI       │
                    │(NEW)            │
                    └─────────────────┘
```

---

### Component Changes

#### ✅ NO CHANGES - Keep As-Is

##### KeyMonitor.swift
- **Keep 100%** - Works perfectly
- No modifications needed

##### WaveformWindow.swift
- **Keep 100%** - Solid foundation
- No modifications needed

---

#### ⚠️ MINOR UPDATES - Preserve Core Logic

##### WaveformView.swift
**Changes Needed**:
1. Add true "base state" mode
   - When `audioLevel == 0.0`: Show dots in straight line (no randomness)
   - Use fixed small height (0.22) for all bars
2. Improve responsiveness to pauses
   - When audio drops below threshold, return to base state faster
3. Keep all dancing logic (sine waves, personalities, gradient)

**Lines to Modify**: ~10 lines
**Risk**: Low

##### midoriApp.swift (AppDelegate)
**Changes Needed**:
1. Update menu bar items
   - Add "About" button → Show standard macOS about dialog
   - Add "Train" button → Open training UI window
2. Fix timing
   - Change delay from 1.0s to 0.5s (line 138)
   - Move pop sound to play after 0.5s, not immediately
3. Simplify state management
   - Remove complex nested async if possible
   - Clean up timer cancellation logic
4. Fix restart mechanism
   - Replace deprecated `launchPath` with modern API

**Lines to Modify**: ~50 lines
**Risk**: Medium (state management is delicate)

---

#### 🔧 MAJOR FIXES - Preserve Interface

##### AudioRecorder.swift
**Changes Needed**:
1. Add proper device detection
   - Detect when AirPods are connected
   - Automatically switch to AirPods microphone
   - Use `findBuiltInMicrophone()` or equivalent for AirPods
2. Fix audio engine lifecycle
   - Ensure proper cleanup on stop
   - Handle engine failures gracefully
3. Fix potential memory leaks
   - Review buffer storage strategy
   - Consider buffer pool or limits

**Lines to Modify**: ~80 lines
**Risk**: High (audio subsystem is complex)

**Keep**:
- Audio level calculation (RMS)
- Callback interface (`onAudioLevelUpdate`)
- Buffer format (can still use native 48kHz)

---

#### 🔄 IMPROVEMENTS TO EXISTING COMPONENT

##### TranscriptionManager.swift (Keep with Parakeet V2)
**Keep**:
- FluidAudio import and usage
- Parakeet V2 model loading
- Audio downsampling to 16kHz
- Core transcription functionality

**Potential Improvements**:
- Better async initialization handling
- Improved resampling filter (replace simple stride)
- Error handling improvements

**Lines to Modify**: ~30 lines (optimizations)
**Risk**: Low

---

#### 🆕 NEW COMPONENTS

##### CorrectionLayer.swift
**Purpose**: Post-processing correction layer for Parakeet V2 transcriptions

**Responsibilities**:
- Store user-defined word/phrase corrections
- Apply corrections to transcribed text
- Simple string replacement or fuzzy matching
- Manage corrections dictionary on disk
- Load/save user corrections

**Implementation Approach**:
- Dictionary-based replacements (e.g., "clawed" → "Claude")
- Case-insensitive matching with case preservation
- Support for multi-word phrase corrections
- Persistent storage in user defaults or JSON file

**Lines to Write**: ~150 lines
**Risk**: Low

##### TrainingWindow.swift + TrainingView.swift
**Purpose**: SwiftUI UI for managing custom word corrections

**Features**:
- Plus button to add new correction
- Record button to capture sample (play icon)
- Show live transcription of what Parakeet thinks
- Text field for correct spelling/transcription
- Save/Delete buttons
- List of all corrections
- Simple interface for building correction dictionary

**Lines to Write**: ~250 lines
**Risk**: Low (UI is straightforward)

##### AboutWindow.swift
**Purpose**: Standard macOS about dialog

**Content**:
- App name: "Midori"
- Version number
- Copyright: "© 2025 Deepak Patnaik"
- App icon

**Lines to Write**: ~50 lines
**Risk**: Low

---

## Migration Strategy

### Phase 1: Fix Critical Stability Issues
**Goal**: Make app stable and reliable
**Focus**: AudioRecorder.swift

**Tasks**:
1. Add device detection for AirPods
2. Fix audio engine lifecycle
3. Review and fix memory leaks
4. Add error handling for edge cases

**Testing**: Verify no crashes, works with AirPods

### Phase 2: Implement Correction Layer
**Goal**: Add post-processing correction for custom vocabulary
**Focus**: Create CorrectionLayer.swift

**Tasks**:
1. Create new CorrectionLayer component
2. Implement dictionary-based text replacement
3. Integrate with TranscriptionManager output
4. Add persistence for user corrections
5. Test correction accuracy

**Testing**: Verify corrections work, test edge cases

### Phase 3: UI/UX Improvements
**Goal**: Match desired user experience
**Focus**: Timing, waveform, menu items

**Tasks**:
1. Update timing (0.5s delay, pop sound timing)
2. Add base state to waveform
3. Add About menu item + window
4. Fix restart mechanism
5. Test complete flow

**Testing**: Verify UX matches requirements exactly

### Phase 4: Custom Dictionary UI
**Goal**: Implement UI for managing corrections
**Focus**: TrainingWindow + TrainingView

**Tasks**:
1. Create TrainingWindow + TrainingView
2. Implement correction entry UI
3. Integrate with CorrectionLayer
4. Add "Train" menu item
5. Test end-to-end correction flow

**Testing**: Add "Claude" correction and verify it works

---

## Risk Assessment

### Low Risk Changes
- ✅ KeyMonitor (no changes)
- ✅ WaveformWindow (no changes)
- ✅ WaveformView base state (minor addition)
- ✅ About window (new, isolated)
- ✅ Menu bar updates (simple additions)

### Medium Risk Changes
- ⚠️ AppDelegate timing adjustments
- ⚠️ AppleSpeechManager (new but well-documented API)
- ⚠️ CustomLanguageModelManager (new but clear requirements)
- ⚠️ Training UI (new but standard SwiftUI)

### High Risk Changes
- 🔴 AudioRecorder device detection (complex audio subsystem)
- 🔴 AudioRecorder lifecycle fixes (potential for new bugs)
- 🔴 State management refactoring (if we simplify too much)

---

## Success Metrics

### Phase 1 Success
- [ ] Zero crashes in 24-hour test period
- [ ] AirPods microphone works without manual switching
- [ ] Pop sound plays reliably with AirPods
- [ ] No memory leaks (tested with Instruments)

### Phase 2 Success
- [ ] CorrectionLayer applies corrections accurately
- [ ] Corrections persist across app restarts
- [ ] Case-insensitive matching works
- [ ] Multi-word phrase corrections work

### Phase 3 Success
- [ ] Waveform appears instantly in base state
- [ ] Double pop plays exactly 0.5s after key press
- [ ] Waveform dances responsively, returns to base on pause
- [ ] About dialog shows correct info
- [ ] All UX matches Requirements.md

### Phase 4 Success
- [ ] Training UI functional and intuitive
- [ ] "Claude" corrects to proper spelling after adding correction
- [ ] Corrections persist across app restarts
- [ ] Multiple corrections work
- [ ] Can edit/delete corrections

---

## File Structure Changes

### Current Files (AS-IS)
```
midori/
├── midori/
│   ├── midoriApp.swift (350 lines)
│   ├── KeyMonitor.swift (69 lines)
│   ├── AudioRecorder.swift (239 lines)
│   ├── TranscriptionManager.swift (147 lines) ← KEEP
│   ├── WaveformView.swift (166 lines)
│   ├── WaveformWindow.swift (129 lines)
│   └── ContentView.swift (unused)
├── FluidAudio-Local/ ← KEEP (Parakeet V2 dependency)
└── Requirements.md
```

### Future Files (SHOULD-BE)
```
midori/
├── midori/
│   ├── midoriApp.swift (350 lines, ~50 modified)
│   ├── KeyMonitor.swift (69 lines, no changes)
│   ├── AudioRecorder.swift (239 lines, ~80 modified)
│   ├── TranscriptionManager.swift (147 lines, ~30 modified)
│   ├── CorrectionLayer.swift (150 lines) ← NEW
│   ├── WaveformView.swift (166 lines, ~10 modified)
│   ├── WaveformWindow.swift (129 lines, no changes)
│   ├── TrainingWindow.swift (100 lines) ← NEW
│   ├── TrainingView.swift (150 lines) ← NEW
│   └── AboutWindow.swift (50 lines) ← NEW
├── FluidAudio-Local/ ← KEEP
├── Requirements.md
└── Architecture.md (this file)
```

### Total Line Count
- **Current**: ~1100 lines of Swift
- **Future**: ~1350 lines of Swift
- **Net Change**: +250 lines (mostly new features)

---

## Dependencies Comparison

### Current (AS-IS) and Future (SHOULD-BE)
```swift
// Package.swift
dependencies: [
    .package(path: "./FluidAudio-Local")
]
```

**Apple frameworks**:
- SwiftUI - UI and waveform
- AppKit - Menu bar, windows, events
- AVFoundation - Audio recording
- ServiceManagement - Auto-launch at login

---

## Build Configuration

### Current Configuration
- Debug-only builds (Release breaks FluidAudio)
- App size (~17MB with Parakeet V2 models)
- External model downloads from HuggingFace
- FluidAudio dependency required

### No Changes Planned
- Continue using Debug builds
- Keep FluidAudio dependency
- Maintain existing build configuration

---

## Next Steps

1. Review this architecture document
2. Approve migration strategy
3. Begin Phase 1: Fix AudioRecorder stability
4. Test thoroughly before moving to Phase 2
5. Iterate through phases sequentially

Each phase should be completed, tested, and verified before moving to the next. This ensures we don't break working functionality while adding new features.
