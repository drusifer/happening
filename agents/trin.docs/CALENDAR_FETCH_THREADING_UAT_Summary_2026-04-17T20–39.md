# Calendar Fetch Threading UAT Summary — 2026-04-17T20:39

## Verdict
PASS for calendar fetch threading scope.

## Acceptance Criteria Verified
- Overlapping `refresh()` calls are ignored as work and return the active in-flight Future.
- No queued follow-up fetch is created for overlapping refreshes.
- Selected calendars are fetched sequentially after `primary`.
- Per-calendar error isolation remains covered.

## Evidence
Inspected implementation:
- `CalendarController._scheduleFetch()` returns `_inFlightFetch` when present.
- `CalendarController._fetchOnce()` now uses a `for` loop with `await _service.fetchEvents(id)` rather than `Future.wait`.

Inspected tests:
- Updated overlapping refresh test expects one fetch.
- New queue-order test asserts only `primary` is requested first, then `secondary` after `primary` completes.

Command:
`make -f Makefile.prj test`

Result:
FAILED overall due unrelated window binding failures.

Calendar threading tests passed during the full run:
- `overlapping refresh calls are ignored and return active future`
- `selected calendars are fetched sequentially after primary`

## Remaining Blocker
Full suite remains red from 11 known window tests where `WidgetsBinding` is not initialized before `WindowService.initialize()`.
