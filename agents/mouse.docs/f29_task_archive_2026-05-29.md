# Task Board — Astronomical Timeline Theme Sprint (F-29)
**Updated**: 2026-05-18 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal
Add an opt-in "Astronomical" theme that overlays sunrise, sunset, moonrise, and moonset
markers on the timeline at their exact times, with a day/night gradient background.
All astronomical data calculated offline from user's location via a Dart astronomy library.
Location sourced via `geolocator` OS API (with city-search + manual lat/lng fallback).

## Source Artifacts
- Product stories: `agents/cypher.docs/f29_astronomical_theme_stories.md`
- UX Gate 1: `agents/smith.docs/f29_gate1_review_2026-05-18.md`
- Architecture: `agents/morpheus.docs/ASTRO_THEME_ARCH_2026-05-18.md`
- UX Gate 2: `agents/smith.docs/f29_gate2_review_2026-05-18.md`

---

## Phase A — Data Models + Service
**Gate**: `make test` green; `AstroDataService` calculates and caches solar + lunar data correctly

### AST-A1: Dependencies + Data model
- **Goal**: Add `geolocator: any` and Dart astronomy library (Neo selects best pub.dev package
  for sunrise/sunset/moonrise/moonset/phase) to `pubspec.yaml`. Create `app/lib/core/astro/`:
  - `AstroSettings` — value object: `latitude: double?`, `longitude: double?`, `cityName: String?`
  - `AstroData` — value object: `civilTwilightBegin`, `sunrise`, `solarNoon`, `sunset`,
    `civilTwilightEnd` (all `DateTime`); `moonrise: DateTime?`, `moonset: DateTime?`;
    `phase: MoonPhase`, `illuminationFraction: double`
  - `MoonPhase` — 8-value enum: `newMoon`, `waxingCrescent`, `firstQuarter`, `waxingGibbous`,
    `full`, `waningGibbous`, `lastQuarter`, `waningCrescent`
  **Before coding**: Neo evaluates available pub.dev astronomy packages and posts
  the chosen package name + rationale to CHAT.md for Morpheus review.
  Write unit tests for `AstroData` equality and `MoonPhase`.
- **Files**:
  - `app/pubspec.yaml` ✎
  - `app/lib/core/astro/astro_settings.dart` ✦
  - `app/test/core/astro/astro_settings_test.dart` ✦
- **Risk**: Low
- **Tests**: `make test` green

### AST-A2: `AstroDataService`
- **Goal**: Create `AstroDataService extends ChangeNotifier`.
  Listens to `SettingsService`; calculates solar + lunar data via Dart astro library for
  (today, lat, lng); caches in memory for (date, lat, lng); midnight timer invalidates cache.
  Exposes `AstroData? current` (null if no location or theme != astronomical). No network calls.
  Write unit tests: correct solar times for known lat/lng; correct moonPhase for known dates;
  cache hit; null when no location set.
- **Files**:
  - `app/lib/core/astro/astro_data_service.dart` ✦
  - `app/test/core/astro/astro_data_service_test.dart` ✦
- **Risk**: Medium — Dart astro library API varies by package
- **Tests**: `make test` green

---

## Phase B — Painter Layers
**Gate**: `make test` green; visual smoke: gradient + icons visible at correct timeline positions

### AST-B1: `AstronomicalBackgroundLayer`
- **Goal**: New `TimelineLayer` replacing `BackgroundLayer` when astronomical theme active.
  Horizontal linear gradient with stops at civil twilight times:
  - Before `civilTwilightBegin` → dark navy `Color(0xFF0A0E1A)`
  - `civilTwilightBegin` → `sunrise` → warm orange/pink `Color(0xFFFF8C42)`
  - `sunrise` → `sunset` → sky blue `Color(0xFF87CEEB)`
  - `sunset` → `civilTwilightEnd` → warm orange/pink
  - After `civilTwilightEnd` → dark navy
  Uses `TimelineLayout.xForTime()` for pixel mapping; clips to visible window.
  Write tests: gradient stop positions for known inputs.
- **Files**:
  - `app/lib/features/timeline/painters/astronomical_background_layer.dart` ✦
  - `app/test/features/timeline/painters/astronomical_background_layer_test.dart` ✦
- **Risk**: Low
- **Tests**: `make test` green

