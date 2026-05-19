# Current Task — 2026-05-18

## F-29 Astronomical Timeline Theme — AST-E1 UAT

**Status**: UAT PASS (1 known non-blocking gap)

### Test Gate
- `flutter test`: 328/328 ✅
- `flutter analyze`: No new errors in F-29 code ✅

### AC Checklist

| AC | Status | Notes |
|----|--------|-------|
| AC-1: Astronomical in theme picker | ✅ | AppTheme.astronomical enum value; in _PickerRow |
| AC-2: Gradient correct colors/stops | ✅ | dark-navy→orange→sky-blue→orange→dark-navy at civil twilight/sunrise/sunset |
| AC-3: Icons at actual sunrise/sunset | ✅ | astroData.sunrise / astroData.sunset (not twilight boundaries) |
| AC-4: Moon icons + directional arrows | ✅ | up=rise, down=set; phase silhouette; clips at window edges |
| AC-5: MoonPhaseBadge + tooltip | ✅ | 8px left of settings gear; Tooltip "Phase · X% illuminated" |
| AC-6: Location UI | ✅ | geolocator button + permission error; city search error msg; lat/lng advanced |
| AC-7: Theme toggle off removes layers | ✅ | AstroDataService emits null → useAstro=false → BackgroundLayer fallback |
| AC-8: Zero network calls | ✅ | apsl_sun_calc is offline; geolocator uses OS APIs |
| AC-9: 328/328 + analyze clean | ✅ | +52 tests from baseline; no new lint errors |

### Known Gap (non-blocking)
City name → lat/lng geocoding always returns null. `_defaultResolveCityName` returns null with a comment noting this. Users must use device location button or Advanced lat/lng fields. Error UX is correct per spec ("No results for 'X' — try a larger nearby city, or use Advanced coordinates.").

*Last updated: 2026-05-18*
