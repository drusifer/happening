# macOS Build Plan — v0.2.1

**Owner:** Morpheus
**Date:** 2026-03-07
**Target:** Distribute a working macOS .app bundle for Happening

---

## Blocker Analysis

### BLOCKER-1 (Critical): `window_service.dart` — Windows-only FFI at top level

`app/lib/core/window/window_service.dart` has top-level Windows FFI code that crashes on macOS:

```dart
// These execute at MODULE LOAD TIME — crash on macOS:
import 'package:win32/win32.dart' hide Size;
final _shAppBarMessage = DynamicLibrary.open('shell32.dll')
    .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');
```

**Fix:** Extract a `WindowService` interface + platform-specific implementations:
- `window_service.dart` → abstract interface
- `window_service_windows.dart` → Windows (AppBar + win32 FFI)
- `window_service_posix.dart` → Linux + macOS (window_manager only)

Use conditional imports:
```dart
// window_service.dart
export 'window_service_stub.dart'
    if (dart.library.io) 'window_service_io.dart';
```

Or simpler: use `Platform.isWindows` guards and lazy initialization (no top-level FFI).

**Simplest approach:** Move `_shAppBarMessage` lookup inside `_registerAppBar()` and wrap in `Platform.isWindows` guard. The `win32` package can still be imported — it just won't be called on macOS. Verify `win32` pubspec supports macOS targets first.

### BLOCKER-2: `win32` package — platform support

Check `pubspec.yaml` to confirm `win32` is not restricted to Windows platform. If it is, need platform-conditional imports.

---

## Task Breakdown

### T1 — Fix window_service.dart for macOS (Neo)
- Move `_shAppBarMessage` lookup inside `_registerAppBar()` (lazy, not top-level)
- Wrap all `DynamicLibrary.open('shell32.dll')` calls inside `Platform.isWindows` guards
- Verify `win32` import compiles on macOS (or use conditional import to exclude it)
- macOS window positioning: use `_wm.setPosition(Offset.zero)` (same as Linux — already in else-branch of `_registerAppBar`)
- macOS-specific: may need `NSPanel` level for "always on top above menubar" — investigate via `window_manager` docs

### T2 — Makefile targets (Neo)
Add to Makefile:
```makefile
run-macos: $(PUB_STAMP)
    cd $(APP_DIR) && $(FLUTTER) run -d macos

integration-test-macos: $(PUB_STAMP)
    cd $(APP_DIR) && $(FLUTTER) test integration_test/ -d macos

dist-macos: build-macos
    @mkdir -p $(DIST_DIR)
    cp -r $(APP_DIR)/build/macos/Build/Products/Release/happening.app \
        $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).app
    # Optional: create dmg
    # hdiutil create -volname "Happening" -srcfolder $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).app \
    #     -ov -format UDZO $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).dmg
    @echo "macOS package: $(DIST_DIR)/happening-$(VERSION)-macos-$(ARCH).app"

dist-proxy-macos:
    @mkdir -p $(DIST_DIR)
    dart compile exe $(PROXY_DIR)/bin/server.dart \
        -o $(DIST_DIR)/happening-proxy-$(VERSION)-macos-$(ARCH)
    @echo "Proxy binary: $(DIST_DIR)/happening-proxy-$(VERSION)-macos-$(ARCH)"
```
Update `help` target to document new targets.

### T3 — Smoke test (Trin)
1. `make run-macos` — app launches, strip appears at top of screen
2. Auth flow: sign-in opens browser, redirects back, token persists
3. Calendar events render on timeline strip
4. Hover expand/collapse works
5. Settings panel opens/closes
6. `make dist-macos` — .app bundle created in dist/

### T4 — macOS-specific window behaviour (Neo, if needed)
macOS "always on top" level needs to be above the menu bar for a proper top-strip experience.
`window_manager` exposes `setLevel(kCGFloatingWindowLevel)` via `setAlwaysOnTop`.
May need to set `NSWindowLevel` to `NSStatusWindowLevel` or higher — investigate after T3 smoke test.

### T5 — Update docs (Oracle)
- Update README.md: add macOS section to Prerequisites and Running
- Update USER_GUIDE.md: macOS screenshots
- Update docs/ARCH.md: platform support matrix

---

## Acceptance Criteria

- [ ] `make build-macos` succeeds on macOS hardware
- [ ] App runs: strip at top, always-on-top, transparent background
- [ ] Auth flow completes end-to-end (PKCE + proxy)
- [ ] All 185+ unit/widget tests pass (no regressions)
- [ ] `make dist-macos` produces distributable .app

---

## Unknowns / Risks

1. `win32` package — does it compile on macOS? Check pubspec platform restrictions.
2. macOS AppKit `NSWindowLevel` — `window_manager` may not expose the right level for a menubar-style strip. May need a macOS plugin or Swift native code.
3. Code signing — required for Notarization (distribution). Out of scope for v0.2.1 smoke test; document as v0.3.0 item.
4. macOS sandbox + localhost — sandbox allows `network.client` but NOT `network.server`. The PKCE auth flow binds `HttpServer.bind('localhost', 0)` — this requires `com.apple.security.network.server` in entitlements. **Check DebugProfile.entitlements**: it has `network.server=true` for debug. **Release.entitlements does NOT have network.server** — this will break auth in release builds. MUST fix Release.entitlements.

---

## Sequencing

```
T1 (Neo: fix window_service) → T2 (Neo: Makefile) → T3 (Trin: smoke test) → T4 (Neo: if issues) → T5 (Oracle: docs)
```

Start with T1 + T2 in parallel.
