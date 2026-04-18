# Calendar Fetch Threading Implementation Summary — 2026-04-17T20:38

## Delivered
- Completed Morpheus calendar fetch threading architecture in `CalendarController`.
- Kept controller-level single-flight behavior with `_inFlightFetch`.
- Overlapping `refresh()` calls now return the active in-flight `Future<void>` and do not queue follow-up work.
- Replaced per-calendar `Future.wait` fan-out with sequential fetch processing.
- Preserved per-calendar failure isolation by logging failed calendar IDs and contributing `[]`.

## Tests Updated
- Renamed stale queued-refresh test to assert ignored overlapping refreshes.
- Extended `_BlockingCalendarService` to record requested calendar IDs.
- Added regression test that selected calendars are fetched sequentially:
  - `primary` requested first.
  - `secondary` is not requested until `primary` completes.

## Validation
Command:
`make -f Makefile.prj test`

Result:
FAILED overall due known window binding test failures.

Calendar threading tests passed in the full run:
- `overlapping refresh calls are ignored and return active future`
- `selected calendars are fetched sequentially after primary`

Remaining unrelated failures:
- 11 window tests fail because `WidgetsBinding` is not initialized before `WindowService.initialize()`.
