# Linux Wayland Simplification Smoke Matrix

**Sprint**: Linux Wayland Simplification  
**Phase**: LWS-A2  
**Owner**: Trin with User support for real-session coverage

## Required Sessions
- X11 or XWayland session.
- Wayland session.

If either session is unavailable, record it as a release blocker for claiming Linux transparent support. Native reservation removal can still proceed.

## Startup Checks
- App launches without a black window or black strip.
- Strip appears at the top of the primary display.
- Strip width matches the primary display width.
- App remains above normal windows where the compositor allows always-on-top.
- App icon still appears where the desktop environment shows app/window icons.

## Transparent Idle Checks
- Set Linux transparent support only in a verified test build/session.
- Idle strip uses the configured transparency.
- Clicks on timeline/event areas pass to the window underneath.
- Underlying window titlebar can be focused, dragged, and resized from behind the strip.
- Happening controls are not accidentally interactive while idle.

## Focus Checks
- Global focus hotkey focuses Happening.
- Focused mode disables pass-through.
- Settings, refresh, quit, and event details work while focused.
- Escape returns to idle pass-through mode.
- Inactivity timeout returns to idle only when settings/details are not active.

## Regression Checks
- Hover expansion still works in reserved/unsupported Linux mode.
- No invisible 0-width or wrong-height window after display sleep/resume.
- No stale native reserved-space behavior remains: newly maximized windows are not pushed down by Happening on Linux.

## Recorded Smoke Results

```text
Session: X11/XWayland
Desktop/compositor: GNOME session with XWayland available
Build: 2026-04-25 development run
Pass: App launches; top strip placement works without shell reservation.
Fail: Linux transparency is still hidden/unsupported, so the reserved-mode solid strip remains.
Notes: This is the preferred Linux backend for current development runs.
Decision: keep Linux transparent hidden; use X11/XWayland for stable placement
```

```text
Session: Wayland
Desktop/compositor: GNOME Wayland
Build: 2026-04-25 development run
Pass: App launches.
Fail: Window appears in the middle instead of top-aligned; interaction eventually ends with "Gdk-Message: Error flushing display: Protocol error" / "Lost connection to device."
Notes: Native Wayland does not reliably honor absolute positioning through standard Flutter/GTK APIs, and current resize/constraint mutation is unstable in this session.
Decision: native Wayland unsupported for strip behavior; keep Linux transparent hidden
```

## Result Format
Record one result block per session:

```text
Session: X11/XWayland | Wayland
Desktop/compositor:
Build:
Pass:
Fail:
Notes:
Decision: expose transparent | keep hidden | blocked
```
