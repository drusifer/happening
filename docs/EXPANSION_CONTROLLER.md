# ExpansionController Architecture

## Problem with the current design

The expand/collapse logic is scattered across at least six call sites, each doing its own conditional reasoning:

- `LinuxHoverController` — 300ms suppression timer to absorb GTK synthetic exits
- `TimelineStrip.didChangeAppLifecycleState` — collapses on focus loss
- `WindowService.didChangeAppLifecycleState` — collapses on resume via `_resumedCollapseIfNeeded`
- `_clearInteractiveState` — collapses on settings close
- `didUpdateWidget` — re-evaluates hover when loading clears
- `AsyncGate` — serialises concurrent expand/collapse calls from all of the above

Every caller must know the current state before acting. The `_wantsExpanded` flag, `isExpandedNotifier`, the 300ms timer, `getSize()` checks, and Linux-specific branching all exist to compensate for the fact that many concurrent actors are each making partial decisions about what the window should do. The result is emergent behaviour that is sensitive to event timing.

### Symptoms of the current design

- **expand-black**: `onExpanded()` fires before GTK confirms the resize, so the card renders into a 60px Flutter canvas while the GTK window is physically 340px.
- **Fetching stuck**: `_handleMouse` only fires on pointer events. When `isLoading` clears in `didUpdateWidget`, the strip doesn't re-evaluate the already-hovering cursor.
- **Invisible card**: GTK's max constraint must be pinned to collapsed height before the expand trick works. If the startup collapse or a sleep/resume cycle is skipped, max stays at ∞ and GTK silently ignores the resize request.

All three symptoms are timing races that exist because the UX layer and the window layer share mutable state and call each other directly.

---

## Design principles

1. **One class owns all expand/collapse decisions.** No logic in callers.
2. **Main-isolate async queue.** No Dart Isolate, no SendPort/ReceivePort.
3. **Always execute the full resize sequence.** No "same-state skip" — the platform strategy handles idempotency; always running the sequence guarantees GTK constraints are reasserted on resume.
4. **Emit state only after GTK confirms.** `didChangeMetrics` + `wm.getSize()` correlation; no callbacks before confirmation.

---

## Proposed design

```
┌──────────────────────────────────────────────────────┐
│  UX Layer  (main isolate, UI thread)                 │
│                                                      │
│  mouse events ──┐                                    │
│  didUpdateWidget─┼─► controller.send(ExpansionState) │
│  lifecycle ─────┘                                    │
│                                                      │
│  No state checks before calling. No guards.          │
└──────────────────────────────────────────────────────┘
                           │
              controller.send() — fire and forget
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│  ExpansionController  (main isolate, async loop)     │
│                                                      │
│  Queue: one pending slot, last-write-wins            │
│                                                      │
│  Processing loop (one resize at a time):             │
│    dequeue intent                                    │
│    call ResizeExecutor.resize(intent)                │
│    await GTK confirmation via didChangeMetrics       │
│    emit PhysicalWindowState {height, isExpanded}     │
│                                                      │
│  Also owns WidgetsBindingObserver for confirmation.  │
└──────────────────────────────────────────────────────┘
                           │
                  PhysicalWindowState stream
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│  Painter / Builder  (main isolate, UI thread)        │
│                                                      │
│  StreamBuilder<PhysicalWindowState>                  │
│    if state.isExpanded: render strip + card          │
│    else:               render strip only             │
│                                                      │
│  No decisions. No conditions based on intent.        │
│  Only reacts to confirmed physical state.            │
└──────────────────────────────────────────────────────┘
```

---

## Queue semantics

```
intent arrives  │ loop idle      │ start processing immediately
intent arrives  │ loop busy      │ overwrite pending slot (last-write-wins)
loop iteration  │ pending exists │ dequeue, start next processing
loop iteration  │ no pending     │ go idle
```

The queue has exactly one pending slot. The controller always converges to the last stated intent.

This eliminates the 300ms suppression timer. GTK's synthetic pointer-exit fires a `collapsed` intent. The real pointer position (still inside the strip) fires an `expanded` intent 1–2ms later. The second overwrites the first before processing starts. No timer, no platform-specific suppression logic.

