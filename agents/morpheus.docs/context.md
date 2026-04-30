# Morpheus Context

## Linux Click-Through Research — 2026-04-26

- `window_manager` v0.5.1 does NOT implement `setIgnoreMouseEvents` on Linux (returns `MissingPluginException`).
- **CONFIRMED (2026-04-26 smoke)**:
  - Native Wayland (`GDK_BACKEND=wayland`): ✅ click-through works via `wl_surface.set_input_region`
  - XWayland (`GDK_BACKEND=x11`): ❌ Mutter ignores X11 SHAPE for Wayland routing — clicks do NOT pass through
  - Pure X11 (no Wayland compositor): ✅ should work via XShape (untested but no compositor interference)
- **Root cause**: Mutter routes clicks at the Wayland surface level. XWayland presents a single surface to Mutter; X11 input shapes only affect X11-internal routing within XWayland.
- **Architecture implication**: Click-through requires native Wayland, which requires layer-shell for positioning. The current app forces GDK_BACKEND=x11 for window_manager positioning — incompatible with click-through.
- **Full solution scope**: Re-introduce gtk-layer-shell (optional CMake dep) for Wayland positioning + use GDK input shape for click-through on native Wayland.
- Test app created: `tools/click_through_test/` — run with `make run-click-test` (Wayland) or `make run-click-test-x11`.
  - Custom inline Flutter plugin: `linux/runner/click_through_plugin.cc/.h`
  - Methods: `setIgnoreMouseEvents({ignore: bool})`, `getDisplayServer()`
  - ARGB transparent window + toggle UI with log.
- Build verified: `flutter build linux --release` passes clean.
- Research doc: `agents/morpheus.docs/LINUX_CLICK_THROUGH_RESEARCH_2026-04-26.md`
- Integration path for `happening` main app:
  1. Copy `click_through_plugin.cc/.h` to `app/linux/runner/`.
  2. Register in `my_application.cc` after `fl_register_plugins`.
  3. Update `LinuxWindowInteractionStrategy` to call `happening/click_through` channel before `window_manager`.
  4. Gate `linuxTransparentSupported = true` after real-session click-through smoke passes.

## Transparent Timestrip Architecture — 2026-04-24
- Smith Gate 1 approved transparent timestrip sprint stories with UX constraints:
  - global hotkey primary focus path
  - idle click-through by default
  - hide macOS reserved/statusbar mode
  - bounded transparency slider
- Architecture decision: keep `WindowResizeStrategy` for geometry and add a separate `WindowInteractionStrategy` for pass-through/focus/window-mode availability.
- Detailed architecture saved at `agents/morpheus.docs/TRANSPARENT_TIMESTRIP_ARCH_2026-04-24T15:08.md`.
- Linux transparent mode must be capability-gated; reserved mode remains fallback/default unless verified.
- Sprint plan approved:
  - Root `task.md` contains Transparent Timestrip Sprint with 7 phases and 14 tasks.
  - Review saved at `agents/morpheus.docs/transparent_timestrip_sprint_plan_review_2026-04-24T15:11.md`.
- Phase A review complete:
  - pass-through probe API in `WindowService` is sufficient as the interaction seam before Phase C.
  - Linux transparent mode remains correctly capability-gated/hidden.
  - `hotkey_manager` is an acceptable implementation target for TT-D2 and does not need to be added during Phase A.
  - `task.md` and architecture notes now reflect the implemented spike outputs.
- Phase B review complete:
  - persisted `windowMode` and `idleTimelineOpacity` satisfy the settings-foundation requirement.
  - effective mode is now available before `WindowService.initialize(...)`.
  - `copyWith(...)` reduces risk of resetting newly introduced settings at existing update sites.
- Phase C review complete:
  - `WindowInteractionStrategy` now owns pass-through/focus/window-mode interaction policy separately from `WindowResizeStrategy`.
  - `WindowService` is the orchestration point for effective mode init and interaction delegation.
  - Windows AppBar reservation is correctly restricted to reserved mode and is disposed when mode switches to transparent.
- 2026-04-25 load checkpoint:
  - Recent chat shows Neo reconciled build and sprint board after Phase D/F artifacts: `make format` passed, `make test` passed 289/289, `make build-linux` passed, and task board items TT-D1/D2/D3/E1/F1/F2 were closed.
  - `make analyze` later passed with "No issues found" on 2026-04-25 16:29.
  - Morpheus loaded state from `$bob-protocol init load morph`; next useful lead action is review/approve the reconciled Phase D/F scope if requested.
