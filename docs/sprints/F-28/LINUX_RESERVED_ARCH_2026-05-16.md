# Architecture — Linux Reserved Space (F-28)
*Morpheus — 2026-05-16*

## Decision

Implement Linux screen-space reservation via a **thin Flutter platform-channel plugin**
in the Linux runner, orchestrated from `WindowService` in Dart — mirroring the Windows
AppBar pattern already in place.

---

## Context & Constraints

### What changed from the old approach
The Linux runner previously contained C++ strut code (`set_x11_strut()`) that was
deliberately removed in the Linux Wayland Simplification sprint because:
1. It set `_NET_WM_WINDOW_TYPE_DOCK` after window mapping → black screen on Mutter/XWayland.
2. Reservation logic was embedded in the runner, not the feature layer.
3. No runtime enable/disable possible (settings can change at runtime).

### Why the black screen will NOT recur
The previous bug was caused by `_NET_WM_WINDOW_TYPE_DOCK` changing the window type
after mapping. The new implementation sets ONLY `_NET_WM_STRUT_PARTIAL` (not DOCK type).
`_NET_WM_STRUT_PARTIAL` can be safely set or cleared at any time after window mapping.

### Why NOT pure Dart FFI
Getting the X11 Window ID (XID) from pure Dart requires either searching the full window
tree by PID (fragile) or relying on XGetInputFocus (wrong window if focus moves).
The GDK layer already holds the `GtkWindow*` → `GdkWindow*` → XID chain; the runner
is the correct place to expose it via a platform channel. This is the standard Flutter
pattern (mirrors how `window_manager` itself works).

---

## Component Map

### New: `app/linux/runner/strut_plugin.h/.cc`
A Flutter `MethodChannel("happening/strut")` plugin registered in `my_application.cc`.

Methods exposed:
- `getWindowId()` → `int` (the X11 XID, or 0 on Wayland/failure)
- `reserve(height: int, screenWidth: int)` → void
- `release()` → void

Implementation:
```cpp
// Get XID
GdkWindow* gdk_window = gtk_widget_get_window(toplevel_);
Display*   display    = gdk_x11_get_default_xdisplay();  // null on Wayland
Window     xid        = gdk_x11_window_get_xid(gdk_window);

// Set strut (height = collapsed strip height in physical pixels)
// _NET_WM_STRUT_PARTIAL: left, right, top, bottom,
//                        left_start, left_end, right_start, right_end,
//                        top_start, top_end, bottom_start, bottom_end
long strut[12] = {0, 0, height, 0,  0, 0,  0, 0,  0, screenWidth,  0, 0};
Atom atom = XInternAtom(display, "_NET_WM_STRUT_PARTIAL", False);
XChangeProperty(display, xid, atom, XA_CARDINAL, 32, PropModeReplace,
                (unsigned char*)strut, 12);
// Also set legacy _NET_WM_STRUT for older WMs
long strut4[4] = {0, 0, height, 0};
atom = XInternAtom(display, "_NET_WM_STRUT", False);
XChangeProperty(display, xid, atom, XA_CARDINAL, 32, PropModeReplace,
                (unsigned char*)strut4, 4);
XFlush(display);
```

Wayland guard: if `display == nullptr`, return without error.

### Modified: `app/linux/runner/my_application.cc`
Register `StrutPlugin` after `fl_register_plugins()`, passing the `GtkWindow*` pointer.

### New: `app/lib/core/window/linux_strut_service.dart`
Thin Dart wrapper around `MethodChannel('happening/strut')`:
```dart
class LinuxStrutService {
  static const _channel = MethodChannel('happening/strut');
  Future<int> getWindowId() async { ... }
  Future<void> reserve({required int height, required int screenWidth}) async { ... }
  Future<void> release() async { ... }
}
```
No-op stubs for non-Linux platforms (the channel won't exist there).

### Modified: `app/lib/core/window/window_service.dart`
Add `LinuxStrutService` alongside the Windows `_shAppBarMessage` pattern:

```
initialize():
  if _isLinux && reserved → await _reserveLinuxStrut()

_onDisplayChangedInner():
  if _isLinux && reserved → await _reserveLinuxStrut()  (re-set with new dimensions)

setWindowMode():
  if _isLinux:
    reserved → await _reserveLinuxStrut()
    other   → await _linuxStrutService.release()

dispose():
  if _isLinux → await _linuxStrutService.release()
```

### NOT modified
- `ReservedWindowInteractionStrategy` — no change needed
- `my_application.cc` startup sequence — strut is set via Dart call after window shown
- Linux runner `.cmake`/`CMakeLists.txt` — add `X11` to `target_link_libraries`

---

## Timing

The Dart call to `reserve()` happens from `WindowService.initialize()`, which is called
AFTER `_wm.waitUntilReadyToShow()` + `_wm.show()`. The window is already mapped at
this point. Setting `_NET_WM_STRUT_PARTIAL` post-mapping is safe (unlike DOCK type).

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Wayland: XID is 0, strut silently skipped | High | Handled: guard in plugin |
| EWMH WM ignores strut (e.g. i3, openbox) | Low | Not a crash; cosmetic only |
| `_NET_WM_STRUT_PARTIAL` causes flicker on re-set | Low | Re-set only on display change |
| XWayland: strut ignored by Mutter | Medium | Logged as warning; same as current |

---

## Phase Breakdown (for Mouse)

**Phase A — Plugin scaffold** (1-2 tasks)
- A1: `strut_plugin.h/.cc` — `getWindowId()` only; registered in runner; returns XID or 0
- A2: `linux_strut_service.dart` — channel wrapper; `getWindowId()` smoke test

**Phase B — Reserve/release** (2 tasks)
- B1: `reserve()` + `release()` in plugin; `LinuxStrutService` exposes them
- B2: `WindowService` wires `_reserveLinuxStrut()` / `_releaseLinuxStrut()` on init/mode-change/display-change

**Phase C — Tests + QA** (1-2 tasks)
- C1: Unit tests for `LinuxStrutService` (mock channel); integration smoke on X11
- C2: Trin UAT pass; Morpheus review

---

## Acceptance (from US-L1–L3, amended by Smith)

- AC-L1-1: OS work area excludes strip height when app starts in reserved mode on Linux
- AC-L1-2: Maximized windows stay below strip (manual smoke on X11/XWayland)
- AC-L1-3: Strut released when mode changes away from reserved
- AC-L1-4/L1-5: Windows/macOS unchanged (no regression)
- AC-L2-1: Strut re-applied on display change with current collapsed height
- AC-L2-2: No double-set crash on concurrent display changes
- AC-L3-1: If reservation unavailable (Wayland), app starts normally with log warning
- AC-L3-2: Wayland behavior identical to current

---

*Arch doc: LINUX_RESERVED_ARCH_2026-05-16.md*
