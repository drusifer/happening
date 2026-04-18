# Next Steps — UPDATED 2026-04-17

## IMMEDIATE
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
