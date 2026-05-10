# ExpansionController TDD Implementation — 2026-05-06
**Status**: PHASE 3 COMPLETE
**Progress**: 100% (All 3 phases done, 292/292 green)

## Completed this session
- Phase 1 (prior session):
  - `app/lib/core/window/physical_window_state.dart` — immutable value type
  - `app/lib/core/window/resize_executor.dart` — abstract interface
  - `app/lib/core/window/expansion_controller.dart` — queue + didChangeMetrics loop
  - `app/test/core/window/expansion_controller_test.dart` — 9 unit tests

- Phase 2 (prior session):
  - `app/lib/core/window/window_service.dart` — added `getSize()` public method
  - `app/lib/core/window/window_service_resize_executor.dart` — new concrete ResizeExecutor
  - `app/lib/features/timeline/timeline_strip.dart` — wired ExpansionController
  - `app/test/features/timeline/timeline_strip_test.dart` — updated fakes
  - `app/test/goldens/timeline_strip_golden_test.dart` — updated fakes

- Phase 3 (this session):
  - `app/lib/core/window/window_service.dart` — removed AsyncGate, _wantsExpanded,
    isExpandedNotifier, expand()/collapse(), resetToFreshCollapsedState(),
    didChangeAppLifecycleState, _resumedCollapseIfNeeded.
    Added: performResize(ExpansionState), _isExpanded bool.
  - `app/lib/core/window/window_service_resize_executor.dart` — now calls performResize()
  - `app/lib/features/timeline/timeline_strip.dart` — removed resetToFreshCollapsedState()
    call and old debug log fields
  - `app/lib/simple_main.dart` — rewrote to use ExpansionController
  - Deleted: `hover/linux_hover_controller.dart`, `hover/hover_controller.dart`,
    `hover/default_hover_controller.dart`, `test/.../hover_controller_test.dart`
  - `app/test/core/window/window_service_test.dart` — removed expand/collapse/lifecycle tests
  - `app/test/features/timeline/timeline_strip_test.dart` — rewrote _FakeWindowService
    to use performResize()
  - `app/test/goldens/timeline_strip_golden_test.dart` — same fake update
  - `app/test/app_test.dart` — same fake update
  - `app/test/core/window/window_linux_e2e_test.dart` — updated to use performResize()
  - 292/292 green, format clean

## What exists now
- `ExpansionController` is the single authority for expand/collapse
- `WindowService` exposes `performResize()` only — no public expand/collapse
- `WindowServiceResizeExecutor` delegates to `performResize()` — no AsyncGate path
- All hover controller files deleted
- `isExpandedNotifier` is gone; visual state comes from stream

## Next item
- DONE. Manual Wayland smoke test recommended.
- Optional: remove `PhysicalWindowState` emission from `ExpansionController.initState`
  (currently stream emits nothing until first resize — initialData: collapsed handles this)
