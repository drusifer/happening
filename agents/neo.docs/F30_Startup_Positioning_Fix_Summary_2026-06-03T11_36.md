# F-30 Startup Monitor Positioning Fix Summary — 2026-06-03T11:36

## Overview
Fixed the startup behavior of the application where restarting it under a multi-monitor layout initially painted it on the primary display (even if the user had persisted their choice on the secondary display). 

## Implementation Details
- **Active Monitor Positioning**: Modified `WindowService.initialize` inside `app/lib/core/window/window_service.dart` to position the window at `_activeDisplay` (via `_strategy.moveToDisplay`) inside the `waitUntilReadyToShow` callback.
- **Timing and Sequence**: By performing this move before calling `beforeShow` and `performShow`, we ensure that:
  - The window is positioned at the correct monitor before the window manager reveals it, avoiding any startup flicker.
  - Platform-specific space reservations (like the Windows AppBar bounding box reservation or the Linux struts reservation) correctly target the chosen monitor's layout coordinates, preventing reservations from leaking onto the primary monitor at startup.
- **Verification Tests**:
  - Added a unit test `initialize positions window on the active display work area origin` to `window_service_test.dart`.
  - Stubbed a custom displays layout containing a secondary display info with an offset (`Offset(1920, 0)`).
  - Verified that calling `WindowService.initialize` triggers `mockWM.setPosition` at `Offset(1920, 0)` during initialization.
  - Full test suite: **427 passing**, 1 pre-existing failing golden.
  - Codebase analysis and metrics checks: **Clean (exit 0)**.

## Handoff & Next Steps
- Handed off to **Trin** for final verification and UAT signature.
- Handoff to **Oracle** for F-30 documentation update.
