# TIMELINE_STRIP_COMPACT_PLATFORM_TIME_FORMAT Summary — 2026-04-17T21:52

## Request
Drew wanted the timeline strip to follow the platform 12/24-hour preference while staying compact:
- hour markers show only the hour (`11pm` or `23`);
- half-hour markers show `30`.

## Changes
- Updated `TickLayer` hour labels to compact 12/24-hour formatting based on `MediaQuery.alwaysUse24HourFormat`.
- Updated half-hour painted labels to `30`.
- Updated `TimelinePainter` semantics to use the same compact hour and half-hour labels as the painted strip.
- Added regression coverage for compact 12-hour and 24-hour semantic labels.
- Regenerated the affected timeline/hover golden.

## Validation
- `make -f Makefile.prj format` passed.
- `make -f Makefile.prj update-goldens` passed.
- `make -f Makefile.prj test` passed: 243/243.
