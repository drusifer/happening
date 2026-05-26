# Calendar Fetch Threading QA Summary — 2026-04-17T20:05

## Verdict
NOT DONE.

## Expected Behavior
Per Morpheus architecture and Oracle ask:
- `CalendarController.refresh()` returns the active in-flight `Future<void>` when a fetch is already running.
- Overlapping refresh requests are ignored as work; no queued follow-up fetch.
- Selected calendars are fetched through a sequential per-calendar queue.
- Per-calendar failures remain isolated.

## Findings
- `CalendarController._scheduleFetch()` has the single-flight guard and returns `_inFlightFetch` for overlapping refreshes.
- `CalendarController._fetchOnce()` still uses `Future.wait(idsToFetch.map(...))`, so selected calendars are fetched concurrently, not sequentially.
- `calendar_controller_test.dart` still contains the stale queued-follow-up expectation. It expects `fetchCalls == 2` after an overlapping refresh burst, but the new policy should keep it at `1`.
- No test currently proves sequential calendar fetch order (`primary` requested first, `secondary` only after primary completes).

## Verification
Command:
`make -f Makefile.prj test`

Result:
FAILED.

Relevant failures:
- Calendar threading regression: `CalendarController overlapping refresh calls coalesce to one queued follow-up fetch` expected `2`, actual `1`.
- Existing window tests also fail because `WidgetsBinding` is not initialized before `WindowService.initialize()`.

## Required Neo Follow-Up
- Replace `Future.wait` in `CalendarController._fetchOnce()` with sequential calendar queue processing.
- Rename/update the overlapping refresh test to assert ignored refreshes and one fetch call.
- Extend `_BlockingCalendarService` to record requested calendar IDs.
- Add queue-order test with selected `secondary` calendar.
