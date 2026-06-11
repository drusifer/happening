# Neo Next Steps — 2026-06-11

## F-31 Implementation COMPLETE (Phases A + B)

### Ready for Trin UAT
- F31-C1: Multi-platform UAT matrix
  - Linux X11/Wayland: hide → strut released; show → strut re-acquired
  - Windows: hide → AppBar released; show → AppBar re-acquired  
  - macOS: no strut side effects
  - All: countdown live while hidden; cycle repeatable ≥ 5 times; starts visible on launch

### Ready for Smith UX pass
- F31-C2: Verify touch targets, animation, anchor position, STB restore

### Files changed in F-31 A+B:
- `app/lib/core/window/window_service.dart` (public hooks + API)
- `app/lib/core/window/linux_window_service.dart` (onHideStrip/onShowStrip)
- `app/lib/core/window/windows_window_service.dart` (onHideStrip/onShowStrip)
- `app/lib/features/timeline/timeline_strip.dart` (state machine + UI)
- `app/test/core/window/window_service_test.dart` (F-31 A tests)
- `app/test/features/timeline/timeline_strip_hide_test.dart` (NEW: F-31 B tests)
- `app/test/goldens/goldens/hover_card_alignment.png` (updated golden)
