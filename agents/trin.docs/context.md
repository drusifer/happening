# Trin Context

## Session 2026-05-10 — Logger + EC redundancy

### AppLogger deletion
- `AppLogger` facade deleted entirely. Per-class `Logger('ClassName')` pattern
  is now the only approach used project-wide.
- `Logger.root` configured once in `main.dart::_setupLogging(Directory)`:
  level (FINE in debug, INFO in release), console via `debugPrint` (still needs
  replacement with `dart:developer`), file append for INFO+.
- `app/lib/core/util/logger.dart` no longer exists.

### EC redundancy suppression
- Added `_lastConfirmed: ExpansionState?` field.
- `send()` returns early (no execute, no log) if
  `!_processing && _pending == null && intent == _lastConfirmed`.
- `_lastConfirmed` is set at the end of `_execute()` before emitting to stream.
- Fixes three log-observed problems:
  1. Collapse on first mouse event when already at collapsed height.
  2. Re-expand when mouse hovers and window already at 340px.
  3. Double-collapse cascade: EC done → stream emit → strip rebuild → re-sends
     collapsed → second full collapse.
- The old "GTK always-executes" guarantee is intentionally removed; the first
  send after a fresh start (or after a future `_lastConfirmed` reset) still
  executes normally.

### flutter_test stream timing lesson
- `flutter_test` zone defers broadcast-stream listener callbacks as microtasks
  rather than delivering them synchronously inside `add()`.
- Tests that call `await controller.refresh()` and then immediately check
  stream emissions need one extra `await Future<void>.delayed(Duration.zero)`
  to flush the delivery microtask.

## Transparent Timestrip Phase C UAT — 2026-04-24
- (unchanged from prior context — see earlier entries for full detail)

## Linux Wayland Simplification Phase D Gate — 2026-04-25
- Automated checks all pass; host-side `make analyze` clean; Codex sandbox
  analyze blocked by inotify watcher cap.
- X11/XWayland selected as Linux backend; native Wayland not claimed.
- Linux transparent support not claimed; remains hidden until validated.

## QA Decisions
- Every bug fix MUST have an empirical reproduction test.
- Broadcast stream tests that check emissions after an awaited async call need
  `await Future<void>.delayed(Duration.zero)` to flush the delivery microtask
  in the flutter_test zone.
