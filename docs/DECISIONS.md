# Project Decisions: What's Happening?

This document records the architectural and technical decisions made during the development of "What's Happening?".

## TL;DR
Linux keeps the GTK header bar disabled and uses Dart-side window sizing/constraint strategies for a thin strip. Linux shell-reservation is implemented via a `linux_dock_window_manager` Flutter plugin that sets `_NET_WM_STRUT_PARTIAL` — NOT via C++ runner code or `window_manager.dock()` (left/right only). DEC-006 supersedes DEC-005's non-reserving stance. Linux must use `LinuxResizeStrategy` (sets `resizable=true`) — GTK3 silently ignores `gtk_window_resize` on non-resizable windows (DEC-007). F-31 hide/show animation is Flutter-only (width tween); OS window resizes once per transition to avoid platform channel flooding (DEC-008). All window transitions converged onto one applier (`WindowService.applyState`) gated by one `StripController`; `ExpansionController` and the bespoke resize/reservation paths were deleted (DEC-009).

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
-   Earlier builds forced `GDK_BACKEND=x11` to recover `alwaysOnTop` and `setPosition` behavior on some Wayland desktops.

### Superseded Guidance
The sizing constraints and disabled GTK header bar remain relevant. The older `GDK_BACKEND=x11` and reserved-space panel guidance is superseded by DEC-005: Linux no longer attempts shell work-area reservation.

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

## DEC-005: Linux Uses Non-Reserving Window Behavior
**Date**: 2026-04-25
**Status**: Superseded by DEC-006 (2026-05-16)
**Authors**: Drew, Morpheus (Lead), Neo (SWE), Trin (QA)

### Context
"What's Happening?" previously used native Linux runner code to reserve desktop space:
X11 `_NET_WM_STRUT_PARTIAL` plus DOCK window type, and optional Wayland
`gtk-layer-shell` exclusive-zone setup. That path added compositor-specific
startup behavior, direct X11 linkage, optional layer-shell build detection, and
C++ parsing of "What's Happening?" settings.

The Transparent Timestrip product direction changes the goal from "push other
windows down" to "stay visible without getting in the user's way."

### Decision
Remove "What's Happening?"-owned Linux shell-reservation behavior:

1. Do not set X11 struts or DOCK window type.
2. Do not use Wayland `gtk-layer-shell` for exclusive zones.
3. Do not parse "What's Happening?" settings from the C++ runner to calculate reserved height.
4. Keep Linux transparent/pass-through behavior behind explicit real-session validation.
5. Keep normal sizing/positioning and pass-through policy in Dart strategy classes.
6. Prefer the X11/XWayland GTK backend for current Linux runs because it preserves top strip placement without shell reservation.

### Consequences
- Linux build no longer needs direct "What's Happening?"-owned X11 linkage or optional layer-shell detection.
- Linux windows are no longer expected to push maximized windows below the strip.
- Unsupported Linux transparent mode remains hidden. X11/XWayland placement is acceptable for current Linux runs, but native Wayland remains unsupported for the strip behavior: real-session testing showed compositor-managed center placement and a GTK protocol disconnect during interaction.
- Windows AppBar reservation remains unchanged.

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
On Windows, the strip's AppBar reservation worked at launch, but could become stale after the user changed DPI scaling, changed resolution, or otherwise altered display metrics while "What's Happening?" was running. Once stale, newly opened or repositioned windows could overlap the strip because the shell work area was still based on launch-time physical-pixel values.

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

## DEC-006: Linux Reserved Space via `linux_dock_window_manager` Plugin
**Date**: 2026-05-16
**Status**: Decided — supersedes DEC-005
**Authors**: Drew, Morpheus (Lead), Oracle (Docs)

### Context
DEC-005 (2026-04-25) removed all Linux shell-reservation code because the previous
implementation embedded X11 struts and `_NET_WM_WINDOW_TYPE_DOCK` in the C++ runner,
which caused a black-screen bug (Mutter re-classified the window after mapping) and
mixed startup concerns with feature behavior.

The Send-to-Back sprint (complete, 2026-05-14) reintroduced `WindowMode.reserved` as
the primary Linux/Windows mode, making it desirable to actually reserve desktop space
on Linux so maximized windows stay below the strip — mirroring Windows AppBar behavior.

**`window_manager.dock()` was evaluated and rejected.** Investigation revealed:
- On Windows, `window_manager.dock()` implements `SHAppBarMessage` for `ABE_LEFT` /
  `ABE_RIGHT` only. It does not support `ABE_TOP`, which is what the strip needs.
- On Linux, `isDockable()`, `dock()`, and `undock()` are **stubs** that return hardcoded
  values and perform no X11 operations.