### AST-B2: `SolarMarkerLayer`
- **Goal**: New `TimelineLayer` for solar event icons.
  - Sunrise icon (☀️ or custom SVG) at `layout.xForTime(astroData.sunrise)`
  - Sunset icon at `layout.xForTime(astroData.sunset)`
  - Solar noon small tick + label at `layout.xForTime(astroData.solarNoon)`
  All clipped to `[0, stripWidth]`; renders BELOW event blocks.
  Write tests: icon x positions match expected for given solar times; clips correctly.
- **Files**:
  - `app/lib/features/timeline/painters/solar_marker_layer.dart` ✦
  - `app/test/features/timeline/painters/solar_marker_layer_test.dart` ✦
- **Risk**: Low
- **Tests**: `make test` green

### AST-B3: `LunarMarkerLayer` + `TimelinePainter` wiring
- **Goal**: New `TimelineLayer` for moon event icons.
  - Moonrise: 8-phase moon icon + upward arrow at `layout.xForTime(astroData.moonrise)` if in window
  - Moonset: same phase icon (dimmer) + downward arrow at `layout.xForTime(astroData.moonset)` if in window
  - Clips to `[0, stripWidth]`; no overflow artifact
  Wire `TimelinePainter`:
  - Add params: `astroData: AstroData?`, `isAstroTheme: bool`
  - When `isAstroTheme && astroData != null`: replace `BackgroundLayer` → `AstronomicalBackgroundLayer`;
    insert `SolarMarkerLayer` + `LunarMarkerLayer` after background, before `PastOverlayLayer`
  - When not astronomical: existing layer order unchanged
  Update `shouldRepaint` for new params.
- **Files**:
  - `app/lib/features/timeline/painters/lunar_marker_layer.dart` ✦
  - `app/test/features/timeline/painters/lunar_marker_layer_test.dart` ✦
  - `app/lib/features/timeline/timeline_painter.dart` ✎
  - `app/test/features/timeline/timeline_painter_test.dart` ✎
- **Risk**: Medium — `TimelinePainter` has many existing tests; param additions must not regress
- **Tests**: `make test` green

---

## Phase C — Location Settings UI
**Gate**: "Use Current Location" works on all platforms; city search resolves or errors correctly; prompt shown when no location

### AST-C1: geolocator — "Use Current Location" button
- **Goal**: Add "Location" section to `settings_panel.dart` (visible when Astronomical theme enabled).
  "Use Current Location" button calls `geolocator.getCurrentPosition()`.
  Permission UX (Smith Note 5):
  - `granted` → save lat/lng to `AstroSettings`; show "Using device location" label
  - `denied` → inline: "Location access denied. Grant permission in System Settings, or enter your location below."
  - `deniedForever` → same message
  Platform entitlements:
  - macOS: add `NSLocationWhenInUseUsageDescription` to `macos/Runner/Info.plist`
  - Windows: no extra config
  - Linux: GeoClue2 — graceful fallback message if unavailable
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/macos/Runner/Info.plist` ✎
  - `app/test/features/timeline/settings_panel_test.dart` ✎
- **Risk**: Medium — permission flows vary per platform
- **Tests**: `make test` green; manual smoke on all platforms

### AST-C2: City search + lat/lng override + location preview
- **Goal**: City search text field (primary manual fallback, Smith Note 2):
  - Resolves city name to lat/lng via OS geocode or bundled lookup
  - No match → "No results for '{query}' — try a larger nearby city, or use Advanced coordinates." (Smith Note 6)
  - Match → preview "New York, NY → 40.71°N 74.00°W"; user confirms to save
  Advanced section (collapsed): raw lat/lng decimal fields; validates range; inline error if invalid.
  Location preview label always shown (city name or coordinate string).
  No-location prompt: when astronomical + no location → "Set location to see sunrise & moon times" in strip (AC-F29-1-6).
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/test/features/timeline/settings_panel_test.dart` ✎
- **Risk**: Low (UI only)
- **Tests**: `make test` green

---

## Phase D — Badge + Theme Toggle
**Gate**: `make test` green; Astronomical theme activates/deactivates correctly; moon badge visible

### AST-D1: `AppTheme.astronomical` + settings persistence
- **Goal**: Add `astronomical` to `AppTheme` enum in `settings_service.dart`.
  Add `AstroSettings astroSettings` field to `AppSettings` (default: empty).
  Update `toJson`/`fromJson`/`copyWith`. Existing `fromString` fallback is already safe.
  Add Theme selector to settings panel: "Default" / "Astronomical".
  Switching to Astronomical: if location saved → apply immediately; else → expand location section.
  Switching to Default: removes all astro layers immediately, no restart.
