# Next Steps — UPDATED 2026-03-18

## IMMEDIATE
All Linux async bugs resolved. Manual UAT passed. Nothing blocking.

## BACKLOG (macOS build v0.2.1)
- @Neo *swe fix: `window_service.dart` — lazy init + `Platform.isWindows` guards. See MACOS_BUILD_PLAN.md T1.
- @Neo *swe fix: `Release.entitlements` — add `com.apple.security.network.server` for PKCE auth.
- @Neo *swe impl: Makefile — add `run-macos`, `dist-macos`, `integration-test-macos`, `dist-proxy-macos` targets.
- @Trin *qa smoke: macOS `run-macos` after Neo's fixes.
