# Neo Context

## Project: Happening (Flutter Desktop)
**Last active**: 2026-02-26 — BUG-03 fix confirmed on Linux Desktop

## BUG-03: Fat Background / Window Height Fix
Fixed a critical window-height issue on Linux (XWayland).
1. **GTK Header Bar Override**: Linux's GNOME/GTK enforces a minimum height when a Header Bar is present. Added `gboolean use_header_bar = FALSE;` to `app/linux/runner/my_application.cc` to allow heights < 50px.
2. **DPR Math Conflict**: Corrected window-sizing math in `window_service.dart`. `window_manager` expects logical pixels, so we must divide physical screen dimensions (provided by `screen_retriever` on Linux) by the device pixel ratio (DPR).
3. **Window Constraints**: Maintained `minimumSize` and `maximumSize` locks to prevent the OS from snapping the window back to a default height (e.g. 720px).

## Project Layout
```
happening/
  Makefile                  — setup/test/build/run (dep-checked)
  scripts/setup.sh          — checks system deps
  app/                      — Flutter project root
    lib/
      main.dart
      app.dart
      core/time/clock_service.dart
      core/window/window_service.dart
    linux/                  — Linux desktop platform files
    test/                   — 44 tests, all GREEN
```

## Test Status
- 44/44 GREEN
- All Sprint 1 core components verified.

## Sprint Status
- Sprint 1: COMPLETE ✅ (Shell, Timeline Layout, Window Positioning)
- Sprint 2: READY (Google Calendar auth + live events)
- Sprint 3: READY (hover, platform release)
