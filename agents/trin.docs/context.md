# Trin Context

## Transparent Timestrip Phase C UAT — 2026-04-24
- `WindowInteractionStrategy` is now the interaction-policy seam parallel to `WindowResizeStrategy`.
- `WindowService` delegates pass-through and focus behavior through the strategy and initializes it with the effective `WindowMode`.
- Windows AppBar reservation/reassertion now runs only in reserved mode; switching to transparent disposes the AppBar registration.
- Coverage now includes strategy factory behavior plus WindowService delegation/mode-switch tests.
- Latest complete validation run recorded in chat: `make test` passed 275/275.

## Linux Wayland Simplification Phase A UAT — 2026-04-25
- Expected behavior: Linux transparent remains hidden/unsupported by default; verified transparent behavior is opt-in only; manual smoke matrix gates any Linux transparent support claim.
- Verified `AppSettings.effectiveWindowMode(...)` keeps Linux reserved unless `linuxTransparentSupported` is true.
- Verified `LinuxWindowInteractionStrategy` is no-op by default and can toggle forwarded ignored mouse events only when constructed with verified support.
- Verified `SettingsPanel` hides Linux transparent mode by default and shows it only with `linuxTransparentSupported: true`.
- Verified smoke matrix exists at `agents/trin.docs/linux_wayland_simplification_smoke_matrix_2026-04-25T16:55.md`.
- Validation: `make test` passes 293/293. Neo also recorded `make format` and `make build-linux` pass; `make analyze` remains blocked by Flutter analysis server crash.

## Linux Wayland Simplification Phase B/C UAT — 2026-04-25
- Verified Linux runner no longer contains X11 strut/DOCK hooks, `gtk-layer-shell`, direct X11 linkage, or C++ settings parsing.
- Verified minimal Linux runner still keeps Flutter startup, icon loading, transparent view background, and first-frame show.
- Verified docs now describe Linux as non-reserving and validation-gated: `docs/ARCH.md`, `docs/DECISIONS.md`, `docs/PRD.md`, `README.md`, `docs/WINDOWS_BUILD_STRATEGY.md`, and `agents/oracle.docs/LESSONS.md`.
- Validation from Neo: `make format` pass, `make test` pass 293/293, `make build-linux` pass. `make analyze` remains a Flutter analysis server crash.

## Linux Wayland Simplification Phase D Gate — 2026-04-25
- Automated checks:
  - `make format` passed.
  - `make test` passed 293/293.
  - `make build-linux` passed.
  - `make analyze` failed from Flutter analysis server crash, same tool blocker as previous runs.
  - User reran `make analyze` at 2026-04-25 17:14; `build/build.out` still shows analysis server watcher failure: `OS Error: Too many open files, errno = 24`, then `Bad state: Future already completed`, before any source diagnostics.
  - User reports the host-side `make analyze` issue is fixed after excluding `.flutter`.
  - Codex sandbox rerun at 2026-04-25 19:12 still fails before diagnostics because the sandbox has `fs.inotify.max_user_instances=128`.
  - 2026-04-25 19:27/19:28 continuation: `make format` passed with 0 changed files; `make test` passed 293/293; clean sequential `make build-linux` passed and built `build/linux/arm64/release/bundle/happening`.
- Real-session UAT:
  - Smoke matrix exists and now includes user-supported results.
  - X11/XWayland placement works without shell reservation and is the preferred Linux backend.
  - Native Wayland launches but appears centered and later disconnects with a GTK protocol error during interaction.
  - Linux transparent support must not be claimed yet; unsupported Linux transparent mode remains hidden.
  - `make run-linux` now forces `GDK_BACKEND=x11`.

## Transparent Timestrip Phase B UAT — 2026-04-24
- `AppSettings` persistence now covers `windowMode` and `idleTimelineOpacity`.
- Backward-compatible defaults remain intact for older settings files.
- Idle opacity clamp behavior is covered in settings tests.
- Settings update call sites now use `copyWith(...)`, so new fields are preserved instead of reset.
- `main.dart` resolves effective window mode before `WindowService.initialize(...)`.
- Validation: `make test` passes 264/264.

## Transparent Timestrip Phase A UAT — 2026-04-24
- Neo's Phase A scope matches the sprint board: a pass-through probe API, Linux hidden by default, and a documented hotkey implementation target.
- `WindowService.setPassThroughEnabled(bool)` uses `setIgnoreMouseEvents(enabled, forward: true)` only when transparent pass-through is supported.
- Unsupported platform behavior is a no-op; Linux default availability is false.
- `make test` from the merged main `Makefile` passed 259/259, so the Makefile merge did not regress the suite.
- Manual macOS/Windows click-through behavior is still a later smoke-test item, not a blocker for Phase A UAT.

## Calendar Fetch Threading QA — 2026-04-17
- Expected behavior from Morpheus architecture: single-flight `_inFlightFetch`, ignored overlapping refreshes return the active Future, per-calendar fetches run sequentially, no queued follow-up.
- QA verdict: NOT DONE. `CalendarController._scheduleFetch()` has the ignore/active-Future behavior, but `_fetchOnce()` still uses `Future.wait` across selected calendars.
- `app/test/features/calendar/calendar_controller_test.dart` has stale queued-follow-up assertions expecting 2 fetches; new policy should expect 1 fetch for overlapping refresh calls.
- Missing coverage: sequential queue-order test proving `primary` is requested first and selected calendars start only after the previous calendar completes.
- `make -f Makefile.prj test` failed. Calendar failure is policy/test mismatch; unrelated window tests still fail on missing `WidgetsBinding` initialization before `WindowService.initialize()`.
- Follow-up UAT after Neo implementation: PASS for calendar threading scope. `_fetchOnce()` now uses sequential `for/await`, overlapping refresh test expects one fetch, and queue-order test covers `primary` before `secondary`.
- Full suite is still red only from known window binding tests, not calendar threading.

## Test Grooming — 2026-03-06
- `HoverDetailOverlay` gated on `_windowService.isExpandedNotifier.value` (not just `_hoveredEvent != null`). Fakes MUST update this notifier.
- `_doCollapse` calls global `windowManager.focus()` on Linux — untestable without full binding. Skip on non-Windows.
- `window_service.dart` `initialize` now uses `waitUntilReadyToShow` callback pattern — old unit test expectations were stale.
- Golden: hover card alignment updated for current UI.


## Sprint 5: Fresh Start — 2026-03-01
- Group A, B, C, D COMPLETE.
- Starting Group E (Interaction: Click-to-Expand) verification. S5-E1/E2/E3/E4.
- All previous S5 attempts REVERTED. Clean slate from v0.1.0.

## QA Decisions
- Every bug fix MUST have an empirical reproduction test (unit or integration).
- S5-E4: Need to verify HTML stripping and description display.
- Tap detection (S5-E1) requires widget testing with gesture simulation.
