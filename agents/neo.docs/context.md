# Linux Click-Through XWayland Only — 2026-05-05T22:10
- User clarified XWayland is the only Linux path that should be supported for click-through and asked to remove logic for other Linux variants.
- Capability is now explicitly XWayland-only:
  - `ClickThroughCapability.detect()` requires `displayServer == 'xwayland'`.
  - Native support boolean is still checked, but only after the backend matches XWayland.
- Renamed channel method from `isLayerShellAvailable()` to `isClickThroughAvailable()` to remove misleading Wayland/layer-shell semantics.
- Native `click_through_plugin.cc` now returns true only when `detect_backend()` reports `xwayland`; pure X11 and native Wayland return false.
- Updated tests:
  - X11 rejected even with fake native support.
  - XWayland accepted with fake native support.
  - Wayland rejected even with fake native support.
- Validation:
  - `make format` passed.
  - `make test FILE=test/core/linux/click_through_capability_test.dart` passed 4/4.
  - `make test` passed 304/304.
  - `make build-linux` passed.

# Linux Click-Through Capability + Makefile Test Target — 2026-05-05T20:38
- User clarified that X11 click-through works and asked to remove the env var gate and Wayland-only restriction.
- Removed `LINUX_TRANSPARENT` / `HAPPENING_LINUX_TRANSPARENT` from `Makefile run-linux`.
- `ClickThroughCapability.detect()` now uses the native channel support boolean for every display backend, preserving the logged backend string but not rejecting X11/XWayland.
- Native Linux plugin now returns support for `x11` and `xwayland` because it implements click-through with GDK input-shape there; Wayland still depends on `LAYER_SHELL_AVAILABLE`.
- Added `app/test/core/linux/click_through_capability_test.dart` covering X11, XWayland, and unsupported results.
- User noticed `make test FILE=...` was ignored; fixed Makefile outer mkf forwarding and inner Flutter test recipe:
  - `FILE` and `ARGS` are passed through mkf into the recursive make.
  - `test` and `test-watch` append `$(FILE) $(ARGS)` to `flutter test`.
- Validation:
  - `make format` passed.
  - `make test FILE=test/core/linux/click_through_capability_test.dart` ran only that file and passed.
  - `make test` passed 303/303.
  - `make build-linux` passed.

# Window Behavior Checkbox Layout — 2026-05-05T20:32
- User requested the settings panel window behavior control be horizontal and checkbox-based to save real estate.
- VIA was attempted but returned no symbols because the project area is Dart; used `rg` and direct file reads instead.
- Replaced the visible two-option `WindowMode` picker in `SettingsPanel` with `_WindowBehaviorCheckbox`.
- Semantics:
  - checked means `WindowMode.transparent` / clicks pass through;
  - unchecked means `WindowMode.reserved`;
  - disabled when both modes are not available.
- Removed the visible `Reserve space at top` option and Linux unsupported explanatory paragraph from the compact settings panel.
- Validation: `make format`, `make test` 300/300, and `make build-linux` passed.

# Expanded Settings Room — 2026-05-05T20:27
- User requested more room in the expanded section after settings controls became taller.
- Increased expanded window heights in `WindowService.getExpandedHeight()`:
  - small 300
  - medium 320
  - large 340
- Updated the medium expanded size test to expect `Size(1920, 320)`.
- Updated app test fake and standalone demo constants to `320`.
- Validation: `make format`, `make test`, and `make build-linux` passed.

# Refresh Fresh-Collapsed Recovery — 2026-05-05T20:22
- User reported the expanded area worked for a while then reverted to black, suggesting state that gets set and stuck.
- Implemented refresh as a recovery/reset path, not just data reload:
  - `TimelineStrip._resetToFreshCollapsedState()` clears hover/settings/focus-indicator/layout-related state and re-syncs interaction hold.
  - `WindowService.resetToFreshCollapsedState()` clears desired expansion (`_wantsExpanded=false`), clears rendered expansion (`isExpandedNotifier=false`), then runs a gated physical collapse.
- Added count/boolean-only diagnostics around conditional display decisions:
  - no hovered event IDs in `TimelineStrip.paint-state`;
  - no hovered event IDs in `TimelinePainter.paint`;
  - calendar controller/service runtime logs remain count-only.
