# Development Workflow

**Last Updated**: 2025-11-17

---

## Working While the App is Running

**IMPORTANT**: You can continue using the current stable build of Midori while we develop new features. The app does not need to be quit during development.

---

## Parallel Development Strategy

### Current Stable Build Location
```
build/Build/Products/Debug/midori.app
```

This is where the currently running app lives. **Do not touch this while the app is in use.**

### Development Workflow

```
1. User keeps using stable app (it stays running)
   ↓
2. Developer creates feature branch
   ↓
3. Developer modifies code on branch
   ↓
4. Developer builds to test location (or same location when ready to test)
   ↓
5. User decides when to test
   • Quit current stable app
   • Launch new test build
   • Try it out
   ↓
6. Decision point:
   ├─ If it works → Keep using new version, merge branch to main
   └─ If it breaks → Quit new build, relaunch old stable app
```

---

## Git Branching Strategy

### Creating a Feature Branch
```bash
# Always start from main
git checkout main

# Create feature branch
git checkout -b feature/airpods-fix
# or
git checkout -b feature/apple-speech
```

### Working on the Branch
```bash
# Make changes to files
# Commit frequently
git add <files>
git commit -m "Fix AirPods device detection"

# Keep committing as you work
```

### Testing a New Build

**Step 1: Quit the running app**
```bash
# User manually quits Midori from menu bar (Quit button)
# OR
killall midori
```

**Step 2: Build and install the new version**
```bash
# From the feature branch
./scripts/install-local.sh

# This builds and installs to ~/.local/midori/midori.app
open ~/.local/midori/midori.app
```

**Step 3: Test the new version**
- Try the new features
- Check for crashes
- Verify everything works

**Step 4a: If it works - Keep it**
```bash
# Merge the feature branch to main
git checkout main
git merge feature/airpods-fix

# Delete the feature branch
git branch -d feature/airpods-fix
```

**Step 4b: If it breaks - Rollback**
```bash
# Quit the broken app
killall midori

# Go back to main branch
git checkout main

# Rebuild the stable version
./scripts/install-local.sh
open ~/.local/midori/midori.app

# You're back to the working version!
```

---

## Phase-by-Phase Migration

### Phase 1: Fix AudioRecorder (AirPods Support)

**Branch**: `feature/airpods-fix`

**Files to Modify**:
- `midori/AudioRecorder.swift` (~80 lines)

**Testing Requirements**:
- Connect AirPods
- Try recording
- Verify app detects AirPods automatically
- Pop sound should play reliably
- No crashes

**Rollback Plan**:
- If AirPods still don't work or app crashes → rollback to main
- Feature branch stays unmerged, we debug more

---

### Phase 2: Replace Transcription Engine

**Branch**: `feature/apple-speech`

**Files to Create**:
- `midori/AppleSpeechManager.swift` (~200 lines)

**Files to Modify**:
- `midori/midoriApp.swift` (replace TranscriptionManager usage)

**Files to Delete** (after testing):
- `midori/TranscriptionManager.swift`
- `FluidAudio-Local/` (entire directory)

**Testing Requirements**:
- Record speech
- Verify transcription works
- Compare accuracy to old version
- Check speed (should be faster)
- No crashes

**Rollback Plan**:
- If transcription broken → rollback to main (still has Parakeet V2)
- We debug AppleSpeechManager on the branch

---

### Phase 3: UI/UX Improvements

**Branch**: `feature/ux-improvements`

**Files to Modify**:
- `midori/midoriApp.swift` (timing, menu items)
- `midori/WaveformView.swift` (base state)

**Files to Create**:
- `midori/AboutWindow.swift` (~50 lines)

**Testing Requirements**:
- Waveform shows base state (dots in line)
- Double pop plays at 0.5s
- About dialog works
- Restart button works
- Everything feels right

**Rollback Plan**:
- If UX broken → rollback to main
- We fix on the branch