- The dock API does not embed the strip into the existing system panel (GNOME Shell,
  KDE Plasma). Embedding requires platform-specific extension APIs (GNOME Shell
  extensions, Plasma widgets) entirely outside Flutter's reach. The dock API creates a
  separate independent panel, not an inset component.
- The app already bypasses `window_manager.dock()` on Windows for this same reason
  (`window_service.dart` calls `SHAppBarMessage` directly via FFI).

### Decision
Implement Linux desktop-space reservation via a dedicated Flutter platform-channel
plugin (`linux_dock_window_manager`, channel `"linux_dock_window_manager"`) registered
in the Linux runner. Only three methods are implemented:

1. `isDockable()` → `bool`: returns true if `gdk_x11_get_default_xdisplay() != null`
   (X11/XWayland), false on Wayland.
2. `dock(height: int)` → void: sets `_NET_WM_STRUT_PARTIAL` and `_NET_WM_STRUT` for
   a full-width top reservation of `height` physical pixels. No-op on Wayland.
3. `undock()` → void: clears both strut atoms. No-op on Wayland.

**Why not C++ runner code (as before):** The runner must remain startup-only. Strut
behavior must be controllable at runtime (user can switch `WindowMode` in settings).
A platform-channel plugin decouples the reservation from startup and allows `WindowService`
to call `dock()`/`undock()` whenever the mode or display geometry changes.

**Why `_NET_WM_STRUT_PARTIAL` and not `_NET_WM_WINDOW_TYPE_DOCK`:** The previous
black-screen bug was caused specifically by setting `_NET_WM_WINDOW_TYPE_DOCK` after
window mapping, which caused Mutter to re-classify and re-composite the window.
`_NET_WM_STRUT_PARTIAL` can be set or cleared safely at any time post-mapping and
does not change the window type.

`WindowService` orchestrates calls to `LinuxDockWindowManager` (Dart wrapper) in the
same locations it manages the Windows AppBar: `initialize()`, `setWindowMode()`,
`_onDisplayChangedInner()`, and `dispose()`.

### Consequences
- Linux `WindowMode.reserved` now actually reserves screen space; maximized windows
  snap below the strip on X11/XWayland.
- Wayland sessions see no change (strut is silently skipped; a log warning is emitted).
- The Linux runner remains minimal; no "What's Happening?"-specific logic in C++.
- `window_manager.dock()` is not called; the plugin is entirely additive.
- DEC-005 is superseded; the "non-reserving" stance applied only while C++ runner
  implementation was the only viable path.

## DEC-007: Linux Resize Strategy Must Set `resizable=true`
**Date**: 2026-05-18
**Status**: Decided
**Authors**: Drew, Neo (SWE)

### Context
After the `GDK_WINDOW_TYPE_HINT_DOCK` type hint was added to `my_application.cc`
(pre-map, to support reserved-space struts) expand/collapse was observed to leave a
transparent ~280px band below the collapsed strip that blocked clicks on underlying
windows. The strip also reported that expanded timeline cards were not clickable.

Investigation identified that `MacOsResizeStrategy` — the fallback for all non-Windows
platforms — calls `setResizable(false)` in `initialize()`. On GTK 3, when a window is
non-resizable, `gtk_window_resize()` is **silently ignored**; the window size is instead
pinned to the Flutter widget's preferred size. Because the geometry-hint path
(`setMinimumSize` / `setMaximumSize` → `gdk_window_set_geometry_hints`) did influence
the expand direction (min=max=expandedH forces the WM to constrain the window), expand
appeared to work. But on collapse, `gtk_window_resize(collapsedH)` was a no-op, so the
X11 window stayed at the expanded height. The 280px transparent band was the X11 window
boundary still at 340px while Flutter rendered only 60px of content.

### Decision
Create `LinuxResizeStrategy` (`resize_strategy/linux_resize_strategy.dart`) as a
Linux-specific subclass with the same expand/collapse sequence as `MacOsResizeStrategy`
but with `initialize()` calling `setResizable(true)` instead of `setResizable(false)`.

`WindowResizeStrategy.create()` is updated to return `LinuxResizeStrategy` when
`Platform.isLinux`, before falling through to `MacOsResizeStrategy` for macOS.

`setResizable(true)` is safe on Linux because:
- The window is frameless (`setAsFrameless()` removes all GTK decorations including
  resize handles), so the user has no way to manually resize it.
- The `_NET_WM_WINDOW_TYPE_DOCK` type hint discourages WM-initiated resizing.
- `setMinimumSize` / `setMaximumSize` are still called to communicate constraints
  to the WM via `WM_NORMAL_HINTS`.

### Consequences
- Expand and collapse both resize the X11 window correctly; the transparent band no
  longer blocks clicks after collapse.
