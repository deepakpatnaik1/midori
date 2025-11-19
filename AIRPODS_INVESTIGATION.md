# AirPods Compatibility Investigation Report

**Branch**: `investigate-airpods-reliability`
**Date**: 2025-11-19
**Status**: Investigation Complete - No Code Changes

---

## Executive Summary

Midori's AirPods compatibility issues stem from **fundamental architectural limitations in macOS AVAudioEngine** when working with Bluetooth audio devices. The unreliability is not primarily caused by bugs in Midori's code, but rather by:

1. **Bluetooth protocol constraints** (A2DP vs HFP mode switching)
2. **AVAudioEngine's automatic device aggregation** behavior on macOS
3. **Missing audio route change handling** in the current implementation
4. **Sample rate mismatches** between AirPods (16kHz input) and expectations (48kHz)

This report details the root causes and provides actionable recommendations for improving reliability.

---

## Current Implementation Analysis

### AudioRecorder.swift (277 lines)

**What it does:**
- Creates a new `AVAudioEngine` instance on each recording
- Uses `inputNode.outputFormat(forBus: 0)` to get current device format
- Installs tap with 4096 buffer size
- Stores buffers in memory (up to 300 buffers = ~10 seconds)
- No device change monitoring
- No route change notifications
- No audio session management

**Key observations:**
```swift
// Line 184-221: startRealAudioRecording()
audioEngine = AVAudioEngine()
let format = input.outputFormat(forBus: 0)  // Takes whatever format device provides
input.installTap(onBus: 0, bufferSize: 4096, format: format) { ... }
try engine.start()
```

**Good practices:**
- ✅ Creates fresh engine per recording (avoids stale state)
- ✅ Uses device's native format (doesn't force 48kHz)
- ✅ Has error handling on engine.start()
- ✅ Cleans up tap before stopping engine

**Missing pieces:**
- ❌ No `AVAudioEngineConfigurationChange` notification listener
- ❌ No audio route change handling
- ❌ No recovery from engine failures mid-recording
- ❌ No validation that format is compatible with transcription
- ❌ No handling of device disconnection during recording

---

## Root Cause Analysis

### 1. The Bluetooth A2DP/HFP Mode Problem

**What happens:**
- AirPods have two modes:
  - **A2DP (Advanced Audio Distribution Profile)**: 48kHz stereo, output-only, high quality
  - **HFP (Hands-Free Profile)**: 16kHz mono, bidirectional (input + output), low quality

**The issue:**
- When an app uses the microphone, macOS switches AirPods from A2DP to HFP
- This causes:
  - Audio quality drops dramatically (48kHz → 16kHz)
  - Latency increases
  - Sound becomes "tinny" or "AM radio quality"
  - **Any playback happening at the time gets disrupted**

**Why it affects Midori:**
- When you press Right Command, Midori:
  1. Plays double pop sound (needs output)
  2. Starts microphone recording (needs input)
- AirPods must switch from A2DP → HFP to enable microphone
- The pop sound may play during the transition, causing distortion or failure
- The microphone starts in 16kHz mode (not the assumed 48kHz)

**Source:**
- https://supermegaultragroovy.com/2021/01/28/more-on-avaudioengine-airpods/
- Stack Overflow: "Why does my bluetooth output sound bad when input is on?"

---

### 2. AVAudioEngine's "Automatic Aggregation" Problem

**What AVAudioEngine does on macOS:**
- When you create an `AVAudioEngine` with microphone permissions, it automatically:
  1. Detects the default input device (AirPods microphone)
  2. Detects the default output device (AirPods speakers)
  3. Creates an **aggregate device** combining both
  4. Forces the microphone into active state

**The problem:**
- You cannot tell AVAudioEngine "I only want input, ignore output"
- The API lacks intent declaration for input-only vs output-only engines
- Simply accessing `engine.inputNode` triggers output device changes

