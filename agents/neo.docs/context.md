# Neo Context — 2026-05-25

## Current State
All work complete. 350/350 tests green. Ready for /clear.

## Session work (2026-05-25)

### 1. Now-line DPI/font scaling fix (timeline_strip.dart)
- **Problem**: `nowIndicatorX` was hardcoded at `stripWidth * 0.10`, causing the countdown timer to collide with the left toolbar buttons at high DPI (narrow logical strip) or large font sizes (wide countdown text).
- **Fix**: Replaced hardcoded fraction with a formula derived from actual widget sizes:
  ```dart
  const double leftToolbarRight = 8.0 + 3 * 24.0 + 2 * 4.0; // = 88px
  final double countdownEst = fontSize * 5.0 + 12.0;
  final double nowIndicatorX = (leftToolbarRight + 16.0 + countdownEst)
      .clamp(0.0, stripWidth * 0.35);
  final double actualFraction = nowIndicatorX / stripWidth;
  ```
- Window start/end split now uses `actualFraction` (was hardcoded 0.125/0.875).
- **Key constraint**: Do NOT use `devicePixelRatio` as a multiplier — Flutter test harness uses DPR=3.0 and layout is already in logical pixels. The clamp handles high-DPI narrow strips automatically.
- Golden test regenerated. Test hover positions updated from x=140 → x=260 (event at now+30min now starts at ~241px with default font on 800px strip).

### 2. Geolocator removal
- Removed `geolocator: any` from pubspec.yaml (dropped 6 packages).
- Removed all geolocator API calls from settings_panel.dart: `_defaultGetDevicePosition`, `_useDeviceLocation`, `GetDevicePosition` typedef, `getDevicePosition` param on SettingsPanel + _AstroLocationSection, "Use Current Location" button + spinner + error text.
- `_defaultResolveCityName` was a stub returning null (city search broken).

### 3. City search — local GeoNames asset
- **New file**: `app/lib/core/astro/city_search.dart` — loads `assets/data/cities.csv` (lazy, cached), case-insensitive prefix-then-contains search.
- **New file**: `app/assets/data/cities.csv` — seed file with ~170 major world cities. Run `make fetch-cities` to replace with full GeoNames dataset (~25,000 cities, pop > 15,000).
- **Makefile**: Added `fetch-cities` target (downloads cities15000.zip from GeoNames, processes to name|country|lat|lng CSV). Also added to `setup` as a dependency.
- **pubspec.yaml**: Added `assets/data/cities.csv` asset declaration.
- `_defaultResolveCityName` now delegates to `city_search.searchCity()`. No network calls.

### 4. Advanced lat/lng UI removed
- Removed from settings_panel.dart: `_latController`, `_lngController`, `_showAdvanced`, `_coordError`, `initState()`, `_applyCoords()`, `_buildAdvancedSection()`, `_CoordField` class, Advanced toggle from build().
- `import 'package:flutter/services.dart'` removed (was only for FilteringTextInputFormatter).
- Error message updated: "try a different or nearby city" (no longer references Advanced).
- `AstroSettings` model unchanged — still stores latitude/longitude/cityName (set by city search, read by astronomy engine).
- Deleted 2 tests: "Advanced section hidden by default" and "Apply saves invalid coords shows error".

## Key patterns / constraints
- NEVER use Opacity widget on Linux (GTK regression → use canvas.saveLayer+BlendMode.dstIn in TimelinePainter)
- NEVER use devicePixelRatio to scale Flutter layout positions — it affects physical pixels, not logical
- City search: `city_search.searchCity(query)` returns `({double lat, double lng, String label})?`
- Left toolbar width: `8 + 3*24 + 2*4 = 88px` (left offset + 3 buttons + 2 spacers)
- Now indicator formula: `leftToolbarRight(88) + 16 + fontSize*5.0 + 12` clamped to 35% of strip width
- Test surface: 800px wide, DPR=3.0 (Flutter default in tests — irrelevant since we don't use DPR)
- make fetch-cities requires curl + unzip; `make setup` now includes it as a dependency