**No skip based on confirmed state.** Every dequeued intent triggers a full resize sequence. On macOS/Windows, `setSize` to the current size is a no-op at the OS level. On Linux, the full GTK sequence (`setSize → setMin → setMax`) reasserts the min/max constraints — which is exactly what `_resumedCollapseIfNeeded` currently does manually. By always running the sequence, constraint reassertion after sleep/resume is automatic.

---

## GTK confirmation

`ExpansionController` implements `WidgetsBindingObserver`. After issuing a resize, it holds a `Completer<void>` and the target height. `didChangeMetrics` resolves the completer only when `wm.getSize()` confirms the physical height matches the target (within 2px tolerance). Spurious `didChangeMetrics` firings — keyboard, DPI change, display reconnect — are absorbed because their sizes won't match the pending target.

```
resize issued     → _pending = Completer(), _targetHeight = 340
didChangeMetrics  → getSize() → 60px → mismatch, ignore
didChangeMetrics  → getSize() → 340px → match, complete()
PhysicalWindowState(height=340) emitted
StreamBuilder rebuilds → card enters tree
```

The card cannot render into a 60px canvas because `PhysicalWindowState` is emitted only after this confirmation. The GTK window and Flutter's canvas are always in sync before any card widget enters the tree.

On macOS and Windows where resize is synchronous enough that `didChangeMetrics` fires immediately and reliably, the same path works without special-casing.

---

## Implementation sketch

```dart
class ExpansionController with WidgetsBindingObserver {
  ExpansionController({required ResizeExecutor executor}) : _executor = executor {
    WidgetsBinding.instance.addObserver(this);
    _stateController.add(PhysicalWindowState.collapsed);
  }

  final ResizeExecutor _executor;
  final _stateController = StreamController<PhysicalWindowState>.broadcast();
  Stream<PhysicalWindowState> get stateStream => _stateController.stream;

  ExpansionState? _pending;
  bool _processing = false;
  Completer<void>? _resizeConfirmation;
  double _targetHeight = 0;

  void send(ExpansionState intent) {
    _pending = intent;
    if (!_processing) _runLoop();
  }

  Future<void> _runLoop() async {
    _processing = true;
    while (_pending != null) {
      final intent = _pending!;
      _pending = null;
      await _execute(intent);
    }
    _processing = false;
  }

  Future<void> _execute(ExpansionState intent) async {
    _targetHeight = intent == ExpansionState.expanded
        ? _executor.expandedHeight
        : _executor.collapsedHeight;
    _resizeConfirmation = Completer<void>();
    await _executor.resize(intent);
    await _resizeConfirmation!.future;
    _resizeConfirmation = null;
    _stateController.add(PhysicalWindowState(
      height: _targetHeight,
      isExpanded: intent == ExpansionState.expanded,
    ));
  }

  @override
  void didChangeMetrics() {
    final pending = _resizeConfirmation;
    if (pending == null || pending.isCompleted) return;
    _executor.getSize().then((size) {
      if (!pending.isCompleted && (size.height - _targetHeight).abs() < 2.0) {
        pending.complete();
      }
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
  }
}
```

`ResizeExecutor` is a thin wrapper: it holds `expandedHeight`/`collapsedHeight`, delegates to `WindowResizeStrategy`, and exposes `getSize()`. It does not own `WidgetsBindingObserver`. No logic moves into it.

---

## UX layer contract

Every source of expand/collapse intent becomes a single call with no guards:

```dart
controller.send(ExpansionLogic.determineState(...));
// or
controller.send(ExpansionState.collapsed);
```

| Source | New behaviour |
|---|---|
| `_handleMouse` | `controller.send(ExpansionLogic.determineState(...))` |
| `didUpdateWidget` (loading cleared) | `controller.send(ExpansionLogic.determineState(...))` |
| `didChangeAppLifecycleState` (focus lost) | `controller.send(ExpansionState.collapsed)` |
| `didChangeAppLifecycleState` (resumed) | `controller.send(ExpansionState.collapsed)` — full GTK sequence runs, reasserting constraints |
| `_clearInteractiveState` | `controller.send(ExpansionState.collapsed)` |
| `_toggleSettings` open | `controller.send(ExpansionState.expanded)` |
| `_toggleSettings` close | `controller.send(ExpansionState.collapsed)` |

