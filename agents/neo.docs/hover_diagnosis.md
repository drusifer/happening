# Hover Card — Root Cause Diagnosis (2026-03-02)

## Symptom: ALL of the following are broken
1. Black expanded area (transparency)
2. Hover card never shows
3. Card flickers/stutters
4. Accidental expansion on click

## Root Cause Analysis

### Bug 1: Black Expanded Area
**Cause**: `Color(0x00000000)` transparency requires a compositor to work. On Linux/XWayland (Snapdragon ARM), the compositor may not be compositing the GTK window correctly. Without a compositor, transparent pixels render as black.
**Evidence**: `setAsFrameless() + setHasShadow(false) + setBackgroundColor(0x00)` — all three applied but still black.

### Bug 2: Card Flicker / Never Shows (Race Condition)
**Cause**: `expand()` does three sequential async calls:
```dart
await _wm.setMinimumSize(size);   // call 1
await _wm.setMaximumSize(size);   // call 2
await _wm.setSize(size);          // call 3
```
The OS processes these asynchronously. During the resize, the window bounds change mid-frame. The mouse pointer briefly exits the shrinking/growing window boundary → `_onMouseExit` fires → `_collapse()` starts → races against `_expand()`.

**Result**: window flickers between 30px and 250px, or stays collapsed.

### Bug 3: Accidental Click Expansion
**Cause**: On Linux, a click generates:
- `PointerDownEvent` (buttons = 1)
- `PointerMoveEvent` (buttons MAY be 0 briefly — timing-dependent)
- `PointerUpEvent` (buttons = 0)

The `buttons != 0` guard in `_onMouseMove` is unreliable because the move event during a click may arrive with `buttons = 0` depending on GTK event coalescing.

## Why OS Resize is the Wrong Tool
The resize approach requires:
1. OS-level async resize (inherently non-atomic)
2. Compositor transparency support (not guaranteed)
3. Perfect bitmask isolation from click events (unreliable on Linux)

Any one of these failing breaks the feature. All three are unreliable on Linux/XWayland.

---

## Three Alternative Approaches

### Option A: Static Window + setIgnoreMouseEvents (Cleanest)
- Window initializes at 250px **always** (no resize ever)
- `setIgnoreMouseEvents(true, forward: true)` when no card shown → desktop is click-through
- `setIgnoreMouseEvents(false)` when card/settings shown → card is interactive
- `forward: true` lets us receive hover events even while passing clicks through

**Risk**: `setIgnoreMouseEvents` with `forward: true` behaviour on Linux/XWayland is untested. May not forward events on Wayland-based systems.

### Option B: Static Window + Solid Background (Safest, no compositor needed)
- Window initializes at 250px **always**
- Bottom 220px uses a **solid** dark/light background color (not transparent) — no compositor needed
- The strip background is opaque (already done)
- Card is rendered in solid lower area
- No resize = no race condition

**Downside**: Lower area blocks desktop mouse events even when no card shown (window is opaque). Window is always 250px tall — covers top of screen permanently.

### Option C: Fix Resize Approach (Incremental)
- Keep resize but fix race: serialize with a `Completer` chain so expand/collapse never overlap
- Add 200ms debounce on collapse (re-entering strip cancels pending collapse)
- Swap transparent background for solid color (fixes black area, no compositor needed)
- Accept that expand/collapse is slightly laggy on Linux

**Downside**: Still dependent on OS resize reliability. May still flicker.

---

## Recommendation
**Option A** if `setIgnoreMouseEvents(forward: true)` works on XWayland.
**Option B** as fallback if click-through doesn't work.

Need Drew/Morpheus to decide before implementing.
