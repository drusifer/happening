# Linux Click-Through Research — 2026-04-26

## Problem

`window_manager` v0.5.1 does not implement `setIgnoreMouseEvents` on Linux.  
The Dart call throws `MissingPluginException` which the current code silently swallows.  
Transparent mode is visual-only; the window still receives all pointer events.

## Why `window_manager` Can't Help Here

The Linux plugin (`window_manager_plugin.cc`) falls through to `FlMethodNotImplementedResponse`
for `setIgnoreMouseEvents`.  Only macOS (Swift `NSWindow.ignoresMouseEvents`) and
Windows (`WS_EX_TRANSPARENT | WS_EX_LAYERED` via `SetWindowLong`) are implemented.

## Native Linux Options

### Option A — GDK Input Shape  ★ Recommended ★

```c
// Enable click-through:
GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
cairo_region_t* empty = cairo_region_create();          // empty = no input area
gdk_window_input_shape_combine_region(gdk_win, empty, 0, 0);
cairo_region_destroy(empty);

// Disable click-through:
gdk_window_input_shape_combine_region(gdk_win, NULL, 0, 0);  // NULL = full window
```

**How it works under the hood:**
- **X11**: GDK calls `XShapeCombineRegion(dpy, xid, ShapeInput, ...)` via the SHAPE extension.
  An empty input shape means no part of the window accepts pointer events; the compositor
  delivers them to the next window in the Z-order.
- **XWayland**: X11 SHAPE calls do NOT propagate to Mutter's routing layer.
  Mutter delivers clicks to the XWayland surface before checking any X11 input shape.
  Confirmed BROKEN on Mutter/XWayland (2026-04-26 smoke).
- **Native Wayland (GDK Wayland backend)**: GDK maps this call to
  `wl_surface.set_input_region(NULL_REGION)`.  Most modern compositors (GNOME, KDE/KWin,
  Sway, Hyprland) respect this.  Not tested on native Wayland.

**Pros:** GDK3 API — no direct X11 or Wayland linkage required.  Works with the existing
GTK3 runner.  Clean enable/disable toggle.

**Cons:** Must be called after the GdkWindow is realized and mapped.  A Dart MethodChannel
call (button press after window shown) satisfies this timing naturally.

### Option B — Direct Xlib/XShape

```c
#include <X11/extensions/shape.h>
Display* dpy   = GDK_WINDOW_XDISPLAY(gdk_win);
Window   xid   = GDK_WINDOW_XID(gdk_win);
XShapeCombineRectangles(dpy, xid, ShapeInput, 0, 0, NULL, 0, ShapeSet, 0);
```

This is the raw X11 call that Electron uses.  GDK Option A calls this internally so
Option A is strictly preferable — same result, no extra linkage.

### Option C — Wayland `wl_surface.set_input_region` (direct)

Requires `libwayland-client` and GDK Wayland backend internals to get the `wl_surface`.
More invasive than Option A and only needed if the GDK abstraction fails on native Wayland.

### Option D — Extend `window_manager`

File an upstream PR or fork `window_manager` to add a Linux `setIgnoreMouseEvents`
implementation using the GDK input-shape approach.  This is the cleanest long-term path
but requires publishing/maintaining a fork.

## Transparency on Linux (Working)

ARGB compositing works when:
1. `gdk_screen_get_rgba_visual(screen)` returns a non-null visual AND the compositor
   is running (nearly always true on modern GNOME/KDE/etc).
2. `gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual)` is called BEFORE realize.
3. `gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE)` is set.
4. `fl_view_set_background_color(view, {.alpha=0.0})` is set so Flutter does not paint
   a solid black background over the transparent GTK surface.

The `happening` main app already does steps 2–4 via the ARGB background approach adopted
in earlier sprints.

## Test App

Location: `tools/click_through_test/`

### What it contains

- **`linux/runner/click_through_plugin.cc/.h`** — inline Flutter plugin exposing:
  - `setIgnoreMouseEvents({ignore: bool})` via GDK input shape
  - `getDisplayServer()` — returns `"x11"`, `"xwayland"`, or `"wayland"`
- **`linux/runner/my_application.cc`** — ARGB transparent window, always-on-top,
  registers the custom plugin.
- **`lib/main.dart`** — toggle UI with live log of each call result.

### Run it

```bash
make run-click-test          # debug hot-reload mode (GDK_BACKEND=x11)
make build-click-test        # release bundle
```

Or directly:
```bash
cd tools/click_through_test
GDK_BACKEND=x11 flutter run -d linux
```

### Confirmed results per backend (smoke-tested 2026-04-26)

| Backend     | Transparency | Click-through via GDK input shape |
|-------------|-------------|-----------------------------------|
| X11 (pure)  | ✅           | ✅ (XShape, no compositor in the way) |
| XWayland    | ✅           | ❌ Mutter ignores X11 input shapes for Wayland routing |
| Wayland     | ✅           | ✅ CONFIRMED — `wl_surface.set_input_region` honored by Mutter |

**Root cause of XWayland failure**: Mutter routes clicks at the Wayland surface level.
An X11 app in XWayland is a single Wayland surface — Mutter delivers the click to it
without checking the X11 SHAPE input region, which only affects X11-internal event routing.

**Why native Wayland works**: The GDK Wayland backend translates
`gdk_window_input_shape_combine_region(empty)` → `wl_surface.set_input_region(empty)`.
Mutter checks this before routing, so clicks fall through to the surface below.

**Additional fix required**: Must also set `GDK_WINDOW_TYPE_HINT_NOTIFICATION` and
`gtk_window_set_accept_focus(FALSE)` before show — otherwise the WM still gives the
window focus on nearby clicks even when input region is empty.

## Architecture Implication for `happening`

Click-through **requires native Wayland** (`GDK_BACKEND=wayland`).
The main app currently forces `GDK_BACKEND=x11` for `window_manager` positioning.
Native Wayland has no absolute window positioning without layer-shell.

**Therefore: Linux transparent/click-through mode requires gtk-layer-shell.**

Scope of that work:
1. Re-introduce `gtk-layer-shell` (optional dependency, CMake-gated) to `app/linux/`.
2. On Wayland: use layer-shell for position + anchor; use GDK input shape for click-through.
3. On X11 (pure, no compositor): use existing `window_manager` + GDK input shape.
4. On XWayland (Wayland desktop): currently no click-through — notify user; fallback to reserved mode.

## Integration Path for `happening`

The previous integration path (just adding the plugin to the X11 runner) is **insufficient**
because click-through doesn't work under XWayland. The full path is:

1. Decide whether to support native Wayland in a sprint (requires layer-shell reintroduction).
2. If yes: add `click_through_plugin.cc/.h` to `app/linux/runner/`.
3. Add `GDK_WINDOW_TYPE_HINT_NOTIFICATION` + `accept_focus=FALSE` before show for transparent mode.
4. Wire `LinuxWindowInteractionStrategy.setPassThrough` to the GDK input shape channel.
5. Gate `linuxTransparentSupported = true` only when running on native Wayland with layer-shell.

## Key Constraint

`gdk_window_input_shape_combine_region` must be called on a mapped (shown) window.
The Dart MethodChannel toggle is always called post-show so timing is safe in production.
Do NOT call it during C++ initialization before `first_frame_cb`.
