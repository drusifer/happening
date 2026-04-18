# Hover Card Platform Time Format Summary — 2026-04-17T21:40

## Problem
The timeline strip labels used AM/PM-style times, while event hover cards used a hard-coded 24-hour `HH:mm` formatter.

## Change
`HoverDetailOverlay` now formats event start/end times with Flutter's platform localization path:

- `MaterialLocalizations.of(context).formatTimeOfDay(...)`
- `MediaQuery.alwaysUse24HourFormatOf(context)`

This means event cards follow the platform/user 12-hour or 24-hour setting instead of forcing one format.

## Tests
Updated `hover_detail_overlay_test.dart`:

- default localized 12-hour output: `10:00 AM - 10:30 AM`
- forced platform 24-hour output: `10:00 - 10:30`

Regenerated `hover_card_alignment.png` because the default test render now includes AM/PM text.

## Validation
- `make -f Makefile.prj format` passes.
- `make -f Makefile.prj update-goldens` passes.
- `make -f Makefile.prj test` passes: 241/241.
