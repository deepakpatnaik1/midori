# Midori - Quick Reference Card

## Build & Run
```bash
./scripts/run.sh              # Build and launch app
./scripts/build.sh            # Build only
./scripts/verify-setup.sh     # Check configuration
```

## In Xcode
- **Build & Run**: Cmd+R
- **Build Only**: Cmd+B  
- **Console**: Cmd+Shift+Y (toggle)
- **Scheme**: Select "Midori-Debug" in toolbar

## File Locations
- **App**: `build/Build/Products/Debug/midori.app`
- **Source**: `midori/`
- **Docs**: `docs/REQUIREMENTS.md` | `docs/BEST_PRACTICES.md`

## Key Concepts
- **Fixed Build**: Same path = permissions persist
- **Debug Only**: Always Debug configuration
- **NSEvent**: No permissions needed for Right Command key
- **Mock Data**: Bypass blockers during development

## When Stuck (3+ Attempts)
1. PAUSE - Stop coding
2. DIAGNOSE - Form hypotheses  
3. TEST - Minimal changes
4. BYPASS - Use mock data if blocked

See `docs/BEST_PRACTICES.md` section 0.5

## Your Role vs Claude's Role
- **You**: Business logic, UX, product decisions
- **Claude**: Implementation, automation, configuration
