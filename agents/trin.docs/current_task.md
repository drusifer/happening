# Current Task

## Linux Wayland Simplification Phase A UAT — 2026-04-25
**Status**: PASSED / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Loaded Trin state and recent chat.
- [x] Consulted Oracle via chat for expected Phase A behavior.
- [x] Reviewed Phase A implementation diff.
- [x] Verified Linux transparent support remains hidden by default.
- [x] Verified verified Linux support path is explicit and opt-in.
- [x] Verified settings panel availability matches capability.
- [x] Verified smoke matrix covers X11/XWayland and Wayland support gates.
- [x] Ran `make test`.

### Validation
- [x] `make test` passes: 293/293.
- [x] Neo validation: `make format` passed.
- [x] Neo validation: `make build-linux` passed.
- [ ] `make analyze` remains blocked by Flutter analysis server crash.

## Linux Wayland Simplification Phase B/C UAT — 2026-04-25
**Status**: PASSED / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Consulted Oracle via chat for expected Phase B/C behavior.
- [x] Verified native reservation symbols are absent from `app/linux`.
- [x] Verified CMake no longer links direct X11 or detects layer-shell.
- [x] Verified docs no longer present Linux shell reservation as current product path.
- [x] Reviewed minimal runner startup responsibilities.

### Validation
- [x] Neo validation: `make format` passed.
- [x] Neo validation: `make test` passed 293/293.
- [x] Neo validation: `make build-linux` passed.
- [ ] `make analyze` remains blocked by Flutter analysis server crash.

## Linux Wayland Simplification Phase D Gate — 2026-04-25
**Status**: PASSED for X11/XWayland support scope / native Wayland and transparent not claimed
**Progress**: 100%

### Completed
- [x] Consulted Oracle via chat for expected Phase D behavior.
- [x] Ran `make format`.
- [x] Ran `make test`.
- [x] Ran `make build-linux`.
- [x] Ran `make analyze` and confirmed known Flutter analysis server crash.
- [x] Updated `task.md` with verification results and blockers.
- [x] Reviewed user's 2026-04-25 17:14 rerun in `build/build.out`; analyzer blocker reproduced with `Too many open files` / `Bad state: Future already completed`.
- [x] Reviewed user's report that host-side `make analyze` is fixed; Codex sandbox rerun at 2026-04-25 19:12 still fails due local inotify instance cap.
- [x] Recorded user smoke: X11/XWayland placement works; native Wayland appears centered and disconnects with GTK protocol error during interaction.
- [x] Verified `make run-linux` now forces `GDK_BACKEND=x11`.
- [x] Ran `make format`: pass, 0 changed.
- [x] Ran `make test`: pass 293/293.
- [x] Ran clean sequential `make build-linux`: pass, built Linux arm64 release bundle.

### Not Claimed
- [ ] Native Wayland strip behavior is not supported: centered placement and GTK protocol disconnect during interaction.
- [ ] Linux transparent mode remains hidden until separately validated.

## Transparent Timestrip Phase C UAT — 2026-04-24
**Status**: PASSED / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Loaded Trin state and recent chat.
- [x] Consulted Oracle via chat for the expected Phase C behavior.
- [x] Reviewed the Phase C implementation diff and architecture constraints.
- [x] Verified `WindowInteractionStrategy` owns interaction policy separately from resize strategy.
- [x] Verified Windows AppBar reservation is restricted to reserved mode.
- [x] Verified Phase C tests cover strategy factory behavior and WindowService delegation.
- [x] Confirmed latest complete `make test` run passed 275/275.

## Transparent Timestrip Phase B UAT — 2026-04-24
**Status**: PASSED / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Reviewed Phase B implementation diff.
- [x] Verified persistence/migration for `windowMode` and `idleTimelineOpacity`.
- [x] Verified clamp behavior and preserved-settings call sites.
- [x] Verified effective mode is resolved before window initialization.
- [x] Confirmed `make test` passed 264/264.

## Transparent Timestrip Phase A UAT — 2026-04-24
**Status**: PASSED / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Loaded Trin state and recent chat.
- [x] Reviewed Phase A implementation diff.
- [x] Verified pass-through probe behavior and unsupported-platform no-op behavior.
- [x] Verified Linux default transparent availability remains false.
- [x] Verified hotkey decision stayed at feasibility/target level only.
- [x] Verified `task.md` Phase A statuses align with delivered scope.
- [x] Confirmed `make test` passed 259/259.

## Calendar Fetch Threading UAT — 2026-04-17
**Status**: PASSED for scope / handed to Morpheus
**Progress**: 100%

### Completed
- [x] Reviewed Neo implementation.
- [x] Confirmed `_inFlightFetch` ignored-refresh completion signal.
- [x] Confirmed `Future.wait` calendar fan-out was removed.
- [x] Confirmed sequential queue-order test exists.
- [x] Ran `make -f Makefile.prj test`.

### Result
- [x] Calendar threading tests passed.
- [ ] Full suite still red from unrelated window binding initialization failures.

## Calendar Fetch Threading QA — 2026-04-17
**Status**: FAILED / handed back to Neo
**Progress**: 100% QA assessment complete

### Completed
- [x] Loaded Trin state and Morpheus calendar fetch architecture.
- [x] Asked Oracle for expected behavior via CHAT.
- [x] Inspected `CalendarController` implementation.
- [x] Inspected calendar controller tests.
- [x] Ran `make -f Makefile.prj test`.
- [x] Confirmed feature is not complete against architecture.

### Findings
- [x] Single-flight ignored refresh behavior exists.
- [x] Per-calendar queue is missing; implementation still uses `Future.wait`.
- [x] Overlapping refresh test is stale and failing.
- [x] Queue-order test is missing.

## Sprint 6 QA Gate — Phase 1 — 2026-03-18
**Status**: PASSED ✅ — 195/195 GREEN (1 pre-existing golden skip)

### Phase 1 Verified
- [x] T-01 `AsyncGate<T>`: 4/4 unit tests, spec compliant ✅
- [x] T-02 `PeriodicController<T>`: abstract interface, no regression ✅
- [x] Full suite: 191 prior + 4 new = 195 pass, 1 skip (S4-31 golden, pre-existing) ✅

### QA Gate: OPEN → Phase 2 ✅

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
