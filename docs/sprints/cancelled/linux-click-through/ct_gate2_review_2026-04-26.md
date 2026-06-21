# Smith Gate 2 Review — Linux Click-Through Architecture
**Date:** 2026-04-26
**Status:** APPROVED with notes

---

## Architecture Verdict: ✅ Approved

The architecture correctly addresses all three UX questions from Gate 1.

---

## Phase Review

### Phase A — Detection + Plugin Port ✅
No user-visible changes except that transparent support is now driven by real runtime detection instead of a smoke flag. This is strictly better — users on XWayland no longer have to discover click-through is broken after enabling it.

### Phase B — Layer-Shell Positioning ✅ with note

Architecture is correct. One note for Neo during implementation:

**Exclusive zone:** The architecture draft sets `exclusive_zone = 1`. For transparent mode the strip floats over content — it should NOT reserve any desktop space. Correct value is `exclusive_zone = 0` (no reserved space). Reserved mode (X11 path) handles space reservation via the existing `window_manager` strut path. Neo: set `gtk_layer_shell_set_exclusive_zone(window, 0)` for the transparent Wayland anchor.

### Phase C — Integration + Polish ✅

`HoverFocusController` design exactly matches my Q2 answer. One implementation constraint to verify:

**Focus release on hover-card collapse:** When the hover card closes (user clicks away, presses Escape, or moves cursor off the strip), `setFocused(false)` must be called. The `onExit` handler in `HoverFocusController` covers cursor-leave. Verify that the existing hover-card dismiss path also calls `windowService.setFocused(false)` — or that `onExit` always fires when the card closes (if the card dismissal moves focus elsewhere first). Neo and Trin: confirm this in UAT for CT-03.

---

## UX Checklist

| Requirement | Architecture | Verdict |
|---|---|---|
| Hover 300ms primary focus trigger | `HoverFocusController` with 300ms `Timer` | ✅ |
| Hotkey secondary (not removed) | Existing `TimelineFocusHotkeyBinding` unchanged | ✅ |
| Both paths converge on `setFocused()` | Yes — single `WindowService.setFocused()` entry point | ✅ |
| CT-04 inline, always visible, no jargon | Confirmed — below disabled option, prescribed text | ✅ |
| Soft gate — app always launches | `isLayerShellAvailable()` soft-gates, no crash/dialog | ✅ |
| XWayland: disabled + explanation | `linuxTransparentSupported = false`, CT-04 text shown | ✅ |
| X11 reserved mode untouched | `GDK_BACKEND=x11` path unchanged | ✅ |
| No `gtk-layer-shell` / `XWayland` jargon to user | Architecture uses internal symbols only; CT-04 text is jargon-free | ✅ |

---

## Approved Notes Summary for Neo/Trin

1. **Phase B exclusive zone**: `gtk_layer_shell_set_exclusive_zone(window, 0)` — not 1.
2. **CT-03 focus release**: Verify hover-card dismiss always fires `setFocused(false)` before UAT sign-off.

---

## Handoff

Architecture approved. @Mouse *sm plan sprint CT