- 2026-04-25 Linux/Wayland simplification review:
  - Recommendation: make Linux follow the transparent non-reserving model where proven, and remove Linux reserved-space native code rather than trying to maintain X11 strut plus optional Wayland layer-shell.
  - `app/linux/runner/my_application.cc` currently mixes reserved-space panel setup (`set_x11_strut`, `set_wayland_layer`, `get_reserved_height`) with Flutter runner startup.
  - Reserved-space behavior cannot be replaced cleanly by Dart-only `window_manager`; Wayland exclusive zones require layer-shell integration and X11 struts require Xlib.
  - If Linux reserved mode is dropped or demoted to unsupported, candidates for removal are X11 include/linkage, `_NET_WM_STRUT_PARTIAL`/DOCK setup, optional `gtk-layer-shell` CMake logic, and C++ settings-file parsing for strip height.
  - Keep a minimal Linux runner only for standard Flutter/GTK startup, icon, and any transparent view background that `window_manager` cannot reliably provide.
  - Sprint architecture approved at `agents/morpheus.docs/LINUX_WAYLAND_SIMPLIFICATION_ARCH_2026-04-25T16:41.md`.
  - Sprint plan approved at `agents/morpheus.docs/linux_wayland_simplification_sprint_plan_review_2026-04-25T16:41.md`.
  - Phase A review approved:
    - Linux transparent remains default-hidden via `linuxTransparentSupported = false`.
    - verified Linux support is represented in Dart interaction/settings tests without introducing native shell-reservation code.
    - smoke matrix is sufficient for later real-session X11/XWayland and Wayland support claims.
    - next implementation phase should remove native Linux reservation code in a small, reversible patch.
  - Phase B/C review approved:
    - Linux runner no longer carries X11 strut/DOCK, direct X11 linkage, optional layer-shell setup, or C++ settings parsing.
    - Minimal GTK startup, app icon loading, transparent view background, and first-frame show are preserved.
    - Public docs and Oracle lesson now reflect Linux non-reserving behavior and validation-gated transparent support.
    - Windows AppBar behavior was untouched.
  - Phase D review:
    - implementation and docs are acceptable as a non-claiming release path because Linux transparent remains hidden unless verified.
    - full support claim is blocked by `make analyze` Flutter analysis-server crash and missing X11/XWayland plus Wayland real-session smoke results.
  - Phase D continuation:
    - user reports host-side `make analyze` is clean after excluding `.flutter`.
    - Trin reran `make format`, `make test`, and a clean sequential `make build-linux`; all pass.
    - user smoke established X11/XWayland placement works without shell reservation.
    - native Wayland remains unsupported for strip behavior: centered placement plus GTK protocol disconnect during interaction.
    - Architecture decision: approve X11/XWayland Linux behavior, do not claim native Wayland or Linux transparent support.

## Calendar Fetch Threading Architecture — 2026-04-17
- User asked for architecture before implementation: fetch calendars through a queue, but do not queue refresh requests while a refresh/fetch is pending.
- Binding decision: two-level concurrency model.
  - Controller-level single-flight via `_inFlightFetch`.
  - Per-calendar sequential queue inside the active fetch.
- `refresh()` remains the completion signal: ignored refresh calls return the currently active `Future<void>`.
- `events` stream remains the data signal: emit once after queued calendar fetches complete and are deduped.
- No `_queuedForceRefresh`, no `while (true)`, no `Future.wait` fan-out for selected calendars.
- Details documented in `agents/morpheus.docs/CALENDAR_FETCH_THREADING_ARCH_2026-04-17T19:59.md`.
- Implementation review complete: approved. `CalendarController` now uses `_inFlightFetch` for single-flight, a sequential `for`/`await` calendar loop, and tests for ignored refreshes plus selected-calendar queue order.
- Full suite remains red from unrelated window binding initialization failures; calendar threading UAT passed for scope.

## Active: Linux Black Screen Fix — 2026-04-15

### Root Cause (CONFIRMED)
`my_application.cc`'s `first_frame_cb` called `set_x11_strut()` (which sets
`_NET_WM_WINDOW_TYPE_DOCK`) AFTER the window was already mapped by
`_wm.show()` from `WindowService`. Mutter/XWayland re-classifies the window on
type change and destroys its ARGB compositing context → permanent black screen.

### Fix Applied
Moved `set_x11_strut(GTK_WINDOW(window))` to right after
`gtk_widget_realize(GTK_WIDGET(view))` in `my_application_activate()`, before
any `gtk_widget_show()` call. X11 properties can be set on realized-but-unmapped
windows; Mutter reads them at map time and sets up ARGB correctly.

Simplified `first_frame_cb` to just `gtk_widget_show(toplevel)`.

### Awaiting User Test
Build: `make -f Makefile.prj run-linux` — should no longer show black screen.
Also check: stuck-Fetching may be separate (didn't reproduce in the debug log run).

## Previous: Loading State Refactor — 2026-03-23

### Problem
`app.dart` swaps `_LoadingStrip` → `TimelineStrip` on first events emission. `TimelineStrip` has expensive state (HoverController, WidgetsBindingObserver, timers). The swap races with async window ops.

### Decision (ARCH-004)
Never unmount `TimelineStrip` once authenticated. Pass `isLoading: events == null` + `events: events ?? const []`. Branch painter layer stack when loading.

### Approach
- `app.dart`: remove `_LoadingStrip`, remove null check, always render `TimelineStrip`
- `timeline_strip.dart`: accept + thread `isLoading` to painter
- `timeline_painter.dart`: add `isLoading`, branch: loading = [BackgroundLayer, FetchingLayer], normal = full stack
- New `painters/fetching_layer.dart`: centered italic text on canvas
- NO transparency overlay — on first boot events is empty, nothing behind the overlay

### Status: Awaiting user approval to hand to Neo

## Previous: Linux Expand Bug Re-investigation — 2026-03-23

### Root Cause Confirmed (ARCH-002 regression)
`LinuxResizeStrategy.expand()` order was wrong in Sprint 6 "fix". Real fix: setSize→setMinimumSize→setMaximumSize. GTK grows window when window < min_size. Fixed in linux_resize_strategy.dart. UAT passed.

## Previous: Linux Window Resize Bugs — 2026-03-18
### ARCH-002 Decision
`LinuxResizeStrategy.expand()` must use: `setSize → setMinimumSize → setMaximumSize`
Rationale: GTK forces window growth via min>max conflict.
