# Neo Next Steps — 2026-05-19

## F-29 Astronomical Timeline Theme Sprint — Phases A–D COMPLETE + gradient hotfix

Gradient rewritten 2026-05-19: 4 stops at actual solar event times (civilTwilightBegin=amber, sunrise=skyBlue, sunset=skyBlue, civilTwilightEnd=amber). No invented midpoints. 333/333 green. Doc at agents/neo.docs/astro_gradient_pre_rewrite.md.

Awaiting user feedback on gradient visual — user may have further moon/sun requirements to clarify.

## Handoff to Trin

- Run `flutter test` — should be 328/328
- Manual AC checklist (AST-E1):
  - US-F29-1: device location, city search, lat/lng, persist, no-location prompt
  - US-F29-2: gradient stops at civil twilight; icons at actual sunrise/sunset; solar noon tick; z-order
  - US-F29-3: moonrise/moonset icons + directional arrows; badge always visible; phase + illumination %
  - US-F29-4: theme toggle on/off; persisted; instant apply; location check on activation
  - Platform smoke: macOS, Windows, Linux
  - `flutter analyze` — no new errors in F-29 code

## Key implementation notes for Trin/Morpheus

- `apsl_sun_calc` API: `SunCalc.getTimes()` returns `dawn` (civil twilight begin) and `dusk` (civil twilight end)
- `getMoonTimes()` returns `rise`/`set` as `DateTime?` — null if moon doesn't rise/set that day
- City search resolution returns null always (no geocoding implemented) — lat/lng Advanced field is the workaround
- `AstroDataService` created inside `_TimelineStripState.initState()` (not injected from main.dart)

## Files changed (F-29)

### New files
- `app/lib/core/astro/astro_settings.dart` — AstroSettings, AstroData, MoonPhase
- `app/lib/core/astro/astro_data_service.dart` — AstroDataService
- `app/lib/features/timeline/painters/astronomical_background_layer.dart`
- `app/lib/features/timeline/painters/solar_marker_layer.dart`
- `app/lib/features/timeline/painters/lunar_marker_layer.dart`
- `app/lib/features/timeline/moon_phase_badge.dart`
- `app/test/core/astro/astro_settings_test.dart`
- `app/test/core/astro/astro_data_service_test.dart`
- `app/test/features/timeline/painters/astronomical_background_layer_test.dart`
- `app/test/features/timeline/painters/solar_marker_layer_test.dart`
- `app/test/features/timeline/painters/lunar_marker_layer_test.dart`
- `app/test/features/timeline/moon_phase_badge_test.dart`

### Modified files
- `app/pubspec.yaml` — added apsl_sun_calc, geolocator
- `app/lib/core/settings/settings_service.dart` — AppTheme.astronomical, AstroSettings in AppSettings
- `app/lib/features/timeline/timeline_painter.dart` — astroData/isAstroTheme params + layer wiring
- `app/lib/features/timeline/timeline_strip.dart` — AstroDataService lifecycle + MoonPhaseBadge
- `app/lib/features/timeline/settings_panel.dart` — Location column (C1/C2)
- `app/lib/app.dart` — astronomical case in _resolveTheme
- `app/test/features/timeline/settings_panel_test.dart` — 8 new astro tests
