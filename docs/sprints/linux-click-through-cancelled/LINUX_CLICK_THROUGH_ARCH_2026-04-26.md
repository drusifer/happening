# Linux Click-Through Architecture — 2026-04-26

**Status:** Approved (Smith Gate 2) + Dart abstraction design added
**Sprint:** Linux Transparent Click-Through (CT-01 – CT-05)
**Morpheus version:** 1.1

---

## Problem Summary

`window_manager.setIgnoreMouseEvents()` is not implemented on Linux. The GDK input-shape API (`gdk_window_input_shape_combine_region`) works on native Wayland via `wl_surface.set_input_region`. It does NOT work on XWayland because Mutter routes clicks at the Wayland surface level before checking X11 input shapes. Native Wayland also requires `gtk-layer-shell` for absolute positioning because `window_manager` x/y positioning calls fail on native Wayland.

---

## Dart Abstraction Design

The click-through feature is split into three layers. The abstraction boundary is `ClickThroughChannel` — everything above it is pure Dart; everything below is C++/GDK.

### Layer 1 — Native Bridge Interface

```
ClickThroughChannel (abstract)
  ├── LinuxClickThroughChannel   — GDK MethodChannel impl (Linux only)
  └── NullClickThroughChannel    — no-op (non-Linux, tests)
```

```dart
// app/lib/core/linux/click_through_channel.dart
abstract class ClickThroughChannel {
  Future<void> setPassThrough(bool enabled);
  Future<String> getDisplayServer();      // "wayland" | "xwayland" | "x11"
  Future<bool>   isLayerShellAvailable();
}

class NullClickThroughChannel implements ClickThroughChannel {
  const NullClickThroughChannel();
  @override Future<void>   setPassThrough(bool _) async {}
  @override Future<String> getDisplayServer()       async => 'unknown';
  @override Future<bool>   isLayerShellAvailable()  async => false;
}
```

```dart
// app/lib/core/linux/linux_click_through_channel.dart
class LinuxClickThroughChannel implements ClickThroughChannel {
  static const _ch = MethodChannel('com.happeningapp/click_through');

  @override
  Future<void> setPassThrough(bool enabled) =>
      _ch.invokeMethod('setIgnoreMouseEvents', {'ignore': enabled});

  @override
  Future<String> getDisplayServer() async =>
      await _ch.invokeMethod<String>('getDisplayServer') ?? 'unknown';

  @override
  Future<bool> isLayerShellAvailable() async =>
      await _ch.invokeMethod<bool>('isLayerShellAvailable') ?? false;
}
```

### Layer 2 — Detection Result (Value Object)

```dart
// app/lib/core/linux/click_through_capability.dart
class ClickThroughCapability {
  const ClickThroughCapability({
    required this.supported,
    required this.displayServer,
  });

  final bool   supported;
  final String displayServer;

  static const unsupported = ClickThroughCapability(
    supported: false, displayServer: 'unknown',
  );

  static Future<ClickThroughCapability> detect(ClickThroughChannel ch) async {
    final server = await ch.getDisplayServer();
    if (server != 'wayland') {
      return ClickThroughCapability(supported: false, displayServer: server);
    }
    final hasShell = await ch.isLayerShellAvailable();
    return ClickThroughCapability(supported: hasShell, displayServer: server);
  }
}
```

### Layer 3 — Strategy Integration

`LinuxWindowInteractionStrategy` takes a `ClickThroughChannel` (not a `WindowManager`) and calls `setPassThrough` directly. No `try/catch` for `MissingPluginException` — the channel abstraction owns error handling.

```dart
class LinuxWindowInteractionStrategy extends WindowInteractionStrategy {
  LinuxWindowInteractionStrategy({
    required ClickThroughChannel channel,
    required bool supportsTransparentPassThrough,
  }) : _channel = channel, ...

  Future<void> _applyPassThrough(bool enabled) =>
      _channel.setPassThrough(enabled);
}
```

