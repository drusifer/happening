# Architecture — F-29 Astronomical Timeline Theme
*Morpheus — 2026-05-18*

## Summary

F-29 adds an opt-in "Astronomical" theme. When active, the timeline background renders
a day/night gradient (civil twilight → sunrise → day → sunset → civil twilight) and
sun/moon icons appear at their exact timeline positions. All data is calculated offline
from a saved lat/lng using a Dart astronomy library. Location is obtained via the
`geolocator` Flutter package (OS native) with a city-search + raw-coordinate fallback.

---

## Design Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Add `astronomical` to existing `AppTheme` enum | `AppTheme` already persisted in `AppSettings`; `fromString` has safe fallback; zero breaking change |
| D2 | Embed `AstroSettings` (lat/lng/cityName) inside `AppSettings` | Keeps single settings file; consistent with existing `selectedCalendarIds` list pattern |
| D3 | `AstroDataService` as `ChangeNotifier`, separate from `SettingsService` | Settings → triggers recalc; result flows to painter; no polling needed |
| D4 | Layer injection — swap/insert in `TimelinePainter.paint()` layers list | Existing compositor pattern; zero coupling; fallback is just existing `BackgroundLayer` |
| D5 | Moon phase badge as Flutter widget, not painter layer | Needs to be a tap target (opens location settings); painter layers can't receive gestures |
| D6 | Sunrise icon at `astroData.sunrise`, gradient starts at `civilTwilightBegin` | Smith Note 1: "sun icon implies sun is up" — gradient = sky; icon = solar event |
| D7 | City search as primary manual location fallback | Smith Note 2: raw lat/lng is too technical for most users |
| D8 | Dart astronomy library for all solar + lunar data | No external API; offline; Drew decision. Neo to select pub.dev package during Phase A. |

---

## Component Map

```
AppSettings
  ├── AppTheme (enum) — add: astronomical
  └── AstroSettings (new value object)
        ├── latitude: double?
        ├── longitude: double?
        └── cityName: String?          ← display label from city search or reverse geocode

AstroDataService (ChangeNotifier)
  ├── listens to: SettingsService
  ├── recalculates when: date changes OR location changes
  ├── uses: Dart astronomy library (pub.dev — Neo selects)
  └── exposes: AstroData? (null until location set)

AstroData (value object)
  ├── civilTwilightBegin: DateTime     ← gradient starts
  ├── sunrise: DateTime                ← sunrise icon
  ├── solarNoon: DateTime              ← noon tick
  ├── sunset: DateTime                 ← sunset icon
  ├── civilTwilightEnd: DateTime       ← gradient ends
  ├── moonrise: DateTime?              ← null if no moonrise today
  ├── moonset: DateTime?               ← null if no moonset today
  ├── phase: MoonPhase (enum, 8 values)
  └── illuminationFraction: double     ← 0.0–1.0

TimelinePainter
  ├── existing: backgroundColor, events, layout...
  ├── new params: astroData: AstroData?, isAstroTheme: bool
  └── paint() layers list (when isAstroTheme && astroData != null):
        [0] AstronomicalBackgroundLayer  ← replaces BackgroundLayer
        [1] SolarMarkerLayer             ← new, below events
        [2] LunarMarkerLayer             ← new, below events
        [3] PastOverlayLayer             ← existing (unchanged)
        [4] TickLayer                    ← existing (unchanged)
        [5] EventsLayer                  ← existing (unchanged)
        [6] NowIndicatorLayer            ← existing (unchanged)
        [7] FetchingLayer                ← existing (unchanged)
        [8] SignInLayer                  ← existing (unchanged)

New painter layers:
  AstronomicalBackgroundLayer
    ├── inputs: windowStart, windowEnd, stripWidth, astroData, layout
    └── draws: horizontal LinearGradient with stops at:
          civil_twilight_begin → sunrise → solar_noon → sunset → civil_twilight_end
          Colors: dark-navy → orange-pink → sky-blue → sky-blue → orange-pink → dark-navy

  SolarMarkerLayer
    ├── inputs: layout, astroData, stripWidth
    └── draws: sunrise SVG icon at layout.xForTime(sunrise),
               sunset SVG icon at layout.xForTime(sunset),
               small tick at layout.xForTime(solarNoon)
               — clips to [0, stripWidth]; no icon if outside window

  LunarMarkerLayer
    ├── inputs: layout, astroData, stripWidth
    └── draws: moon-phase icon + upward arrow at moonrise x (if in window)
               moon-phase icon + downward arrow at moonset x (if in window)
               — 8-phase SVG set; clips to [0, stripWidth]

TimelineStrip (widget)
  └── new: MoonPhaseBadge widget (always visible when astro theme + location set)
        ├── position: right side, left of settings gear, 8px separation (Smith Note 4)
        ├── content: phase name + illumination %
        └── tap: opens settings location section

SettingsPanel (widget)
  └── new sections when AppTheme.astronomical:
        Theme selector (Default / Astronomical)
        Location section:
          [Use Current Location button] ← geolocator.getCurrentPosition()
          [City search field]           ← primary manual fallback (Smith Note 2)
          [Advanced: lat / lng fields]  ← override, collapsed by default
          [Location preview label]      ← "New York, NY" or "40.71°N 74.00°W"
```

