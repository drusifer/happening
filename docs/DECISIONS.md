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
