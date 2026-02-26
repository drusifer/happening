# Neo Context

## Project: Happening (Flutter Desktop)
**Last active**: 2026-02-26 — shutdown for migration to desktop

## Platform
- Dev machine was: ARM64 Debian Trixie (Raspberry Pi 5)
- Flutter SDK: installed at `.flutter/flutter` (stable channel, git clone)
- `make setup` is idempotent — re-run on new machine to re-install Flutter

## Project Layout
```
happening/
  Makefile                  — setup/test/build/run (dep-checked)
  scripts/setup.sh          — clones Flutter stable to .flutter/
  app/                      — Flutter project root
    pubspec.yaml
    lib/
      main.dart
      app.dart              — HappeningApp (root StatefulWidget + mock events)
      core/time/clock_service.dart
      core/window/window_service.dart
      features/calendar/calendar_event.dart
      features/calendar/video_link_extractor.dart
      features/timeline/timeline_layout.dart
      features/timeline/timeline_strip.dart
      features/timeline/timeline_painter.dart
      features/timeline/now_indicator.dart
      features/timeline/event_block.dart
      features/timeline/countdown_display.dart
      features/timeline/celebration_widget.dart
    linux/                  — Linux desktop platform (from flutter create)
    test/                   — 44 tests, all GREEN
```

## Key Technical Decisions
- Stateless-first: StreamBuilder<DateTime> drives strip, single root StatefulWidget
- TimelineLayout: pure math, no Flutter imports — xForTime(time, [now])
- VideoLinkExtractor: static, priority chain (hangoutLink → conferenceData → location → description regex)
- CalendarEvent: equality by id, immutable, copyWith
- window_manager: always-on-top, frameless, 52px logical height
- Mock events in app.dart — replaced with real data in Sprint 2

## Test Status
- 44/44 GREEN
- Suites: ClockService(3), VideoLinkExtractor(9), CalendarEvent(8),
  TimelineLayout(10), CountdownDisplay(5), TimelineStrip(4)

## Sprint Status
- Sprint 1: COMPLETE (all code + tests)
- Sprint 2: NOT STARTED (Google Calendar auth + live events)
- Sprint 3: NOT STARTED (hover, platform polish, release)

## Known Issues / Blockers
- `libgtk-3-dev` not installable on Pi due to RPi `+rpt1` wayland pkg conflict
- `make run` blocked on this — needs GTK3 dev headers to build Linux runner
- On desktop (Ubuntu): `sudo apt install libgtk-3-dev` should just work
- waypipe already installed on Pi; display forwarding was the motivation

## Next Steps (Sprint 2)
- S2-01: VideoLinkExtractor already done ✅
- S2-02: CalendarEvent model already done ✅
- S2-03: AuthService — Google OAuth loopback redirect
- S2-04: TokenStore — flutter_secure_storage wrapper
- S2-05: CalendarService — Google Calendar API v3
- S2-06: EventRepository — cache + polling
- S2-07: Wire into HappeningApp root state
