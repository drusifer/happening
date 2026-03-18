# Refactor Sprint — Consolidated Plan — 2026-03-18
# Drew-approved order + feedback incorporated

---

## Design Principles (from Drew's feedback)
- **Polymorphic scheduled events** — all timed/periodic work unified under `PeriodicController<T>`
- **Platform-specific strategies** — window service AND hover controller get platform implementations
- **AsyncGate clarified** — gate lives in `WindowService`, `HoverController` calls it cleanly
- **CountdownController** — 1Hz stream (active only), sibling to `PaintTickController` (10s) and `CalendarRefreshController` (5min)
- **CPU preserved** — countdown at 1Hz, timeline repaint at 10s, calendar at 5min — each independent

---

## Phase 1 — Foundations (no behavior change)

### Step 1: `AsyncGate<T>` — `lib/core/util/async_gate.dart`

**Purpose**: Reusable "pending-last" async guard. Replaces the hand-rolled
`_resizing + _pendingWantsExpanded` pattern in `WindowService`.

```dart
/// Ensures only one async [action] runs at a time.
/// If [request] is called while busy, the LAST value is remembered
/// and re-fired automatically when the current action completes.
class AsyncGate<T> {
  bool _running = false;
  T? _pending;

  Future<void> request(T value, Future<void> Function(T) action) async {
    if (_running) { _pending = value; return; }
    _running = true;
    try {
      await action(value);
    } finally {
      _running = false;
      final p = _pending; _pending = null;
      if (p != null) unawaited(request(p, action));
    }
  }
}
```

**UX integration example** (how it wires into window expand/collapse):
```
Mouse hover over event
  → HoverController.setIntent(ExpansionState.expanded)
    → windowService.expand()
      → _gate.request(true, _doResize)   // _gate is AsyncGate<bool> in WindowService
        → if busy: stores pending=true, returns immediately (no concurrent resize)
        → if free: runs _doResize(true) → setSize(260px) → isExpandedNotifier=true
        → on finish: checks pending → if pending=false → runs _doResize(false) → collapse

Mouse moves off event DURING resize
  → HoverController.setIntent(ExpansionState.collapsed)
    → windowService.collapse()
      → _gate.request(false, _doResize)  // _running=true, so stores pending=false
        → returns immediately
  ... (resize finishes) ...
  → _gate sees pending=false → automatically fires collapse
```

**Replaces in `WindowService`**: `bool _resizing`, `bool? _pendingWantsExpanded`, `_checkPending()`

**Also used by**: `CalendarRefreshController` (dedup rapid refresh taps), `SettingsService` (dedup rapid file saves)

---

### Step 2: `PeriodicController<T>` — `lib/core/schedule/periodic_controller.dart`

**Purpose**: Unified interface for all scheduled/timed streams. Replaces ad-hoc `Timer` + `StreamController` patterns.

```dart
abstract class PeriodicController<T> {
  Stream<T> get stream;
  void dispose();
}
```

**Three concrete implementations** (see Steps 6–8):

| Class | Cadence | Stream type | Replaces |
|-------|---------|-------------|---------|
| `CountdownController` | 1Hz (active only, 0Hz when idle) | `Stream<CountdownState>` | `tick1s` in strip + countdown logic |
| `PaintTickController` | 10s always | `Stream<DateTime>` | `tick10s` in strip |
| `CalendarRefreshController` | 5min | `Stream<void>` | `CalendarController` internal Timer |

**File structure**:
```
lib/core/schedule/
  periodic_controller.dart     ← abstract class
  countdown_controller.dart    ← 1Hz, CountdownState
  paint_tick_controller.dart   ← 10s, DateTime
  calendar_refresh_controller.dart ← 5min, void
```

**CPU contract preserved**: Each controller fires independently. Timeline painter still only repaints at 10s. Countdown still ticks at 1Hz only when an event is active.

---

## Phase 2 — Platform Strategies

### Step 3: `WindowResizeStrategy` — `lib/core/window/resize_strategy/`

*(Existing plan from WINDOW_SERVICE_REFACTOR_PLAN.md — incorporated here)*

**Interface**:
```dart
abstract class WindowResizeStrategy {
  static WindowResizeStrategy create({required WindowManager wm, required ScreenRetriever sr}) {
    if (Platform.isWindows) return WindowsResizeStrategy(wm: wm, sr: sr);
    if (Platform.isLinux)   return LinuxResizeStrategy(wm: wm, sr: sr);
    return MacOsResizeStrategy(wm: wm, sr: sr);  // wraps existing else-branch logic
  }

  Future<void> initialize(Size initialSize, double dpr);
  Future<void> expand(Size targetSize, VoidCallback onExpanded);
  Future<void> collapse(Size targetSize);
  void dispose() {}
}
```

