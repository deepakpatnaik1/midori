# Security Analysis - Midori Voice-to-Text App

## Executive Summary

This document outlines the security analysis of the Midori macOS application, identifying potential vulnerabilities and recommending mitigations.

## Current Security Posture

### ✅ Strengths

1. **Permission Model**
   - Requires explicit user consent for Microphone access
   - Requires explicit user consent for Accessibility access
   - Both permissions enforced by macOS system dialogs

2. **Thread Safety**
   - Bulletproof state management with serial DispatchQueue
   - Prevents race conditions in recording state
   - All UI operations on main thread

3. **Local Processing**
   - Audio recorded and processed locally
   - Transcription happens on-device (no cloud APIs)
   - No sensitive data transmitted over network

4. **Code Signing**
   - App is code-signed (ad-hoc for development)
   - macOS Gatekeeper validation on launch

### ⚠️ Security Concerns & Mitigations

## 1. **CRITICAL: Logging of Sensitive Data**

**Issue:** Transcribed text is logged to console in multiple locations
- Line 251: `print("📋 Transcribed text: \(text)")`
- Line 259: `print("📋 Setting pasteboard: \"\(textWithSpace)\"")`
- Line 271: `print("✓ Pasteboard contains: \"\(pasteboardText ?? "nil")\"")

**Risk:**
- Console logs accessible via Console.app
- Logs may be included in system diagnostics
- Transcribed speech could contain sensitive/private information
- Logs persisted to disk by macOS

**Severity:** **HIGH**

**Recommendation:**
```swift
// Remove sensitive data from logs
print("📋 Transcribed text: [REDACTED - \(text.count) chars]")
print("📋 Setting pasteboard: [REDACTED]")
```

## 2. **Pasteboard Security**

**Issue:** Using system pasteboard to inject text
- Line 262-266: Clears and sets NSPasteboard.general
- Overwrites user's clipboard contents
- Clipboard history apps could capture transcribed text

**Risk:**
- User loses their clipboard contents
- Third-party clipboard managers may log sensitive transcriptions
- Clipboard syncing (Universal Clipboard) could leak to other devices

**Severity:** MEDIUM

**Current Mitigation:**
- Pasteboard is only accessible with Accessibility permission
- Text immediately pasted and replaced

**Recommendation:**
- Document clipboard behavior in user guide
- Consider: Option to preserve user's clipboard after paste

## 3. **CGEvent Injection**

**Issue:** Simulating Cmd+V keystrokes via CGEvent
- Line 282-296: Posts CGEvents to inject text
- Requires Accessibility permission (correctly implemented)

**Risk:**
- If compromised, could simulate arbitrary keystrokes
- Accessibility permission is extremely powerful

**Severity:** LOW (Properly gated)

**Current Mitigation:**
- ✅ Gated behind AXIsProcessTrusted() check
- ✅ Only simulates Cmd+V (paste) - no arbitrary keys
- ✅ Hard-coded key codes (0x09 for 'V')
- ✅ User must explicitly grant Accessibility permission

## 4. **Audio Recording Security**

**Issue:** Continuous microphone access when running

**Risk:**
- App could theoretically record without user knowledge
- Audio buffers stored in memory

**Severity:** LOW

**Current Mitigation:**
- ✅ Requires macOS Microphone permission
- ✅ Recording only when Right Command held (1+ seconds)
- ✅ Visual feedback (waveform) when recording
- ✅ Audio feedback (pop sound) when recording starts
- ✅ Buffers cleared after transcription

**Recommendation:**
- ✅ Already implemented: User-initiated recording only
- Consider: Option to show menu bar indicator while recording

## 5. **Process Restart Functionality**

**Issue:** Restart function uses Process() with Bundle.main.executablePath
- Line 310-315: Creates new process to restart app

**Risk:**
- If executable path is manipulated, could launch malicious code
- Process() can be dangerous if not properly validated

**Severity:** LOW

**Current Mitigation:**
- ✅ Uses Bundle.main.executablePath (trusted)
- ✅ No user input in path
- ✅ Only accessible via menu bar (requires app to be running)

**Recommendation:**
- Add path validation to ensure executable hasn't been tampered with

## 6. **App Sandbox**

**Issue:** App sandbox is DISABLED
- Found: `ENABLE_APP_SANDBOX = NO` in Debug configuration
- Found: `ENABLE_APP_SANDBOX = YES` in Release configuration

**Risk:**
- Debug builds have full system access
- Could access files outside app container
- Could make network connections without restrictions

**Severity:** MEDIUM (Debug), LOW (Release)

**Current Status:**
- Release builds appear to have sandbox ENABLED
- Debug builds for development have it disabled

**Recommendation:**
- ✅ Release builds already sandboxed
- Document why Debug builds need sandbox disabled (Accessibility features)
- Ensure distribution DMG uses Release/sandboxed build

## 7. **Model Download Security**

**Issue:** FluidAudio downloads AI model over internet
- Line 53 in TranscriptionManager.swift
- No visible certificate pinning or integrity checks

**Risk:**
- Man-in-the-middle attacks could provide malicious model
- Model could be tampered with during download

**Severity:** LOW

**Current Mitigation:**
- FluidAudio library handles downloads
- Likely uses HTTPS (needs verification)
- macOS validates TLS certificates

**Recommendation:**
- Verify FluidAudio uses HTTPS for downloads
- Check if FluidAudio validates model checksums/signatures
- Consider: Cache model in app bundle for offline use

## 8. **Launch at Login**

**Issue:** Auto-registers for launch at login
- Line 46-47: Automatically enables launch at login
- No user consent dialog

**Risk:**
- Persistence mechanism
- Runs on every boot
- User may not be aware

**Severity:** LOW

**Current Behavior:**
- Enabled automatically on first launch
- Required for "always ready" functionality
- Documented in INSTALL.txt

**Recommendation:**
- ✅ Already documented in installation instructions
- Consider: First-run dialog explaining launch at login
- Consider: Menu bar option to disable auto-launch

## 9. **Input Validation**

**Issue:** Minimal validation of transcription text
- Text directly injected via pasteboard and Cmd+V
- No sanitization or length limits

**Risk:**
- Extremely long transcriptions could cause issues
- Special characters might cause problems in some apps

**Severity:** LOW

**Current Mitigation:**
- Transcription comes from local AI model (trusted source)
- Not user-provided input
- macOS handles pasteboard safely

**Recommendation:**
- Add reasonable length limit (e.g., 10,000 characters)
- Log warning if transcription exceeds expected length

## 10. **Thread.sleep() Usage**

**Issue:** Using Thread.sleep() in main-thread context
- Line 274: `Thread.sleep(forTimeInterval: 0.1)`

**Risk:**
- Blocks main thread
- Could cause UI freezes
- Not a security issue, but poor practice

**Severity:** LOW (UX issue)

**Recommendation:**
```swift
// Use async delay instead
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    // Post CGEvents here
}
```

---

## Recommendations Summary

### Immediate Actions (High Priority)

1. **Remove sensitive data from logs**
   - Redact transcribed text from console output
   - Only log metadata (length, timestamp)

2. **Verify model download security**
   - Confirm FluidAudio uses HTTPS
   - Check for integrity validation

### Medium Priority

3. **Document clipboard behavior**
   - Warn users clipboard will be overwritten
   - Add to INSTALL.txt

4. **Add input validation**
   - Limit transcription length
   - Handle edge cases gracefully

5. **Improve restart security**
   - Validate executable path before launching

### Low Priority

6. **Replace Thread.sleep()**
   - Use async patterns instead

7. **Consider first-run dialog**
   - Explain launch at login
   - Explain permissions needed

---

## Security Best Practices Currently Followed

✅ Requires explicit user consent for sensitive permissions
✅ Local processing (no cloud APIs)
✅ Minimal attack surface (single key input)
✅ Code signing enabled
✅ Sandboxing enabled in Release builds
✅ Thread-safe state management
✅ No arbitrary code execution
✅ No network connections (except model download)
✅ Open source (auditable)

---

## Conclusion

The Midori app follows good security practices overall. The main concern is **logging sensitive data** which should be addressed immediately before public distribution. Other issues are minor and can be addressed incrementally.

For a personal/family app, the current security posture is acceptable. For wider distribution, implement the high-priority recommendations above.
