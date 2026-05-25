# Neo Next Steps — 2026-05-25

## All session work complete. Tests green.

## If picking up after /clear

1. **Verify tests still pass**: `make test` — should be green.

2. **Run fetch-cities** (optional, for full dataset):
   ```
   make fetch-cities
   ```
   Replaces `app/assets/data/cities.csv` seed (170 cities) with full GeoNames ~25,000 city dataset.

3. **Oracle AST-E2 doc pass** (long-standing pending item):
   ```
   @Oracle *ora record "Astro theme sprint complete + UX polish. Ready for AST-E2 doc pass."
   ```

## Key fixes done this session (for reference)

### Lunar body test timezone fix
- Two tests ("fade-in has nightNavy", "fade-out ends at nightNavy") were failing because
  `getSolarTimes` returns UTC DateTimes but tests used local `DateTime(2026, 5, 18, 12, 0, 0)`.
- Fix: test 1 uses `testNow = solarTimes.solarNoon`; test 2 uses `testNow = nightRise`.
- Both build a `layoutLocal` from their `testNow` so window covers the post-dusk events.

### Events z-order above tick lines
- In `timeline_painter.dart`, swapped `TickLayer` before `EventsLayer` in the layers list.
- Golden regenerated with `make test ARGS="--update-goldens"`.

### Version bump
- `app/lib/core/app_metadata.dart`: `appVersion = '0.5.1'` (was '0.4.0').
- `pubspec.yaml` already had 0.5.1 — app_metadata.dart must be kept in sync manually.

## Key files to know
- `app/lib/core/app_metadata.dart` — hardcoded appVersion shown in settings panel
- `app/lib/core/astro/city_search.dart` — local city search (GeoNames asset)
- `app/assets/data/cities.csv` — bundled city database (format: name|country|lat|lng)
- `app/lib/features/timeline/timeline_painter.dart` — layer paint order
