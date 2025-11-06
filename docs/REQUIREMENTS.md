# Midori - Voice-to-Text Transcription App Requirements

**GitHub Repository**: https://github.com/deepakpatnaik1/etero
**Platform**: macOS
**Language**: Swift
**Last Updated**: 2025-11-05

## Core Functionality

### Application Behavior
- Small Swift app for macOS
- Auto-launches at login
- Always running in background
- Minimal memory and CPU consumption
- Menu bar indicator showing app status with quit/restart options
- Survives and auto-launches after restart

### Recording Trigger
- **Activation**: Right Command key press
- **Deactivation**: Right Command key release
- **No alternatives**: Right Command key is only option
- **No auto-stop**: Recording duration entirely controlled by key press/release

### Audio Capture
- **Input source**: Microphone only (not system-wide audio)
- **Audio framework**: AVAudioEngine
- **Permissions**: Standard macOS microphone permission prompt

### User Feedback Sequence

#### On Key Press
1. Right Command key pressed
2. Wait 1 second
3. Play pop sound
4. Display waveform visualization (bottom center of screen)

#### During Recording
- Waveform shows actual real-time audio levels
- Waveform animates based on microphone input
- Uses purple-to-cyan gradient (matching logo)
- Small and beautiful visualization

#### On Key Release
1. Right Command key released
2. Waveform disappears
3. Pulsing dots appear at same position
4. Dots remain visible until transcription completes

#### Transcription Complete
1. Dots disappear
2. Transcribed text instantly pasted at cursor position in active app
3. Works in any app (requires Accessibility permissions)

### Error Handling
- If transcription fails: Display error message
- No silent failures

## Technical Requirements

### Whisper Integration
- **Engine**: whisper.cpp (NOT WhisperKit)
- **Initial model**: Small Whisper model
- **Language**: English only
- **Model storage**: User-specified directory
- **Model delivery**: Downloaded on first launch
- **Post-launch**: Test different models to find optimal for purpose

### Permissions
- **Microphone**: Standard macOS permission prompt
- **Accessibility**: Required for text injection and Right Command key monitoring
- **No setup prompts**: App assumes permissions will be granted

### Development Philosophy
- Use readily available libraries and tools
- Minimize custom implementation where possible
- Prioritize simplicity and reliability

## Visual Assets

### Logo/Icon
- Source file: `voice.png` in project root
- Design: 9 vertical rounded bars in symmetric waveform pattern
- Gradient: Purple/magenta (top) → blue/cyan (bottom)
- Usage: App icon and waveform visualization basis

### Waveform Design
- Reconstruct logo design for live visualization
- 9 bars with rounded caps
- Symmetric height pattern
- Purple-to-cyan gradient
- Animate bar heights based on real-time audio levels
- Bottom center screen position
- Small footprint

## Performance Targets
- Minimal memory usage
- Minimal CPU usage when idle
- Efficient during recording and transcription
- No specific numeric targets, but optimize aggressively given simplicity

## Future Considerations
- Model testing and optimization post-initial build
- Potential model switching capability
- Performance profiling and optimization
