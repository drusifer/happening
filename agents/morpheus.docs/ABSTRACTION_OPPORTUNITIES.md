# Abstraction Opportunities — 2026-03-18

## Priority Order

### 1. `AsyncGate<T>` — Generic pending-last async guard
**Location**: `lib/core/util/async_gate.dart`
**Replaces**: hand-rolled `_resizing + _pendingWantsExpanded` in WindowService, ad-hoc unawaited patterns
**Pattern**:
```dart
class AsyncGate<T> {
  bool _running = false;
  T? _pending;
  Future<void> request(T value, Future<void> Function(T) action) async {
    if (_running) { _pending = value; return; }
    _running = true;
    try { await action(value); } finally {
      _running = false;
      final p = _pending; _pending = null;
      if (p != null) unawaited(request(p, action));
    }
  }
}
```
**Applies to**:
- `WindowService._doExpand/_doCollapse` → `_gate.request(true/false, _resize)`
- `CalendarController` refresh (5-min polling deduplication)
- `SettingsService` file writes (debounce rapid saves)

# DREWs FEEDBACK: 

This looks like a good start but it's not clear how request() integrates with the UX events please elaborate

---

### 2. `CountdownState` value object
**Location**: `lib/features/timeline/countdown_state.dart`
**Replaces**: ~30-line computation duplicated in both `StreamBuilder`s in `timeline_strip.dart`
```dart
class CountdownState {
  final CalendarEvent? activeEvent;
  final DateTime? targetTime;
  final CountdownMode mode;
  final Duration remaining;
  factory CountdownState.compute(List<CalendarEvent> events, DateTime now, TimelineLayout layout);
}
```
**Benefit**: Single source of truth for active/next/mode/color logic.

# DREWs FEEDBACK: 
+1 i like this encapsulation

---

### 3. `HoverController` — async window intent isolator
**Location**: `lib/features/timeline/hover_controller.dart`
**Replaces**: `unawaited(_windowService.expand/collapse())` calls scattered in `TimelineStrip`
```dart
class HoverController {
  final WindowService _windowService;
  void setIntent(ExpansionState state) {
    if (state == ExpansionState.expanded) {
      if (!_windowService.isExpandedNotifier.value) unawaited(_windowService.expand());
    } else {
      if (_windowService.isExpandedNotifier.value) unawaited(_windowService.collapse());
    }
  }
}
```
**Benefit**: `TimelineStrip` has zero `unawaited()` window calls. All async window logic in one place.

# DREWs FEEDBACK: 

see #1 how does this integrate

---

### 4. `EventBoundsCalculator` — extract from `_handleMouse`
**Location**: alongside `ExpansionLogic` in `lib/features/timeline/`
**Replaces**: the `boundsMap` build loop (~20 lines) inside `_handleMouse`
```dart
class EventBoundsCalculator {
  static Map<String, EventBounds> compute(
    List<CalendarEvent> events, TimelineLayout layout, DateTime now,
    double stripHeight, bool isOverStripZone,
  );
}
```
**Benefit**: `_handleMouse` shrinks from ~90 lines to ~40. Bounds logic is testable in isolation.

# DREWs FEEDBACK: 
+1 KISS

---

### 5. `CountdownController` — merge tick streams
**Location**: `lib/features/timeline/countdown_controller.dart`
**Replaces**: nested `StreamBuilder(tick10s, StreamBuilder(tick1s, ...))` in `build()`
```dart
class CountdownController {
  Stream<CountdownState> stream(List<CalendarEvent> events);
  // Merges tick1s + tick10s into a single CountdownState stream
}
```
**Benefit**: Flat single `StreamBuilder<CountdownState>` in build. Simpler widget tree, testable.

# DREW FEEDBACK:
+1 Testable seam good for dependancy injection

---

## Implementation Order (recommended)
1. `AsyncGate<T>` — foundational, cleans up WindowService immediately
2. `CountdownState` — isolated, low-risk, high duplication reduction
3. `EventBoundsCalculator` — pairs with existing `ExpansionLogic` refactor
4. `HoverController` — depends on AsyncGate being in place
5. `CountdownController` — biggest widget restructure, do last

## Assign To
@Neo *swe impl ABSTRACTION_OPPORTUNITIES.md (after painter + window service refactors)


# DREW FEEDBACK on outstanding questions:
Q1 Refactor order — the three plans interact:
  - AsyncGate<T> should be extracted before the WindowService strategy refactor (so WindowsResizeStrategy uses it natively rather
  than re-rolling the pattern again)
  - Suggested sequence: AsyncGate → WindowService strategies → Painter layers → remaining abstractions
  - Is that ordering acceptable, or do you want painter first (lowest risk)?

A1: order looks good to me


Q2 MacOsResizeStrategy — currently a placeholder ("similar to Linux"). It's untested territory. Do you want a real macOS design
  now, or stub it and fill in after a macOS smoke test?


A2: Hmm, I'm not sure.  Is this a vestage of an incomplete change? I want extensable class for platform specific WindowService behaviors.  We have existing code that works for mac linux and windows so we can use that but I want to see the plan for that arch

Q3 CountdownController CPU risk — merging tick1s + tick10s into one stream means the full timeline layout runs at 1Hz instead of
  0.1Hz. That was deliberately avoided (LESSONS.md: "Tiered UI Update Frequency for CPU Optimization"). Two options:
  - Keep two streams, just extract the CountdownState VO (items 2 only, skip item 5)
  - Redesign CountdownController to emit two event types at different rates — more complex

A3: Redesign - new Types with polymorhic event handeling, CountdowController is one (repeats 1/s when active), and a second Class for painting events (10sec),  But also one for CalenderRefresh timer.  In otherwords use this to unify all events that happen on a schedule.

Q4. HoverController scope — the focus-follows-mouse issue (spurious onEnter as window expands under cursor) is still open. Should
  HoverController include suppression logic for that, or is that a separate story?

A4: Yes inscope but see earlier thread aout plantform specic polymorphic implementations to make this logic more abstract.