**Implementations**:

| Strategy | `initialize` | `expand` | `collapse` |
|----------|-------------|----------|------------|
| `LinuxResizeStrategy` | no `setResizable(false)`, `setPosition(zero)` | `setSize(target)` then `onExpanded()` | `setSize(target)` |
| `WindowsResizeStrategy` | AppBar FFI, `setResizable(false)` | `onExpanded()` then `setMax→setSize→setMin` | `setMin→setMax→setSize` |
| `MacOsResizeStrategy` | `setResizable(false)`, `setPosition(zero)` | `onExpanded()` then `setMax→setSize→setMin` | `setMin→setMax→setSize` |

**A2 answer**: MacOs wraps the EXISTING working `else` branch — no new logic invented, just isolated.

**`WindowService` after Step 3**: No `Platform.isXxx` anywhere. `AsyncGate` from Step 1 replaces `_resizing/_pendingWantsExpanded`. Clean delegation to strategy.

**File structure**:
```
lib/core/window/
  window_service.dart                       ← delegates, uses AsyncGate
  resize_strategy/
    window_resize_strategy.dart            ← abstract + factory
    linux_resize_strategy.dart
    windows_resize_strategy.dart           ← Win32 FFI isolated here
    macos_resize_strategy.dart
```

---

### Step 4: `HoverController` — `lib/features/timeline/hover/`

**Purpose**: Isolates ALL async window calls from `TimelineStrip`. Platform-specific implementations handle OS quirks (focus-follows-mouse on Linux).

**Interface**:
```dart
abstract class HoverController {
  static HoverController create(WindowService ws) {
    if (Platform.isLinux) return LinuxHoverController(ws);
    return DefaultHoverController(ws);
  }

  void setIntent(ExpansionState state);
  void dispose() {}
}
```

**`DefaultHoverController`** (Windows/macOS):
```dart
class DefaultHoverController extends HoverController {
  void setIntent(ExpansionState state) {
    if (state == ExpansionState.expanded) {
      if (!_ws.isExpandedNotifier.value) unawaited(_ws.expand());
    } else {
      if (_ws.isExpandedNotifier.value) unawaited(_ws.collapse());
    }
  }
}
```

**`LinuxHoverController`** — adds focus-follows-mouse suppression (A4):
```dart
class LinuxHoverController extends HoverController {
  Timer? _suppressTimer;

  void setIntent(ExpansionState state) {
    if (state == ExpansionState.expanded) {
      // Arm suppression: ignore collapse calls for 300ms after expand starts
      // (absorbs the spurious onEnter that fires as window grows under cursor)
      _suppressTimer?.cancel();
      _suppressTimer = Timer(const Duration(milliseconds: 300), () => _suppressTimer = null);
      if (!_ws.isExpandedNotifier.value) unawaited(_ws.expand());
    } else {
      if (_suppressTimer != null) return; // suppressed — drop collapse
      if (_ws.isExpandedNotifier.value) unawaited(_ws.collapse());
    }
  }
}
```

**`TimelineStrip` after Step 4**: Zero `unawaited(_windowService...)` calls. Just `_hoverController.setIntent(state)`.

**File structure**:
```
lib/features/timeline/hover/
  hover_controller.dart          ← abstract + factory
  default_hover_controller.dart
  linux_hover_controller.dart    ← focus-follows-mouse suppression
```

---

## Phase 3 — Timeline Abstractions

### Step 5: `EventBoundsCalculator` — `lib/features/timeline/event_bounds_calculator.dart`

*(Drew: +1 KISS)*

```dart
class EventBoundsCalculator {
  static Map<String, EventBounds> compute({
    required List<CalendarEvent> events,
    required TimelineLayout layout,
    required DateTime now,
    required double stripHeight,
    required bool isOverStripZone,
  });
}
```

`_handleMouse` drops from ~90 lines to ~40. Bounds logic gets its own unit tests.

---

### Step 6: `CountdownState` VO — `lib/features/timeline/countdown_state.dart`

*(Drew: +1 encapsulation)*

```dart
class CountdownState {
  final CalendarEvent? activeEvent;
  final CalendarEvent? nextEvent;
  final DateTime? targetTime;
  final CountdownMode mode;
  final Duration remaining;

  factory CountdownState.compute(List<CalendarEvent> events, DateTime now);
}
```