**Quote from research:**
> "AVAudioEngine doesn't provide an API to specify that you're building an output-only engine on macOS and don't require input capabilities. The API doesn't allow developers to opt out of the input capability explicitly, which is described as 'the crux of the problem'."

**Impact on Midori:**
- Every time you start recording, AVAudioEngine reconfigures both input AND output
- This causes mode switching, latency spikes, and potential audio glitches
- Pop sounds may fail or play with degraded quality

---

### 3. Missing Configuration Change Handling

**What should happen:**
When the audio engine's I/O unit observes:
- Channel count change
- Sample rate change
- Device connection/disconnection

The engine:
1. Stops automatically
2. Uninitializes itself
3. Issues `AVAudioEngineConfigurationChange` notification

**What Midori currently does:**
- Nothing. No listeners for this notification.

**Consequences:**
- If AirPods disconnect mid-recording: **silent failure**
- If device switches (e.g., user manually changes in System Settings): **app breaks**
- If Bluetooth connection drops temporarily: **recording stops, no recovery**

**What iOS/macOS developers typically do:**
```swift
NotificationCenter.default.addObserver(
    forName: .AVAudioEngineConfigurationChange,
    object: audioEngine,
    queue: .main
) { [weak self] _ in
    // Stop recording gracefully
    // Remove tap
    // Restart engine with new configuration
    // Or fail gracefully with error to user
}
```

**Midori doesn't have this.**

---

### 4. Sample Rate Mismatch Problem

**Current assumptions in TranscriptionManager.swift:135-140:**
```swift
// AVAudioEngine typically captures at 48kHz Float32 mono
let downsampleRatio = 3 // 48000 / 16000 = 3
```

**Reality with AirPods:**
- AirPods microphone operates at **16kHz native**
- When Midori assumes 48kHz and downsamples by 3:1, it's actually:
  - Taking 16kHz input
  - Downsampling to ~5.3kHz
  - Feeding corrupted audio to Parakeet V2

**Result:**
- Transcription quality degrades severely
- Or transcription fails completely
- Audio data is misaligned, causing gibberish output

**What should happen:**
```swift
let format = input.outputFormat(forBus: 0)
let actualSampleRate = format.sampleRate  // Could be 16000, 44100, 48000, etc.
let downsampleRatio = Int(actualSampleRate / 16000)
```

**Midori hardcodes 48kHz assumption** (documented limitation in TranscriptionManager.swift:135).

---

### 5. The "Pop Sound" Timing Issue

**Current flow (midoriApp.swift:172-198):**
```
1. User presses Right Command
2. Play pop sound 1
3. Wait 0.15 seconds
4. Play pop sound 2
5. Show waveform
6. Start audio recording
```

**Problem with AirPods:**
- Step 2 triggers A2DP → HFP mode switch
- Mode switch takes ~200-500ms (varies by device, macOS version, Bluetooth quality)
- Steps 3-6 happen DURING the mode switch
- Audio recording starts before AirPods microphone is fully ready

**Consequences:**
- First 0.5-1 second of audio is lost or corrupted
- User thinks recording started but audio buffer is empty/garbage
- Transcription fails with "no audio data" or produces wrong text

**Why it works with Mac built-in mic:**
- Built-in microphone is always ready
- No mode switching required
- No Bluetooth latency

---

## Why AirPods Are "Unreliable"

Combining all the above issues:

| Symptom | Root Cause |
|---------|------------|
| Recording sometimes produces no text | Sample rate mismatch (16kHz treated as 48kHz) |
| First second of speech cut off | AirPods not ready when recording starts (mode switch delay) |
| Pop sound doesn't play | A2DP → HFP transition interrupts playback |
| Pop sound is distorted/quiet | Playing during mode switch causes audio glitches |
| App "stops working" after AirPods disconnect | No AVAudioEngineConfigurationChange handler |
| Inconsistent transcription quality | Audio format misdetection, buffer corruption |
| Works fine with built-in mic | Built-in mic: always 48kHz, no Bluetooth, no mode switching |

