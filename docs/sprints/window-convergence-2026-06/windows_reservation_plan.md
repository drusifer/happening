# Plan: Windows Screen Reservation Integration

**Goal**: Port the working screen reservation logic from `simple_main.dart` to the main app, ensuring dynamic height support.

## Tasks

### 1. Entry Point Alignment (main.dart)
*   [ ] Call `windowService.initialize()` before `runApp`.
*   [ ] Set Windows-specific flags: `setAsFrameless`, `setHasShadow(false)`.
*   [ ] Set initial alignment (e.g., Top-Center).

### 2. Dynamic Height Sync (TimelineStrip)
*   [ ] Add `_windowService.updateTargetHeights()` call inside `_updateHeights()`.
*   [ ] Ensure `WindowService` is notified immediately on font size changes from `SettingsService`.

### 3. Service Implementation (WindowService)
*   [ ] Implement `updateTargetHeights(collapsed, expanded)`.
*   [ ] On Windows, use `window_manager` to update the "reserved" screen area (AppBar/Dock behavior) based on the collapsed height.

## Verification
*   [ ] Verify other maximized windows do not overlap the collapsed strip.
*   [ ] Verify strip expands downward/upward without shifting the reserved desktop area.
*   [ ] Verify font size changes live-update the reserved area.