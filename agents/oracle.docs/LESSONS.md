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

## [2026-03-16] X11 DOCK Type Must Be Set Before gtk_widget_show

> **Tags:** #Linux #X11 #WindowManager #Positioning #Neo

### Context
On startup the strip occasionally appeared too low with empty space above it. Restarting fixed it, indicating a race condition.

### The Issue
In `first_frame_cb`, `gtk_widget_show(toplevel)` was called before `set_x11_strut()`. The WM saw the window as a normal window type first and positioned it accordingly (e.g. below the desktop panel). Setting `_NET_WM_WINDOW_TYPE_DOCK` and `_NET_WM_STRUT_PARTIAL` after the window was already mapped didn't always trigger a reposition.

### The Solution
Swap the order: call `set_x11_strut()` before `gtk_widget_show()`. The toplevel is already realized (via `gtk_widget_realize` on the view), so `gtk_widget_get_window()` returns a valid GdkWindow. The WM sees the DOCK type from the first map event and never mispositions it.

### The Rule
**Set `_NET_WM_WINDOW_TYPE_DOCK` and `_NET_WM_STRUT_PARTIAL` before mapping the window.** A window's type hint must be applied before `gtk_widget_show` to guarantee the WM places it correctly from the start.

### References
- **Files:** `app/linux/runner/my_application.cc`

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

## [2026-03-03] Direct vs. Serialized Window Management (KISS Protocol)

> **Tags:** #Architecture #WindowManager #KISS #Morpheus

### Context
A complex asynchronous serialization queue was implemented in `WindowService` to prevent race conditions during rapid window resizing.

### The Issue
The serialization queue added significant architectural complexity and introduced state synchronization bugs where the window would get "stuck" if a platform call failed or if focus events fired in rapid succession. For low-frequency events like window resizing, the overhead was unjustified.

### The Solution
Reverted to a "KISS" approach: direct platform calls gated by simple boolean UI state checks. The `WindowService` became a stateless proxy for the platform, and the `TimelineStrip` became the sole arbiter of when to trigger a transition.

### The Rule
**Prefer direct, idempotent calls over complex serialization queues for low-frequency OS interactions.** Gating logic should live in the UI controller, not the service proxy, to ensure the physical window state always reflects the intended UI state.

### References
- **Files:** `app/lib/core/window/window_service.dart`, `app/lib/features/timeline/timeline_strip.dart`

---

## [2026-03-03] Context-Aware Hover Bounding (The Latch Logic)

> **Tags:** #UX #Hover #Collision #Neo

### Context
Users found it difficult to click action buttons on hover cards because moving the mouse horizontally toward a button would often trigger an adjacent overlapping event, causing the original card to vanish.

### The Issue
Standard 1D horizontal hit-testing is too sensitive for overlapping events. A single bounding box logic for both the strip and the card zone cannot satisfy both "precision navigation" and "stable interaction."

### The Solution
Implemented "Context-Aware Bounding Boxes":
1.  **Strip Zone**: Bounds match the exact event column width for precision selection.
2.  **Card Zone**: Bounds expand to the full width of the hover card.
3.  **The Latch**: The UI prioritizes the currently hovered event as long as the mouse remains within its (expanded) bounds, effectively "latching" the card open while the user moves toward buttons.

### The Rule
**Interaction bounds should adapt to the UI state.** Once a detail view is open, expand the "hit zone" to cover the entire interactive surface of that view to prevent focus-stealing from adjacent elements.

### References
- **Files:** `app/lib/features/timeline/timeline_strip.dart`, `app/lib/features/timeline/expansion_logic.dart`

---

## [2026-03-19] Windows ABM_SETPOS Mutates AppBarData Struct Fields

> **Tags:** #Windows #AppBar #Win32 #WindowManager #Neo

### Context
After collapse, the window was rendering at 140px wide instead of the full 3840px screen width.

### The Issue
`_reserveCollapsedSpace()` was being called twice: once at init (correct) and once on every `_doCollapse()` (wrong). On the second call, `ABM_SETPOS` had already mutated `rcLeft`/`rcRight` in the `_AppBarData` struct. Reading `rcLeft` (now ~3700) as the window X position placed the window at x=3700 with width=3840 — only 140px visible on a 3840-wide display.

### The Solution
Removed the redundant `_reserveCollapsedSpace()` call from `_doCollapse()`. AppBar reservation is a one-time init operation. `WindowsResizeStrategy.collapse()` correctly positions the window; there is no need to re-register with the AppBar system on every collapse.