`main()` detection becomes a clean two-liner:
```dart
final channel = Platform.isLinux
    ? LinuxClickThroughChannel()
    : const NullClickThroughChannel();
final capability = await ClickThroughCapability.detect(channel);
// capability.supported → replaces linuxTransparentSupported bool
// capability.displayServer → logged for diagnostics
```

### Why Not "ClickThroughWidget"

`Widget` in Flutter is a UI component. This complexity is native bridge + state, not UI. The right seam is the abstract interface. A `ClickThroughScope` (`InheritedNotifier`) would be added only if multiple widgets need to react to pass-through state — not currently required.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│ Dart Layer                                          │
│                                                     │
│  main() ──async──► ClickThroughCapability.detect()  │
│    channel.getDisplayServer() → "wayland" / ...     │
│    channel.isLayerShellAvailable() → bool           │
│    capability.supported → linuxTransparentSupported │
│                                                     │
│  LinuxWindowInteractionStrategy(channel: ...)       │
│    setFocused(bool) → channel.setPassThrough        │
│    setPassThrough(bool) → channel.setPassThrough    │
│                                                     │
│  TimelineStrip → HoverFocusController               │
│    onEnter → 300ms timer → setFocused(true)         │
│    onExit  → cancel/setFocused(false)               │
│  Hotkey → setFocused(true/false)  [secondary path]  │
└─────────────────────────────────────────────────────┘
           MethodChannel: com.happeningapp/click_through
┌─────────────────────────────────────────────────────┐
│ C++ Layer (app/linux/runner/)                       │
│                                                     │
│  click_through_plugin.cc                            │
│    setIgnoreMouseEvents(ignore: bool)               │
│      → gdk_window_input_shape_combine_region        │
│      → gtk/gdk_window_set_accept_focus              │
│      → gdk_display_flush + gdk_window_invalidate    │
│    getDisplayServer() → "wayland" | "xwayland" | "x11"│
│    isLayerShellAvailable() → bool (compile-time)    │
│                                                     │
│  my_application.cc                                  │
│    On Wayland + layer-shell: anchor before show      │
│    On X11/XWayland: existing GDK_BACKEND=x11 path   │
└─────────────────────────────────────────────────────┘
```

---

## Phase Breakdown

### Phase A — Detection + Plugin Port

**Goal:** Port the click-through plugin from the test app to the main app and wire the Dart channel. Update `LinuxWindowInteractionStrategy` to use the real native channel. Replace the smoke flag in `main()` with runtime backend detection.

**Files changed:**

| File | Change |
|---|---|
| `app/linux/runner/click_through_plugin.cc` | New — ported from test app. Channel renamed to `com.happeningapp/click_through`. Debug `g_print` removed except for errors. |
| `app/linux/runner/click_through_plugin.h` | New — header, same interface as test app. |
| `app/linux/runner/my_application.cc` | Register click-through plugin via `click_through_plugin_register_with_registrar`. |
| `app/linux/runner/CMakeLists.txt` | Add `click_through_plugin.cc` to `add_executable` sources. |
| `app/lib/core/linux/linux_click_through_channel.dart` | New — thin Dart `MethodChannel` wrapper. Methods: `setIgnoreMouseEvents(bool)`, `getDisplayServer()`. |
| `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart` | Replace `_wm.setIgnoreMouseEvents()` with `_channel.setIgnoreMouseEvents()`. Constructor takes `LinuxClickThroughChannel` instead of `WindowManager`. |
| `app/lib/main.dart` | Replace `_linuxTransparentSmokeEnabled()` with async `_detectLinuxTransparentSupport()` calling the channel. Smoke flag logic removed. |
| `app/test/core/window/window_interaction_strategy_test.dart` | Update Linux strategy mocks for new channel interface. |

**`LinuxClickThroughChannel` interface:**
```dart
class LinuxClickThroughChannel {
  static const _channel = MethodChannel('com.happeningapp/click_through');

