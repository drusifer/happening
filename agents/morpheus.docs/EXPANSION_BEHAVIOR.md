# Expansion Behavior Architecture

## Overview
The `ExpansionBehavior` is a pure-logic interface designed to decouple the window expansion state determination from the Flutter widget tree and OS-level window services.

## Core Principles
1. **Stateless**: The logic is a pure function of coordinates and flags.
2. **Zero Dependencies**: It does not depend on Flutter, `CalendarEvent`, or `WindowService`.
3. **Deterministic**: Given the same inputs, it always returns the same `ExpansionState`.

## Interface: `ExpansionBehavior`

### Data Types
- `ExpansionState`: Enum (`expanded`, `collapsed`).
- `EventXBounds`: Simple data class holding `startX` and `endX` in logical pixels.

### Primary Function: `determineState`
```dart
static ExpansionState determineState({
  required double mouseX,
  required double mouseY,
  required List<EventXBounds> eventBounds,
  required double stripHeight,
  required bool isSettingsOpen,
})
```

### Logic Rules:
1. **Settings Guard**: If `isSettingsOpen` is true, result is `expanded`.
2. **Interaction Zone**: If `mouseY >= stripHeight`, the mouse is in the hover card area; result is `expanded` to allow interaction.
3. **Hit Zone**: If `mouseX` falls within any `EventXBounds` (min width 3.0px), result is `expanded`.
4. **Default**: If no hits and not in the interaction zone, result is `collapsed`.

## Integration Plan

### 1. `TimelineStrip` Implementation Detail
The `TimelineStrip` should refactor its `_onMouseMove` handler to delegate state determination to the behavior.

**Step-by-Step Integration:**
1.  **Map Events to Bounds**: Convert `widget.events` to `List<EventXBounds>` using the current `TimelineLayout.xForTime`.
2.  **Calculate State**: Call `ExpansionBehavior.determineState` using current mouse coordinates, the calculated bounds, and `_isSettingsOpen`.
3.  **Synchronize UI State**:
    -   If the state is `expanded`, identify the hit event (if any) to update `_hoveredEvent` for rendering the `HoverDetailOverlay`.
    -   If the state is `collapsed`, set `_hoveredEvent = null`.
4.  **Forward to WindowService**:
    -   Call `_windowService.expand()` if state is `expanded`.
    -   Call `_windowService.collapse()` if state is `collapsed`.

**Pseudo-code for `_onMouseMove`:**
```dart
void _onMouseMove(PointerEvent details) {
  final layout = _layout;
  if (layout == null) return;

  // 1. Prepare bounds
  final bounds = widget.events.map((e) => EventXBounds(
    layout.xForTime(e.startTime, _now),
    layout.xForTime(e.endTime, _now),
  )).toList();

  // 2. Determine intended state
  final state = ExpansionBehavior.determineState(
    mouseX: details.localPosition.dx,
    mouseY: details.localPosition.dy,
    eventBounds: bounds,
    stripHeight: _collapsedHeight,
    isSettingsOpen: _isSettingsOpen,
  );

  // 3. Update local UI state (hit-testing for the card)
  final hit = layout.eventAtX(details.localPosition.dx, widget.events, _now);
  setState(() => _hoveredEvent = hit);

  // 4. Execute expansion/collapse
  if (state == ExpansionState.expanded) {
    unawaited(_windowService.expand());
  } else {
    unawaited(_windowService.collapse(height: _collapsedHeight));
  }
}
```

### 2. Testing Strategy
@Trin: Write unit tests in `test/features/timeline/expansion_behavior_test.dart` to verify:
- **Interaction Zone Persistence**: Verify `ExpansionState.expanded` when `mouseY > stripHeight`.
- **Event Hit Precision**: Verify `Expanded` on boundaries and `Collapsed` in gaps.
- **Settings Overrides**: Verify `Expanded` even when mouse is outside the strip if settings are open.