No `if (isExpanded)` guards. The controller handles deduplication via the queue.

---

## Painter contract

`PhysicalWindowState` answers one question: is the OS window physically expanded? It does not carry the reason for expansion.

What to render in the expanded area is UX-layer state. `_isSettingsOpen` and `_hoveredEvent` remain local fields in `_TimelineStripState`. The builder gates on both:

```dart
StreamBuilder<PhysicalWindowState>(
  stream: controller.stateStream,
  initialData: PhysicalWindowState.collapsed,
  builder: (context, snapshot) {
    final isExpanded = snapshot.data!.isExpanded;

    return Stack(children: [
      // ... strip painter always present ...

      // hover card: window expanded AND not settings AND hovering an event
      if (isExpanded && !_isSettingsOpen && _hoveredEvent != null)
        HoverDetailOverlay(event: _hoveredEvent!, ...),

      // settings panel: _isSettingsOpen alone — window is always expanded when settings are open
      if (_isSettingsOpen)
        SettingsPanel(...),
    ]);
  },
)
```

`isExpanded` replaces `_windowService.isExpandedNotifier.value` as the window-physical gate. `_isSettingsOpen` and `_hoveredEvent` continue to route content within the expanded area exactly as they do today.

`initialData` is `PhysicalWindowState.collapsed` so there is no null snapshot gap on startup.

---

## What is eliminated

| Current mechanism | Replaced by |
|---|---|
| `LinuxHoverController` 300ms timer | queue last-write-wins (second intent overwrites first) |
| `AsyncGate` | controller's serial `_runLoop` |
| `_wantsExpanded` flag | controller's internal `_pending` slot |
| `isExpandedNotifier` driving card visibility | `PhysicalWindowState.isExpanded` from stream |
| `_resumedCollapseIfNeeded` + `getSize()` check | always running the full resize sequence (GTK constraints reasserted automatically) |
| `onExpanded()` before `didChangeMetrics` | controller emits only after `didChangeMetrics` size confirmation |
| Multiple callers checking state before acting | all callers are stateless senders — no guards at call sites |
| Linux-specific branching in `WindowService` | remains encapsulated in `LinuxResizeStrategy` |

---

## Files affected

| File | Change |
|---|---|
| `expansion_controller.dart` | New. Owns the queue, processing loop, `didChangeMetrics` confirmation, and `PhysicalWindowState` stream. |
| `physical_window_state.dart` | New. Immutable `{double height, bool isExpanded}` with a `collapsed` constant. |
| `resize_executor.dart` | New thin wrapper: holds `expandedHeight`/`collapsedHeight`, delegates to `WindowResizeStrategy`, exposes `getSize()`. No logic. |
| `window_service.dart` | Remove `AsyncGate`, `_wantsExpanded`, `isExpandedNotifier`, `_resumedCollapseIfNeeded`, `didChangeAppLifecycleState` collapse logic, `expand()`/`collapse()` public API. `WindowService` retains initialization, AppBar management, display-change handling, and `ResizeExecutor` construction. |
| `linux_hover_controller.dart` | Delete. |
| `hover_controller.dart` | Delete or reduce to a `controller.send(state)` passthrough with no internal state. |
| `timeline_strip.dart` | All expand/collapse call sites become `controller.send(...)`. Remove `_lastPointerEvent` replay hack in `didUpdateWidget` — re-evaluation on loading clear is just `controller.send(ExpansionLogic.determineState(...))`. |
| `linux_resize_strategy.dart` | Unchanged — remains the GTK-specific resize sequence. |

### What stays out of scope

`WindowService.reassertAppBar()` is a Windows-only, user-triggered AppBar registration cycle. It is not part of the expand/collapse state machine. It remains a direct method on `WindowService`, called by `TimelineStrip` on the refresh button tap. It issues a collapse via the controller before its registration cycle.

---

## Testing strategy

### 1. `ExpansionController` — pure unit tests

`ResizeExecutor` is an interface. Inject a fake that records calls, holds resizes in-flight via a `Completer`, and returns a configurable size from `getSize()`. Call `controller.didChangeMetrics()` directly — it is a public method on `WidgetsBindingObserver`.

