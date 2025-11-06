# Midori Development Best Practices

**Owner**: Development Team
**Status**: Mandatory for all development sessions
**Last Updated**: 2025-11-05

---

## 0. Development Role Division

### Human Focus: Business Logic & UX
The human developer (product owner) focuses on:
- Business logic and product decisions
- User experience design and flow
- Feature requirements and specifications
- Strategic technical decisions

### Claude Code Focus: Implementation & Automation
Claude Code handles:
- All implementation details and coding
- Automation of repetitive tasks
- Configuration management
- Build system setup and maintenance
- Script creation for common operations
- Technical execution of specifications

**Key Principle**: Human thinks through what needs to be done; Claude Code figures out how to do it and executes.

---

## 0.5. Debugging Complex Issues: When to Pause

### The Pattern Recognition Problem

When the same bug persists after 3+ fix attempts, **PAUSE immediately**. Signs to watch for:
- Making the same type of change repeatedly without understanding root cause
- Introducing new bugs while trying to fix old ones
- User frustration increasing with each attempt
- Loss of systematic approach in favor of "trying things"

### The "Pause and Plan" Protocol

**The Pause Prompt** (verbatim - use this when stuck):

> "Claude, I've been doing software development with you for a long time now. And I've figured something out. When I encounter the same bug a few times in a row, despite you making code changes each time, then it is time to pause. You tend to lose your cool head and start making reckless, unplanned, and unauthorized code changes. So I'm asking you to pause. Give me three possible reasons why we're encountering these bugs.
>
> The first bug is x.
> The second bug is y.
> The third bug is z."

**Why this prompt works:**
- Forces acknowledgment of the failure pattern
- Requires hypothesis formation before more code changes
- Separates diagnosis from implementation
- Gives both human and AI time to think systematically
- Prevents the "just try one more thing" spiral

**What worked in the waveform animation bug:**

1. **User initiated the pause**: Used the pause prompt above
2. **Systematic diagnosis**: Created 3 specific hypotheses to test
3. **Minimal test changes**: Added only debug logging, no functionality changes
4. **Test isolation**: Tested ONE thing at a time
5. **When blocked by side issue**: Used mock data to bypass the blocker entirely

### The Mock Data Breakthrough Pattern

**Context**: Audio recording triggered infinite permission dialogs, blocking all progress.

**Wrong approach** (what we were doing):
- Try to fix permission system
- Add different permission APIs
- Disable sandbox
- Reset permissions
- Each attempt made it worse

**Right approach** (what worked):
```swift
// Instead of fighting the real audio system:
func startRecording() {
    isRecording = true
    startMockAudioGeneration()  // Bypass the blocker entirely
}

private func startMockAudioGeneration() {
    mockTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
        let level = (sin(time) + 1.0) / 2.0 * 0.8 + 0.2
        self?.onAudioLevelUpdate?(level)
    }
}
```

**Why this worked**:
1. **Decoupled the problems**: Separated UI animation from audio capture
2. **Proved the pipeline**: Confirmed AudioRecorder → WaveformWindow → WaveformView works
3. **No side effects**: Zero chance of triggering permission dialogs
4. **Immediate feedback**: Could see results instantly
5. **Restored confidence**: Both human and AI could see progress

### When to Use Mock Data

**Use mock data to bypass a blocker when:**
- External system (permissions, network, hardware) is causing issues
- You need to verify the rest of your code works
- The blocker is a known problem you can fix later
- You're stuck in a loop trying to fix one specific thing

**Example scenarios:**
- Permission dialogs → Mock the data source
- Network API failing → Mock the response
- Hardware unavailable → Simulate the input
- External service down → Return fake data

### The Three-Strike Rule

After **3 failed attempts** to fix the same issue:
1. **STOP** making code changes
2. **IDENTIFY** 2-3 specific hypotheses about the root cause
3. **TEST** each hypothesis with minimal, isolated changes
4. **If still blocked**: Mock/bypass the problem to verify everything else works
5. **Document** what you learned before returning to the original problem