- **Files**:
  - `app/lib/core/settings/settings_service.dart` ✎
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/test/core/settings/settings_service_test.dart` ✎
- **Risk**: Low (additive; safe fallbacks)
- **Tests**: `make test` green

### AST-D2: `MoonPhaseBadge` + tree wiring
- **Goal**: Create `MoonPhaseBadge` widget — always visible when astronomical + location set.
  Shows: phase icon + phase name + illumination %. Tooltip on hover: full phase name + "X% illuminated" (Smith Note 7).
  Position: right side of strip, 8px left of settings gear; does not reduce gear tap target (Smith Note 4).
  Wire `AstroDataService` into widget tree from `main.dart`.
  Wire `TimelineStrip`: consume `AstroDataService.current` → pass to `TimelinePainter`; add `MoonPhaseBadge`.
- **Files**:
  - `app/lib/features/timeline/moon_phase_badge.dart` ✦
  - `app/lib/features/timeline/timeline_strip.dart` ✎
  - `app/lib/main.dart` ✎
  - `app/test/features/timeline/moon_phase_badge_test.dart` ✦
  - `app/test/features/timeline/timeline_strip_test.dart` ✎
- **Risk**: Medium — widget tree wiring; existing strip tests must still pass
- **Tests**: `make test` green

---

## Phase E — QA + Review
**Gate**: All US-F29 AC verified; Morpheus approved; docs updated

### AST-E1: Trin UAT
- **Owner**: @Trin
- **Goal**: Full test suite (`make test`). Manual AC checklist:
  - US-F29-1: device location, city search, lat/lng, persist, no-location prompt
  - US-F29-2: gradient stops at civil twilight; icons at actual sunrise/sunset; solar noon tick; z-order
  - US-F29-3: moonrise/moonset icons + directional arrows; badge always visible; phase + illumination %
  - US-F29-4: theme toggle on/off; persisted; instant apply; location check on activation
  Platform smoke: macOS, Windows, Linux. `make analyze` clean.
- **Risk**: Low if all prior phases clean

### AST-E2: Morpheus code review + Oracle doc pass
- **Owner**: @Morpheus (review) + @Oracle (docs)
- **Goal**: Morpheus: review `AstroDataService` (midnight timer, cache, ChangeNotifier lifecycle),
  painter layer isolation, `TimelinePainter` param additions.
  Oracle: update `docs/ARCH.md` (new astro subsystem), mark F-29 shipped in PRD.
- **Risk**: Low

---

## Sprint Acceptance Criteria (Definition of Done)
1. "Astronomical" theme visible in settings, persisted across restarts
2. Gradient: civil twilight begin → sunrise → day → sunset → civil twilight end (correct colors)
3. Sunrise/sunset icons at actual solar event times (not twilight boundaries)
4. Moonrise/moonset icons with 8-phase symbol + directional arrow; clip cleanly at window edge
5. Moon phase badge always visible; positioned left of settings gear; tooltip on hover
6. Location: geolocator button + permission UX; city search with error handling; lat/lng advanced override
7. Switching theme off removes all astro elements immediately; no regression on default theme
8. Zero network calls for astronomical data; fully offline after location saved
9. `make test` green at or above pre-sprint baseline; `make analyze` clean

---

## Status Legend
✦ New file | ✎ Modified | 🗑 Deleted

---

# Previous Sprint — Linux Reserved Space Sprint (F-28)
**Updated**: 2026-05-16 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus
**Status**: Phases A+B+hotfixes DONE (276/276 green) — Phase C PENDING

---

## Phase C — QA + Review (PENDING)

### LRS-C1: Trin UAT
- Run full test suite (`make test`).
- Manual AC checklist: AC-L1-1 through AC-L3-2.
- X11/XWayland smoke: maximize a terminal over strip; confirm strip not covered.
- Wayland smoke: confirm app starts without crash, log shows `isDockable=false`.

### LRS-C2: Morpheus code review
- Review `linux_dock_window_manager_plugin.cc` for memory safety (atom reuse, no XFree leaks).
- Review `WindowService` wiring for serialisation (no concurrent dock/undock race).
- Approve or return to Neo.
