# Neo Current Task — 2026-05-25

## Status: ALL COMPLETE

## Completed this session
- [x] Now-line DPI/font scaling fix (nowIndicatorX formula based on button + countdown size)
- [x] Geolocator package removed entirely
- [x] City search implemented using local GeoNames asset (no network calls)
- [x] fetch-cities Makefile target added
- [x] Advanced lat/lng UI removed from settings panel
- [x] 350/350 tests green

## Pending (not blocking /clear)
- [ ] User to run `make fetch-cities` for full 25k-city dataset (seed file with 170 cities committed)
- [ ] Oracle AST-E2 doc pass (carried over from previous sprint)

## Files changed this session
- app/lib/features/timeline/timeline_strip.dart — now indicator formula
- app/lib/features/timeline/settings_panel.dart — removed geolocator, Advanced UI; wired city search
- app/lib/core/astro/city_search.dart — NEW: local city search (GeoNames asset)
- app/assets/data/cities.csv — NEW: seed city database (~170 cities)
- app/pubspec.yaml — removed geolocator, added assets/data/
- app/pubspec.lock — 6 geolocator packages removed
- Makefile — fetch-cities target + setup dependency
- app/test/features/timeline/timeline_strip_test.dart — hover x updated 140→260
- app/test/features/timeline/settings_panel_test.dart — 2 Advanced section tests deleted
- app/test/goldens/goldens/hover_card_alignment.png — regenerated (now line moved)