- Added regression test that refresh clears an active hover card and collapses the fake window.
- Validation:
  - `make format` passed.
  - `make test` passed 300/300.
  - `make build-linux` passed.
  - `make analyze` still fails on unrelated pre-existing `lib/main.dart:66` visible-for-testing warning.

# Deterministic Expansion State Correction — 2026-05-05T19:04
- User challenged the state model: app should declare the intended state deterministically, not infer/sync from scattered async callbacks.
- Correction:
  - `_wantsExpanded` remains the immediate desired logical state used to block lifecycle resume races.
  - `isExpandedNotifier` now flips to true only in the resize strategy `onExpanded` callback, after Linux resize commands complete.
- Rationale: previous change made Flutter render `expanded=true` while root constraints were still `maxH=60.0`, creating `expanded=true card=true maxH=60.0` and exposing black native space.
- Validation: `make test` 299/299, `make build-linux` passed.

# Linux Expand Surface Allocation Fix — 2026-05-05T18:58
- User reported first expand looked good, second expand all black. Requirement restated: expanded backdrop must be transparent on all platforms; content must be visible.
- Latest logs after race fix:
  - First expand reached `TimelineStrip.paint-state ... maxH=260.0`.
  - Second expand stayed at `maxH=60.0` even after `LinuxResizeStrategy.expand()` completed.
  - This means GTK/window_manager grew the native window enough to expose transparent lower area, but Flutter did not receive a 260px surface/layout allocation on the second expand.
- Fix in `LinuxResizeStrategy.expand()`:
  - Preserve setSize→setMin→setMax order.
  - Add final `setSize(targetSize)` after min/max constraints are valid to force a fresh GTK/Flutter size allocation on repeated expands.
- Updated strategy test to require setSize→setMin→setMax→setSize→callback.
- Validation: `make format`, `make test` 299/299, `make build-linux` passed.

# Linux Expansion Race Fix — 2026-05-05T18:52
- Latest paint logs proved Flutter state was `expanded=true card=true`, but the first bad expand had `resumed — re-asserting collapsed window size` between `_doExpand()` start and `LinuxResizeStrategy.expand() START`.
- Root cause: lifecycle resume used completed state (`isExpandedNotifier`) only. During in-flight expand, notifier could still be false while the user's current intent was expanded, so resume queued a collapse behind the expand in `AsyncGate`.
- Fix in `WindowService`:
  - Added `_wantsExpanded` as latest requested logical resize state.
  - `expand()` sets `_wantsExpanded=true` synchronously before logging/awaiting.
  - `collapse()` sets `_wantsExpanded=false` synchronously.
  - lifecycle `resumed` skips collapsed recovery if `_wantsExpanded || isExpandedNotifier.value`.
  - `_doExpand()` flips `isExpandedNotifier` before the debug await to reduce the pre-paint race window.
- Added regression test: `didChangeAppLifecycleState: does not queue collapse during in-flight expand`.
- Validation: `make format` passed, `make test` passed 299/299, `make build-linux` passed.

# Calendar Logging Privacy Cleanup — 2026-05-05T18:50
- User flagged calendar diagnostics as sensitive: event IDs, calendar IDs, titles, emails, organizer/creator, start times.
- Removed active `[CalendarDiag]` detailed logging from `GoogleCalendarService.fetchEvents()`.
- Replaced it with count-only `[CalendarFetch] fetched <raw> raw items, <timed> timed items`.
- Removed `CalendarController` logging of selected calendar ID sets and per-ID counts; it now logs only number of configured calendars and per-calendar event counts without IDs.
- Fetch warnings no longer include calendar IDs.
- Validation: `make format` passed and `make test` passed 298/298.

# Linux Paint Debug Instrumentation — 2026-05-05T18:46
- User reported resumed-skip fix did not solve black expanded area. Latest `build/build.out` showed initially good behavior, then black after cycles.
- Key new log: at 18:43:39.851 `_doExpand()` started, then at 18:43:39.863 lifecycle `resumed` logged `re-asserting collapsed window size`, queued `collapse()`, and produced an immediate expand-then-collapse sequence. Later `resumed` events correctly logged `expanded, skipping size reassert`.
- Added paint diagnostics:
  - `TimelineStrip.paint-state ...` logs only when relevant render state changes: expanded/card/settings/hover/focus/window mode/transparent idle/backdrop color/painter bg/constraints.
  - `TimelinePainter.paint ...` logs throttled paint calls with canvas size, background ARGB, opacity, event count, hovered ID, loading/sign-in flags.
