# Next Steps

- [x] DIAGNOSED: buttons-disappear-after-sleep bug → WindowService._onDisplayChanged() zero-width race. Handed to Neo.
- [ ] Trin: After Neo fixes WindowService, re-run `make -f Makefile.prj test` and verify no regressions.
- [ ] Morpheus: Review calendar fetch threading implementation for architecture compliance.
- [ ] Neo/Trin later: Fix unrelated window binding tests so full suite can be green.
- [ ] Neo: Implement Morpheus calendar fetch threading architecture:
  - Replace `Future.wait` in `CalendarController._fetchOnce()` with sequential per-calendar queue processing.
  - Keep `_inFlightFetch != null` guard and return the active Future for overlapping refreshes.
  - Do not add queued follow-up state or a `while (true)` drain loop.
  - Update stale overlapping refresh test to expect one fetch.
  - Add selected-calendar queue-order test.
- [ ] Trin: Re-run `make -f Makefile.prj test` after Neo implementation.
- [ ] Trin: If full suite remains red only from window binding tests, file that as separate blocker and run focused calendar verification as secondary evidence.
- [ ] Trin: Final full regression suite run for v0.2.0 (all unit + integration + golden).
- [ ] Trin: Verification of Group F (macOS) once Neo is done.
- [ ] Mouse: Prepare for v0.2.0 release.
