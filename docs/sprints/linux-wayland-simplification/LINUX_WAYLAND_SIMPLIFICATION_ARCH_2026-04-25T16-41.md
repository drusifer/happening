# Linux Wayland Simplification Architecture

**Date**: 2026-04-25T16:41  
**Lead**: Morpheus  
**Sprint**: linux_wayland_simplification

## Decision
Remove Happening-owned Linux reserved-space panel behavior and make Linux follow the transparent, non-reserving interaction model only where validated. Do not replace X11 struts or Wayland exclusive zones with another native reservation layer.

## Rationale
The previous Linux native path mixed two concerns:
- Flutter/GTK runner startup.
- Shell-reserved panel behavior.

Transparent timestrip changes the product goal. We no longer need Linux to push other windows down if pass-through transparent mode is reliable. Maintaining both X11 `_NET_WM_STRUT_PARTIAL` and optional Wayland `gtk-layer-shell` creates build/runtime complexity for a product behavior we are moving away from.

## Target Boundaries

### Keep In Dart/Flutter
- Window sizing and positioning through `WindowService` and `WindowResizeStrategy`.
- Transparent mode availability through `WindowInteractionStrategy`.
- Settings availability through `AppSettings.effectiveWindowMode(...)` and settings-panel filtering.
- Pass-through calls through `window_manager.setIgnoreMouseEvents(...)` where supported.

### Keep In Linux Runner
- Standard Flutter Linux GTK startup.
- App icon loading if still needed.
- Transparent view background if Dart/window options alone do not reliably establish transparency before first frame.

### Remove From Linux Runner
- `get_reserved_height()`.
- X11 `_NET_WM_STRUT_PARTIAL` and `_NET_WM_WINDOW_TYPE_DOCK` setup.
- Direct Xlib includes and direct X11 runner linkage.
- Optional `gtk-layer-shell` setup and CMake detection.
- C++ parsing of `~/.config/happening/settings.json`.

## Implementation Strategy
1. Add or update tests that lock Linux availability behavior before deleting native code.
2. Remove Linux reserved-space runner code and CMake dependencies.
3. Update docs to say Linux uses transparent/non-reserving behavior only when validated; shell reservation is intentionally unsupported.
4. Run automated checks.
5. Perform real-session Linux smoke tests:
   - X11/XWayland
   - Wayland

## Non-Goals
- No new Wayland layer-shell plugin.
- No new X11 shape/strut bridge.
- No change to Windows AppBar reservation.
- No broad rewrite of `LinuxResizeStrategy` unless required by removed reservation assumptions.

## Risks
- Linux pass-through may still fail on some compositors.
- `alwaysOnTop` and top-position behavior can vary by Wayland compositor.
- Removing reservation changes the overlap model; visual transparency and focus affordances must make this intentional.

## Binding Constraints For Neo
- Keep `WindowResizeStrategy` geometry-only.
- Keep `WindowInteractionStrategy` responsible for support and pass-through policy.
- Do not expose Linux transparent mode without recorded real-session validation.
- Remove native reservation code in a small patch that is easy to revert if build smoke fails.
- Use `make` targets for validation.
