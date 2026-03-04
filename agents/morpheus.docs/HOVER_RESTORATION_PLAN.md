# Hover Restoration & Interaction Stabilization Plan (KISS Version)

## 1. Problem Statement
The window collapsing logic is broken because the stable architecture (serialization + debouncing) was stripped away. We must restore a **deterministic** and **consistent** interaction model that handles GTK/Wayland race conditions.

---

## 2. Core Principles (KISS)
- **Service-Owned State**: `WindowService` owns the `_wantsExpanded` flag and serializes all OS calls.
- **Widget Intent**: `TimelineStrip` calculates "Should be Expanded" and forwards intent to the service.
- **Debounced Collapse**: Never collapse immediately. Always use a 150ms buffer to absorb GTK resize artifacts.
- **Suppressed Re-entry**: Always block expansion for 250ms after a collapse to ignore the GTK "shrink artifact" pointer-enter.

---

## 3. Implementation Steps

### Phase 1: WindowService (Serialization)
- **Fix**: Update `expand()` and `collapse()` to `await _enqueueResize()`.
- **Fix**: Remove direct, unawaited calls to `_doExpand()`/`_doCollapse()`.
- **Result**: OS resize calls are strictly sequential; no more "stuck" windows due to racing constraints.

### Phase 2: TimelineStrip (Guards)
- **Logic**: Simplify `_handleMouse`.
  - `shouldExpand = isSettingsOpen || isOverCard || (isOverStrip && hit != null)`
- **Debounce**: Restore `_collapseTimer` (150ms).
  - Capture `_collapsedHeight` at the moment the timer starts (L12).
- **Suppression**: Restore `_suppressTimer` (250ms).
  - Active after collapse fires. Blocks `onEnter` and `onHover`.
- **State Sync**: Only `setState` when `_hoveredEvent` or `_isHoveringStrip` actually changes.

---

## 4. Verification
- **Logs**: Verify `COLLAPSE -> SUPPRESS ARMED -> (Wait 250ms) -> SUPPRESS EXPIRED`.
- **Tests**: Ensure `timeline_strip_test.dart` passes all 202+ tests.
