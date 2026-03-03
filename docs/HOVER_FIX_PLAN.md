# Hover Fix & Interaction Stabilization Plan (Stable Version)

## 1. Problem Statement
The application needs to show detailed "Hover Cards" for calendar events. Since the app is a 30px strip, these cards must escape the window bounds. OS-level window resizing is the chosen method, but it has been plagued by race conditions and accidental "click-to-expand" behavior.

---

## 2. Lessons Learned (The "Stop Looping" List)

### Early Lessons (Sprint 4)
- **Multi-Window is Unstable**: Spawning a second OS window for cards crashes the Linux compositor (GTK/OpenGL errors). **Abandoned.**
- **OS Resize Latency**: The card must be rendered in the same frame as the resize request to avoid clipping.
- **Linux Event Echo**: Clicks on Linux fire simultaneous move/hover events. Without a cooldown, a click will always trigger a hover-expansion. Fix: remove click event handlers on event objects entirely.
- **Animation Bottleneck**: `pumpAndSettle` cannot be used in tests because of the 1Hz repeating clock animation. Fix: Control via `enableAnimations` flag when testing.
- **Bitmask Insufficiency**: A simple bitmask check in `onHover` is effective only if there are NO other listeners for clicks.
- **The "Click Desert" Realization**: If the goal is hover-only, there should be zero code listening for clicks in the event area.

### Sprint 5 Lessons (GTK/Wayland Race Conditions)

#### L1 — setMinimumSize BEFORE setSize fires pointer-leave
Calling `setMinimumSize(250)` before `setSize(250)` on GTK causes an immediate constraint-enforced resize. This fires a spurious `pointer-leave` event → `_onMouseExit` → card collapses before rendering.
**Fix**: Always call `setSize` FIRST (smooth resize, cursor stays inside, no pointer-leave). Then `setMinimumSize`/`setMaximumSize` as enforcement backup.

#### L2 — GTK/Wayland correct resize call order
- **Expand**: `setSize(250)` → `setMinimumSize(250)` → `setMaximumSize(250)`
- **Collapse**: `setMinimumSize(30)` → `setMaximumSize(30)` → `setSize(30)`
  (Must lower the min constraint first so GTK allows shrinking below the previous min.)

#### L3 — setResizable(false) can silently throttle setSize
After `setResizable(false)` is set (especially following settings interaction), `setSize` alone may be silently ignored. The `setMinimumSize`/`setMaximumSize` calls serve as enforcement backup — they force the compositor to comply even when `setSize` is throttled.

#### L4 — GTK ARGB visual requires explicit calls
`setAsFrameless()` and `setBackgroundColor(Color(0x00000000))` must be called explicitly in the `waitUntilReadyToShow` callback — NOT just in `WindowOptions`. Without them, GTK allocates an RGB (non-transparent) visual. The compositor cannot make the background transparent, resulting in a solid black window.

#### L5 — Concurrent async calls interleave on GTK channel
With 3 async calls each in expand/collapse, concurrent invocations interleave:
- Example: collapse's `setMaximumSize(30)` arrives → expand's pending `setSize(250)` is rejected (250 > max=30) → expand's `setMinimumSize(250)` forces window to 250 via constraint → new pointer-leave → debounce → loop → stuck expanded.
**Fix**: Serialize all resize operations in `WindowService` (see Architecture section).

#### L6 — Widget boolean mirroring OS state is always stale
`_isExpanded` boolean in the widget tries to mirror async OS state. During any async transition it is wrong. Concurrent calls bypass the guard. **This is the root cause of all race conditions.**
**Fix**: The guard belongs in `WindowService`, not the widget.

#### L7 — 150ms debounce absorbs GTK spurious pointer-leave
GTK fires pointer-leave during window resize animation. A 150ms debounce on `_onMouseExit` absorbs these spurious events. The timer is cancelled by `_onMouseMove` on re-entry.

#### L8 — Settings open must block debounce collapse
`_isSettingsOpen` is set by explicit user action and must NOT be auto-closed by spurious mouse exit during resize. Add `if (_isSettingsOpen) return;` in the debounce callback.

#### L9 — _inFlight stuck non-null permanently blocks all future collapses
If any platform channel call inside `_doExpand()` or `_doCollapse()` throws (e.g. `setMinimumSize` after `setSize` succeeds), the exception propagates before `_inFlight = null` runs. `_inFlight` stays forever non-null. Every subsequent `collapse()` call sees `_inFlight != null` → returns immediately → window stuck expanded permanently.
**Fix**: Wrap `await _inFlight` in `try/finally` so `_inFlight = null` always runs regardless of exceptions.
```dart
try {
  await _inFlight;
} finally {
  _inFlight = null;
}
```

#### L10 — GTK fires spurious pointer-enter after window collapses (shrink artifact)
When the window collapses from 250px to 35px, if the cursor is physically within the top 35px (the strip), GTK fires a `pointer-enter` event for the newly-shrunken window. Flutter sees this as a genuine re-entry → `onEnter` + `onHover` fire → event hit found → `expand()` called → window immediately re-expands → debounce fires again → loop. The window appears "stuck expanded" or flickers.
**Fix**: Arm a 250ms `_suppressExpandTimer` at the moment the debounce fires collapse. While the timer is live, all mouse events (`onEnter` and `onHover`) are no-ops. After 250ms the next genuine mouse move re-evaluates normally.