- Requirement remains: expanded backdrop stays transparent on all platforms.
- Validation after instrumentation: `make format`, `make test` 298/298, `make build-linux` all passed.

# Linux Expanded Black Background Fix — 2026-05-05T18:25
- User clarified hard requirement: expanded backdrop color is always transparent on every platform; no opaque Linux-specific expanded layer.
- `resumed` is not a sticky state to clear. It is a Flutter lifecycle notification emitted when the engine/window returns to foreground/focus.
- In `build/build-expand-black-bug.out`, later failed-looking expansions correlate with `WindowService.didChangeAppLifecycleState: resumed — re-asserting window size`, which called `_doExpand()` while the window was already expanded.
- That extra physical resize can expose the native GTK transparent surface before Flutter paints/composites the next frame; if the compositor fills that surface black, it appears over/behind the transparent expanded area and hides cards.
- Fix implemented in `app/lib/core/window/window_service.dart`: on `resumed`, skip size reassertion when already expanded; only collapsed resume uses the normal gated `collapse()` recovery path.
- Test updated in `app/test/core/window/window_service_test.dart`: expanded `resumed` now verifies no `setSize`, `setMinimumSize`, or `setMaximumSize` calls.
- Validation: `make test FILE=app/test/core/window/window_service_test.dart` ran the full suite and passed 298/298; `make format` passed; `make build-linux` passed.

# Linux Expanded Black Background Diagnosis — 2026-05-05T18:19
- User provided `build/build-expand-black-bug.out`: first expansions looked correct, later expansions showed black over the expanded window/cards.
- Log shows normal expand/collapse resize sequences plus repeated Linux lifecycle `resumed` events that re-run `_doExpand()` while already expanded, e.g. 18:11:09, 18:11:13, 18:11:15, 18:13:56.
- Current `timeline_strip.dart` keeps the full expanded `Positioned` transparent. User confirmed this is required on all platforms.
- Diagnosis: the lower expanded area depends on native/GTK transparency. When Linux compositor/GTK exposes the transparent surface during unnecessary lifecycle reassertion, the expanded area can show black before the next Flutter frame.
- Rejected idea: painting a Linux opaque expanded backdrop. User explicitly rejected it.

# Protocol Load — 2026-05-05T18:15
- Loaded Neo through `$bob-protocol init load neo`.
- Current persisted engineering state remains the completed Linux transparency work:
  - GTK RGBA visual + `gtk_widget_set_app_paintable` added in `app/linux/runner/my_application.cc`.
  - Linux expanded section black-background fix completed in `app/lib/features/timeline/timeline_strip.dart`.
  - Last validation recorded by Neo: `make test` 298/298 and `make build-linux` green.
- Remaining follow-up is native Linux smoke verification if the user reports transparency still failing.
- Project capability still declares `via: enabled`; use `mcp__via__via_query` for symbol lookup before implementation/refactor work.

# Linux Transparent X11/XWayland Smoke Flag — 2026-04-25
- Added temporary `LINUX_TRANSPARENT=1` Makefile opt-in for Linux X11/XWayland smoke testing.
- Runtime flag is exposed as `HAPPENING_LINUX_TRANSPARENT`; default remains off.
- `main.dart` uses the flag to enable Linux transparent capability in `WindowService` and `AppSettings.effectiveWindowMode(...)`.
- `HappeningApp` threads the flag into `TimelineStrip`; `TimelineStrip` threads it into settings/effective-mode handling and `SettingsPanel`.
- Validation: `make format` pass, `make test` pass 293/293, `make build-linux` pass.
- User smoke showed the Flutter surface starts transparent, then a white layer is painted; controls disappear and click-through did not work.
- Removed idle transparent full-window background fill in `TimelineStrip`: transparent idle now uses `Colors.transparent` for both the backing container and `TimelinePainter` background.
- Revalidation after opaque-layer fix: `make format` pass, `make test` pass 293/293, clean sequential `make build-linux` pass.
- Second user smoke showed the intended UX is visible mostly-opaque chrome on transparent background, not hidden controls. Updated `TimelineStrip` so countdown/buttons remain visible and Linux verified smoke remains interactive.
- `build/build.out` showed `MissingPluginException(No implementation found for method setIgnoreMouseEvents on channel window_manager)`: Linux click-through is not available through `window_manager`; this is not a missing apt/pub dependency.
- Linux focus hotkey registration also failed for `<Primary><Shift>KP_Space`, so Linux now uses Ctrl+Shift+H for the smoke path.
- Revalidation after interaction correction: `make format` pass, `make test` pass 294/294, clean `make build-linux` pass.