Kills ~30-line duplication in both `StreamBuilder`s. Used by `CountdownController` stream.

---

### Step 7: `CountdownController` — `lib/core/schedule/countdown_controller.dart`

*(Drew: +1 testable DI seam)*

1Hz `PeriodicController<CountdownState>`. Active only when an event is imminent/active (0Hz otherwise → CPU preserved).

```dart
class CountdownController implements PeriodicController<CountdownState> {
  CountdownController({required ClockService clock, required List<CalendarEvent> events});
  @override Stream<CountdownState> get stream => ...; // tick1s filtered + CountdownState.compute
}
```

---

### Step 8: `PaintTickController` — `lib/core/schedule/paint_tick_controller.dart`

10s `PeriodicController<DateTime>`. Thin wrapper around `ClockService.tick10s`. Gives the timeline painter a testable, injectable clock source.

---

### Step 9: `CalendarRefreshController` — `lib/core/schedule/calendar_refresh_controller.dart`

5min `PeriodicController<void>`. Extracts the internal `Timer` from `CalendarController`. Uses `AsyncGate` to deduplicate rapid refresh taps.

---

## Phase 4 — Painter Decomposition

### Step 10: `TimelineLayer` + layer types

*(Existing plan from PAINTER_REFACTOR_PLAN.md — incorporated here)*

5 layers: `BackgroundLayer`, `PastOverlayLayer`, `TickLayer`, `EventsLayer`, `NowIndicatorLayer`.
Shared: `TimelinePaintUtils` (static helpers).
`TimelinePainter` constructor/shouldRepaint/semanticsBuilder unchanged.

---

## Full File Inventory

```
lib/
  core/
    util/
      async_gate.dart                          ← Step 1 ✦ NEW
    schedule/
      periodic_controller.dart                 ← Step 2 ✦ NEW (abstract)
      countdown_controller.dart                ← Step 7 ✦ NEW
      paint_tick_controller.dart               ← Step 8 ✦ NEW
      calendar_refresh_controller.dart         ← Step 9 ✦ NEW
    window/
      window_service.dart                      ← Step 3 ✎ MODIFIED
      resize_strategy/
        window_resize_strategy.dart            ← Step 3 ✦ NEW
        linux_resize_strategy.dart             ← Step 3 ✦ NEW
        windows_resize_strategy.dart           ← Step 3 ✦ NEW
        macos_resize_strategy.dart             ← Step 3 ✦ NEW
  features/
    timeline/
      hover/
        hover_controller.dart                  ← Step 4 ✦ NEW
        default_hover_controller.dart          ← Step 4 ✦ NEW
        linux_hover_controller.dart            ← Step 4 ✦ NEW
      event_bounds_calculator.dart             ← Step 5 ✦ NEW
      countdown_state.dart                     ← Step 6 ✦ NEW
      painters/
        timeline_layer.dart                    ← Step 10 ✦ NEW
        timeline_paint_utils.dart              ← Step 10 ✦ NEW
        background_layer.dart                  ← Step 10 ✦ NEW
        past_overlay_layer.dart                ← Step 10 ✦ NEW
        tick_layer.dart                        ← Step 10 ✦ NEW
        events_layer.dart                      ← Step 10 ✦ NEW
        now_indicator_layer.dart               ← Step 10 ✦ NEW
      timeline_painter.dart                    ← Step 10 ✎ MODIFIED (compositor only)
      timeline_strip.dart                      ← Steps 4,5,7,8 ✎ MODIFIED
```

---

## Step Execution Order for Neo

| Step | Task | Risk | Tests |
|------|------|------|-------|
| 1 | `AsyncGate<T>` | Low | Unit test |
| 2 | `PeriodicController<T>` abstract | Low | None needed |
| 3 | `WindowResizeStrategy` + WindowService refactor | Medium | Existing window tests |
| 4 | `HoverController` + Linux suppression | Medium | Unit test suppression |
| 5 | `EventBoundsCalculator` | Low | Unit test |
| 6 | `CountdownState` VO | Low | Unit test |
| 7 | `CountdownController` | Low | Unit test |
| 8 | `PaintTickController` | Low | Unit test |
| 9 | `CalendarRefreshController` | Low | Unit test |
| 10 | Painter layer decomposition | Low | All goldens pass |

**All tests green after each step before proceeding.**

---

## Assign To
@Neo *swe impl REFACTOR_SPRINT_PLAN.md — execute steps 1–10 sequentially, one step per chat turn.
