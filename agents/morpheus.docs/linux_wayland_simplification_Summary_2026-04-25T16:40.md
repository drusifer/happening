# Linux Wayland Simplification Summary - 2026-04-25T16:40

## Request
Revisit Linux/Wayland support and simplify native code now that transparent mode is the preferred interaction model.

## Findings
- Current Linux native runner contains reserved-space panel code:
  - X11 `_NET_WM_STRUT_PARTIAL` and DOCK type via Xlib.
  - Optional Wayland `gtk-layer-shell` exclusive zone.
  - C++ settings-file parsing to calculate reserved strip height.
- Dart/window_manager can cover normal window management and click-through API surface, but not shell work-area reservation.
- Wayland reserved-space support is inherently compositor/protocol-specific and cannot be made reliable with generic Flutter/Dart APIs alone.

## Recommendation
If Linux no longer needs to reserve desktop space, remove the Linux reserved-space native code. Keep only minimal Flutter/GTK runner behavior and rely on Dart plugins for normal window size, position, always-on-top, transparency, and pass-through behavior where validated.

## Proposed Handoff
@Neo spike Linux transparent simplification:
1. Remove X11 strut and layer-shell reservation logic.
2. Remove X11 link and optional gtk-layer-shell CMake block if unused.
3. Keep/verify transparent background startup.
4. Change Linux mode availability only after real-session X11/Wayland validation.
5. Run `make test`, `make analyze`, and `make build-linux`.
