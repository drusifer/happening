# Current Task

## TDD Sprint 1 — Pure-Dart Components
**Status**: RED+GREEN written, awaiting `make test` to confirm GREEN

### Done
- [x] Makefile (setup/test/build/run/clean/format/analyze/help)
- [x] scripts/setup.sh (Flutter git clone, ARM64-safe, idempotent)
- [x] app/pubspec.yaml
- [x] app/analysis_options.yaml
- [x] .gitignore updated (.flutter/ ignored, *.lock exception noted)
- [x] TDD RED: clock_service_test.dart
- [x] TDD RED: video_link_extractor_test.dart (9 tests)
- [x] TDD RED: calendar_event_test.dart (8 tests)
- [x] TDD RED: timeline_layout_test.dart (10 tests)
- [x] TDD GREEN: ClockService
- [x] TDD GREEN: VideoLinkExtractor
- [x] TDD GREEN: CalendarEvent
- [x] TDD GREEN: TimelineLayout

### Sprint 1 — ALL CODE COMPLETE ✅ 44/44 tests GREEN
- [x] main.dart + app.dart (HappeningApp with mock events)
- [x] WindowService (always-on-top, frameless, 52px logical)
- [x] TimelineStrip (StatelessWidget + StreamBuilder)
- [x] TimelinePainter (CustomPainter, proportional layout)
- [x] NowIndicator, EventBlock, CountdownDisplay, CelebrationWidget
- [x] Widget tests: countdown_display_test (5), timeline_strip_test (4)
- [x] Makefile dep-checking: pub get skips unless pubspec changes
- [x] `make test` → 44/44 GREEN

### Awaiting
- `make run` smoke test (needs display — Drew or Trin)