**Red flags that you need to pause:**
- "Let me try one more thing..."
- Making changes without understanding why the last one failed
- User says "it's still not working" 3+ times
- You're adding debug code but not analyzing the output
- Each fix introduces a new bug

### Documentation Requirement

When you successfully use mock data to bypass a blocker, **document it immediately**:
```swift
// TEMPORARY: Mock audio to bypass permission dialog bug
// TODO: Replace with real AVAudioEngine after fixing permissions
// See: BEST_PRACTICES.md section 0.5
```

This ensures:
- Future developers know it's temporary
- The reason is clear
- There's a path back to the real implementation

---

## 1. Technical Automation Philosophy

### Direct Terminal Modification Capability

**IMPORTANT**: Most Xcode project configuration can be modified directly via terminal rather than requiring manual GUI interaction.

#### What Can Be Automated:
- **Scheme files** (`.xcscheme`): Direct XML editing for build configurations
- **Project settings** (`.pbxproj`): Text-based modifications for build settings
- **Info.plist**: Use `plutil` or direct XML editing
- **Run script phases**: Can be added programmatically to `.pbxproj`
- **Build settings**: Direct modification in project file

#### When to Use Terminal vs GUI:

**Prefer Terminal When:**
- Batch operations across multiple settings
- Reproducible setup scripts
- CI/CD automation
- Experienced with Xcode project file structure
- Want version-controlled, reviewable changes

**Use GUI When:**
- First-time project creation (Xcode generates proper structure)
- Unfamiliar with XML structure of project files
- Want Xcode validation of changes
- Complex operations (adding targets, frameworks, etc.)

#### Best Practice for Future Projects:
1. **Initial creation**: Use Xcode GUI to create project
2. **Configuration**: Automate via terminal (schemes, build settings, Info.plist)
3. **Verification**: Open in Xcode to validate
4. **Documentation**: Script all terminal changes for reproducibility

**Example**: This project's scheme configuration (locking to Debug) was done via direct XML editing of `Midori-debug.xcscheme` rather than manual GUI clicks.

---

## 1. Debug Build Workflow

### Core Principle
We work exclusively in Debug configuration during development. No exceptions. No ambiguity about which build is active.

### Scheme Configuration (One-time Setup)

1. Create dedicated Debug scheme: Product > Scheme > Edit Scheme
2. Lock all actions to Debug configuration:
   - Run: Debug
   - Test: Debug
   - Profile: Debug
   - Analyze: Debug
   - Archive: Debug
3. Mark scheme as **Shared** (commit to version control)
4. Naming convention: `Midori-Debug`

### Active Verification
- Verify active scheme in toolbar (top-left near Play button)
- Current configuration visible in Edit Scheme under each action
- Never assume. Always verify before building.

### Debug Configuration Requirements
- **Optimization Level**: `-O0` (None)
- **Debug Information Format**: DWARF
- **Swift Compilation Mode**: Incremental
- **Enable Testability**: YES
- **Swift Compiler Flags**: `-DDEBUG`
- **Preprocessor Macros**: `DEBUG=1`

### Build Verification Script
Add Run Script Phase (fails build if wrong configuration):

```bash
if [ "${CONFIGURATION}" != "Debug" ]; then
    echo "error: Wrong configuration! Expected Debug, got ${CONFIGURATION}"
    exit 1
fi
echo "✓ Confirmed: Building in Debug configuration"
```

---

## 2. macOS Accessibility Permission Management

### The Problem

Every Xcode build creates a new binary at a different path in DerivedData:
```
/Users/.../Library/Developer/Xcode/DerivedData/Midori-xyz/Build/Products/Debug/Midori.app
```

macOS tracks accessibility permissions **per app bundle path**. Each rebuild = new path = new permission needed. This is the #1 source of frustration in macOS development with accessibility features.

### Solution: Fixed Build Location

**MANDATORY: Build to a consistent location that doesn't change between builds.**

#### Implementation Option 1: Project-Relative Build Location

1. In Xcode: File > Project Settings
2. Change "Derived Data" to "Project-relative Location"
3. Set path to: `build/`
4. Add `build/` to `.gitignore`

#### Implementation Option 2: Custom Build Directory

