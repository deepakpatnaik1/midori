# Systematic Testing - Midori

**Date**: 2025-11-18

---

## Phase 4: Custom Dictionary UI Testing

### Test 1: Custom Dictionary Window Access

**Status**:  PASSED

- **Test**: Open Custom Dictionary from menu bar
- **Expected**: Window opens when clicking "Custom Dictionary..." menu item (Cmd+D)
- **Actual**: Window opens successfully
- **Result**: PASSED

---

### Test 2: Test Recording UI Visibility

**Status**: ✅ PASSED (after rebuild)

- **Test**: Verify "Record Test Sample" button is visible in Custom Dictionary window
- **Expected**: Blue "Record Test Sample" button visible in "Test what gets transcribed:" section at top of window
- **Actual**: Button is now visible after rebuild and restart
- **Code Location**: [TrainingWindow.swift:96-146](midori/TrainingWindow.swift#L96-L146)
- **Resolution**: Window was displaying cached version. Rebuild and restart fixed the issue.
- **Note**: Window caching issue - existing window instance was created before code changes were compiled

---

### Test 3: Test Recording Feature

**Status**: ✅ PASSED

- **Test**: Record audio sample in Custom Dictionary, verify transcription appears and auto-populates field
- **Expected**:
  - Click "Record Test Sample" button
  - Button turns red during recording
  - Transcription appears in green box
  - "Transcribes as" field auto-populates with result
- **Actual**: Feature works perfectly. All expected behaviors confirmed.
- **User Feedback**: "Works very well. I'm very pleased with it."
- **Code Location**: [TrainingWindow.swift:279-337](midori/TrainingWindow.swift#L279-L337)
- **Result**: PASSED - Excellent UX, smooth workflow

---

### Test 4: Manual Correction Entry

**Status**: ⏳ PENDING

- **Test**: Add correction manually using text fields
- **Expected**: Can type in both fields, click plus button to add
- **Actual**: Not yet tested

---

### Test 5: Correction Persistence

**Status**: ⏳ PENDING

- **Test**: Add correction, restart app, verify it persists
- **Expected**: Corrections remain after app restart
- **Actual**: Not yet tested

---

### Test 6: Correction Application

**Status**: ❌ CRITICAL BUG → ⏸️ WORK ABANDONED

- **Test**: Record audio with word that has correction, verify correction is applied
- **Expected**: Transcribed text shows corrected version with correction applied only to matching phrase
- **Actual**: MASSIVE TEXT CORRUPTION - "Call 2A" or "MODIFIED CALL 2A" was being inserted between EVERY word
- **Example**:
  - User spoke: "Document this bug" (3 times)
  - Expected output: "Document this bug. Document this bug. Document this bug."
  - Actual output: "MODIFIED CALL 2ADocumentMODIFIED CALL 2A MODIFIED CALL 2AthisMODIFIED CALL 2A MODIFIED CALL 2AbugMODIFIED CALL 2A."
- **Root Cause**: NEVER FULLY IDENTIFIED
  - Initial hypothesis: Punctuation-stripping logic creating malformed regex patterns
  - Fix attempted: Removed punctuation-stripping logic
  - Result: Bug persisted even after fix
  - Further testing: Cleared UserDefaults, bug still occurred with empty dictionary
  - Bug appears to be in the regex pattern matching logic itself
- **Resolution**: REVERTED to commit `ace84ff` (before CorrectionLayer integration)
  - Executed: `git reset --hard ace84ff`
  - All buggy code removed
  - App restored to stable state with Custom Dictionary UI but no integration
- **Lesson Learned**: The integration approach needs to be completely rethought
- **Result**: ABANDONED - Will need different approach for Phase 2

---

## Critical Issues

### Issue #1: Test Recording UI Not Rendering

**Priority**: HIGH → ✅ RESOLVED

**Description**: The test recording section (lines 96-146 in TrainingWindow.swift) was not visible in the Custom Dictionary window despite being present in the code and successfully compiled.

**Root Cause**: Window caching issue. The TrainingWindow instance was created before the code changes were compiled. When the window was first opened, it used the old version of TrainingView that didn't have the test recording UI.

**Resolution**:
1. Rebuilt the app with `./scripts/build.sh`
2. Killed all running Midori processes with `pkill -f midori`
3. Started fresh with `./scripts/run.sh`
4. Window now displays the test recording UI correctly

**Lesson Learned**: When adding new UI elements to existing windows, always rebuild and restart the app completely. SwiftUI windows may cache their view structure if the app instance persists across code changes.

---

## Notes

- All tests performed manually as per project philosophy: "Manual testing first, automated testing later"
- Focus on real-world usage patterns
- Document failures immediately for investigation
