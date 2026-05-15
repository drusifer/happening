# Architecture: Pass-Through Removal + Send-to-Back
**Date**: 2026-05-13
**Status**: Draft — Awaiting Smith Gate 2

---

## Summary

Remove all click-through/pass-through infrastructure. Replace with a uniform "send to back" behavior across all platforms. The architecture simplifies in every dimension: fewer interface methods, no platform branching in the focus model, no `WindowMode.transparent` special-casing anywhere.

---

## Component Map (Before → After)

### `WindowInteractionStrategy` hierarchy

**Before:**
```
WindowInteractionStrategy (abstract, factory)
  MacOsWindowInteractionStrategy   — setPassThrough via setIgnoreMouseEvents(forward:true)
  WindowsWindowInteractionStrategy — setPassThrough via setIgnoreMouseEvents; supportsTransparentPassThrough flag
```

**After:**
```
WindowInteractionStrategy (abstract, factory)
  BaseWindowInteractionStrategy (new, concrete)   — sendToBack / restoreToFront
    MacOsWindowInteractionStrategy                — availability: supportsReserved=false
    ReservedWindowInteractionStrategy             — availability: supportsReserved=true  [renamed from Windows]
```

Factory routing:
- macOS   → `MacOsWindowInteractionStrategy`
- Linux   → `ReservedWindowInteractionStrategy`
- Windows → `ReservedWindowInteractionStrategy`

### Interface changes

**`WindowInteractionStrategy` interface — methods removed:**
- `setPassThrough(bool)` — deleted
- `setFocused(bool)` — deleted (was no-op in reserved mode; transparent mode gone)

**`WindowInteractionStrategy` interface — methods added:**
- `sendToBack()` — implemented in base: `setAlwaysOnTop(false)` + `blur()` + `lower()`
- `restoreToFront()` — implemented in base: `setAlwaysOnTop(true)`

**`WindowModeAvailability` — field removed:**
- `supportsTransparent` — deleted

**`WindowModeAvailability` — remains:**
- `supportsReserved: bool`

### `WindowMode` enum

```dart
// Before
enum WindowMode { transparent, reserved }

// After
enum WindowMode { overlay, reserved }
```

`SettingsService.fromString` fallback: `'transparent'` → `WindowMode.overlay` (silent migration, no prompt).

### `WindowService` — methods removed

| Removed | Reason |
|---------|--------|
| `setPassThroughEnabled(bool)` | pass-through gone |
| `supportsTransparentPassThrough()` | pass-through gone |
| `setInteractionFocused(bool)` | transparent focus model gone; no callers after T-06 |
| `supportsTransparentPassThroughForTesting` ctor param | gone |

### `WindowService` — methods added

```dart
Future<void> sendToBack() => _interactionStrategy.sendToBack();
Future<void> restoreToFront() => _interactionStrategy.restoreToFront();
```

### `TimelineFocusController` — full redesign

**Before**: dual-mode controller managing transparent idle state + reserved interactive state, with `usesTransparentFocusModel` branching everywhere, inactivity timer driving pass-through re-enable.

**After**: single-purpose controller managing send-to-back state + auto-restore timer.

```dart
class TimelineFocusController extends ChangeNotifier {
  // Removed: _windowMode, _isFocused, _isInteractionHeld, isFocusedNotifier
  // Removed: usesTransparentFocusModel, initialize(), focus(), unfocus(),
  //          handleEscape(), handleWindowFocusLost(), registerUserActivity(),
  //          setInteractionHold(), setWindowMode()
  // Removed: _enterIdleTransparentState(), _enterInteractiveState()

  bool _isSentToBack = false;
  Timer? _restoreTimer;
  final Duration restoreTimeout; // default: const Duration(seconds: 10)

  final ValueNotifier<bool> isSentToBackNotifier = ValueNotifier(false);
  bool get isSentToBack => _isSentToBack;

  Future<void> sendToBack() async {
    _setSentToBack(true);
    await _windowService.sendToBack();
    _restartRestoreTimer();       // re-press resets timer
  }

  Future<void> restoreToFront() async {
    _cancelRestoreTimer();
    _setSentToBack(false);
    await _windowService.restoreToFront();
  }

  void _restartRestoreTimer() {
    _cancelRestoreTimer();
    _restoreTimer = Timer(restoreTimeout, () => unawaited(restoreToFront()));
  }
}
```

Key properties:
- Re-press while sent-back: calls `sendToBack()` again → `_restartRestoreTimer()` resets the 10s clock. Timer reset is confirmed visually by the brief state-toggle feedback in the button (Smith requirement).
- Restore does NOT steal focus: `restoreToFront()` only calls `setAlwaysOnTop(true)`, no `wm.focus()`.

### `TimelineStrip` — changes

**Removed:**
- `_clickThroughTimer` field (timer moves to `TimelineFocusController`)
- Direct calls to `_windowService.setPassThroughEnabled()`
- All `_focusController.usesTransparentFocusModel` / `_focusController.isFocused` references
- `_focusController.isFocusedNotifier` listener → replaced with `isSentToBackNotifier`
- `_transparentIdle` / `_isTransparentIdle` state

**Updated:**
- Send-to-back button: calls `_focusController.sendToBack()` — available on ALL platforms (no capability gate)
- Button icon: `Icons.flip_to_back` (Smith-approved)
- Button active state: lit when `_focusController.isSentToBack == true`; brief flash on re-press