In Build Settings, set custom location:
- `CONFIGURATION_BUILD_DIR = /tmp/MidoriBuild`

**Why this works:** Same path every build = permissions persist between rebuilds.

### Permission Reset Script

When you DO need to reset permissions (rare), use this script:

```bash
#!/bin/bash
# scripts/reset-permissions.sh

echo "🧹 Cleaning up permissions and rebuilding..."

# Kill existing app instances
killall Midori 2>/dev/null

# Clear the app from accessibility database
tccutil reset Accessibility com.yourcompany.Midori 2>/dev/null
tccutil reset Microphone com.yourcompany.Midori 2>/dev/null

# Clean build
xcodebuild -scheme Midori-Debug -configuration Debug clean build

echo "✅ Clean build complete"
echo "📋 Now grant permissions in System Settings"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

### Permission Testing Workflow

**Two-phase approach:**

**Phase 1 - Feature Development:**
- Build features using mock/stubbed permission responses
- Test logic without actual system permissions
- Fast iteration without permission headaches

**Phase 2 - Permission Integration Testing:**
- Build to fixed location
- Grant permissions once
- Test actual permission flows
- Only rebuild when changing permission-related code

### Graceful Permission Handling in Code

Always include fallback behavior:

```swift
func checkAccessibility() -> Bool {
    let trusted = AXIsProcessTrusted()

    #if DEBUG
    if !trusted {
        print("⚠️ Accessibility not granted - some features may not work")
        // Continue anyway in debug mode
        return true // Mock as granted for development
    }
    #endif

    return trusted
}
```

---

## 3. Key Monitoring Implementation

### Use NSEvent (Not CGEvent)

**Context**: Lessons learned from Mini App 1 key monitoring test.

#### ❌ Don't Use: CGEvent (Low Level)

```swift
// This approach requires Accessibility permissions and fails from DerivedData
let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: { ... }
)
```

**Problems:**
- Requires Accessibility permissions (always)
- Unreliable when running from DerivedData
- Each rebuild invalidates permissions
- More complex implementation

#### ✅ Do Use: NSEvent (High Level)

```swift
// This approach works reliably without accessibility permissions
globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
    self.handleFlagsChanged(event)
}

localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
    self.handleFlagsChanged(event)
    return event
}
```

**Benefits:**
- No permissions needed for modifier keys
- Works reliably from DerivedData
- Simpler block-based API
- Perfect for development iteration

### Detecting Right Command Key

```swift
private func handleFlagsChanged(_ event: NSEvent) {
    // Right Command key has keyCode 54
    let rightCommandPressed = event.modifierFlags.contains(.command) && event.keyCode == 54

    if rightCommandPressed != isRightCommandPressed {
        self.isRightCommandPressed = rightCommandPressed
        // Handle state change
    }
}
```

### Both Global and Local Monitoring Required

Use **both** monitors to catch events whether the app is focused or not:
- **Global Monitor**: Captures events when app is in background
- **Local Monitor**: Captures events when app is focused

### When to Use Each Approach

**Use NSEvent When:**
- Monitoring modifier keys (Command, Option, Shift, Control)
- Building and testing in Xcode
- Want simpler implementation
- Don't need to modify or block events

**Use CGEvent When:**
- Need to monitor non-modifier keys globally (requires Accessibility)
- Need to modify or block system events
- Building production release (proper code signing resolves DerivedData issues)
- Need lowest-level access to input events

### Implementation Strategy for Midori

1. **Start with NSEvent** during development (works reliably from Xcode)
2. **Test with proper code signing** before deciding if CGEvent is needed
3. **Only switch to CGEvent** if we need features NSEvent can't provide
4. Document which approach is used and why

---

## 4. Version Control

### Required Commits
- `.xcodeproj/xcshareddata/xcschemes/` (shared schemes)
- `build/` in `.gitignore` (if using project-relative builds)
- `/tmp/MidoriBuild` (excluded automatically)
- This best practices document

### Git Protection
Shared schemes ensure team consistency. No local-only scheme variations.

---

## 5. Session Start Protocol

Every development session begins with:

1. ✅ Verify active scheme is `Midori-Debug`
2. ✅ Confirm fixed build location is configured
3. ✅ Check Build Settings if any doubt exists
4. ✅ Verify Debug configuration before first build
5. ✅ Check that permissions are still valid (if doing permission-related work)

---

## 6. Conditional Compilation

Use DEBUG flags for development-only code:

```swift
#if DEBUG
// Debug-specific code (logging, mocks, etc.)
print("🐛 Debug mode active")
#endif
```

---

## 7. Build Enforcement

- Build fails automatically if wrong configuration detected
- No manual intervention needed
- System enforces correctness
- Impossible to accidentally work on wrong build

---

## 8. Future Expansion

When Release builds are needed:
- Create separate `Midori-Release` scheme
- Never modify Debug scheme
- One scheme per configuration (never share schemes across configs)
- Release builds use normal code signing and can live in `/Applications`

---

## Rationale

**Complete control. Zero ambiguity. Minimal friction.**

These practices eliminate the two biggest pain points in macOS development:
1. **Configuration confusion** - Impossible to build wrong configuration
2. **Permission chaos** - Fixed build location means permissions persist

Pre-build verification catches errors before wasted development time. Fixed build locations eliminate the permission reset loop. Proper event monitoring APIs reduce permission requirements during development.

---

## 9. Development Workflow Best Practices

### Git Ignore Essentials

Always include in `.gitignore`:
```
# Xcode
build/
*.xcuserstate
*.xcuserdatad
xcuserdata/
DerivedData/