### The Rule
**Call `SHAppBarMessage(ABM_SETPOS)` only once, at init.** After `ABM_SETPOS`, `rcLeft`/`rcRight` in the struct are unreliable — Windows adjusts them. Only `rcTop` is trustworthy post-SETPOS. Never re-invoke `_reserveCollapsedSpace` on state transitions.

### References
- **Files:** `app/lib/core/window/window_service.dart`

---

## [2026-03-19] Windows Expanded Window Area Must Be Transparent

> **Tags:** #Windows #Transparency #Flutter #UI #Neo

### Context
The expanded hover card window area appeared dark navy (light mode: white) behind and around the hover card on Windows.

### The Issue
The background `Container` in `TimelineStrip` filled the full expanded window height with `stripBackgroundColor` (opaque). On Linux, transparency isn't supported so this is correct. On Windows, DWM compositing supports per-pixel transparency — the expanded area outside the hover card should show the desktop.

### The Solution
Made the background container use `Colors.transparent` when `isExpanded && Platform.isWindows`. The strip painter and hover card each render their own opaque backgrounds, so no visual regression on the strip itself.

### The Rule
**On Windows, expanded window area below the hover card must be `Colors.transparent`.** Use `Platform.isWindows` to gate transparency. Linux keeps the opaque background since it doesn't support DWM-style transparency.

### References
- **Files:** `app/lib/features/timeline/timeline_strip.dart`

---

## [2026-03-03] Tiered UI Update Frequency for CPU Optimization

> **Tags:** #Performance #Flutter #CPU #Neo

### Context
The application was consuming 10-15% of a CPU core while idle, primarily due to full timeline repaints occurring 1-5 times per second.

### The Issue
1.  **Cascading Repaints**: High-frequency animation updates (5Hz) were triggering sibling repaints of the entire 3000px timeline canvas.
2.  **Over-driven Layout**: The heavy `TimelinePainter` was recalculating and redrawing everything at 1Hz, even when only the countdown text needed to change.

### The Solution
1.  **Repaint Isolation**: Wrapped the `CustomPaint` in a `RepaintBoundary` to decouple it from animation updates.
2.  **Tiered Clock Streams**: Updated `ClockService` to provide `tick1s` (for precise countdowns) and `tick10s` (for coarse timeline updates).
3.  **Conditional Animation**: Modified the animation timer to only run when an event is within a "critical" 2-minute window.

### The Rule
**Deactivate high-frequency timers when idle and isolate heavy painters behind a `RepaintBoundary`.** Use tiered update frequencies to match the precision requirements of different UI elements (e.g., 1s for text, 10s for backgrounds).

### References
- **Files:** `app/lib/core/time/clock_service.dart`, `app/lib/features/timeline/timeline_strip.dart`, `app/lib/features/timeline/timeline_painter.dart`

---

## [2026-03-23] GTK Window Expand: setMaximumSize First, Then setMinimumSize

> **Tags:** #Linux #GTK #WindowManager #Resize #Morpheus

### Context
Linux expand was flaky — "all black" or "no cards" on hover. Both symptoms caused by `isExpandedNotifier=true` while GTK never actually grew the window.

### The Issue
`LinuxResizeStrategy.expand()` used the order: `setSize → setMinimumSize → setMaximumSize`. This creates a `min > max` invalid constraint which GTK resolves unpredictably (compositor-dependent). Sometimes it grows the window, sometimes it clamps min to max and stays collapsed.

### The Solution
Swap to: `setMaximumSize(target) → setMinimumSize(target)`. This works because:
1. `setMaximumSize(target)`: lifts cap, constraints valid (`min < max`), window stays put
2. `setMinimumSize(target)`: raises floor to `min = max = target`, with `window < min` — **GTK must grow** (well-defined standard behavior, not compositor-dependent)

Drop the `setSize` advisory call — it is ignored when max-cap is still in place.

### The Rule
**On Linux GTK, expand via `setMaximumSize(target)` then `setMinimumSize(target)`.** The reliable forcing mechanism is GTK's guarantee that `window_size >= min_size`, NOT the `min > max` invalid constraint trick (which is unpredictable across compositor versions). Collapse order (setSize → setMinimumSize → setMaximumSize) remains correct.

### References
- **Files:** `app/lib/core/window/resize_strategy/linux_resize_strategy.dart`

