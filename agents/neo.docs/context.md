# Neo Context — 2026-05-19

## Current State
F-29 Astronomical Timeline Theme Sprint — all phases complete + gradient hotfix session complete.
333/333 tests green.

## What was fixed this session

### 1. AstronomicalBackgroundLayer — full rewrite
Old code used invented midpoints (midMorning, midEvening) not tied to solar events.
New code: 4 stops exactly at civilTwilightBegin (amber), sunrise (sky blue), sunset (sky blue), civilTwilightEnd (amber).
`colorAtX()` is package-visible for testing. Doc: `agents/neo.docs/astro_gradient_pre_rewrite.md`.

### 2. AstroDataService — getTimes() replaced with binary search
`SunCalc.getTimes()` has a Julian Day Number epoch bug — returns dates ~6700 years in future.
Fix: binary search on `SunCalc.getSunPosition()` (confirmed correct from package docs/example).
Key design decisions:
- **Nadir-anchored windows**: `nadir_UTC_hour = (24 − lng/15) mod 24`. Rising events: [nadir−2h, nadir+14h]. Falling events: [nadir+10h, nadir+26h]. Covers all timezones without depending on local timezone of machine.
- **Why nadir**: NY civil twilight end falls at 00:41 UTC; at UTC midnight the sun is already above the −6° threshold, breaking the binary search entry condition. Nadir is always at the true minimum.
- **Solar noon**: float midpoint `(sunrise_ms + sunset_ms) / 2.0` — no integer truncation.
- **Moon times**: validated with `_isReasonableDate()` before use; returns null if JDN bug produces wrong date.
- **Error handling**: full try/catch with SEVERE log; null guards for polar day/night.

### 3. Settings panel — lat/lng fields pre-populated
`_AstroLocationSectionState.initState()` now pre-populates `_latController` and `_lngController` from saved `astroSettings`. Previously they were blank even when lat/lng were saved.

## Key files changed
- `app/lib/features/timeline/painters/astronomical_background_layer.dart` — rewritten
- `app/lib/core/astro/astro_data_service.dart` — rewritten (no more getTimes(), binary search)
- `app/lib/features/timeline/settings_panel.dart` — initState pre-populates lat/lng fields
- `app/lib/features/timeline/timeline_strip.dart` — added _onAstroDataChanged log
- `app/test/features/timeline/painters/astronomical_background_layer_test.dart` — rewritten for new API
- `agents/neo.docs/astro_gradient_pre_rewrite.md` — documents old broken approach

## Architecture (unchanged from F-29 sprint)
- `AstroDataService extends ChangeNotifier` — listens to SettingsService, recalculates on change
- `AstronomicalBackgroundLayer implements TimelineLayer` — draws gradient
- `SolarMarkerLayer` — draws sun icons at sunrise/sunset + noon tick
- `LunarMarkerLayer` — draws moon rise/set + phase
- `MoonPhaseBadge` — widget left of settings gear