---

### Phase 4: Custom Dictionary

**Branch**: `feature/custom-dictionary`

**Files to Create**:
- `midori/CustomLanguageModelManager.swift` (~150 lines)
- `midori/TrainingWindow.swift` (~100 lines)
- `midori/TrainingView.swift` (~200 lines)

**Files to Modify**:
- `midori/midoriApp.swift` (add Train menu item)
- `midori/AppleSpeechManager.swift` (integrate custom model)

**Testing Requirements**:
- Train menu item opens training UI
- Can record training samples
- Can provide ground truth text
- Model gets created and loaded
- "Claude" transcribes correctly after training

**Rollback Plan**:
- If training broken → rollback to main
- Custom dictionary is optional, core features still work

---

## Important Commands

### Check Current Branch
```bash
git branch
# * indicates current branch
```

### See What Changed
```bash
git status
# Shows modified files

git diff
# Shows actual changes
```

### Stash Changes (Save for Later)
```bash
# If you need to switch branches but don't want to commit yet
git stash

# Later, restore the changes
git stash pop
```

### Emergency Rollback
```bash
# Nuclear option: discard ALL changes, go back to last commit
git reset --hard HEAD

# Go back to main and rebuild
git checkout main
./scripts/install-local.sh
open ~/.local/midori/midori.app
```

---

## Build Locations

### Development Build
```
build/Build/Products/Debug/midori.app
```
- Created by `xcodebuild`
- Fixed location (prevents permission resets)

### Installed Build (for Daily Use)
```
~/.local/midori/midori.app
```
- Created by `./scripts/install-local.sh`
- This is what you actually run

### Applications Folder (Optional)
```
/Applications/Midori.app
```
- Created by dragging from DMG installer
- For "production" use

---

## Development Guidelines

### Rule 1: Never Break Main
- Main branch should always be stable
- User can always rollback to main and have a working app
- Only merge to main when feature is tested and working

### Rule 2: Commit Frequently
- Small commits are better than big commits
- Easy to rollback to specific points
- Clear history of what changed when

### Rule 3: Test Before Merging
- Always test on the feature branch first
- User must verify it works in real use
- Only merge when confident

### Rule 4: One Phase at a Time
- Don't start Phase 2 until Phase 1 is merged to main
- Sequential approach reduces risk
- Easier to debug when things go wrong

---

## Communication Protocol

### When Ready to Test
**Developer says**: "Phase 1 is ready to test. I've built the new version on `feature/airpods-fix`. Quit your current app and run `./scripts/install-local.sh` when you're ready to try it."

**User decides when**: "Okay, I'll test it in 10 minutes" OR "Let me finish this dictation first"

### When Test Succeeds
**User says**: "It works! AirPods are working perfectly."

**Developer**: Merges branch to main, deletes feature branch, ready for Phase 2

### When Test Fails
**User says**: "It crashed when I tried to record."

**Developer**: "No problem, rollback to main with `git checkout main && ./scripts/install-local.sh`. I'll debug on the feature branch."

---

## Safety Net

### The Golden Rule
**At any point in time, you can always run:**
```bash
killall midori
git checkout main
./scripts/install-local.sh
open ~/.local/midori/midori.app
```

And you'll have a working app again.

This is why we use Git and why we don't delete the old code until the new code is proven.

---

## Current Status

**Active Branch**: `main`
**Stable Build**: Using Parakeet V2, works except for AirPods
**Next Phase**: Phase 1 - Fix AirPods support
**User Can Keep Using App**: ✅ Yes, during all development

---

## Notes for Future Sessions

When starting a new session:

1. Check current branch: `git branch`
2. Check if app is running: `ps aux | grep midori`
3. Check what's changed: `git status`
4. Read this document to remember where we are
5. Check Architecture.md to remember the plan
6. Check Requirements.md to remember the goal

**Everything is documented. Nothing is lost between sessions.**