  Future<void> setIgnoreMouseEvents(bool ignore) async { ... }
  Future<String> getDisplayServer() async { ... }  // "wayland" | "xwayland" | "x11"
}
```

**`main.dart` detection (Phase A):**
```dart
Future<bool> _detectLinuxTransparentSupport() async {
  if (!Platform.isLinux) return false;
  final channel = LinuxClickThroughChannel();
  final backend = await channel.getDisplayServer();
  // Phase A: backend only (layer-shell check added in Phase B)
  return backend == 'wayland';
}
```

**`LinuxWindowInteractionStrategy` after Phase A:**
```dart
class LinuxWindowInteractionStrategy extends WindowInteractionStrategy {
  LinuxWindowInteractionStrategy({
    required LinuxClickThroughChannel channel,
    required bool supportsTransparentPassThrough,
  }) : _channel = channel, _supportsTransparentPassThrough = supportsTransparentPassThrough;

  Future<void> _trySetIgnoreMouseEvents(bool enabled) async {
    // No try/catch — plugin is always present on Linux now.
    await _channel.setIgnoreMouseEvents(enabled);
  }
}
```

**Capability gate (Phase A):**
- `linuxTransparentSupported = (backend == 'wayland')` — true only when the GDK Wayland backend is active.
- Phase B tightens this to also require layer-shell.

---

### Phase B — Layer-Shell Positioning

**Goal:** Add optional `gtk-layer-shell` dependency. On native Wayland, use layer-shell to anchor the strip to the top of the primary monitor (replacing `window_manager` x/y calls). Tighten capability gate to require both native Wayland AND layer-shell.

**Files changed:**

| File | Change |
|---|---|
| `app/linux/CMakeLists.txt` | Add optional `pkg_check_modules(LAYER_SHELL IMPORTED_TARGET gtk-layer-shell-0)`. If found: `target_link_libraries(...PkgConfig::LAYER_SHELL)` + `add_definitions(-DLAYER_SHELL_AVAILABLE=1)`. |
| `app/linux/runner/click_through_plugin.cc` | Add `isLayerShellAvailable()` method — returns `true` if `LAYER_SHELL_AVAILABLE` is defined, `false` otherwise. |
| `app/linux/runner/my_application.cc` | `#ifdef LAYER_SHELL_AVAILABLE`: if backend is Wayland, call `gtk_layer_shell_init_for_window`, set anchor top, exclusive zone equal to window height. This runs before `gtk_widget_show`. |
| `app/lib/core/linux/linux_click_through_channel.dart` | Add `isLayerShellAvailable()` method. |
| `app/lib/main.dart` | `_detectLinuxTransparentSupport()` extended to also check `isLayerShellAvailable()`. |

**`main.dart` detection (Phase B):**
```dart
Future<bool> _detectLinuxTransparentSupport() async {
  if (!Platform.isLinux) return false;
  final channel = LinuxClickThroughChannel();
  final backend = await channel.getDisplayServer();
  if (backend != 'wayland') return false;
  return await channel.isLayerShellAvailable();
}
```

**Layer-shell anchor (in `my_application.cc`):**
```c
#ifdef LAYER_SHELL_AVAILABLE
#include <gtk-layer-shell/gtk-layer-shell.h>

// Called after window creation, before gtk_widget_show:
if (GDK_IS_WAYLAND_DISPLAY(gdk_display_get_default())) {
  gtk_layer_shell_init_for_window(window);
  gtk_layer_shell_set_layer(window, GTK_LAYER_SHELL_LAYER_TOP);
  gtk_layer_shell_set_anchor(window, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
  gtk_layer_shell_set_anchor(window, GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
  gtk_layer_shell_set_anchor(window, GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
  gtk_layer_shell_set_exclusive_zone(window, 1);  // 1px; Dart resizes to full height on expand
}
#endif
```

**Fallback behavior when layer-shell is absent:**
- `isLayerShellAvailable()` returns `false` → `linuxTransparentSupported = false`.
- App launches in reserved mode. Settings panel shows CT-04 inline explanation.
- No error dialog, no crash.

---

### Phase C — Integration + Polish

**Goal:** Hover-to-focus trigger, CT-04 settings panel inline text, smoke test coverage.

