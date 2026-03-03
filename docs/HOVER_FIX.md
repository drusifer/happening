# Hover Card Fix — Implementation Record

> Status: **IMPLEMENTED & REFINED** (2026-03-02)
> Reference plan: `docs/HOVER_FIX_PLAN.md`
> Decisions: `DEC-003` (ExpansionLogic)

## What Was Fixed

Hover cards on the 35px timeline strip must expand below the window boundary. The implementation went through several failed attempts before landing on the current stable architecture.

## Final Architecture: Pure Logic + Instance Services

The window resizes on hover based on deterministic pure logic. Redundant OS-level calls are avoided via state guards.

### Phase A — OS-level Transparency

`WindowService.initialize()` configures:
- `backgroundColor: Color(0x00000000)` in `WindowOptions`
- `setAsFrameless()`, `setBackgroundColor(Color(0x00000000))`, `setResizable(false)`

The strip area gets an **explicit opaque background** via a `Positioned` layer, ensuring it remains visible while the rest of the expanded window is transparent.

### Phase B — Pure State Determination (DEC-003)

Interaction logic is decoupled from the widget tree into `ExpansionLogic` (pure Dart):
- **Input**: Mouse X/Y, Event 2D Rects, Strip Height, Settings Flag.
- **Rules**:
  1. ALWAYS collapse if mouse is above strip (`y < 0`).
  2. ALWAYS expand if settings panel is open.
  3. Expand ONLY if mouse is within an event's **Expansion Column** (X-bounds of event, Y from 0 to 160px depth).
  4. Otherwise, Collapse.

### Phase C — Instance-Based Window Management

`WindowService` was refactored from static to **instance-based**.
- Initialized in `main.dart` with calculated logical heights.
- Injected into `HappeningApp` -> `TimelineStrip`.
- Guarantees zero state-bleed between tests and predictable initialization.

## Initialization & Resize Rules

### 1. Mandatory Initial Collapse
The window must **ALWAYS initialize in the Collapsed state**. This is enforced in `TimelineStrip.initState`:
```dart
unawaited(_windowService.collapse(height: _collapsedHeight));
```
This ensures the window starts at the correct height calculated from user settings rather than hardcoded OS defaults.

### 2. Calculated Heights
All expansion thresholds are dynamic:
- `_collapsedHeight`: `fontSize + padding` (scales with Font Size setting).
- `_expandedHeight`: `_collapsedHeight + 160.0` (depth of the interaction zone).

### 3. Guarded Execution
`TimelineStrip._handleMouse` uses `_windowService.isExpanded` to block redundant OS resize requests if the state hasn't changed.

## Hover Card Positioning

Card left-anchors to the **event start**, clamped to screen bounds:
```dart
final startX = layout.xForTime(event.startTime, _now);
final cardWidth = _cardWidth(screenWidth);
return startX.clamp(4.0, math.max(4.0, screenWidth - cardWidth - 4.0));
```
Card minimum width: 260px (DEC-002).

## What Was Abandoned

| Approach | Why Dropped |
|---|---|
| Multi-window | GTK/OpenGL compositor crashes on Linux |
| Global Static Service | Race conditions and hard to unit test |
| Hardcoded Thresholds | Failed to scale with Font Size settings |
| Strip-wide Expansion | Unnecessary; buttons are in the collapsed zone |

## Test Coverage

- **Pure Logic Unit Tests** (`expansion_logic_test.dart`): 100% coverage of coordinate-based rules.
- **Widget Regression Tests** (`timeline_strip_test.dart`): Verifies guards and state transitions.
- **Golden Tests** (`timeline_strip_golden_test.dart`): Visual verification of card alignment and transparency.
