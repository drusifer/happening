# Current Task

## TIMELINE_STRIP_COMPACT_PLATFORM_TIME_FORMAT — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Changed timeline strip hour tick labels from full localized times to compact hour-only labels.
- [x] Preserved platform 12/24-hour preference: `10am` style for 12-hour mode, `10` style for 24-hour mode.
- [x] Changed half-hour tick labels to `30`.
- [x] Kept event hover cards on full localized time formatting.
- [x] Updated canvas semantics to match compact painted strip labels.
- [x] Added regression coverage for compact 12-hour and 24-hour semantics.
- [x] Regenerated the affected hover-card/timeline golden.

### Validation
- [x] `make -f Makefile.prj format` passes.
- [x] `make -f Makefile.prj update-goldens` passes.
- [x] `make -f Makefile.prj test` passes: 243/243.

## HOVER_CARD_PLATFORM_TIME_FORMAT — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Replaced hover-card hard-coded `HH:mm` time formatting.
- [x] Used `MaterialLocalizations.formatTimeOfDay()` with `MediaQuery.alwaysUse24HourFormatOf(context)`.
- [x] Added widget tests for default localized 12-hour output and forced 24-hour output.
- [x] Regenerated the hover-card golden after intentional text rendering change.

### Validation
- [x] `make -f Makefile.prj format` passes.
- [x] `make -f Makefile.prj update-goldens` passes.
- [x] `make -f Makefile.prj test` passes: 241/241.

## CALENDAR_PERMISSIONS_DIAGNOSTICS — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Added temporary service-boundary diagnostics for calendar permissions/title investigation.
- [x] Logs calendar `accessRole` from `calendarList.get()` and the events response.
- [x] Logs per-event `summary`, `visibility`, `status`, `eventType`, `creator.email`, `organizer.email`, `start.dateTime`, and `start.date`.
- [x] Kept diagnostics before the timed-event filter so all-day and limited-access API records are visible in logs.
- [x] Avoided logging descriptions, links, locations, conference data, and raw JSON.

### Validation
- [x] `make -f Makefile.prj format` passes.
- [x] `make -f Makefile.prj test` passes: 240/240.

## CALENDAR_MULTI_CALENDAR_CORRECTION — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Read `~/.config/happening/debug.log`.
- [x] Confirmed app was fetching `primary` plus two selected calendar IDs.
- [x] Checked story/archive history after Drew corrected assumptions.
- [x] Restored all-day filtering by requiring `start.dateTime`.
- [x] Restored event-ID-only equality/hash and dedupe.
- [x] Restored existing event title parsing behavior.
- [x] Kept scoped per-calendar fetch count diagnostics.
- [x] Added/updated regression coverage that duplicate recurring event IDs across selected calendars dedupe to one.

### Validation
- [x] `make -f Makefile.prj format` passes.
- [x] `make -f Makefile.prj test` passes: 240/240.

## REMAINING_TEST_FAILURES_FIX — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Consulted Oracle via chat per Neo protocol.
- [x] Investigated remaining full-suite failures.
- [x] Fixed active window tests by initializing Flutter test binding.
- [x] Updated `waitUntilReadyToShow` and `focus` mock behavior in `window_service_test.dart`.
- [x] Added `update-goldens` Make target.
- [x] Regenerated stale hover-card alignment golden.

### Validation
- [x] `make -f Makefile.prj test` passes: 239/239.
- [x] No tests removed; none were deprecated.

## CALENDAR_FETCH_THREADING_IMPL — 2026-04-17
**Status**: COMPLETE / handed to Trin

### Completed
- [x] Consulted Oracle via chat per Neo protocol.
- [x] Loaded Morpheus architecture and Trin QA failure.
- [x] Replaced `Future.wait` calendar fan-out with sequential fetch processing.
- [x] Preserved `_inFlightFetch` single-flight ignored refresh behavior.
- [x] Updated stale overlapping refresh test to assert one fetch.
- [x] Added selected-calendar sequential queue-order test.

### Validation
- [x] `make -f Makefile.prj test` ran.
- [x] Calendar threading tests passed during full run.
- [ ] Full suite remains red from unrelated window binding initialization failures.

## CALENDAR_FETCH_COALESCING_FIX — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Consulted Oracle via chat per Neo protocol.
- [x] Interpreted stuck log: multiple overlapping forced calendar refreshes immediately before logging stopped.
- [x] Serialized `CalendarController` fetches with in-flight tracking.
- [x] Coalesced overlapping refresh bursts into one queued follow-up forced refresh.
- [x] Added blocking-service regression test for overlapping refresh calls.

### Validation
- [x] `make -f Makefile.prj test V=-vv` ran; new coalescing test passed.
- [ ] Full suite still red from unrelated `WindowService.initialize` tests missing `WidgetsBinding` setup.

## LINUX_EXPANDED_PAINT_FIX — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Consulted Oracle via chat per Neo protocol.
- [x] Reviewed Linux transparency/window docs, current TimelineStrip layer order, HoverController behavior, and latest debug log.
- [x] Kept Linux solid-background strategy intact; no compositor transparency dependency added.
- [x] Changed `HoverController.setIntent()` to report whether an intent was accepted.
- [x] Made `TimelineStrip` preserve hover card state when Linux suppresses a synthetic collapse.
- [x] Added regression tests for suppression return values and preserved card painting.

### Validation
- [x] `make -f Makefile.prj test V=-vv` ran; new regression coverage passed.
- [ ] Full suite still red from unrelated `WindowService.initialize` tests missing `WidgetsBinding` setup.

## TIMELINE_FROZEN_FIX — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Consulted Oracle via chat per Neo protocol.
- [x] Interpreted user `strace`: process/event loop alive; likely app clock subscription issue.
- [x] Made `ClockService` tick streams stable broadcast streams.
- [x] Cached `TimelineStrip` paint/countdown streams in widget state.
- [x] Added regression tests for stable stream identity and no stream replacement on parent rebuild.

### Validation
- [x] `make -f Makefile.prj test V=-vv` ran with changed tests passing.
- [ ] Full suite still red from unrelated window binding initialization failures.
- [ ] `make -f Makefile.prj analyze V=-vv` blocked by Flutter analyzer `Too many open files`.

### Notes
- `make format` formatted app files and then failed on telemetry write; user accepted formatting diffs.

## PROTOCOL_INIT_LOAD_NEO — 2026-04-17
**Status**: COMPLETE

### Completed
- [x] Read `agents/CHAT.md` recent messages.
- [x] Loaded Neo skill and state files.
- [x] Loaded `agents/PROJECT.md`; confirmed `via: enabled`.
- [x] Posted Neo protocol init status to `agents/CHAT.md`.

### Current Position
- Neo is online and standing by for the next SWE directive.
- Existing backlog remains: TEST_UPDATE awaits Trin QA verification; Linux strut timing fix awaits test confirmation.

## TEST_UPDATE — 2026-04-02
**Status**: COMPLETE ✅

### Delivered
- [x] `auth_service_test.dart` — added `cancelSignIn()` to `_FakeAuthService`, new contract test
- [x] `calendar_controller_test.dart` — updated 'service error on refresh' for new per-calendar catchError behavior; added `_PerCalendarFakeService` + isolation test
- [x] `timeline_strip_test.dart` — 4 new sign-in mode tests (hides icons, onSignIn tap, onCancelSignIn tap, null calendarController)
- [x] `hover_card_alignment.png` golden regenerated (stale from settings panel refactor)
- [x] 228/228 green, 0 regressions

### Awaiting
- [ ] Trin QA verify
