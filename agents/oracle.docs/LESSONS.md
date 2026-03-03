# Lessons Learned — Happening Project

---

## [2026-02-27] Flutter Snap Hijacks LLVM PATH — Cannot Be Fixed With PATH Override

> **Tags:** #Build #Linux #Flutter #LLVM #Neo

### Context
Sprint 2 Linux build via `make run` failed immediately after adding `flutter_secure_storage`.

### The Issue
Flutter snap's `env.sh` unconditionally prepends `/snap/flutter/150/usr/bin` to `$PATH` at startup. `flutter_tools` runs `which clang++`, resolves symlinks, then looks for `ld.lld` in the *same directory* as the resolved binary — which ends up being `/snap/flutter/150/usr/lib/llvm-10/bin/` (no linker there). Prepending system LLVM 20 to PATH in the Makefile has no effect because the snap re-prepends its own dirs first.

### The Solution
Removed the Flutter snap entirely (`sudo snap remove flutter`) and reinstalled via `git clone https://github.com/flutter/flutter.git -b stable ~/flutter`. For ARM64 (aarch64/Snapdragon X1E) there is no pre-built tarball — git clone is the correct install method.

### The Rule
**NEVER install Flutter via snap on Linux for desktop development.** Use git clone from the stable branch. The snap bundles LLVM 10 without a linker and its PATH injection cannot be overridden.

### References
- **Commit:** N/A (build system fix)
- **Files:** `Makefile`

---

## [2026-02-27] google_sign_in Has No Linux Desktop Implementation

> **Tags:** #Auth #Linux #Flutter #GoogleSignIn #Neo

### Context
After switching from snap to git Flutter, `make run` succeeded but clicking the sign-in strip threw `MissingPluginException` for `google_sign_in`.

### The Issue
The `google_sign_in` package supports Android, iOS, and Web only. It has no platform channel implementation for Linux desktop. The exception fires at runtime on first use.

### The Solution
Replaced `google_sign_in` (and `extension_google_sign_in_as_googleapis_auth`) with `googleapis_auth: ^2.0.0` + `url_launcher: ^6.2.0`. Used `clientViaUserConsent()` which starts a local loopback HTTP server, opens the browser for consent, and captures the auth code automatically.

### The Rule
**NEVER use `google_sign_in` for Linux desktop.** Use `googleapis_auth`'s `clientViaUserConsent` (loopback redirect flow) instead. Store client credentials in `assets/client_secret.json` (gitignored).

### References
- **Commit:** N/A (Sprint 2 auth refactor)
- **Files:** `app/lib/app.dart`, `app/pubspec.yaml`

---

## [2026-02-27] flutter_secure_storage_linux Bundles Old nlohmann/json — Breaks LLVM 20

> **Tags:** #Build #Linux #LLVM #Dependencies #Neo

### Context
After reinstalling Flutter from git, build failed with `-Werror,-Wdeprecated-literal-operator` inside `json.hpp`.

### The Issue
`flutter_secure_storage_linux 1.2.3` bundles an old version of nlohmann/json that uses the deprecated C++ literal operator syntax (`_json`). LLVM 20 compiles with `-Werror` and rejects it.

### The Solution
Removed `flutter_secure_storage` from `pubspec.yaml` entirely. The `TokenStore` abstract class stays (for future use); the concrete `FlutterSecureTokenStore` implementation was removed. Token persistence deferred to Sprint 3.

### The Rule
**Do NOT add `flutter_secure_storage` until upstream ships a version with json.hpp compatible with LLVM 20.** Track as S3-token. Use in-memory or file-based token storage as a temporary workaround.

### References
- **Commit:** N/A
- **Files:** `app/pubspec.yaml`, `app/lib/features/auth/token_store.dart`

---

## [2026-02-27] Window Height: Use Logical Pixels, Not `30.0 / dpr`

> **Tags:** #WindowManager #Linux #GTK #DPI #Neo

### Context
After reinstalling Flutter (snap → git), the window height was too tall again despite the BUG-03 fix (`30.0 / dpr`).

### The Issue
The BUG-03 fix assumed window_manager required physical pixels and pre-divided by DPR. With non-snap Flutter + proper GTK integration, `window_manager` takes **logical pixels** and GTK applies the system scale factor internally. Passing `30.0 / dpr` double-compensates and produces a window that is too short or too tall depending on the scale factor.

