# Task Board — Sprint 6: Refactor Sprint
**Updated**: 2026-03-18 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus

---

## Sprint Goal
Refactor codebase into clean, testable abstractions — zero behavior change, all tests green after each step.

---

## Phase 1 — Foundations

### T-01: `AsyncGate<T>`
- **File**: `lib/core/util/async_gate.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test (gate queues pending, fires on release)
- **Status**: [x] done ✅ (4/4 tests)
- **Assigned**: @Neo

### T-02: `PeriodicController<T>` abstract
- **File**: `lib/core/schedule/periodic_controller.dart` ✦ NEW
- **Risk**: Low
- **Tests**: None needed (abstract interface)
- **Status**: [x] done ✅
- **Assigned**: @Neo

---

## Phase 2 — Platform Strategies

### T-03: `WindowResizeStrategy` + `WindowService` refactor
- **Files**:
  - `lib/core/window/resize_strategy/window_resize_strategy.dart` ✦ NEW
  - `lib/core/window/resize_strategy/linux_resize_strategy.dart` ✦ NEW
  - `lib/core/window/resize_strategy/windows_resize_strategy.dart` ✦ NEW
  - `lib/core/window/resize_strategy/macos_resize_strategy.dart` ✦ NEW
  - `lib/core/window/window_service.dart` ✎ MODIFIED
- **Risk**: Medium
- **Tests**: Existing window_service_test.dart must stay green
- **Status**: [x] done ✅ (13 strategy tests + 3 existing)
- **Assigned**: @Neo
- **Depends on**: T-01

### T-04: `HoverController` + Linux focus-follows-mouse suppression
- **Files**:
  - `lib/features/timeline/hover/hover_controller.dart` ✦ NEW
  - `lib/features/timeline/hover/default_hover_controller.dart` ✦ NEW
  - `lib/features/timeline/hover/linux_hover_controller.dart` ✦ NEW
  - `lib/features/timeline/timeline_strip.dart` ✎ MODIFIED (wired in Phase 3)
- **Risk**: Medium
- **Tests**: Unit test suppression timer (expand → immediate collapse → suppressed)
- **Status**: [x] done ✅ (7 tests)
- **Assigned**: @Neo
- **Depends on**: T-03

---

## Phase 3 — Timeline Abstractions

### T-05: `EventBoundsCalculator`
- **File**: `lib/features/timeline/event_bounds_calculator.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test bounds computation
- **Status**: [x] done ✅ (4 tests)
- **Assigned**: @Neo
- **Note**: `_handleMouse` drops from ~90 lines to ~40

### T-06: `CountdownState` VO
- **File**: `lib/features/timeline/countdown_state.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test `CountdownState.compute` factory
- **Status**: [x] done ✅ (5 tests)
- **Assigned**: @Neo
- **Note**: Kills ~30-line duplication in both StreamBuilders

### T-07: `CountdownController`
- **File**: `lib/core/schedule/countdown_controller.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test 1Hz stream, 0Hz when idle
- **Status**: [x] done ✅
- **Assigned**: @Neo
- **Depends on**: T-02, T-06

### T-08: `PaintTickController`
- **File**: `lib/core/schedule/paint_tick_controller.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test 10s tick
- **Status**: [x] done ✅
- **Assigned**: @Neo
- **Depends on**: T-02

### T-09: `CalendarRefreshController`
- **File**: `lib/core/schedule/calendar_refresh_controller.dart` ✦ NEW
- **Risk**: Low
- **Tests**: Unit test 5min refresh, AsyncGate dedup
- **Status**: [x] done ✅
- **Assigned**: @Neo
- **Depends on**: T-01, T-02

---

## Phase 4 — Painter Decomposition

### T-10: `TimelineLayer` + 5 painter layers
- **Files**:
  - `lib/features/timeline/painters/timeline_layer.dart` ✦ NEW
  - `lib/features/timeline/painters/timeline_paint_utils.dart` ✦ NEW
  - `lib/features/timeline/painters/background_layer.dart` ✦ NEW
  - `lib/features/timeline/painters/past_overlay_layer.dart` ✦ NEW
  - `lib/features/timeline/painters/tick_layer.dart` ✦ NEW
  - `lib/features/timeline/painters/events_layer.dart` ✦ NEW
  - `lib/features/timeline/painters/now_indicator_layer.dart` ✦ NEW
  - `lib/features/timeline/timeline_painter.dart` ✎ MODIFIED (compositor only)
- **Risk**: Low
- **Tests**: All goldens pass, constructor/shouldRepaint/semanticsBuilder unchanged
- **Status**: [x] done ✅
- **Assigned**: @Neo
- **Depends on**: T-05

---

## Execution Order

| Step | Task | Status |
|------|------|--------|
| 1 | T-01 AsyncGate | [x] ✅ |
| 2 | T-02 PeriodicController abstract | [x] ✅ |
| 3 | T-03 WindowResizeStrategy | [x] ✅ |
| 4 | T-04 HoverController | [x] ✅ |
| 5 | T-05 EventBoundsCalculator | [x] ✅ |
| 6 | T-06 CountdownState VO | [x] ✅ |
| 7 | T-07 CountdownController | [x] ✅ |
| 8 | T-08 PaintTickController | [x] ✅ |
| 9 | T-09 CalendarRefreshController | [x] ✅ |
| 10 | T-10 Painter layers | [x] ✅ |

**Rule**: All tests green after each step before proceeding to next.

---

## QA Gate (per step)
@Trin runs `flutter test` after each Neo step. Green = proceed. Red = Neo fixes before next step.
