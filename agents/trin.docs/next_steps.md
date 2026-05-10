# Next Steps

## Immediate (next session)
- [ ] Replace `debugPrint(line)` in `main.dart::_setupLogging` Logger.root handler
      with `dart:developer`'s `log()`:
      ```dart
      import 'dart:developer' as dev;
      // inside onRecord.listen:
      dev.log(r.message, time: r.time, level: r.level.value, name: r.loggerName,
              error: r.error, stackTrace: r.stackTrace);
      ```
      File writing (Level.INFO+) stays as-is.
- [ ] Run `make test` after that change to confirm 293/293 still green.

## Ongoing
- [ ] Manual Wayland smoke: expand/collapse with ExpansionController live;
      verify the three redundant resize operations are gone from the log.
- [ ] Later platform QA: manual macOS/Windows transparent-mode smoke.
