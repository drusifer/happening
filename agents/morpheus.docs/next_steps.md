# Next Steps — UPDATED 2026-03-18

## IMMEDIATE (next session)

1. **ARCH-002: Fix LinuxResizeStrategy.expand() order**
   - Hand to Neo: `@Neo *swe fix ARCH-002`
   - Must use: `setSize(target) → setMinimumSize(target) → setMaximumSize(target)`
   - Reason: min>max conflict forces GTK to grow. Current max-first order removes the force.
   - Also check: `onExpanded()` timing — should it fire AFTER all resize ops + async yield?
   - Update `window_resize_strategy_test.dart` expand order test
   - Update `window_linux_e2e_test.dart` expand E2E test

2. **Trin manual verify** after Neo's fix — hover card visible, no black screen

## BACKLOG (macOS build v0.2.1)
- @Neo *swe fix: window_service.dart — lazy init + Platform.isWindows guards. See MACOS_BUILD_PLAN.md T1.
- @Neo *swe fix: Release.entitlements — add com.apple.security.network.server for PKCE auth.
- @Neo *swe impl: Makefile — add run-macos, dist-macos, integration-test-macos, dist-proxy-macos targets.
- @Trin *qa smoke: macOS run-macos after Neo's fixes.
