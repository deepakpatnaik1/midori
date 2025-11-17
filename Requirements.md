# Midori - User Requirements

**Last Updated**: 2025-11-17
**Status**: In Active Development

---

## Desired User Experience

I click into a text field.

I press and hold the Right Command key.

I instantly see my beautiful colored waveform in its base state. In other words, the bars are not dancing. They're all sitting pretty as dots in a straight line.

Half a second later, I hear the double pop sound. Not a single pop, a double pop.

And then I start speaking.

And as I speak, the waveform dances to the sound of my voice.

If I pause, the waveform goes back to the base state. So as a user, I feel that it is really responsive to my voice.

When I release the Command key, the waveform disappears and the text appears at the cursor.

No, I don't want a pop sound at this time.

---

## Core Requirements

A voice-to-text app that:
1. Lives in my menu bar
2. I hold down Right Command key and speak
3. It transcribes my speech
4. Pastes the text where my cursor is
5. Works with my AirPods Pro 2
6. Never breaks (stability is critical)
7. Learns how to spell "Claude" correctly (not "clawed" or "clod")

---

## Current Status: What's Working vs. What's Broken

### ✅ Working Well
- Lives in menu bar
- Right Command key trigger
- Transcribes speech
- Pastes text at cursor
- Pop sound (when using Mac microphone)
- Permissions (no longer repeatedly asking)

### ❌ Critical Issues

#### 1. Stability (HIGHEST PRIORITY)
- App requires frequent restarts
- Crashes occur regularly
- This is the #1 problem affecting daily use

#### 2. AirPods Pro 2 Support
- Does NOT work with AirPods
- Must manually switch to computer microphone in System Settings → Sound
- Pop sound only works reliably with Mac mic, unreliable with AirPods
- macOS offers native AirPods detection - we should leverage it

#### 3. Custom Dictionary
- NOT implemented
- Frequently used words are consistently transcribed incorrectly
- This becomes increasingly frustrating with daily use
- Need training UI to teach the app correct spellings

---

## Menu Bar Design

The menu bar should have **four buttons**:
1. **About** - Simple, regular macOS about dialog with year and "Deepak Patnaik"
2. **Train** - Opens the custom training/custom dictionary UI
3. **Restart** - Restarts the app
4. **Quit** - Quits the app

---

## Application Behavior

- Start automatically when I turn on the computer
- Stay in the menu bar (no Dock icon)
- App icon should be in Applications folder (searchable via Spotlight)
- App icon should be identical to the dancing waveform

---

## Custom Dictionary Training UI

### Workflow
1. There's a **plus button** (+)
2. I hit the plus button to train a new word or phrase
3. It shows "Training Data 1" with a **play button**
4. I hit the play button and say: *"Claude, come in. Get up to speed on this fascinating project."*
5. The app transcribes whatever it thinks I said
6. I press a **mini plus** button
7. I see the phrase again and the app transcribes it
8. Repeat 3-5 more times (collect multiple audio samples)
9. Finally, I manually write down what I want the app to actually transcribe

### Technical Approach
- Use **Apple Speech Framework** (macOS 14+) with custom vocabulary support
- Leverage `prepareCustomLanguageModel` API
- Provide multiple audio samples (ML training data)
- Provide ground truth text (correct transcription)
- Apple's API handles the ML training
- Custom vocabulary integrates directly into recognition (single unified layer)
- Fully on-device, works offline, no network required

---

## Waveform Visualization

### Base State (Instant)
- Appears immediately when Right Command is pressed
- 9 bars sitting as dots in a straight line (not dancing)
- Purple-to-cyan gradient (hot magenta → pure cyan)
- Bottom center of screen

### Active State (While Speaking)
- Bars dance to the sound of voice
- Responsive to audio levels
- When paused, returns to base state (dots in a line)
- Ultra-sensitive to soft speech

### Disappears
- When Right Command is released
- Waveform vanishes
- Text appears at cursor

---

## Audio Feedback

### Double Pop Sound
- Plays **half a second** after Right Command is pressed
- Double pop, not single
- Indicates recording has started

### No Pop on Release
- When Right Command is released
- No audio feedback
- Just waveform disappears and text appears

---

## AirPods Support Requirements

- Should work automatically when wearing AirPods
- Don't make me switch to Mac microphone manually
- macOS already has perfect AirPods detection - just leverage it
- Pop sound should work reliably with AirPods (currently doesn't)

---

## Reliability Requirements

### Stability
- Should work every single time
- **No crashes** (currently the biggest problem)
- Should survive macOS updates

### Permissions
- ✅ No repeated permission popups after initial grant (this is working)
- Microphone permission
- Accessibility permission

---

## Technical Stack

### Platform
- macOS 14.0+ (Sonoma)
- Swift/SwiftUI
- Modern Swift patterns (async/await, actors, etc.)

### Transcription Engine
- **Apple Speech Framework** (replacing NVIDIA Parakeet V2)
- Better accuracy than Parakeet V2 (5-10% WER vs 11-12% WER)
- Built-in custom vocabulary support via `prepareCustomLanguageModel`
- Fully on-device processing (privacy-focused)
- Free (no API costs or rate limits for on-device recognition)
- Native macOS integration

### Key Technologies
- **Speech Framework** - Transcription with custom vocabulary
- **SwiftUI** - Waveform visualization and training UI
- **AppKit** - Menu bar integration, key monitoring
- **AVFoundation** - Audio recording
- **ServiceManagement** - Auto-launch at login
- **CGEvent** - Text injection (requires Accessibility permission)

### Architecture
- Menu bar app (LSUIElement = YES, no Dock icon)
- Right Command key as trigger (NSEvent global monitoring)
- No app sandbox (required for key monitoring)
- Fixed build location (prevents permission resets)

---

## Success Criteria

### Must Have (Not Yet Achieved)
- ❌ Works reliably with AirPods Pro 2
- ❌ No crashes, stable operation
- ❌ Custom dictionary training UI functional
- ❌ Waveform shows base state (dots) and dances responsively
- ❌ Double pop sound at correct timing (half second delay)

### Already Working
- ✅ Lives in menu bar
- ✅ Right Command key trigger
- ✅ Transcribes speech
- ✅ Pastes text at cursor
- ✅ Auto-launch at login
- ✅ Permissions stable (no repeated prompts)
- ✅ Pop sound (when using Mac mic)

---

## Migration from Parakeet V2 to Apple Speech Framework

### Why Switch?
1. **Better accuracy** - Apple: 5-10% WER, Parakeet: 11-12% WER
2. **Built-in custom vocabulary** - Solves the "Claude" problem natively
3. **Native integration** - No external dependencies (FluidAudio)
4. **Free and unlimited** - No API costs, on-device processing
5. **Simpler architecture** - One unified system vs. separate correction layer

### What We Keep
- Same UX and waveform design
- Menu bar architecture
- Right Command key trigger
- Auto-launch behavior
- Text injection mechanism

### What Changes
- Replace `TranscriptionManager` to use Apple Speech Framework
- Remove FluidAudio dependency
- Add custom language model training workflow
- Build training UI for custom dictionary

---

## Future Enhancements (Optional)
- Transcription history
- Preferences window
- Custom keyboard shortcuts (beyond Right Command)
- Multiple language support
- Cloud sync for custom dictionary
