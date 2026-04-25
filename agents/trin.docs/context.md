# Trin Context

## Transparent Timestrip Phase C UAT — 2026-04-24
- `WindowInteractionStrategy` is now the interaction-policy seam parallel to `WindowResizeStrategy`.
- `WindowService` delegates pass-through and focus behavior through the strategy and initializes it with the effective `WindowMode`.
- Windows AppBar reservation/reassertion now runs only in reserved mode; switching to transparent disposes the AppBar registration.
- Coverage now includes strategy factory behavior plus WindowService delegation/mode-switch tests.
- Latest complete validation run recorded in chat: `make test` passed 275/275.

## Transparent Timestrip Phase B UAT — 2026-04-24
- `AppSettings` persistence now covers `windowMode` and `idleTimelineOpacity`.
- Backward-compatible defaults remain intact for older settings files.
- Idle opacity clamp behavior is covered in settings tests.
- Settings update call sites now use `copyWith(...)`, so new fields are preserved instead of reset.
- `main.dart` resolves effective window mode before `WindowService.initialize(...)`.
- Validation: `make test` passes 264/264.

## Transparent Timestrip Phase A UAT — 2026-04-24
- Neo's Phase A scope matches the sprint board: a pass-through probe API, Linux hidden by default, and a documented hotkey implementation target.
- `WindowService.setPassThroughEnabled(bool)` uses `setIgnoreMouseEvents(enabled, forward: true)` only when transparent pass-through is supported.
- Unsupported platform behavior is a no-op; Linux default availability is false.
- `make test` from the merged main `Makefile` passed 259/259, so the Makefile merge did not regress the suite.
- Manual macOS/Windows click-through behavior is still a later smoke-test item, not a blocker for Phase A UAT.

## Calendar Fetch Threading QA — 2026-04-17
- Expected behavior from Morpheus architecture: single-flight `_inFlightFetch`, ignored overlapping refreshes return the active Future, per-calendar fetches run sequentially, no queued follow-up.
- QA verdict: NOT DONE. `CalendarController._scheduleFetch()` has the ignore/active-Future behavior, but `_fetchOnce()` still uses `Future.wait` across selected calendars.
- `app/test/features/calendar/calendar_controller_test.dart` has stale queued-follow-up assertions expecting 2 fetches; new policy should expect 1 fetch for overlapping refresh calls.
- Missing coverage: sequential queue-order test proving `primary` is requested first and selected calendars start only after the previous calendar completes.
- `make -f Makefile.prj test` failed. Calendar failure is policy/test mismatch; unrelated window tests still fail on missing `WidgetsBinding` initialization before `WindowService.initialize()`.
- Follow-up UAT after Neo implementation: PASS for calendar threading scope. `_fetchOnce()` now uses sequential `for/await`, overlapping refresh test expects one fetch, and queue-order test covers `primary` before `secondary`.
- Full suite is still red only from known window binding tests, not calendar threading.

## Test Grooming — 2026-03-06
- `HoverDetailOverlay` gated on `_windowService.isExpandedNotifier.value` (not just `_hoveredEvent != null`). Fakes MUST update this notifier.
- `_doCollapse` calls global `windowManager.focus()` on Linux — untestable without full binding. Skip on non-Windows.
- `window_service.dart` `initialize` now uses `waitUntilReadyToShow` callback pattern — old unit test expectations were stale.
- Golden: hover card alignment updated for current UI.


## Sprint 5: Fresh Start — 2026-03-01
- Group A, B, C, D COMPLETE.
- Starting Group E (Interaction: Click-to-Expand) verification. S5-E1/E2/E3/E4.
- All previous S5 attempts REVERTED. Clean slate from v0.1.0.

## QA Decisions
- Every bug fix MUST have an empirical reproduction test (unit or integration).
- S5-E4: Need to verify HTML stripping and description display.
- Tap detection (S5-E1) requires widget testing with gesture simulation.
