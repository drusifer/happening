# Morpheus Context

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
