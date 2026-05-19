# Current Task — 2026-05-18

**Status:** F-29 Code Review COMPLETE — APPROVED

## Code Review: F-29 Astronomical Timeline Theme (AST-E2)

### Issues Found and Resolved

| Issue | Severity | Resolution |
|-------|----------|-----------|
| `AstroDataService._recalculate` missing disposed guard — `notifyListeners()` could fire after dispose | HIGH | Fixed: added `_disposed = true` in `dispose()`, check `if (_disposed) return` after `await SunCalc.getTimes()` |

### Architecture Findings (Non-blocking)

| Finding | Verdict |
|---------|---------|
| `AstroDataService` created in `_TimelineStripState.initState()` (not main.dart as arch doc specified) | ACCEPTABLE — equivalent lifecycle; avoids threading through HappeningApp |
| City geocoding always returns null (`_defaultResolveCityName`) | KNOWN GAP — error UX correct; lat/lng advanced field is workaround |
| `_useDeviceLocation` calls real `Geolocator.checkPermission()` after injected callback | MINOR — doesn't affect production; noted for future test refactor |
| Gradient stop ordering — duplicate stops possible when all events outside window | SAFE — Flutter allows duplicate stops; shows all-dark/all-day correctly |

### Painter Layer Review

- **AstronomicalBackgroundLayer**: Clean `TimelineLayer` implementation. `stopFor()` public for testability. Stops clamped to [0,1]. ✅
- **SolarMarkerLayer**: Clips correctly. Uses `TextPainter` for noon symbol. ✅
- **LunarMarkerLayer**: Phase silhouette via shadow-circle technique. Arrow paths correct. ✅
- **TimelinePainter wiring**: `useAstro = isAstroTheme && astroData != null` is a clean guard. Layer list uses spread for conditional insertion. `shouldRepaint` updated. ✅

### Test Coverage Review

- +52 tests from baseline (276 → 328)
- AstroSettings: equality + moonPhase fromFraction ✅
- AstroDataService: lifecycle, solar ordering, cache, location change ✅
- Painter layers: stop positions, x ordering, moon null handling ✅
- MoonPhaseBadge: render, tap, tooltip ✅
- SettingsPanel: location section visible/hidden, prompt, preview, city error, advanced ✅

### Final Gate

**APPROVED.** 328/328 green. Disposed guard fix applied. F-29 is ship-ready pending Oracle doc pass.

---

*Last updated: 2026-05-18*
