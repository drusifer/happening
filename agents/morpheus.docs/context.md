# Morpheus Context

## F-29 Astronomical Timeline Theme — 2026-05-18
- Arch doc: `agents/morpheus.docs/ASTRO_THEME_ARCH_2026-05-18.md`
- Key decisions:
  - Add `AppTheme.astronomical` to existing enum in `settings_service.dart`
  - Embed `AstroSettings` (lat/lng/cityName) in `AppSettings` — persisted in settings.json
  - `AstroDataService` as `ChangeNotifier` — offline calc via Dart astro library (Neo picks package)
  - Layer swap pattern in `TimelinePainter.paint()` — conditional on `isAstroTheme && astroData != null`
  - `MoonPhaseBadge` as Flutter widget (not painter layer) — needs gesture/tap support
  - `geolocator` package for OS location — only called on explicit user tap
  - City search as primary manual fallback (Smith Note 2)
  - Gradient starts at `civilTwilightBegin`; sunrise/sunset icons at actual solar event times (Smith Note 1)
  - Up/down arrow on moon icons for rise/set distinction (Smith Note 3)
  - Moon badge 8px left of settings gear (Smith Note 4)
- 5 sprint phases: A (data model/service), B (painter layers), C (location UI), D (badge + theme toggle), E (QA + docs)
- Platform: geolocator needs NSLocationWhenInUseUsageDescription on macOS; GeoClue2 on Linux
- Awaiting Smith Gate 2 approval → Mouse planning

## Send-to-Back Sprint — 2026-05-13
- Architecture: BaseWindowInteractionStrategy → MacOs + Reserved (Linux+Windows).
- sendToBack: setAlwaysOnTop(false)+blur()+lower(). restoreToFront: setAlwaysOnTop(true) only.
- TimelineFocusController: _isSentToBack + 10s restore timer.
- Arch doc: agents/morpheus.docs/SEND_TO_BACK_ARCH_2026-05-13.md

## Linux Reserved Space (F-28) — 2026-05-18
- Phases A+B+hotfixes DONE. Phase C (Trin UAT + Morpheus review) PENDING.
- Arch doc: agents/morpheus.docs/LINUX_RESERVED_ARCH_2026-05-16.md

## Linux Click-Through Research — 2026-04-26
- DROPPED. Click-through replaced by Send-to-Back.

---
*Last updated: 2026-05-18*