# Neo Context

## Transparent Timestrip Phase C — 2026-04-24
- Added `WindowInteractionStrategy` and platform implementations for macOS, Windows, and Linux.
- `WindowService` now owns both resize and interaction strategies without mixing their responsibilities.
- Added `setInteractionFocused(bool)` and `setWindowMode(WindowMode)` to `WindowService`.
- Windows AppBar registration now runs only in reserved mode; switching to transparent disposes the AppBar registration.
- Added direct tests for interaction strategies and `WindowService` delegation behavior.
- Validation: `make test` passes 275/275.

## Build Fix + Transparent Timestrip Reconcile — 2026-04-25
- Current Flutter/dependency upgrade resolved `win32` to 5.15 and `hotkey_manager` to 0.2.x.
- Fixed compile compatibility:
  - `FindWindow` now returns `int` and accepts `Pointer<Utf16>` directly in resolved `win32`; no `PCWSTR` wrapper or `.value`.
  - `hotkey_manager` 0.2.x uses `HotKey(key: PhysicalKeyboardKey.space, modifiers: [HotKeyModifier...])`.
  - `defaultTargetPlatform` needs explicit `flutter/foundation.dart` import in `main.dart`.
- Removed unused direct `keybinder` dependency; global hotkey path uses `hotkey_manager`.
- Linux CMake release install must force `/usr/local` back to `${PROJECT_BINARY_DIR}/bundle` to keep `flutter build linux --release` non-root.
- Closed board items TT-D1, TT-D2, TT-D3, TT-E1, TT-F1, TT-F2 after `make test` 289/289 and `make build-linux` green.
- `make analyze` remains blocked by Flutter analysis server `Too many open files` crash after code diagnostics were fixed. `analysis_options.yaml` now excludes generated artifacts, but the Flutter tool still crashes before a clean analyzer result.

## Linux Wayland Simplification Phase A — 2026-04-25
- Interpreted `$bloop *impl sprint 4` against the active approved handoff as current sprint Phase A (`LWS Phase A`) because the Linux Wayland board had Phase A ready and Phase D depends on A-C.
- Added explicit Linux transparent capability guardrails:
  - `AppSettings.effectiveWindowMode(...)` now accepts `linuxTransparentSupported`, defaulting false.
  - `LinuxWindowInteractionStrategy` now supports a verified opt-in path using `window_manager.setIgnoreMouseEvents(..., forward: true)`.
  - `SettingsPanel` now has `linuxTransparentSupported`, defaulting false, and only shows Linux transparent mode when verified.
- Added tests for default-hidden Linux transparent mode and verified Linux transparent support.
- Added smoke matrix at `agents/trin.docs/linux_wayland_simplification_smoke_matrix_2026-04-25T16:55.md`.
- Validation: `make format` passed; `make test` passed 293/293; `make build-linux` passed. `make analyze` failed from the known Flutter analysis server crash, not a source diagnostic.

## Linux Wayland Simplification Phase B/C — 2026-04-25
- Removed Linux native shell reservation from the runner:
  - no X11 `_NET_WM_STRUT_PARTIAL`
  - no X11 DOCK window type
  - no direct X11 include/linkage
  - no optional `gtk-layer-shell` setup
  - no C++ parsing of `~/.config/happening/settings.json`
