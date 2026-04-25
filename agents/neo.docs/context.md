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
