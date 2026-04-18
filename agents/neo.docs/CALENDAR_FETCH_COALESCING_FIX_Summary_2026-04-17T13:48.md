# CALENDAR_FETCH_COALESCING_FIX Summary — 2026-04-17T13:48

## Problem
- User reported another stuck running app.
- `strace` showed a futex wait.
- Debug log stopped after several overlapping `CalendarController._fetch(forceRefresh: true)` starts in quick succession, followed by event emissions and a hover expand.

## Fix
- `CalendarController` now tracks `_inFlightFetch`.
- If a fetch is in flight, additional refresh requests do not start parallel fetches. They set `_queuedForceRefresh`.
- When the current fetch finishes, the controller drains at most one queued forced refresh.

## Tests
- Added `_BlockingCalendarService` regression coverage.
- Three overlapping refresh calls now produce exactly two fetches: the active one plus one queued follow-up.

## Validation
- `make -f Makefile.prj test V=-vv` ran and the new regression test passed.
- Full suite still fails on unrelated WindowService tests that access `WidgetsBinding.instance` before initializing the Flutter test binding.
