# F-31 Timestrip Hide/Show — Architecture

**Date:** 2026-06-11  
**Author:** Morpheus  
**Stories:** `agents/cypher.docs/f31_timestrip_hide_stories.md`  
**Smith Gate 1 review:** `agents/smith.docs/f31_gate1_review_2026-06-11.md`

---

## 1. Design Decisions

### D1 — No new controller class; state lives in `_TimelineStripState`
The hide/show cycle is always user-triggered (never debounced, never raced), so the serialisation
machinery of `ExpansionController` is unnecessary. A simple `bool _isHidden` flag in
`_TimelineStripState` plus an `AnimationController` is sufficient and consistent with how other
one-shot user actions (settings open/close, send-to-back) are handled.

### D2 — Animation is a Flutter-only width contraction; OS window resizes once per transition
Calling `windowManager.setSize()` on every animation frame (60fps × 300ms = 18 calls) would
flood the platform channel. Instead:
- **Hide**: Flutter `AnimationController` drives a width tween inside the full-size OS window.
  At animation end, a single `wm.setSize(miniSize)` snaps the OS window to the mini footprint.
- **Show**: `wm.setSize(fullSize)` first (instant, OS window expands), then the Flutter
  `AnimationController` runs the reveal animation.

This means during the hide animation the OS window is still full-width but the strip content
visually contracts. The background is transparent so the extra area is invisible.

### D3 — Strut/AppBar released BEFORE animation, re-acquired AFTER animation
- On hide: `onHideStrip()` hook fires before `_hideAnim.reverse()` starts. Strut is gone
  before the animation begins, so other windows can expand immediately.
- On show: `onShowStrip()` hook fires after `_hideAnim.forward()` completes. Strut is
  re-acquired after the strip is fully visible, not while it's mid-animation.