```dart
class FakeResizeExecutor implements ResizeExecutor {
  final calls = <ExpansionState>[];
  Completer<void> resizeGate = Completer()..complete();
  Size currentSize = const Size(1920, 60);

  @override Future<void> resize(ExpansionState s) async { calls.add(s); await resizeGate.future; }
  @override Future<Size> getSize() async => currentSize;
  @override double get collapsedHeight => 60;
  @override double get expandedHeight => 340;
}
```

| Test | What it verifies |
|---|---|
| `send(expanded)` → confirm → stream emits `isExpanded=true` | happy path expand |
| `send(collapsed)` → confirm → stream emits `isExpanded=false` | happy path collapse |
| `send(expanded)` while busy, `send(collapsed)` arrives → converges to `collapsed` | last-write-wins |
| 10× `send(expanded)` while busy → only 2 resize calls total | queue deduplication |
| `didChangeMetrics` with wrong height (50px when expecting 340) → no emission | spurious GTK fire ignored |
| `didChangeMetrics` with matching height → emits | confirmation correlation correct |
| `send(collapsed)` when already confirmed-collapsed → resize still executes | no-skip guarantee (GTK constraint reassertion on resume) |

The last case is the regression test for the invisible-card bug that `_resumedCollapseIfNeeded` was patching around.

### 2. `TimelineStrip` — widget tests

Inject a `StreamController<PhysicalWindowState>` in place of a real controller and push states directly — no real resize needed.

| Test | What it verifies |
|---|---|
| `PhysicalWindowState.collapsed` → no `HoverDetailOverlay`, no `SettingsPanel` | strip-only state |
| `PhysicalWindowState.expanded` + `_hoveredEvent` set + settings closed → `HoverDetailOverlay` visible | hover path |
| `PhysicalWindowState.expanded` + settings open → `SettingsPanel` visible, no `HoverDetailOverlay` | settings path |
| Settings open while hovering → only `SettingsPanel` visible | settings takes priority |
| Mouse exit → `controller.send(collapsed)` called, no state guard | stateless sender |
| `isLoading` clears while hovering → `controller.send(...)` called | loading-clear path (no `_lastPointerEvent` replay) |

### 3. `WindowService` — keep existing tests

`WindowService` retains initialization, AppBar, and display-change responsibilities. Existing tests cover those unchanged.

### What not to test here

- GTK `setMin`/`setMax` constraint order — covered by `LinuxResizeStrategy` tests.
- Whether `didChangeMetrics` fires from GTK — platform behaviour, covered by manual UAT.
- AppBar registration sequence — covered by `WindowService` tests.

---

## Post-implementation findings (2026-05-06)

### `didChangeMetrics` does not fire on this Linux/GTK config

Every confirmation in the real session uses the 350ms timeout fallback — `didChangeMetrics` is never called by GTK after a resize. This creates two visible bugs:

**Black expansion:** When `resize()` returns the GTK window IS at 340px, but `isExpanded=false` in the stream until the timeout fires 350ms later. Flutter renders `maxH=340` with a transparent (compositor-black) backdrop and no card for that window.

**Reversed-state corruption:** When collapse fires while an expand confirmation is pending, the GTK window shrinks to 60px while the stream still shows `isExpanded=true`. The card renders into a 60px window, appearing black. Two 350ms gaps per hover cycle make this frequent.

### Fix

`_kConfirmTimeout` should be `Duration.zero`. After `resize()` returns all GTK platform-channel calls have been awaited and the window IS at the target size. A zero-duration timer fires on the next event-loop tick; `getSize()` returns the correct height at that point, completing the confirmation in under a frame instead of 350ms.

On platforms where `didChangeMetrics` fires normally (macOS, Windows), it completes the `Completer` before the zero-duration timer, which cancels cleanly.

### Strip-zone hit-testing note

When the mouse is in the strip zone (`mouseY < collapsedHeight`), `_handleMouse` computes raw `xForTime` positions with no clamping. Events outside the current time window have x values far off-screen (e.g. `l:-4476`, `r:5919`). This is correct — those events are not in the visible window and should not trigger expansion. Expansion only fires when the mouse is over an event that falls within the visible time window.

