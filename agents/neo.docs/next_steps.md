# Neo Next Steps — 2026-06-11

## F-31 Implementation COMPLETE (Phases A + B + Drift Fix + Race Condition Fix + Padding/Spacing Fix + 32px Icon Scale)

### Ready for Trin UAT
- F31-C1: Multi-platform UAT matrix
  - Linux X11/Wayland: hide → strut released; show → strut re-acquired
  - Windows: hide → AppBar released; show → AppBar re-acquired  
  - macOS: no strut side effects
  - All: countdown live while hidden; cycle repeatable ≥ 5 times; starts visible on launch
  - Positioning: verify that mini-widget collapses exactly to the top-left of the screen (work area) and does not drift to the right/down.
  - Expanded Hide: verify that clicking "hide" while the strip is hovered/expanded or when settings are open immediately collapses and hides correctly without leaving a shifted/large window or drift.
  - Padding & Spacing: verify that show/hide buttons both have 8px left margin/padding, and that all buttons are spaced exactly 8px apart in the full strip view, with no double spacing when the fallback indicator is hidden.
  - Icon Scale: verify that all buttons/icons render at 32px size (using layout/bounds of 24px).

### Ready for Smith UX pass
- F31-C2: Verify touch targets, animation, anchor position, STB restore, and button alignment/spacing.

### Files changed in latest commits:
- `app/lib/core/window/expansion_controller.dart` (added sendAndAwait)
- `app/lib/features/timeline/timeline_strip.dart` (left padding for hide button, equal spacing for toolbar buttons)
- `app/test/core/window/expansion_controller_test.dart` (added unit tests for sendAndAwait)
- `app/lib/core/window/window_service.dart` (reposition during resizeToMini/resizeToFull)
- `app/test/core/window/window_service_test.dart` (assert setPosition in unit tests)
- `app/test/goldens/timeline_strip_golden_test.dart` (regenerated golden images for new layout)