- Expanded timeline cards are fully clickable.
- `MacOsResizeStrategy` is unchanged; `setResizable(false)` remains correct for macOS
  (prevents resize chrome from appearing on frameless macOS windows).
- The Linux-specific strategy file is the canonical place for any future Linux-only
  resize quirks.

## DEC-008: F-31 Hide/Show — Flutter-Only Animation, Single OS Resize Per Transition
**Date**: 2026-06-11
**Status**: Decided
**Authors**: Morpheus (Arch), Neo (SWE)

### Context
F-31 requires a smooth hide/show animation when the user collapses the timestrip to a mini
widget. The naive implementation would call `windowManager.setSize()` on every animation
frame (60fps × 300ms = 18 calls), flooding the platform channel and causing jank on Linux
(where GTK window resize is synchronous and expensive).

### Decision
The animation is Flutter-only: an `AnimationController` drives a visual width contraction
inside the still-full-size OS window. The OS window resizes exactly once per transition:

- **Hide**: Flutter `_hideAnim.reverse()` runs (full → mini visual contraction). At
  animation end, `wm.setSize(miniSize)` snaps the OS window to the mini footprint.
- **Show**: `wm.setSize(fullSize)` fires first (instant OS expand), then
  `_hideAnim.forward()` runs the mini → full reveal.

The window background is transparent, so the extra OS window area during the hide animation
is invisible to the user. The perceived animation is smooth because only Flutter paint calls
happen at 60fps — no IPC on each frame.

### Consequences
- Platform channel receives exactly 1 `setSize` call per hide or show (not 18).
- During the hide animation the OS window is still full-width; transparent background makes
  the unused area invisible.
- On Windows, the OS window snap at hide-end may produce a brief native animation frame
  that conflicts with the Flutter animation. Mitigated by moving `setSize` before the
  animation in a future fix if observed during UAT.
- `AnimationController` uses no `CurvedAnimation` wrapper (linear curve). A future sprint
  can add `CurvedAnimation(parent: _hideAnim, curve: Curves.easeInOut)` for polish without
  changing this architecture.

## DEC-009: Converge All Window Transitions onto `applyState` + `StripController`
**Date**: 2026-06-21
**Status**: Implemented (Windows-validated; Linux/macOS show/hide deferred to those systems)
**Authors**: Neo (SWE), Drew

### Context
Window transitions had each grown their own bespoke path: init used `applyState`, but
show/hide used `resizeToFull/MiniStrip` + `onShow/HideStrip`, expand/collapse used
`ExpansionController → performResize → _doExpand/_doCollapse`, refresh used a `reassertAppBar`
band-aid, and display/font changes had their own re-resize. Each re-implemented reservation
and positioning slightly differently, so the same "strip lands below its own strut" bug kept
recurring once per path ("works here / breaks there"). Root cause: a path that sized the
window *before* reserving the AppBar band (or never re-pinned to the reserved origin) let
Windows relocate the AppBar window into the work area.

### Decision
1. **One applier.** `WindowService.applyState(StripState)` is the single source of OS geometry:
   reserve the work-area band FIRST (`applyReservation`), then apply size + position AT the
   returned reserved origin. Every transition routes through it.
2. **One gate.** `StripController` (a `ChangeNotifier`, `StripState` owner, serialized by an
   `AsyncGate` — one-slot, last-wins) is the single entry point for user-driven transitions
   (`collapse/expand/hide/show/reapply`). `ExpansionController` folded into it.
3. **No new mechanism for the OS relocation.** An `onWindowMoved` re-pin was proposed and
   *rejected* after the manual gate proved that simply making every path take the init
   sequence (reserve→size→present) eliminated the drift — the inverted order + missing
   present was the real cause, not an intrinsic `ABM_REMOVE→ABM_NEW` relocation.

### Consequences
- Deleted: `ExpansionController`, `ResizeExecutor`, `WindowServiceResizeExecutor`,
  `PhysicalWindowState`, `performResize`, `_doExpand/_doCollapse`. Net ≈ −230 lib lines; the
  dead-code + complexity lints pass for the first time.
- `showStrip`/`hideStrip` remain as the per-platform transition primitives the controller
  dispatches to (Windows = `applyState` + present; Linux base = `resizeToFull/Mini` +
  `onShow/HideStrip` for its strut, **not yet converged** — deferred to a Linux/macOS session).
- Validated on Windows: every hide/show/expand/collapse cycle holds `(0,0)` through delayed
  GEO probes. See LESSONS L-005/L-006 and [ARCH.md §6](ARCH.md#6-window-strategy).
- `docs/EXPANSION_CONTROLLER.md` is superseded (banner added).