---

## Sequence Diagram — Send to Back

```
User                TimelineStrip       TimelineFocusController   WindowService   OS
 |                       |                       |                     |           |
 |--press button-------->|                       |                     |           |
 |                       |--sendToBack()-------->|                     |           |
 |                       |                       |--sendToBack()------>|           |
 |                       |                       |                     |--setAlwaysOnTop(false)→|
 |                       |                       |                     |--blur()-------------->|
 |                       |                       |                     |--lower()------------->|
 |                       |                       |  start 10s timer    |           |
 |                       |<-notifyListeners()--  |                     |           |
 |          (button active state shown)          |                     |           |
 |          (strip now behind other windows)     |                     |           |
 |                                               |                     |           |
 |  (10 seconds elapse)                          |                     |           |
 |                       |                       |--restoreToFront()-->|           |
 |                       |                       |  cancel timer       |--setAlwaysOnTop(true)->|
 |                       |<-notifyListeners()--  |                     |           |
 |          (button returns to normal state)     |                     |           |
 |          (strip returns to always-on-top)     |                     |           |
```

---

## Risk Register

| Risk | Severity | Mitigation |
|------|----------|------------|
| `wm.lower()` not available or unreliable on Linux GTK | Medium | Check `window_manager` Linux plugin for `lower()`. If absent, fall back to `setAlwaysOnTop(false)` only — most WMs will lower the window on the next click anyway. |
| `wm.blur()` no-op on some Linux WMs | Low | `setAlwaysOnTop(false)` + `lower()` is sufficient. `blur()` is best-effort. |
| `setAlwaysOnTop` on Linux: GTK `keep_above` toggle timing | Low | This is well-tested in existing code (app already uses it at startup). No new risk. |
| `isFocusedNotifier` has callers beyond `TimelineStrip` | Low | Grep confirms only `TimelineStrip` holds the listener. Safe to replace with `isSentToBackNotifier`. |
| `HoverFocusController` uses `focusController.isFocused` | Medium | Check `HoverFocusController` — it was only active in transparent mode. With transparent gone, it either becomes a no-op or needs to be removed. |
| Settings migration: `windowMode: "transparent"` saved on disk | Low | `fromString` fallback → `overlay`. Silent, no user prompt needed. |

---

## `HoverFocusController` — decision required

`HoverFocusController` wraps `TimelineFocusController` and calls `focus()`/`unfocus()` on hover enter/leave. In the new model, `focus()`/`unfocus()` no longer exist. 

Decision: **Remove `HoverFocusController`** or reduce it to a no-op wrapper.

`HoverFocusController` is only active when `focusController.usesTransparentFocusModel` is true (see `hover_focus_controller.dart:6`). Since transparent mode is gone, it is entirely inert after this sprint. Remove it entirely to avoid dead code.

---

## Phase Implementation Order (confirming T-01 through T-13)

Phase 1 (cleanup) must complete and reach green tests before Phase 2 begins.

**Critical ordering within Phase 1:**
1. T-02 (`WindowMode` rename) first — other tasks depend on this compile
2. T-03 + T-04 together — interface changes and hierarchy refactor are coupled; do as one commit
3. T-05 (`WindowService` purge) after T-03/T-04 compile
4. T-06 (`TimelineFocusController` simplify) after T-05 (removes callers)
5. T-07 (tests green) — gate before Phase 2

**Phase 2 is additive:** T-08 → T-09 → T-10 → T-11 can each be a clean commit with tests.

---

## Files Changed Summary

| File | Change |
|------|--------|
| `lib/core/window/interaction_strategy/window_interaction_strategy.dart` | Remove `setPassThrough`, `setFocused` from interface; add `sendToBack`, `restoreToFront`; remove `supportsTransparentPassThrough` factory param; update factory routing |
| `lib/core/window/interaction_strategy/base_window_interaction_strategy.dart` | **NEW** — concrete base with `sendToBack`/`restoreToFront` impl |
| `lib/core/window/interaction_strategy/macos_window_interaction_strategy.dart` | Extend base; remove `setPassThrough`/`setFocused`; override `availability` only |
| `lib/core/window/interaction_strategy/windows_window_interaction_strategy.dart` | **RENAME** → `reserved_window_interaction_strategy.dart`; extend base; remove pass-through |
| `lib/core/window/window_service.dart` | Remove `setPassThroughEnabled`, `supportsTransparentPassThrough`, `setInteractionFocused`; add `sendToBack`, `restoreToFront` |
| `lib/core/settings/settings_service.dart` | `WindowMode.transparent` → `WindowMode.overlay`; update `fromString` fallback |
| `lib/features/timeline/focus/timeline_focus_controller.dart` | Full redesign — `_isSentToBack` model, 10s restore timer |
| `lib/features/timeline/focus/hover_focus_controller.dart` | **DELETE** — dead code after transparent mode removal |
| `lib/features/timeline/timeline_strip.dart` | Remove `_clickThroughTimer`, pass-through calls, transparent branching; wire send-to-back button |
| `lib/main.dart` | Remove `supportsTransparentPassThroughForTesting` param + comment |
| All test files (6) | Remove pass-through stubs; replace with send-to-back coverage |
