# macOS Impeller Resize Crash — Summary (2026-10-02)

## Symptom
`make run-macos` → strip crashed ("Lost connection to device") while hovering
expand/collapse. Last logs: `texture and its descriptor disagree about its size`,
`Store action needs resolve but no valid resolve texture specified`.

## Root cause (engine, not app code)
Crash report `~/Library/Logs/DiagnosticReports/happening-2026-10-02-133155.ips`:
SIGSEGV null deref on `io.flutter.raster` in `impeller::Canvas::SetupRenderPass()`
via `EmbedderExternalViewEmbedder::SubmitFlutterView`. Known Flutter 3.47.x macOS
bug: an A→B→A window-size pattern makes `FlutterBackBufferCache` return a
wrong-size surface; Impeller invalidates the texture then dereferences it.
Upstream fix: flutter/flutter#192522 (open, unmerged as of 2026-10-02); dup
reports #192829 / #185394. A null check can't be added from app code (prebuilt
`FlutterMacOS.framework`, raster thread).

## Changes
1. `app/macos/Runner/Info.plist`: `FLTEnableImpeller = false` (Skia fallback).
   Remove once a Flutter release ships #192522.
2. `StripController.collapseFromHover()` + `hoverCollapseDelay` (250ms default):
   hover-driven expanded→collapsed waits the grace period; any other transition
   (expand, explicit collapse, hide/show) cancels it. Repeated hover calls don't
   restart the timer. Non-expanded state → behaves like `collapse()`.
   Logs showed collapse→expand flaps 30–170ms apart, i.e. the A→B→A trigger.
3. `TimelineStrip._handleMouse` uses `collapseFromHover()` (one-line change).
   Settings close / lifecycle / hide paths keep immediate `collapse()`.

## Verification
- `strip_controller_test.dart`: 11/11 green (5 new `collapseFromHover` tests).
- `dart analyze` on touched files: clean.
- Not yet verified manually on macOS (Skia transparency + hover feel).

## Pre-existing, not touched
- `test/features/timeline/timeline_strip_test.dart` fails to load:
  `_FakeAudioService extends CountdownAudioService` → `extends_non_class`
  (line ~1134). Present before this change (confirmed via stash).
- `lint-format` reports unformatted files (incl. countdown code in
  `timeline_strip.dart`, `countdown_display_test.dart`) from F-32.