- Preserved minimal Flutter GTK startup, app icon loading, transparent Flutter view background, and first-frame show.
- Updated docs and Oracle lesson to describe Linux as non-reserving and transparent support as validation-gated.
- Validation: `make format` passed; `make test` passed 293/293; `make build-linux` passed. `make analyze` still crashes in Flutter analysis server.

## Transparent Timestrip Phase B — 2026-04-24
- Added `WindowMode` and `idleTimelineOpacity` to `AppSettings`.
- Added `AppSettings.copyWith(...)` so settings updates preserve newly introduced fields.
- Added `effectiveWindowMode(TargetPlatform)` to centralize platform-safe startup mode resolution:
  - macOS forces transparent
  - Linux forces reserved
  - Windows preserves persisted user choice
- `main.dart` now resolves the effective mode before `WindowService.initialize()`.
- `WindowService.initialize(...)` accepts and stores `initialWindowMode` without changing interaction/geometry behavior yet.
- Settings tests now cover backward-compatible migration, opacity clamping, persisted round-trip, and effective mode resolution.
- Validation: `make test` passes 264/264.

## Transparent Timestrip Phase A — 2026-04-24
- Phase A capability spike implemented and handed to Trin.
- `WindowService` now has `supportsTransparentPassThrough()` and `setPassThroughEnabled(bool)`.
- `setPassThroughEnabled()` calls `window_manager.setIgnoreMouseEvents(enabled, forward: true)` only when transparent pass-through is supported.
- Linux transparent mode stays unavailable by default this sprint due prior real-session failure evidence: static transparent/click-through attempt produced an unusable black bar.
- Unit coverage added for pass-through enable, disable, unsupported no-op, and Linux default availability.
- Hotkey decision: use `hotkey_manager` in TT-D2; defer adding dependency until global focus hotkey wiring starts.
- `Makefile.prj` targets were merged into `Makefile`; `make test` now routes to Flutter tests through mkf and passes.
- Validation: `make format` passes; `make test` passes 259/259.

## Timeline Strip Compact Platform Time Format — 2026-04-17
- Drew clarified the time strip should stay compact: hour ticks only show the hour, and half-hour ticks show `30`.
- Updated `TickLayer` to use the platform 12/24-hour preference without full minute text:
  - 12-hour mode renders hour ticks like `11pm`;
  - 24-hour mode renders hour ticks like `23`;
  - half-hour ticks render `30`.
- `TimelinePainter` semantics now use the same compact labels as the painted ticks, keeping integration-test labels aligned with the canvas.
- Hover/event cards remain on full `MaterialLocalizations.formatTimeOfDay()` output from the prior fix.
- Validation: `make -f Makefile.prj format`, `make -f Makefile.prj update-goldens`, and `make -f Makefile.prj test` pass, 243/243.

## Calendar Fetch Threading Implementation — 2026-04-17
- Completed Morpheus architecture update after Trin QA found partial implementation.
- `CalendarController._scheduleFetch()` remains a single-flight guard: overlapping requests return active `_inFlightFetch` and do not enqueue follow-up work.
- `CalendarController._fetchOnce()` now fetches selected calendar IDs sequentially with a `for` loop instead of `Future.wait`.
- Per-calendar failures still log a warning and contribute an empty event list.
- Updated calendar controller tests:
  - stale queued-follow-up refresh test now asserts ignored overlapping refreshes and one fetch.
  - `_BlockingCalendarService` records requested calendar IDs.
  - added selected-calendar sequential order coverage: `primary` starts first, `secondary` starts only after primary completes.
- Validation: `make -f Makefile.prj test` shows calendar threading tests pass; full suite remains red from unrelated window binding initialization failures.

## Remaining Test Failures Fix — 2026-04-17
- Investigated the remaining red suite after calendar threading.
- Window tests were not deprecated. They failed because `WindowService.initialize()` now calls `WidgetsBinding.instance.addObserver(this)`, so the test harness must initialize `TestWidgetsFlutterBinding`.
- Fixed `window_service_test.dart` and `window_linux_e2e_test.dart` by initializing the test binding.
- Updated `window_service_test.dart` mock setup so `waitUntilReadyToShow()` invokes the callback and `focus()` returns a completed future.
- Golden failure was not deprecated. Regenerated stale `hover_card_alignment.png` after verifying current/failure image kept the intended hover-card layout.
- Added Makefile target `update-goldens` for future Flutter golden refreshes.
- Validation: `make -f Makefile.prj test` passes, 239/239.

