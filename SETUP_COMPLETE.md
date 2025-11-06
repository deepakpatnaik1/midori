# Midori - Setup Complete

## Build System Configuration ✅

Your Midori project is now configured according to best practices from [BEST_PRACTICES.md](docs/BEST_PRACTICES.md).

### What's Been Automated

#### 1. Fixed Build Location
- **Location**: `build/Build/Products/Debug/midori.app`
- **Why**: Same path every build = macOS permissions persist between rebuilds
- **No more**: Permission reset frustration on every rebuild

#### 2. Debug-Only Workflow
- **Scheme**: `Midori-Debug` (shared, locked to Debug configuration)
- **Configuration**: All build actions use Debug configuration only
- **Optimization**: Disabled (`-Onone`) for fast iteration

#### 3. macOS App Configuration
- **App Sandbox**: Disabled (required for global key monitoring)
- **LSUIElement**: Enabled (menu bar app, no dock icon)
- **Microphone Permission**: Description added for permission prompt

#### 4. Automation Scripts

Located in `scripts/`:

```bash
./scripts/verify-setup.sh         # Verify configuration is correct
./scripts/build.sh                # Build the app
./scripts/run.sh                  # Build and run the app
./scripts/reset-permissions.sh    # Reset macOS permissions (rare)
```

All scripts are executable and ready to use.

#### 5. Git Configuration
- **`.gitignore`**: Configured to ignore build artifacts
- **Shared scheme**: Committed to version control for team consistency

## Next Steps: Start Building Features

### Option 1: In Xcode (Recommended for Mac Development)
```bash
open midori.xcodeproj
```
1. Select `Midori-Debug` scheme in toolbar
2. Press **Cmd+R** to build and run
3. Press **Cmd+Shift+Y** to see console logs

### Option 2: From Terminal
```bash
./scripts/run.sh
```

## Development Workflow

### Key Principles
1. **You (Human)**: Focus on business logic and UX decisions
2. **Claude Code**: Handles all implementation, automation, and configuration

### Debug Workflow
- Always use Debug configuration (enforced by scheme)
- Console logging for visibility (**Cmd+Shift+Y** in Xcode)
- Fixed build location = no permission resets

### Permission Management
- **During Development**: Use mock data to bypass permission dialogs
- **For Testing**: Grant permissions once, they persist across rebuilds
- **NSEvent for Keys**: No accessibility permissions needed for Right Command key

### Three-Strike Rule (When Stuck)
If you hit the same bug 3 times:
1. **PAUSE** - Stop making code changes
2. **DIAGNOSE** - Form 2-3 specific hypotheses
3. **TEST** - Minimal changes to test each hypothesis
4. **BYPASS** - Use mock data if blocked by external systems

See [BEST_PRACTICES.md](docs/BEST_PRACTICES.md) section 0.5 for details.

## Current Project Status

### Implemented ✅
- Xcode project structure
- Build system configuration
- Debug workflow automation
- Documentation and best practices

### To Be Built 🚧
- Menu bar app infrastructure
- Global Right Command key monitoring (NSEvent)
- Audio recording (AVAudioEngine with mock data initially)
- Waveform visualization (9-bar purple-to-cyan gradient)
- whisper.cpp integration
- Text injection at cursor
- User feedback sequence (pop sound, pulsing dots)

## Verification

Run the verification script to confirm everything is set up:

```bash
./scripts/verify-setup.sh
```

Expected output: All checks should show ✅

## Architecture Notes

From [BEST_PRACTICES.md](docs/BEST_PRACTICES.md):

- **Manager pattern**: Separate classes for KeyMonitor, AudioRecorder, etc.
- **Callbacks**: Async event handling via closures
- **Weak self**: Always use `[weak self]` in closures
- **Console logging**: Use emoji prefixes (✓ ⚠️ ❌ 🎤 🔴) for visual scanning

## Build Locations Reference

- **App binary**: `build/Build/Products/Debug/midori.app`
- **Build artifacts**: `build/` (gitignored)
- **Source code**: `midori/`
- **Documentation**: `docs/`
- **Scripts**: `scripts/`

## Ready to Code! 🚀

You now have:
- ✅ Zero-friction build system
- ✅ Persistent permissions across rebuilds
- ✅ Automated common operations
- ✅ Clear separation of concerns (you: business logic, Claude: implementation)

**Open Xcode and let's start building!**
