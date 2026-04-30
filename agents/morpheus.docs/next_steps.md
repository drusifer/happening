# Next Steps — UPDATED 2026-04-25

## IMMEDIATE
- Morpheus is initialized and loaded.
- Transparent Timestrip Phases A, B, and C are approved.
- Neo has since reconciled Phase D/F artifacts and reported:
  - `make format` PASS
  - `make test` PASS 289/289
  - `make build-linux` PASS
  - TT-D1/D2/D3/E1/F1/F2 closed in `task.md`
  - `make analyze` initially blocked by Flutter server file handles, then later PASSED with no issues found.
- Next lead action, if user asks to continue: review Phase D/F implementation scope and either approve or hand to Trin for final verification.
- New lead recommendation from Linux/Wayland review:
  - Prefer Linux transparent/non-reserving behavior over maintaining native reserved-space panel code.
  - Do not attempt a Dart-only replacement for Wayland exclusive zones; `window_manager` does not provide that shell-reservation primitive.
  - If approved, assign Neo a small spike:
    1. Remove X11 strut/native reserved-space logic from Linux runner and CMake.
    2. Preserve minimal transparent window startup.
    3. Update Linux availability/settings gates.
    4. Run `make test`, `make analyze`, `make build-linux`.
    5. Require manual Linux X11/Wayland UAT before exposing Linux transparent mode broadly.
- Linux Wayland Simplification sprint is now planned and approved.
- Phase A is complete and approved.
- Next command: `@Neo *swe impl LWS Phase B`.
- Phase B/C are complete and approved.
- Phase D is approved for X11/XWayland Linux behavior.
- Phase D scope:
  - automated regression: `make format`, `make test`, `make analyze`, `make build-linux`.
  - real-session UAT: execute or explicitly block X11/XWayland and Wayland smoke matrix before claiming Linux transparent support.
- Current outcome:
  - code/docs complete.
  - `make format`, `make test`, and `make build-linux` pass.
  - user reports host-side `make analyze` clean; Codex sandbox analyze remains environment-limited by inotify cap.
  - X11/XWayland selected and forced for `make run-linux`.
  - native Wayland and Linux transparent support are not claimed.

## PREVIOUS IMMEDIATE
- Calendar fetch threading implementation/review is complete and approved for scope.
- Remaining test-suite blocker is unrelated: window binding initialization failures in window tests.
- Recommended next engineering task: fix window test binding setup so full `make -f Makefile.prj test` can go green.

## LINUX
Linux async bugs mostly resolved, but user is actively testing freeze/hover paths. Keep debug log based diagnosis tight.

## BACKLOG (macOS build v0.2.1)
- @Neo *swe fix: `window_service.dart` — lazy init + `Platform.isWindows` guards. See MACOS_BUILD_PLAN.md T1.
- @Neo *swe fix: `Release.entitlements` — add `com.apple.security.network.server` for PKCE auth.
- @Neo *swe impl: Makefile — add `run-macos`, `dist-macos`, `integration-test-macos`, `dist-proxy-macos` targets.
- @Trin *qa smoke: macOS `run-macos` after Neo's fixes.