## Calendar Multi-Calendar Correction — 2026-04-17
- Drew corrected the multi-calendar diagnosis: repeated events should be deduped, event titles are valid, and all-day events must not be displayed.
- Restored documented calendar contracts from story/archive history:
  - all-day events are excluded by requiring `start.dateTime`;
  - `CalendarEvent` equality/hash are event-ID based;
  - `CalendarController._dedup()` dedupes by event ID across selected calendars;
  - title parsing is back to the existing summary behavior.
- Kept the earlier fetch-threading work: ignored overlapping refresh requests return the active `_inFlightFetch`, and selected calendars fetch sequentially.
- Kept only scoped per-calendar count logging: `Fetched calendar <id>: <n> events`.
- Validation: `make -f Makefile.prj format` passes; `make -f Makefile.prj test` passes, 240/240.

## Calendar Permissions Diagnostics — 2026-04-17
- Drew suspects missing titles may be a Google Calendar permissions/visibility issue for meetings owned by `[USER_EMAIL_1]` and shared with `[USER_EMAIL_2]`.
- Added temporary `[CalendarDiag]` logging in `GoogleCalendarService.fetchEvents()` before the timed-event filter.
- Calendar diagnostics log: calendar ID, metadata summary, events response summary, `calendarList.accessRole`, response `accessRole`, and raw item count.
- Event diagnostics log: event ID, summary, visibility, status, eventType, creator email, organizer email, `start.dateTime`, and `start.date`.
- Intentionally does not log descriptions, locations, html links, conference links, or full raw JSON.
- Validation: `make -f Makefile.prj format` and `make -f Makefile.prj test` pass, 240/240.

## Hover Card Platform Time Format — 2026-04-17
- Drew reported the time strip used AM/PM labels while event hover cards used hard-coded 24-hour `HH:mm`.
- Updated `HoverDetailOverlay` to format event start/end times through `MaterialLocalizations.formatTimeOfDay()`.
- The formatter now honors `MediaQuery.alwaysUse24HourFormatOf(context)`, so platform 12/24-hour preference controls the card.
- Added widget coverage for default localized 12-hour output and forced 24-hour output.
- Regenerated `hover_card_alignment.png` golden because the card text changed from `10:00 - 10:30` to localized AM/PM text in the default test environment.
- Validation: `make -f Makefile.prj format`, `make -f Makefile.prj update-goldens`, and `make -f Makefile.prj test` pass, 241/241.

## Protocol Init — 2026-04-17
- Loaded Neo via bob-protocol on 2026-04-17T13:04.
- Recent team context: TEST_UPDATE remains complete and awaiting Trin QA verification.
- Recent team context: Morpheus diagnosed/fixed Linux X11 strut timing by moving `set_x11_strut` to post-realize pre-show in `my_application.cc`; testing is still needed.
- Project capability: `via` is enabled; use `mcp__via__via_query` for symbol navigation before implementation/refactor work.

## Timeline Frozen Fix — 2026-04-17
- User reported running app timeline was frozen/not counting down and provided `strace`.
- `strace` showed the process was alive and Flutter timers were firing (`timerfd_settime` roughly every second), pointing to app stream/subscription behavior rather than a native deadlock.
- Fix: `ClockService` now owns stable broadcast `tick1s`/`tick10s` streams instead of returning new `Stream.periodic` instances on every getter read.
- Fix: `TimelineStrip` caches the injected clock streams in state and refreshes them only if `clockService` changes, preventing parent rebuilds from replacing active stream subscriptions.
- Tests added for stable clock stream identity and TimelineStrip not replacing clock streams on parent rebuild.
- Validation: `make -f Makefile.prj test V=-vv` compiled and ran changed tests, which passed, but full suite remains red from unrelated `WindowService.initialize` tests missing `WidgetsBinding` initialization. `make -f Makefile.prj analyze V=-vv` failed from Flutter analyzer `Too many open files`. `make format` formatted app files before failing on Flutter telemetry; user accepted formatting diffs.

