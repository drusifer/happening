# Neo Next Steps — 2026-05-25

## All session work complete. 350/350 green.

## If picking up after /clear

1. **Verify tests still pass**: `make test` — should be 350/350.

2. **Run fetch-cities** (optional, for full dataset):
   ```
   make fetch-cities
   ```
   Replaces `app/assets/data/cities.csv` seed (170 cities) with full GeoNames ~25,000 city dataset.
   After running, commit the updated CSV.

3. **Oracle AST-E2 doc pass** (long-standing pending item):
   ```
   @Oracle *ora record "F-29 Astronomical Theme complete; lint sprint done; location/now-line work done. Ready for AST-E2 doc pass."
   ```

## Key files to know
- `app/lib/core/astro/city_search.dart` — city search logic (new this session)
- `app/assets/data/cities.csv` — bundled city database (format: name|country|lat|lng)
- `app/lib/features/timeline/settings_panel.dart` — location section: city search only, no Advanced UI
- `app/lib/features/timeline/timeline_strip.dart:540` — nowIndicatorX formula

## Architecture decisions made this session
- nowIndicatorX = `(leftToolbarRight(88) + 16 + fontSize*5.0 + 12).clamp(0, stripWidth*0.35)` — derived from button+countdown widget sizes, NOT a percentage of strip width
- City search: local asset only, no external APIs, no geolocator
- AstroSettings model: unchanged (still stores lat/lng/cityName — set by city search, read by astro engine)