#### L11 — Hover state variables must all gate on the same suppress flag
Setting `_hoveredEvent` in `_onMouseMove` while skipping `expand()` (inconsistent suppress check placement) leaves `_hoveredEvent` non-null after collapse. On the next hover event, `hit?.id == _hoveredEvent?.id` is true → early return → `expand()` never fires even after suppress expires. Window stays collapsed silently.
**Fix**: The suppress check must be a single early return at the TOP of `_onMouseMove`, before any state mutation. Apply the same guard to `onEnter`. This keeps `_isHoveringStrip`, `_hoveredEvent`, and the expand call all consistent.
```dart
// In onEnter and at top of _onMouseMove:
if (_suppressExpandTimer != null) return;
```

#### L12 — Capture collapsed height at exit time, not at timer-fire time
`_collapsedHeight` is a build-time side-effect field. Reading it 150ms later (when the debounce timer fires) risks using a stale value if a rebuild occurred between exit and timer fire.
**Fix**: Capture as a local variable when `_onMouseExit` fires:
```dart
final collapsedHeight = _collapsedHeight;
_collapseTimer = Timer(..., () {
  _windowService.collapse(height: collapsedHeight); // captured, not field
});
```

---

## 3. Final Architecture: Morpheus Pattern

The correct architecture (documented by Morpheus/TL in `agents/morpheus.docs/async_architecture.md`):

### Rule: Service owns state, widget expresses intent
- `WindowService` owns `_wantsExpanded` — the desired state.
- `WindowService` owns `_inFlight` — the in-flight serialization mutex.
- Widget has **no** `_isExpanded` field. It calls `windowService.expand()` or `windowService.collapse()` directly.

### _enqueueResize() — Single-flight serialization with error safety
```dart
Future<void> _enqueueResize() async {
  if (_inFlight != null) return;   // already running, desired state already updated
  bool want;
  do {
    want = _wantsExpanded;
    _inFlight = want ? _doExpand() : _doCollapse();
    try {
      await _inFlight;
    } finally {
      _inFlight = null; // ALWAYS reset — platform throws must not leave this stuck
    }
  } while (_wantsExpanded != want); // re-run if state changed mid-flight
}
```

### expand() / collapse() — Idempotent, serialized
```dart
Future<void> expand() async {
  if (_wantsExpanded) return;    // idempotent
  _wantsExpanded = true;
  await _enqueueResize();
}

Future<void> collapse({double? height}) async {
  if (height != null) _lastHeight = height;
  if (!_wantsExpanded) return;   // idempotent
  _wantsExpanded = false;
  await _enqueueResize();
}
```

### _doExpand() / _doCollapse() — Correct GTK call order
```dart
Future<void> _doExpand() async {
  final size = Size(_lastWidth, _kExpandedHeightLogical);
  await _wm.setSize(size);        // smooth resize first — cursor stays inside, no pointer-leave
  await _wm.setMinimumSize(size); // enforcement backup
  await _wm.setMaximumSize(size); // lock max
}

Future<void> _doCollapse() async {
  final size = Size(_lastWidth, _lastHeight);
  await _wm.setMinimumSize(size); // allow shrink first
  await _wm.setMaximumSize(size); // lock max
  await _wm.setSize(size);        // then resize
}
```

---

## 4. The Approach: "Click Desert" + Strict Bitmask + Serialized Resize

### Phase A: Total Transparency
- Set `MaterialApp` and `Scaffold` to `Colors.transparent`.
- Explicit opaque backgrounds added to the 30px strip and hover cards to ensure visibility.
- `setAsFrameless()` + `setBackgroundColor(Color(0x00000000))` called explicitly in `waitUntilReadyToShow` callback for GTK ARGB visual.

### Phase B: Click Desert (Handler Removal)
- **Root Removal**: The root `GestureDetector` and `Listener` have been removed. The timeline area has NO handlers for clicks.
- **Isolated Handlers**: Only the Settings and Refresh icons have `GestureDetector` wrappers.
- **Strict Bitmask**: `_onMouseMove` explicitly returns if `details.buttons != 0`. Most robust way to ignore clicks masquerading as hovers.

### Phase C: Serialized Window Resize (Morpheus Architecture)
- `WindowService` holds all resize state and serializes calls via `_enqueueResize()`.
- `_enqueueResize()` uses `try/finally` to guarantee `_inFlight = null` even on platform exceptions.
- Widget drops `_isExpanded` entirely, calls service directly.
- 150ms debounce on `_onMouseExit` absorbs GTK spurious pointer-leave during resize.
- Settings open blocks debounce collapse.
- 250ms `_suppressExpandTimer` armed at debounce-fire time blocks GTK spurious re-entry after window shrinks.
- Both `onEnter` and `onHover` gate on `_suppressExpandTimer` — single consistent suppress point.

### Phase D: Testing & Animations
- **Control**: Added `enableAnimations` flag to `TimelineStrip`. In tests, set to `false` to stop the 1Hz repeating timer.
- **Fake service**: `_FakeWindowService` in tests mirrors the idempotency guard so call counts are accurate.
- **Debounce timing**: Tests use `pump(Duration(milliseconds: 200))` after mouse exit to let the 150ms debounce fire.

---

## 5. Verification
- **Tests**: 202/202 passing (as of 2026-03-02).
- **Golden tests**: `hover_card_fixed.png`, `persistent_tap_card.png`, `ticks_over_events.png`, `uat_edge_cases.png`.
- **Manual**: Run `make run`, hover should show card, settings open should keep window expanded, mouse exit should collapse after ~150ms.
- **Logs**: `~/.config/happening/debug.log` — key events: `ENTER`, `hit→`, `EXPAND`, `COLLAPSE`, `EXIT`, `debounce FIRED`, `suppress EXPIRED`.
