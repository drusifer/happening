# Neo Current Task — 2026-05-22

**Status**: Lunar transition fix — COMPLETE (371/371 green)

## What was completed this session

### Sky Body Refactor (per agents/morpheus.docs/SKY_BODY_REFACTOR_PLAN.md)

**Goal**: Replace SkyArc/Sunlight/Moonlight + separate marker layers with unified SkyBody hierarchy.

#### New files created
- `app/lib/features/timeline/painters/sky_body.dart` — Abstract base with `gradientStops`, `nightnessAt`, `paintGlyphs`, `drawIfVisible` helper
- `app/lib/features/timeline/painters/solar_body.dart` — SolarBody(SolarDayTimes): dayBlue/nightNavy/dawnDusk gradient + SunRise/Sun/SunSet glyphs
- `app/lib/features/timeline/painters/lunar_body.dart` — LunarBody(LunarDayTimes, SolarBody): transparent down/twilight, instant rise/set, daytime suppression, moon glyphs

#### Rewritten
- `app/lib/features/timeline/painters/astronomical_background_layer.dart` — Creates SolarBody×2 + LunarBody per date; merges gradient stops; draws stars; calls paintGlyphs on each body

#### Modified
- `app/lib/features/timeline/timeline_painter.dart` — Removed SolarMarkerLayer + LunarMarkerLayer imports and layer instances (glyphs now owned by bodies in ABL)

#### Deleted (obsolete)
- `app/lib/features/timeline/painters/sky_lights.dart`
- `app/lib/features/timeline/painters/solar_marker_layer.dart`
- `app/lib/features/timeline/painters/lunar_marker_layer.dart`
- `app/lib/features/timeline/painters/astro_marker_layer.dart`

#### Test files
- NEW: `test/features/timeline/painters/solar_body_test.dart` (7 tests)
- NEW: `test/features/timeline/painters/lunar_body_test.dart` (8 tests)
- UPDATED: `test/features/timeline/painters/astronomical_background_layer_test.dart` (removed colorAtX, added SolarBody tests)
- DELETED: `test/features/timeline/painters/solar_marker_layer_test.dart`
- DELETED: `test/features/timeline/painters/lunar_marker_layer_test.dart`

## Test gate
- Before: 355/355 green
- After: 365/365 green (+10)

## Sprint status
- F-29 Astronomical Timeline Theme — All phases COMPLETE
- SkyBody refactor was a post-sprint cleanup requested by Morpheus review
