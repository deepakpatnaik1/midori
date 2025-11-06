# Fix: Dual Instance Paste Duplication Issue

## Problem
Text was appearing doubled when transcribed, even though logs showed only one paste event.

## Root Cause
**TWO Midori instances running simultaneously:**
1. **DerivedData build** - Launched via Xcode Cmd+R: `/Users/d.patnaik/Library/Developer/Xcode/DerivedData/midori-.../Build/Products/Debug/midori.app`
2. **Stable build** - At `~/.local/midori/midori.app`

Both instances:
- Listen for Right Command key press
- Record audio independently
- Transcribe via Parakeet V2
- Paste text via Cmd+V simulation

**Result:** Everything appears doubled because two apps are pasting the same transcription.

## Solution

### ✅ Correct Way to Test

**Option 1: Launch from Terminal**
```bash
open ~/.local/midori/midori.app
```

**Option 2: Use Menu Bar Restart**
- Click Midori menu bar icon → "Restart"

**To Rebuild After Changes:**
```bash
./scripts/install-local.sh  # Builds AND copies to stable location
```

### ❌ NEVER Do This

**DO NOT use Cmd+R in Xcode** - This launches the DerivedData build alongside any existing instance, causing dual-paste.

## Verification

Check for multiple instances:
```bash
ps aux | grep "[m]idori"
```

Should show **only ONE** process. If you see two, kill all and restart:
```bash
killall -9 midori && open ~/.local/midori/midori.app
```

## Conclusion

The text injection code was **always correct**. The duplication was environmental - caused by running multiple app instances simultaneously. With a single instance, paste works perfectly!
