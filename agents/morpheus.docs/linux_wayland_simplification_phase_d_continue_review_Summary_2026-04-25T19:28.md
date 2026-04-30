# Linux Wayland Simplification Phase D Continue Review - 2026-04-25T19:28

## Review
Phase D is architecturally acceptable for the adjusted Linux scope:
- Linux native reservation code remains removed.
- `make run-linux` explicitly chooses X11/XWayland for stable top strip placement.
- Native Wayland failure is recorded as unsupported rather than papered over.
- Linux transparent mode remains hidden, so users are not offered an unverified mode.

## Decision
Approved for X11/XWayland Linux behavior. No native Wayland or Linux transparent support claim.

## Follow-Up
If native Wayland becomes a target again, design it as a separate sprint. Options are either a compositor-specific layer-shell path or a conservative Wayland mode that avoids absolute positioning and aggressive resize constraints.