---

## New Files

| File | Purpose |
|------|---------|
| `app/lib/core/astro/astro_settings.dart` | `AstroSettings` value object + `MoonPhase` enum + `AstroData` |
| `app/lib/core/astro/astro_data_service.dart` | `AstroDataService` — calculates and caches daily astro data |
| `app/lib/features/timeline/painters/astronomical_background_layer.dart` | Day/night gradient painter |
| `app/lib/features/timeline/painters/solar_marker_layer.dart` | Sunrise/sunset/noon painter |
| `app/lib/features/timeline/painters/lunar_marker_layer.dart` | Moonrise/moonset icon painter |
| `app/lib/features/timeline/moon_phase_badge.dart` | Phase + illumination widget |

---

## Modified Files

| File | Change |
|------|--------|
| `app/lib/core/settings/settings_service.dart` | Add `AppTheme.astronomical`; add `AstroSettings` field to `AppSettings`; toJson/fromJson |
| `app/lib/features/timeline/timeline_painter.dart` | Add `astroData`, `isAstroTheme` params; conditional layer swap/insert |
| `app/lib/features/timeline/timeline_strip.dart` | Wire `AstroDataService`; add `MoonPhaseBadge` widget |
| `app/lib/features/timeline/settings_panel.dart` | Add Theme selector; add Location section with geolocator + city search |
| `app/lib/main.dart` | Instantiate `AstroDataService`; provide to widget tree |
| `app/pubspec.yaml` | Add `geolocator: any`; add Dart astronomy library (Neo selects) |

---

## Platform Notes (geolocator)

| Platform | Notes |
|----------|-------|
| macOS | Requires `NSLocationWhenInUseUsageDescription` in Info.plist |
| Windows | Uses Windows.Devices.Geolocation — no extra config |
| Linux | Uses GeoClue2 D-Bus — requires GeoClue2 running; graceful fallback if unavailable |

geolocator is used **only** when the user taps "Use Current Location". It is NOT called
at startup, NOT called on each paint, and NOT cached by the app beyond storing the
resulting lat/lng in `AstroSettings`. Permission is requested once per tap.

---

## `AstroDataService` Recalculation Logic

```
On settings change:
  if theme == astronomical && location set:
    if cached (date, lat, lng) == (today, lat, lng):
      emit cached
    else:
      calculate via astro library
      cache result
      emit result
  else:
    emit null

On midnight tick (day change):
  invalidate cache
  recalculate if conditions met
```

No network calls. No persistence beyond the day cache in memory.

---

## Smith Notes — Architecture Response

| Note | Response |
|------|----------|
| Note 1: Sunrise icon at actual sunrise, gradient at civil twilight | D6 above — `SolarMarkerLayer` draws icons at `sunrise`/`sunset`; `AstronomicalBackgroundLayer` starts gradient at `civilTwilightBegin` |
| Note 2: City search as primary manual fallback | Location section UI: city search field is primary; lat/lng is collapsed "Advanced" section |
| Note 3: Moon rising vs. setting — directional cue | `LunarMarkerLayer` draws an up-arrow badge below the moonrise icon and a down-arrow badge below the moonset icon |
| Note 4: Moon badge must not reduce settings gear tap target | `MoonPhaseBadge` positioned at fixed offset left of settings gear; gear tap target is untouched |

---

## Sprint Phases (for Mouse)

| Phase | Tasks | Owner |
|-------|-------|-------|
| A — Data model + service | `AstroSettings`, `AstroData`, `MoonPhase`, `AstroDataService`, Dart astro lib wired | Neo |
| B — Painter layers | `AstronomicalBackgroundLayer`, `SolarMarkerLayer`, `LunarMarkerLayer`; `TimelinePainter` wired | Neo |
| C — Location settings UI | geolocator button, city search, lat/lng override, location preview, prompt AC | Neo |
| D — Badge + theme toggle | `MoonPhaseBadge` widget; Theme selector in settings panel; `AppTheme.astronomical` enum add | Neo |
| E — QA + docs | Trin UAT all US-F29 AC; Oracle doc pass (ARCH.md, PRD.md) | Trin, Oracle |
