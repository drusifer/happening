# Calendar Multi-Calendar Update Correction Summary — 2026-04-17T21:05

## Superseded Assumptions
The first pass in this summary was wrong. Drew clarified that:
- events should be deduped;
- event titles are valid;
- the events are repeating events;
- all-day events are not supposed to be displayed.

The implementation has been corrected to restore those existing behaviors.

## Problem
Drew reported calendar updates were not right:
- Settings/log showed two selected calendars, but the UI looked like it only showed events from one.
- Event title display was missing for at least one item.

## Log Finding
`~/.config/happening/debug.log` showed the app fetching:
- `primary`
- `[CAL_ID_1]`
- `[CAL_ID_2]`

So settings selection and fetch scheduling were working. The weak spots are now treated as a live data/UI diagnosis, not a license to change event identity or parser semantics.

## Corrected Fixes
- `CalendarEvent` equality/hash are event-ID based again.
- `CalendarController._dedup()` dedupes by event ID across selected calendars.
- `GoogleCalendarService.fetchEvents()` excludes all-day entries by requiring `start.dateTime`.
- `GoogleCalendarService.fromApiEvent()` assumes timed events and keeps the existing summary title behavior.
- Kept scoped per-calendar fetch diagnostics:
  - `Fetched calendar <id>: <n> events`

## Tests
Added/updated regression coverage:
- Duplicate recurring event IDs across selected calendars are deduped to one event.
- Event equality/hash remain event-ID based.
- Removed the incorrect all-day-display and whitespace-title tests.

Validation:
- `make -f Makefile.prj format` passes.
- `make -f Makefile.prj test` passes: 240/240.

## Manual Retest
Restart the running app to load this code. On refresh, the log should include per-calendar counts while preserving the documented all-day exclusion and dedupe behavior.
