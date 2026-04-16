# Morpheus Context

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
