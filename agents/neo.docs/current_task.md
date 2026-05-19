# Neo Current Task — 2026-05-18

**Status**: F-29 Astronomical Timeline Theme Sprint — Phases A+B+C+D COMPLETE + gradient hotfix 2026-05-19

## What was completed this session

### AST-A1: Dependencies + Data model
- Added `apsl_sun_calc: ^0.0.4` and `geolocator: any` to `pubspec.yaml`
- Created `app/lib/core/astro/astro_settings.dart`:
  - `MoonPhase` enum (8 values) with `fromFraction()` mapping suncalc's 0–1 phase
  - `AstroData` value object (civil twilight, sunrise, noon, sunset, moonrise, moonset, phase, illumination)
  - `AstroSettings` value object (lat, lng, cityName + copyWith/toJson/fromJson)
- Created `app/test/core/astro/astro_settings_test.dart` — 18 tests ✅

### AST-A2: AstroDataService
- Added `AppTheme.astronomical` to `AppTheme` enum in `settings_service.dart`
- Added `AstroSettings astroSettings` field to `AppSettings` (copyWith/toJson/fromJson)
- Created `app/lib/core/astro/astro_data_service.dart`:
  - `AstroDataService extends ChangeNotifier`
  - Listens to `SettingsService`, calculates via `SunCalc.getTimes()` + `getMoonTimes()` + `getMoonIllumination()`
  - In-memory cache keyed by (dateKey, lat, lng); midnight timer invalidates
  - Emits `AstroData? current` (null if no location or theme != astronomical)
- Created `app/test/core/astro/astro_data_service_test.dart` — 8 tests ✅

### AST-B1: AstronomicalBackgroundLayer
- Created `app/lib/features/timeline/painters/astronomical_background_layer.dart`
- Horizontal LinearGradient: dark-navy → orange-pink → sky-blue → sky-blue → orange-pink → dark-navy
- Stops mapped via `layout.xForTime()` / stripWidth, clamped to [0,1]
- Created `app/test/features/timeline/painters/astronomical_background_layer_test.dart` — 6 tests ✅

### AST-B2: SolarMarkerLayer
- Created `app/lib/features/timeline/painters/solar_marker_layer.dart`
- Sunrise (orange circle + rays) and sunset (red-orange circle + rays) at exact event times
- Solar noon: vertical tick + ☉ label
- Clips to [0, stripWidth]
- Created `app/test/features/timeline/painters/solar_marker_layer_test.dart` — 4 tests ✅

### AST-B3: LunarMarkerLayer + TimelinePainter wiring
- Created `app/lib/features/timeline/painters/lunar_marker_layer.dart`
- Moon phase silhouette (shadow-circle technique), directional arrows for rise/set
- Clips to [0, stripWidth], null-safe for days with no moonrise/moonset
- Updated `app/lib/features/timeline/timeline_painter.dart`:
  - New params: `astroData: AstroData?`, `isAstroTheme: bool`
  - Conditionally replaces `BackgroundLayer` → `AstronomicalBackgroundLayer`; inserts `SolarMarkerLayer` + `LunarMarkerLayer` before `PastOverlayLayer`
  - Updated `shouldRepaint` for new params
- Created `app/test/features/timeline/painters/lunar_marker_layer_test.dart` — 3 tests ✅

### AST-C1/C2: Location Settings UI
- Updated `app/lib/features/timeline/settings_panel.dart`:
  - Added `GetDevicePosition` + `ResolveCityName` + `CityResult` typedefs (injectable)
  - 4th column `_AstroLocationSection` shown when `AppTheme.astronomical`
  - "Use Current Location" button via geolocator with permission UX (denied/deniedForever message)
  - City search TextField → `resolveCityName()` → no-match error or preview+Confirm
  - Advanced section (collapsed): lat/lng decimal fields with validation + Apply button
  - Location preview label (city · coord) or "Set location" prompt
- 8 new tests in `settings_panel_test.dart` ✅

### AST-D1: AppTheme.astronomical + settings persistence
- `AppTheme.astronomical` added to enum (AST-A2 above)
- `AstroSettings` embedded in `AppSettings` (AST-A2 above)
- `app.dart` _resolveTheme updated for `astronomical` → `Brightness.dark`

### AST-D2: MoonPhaseBadge + tree wiring
- Created `app/lib/features/timeline/moon_phase_badge.dart`
  - Shows 8-phase emoji icon + illumination %
  - Tooltip: "Phase Name · X% illuminated"
  - Tap → calls `onTap` (opens settings)
- Updated `app/lib/features/timeline/timeline_strip.dart`:
  - `AstroDataService` created in `initState()`, disposed in `dispose()`
  - Passes `astroData` + `isAstroTheme` to `TimelinePainter`
  - Shows `MoonPhaseBadge` when `_astroDataService.current != null` (8px left of settings gear)
- 5 new tests in `moon_phase_badge_test.dart` ✅

## Test gate
- Baseline: 276 tests
- F-29 end: 328/328 green (+52 tests)
- `flutter analyze`: no new errors in F-29 code (pre-existing errors untouched)

## Sprint acceptance criteria status
- AC-1: "Astronomical" theme in settings, persisted ✅ (AST-D1)
- AC-2: Gradient civil twilight → sunrise → day → sunset → civil twilight end ✅ (AST-B1)
- AC-3: Sunrise/sunset icons at actual solar event times ✅ (AST-B2)
- AC-4: Moonrise/moonset icons with phase symbol + directional arrow; clip cleanly ✅ (AST-B3)
- AC-5: Moon phase badge always visible; positioned left of settings gear; tooltip ✅ (AST-D2)
- AC-6: Location: geolocator button + permission UX; city search + error; lat/lng advanced ✅ (AST-C1/C2)
- AC-7: Switching theme off removes astro elements immediately ✅ (AstroDataService emits null)
- AC-8: Zero network calls; fully offline after location saved ✅ (apsl_sun_calc is offline)
- AC-9: `make test` green at/above baseline ✅ (328/328)