**Files changed:**

| File | Change |
|---|---|
| `app/lib/features/timeline/timeline_strip.dart` | Wrap with `MouseRegion`, wire `onEnter`/`onExit` to new `HoverFocusController`. |
| `app/lib/features/timeline/focus/hover_focus_controller.dart` | New — 300ms `Timer` on enter, calls `windowService.setFocused(true)`. Cancel + `setFocused(false)` on exit. |
| `app/lib/features/timeline/settings_panel.dart` | When `!linuxTransparentSupported` on Linux: show inline text below transparent option: *"Transparent mode is not available in this session. Start Happening from a native Wayland session to enable it."* |
| `app/test/features/timeline/timeline_strip_test.dart` | Add hover-focus tests (stub controller). |
| `app/test/core/settings/settings_panel_test.dart` | Add CT-04 inline text visibility test. |

**`HoverFocusController` design:**
```dart
class HoverFocusController {
  static const _delay = Duration(milliseconds: 300);
  Timer? _timer;
  bool _hovering = false;

  void onEnter(WindowService windowService) {
    _hovering = true;
    _timer ??= Timer(_delay, () { windowService.setFocused(true); _timer = null; });
  }

  void onExit(WindowService windowService) {
    _hovering = false;
    _timer?.cancel(); _timer = null;
    windowService.setFocused(false);
  }

  void dispose() { _timer?.cancel(); }
}
```

**Focus trigger precedence:**
- Hover (300ms delay) → primary path; covers CT-01/CT-03
- Global hotkey (Ctrl+Shift+H on Linux) → secondary/explicit path; unchanged from TT-D2
- Both call `WindowService.setFocused(true/false)` → `LinuxWindowInteractionStrategy.setFocused()` → channel

**CT-04 inline text positioning:**
- Below the transparent mode radio button/toggle.
- Always visible when disabled (not tooltip-only). Text: *"Transparent mode is not available in this session. Start Happening from a native Wayland session to enable it."*
- No technical jargon (`gtk-layer-shell`, `XWayland`, `GDK`) in user-visible strings.

---

## Key Constraints

1. `gdk_window_input_shape_combine_region` must be called on a mapped (shown) window. MethodChannel calls are always post-first-frame, so timing is safe. Never call from C++ init code.
2. Layer-shell anchor must be set BEFORE `gtk_widget_show`. The `my_application_activate` function calls show via `first_frame_cb`; layer-shell setup must happen before that callback fires (i.e., immediately after window creation).
3. Do NOT remove `GDK_BACKEND=x11` from `make run-linux` for the X11/reserved path. The Makefile target controls the backend for non-transparent runs.
4. `window_manager` x/y positioning calls are NOT used in Wayland transparent mode — layer-shell anchoring replaces them. `window_manager` is still used for reserved-mode X11 runs.
5. All existing tests must continue to pass. New Linux-specific C++ code is guarded so it never activates on X11/XWayland.

---

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Channel name | `com.happeningapp/click_through` | Matches app reverse-domain; test app used example namespace |
| Layer-shell detection | Compile-time `#ifdef` propagated via channel method | Clean; no runtime probing of optional library symbols |
| Backend detection timing | Async in `main()` before `runApp()` | Channel calls require WidgetsFlutterBinding; detection result must be known before WindowService init |
| Hover delay | 300ms | Prevents accidental focus while mousing over strip to reach content below (Smith recommendation) |
| Hover primary / hotkey secondary | Yes | Smith UX Q2 answer; glanceability is the strip's premise |
| Soft gate on layer-shell | Yes | App must always launch; missing optional feature never blocks startup (Smith UX Q3) |
| CT-04 inline text | Always visible below disabled option | H6 Recognition Rather Than Recall; tooltips require hover-discovery |
| XWayland transparent | Disabled, inline explanation | GDK input shape confirmed broken on Mutter/XWayland |
| X11 pure transparent | Disabled in this sprint | GDK input shape works on pure X11 but no layer-shell positioning; future sprint |
