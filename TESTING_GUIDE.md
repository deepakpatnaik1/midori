# Midori - Testing Guide

## Build Status: ✅ Ready to Test

The complete Midori app has been implemented and built successfully!

## What's Implemented

### ✅ Core Features
1. **Menu Bar App** - Status icon with waveform symbol, Quit/Restart menu
2. **Right Command Key Monitoring** - NSEvent-based, no permissions needed
3. **Audio Recording** - Mock audio with animated levels (real AVAudioEngine ready for production)
4. **Waveform Visualization** - 9-bar purple-to-cyan gradient, animates with audio
5. **User Feedback Sequence** - 1s delay, pop sound, pulsing dots during transcription
6. **Transcription** - Mock transcription (returns random phrases)
7. **Text Injection** - Clipboard + Cmd+V simulation (accessibility permission required)
8. **Error Handling** - User-visible error dialogs

### 🔨 Development Mode Features
- **Mock Audio**: Generates sine wave audio levels (no permission dialogs)
- **Mock Transcription**: Returns random test phrases instantly
- **Debug Logging**: Console output for all major events

## How to Test

### Option 1: Run from Xcode
```bash
open midori.xcodeproj
```
1. Select `Midori-Debug` scheme in toolbar
2. Press **Cmd+Shift+Y** to open console (important - see all debug output)
3. Press **Cmd+R** to build and run
4. App appears in menu bar with waveform icon

### Option 2: Run from Terminal
```bash
./scripts/run.sh
```

### Option 3: Run Pre-Built App
```bash
open build/Build/Products/Debug/midori.app
```

## Testing the Complete Workflow

### Test 1: Basic Recording
1. **Launch** the app
2. **Check** menu bar for waveform icon
3. **Press and HOLD** Right Command key (⌘ right)
4. **Wait** 1 second
5. **Expect**:
   - Hear pop sound (system beep)
   - See animated waveform at bottom center of screen
   - Console: "🎤 Right Command pressed - Starting recording..."
6. **Release** Right Command key
7. **Expect**:
   - Waveform disappears
   - Pulsing dots appear
   - After ~1.5s, dots disappear
   - Text appears in console: "Would paste: [some text]"

### Test 2: Menu Bar Interaction
1. **Click** menu bar icon
2. **Verify** menu shows:
   - "Midori - Voice to Text"
   - Restart (⌘R)
   - Quit (⌘Q)
3. **Try** Restart - app should restart
4. **Try** Quit - app should close

### Test 3: Multiple Recordings
1. Press and hold Right Command
2. Wait 1+ seconds (see waveform animate)
3. Release
4. Wait for transcription complete
5. **Repeat** 3-4 times
6. **Verify** each recording works independently

## Console Output Reference

### Normal Flow
```
✓ Midori launching...
✓ AudioRecorder initialized
✓ TranscriptionManager initialized
⚠️ Using MOCK transcription (development mode)
✓ Waveform window initialized
✓ Key monitor initialized - watching for Right Command key
✓ Midori ready - Press Right Command to start recording

⌘ Right Command key: DOWN
🎤 Right Command pressed - Starting recording...
🔊 Pop sound played
✓ Waveform shown
🎤 Starting MOCK audio recording (development mode)

⌘ Right Command key: UP
🔴 Right Command released - Stopping recording...
🔴 Stopped MOCK audio recording
✓ Waveform hidden
✓ Pulsing dots shown
📝 Transcribing audio...
✓ MOCK transcription complete: [text]
✓ Pulsing dots hidden
⚠️ Accessibility not granted - simulating text injection
📋 Would paste: [text]
```

## What to Look For

### ✅ Good Signs
- Menu bar icon appears
- Right Command key detection is instant
- 1 second delay before waveform appears (as specified)
- Pop sound plays
- Waveform animates smoothly
- Dots pulse while "transcribing"
- Console shows detailed logging with emoji

### ⚠️ Expected Behaviors (Development Mode)
- "MOCK audio recording" - This is correct! Avoids permission dialogs
- "MOCK transcription" - Returns test phrases
- "Accessibility not granted - simulating text injection" - Normal in dev mode

### ❌ Problems to Report
- App doesn't appear in menu bar
- Right Command key not detected
- Waveform doesn't appear
- No pop sound
- App crashes
- Build errors

## Known Limitations (Development Mode)

1. **Mock Audio**: Not recording real audio (bypasses permissions)
2. **Mock Transcription**: Returns random phrases, not real transcription
3. **No Text Injection**: Prints to console instead of pasting (needs accessibility permission)

## Next Steps for Production

### To Enable Real Features:
1. **Real Audio Recording**:
   - Remove `#if DEBUG` blocks in AudioRecorder.swift
   - Grant microphone permission when prompted

2. **Real Transcription**:
   - Integrate whisper.cpp library
   - Download Whisper model
   - Remove mock implementation

3. **Text Injection**:
   - Grant Accessibility permission in System Settings
   - Works automatically once granted

### To Grant Permissions (Optional):
```bash
# Open System Settings to grant permissions
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

Then run:
```bash
./scripts/reset-permissions.sh
```

## Troubleshooting

### App Won't Launch
```bash
# Check if already running
killall midori

# Rebuild clean
xcodebuild -scheme Midori-Debug -configuration Debug clean build
```

### Can't See Console Output
- In Xcode: Press **Cmd+Shift+Y** to show console
- Or use Console.app and filter for "midori"

### Right Command Key Not Working
- Verify you're pressing the RIGHT Command key (not left)
- Check console for key detection messages
- Try clicking menu bar icon to verify app is running

### Waveform Not Appearing
- Check console for "Waveform shown" message
- Verify 1 second delay is completing
- Look at bottom center of screen

## Performance Notes

The app should be:
- **Instant** key detection (< 50ms)
- **Minimal CPU** when idle (< 1%)
- **Small memory** footprint (< 50MB)
- **Smooth** waveform animation (60fps)

## Success Criteria

✅ You should be able to:
1. Press and hold Right Command
2. See animated waveform after 1 second
3. Release and see pulsing dots
4. See transcription result in console
5. Repeat multiple times without issues

## Ready to Test! 🚀

The app is fully functional in development mode. All core features work with mock data to avoid permission complications during development.

**Just press Right Command and watch the magic happen!**