## Linux Expanded Paint Fix — 2026-04-17
- User reported expanded hover section is flaky on Linux: cards sometimes show, sometimes expanded area is all black.
- Docs/log history say Linux should keep a solid background; relying on compositor transparency causes black pixels on X11/Wayland.
- Root cause addressed: LinuxHoverController suppressed GTK synthetic collapse requests, but TimelineStrip still cleared `_hoveredEvent` before suppression, leaving expanded solid background without a card.
- Fix: `HoverController.setIntent()` now returns whether an intent was accepted. Linux returns `false` for suppressed collapses. TimelineStrip preserves hover UI state when an intent is suppressed.
- Tests updated: hover controller now asserts accepted/suppressed intent return values; TimelineStrip has Linux regression coverage that a suppressed synthetic exit keeps `HoverDetailOverlay` painted.
- Validation: `make -f Makefile.prj test V=-vv` ran with the new regression test passing; full suite still fails on unrelated WindowService binding initialization tests.

## Calendar Fetch Coalescing Fix — 2026-04-17
- User reported another app stuck state. `strace -p 55392` showed a futex wait and the debug log stopped after a burst of overlapping `CalendarController._fetch(forceRefresh: true)` calls around 13:43:00 plus a hover expand.
- Root cause addressed: `CalendarController.refresh()` could start unbounded parallel fetches. Each fetch fans out across all selected calendars, so rapid refresh taps created many simultaneous Google API calls and event emissions.
- Fix: `CalendarController` now serializes fetch work. If a fetch is already in flight, new requests coalesce into one queued follow-up forced refresh.
- Added regression coverage with a blocking fake calendar service: three overlapping refresh calls produce exactly two fetches (active + one queued follow-up), not three concurrent fetches.
- Validation: `make -f Makefile.prj test V=-vv` ran and the coalescing regression test passed; full suite remains red only on unrelated WindowService binding initialization tests.

## Windows Sprint — 2026-03-19
- WIN collapse 140px bug: `_reserveCollapsedSpace()` called on every collapse, `ABM_SETPOS` mutates `rcLeft` to ~3700, window placed off-screen. Fix: remove redundant call from `_doCollapse()`.
- WIN expanded transparency: background Container used opaque `stripBackgroundColor`. Fix: `Colors.transparent` when `isExpanded && Platform.isWindows`.
- LESSONS.md updated with both.

## PKCE Auth Migration — 2026-03-06
- Replaced `clientViaUserConsent()` (needs secret) with manual PKCE flow in `GoogleAuthService.signIn()`
- PKCE helpers: `_generateVerifier()` (32 random bytes, base64url) + `_sha256Challenge()` (SHA256, base64url)
- Local `HttpServer.bind('localhost', 0)` captures auth code redirect
- Token exchange POSTs to `https://oauth2.googleapis.com/token` with `code_verifier` — no secret
- `autoRefreshingClient` kept for `tryRestore()` — refresh works with empty secret for Desktop app type
- `assets/client_secret.json` deleted; `_kGoogleClientId` hardcoded in `app.dart`
- `crypto: ^3.0.0` added to pubspec; asset entry removed
- 185/185 tests GREEN


## macOS Build — 2026-03-07
- window_service.dart: moved `DynamicLibrary.open('shell32.dll')` from top-level into `_registerAppBar()` (Windows-only path). Declared as `late final _SHDart _shAppBarMessage` class field.
- Release.entitlements: added `com.apple.security.network.server` for PKCE localhost redirect capture.
- Makefile: added run-macos, dist-macos, integration-test-macos targets.
- macOS build: ✅ 40.5MB .app (flutter build macos --release).
- Tests: 184/185 — 1 golden test (S4-31) fails due to Linux vs macOS rendering difference. Expected. Goldens need regen on macOS.

## Sprint 5: Refinement — 2026-03-02
- Implemented `ExpansionLogic` (pure logic) in `app/lib/features/timeline/expansion_logic.dart`.
- TDD complete: `app/test/features/timeline/expansion_logic_test.dart` passes with 9 tests.
- Logic covers: Settings overrides, Interaction Zone (dy >= stripHeight), Hit Zone (event bounds), and Default (collapsed).