# macOS
.DS_Store

# Swift Package Manager
.swiftpm/
.build/
```

### Branch Strategy

- **main**: Stable, working features only
- **Feature branches**: Named descriptively (e.g., `menu-bar-app`, `audio-recording`, `global-hotkey`)
- **Merge strategy**: Fast-forward merges after testing
- **No work directly on main**: Always branch for new features

### Testing Before Merge

Before merging any feature:
1. **Build succeeds** (Cmd+B)
2. **Run and test** (Cmd+R)
3. **Console output verified** (Cmd+Shift+Y)
4. **Feature works as expected**
5. **Commit with clear message**
6. **Merge to main**

### Commit Message Format

```
Short imperative summary (50 chars or less)

- Bullet points for implementation details
- What was added/changed/fixed
- Any important technical notes
- References to requirements if applicable
```

### Console Debugging

**ALWAYS** use console logging during development:
- Enable console: **Cmd+Shift+Y**
- Use emoji prefixes for visual scanning:
  - ✓ for success
  - ⚠️ for warnings
  - ❌ for errors
  - 🎤 🔴 📝 etc. for actions
- Print state changes, file paths, key events
- Remove or disable logs in production

### Development Speed Tips

1. **Cmd+R** to build and run (don't use Cmd+B then Cmd+R)
2. **Cmd+Shift+Y** to toggle console
3. **Cmd+9** for build reports
4. Keep console visible during development
5. Use fixed build location for zero permission issues

---

## 10. Architecture Patterns Used

### Separation of Concerns

- **Manager classes**: Single responsibility (KeyMonitor, AudioRecorder, etc.)
- **AppDelegate**: Orchestration and wiring only
- **Callbacks**: For async events (`onRightCommandPressed`, `onAudioLevelUpdate`)
- **Weak self**: Always use `[weak self]` in closures to prevent retain cycles

### File Organization

```
Midori/
├── MidoriApp.swift          # App entry point, AppDelegate
├── ContentView.swift       # SwiftUI views (if needed)
├── KeyMonitor.swift        # Key event monitoring
├── AudioRecorder.swift     # Audio recording logic
└── [Feature]Manager.swift  # Additional feature managers
```

### Error Handling Philosophy

- **Console logging**: For development visibility
- **User feedback**: For production errors (via UI)
- **Graceful degradation**: Continue with reduced functionality if possible
- **Permission checks**: Handle denied permissions gracefully

---

## Reference

- Working NSEvent implementation: `Midori/KeyMonitor.swift`
- Working AVAudioEngine implementation: `Midori/AudioRecorder.swift`
- Project setup guide: `docs/PROJECT_SETUP.md`