### The Solution
Changed `logicalHeight = 30.0 / dpr` → `logicalHeight = _kStripHeightLogical` (30.0). Let window_manager + GTK handle DPI.

### The Rule
**On Linux, `window_manager.setSize()` takes logical pixels.** Do not pre-divide by DPR. GTK applies the system scale factor automatically. The DPR division was a workaround for snap Flutter's broken GTK integration.

### References
- **Commit:** N/A (post-Sprint 2 fix)
- **Files:** `app/lib/core/window/window_service.dart`

---

## [2026-02-27] X11 Strut Requires Explicit libX11 Link in Runner CMakeLists

> **Tags:** #Build #Linux #X11 #CMake #Neo

### Context
Added `_NET_WM_STRUT_PARTIAL` hint to `my_application.cc` using `XInternAtom` / `XChangeProperty`. Build failed with: `libX11.so.6: error adding symbols: DSO missing from command line`.

### The Issue
GTK links X11 transitively but the linker (clang++ on arm64) requires all DSOs used directly to be listed explicitly. Using Xlib symbols without declaring the dependency causes a linker error even though `libX11.so` is present on the system.

### The Solution
Added `target_link_libraries(${BINARY_NAME} PRIVATE X11)` to `app/linux/runner/CMakeLists.txt`.

### The Rule
**Any direct use of Xlib symbols (`XInternAtom`, `XChangeProperty`, etc.) requires `target_link_libraries(... PRIVATE X11)` in the runner's CMakeLists.** Do not rely on GTK's transitive X11 dependency.

### References
- **Files:** `app/linux/runner/CMakeLists.txt`, `app/linux/runner/my_application.cc`

---

## [2026-02-27] Google OAuth Test Users Required for Unverified Apps

> **Tags:** #Auth #GoogleOAuth #Setup #Drew

### Context
After successfully opening the Google consent screen, sign-in was blocked with "Access blocked: Happening has not completed the Google verification process."

### The Issue
OAuth apps in "External" testing mode can only be used by accounts explicitly listed as Test Users in the Google Cloud Console OAuth consent screen.

### The Solution
In Google Cloud Console → APIs & Services → OAuth consent screen → Test users → Add Gmail address of the user.

### The Rule
**Add test user emails in Cloud Console before testing OAuth.** Unverified apps require explicit test user allowlisting. No app changes needed — this is a Cloud Console configuration step.

### References
- **Commit:** N/A
- **Files:** `assets/client_secret.json` (gitignored)

---

## [2026-03-02] Hover Interaction & Service Architecture (Sprint 5 Refinement)

> **Tags:** #Architecture #UX #Testing #State #Morpheus #Neo

### Context
Coordination between event hit-testing, mouse coordinates, and window expansion state was prone to race conditions and inconsistent behavior across font sizes.

### The Issue
1.  Global/Static state in `WindowService` made testing difficult and caused state bleed.
2.  Ad-hoc expansion overrides in `TimelineStrip` (e.g., forcing expansion for icons) led to unexpected window resizing.
3.  Expansion thresholds were hardcoded and didn't scale with font size.

### The Solution
1.  **Avoid Globals/Statics**: Refactored `WindowService` to be instance-based and injected via constructor.
2.  **Pure State Determination**: Created `ExpansionLogic` as a stateless pure function of coordinates and 2D `EventBounds`.
3.  **Expansion Column Rule**: The window only expands when the mouse is within an event's horizontal bounds or settings are open. Icons (Gear/Refresh) are in the collapsed area and don't need expansion.
4.  **Calculated Thresholds**: All heights are derived from `settings.fontSize.px` using a central `_updateHeights()` helper.

### The Rule
**Window state must be a deterministic function of inputs.** Services must be instance-based. Interactive elements in the collapsed area must not trigger window expansion unless they represent an event hit or settings override.

### References
- **Decisions:** `DEC-003`
- **Files:** `app/lib/features/timeline/expansion_logic.dart`, `app/lib/core/window/window_service.dart`, `app/lib/features/timeline/timeline_strip.dart`