---

## Industry Research Findings

### Known AVAudioEngine + AirPods Issues (2021-2024)

**From Stack Overflow, Apple Forums, and technical blogs:**

1. **AVAudioEngine resets itself when route changes occur**
   - All players attached to the engine stop
   - Scheduled samples are purged
   - Must rebuild the entire audio graph

2. **No recovery mechanism provided by Apple**
   - App must manually detect changes
   - App must manually tear down and rebuild engine
   - No automatic recovery

3. **Timing issues with Bluetooth**
   - Route change notification may arrive AFTER engine has already failed
   - Bluetooth devices introduce 100-500ms latency in route changes
   - No way to "wait for device ready" programmatically

4. **iPhone 16 specific issue (2024)**
   - installTap callback stops being invoked after phone call interruptions
   - Requires full engine restart
   - Apple has not provided a fix as of iOS 18.7.1

5. **Common error code: 561145187**
   - Occurs when trying to start engine while app is backgrounded
   - Introduced in iOS 12.4, still present in 2024

**Recommended solutions from community:**
- Add mixer node between input and tap (provides buffer against changes)
- Always remove tap before reinstalling
- Listen for AVAudioEngineConfigurationChange notification
- Implement full engine tear-down and restart on route changes
- Consider using AVAudioSession.setPreferredInput to lock to specific device
- On macOS, recommend users set System Settings → Sound → Input to built-in mic

---

## Recommendations

### Priority 1: Handle Configuration Changes (Critical)

**What to implement:**
```swift
// In AudioRecorder.init() or when engine is created
NotificationCenter.default.addObserver(
    forName: .AVAudioEngineConfigurationChange,
    object: audioEngine,
    queue: .main
) { [weak self] notification in
    print("⚠️ Audio configuration changed - stopping recording")
    self?.handleConfigurationChange()
}
```

**Handler logic:**
```swift
private func handleConfigurationChange() {
    if isRecording {
        // Gracefully stop recording
        stopRecording()

        // Notify user (menu bar icon flash? console log?)
        print("⚠️ Audio device changed during recording")

        // Option: attempt to restart with new device
        // Option: show notification to user
    }
}
```

**Why this is critical:**
- Currently, when AirPods disconnect, app enters undefined state
- User has no feedback that recording failed
- Prevents "silent failures" where user thinks it's working but it's not

**Effort:** Low (1-2 hours)
**Impact:** High (prevents crashes and undefined behavior)

---

### Priority 2: Dynamic Sample Rate Detection (Critical)

**Current problem:**
```swift
// TranscriptionManager.swift:139
let downsampleRatio = 3 // Assumes 48kHz input
```

**Solution:**
Pass sample rate from AudioRecorder to TranscriptionManager:

```swift
// In AudioRecorder.swift
func getAudioFormat() -> AVAudioFormat? {
    return inputNode?.outputFormat(forBus: 0)
}

// In TranscriptionManager.swift
func transcribe(audioData: Data, sourceFormat: AVAudioFormat?, completion: ...) {
    let sampleRate = sourceFormat?.sampleRate ?? 48000.0
    let downsampleRatio = Int(sampleRate / 16000.0)
    // Now correctly handles 16kHz, 44.1kHz, 48kHz, etc.
}
```

**Why this is critical:**
- AirPods microphone is 16kHz
- Mac built-in mic is 48kHz
- External USB mics vary (44.1kHz, 48kHz, 96kHz)
- Wrong ratio = garbage transcription

**Effort:** Medium (3-4 hours, includes testing)
**Impact:** High (fixes transcription quality with AirPods)

---

### Priority 3: Delay Recording Start After Pop Sound (Medium)

**Current timing:**
```
Pop sound 1 → 0.15s → Pop sound 2 → immediate recording start
```

**Proposed timing:**
```
Pop sound 1 → 0.15s → Pop sound 2 → 0.5s delay → recording start
```

