# Current Task

## Test Grooming — 2026-03-06
**Status**: COMPLETE ✅ — 185/185 GREEN

### Fixed
- Deleted obsolete `widget_test.dart` (Flutter counter boilerplate, `MyApp` no longer exists)
- Fixed `_FakeWindowService.expand/collapse` in `timeline_strip_test.dart` — added `isExpandedNotifier.value` sync (was missing; HoverDetailOverlay gated on this notifier)
- Fixed `_FakeWindowService.expand/collapse` in `timeline_strip_golden_test.dart` — same fix
- Updated `window_service_test.dart` `initialize` test to match actual call sequence (old test verified stale setAlwaysOnTop/setMinimumSize etc. no longer called)
- Added `Platform.isWindows` guard to `collapse` test — _doCollapse calls global `windowManager.focus()` on Linux which requires binding init
- Regenerated `goldens/hover_card_alignment.png` (80% pixel diff from UI changes)

### Fixed
- S3-09: `tapAt(10,10)` → `tap(find.byIcon(Icons.refresh))` (y=10 misses vertically-centered button in 51.5px strip)
- S3-10: `tapAt(45,10)` → `tap(find.byIcon(Icons.settings))` (same root cause)
- Lifecycle expansion: same coordinate fix as S3-10
- BUG-09/11: used delta baseline counts to exclude initState unconditional collapse()

## Sprint 5: Group E Verification — 2026-03-01
**Status**: COMPLETE ✅

### Todo
- [x] S5-E4: Verify GestureDetector tap logic (manual coordinate test) ✅
- [x] S5-E4: Verify HTML strip logic in HoverDetailOverlay (find.text match) ✅
- [x] S5-E4: Verify Task card shows calendar/list name ✅
- [x] S5-E4: Verify description truncation ✅
- [x] Update goldens for Group E ✅

### Done
- [x] Group A, B, C, D COMPLETE ✅
- [x] Logic tests GREEN (78 passing) ✅
- [x] Golden tests GREEN (5 passing) ✅
