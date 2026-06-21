# Happening Project Memory

## Project Overview
Flutter desktop app (Linux/macOS/Windows) — a top-of-screen calendar strip that shows hovercards and a settings panel when expanded.

## Key Files
- `app/lib/core/window/window_service.dart` — `applyState(StripState)`, the single OS-geometry applier
- `app/lib/core/window/strip_controller.dart` — `StripController`, the single serialized transition gate (DEC-009)
- `app/lib/features/timeline/timeline_strip.dart` — main UI, hover/mouse logic
- Window architecture: `docs/ARCH.md` §6 + `docs/DECISIONS.md` DEC-009
- `app/linux/runner/my_application.cc` — GTK native setup (RGBA visual, first_frame_cb)
- `app/lib/main.dart` — entry point
- `~/.config/happening/debug.log` — runtime log file
- `docs/LINUX_SIMPLIFICATION.md` — design doc for 2026-05-11 platform simplification

## Linux Platform (XWayland only)
As of 2026-05-11, all Linux-specific platform code has been removed.
Linux now uses the same code paths as macOS:
- `MacOsResizeStrategy`: expand = setMax→setSize→setMin; collapse = setMin→setMax→setSize
- `MacOsWindowInteractionStrategy`: click-through via `window_manager.setIgnoreMouseEvents()`
- No custom C++ click-through plugin; no layer-shell; no XWayland detection
- `linuxTransparentSupported = Platform.isLinux` (always true)

## Expand/Collapse Flicker (open issue)
Diagnosed 2026-05-11. NOT YET FIXED.
- `setSize` grows GTK window at +42ms after expand intent
- Flutter `maxH` lags ~171ms while subsequent platform calls block the GLib event loop
- During that gap: 50px Flutter surface appears at bottom of 300px GTK window
- Fix direction: emit expanded state before OS resize, OR remove constraint calls from expand

## Multi-Agent Protocol
Uses BOB_SYSTEM_PROTOCOL — see `agents/bob.docs/BOB_SYSTEM_PROTOCOL.md`.
Chat log: `agents/CHAT.md`. Post via `make chat MSG="..." PERSONA="..." CMD="..."`.
