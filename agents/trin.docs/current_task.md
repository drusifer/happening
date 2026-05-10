# Current Task

## Session 2026-05-10 — Logger cleanup + EC redundancy suppression
**Status**: COMPLETE (293/293 green)
**Progress**: 100%

### Completed
- [x] Fixed `calendar_controller_test.dart` per-cal isolation test: added
      `await Future<void>.delayed(Duration.zero)` after `refresh()` to flush
      flutter_test's deferred broadcast-stream delivery microtask. Root cause:
      working-tree logger migration removed the trailing `await AppLogger.debug`
      that HEAD code accidentally used to flush the microtask queue.
- [x] Deleted `AppLogger` facade (`app/lib/core/util/logger.dart`). All files
      now use `package:logging/logging.dart` directly with per-class
      `static final _log = Logger('ClassName')`.
- [x] Removed `import '../../core/util/logger.dart'` from: `auth_service.dart`,
      `calendar_controller.dart`, `calendar_service.dart`, `app.dart`,
      `window_linux_e2e_test.dart`. Replaced `AppLogger.debug(...)` in
      `main.dart` with `_log.fine(...)` and direct `Logger.root` setup in
      `_setupLogging(Directory)`.
- [x] EC: replaced all `debugPrint('[EC] ...')` with `_log.fine(...)` using
      `static final _log = Logger('EC')`. Removed `import flutter/foundation`.
- [x] EC: added `_lastConfirmed` field; `send()` now skips execute when idle,
      no pending, and `intent == _lastConfirmed`. Fixes three redundant resize
      operations seen in the expand-collapse trace.
- [x] EC test: replaced "same state always executes — no skip" test with:
      - "idle same-state send is skipped — no redundant resize"
      - "different state after confirmed executes normally"
- [x] 293/293 green (was 292 before adding the two new EC tests).

### Pending (next session)
- [ ] `main.dart::_setupLogging`: replace `debugPrint(line)` in the
      `Logger.root.onRecord` handler with `dart:developer`'s `log()`.
      Cannot recurse through Logger — use `dev.log(r.message, time: r.time,
      level: r.level.value, name: r.loggerName)`.
- [ ] Manual Wayland smoke: expand/collapse with ExpansionController live.
