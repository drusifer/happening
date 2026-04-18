# Calendar Permissions Diagnostics Summary — 2026-04-17T21:20

## Problem
Drew suspects the missing title/calendar issue may be caused by Google Calendar sharing permissions. The events are owned by `[USER_EMAIL_1]` and shared with `[USER_EMAIL_2]`.

## Change
Added temporary diagnostics inside `GoogleCalendarService.fetchEvents()` after the Google API response is received and before the app filters all-day events.

Calendar-level log fields:
- `calendar`
- `metaSummary`
- `responseSummary`
- `accessRole`
- `responseAccessRole`
- `items`

Event-level log fields:
- `calendar`
- `id`
- `summary`
- `visibility`
- `status`
- `eventType`
- `creator`
- `organizer`
- `startDateTime`
- `startDate`

## Privacy Scope
The diagnostic does not log descriptions, locations, event links, video links, conference data, or full raw JSON.

## Validation
- `make -f Makefile.prj format` passes.
- `make -f Makefile.prj test` passes: 240/240.

## Next Manual Step
Restart the app and refresh calendars. Then inspect:

```bash
tail -200 ~/.config/happening/debug.log | rg 'CalendarDiag|Fetching calendars|Fetch complete'
```

If `accessRole` is `freeBusyReader`, or events show `<empty>` summary with private/confidential visibility, the likely cause is Google sharing permissions rather than app title parsing.