This satisfies AC-F31-4-1 ("released before or during") and AC-F31-4-2 ("re-acquired immediately
after the show animation completes").

### D4 — Z-order override for mini widget (resolves Smith Note C)
The always-on-top guarantee (AC-F31-2-5) must survive even when the strip was in send-to-back
mode before hiding.

- On `_hideStrip()`: save `_preHideSentToBack = _focusController.isSentToBack`; if true, call
  `_windowService.restoreToFront()` BEFORE hiding, then call `wm.setAlwaysOnTop(true)` to lock
  the mini widget on top.
- On `_showStrip()`: after the animation, restore interaction state:
  - If `_preHideSentToBack` was true, re-apply send-to-back via `_focusController.sendToBack()`.
  - Otherwise, no action needed (window was already always-on-top).

### D5 — Mini width is computed, not measured
AC-F31-2-4 calls for "content-width." Rather than a layout measurement pass (which adds a frame
of latency), mini width is computed:

```dart
double _miniWidth(double fontSizePx) =>
    fontSizePx * 6.0 + 12.0  // countdown text + padding
    + 8.0                      // gap
    + 24.0                     // show button icon
    + 8.0 * 2;                 // button horizontal padding
```

This formula derives from the same `fontSize * 6.0` countdown estimate already used at line 551
of `timeline_strip.dart` for `countdownEst`. If Neo finds the formula is too tight after
integration testing, it can be widened — no AC specifies a pixel count.

### D6 — Hook terminology: `onHideStrip` / `onShowStrip` on `WindowService`
Following the existing virtual hook pattern (`onWindowModeChanged`, `onDisplayChangedExtra`,
`onHideStrip`, `onShowStrip`):
- Base `WindowService`: no-op implementations (return immediately).
- `LinuxWindowService`: calls `_linuxDock.undock()` / `_reserveLinuxStrut()`.
- `WindowsWindowService`: calls `_disposeAppBar()` / `_registerAppBar()`.
- `MacOSWindowService`: inherits no-op (AC-F31-5-3 — macOS has no reservation).

---

## 2. Modified Files

### `app/lib/core/window/window_service.dart`

**Correction from plan review**: `onHideStrip()`/`onShowStrip()` are `@protected` and `wm` is
`@protected` — neither is callable from `_TimelineStripState` outside the class hierarchy.
Add four public methods to `WindowService` that wrap the protected internals:

```dart
// Returns mini strip width in logical pixels for the given font size.
double getMiniWidth(double fontSizePx) =>
    fontSizePx * 6.0 + 12.0 + 8.0 + 24.0 + 16.0;

/// Called by _TimelineStripState before hide animation starts.
/// Releases platform reservation (strut on Linux, AppBar on Windows).
Future<void> prepareToHide() async => onHideStrip();

/// Called by _TimelineStripState after show animation completes.
/// Re-acquires platform reservation.
Future<void> completeShow() async => onShowStrip();

/// Resizes OS window to the mini strip footprint (called at hide-animation end).
Future<void> resizeToMiniStrip(double fontSizePx) async {
  await wm.setSize(Size(getMiniWidth(fontSizePx), getCollapsedHeight()));
}

/// Resizes OS window to full strip width (called at show-animation start).
Future<void> resizeToFullStrip() async {
  await wm.setSize(Size(_screenWidth, getCollapsedHeight()));
}
```

The protected hooks remain `@protected` — subclasses override them; the public wrappers are
the only surface `_TimelineStripState` touches.

Add virtual hooks (alongside existing `onWindowModeChanged` etc.):
```dart
@protected
Future<void> onHideStrip() async { return; }

@protected
Future<void> onShowStrip() async { return; }
```

### `app/lib/core/window/linux_window_service.dart`
```dart
@override
Future<void> onHideStrip() async {
  if (windowMode == WindowMode.reserved) {
    await _linuxDock.undock();
  }
}

@override
Future<void> onShowStrip() async {
  if (windowMode == WindowMode.reserved) {
    await _reserveLinuxStrut();
  }
}
```

### `app/lib/core/window/windows_window_service.dart`
```dart
@override
Future<void> onHideStrip() async {
  if (!_enableWindowsAppBar) return;
  _disposeAppBar();
}

@override
Future<void> onShowStrip() async {
  if (!_enableWindowsAppBar) return;
  if (windowMode == WindowMode.reserved) {
    await _registerAppBar();
  }
}
```

### `app/lib/features/timeline/timeline_strip.dart`

**New state variables (in `_TimelineStripState`):**
```dart
bool _isHidden = false;
bool _preHideSentToBack = false;
late final AnimationController _hideAnim;
```

**In `initState()`:**
```dart
_hideAnim = AnimationController(
  vsync: this,                   // _TimelineStripState already has WidgetsBindingObserver
  duration: const Duration(milliseconds: 300),
  value: 1.0,                    // 1.0 = fully visible
)..addListener(() { if (mounted) setState(() {}); });
```

Note: `_TimelineStripState` must add `SingleTickerProviderStateMixin` (or use the existing
`WidgetsBindingObserver` — check if `vsync` from `TickerProvider` is available, otherwise add
`with SingleTickerProviderStateMixin`).

**New methods:**
```dart
Future<void> _hideStrip() async {
  // Save pre-hide state
  _preHideSentToBack = _focusController.isSentToBack;

  // Z-order: ensure mini widget is always-on-top
  if (_preHideSentToBack) {
    await _focusController.restoreToFront();
  }

  // Release strut/AppBar before animation (AC-F31-4-1)
  await _windowService.prepareToHide();

  // Collapse settings if open (AC-F31-3-4 equivalent — clean state on hide)
  if (_isSettingsOpen) {
    setState(() { _isSettingsOpen = false; });
    _expansionController.send(ExpansionState.collapsed);
  }

  setState(() { _isHidden = true; });

  // Run visual animation (full → mini)
  await _hideAnim.reverse();

  // Snap OS window to mini size
  await _windowService.resizeToMiniStrip(
      widget.settingsService.current.fontSizePx);
}

Future<void> _showStrip() async {
  // Expand OS window before animation
  await _windowService.resizeToFullStrip();

  // Switch widget tree to full content
  setState(() {
    _isHidden = false;
    _isHoveringStrip = false;  // AC-F31-3-4
  });
  _expansionController.send(ExpansionState.collapsed);  // AC-F31-3-4

  // Run visual animation (mini → full)
  await _hideAnim.forward();

  // Re-acquire strut/AppBar after animation (AC-F31-4-2)
  await _windowService.completeShow();

  // Restore pre-hide z-order
  if (_preHideSentToBack) {
    await _focusController.sendToBack();
    _preHideSentToBack = false;
  }
}
```

**Hide button widget** (new private class, file-local):
```dart
class _HideButton extends StatelessWidget {
  const _HideButton({required this.onTap, required this.stripBackgroundColor});
  final VoidCallback onTap;
  final Color stripBackgroundColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      child: Icon(Icons.arrow_left, color: stripBackgroundColor.computeLuminance() > 0.5
          ? Colors.black54 : Colors.white70),
    ),
  );
}
```

Note: `Icons.arrow_left` is a rectangular-style left arrow consistent with Material chevron
weight. Neo should verify this matches the "rectangular arrow button" description in AC-F31-1-1;
if the icon shape is wrong, substitute a suitable Material icon (e.g. `Icons.chevron_left`
drawn at a larger size, or a custom painter). The 24×24 `minWidth`/`minHeight` in `BoxConstraints`
satisfies AC-F31-1-5 (Smith Note B).

**`_buildLeftToolbar` modification:**
Prepend the hide button BEFORE the existing Row in `_buildLeftToolbar`. Since the AC says
"far-left edge of the timestrip," it should be at `left: 0`, not `left: 8`. The existing
toolbar starts at `left: 8`; we'll position the hide button at `left: 0` separately:

```dart
// In _buildLayout, add before _buildLeftToolbar call:
if (!isAuthPrompt && !_isHidden)
  Positioned(
    left: 0,
    top: 0,
    height: _collapsedHeight,
    child: Center(
      child: _HideButton(
        onTap: () => unawaited(_hideStrip()),
        stripBackgroundColor: stripBg,
      ),
    ),
  ),
```

The existing left toolbar remains at `left: 8` (giving the hide button its own 8px lane before
the toolbar starts).

**Mini widget build path (in `_buildLayout`):**
When `_isHidden = true`, return a minimal widget instead of the full Stack. The `_hideAnim.value`
drives the animated width while the animation is in progress:

```dart
if (_isHidden || _hideAnim.value < 1.0) {
  return _buildMiniWidget(context, constraints);
}
```

```dart
Widget _buildMiniWidget(BuildContext context, BoxConstraints constraints) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,      // Smith Note A: pointer cursor
    child: GestureDetector(
      onTap: () => unawaited(_showStrip()), // AC-F31-3-2: countdown tap
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCountdownPositioned(context, _layout ?? _buildFallbackLayout(constraints), outerMode),
          GestureDetector(
            onTap: () => unawaited(_showStrip()),
            child: Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_right, size: 18),
            ),
          ),
        ],
      ),
    ),
  );
}
```

Note: Both the countdown row and the → button call `_showStrip()` (satisfying AC-F31-3-1 and
AC-F31-3-2). The `MouseRegion(cursor: SystemMouseCursors.click)` wrapping the entire mini widget
satisfies Smith Note A (pointer cursor affordance for the clickable countdown).

---

## 3. Phase Plan (for Mouse)

| Phase | Tasks | Owner | Gate |
|-------|-------|-------|------|
| A — WindowService hooks | F31-A1: hooks + tests on base; F31-A2: Linux + Windows overrides + tests | Neo + Trin | make test green |
| B — Strip UI | F31-B1: state flag + anim controller + hide/show methods + tests; F31-B2: hide button + mini widget + tests | Neo + Trin | make test green |
| C — UAT + Docs | F31-C1: manual UAT (Trin); F31-C2: Smith UX pass; F31-C3: Oracle docs | Trin + Smith + Oracle | Smith approve |

Dependency: A → B → C. Phases are strictly sequential (each requires the previous to be green).

---

## 4. Test Plan

| Test | File |
|------|------|
| `_isHidden` starts false; `hideStrip()` → true; `showStrip()` → false | `timeline_strip_hide_test.dart` |
| Countdown continues updating while hidden (StreamBuilder still wired) | `timeline_strip_hide_test.dart` |
| Hide with send-to-back active → restoreToFront called; show → sendToBack re-applied | `timeline_strip_hide_test.dart` |
| Settings close if open on hide | `timeline_strip_hide_test.dart` |
| LinuxWindowService: `onHideStrip` calls undock; `onShowStrip` calls dock | `linux_window_service_test.dart` |
| LinuxWindowService: no strut ops if windowMode = sendToBack | `linux_window_service_test.dart` |
| WindowsWindowService: `onHideStrip` disposes AppBar; `onShowStrip` registers | `windows_window_service_test.dart` |
| Hide/show cycle repeatable (AC-F31-3-5) | `timeline_strip_hide_test.dart` |

---

## 5. Out-of-Scope Confirmations

- Keyboard shortcut: deferred per story
- Multi-monitor variant: F-30 already handles display selection; no changes needed here
- macOS reservation: no-op (virtual hook base returns immediately)
- Countdown format or urgency logic: untouched

---

*Morpheus — 2026-06-11*
