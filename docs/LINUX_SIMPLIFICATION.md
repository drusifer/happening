# Linux Platform Simplification

## Context

The Linux implementation accumulated platform-specific C++ and Dart code over several sprint cycles:
- A custom GTK plugin for click-through / input-shape (never reliably functional)
- An invalid-constraint resize trick to force GTK to honor `setSize()`
- XWayland detection infrastructure gating transparent mode availability

All of this was written before the project settled on **XWayland** as the only supported Linux display backend and dropped transparent/click-through mode entirely (see Send-to-Back sprint). Linux now shares the same code path as macOS via `MacOsResizeStrategy` and `ReservedWindowInteractionStrategy`.

## Goal

Remove all Linux-specific workarounds and let Linux share the same code paths as macOS and Windows, using only the `window_manager` Flutter API.

---

## What Is Removed

### C++ — custom click-through plugin

| File | Reason removed |
|------|---------------|
| `app/linux/runner/click_through_plugin.cc` | Click-through feature dropped entirely (Send-to-Back replaces it) |
| `app/linux/runner/click_through_plugin.h` | Same |

### Dart — Linux-only abstractions

| File | Reason removed |
|------|---------------|
| `app/lib/core/linux/click_through_channel.dart` | Abstract interface for custom C++ channel |
| `app/lib/core/linux/linux_click_through_channel.dart` | Concrete channel to the C++ plugin |
| `app/lib/core/linux/click_through_capability.dart` | XWayland detection — no longer needed |
| `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart` | Replaced by macOS strategy |
| `app/lib/core/window/resize_strategy/linux_resize_strategy.dart` | Replaced by macOS strategy |

### Build wiring

- `CMakeLists.txt`: remove `click_through_plugin.cc` from sources and `LAYER_SHELL` link block
- `my_application.cc`: remove `#include "click_through_plugin.h"` and its manual registration call

---

## What Stays

### `my_application.cc` — RGBA visual setup

The GTK RGBA visual setup is **kept**:

```c
GdkScreen* screen = gtk_widget_get_screen(GTK_WIDGET(window));
GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
if (rgba_visual != nullptr) {
  gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual);
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
}
```

`window_manager.setBackgroundColor(Colors.transparent)` operates at the Flutter surface level (the `FlView` widget). It does not configure alpha compositing at the GTK/compositor level. The RGBA visual must still be set at window creation time in C++ for the window to be visually transparent.

`first_frame_cb` (defer window show until Flutter has content) is also kept — it prevents a black-flash on startup.

The `#ifdef LAYER_SHELL_AVAILABLE` block is removed — layer-shell is only relevant for native Wayland, which is not supported.

---

## What Changes

### Resize strategy — Linux uses macOS path

`LinuxResizeStrategy` used an invalid-constraint trick:

```
Expand: setSize(advisory) → setMinimumSize(>max, forces GTK) → setMaximumSize → setSize(fresh)
```

This was developed when `setSize()` was believed to be advisory/ignored on GTK. Log analysis (`build/bad.out`) shows `setSize()` **does** work on XWayland — the window grows physically within ~42ms of the call. The invalid-constraint sequence adds ~200ms of unnecessary delay and is the root cause of the expand flicker.

Linux now uses `MacOsResizeStrategy`:

```
Expand:   setMaximumSize(target) → setSize(target) → setMinimumSize(target)
Collapse: setMinimumSize(target) → setMaximumSize(target) → setSize(target)
```

`WindowResizeStrategy.create()` removes the Linux branch; `Platform.isLinux` falls through to `MacOsResizeStrategy`.

### Interaction strategy — Linux uses Reserved (Send-to-Back sprint, 2026-05-14)

`LinuxWindowInteractionStrategy` routed through the custom C++ channel. After the Linux simplification sprint (2026-05-11), Linux temporarily used `MacOsWindowInteractionStrategy`.

The Send-to-Back sprint renamed `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy` and routes both Linux and Windows through it. `WindowInteractionStrategy.create()` routes `Platform.isLinux` → `ReservedWindowInteractionStrategy`. The strategy hierarchy is now: `BaseWindowInteractionStrategy` → `MacOsWindowInteractionStrategy` (macOS) / `ReservedWindowInteractionStrategy` (Linux + Windows).

Transparent/pass-through mode and its `linuxTransparentSupported` flag are removed entirely. Click-through is replaced by **Send-to-Back**: `setAlwaysOnTop(false)` + `blur()` on press; `setAlwaysOnTop(true)` on auto-restore after 10s. No platform-specific code required.

---

## File Map After Change

```
app/linux/runner/
  main.cc                          (unchanged)
  my_application.cc                (simplified — no plugin registration, no layer-shell)
  my_application.h                 (unchanged)
  CMakeLists.txt                   (simplified — no click_through_plugin source)

app/lib/core/
  linux/                           (directory deleted entirely)
  window/
    resize_strategy/
      window_resize_strategy.dart  (Linux branch removed)
      macos_resize_strategy.dart   (unchanged — now also used for Linux)
      windows_resize_strategy.dart (unchanged)
      linux_resize_strategy.dart   (deleted)
    interaction_strategy/
      window_interaction_strategy.dart          (Linux + Windows → ReservedWindowInteractionStrategy)
      base_window_interaction_strategy.dart     (new — sendToBack/restoreToFront impl)
      macos_window_interaction_strategy.dart    (extends Base; macOS only)
      reserved_window_interaction_strategy.dart (extends Base; Linux + Windows; renamed from windows_)
      linux_window_interaction_strategy.dart    (deleted)
      windows_window_interaction_strategy.dart  (deleted — renamed to reserved_)

app/lib/main.dart                  (XWayland detection removed)
```

---

## Why Not Remove the Resize Constraint Calls Entirely

The macOS strategy still uses `setMinimumSize` / `setMaximumSize` around `setSize`. These are kept for two reasons:

1. On macOS, size constraints are enforced by the OS — without them, the window can be resized by the user
2. The sequence `setMax → setSize → setMin` ensures constraints are always valid before and after the resize, preventing GTK/macOS from clamping the `setSize` call

The constraint calls do not cause the flicker on Linux because they follow `setSize` (expand) or precede `setSize` (collapse) — the window grows/shrinks at the right moment relative to the Flutter layout update.
