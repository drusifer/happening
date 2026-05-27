# Happening v0.5.1

Released: 2026-05-27
Compare: `20260423` → `release/0.5.1` (38 commits)

## Highlights

### Astronomical theme
A new opt-in theme paints the timeline strip with a live sky background:
- Solar arc drives the day-cycle gradient (navy → amber → blue → amber → navy)
- Moon glow appears above the horizon at night, scaled by tonight's illumination fraction
- Stars in the night portion with twilight-faded brightness
- Sun, sunrise, sunset, moonrise, transit and moonset glyphs are placed at the
  correct positions on the strip
- Background gradient continues smoothly through moonrise-during-day and
  moon-up-at-sunset transitions

### macOS support
Happening now builds and runs natively on macOS, with transparent-background
support matching the Linux/Windows behaviour.

### Transparent background (Linux + macOS)
The strip can be rendered with a transparent background so calendar events
read directly against the desktop wallpaper.

### Settings UI
- Continuous font-size slider (11–22pt, 1pt steps), replacing the S/M/L picker
- Transparency slider
- City search for setting location (powered by an offline GeoNames asset,
  ~33k cities, no network calls)

### Send-to-back
Cross-platform send-to-back lowers the always-on-top window for 10 s before
auto-restoring, useful for grabbing whatever is underneath without quitting.

## Bug fixes
- **Moonrise during the day no longer paints lunar lighting onto the daytime
  region** — lunar arcs are now clipped to the night portion of each moon-up
  window.
- **Sunset twilight with moon up** now transitions amber → moonlit (instead of
  amber → navy → moonlit), eliminating the dark dead-zone at civil-twilight
  end. Mirror behaviour at dawn.
- Fixed Linux secondary-display layout regression.
- Fixed Windows initial-size race (`afterReadyToShow` now locks the collapsed
  height post-show, no more startup squish).
- Fixed Linux login flow failure.
- Fixed overlapping-event card stacking (exact-overlap groups now render with
  per-rank offset; hit testing matches the painter).
- `make` now runs natively on Windows (cross-platform helpers under
  `tools/mkf.py`, `print_help.py`, `sync_version.py`).
- Flutter SDK pinned to a version compatible with Ubuntu 26.04 LTS.

## Architecture & internals
- New `core/astro/` module: `AstroDataService`, `SolarCalculator`,
  `AstroSettings`, `CitySearch`, plus an `AstroData` value object.
- Background painter refactored to a small `SkyBody` hierarchy
  (`SolarBody`, `LunarBody`) emitting `Arc` segments. The lunar/solar
  branching that lived in `AstronomicalBackgroundLayer` is gone — ABL now
  just collects arcs, clips solar where lunar overlaps, and paints one
  `LinearGradient`.
- Window service split per platform (`WindowsWindowService`,
  `LinuxWindowService`, `MacosWindowService`, `LinuxDockWindowManager`) with
  shared resize strategies and a `WindowInteractionStrategy` hierarchy.
- `ExpansionController` + `ResizeExecutor` replace the old AsyncGate /
  HoverController / CountdownState scaffolding.
- New `TimelineFocusController`.
- Single source of truth for app version: `app/assets/version.txt`
  (synced via `sync_version.py`).

## Test coverage
- 352/352 green at tip of `release/0.5.1`.
- New scenario tests for astro background (rise/set × day/night matrix,
  short-night fallback, amber bridge, upColor scaling).
- New tests for `ExpansionController`, `LinuxDockWindowManager`,
  `WindowInteractionStrategy`, `TimelineFocusController`, `TimelineLayout`.

## Removed
- Dead `simple_main.dart`, `windows_test.dart` scratch entry points.
- Old `AsyncGate`, `HoverController` hierarchy, `CountdownState`,
  `EventBoundsCalculator` standalone classes (functionality folded into
  newer controllers).
