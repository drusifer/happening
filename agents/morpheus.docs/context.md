# Morpheus Context

## Active Investigation: Linux Window Resize Bugs — 2026-03-18

### Root Cause Identified (CONFIRMED)
`LinuxResizeStrategy.expand()` order is WRONG. GTK expand requires intentional min>max conflict to force compositor to grow.

**Pre-Sprint6 expand (WORKED):**
```
setSize(260)         → advisory, ignored (max still 60)
setMinimumSize(260)  → min=260 > max=60 = INVALID → GTK resolves by GROWING ← forcing mechanism
setMaximumSize(260)  → formalise
```

**Current expand (BROKEN):**
```
setMaximumSize(260)  → lifts cap but no force
setSize(260)         → advisory, ignored
setMinimumSize(260)  → min=max=260, valid constraint, GTK may not resize
```

**Evidence:** 15/17 expand attempts in logs show `isExpanded=true` but `maxHeight=60`. Window never visually expands after first collapse.

### Two Bugs from One Root Cause
- **Bug 1 (no-hover)**: `isExpanded=true` + `maxHeight=60` → HoverDetailOverlay at `top:57` clipped to 3px in 60px window → invisible
- **Bug 2 (nopaint)**: Same + dark mode background → all black

### Sprint 6 Regression Summary
| Component | Status |
|---|---|
| AsyncGate (race condition) | ✅ Fixed |
| LinuxResizeStrategy.collapse() | ✅ Fixed (setSize→setMin→setMax) |
| LinuxResizeStrategy.expand() | ❌ BROKEN (wrong order, needs revert to pre-S6) |
| HoverController wired | ✅ Done |
| LinuxHoverController suppress timer | ✅ Fixed (only on actual expand transition) |

### ARCH-002 Decision
**LinuxResizeStrategy.expand() must use:** `setSize → setMinimumSize → setMaximumSize`
**NOT:** `setMaximumSize → setSize → setMinimumSize`

Rationale: GTK forces window growth via min>max conflict. New order removes the conflict and the force.

### Also: onExpanded() timing
`onExpanded()` fires after `setMinimumSize()` but GTK applies resize asynchronously. Flutter rebuilds in expanded state before OS window actually resizes. This causes the clipped rendering. May need to move `onExpanded()` to fire AFTER all resize ops AND after a brief yield to let GTK apply.

## Previous Context
### Sprint 6: macOS build — 2026-03-07
- v0.2.0 shipped. Starting macOS v0.2.1 build.
- CRITICAL BLOCKER: `window_service.dart` has top-level `DynamicLibrary.open('shell32.dll')` — crashes on macOS at module load time. Must lazify + guard with Platform.isWindows.
- RISK: Release.entitlements missing `network.server` — PKCE auth binds localhost server, will fail in release build. Must add to Release.entitlements.
