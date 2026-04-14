# Project Decisions: Happening

This document records the architectural and technical decisions made during the development of Happening.

## TL;DR
Critical fixes for the "fat background" bug on Linux (X11/Wayland) require disabling GTK Header Bars, performing manual DPR-to-logical pixel conversion for `window_manager`, and applying rigid min/max size constraints.

## DEC-001: Linux Window Height Constraint (Wayland/GTK)
**Date**: 2026-02-26
**Status**: Decided
**Authors**: Neo (SWE), Morpheus (Lead)

### Context
The "Timeline Strip" requires a very small window height (e.g. 30px). On Linux desktop (GNOME/Wayland using `GDK_BACKEND=x11`), initial implementation resulted in a "fat background" (~720px tall) despite Flutter-level constraints.

### Decision
To achieve a thin, stable strip height on Linux, we must bypass several OS-level and framework-level defaults:

1.  **Disable GTK Header Bar**: By default, GTK injects a Header Bar into every GtkWindow. These have a minimum height enforced by the system theme. We must force `use_header_bar = FALSE` in `app/linux/runner/my_application.cc`.
2.  **DPR-Aware Logical Sizing**: `window_manager` expects logical pixels. `screen_retriever` on Linux returns physical pixels. We must divide the physical screen width and our desired physical height (e.g. 30px) by the Device Pixel Ratio (DPR) to provide a valid logical size to the window manager.
3.  **Rigid Constraints**: Both `minimumSize` and `maximumSize` in `WindowOptions` (and post-show callbacks) must be set to the target size to prevent the compositor from resetting the window to a default "safe" height.
4.  **C++ Window Floor**: Set `gtk_window_set_default_size` in C++ to a very small value (e.g. 1px or 30px) to ensure the initial window creation doesn't enforce a floor.

### Consequences
-   The window is now correctly sized to 30px.
-   The C++ runner is no longer a "vanilla" Flutter template; it contains platform-specific hacks.
-   `GDK_BACKEND=x11` is required to ensure `alwaysOnTop` and `setPosition` work reliably on modern Wayland compositors.

## DEC-002: Hover Card Alignment and Sizing
**Date**: 2026-03-01
**Status**: Decided
**Authors**: Neo (SWE), Morpheus (Lead), Trin (QA)

### Context
User feedback indicated that centered hover cards felt "detached" from the event block they described. For long or active events, the card could appear far from the mouse or the visual start of the event.

### Decision
1.  **Left-Alignment**: The hover card MUST align its left edge with the left edge of the visible portion of the event block.
2.  **Dynamic Width**: The card MUST be at least as wide as the visible portion of the event block, but no less than 260px (default width) to accommodate its content.

### Consequences
-   The card feels visually "attached" to the event.
-   The `_cardLeft` logic in `TimelineStrip` must be updated to use the visible start of the event.
-   `HoverDetailOverlay` must accept a `minWidth` parameter.

## DEC-003: ExpansionBehavior Pure Logic Interface
**Date**: 2026-03-02
**Status**: Decided
**Authors**: Morpheus (Lead), Neo (SWE)

### Context
Coordination between event hit-testing, mouse coordinates, and window expansion state in `TimelineStrip` was becoming complex and prone to race conditions (especially on Linux/GTK). We needed a way to deterministically calculate the "intended" state of the window (Expanded/Collapsed) without relying on asynchronous OS state or complex widget state flags.

### Decision
1.  **Pure Functional Interface**: Create a stateless `ExpansionBehavior` class (pure Dart) that calculates the `ExpansionState` (enum) based solely on coordinate inputs and a simple `isSettingsOpen` flag.
2.  **Zero Dependencies**: The behavior logic must NOT depend on Flutter (`Size`, `Offset`, etc.), `CalendarEvent`, or `WindowService`. It uses primitive doubles and a simple `EventXBounds` data class.
3.  **Coordinate-Based State**:
    -   If `isSettingsOpen` is true -> `Expanded`.
    -   If `mouseY >= stripHeight` (Interaction Zone) -> `Expanded`.
    -   If `mouseX` hits an `EventXBounds` -> `Expanded`.
    -   Otherwise -> `Collapsed`.
4.  **Service Ownership**: `WindowService` remains the single source of truth for the *actual* OS window state, while the widget uses `ExpansionBehavior` to express its *intent*.

### Consequences
-   Hover logic is now 100% unit-testable without a Flutter environment.
-   `TimelineStrip` is simplified; it merely feeds coordinates to the behavior and forwards the result to `WindowService`.
-   Race conditions between mouse-enter/exit and async window resizing are eliminated by having a deterministic "intended" state.

## DEC-004: Refresh Screen Size and DPI on Flutter Metrics Changes
**Date**: 2026-04-14
**Status**: Decided
**Authors**: Morpheus (Lead), Neo (SWE), Oracle (Docs)

### Context
On Windows, the strip's AppBar reservation worked at launch, but could become stale after the user changed DPI scaling, changed resolution, or otherwise altered display metrics while Happening was running. Once stale, newly opened or repositioned windows could overlap the strip because the shell work area was still based on launch-time physical-pixel values.

### Decision
`WindowService` must observe Flutter display metric changes via `WidgetsBindingObserver.didChangeMetrics()` and refresh its cached display state from live APIs:

1.  Read the current DPR from `window_manager.getDevicePixelRatio()`.
2.  Read the current primary display width from `screen_retriever.getPrimaryDisplay().size.width`.
3.  If either value changed, update `_dpr` and `_screenWidth`.
4.  On Windows, re-run `_reserveCollapsedSpace()` so `ABM_QUERYPOS`/`ABM_SETPOS` reassert the AppBar band using updated physical-pixel values, then reposition the window from trusted `rcTop / dpr`.
5.  Re-run the current resize state (`_doExpand()` or `_doCollapse()`) so the visible Flutter window matches the new display dimensions.

Manual refresh also calls `WindowService.reassertAppBar()` from the strip refresh button. That path performs a full `ABM_REMOVE` -> `ABM_NEW` -> `_reserveCollapsedSpace()` cycle as a recovery tool when another app overlaps the strip.

### Consequences
-   Display scaling and screen width changes no longer require restarting the app.
-   The Windows AppBar rect is recalculated in physical pixels after DPI changes.
-   The refresh button now recovers both calendar data and stale Windows work-area reservations.
-   A periodic AppBar reassert timer is not part of the solution; it caused width shrinkage in testing and was removed.