**Rationale:**
- Gives AirPods time to complete A2DP → HFP mode switch
- Ensures microphone is fully active before first audio sample
- Prevents losing first 0.5-1 seconds of speech

**Implementation:**
```swift
// In midoriApp.swift startRecording()
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    self.audioRecorder?.startRecording()
}
```

**Trade-off:**
- Adds 0.5s perceived latency to user
- But: user gets double pop as feedback that recording will start
- Net: better than losing first second of speech

**Effort:** Low (30 minutes)
**Impact:** Medium (reduces "first word cut off" complaints)

---

### Priority 4: Add Audio Format Validation (Medium)

**What to validate:**
```swift
// After getting format from inputNode
let format = input.outputFormat(forBus: 0)

// Validate compatibility
guard format.sampleRate >= 8000 && format.sampleRate <= 48000 else {
    print("❌ Unsupported sample rate: \(format.sampleRate)")
    completion(.failure(.audioConversionFailed))
    return
}

guard format.channelCount == 1 || format.channelCount == 2 else {
    print("❌ Unsupported channel count: \(format.channelCount)")
    completion(.failure(.audioConversionFailed))
    return
}

print("✓ Audio format validated: \(format.sampleRate)Hz, \(format.channelCount)ch")
```

**Why this helps:**
- Detects unusual audio configurations early
- Provides clear error messages instead of silent failures
- Helps debugging user reports

**Effort:** Low (1 hour)
**Impact:** Medium (better error reporting)

---

### Priority 5: User-Facing Workarounds (Low Effort, High User Value)

**Approach 1: Documentation**
Add to README or help menu:
```
Using AirPods with Midori:

For best results, set System Settings → Sound → Input to "iMac Microphone"
This keeps AirPods in high-quality mode for playback.

If you prefer to use AirPods microphone:
- Expect 0.5-1 second delay after pressing Right Command
- Speak clearly and wait for waveform to appear before talking
- Disconnect and reconnect AirPods if recording stops working
```

**Approach 2: In-App Detection**
```swift
// In AudioRecorder.getAvailableInputDevices()
if displayName.contains("AirPods") {
    print("⚠️ AirPods detected - reliability may vary due to Bluetooth limitations")
}
```

**Approach 3: Menu Bar Status**
Add indicator in menu:
- ✅ "Recording Device: iMac Microphone (Recommended)"
- ⚠️ "Recording Device: AirPods Pro (Experimental)"

**Effort:** Low (1-2 hours)
**Impact:** High (sets user expectations, reduces support burden)

---

### Priority 6: Consider Alternative Approaches (Research)

**Option A: Use AVCaptureSession instead of AVAudioEngine**
- Provides more control over device selection
- Better handling of route changes
- More complex API

**Option B: Lock to built-in microphone**
```swift
// Force use of built-in mic regardless of system default
let builtInMic = findBuiltInMicrophone()
audioEngine.inputNode.setPreferredInput(builtInMic)
```

**Option C: Detect AirPods and warn user**
```swift
if currentInputDevice.contains("AirPods") {
    showWarning("AirPods microphone may be unreliable. Switch to built-in mic for best results?")
}
```

**Option D: Add "Device Preference" setting**
- Menu: "Prefer Built-In Microphone" (default: ON)
- Menu: "Prefer AirPods Microphone" (default: OFF)
- Gives user control

**Effort:** High (varies by approach)
**Impact:** High (architectural change, needs careful evaluation)

---

## Testing Recommendations

When implementing fixes, test these scenarios:

### Baseline Tests
- [ ] Record with built-in Mac microphone (should always work)
- [ ] Record with AirPods connected but not selected (should use built-in)
- [ ] Record with AirPods selected as system input (currently broken)

