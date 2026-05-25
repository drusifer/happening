# Neo Current Task — 2026-05-25

## Status: ALL COMPLETE

## Completed this session
- [x] Lunar body tests fixed (timezone-safe layout anchoring)
- [x] Events layer z-order fix (events now draw above tick lines)
- [x] appVersion bumped to 0.5.1 in app_metadata.dart
- [x] All tests green (full suite)

## Pending (not blocking /clear)
- [ ] User to run `make fetch-cities` for full 25k-city dataset
- [ ] Oracle AST-E2 doc pass (long-standing carry-over)

## Files changed this session
- app/test/features/timeline/painters/lunar_body_test.dart — two tests anchored to solarNoon/nightRise to be timezone-independent
- app/lib/features/timeline/timeline_painter.dart — TickLayer moved before EventsLayer (z-order fix)
- app/lib/core/app_metadata.dart — appVersion '0.4.0' → '0.5.1'
- app/test/goldens/goldens/hover_card_alignment.png — regenerated after z-order change