### Edge Cases
- [ ] Disconnect AirPods mid-recording (should fail gracefully)
- [ ] Connect AirPods while app is running (should detect new device)
- [ ] Switch input device in System Settings while recording (should handle change)
- [ ] Record 10+ times in quick succession with AirPods (check for state corruption)

### Audio Quality Tests
- [ ] Verify sample rate detection: log `format.sampleRate` for each device
- [ ] Verify transcription quality: same phrase with built-in vs AirPods
- [ ] Verify no audio loss: record "One two three four five" and check all words appear

### Timing Tests
- [ ] Pop sound plays correctly with AirPods (not cut off or distorted)
- [ ] First word of speech is captured (not cut off)
- [ ] Waveform appears at correct time (matches audio capture start)

---

## Key Insights

1. **This is not primarily a Midori bug** - it's a limitation of AVAudioEngine + Bluetooth on macOS
2. **The requirements document is correct** - "AirPods Pro 2 Support" is marked as broken for valid reasons
3. **Built-in mic works because** - no Bluetooth, no mode switching, consistent 48kHz format
4. **The hardest problem is** - you cannot "fix" Bluetooth protocol limitations at the app level
5. **The most impactful fix is** - proper configuration change handling (prevents crashes/undefined state)
6. **The best user experience is** - detect AirPods and guide user to built-in mic OR handle gracefully

---

## Implementation Priority Summary

| Priority | Task | Effort | Impact | Rationale |
|----------|------|--------|--------|-----------|
| P1 | Handle AVAudioEngineConfigurationChange | Low | High | Prevents crashes and undefined state |
| P2 | Dynamic sample rate detection | Medium | High | Fixes transcription with AirPods |
| P3 | Delay recording start after pop | Low | Medium | Reduces first-word cutoff |
| P4 | Audio format validation | Low | Medium | Better error messages |
| P5 | User documentation/warnings | Low | High | Sets expectations, reduces frustration |
| P6 | Research alternative approaches | High | High | Long-term architectural improvement |

---

## Conclusion

Midori's AirPods unreliability is caused by:
1. **Bluetooth protocol limitations** (unavoidable)
2. **AVAudioEngine's opinionated behavior** (Apple's design choice)
3. **Missing error handling** (can be fixed)
4. **Sample rate assumptions** (can be fixed)

**Recommended immediate actions:**
1. Implement AVAudioEngineConfigurationChange notification handler (1-2 hours)
2. Add dynamic sample rate detection (3-4 hours)
3. Add user-facing documentation about AirPods limitations (1 hour)

**Expected outcome after fixes:**
- AirPods will work more reliably (fewer crashes, better transcription)
- Users will understand limitations (better UX through transparency)
- App won't enter undefined state on device changes (stability improvement)

**Reality check:**
- AirPods will NEVER be as reliable as built-in mic due to Bluetooth
- Best we can do: handle errors gracefully + guide users to optimal setup
- Consider adding "Prefer Built-In Mic" as default behavior

---

## References

- [More on AVAudioEngine + AirPods](https://supermegaultragroovy.com/2021/01/28/more-on-avaudioengine-airpods/)
- [Apple Developer: Responding to audio route changes](https://developer.apple.com/documentation/avfaudio/responding-to-audio-route-changes)
- [Stack Overflow: AVAudioEngine inputNode installTap crash](https://stackoverflow.com/questions/41805381/avaudioengine-inputnode-installtap-crash-when-restarting-recording)
- [GitHub: roaldnefs/airpods - Sound quality fixer for macOS](https://github.com/roaldnefs/airpods)
- Midori codebase:
  - [AudioRecorder.swift](midori/AudioRecorder.swift) (lines 184-245)
  - [TranscriptionManager.swift](midori/TranscriptionManager.swift) (lines 124-149)
  - [midoriApp.swift](midori/midoriApp.swift) (lines 157-243)
  - [Requirements.md](Requirements.md) (lines 60-64, 151-156)
  - [Implementation-Plan.md](Implementation-Plan.md) (lines 15-46)
