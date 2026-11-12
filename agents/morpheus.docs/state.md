# Morpheus Agent State — Linux Startup Runtime Error & Dependency Upgrade Fix (*fix loop)

## Context
- **Review Summary (2026-11-12)**:
  - Reviewed and approved the Linux build and startup crash fix for `window_manager: ^0.7.0` (`cnativeapi: 0.6.0`) and `screen_retriever: ^0.4.0`.
  - **Architectural Notes**:
    1. **Official Compatibility Bridge (`legacy.dart`)**: `window_manager 0.7.0` and `screen_retriever 0.4.0` transitioned to a shared C++ `nativeapi` core (`cnativeapi`) and moved their classic singleton/listener APIs into `package:window_manager/legacy.dart` and `package:screen_retriever/legacy.dart`. Using the official `legacy.dart` bridge preserves existing `WindowService`, `ScreenRetrieverAdapter`, and strategy contracts without invasive rewrites.
    2. **Linux X11 Backend & GDK Type-Safety (`main.cc` & `linux_dock_window_manager_plugin.cc`)**: Under `window_manager 0.7.0`'s synchronous FFI `waitUntilReadyToShow`, `LinuxDockWindowManagerPlugin` is invoked before `first_frame_cb`. Calling `gdk_x11_get_default_xdisplay()` on a `GdkWaylandDisplay` returns a non-null invalid pointer because GTK3's `gdk_x11_display_get_xdisplay` only checks `GDK_IS_DISPLAY`, causing `XInternAtom` to segfault (`SIGSEGV`). Enforcing `setenv("GDK_BACKEND", "x11", 0)` in `main.cc` ensures X11/XWayland dock struts and positioning work regardless of how the binary is launched, and `GDK_IS_X11_DISPLAY` / `GDK_IS_X11_WINDOW` guards in `linux_dock_window_manager_plugin.cc` guarantee memory safety even if someone explicitly overrides `GDK_BACKEND=wayland`.
    3. **Build & Linter Hygiene (`Makefile`, `analysis_options.yaml`)**: Removed broken Windows backslash `$(FLUTTER_SDK)\bin` from Linux `PATH` overrides in `Makefile`, fixed `check-unused-files` flag in `lint-metrics`, and configured `deprecated_member_use: ignore` in `app/analysis_options.yaml` for Flutter 3.50 + `legacy.dart`.

## Current Task
- **Status:** Completed and Approved (`100%`)
- **Assigned to:** @Morpheus
- **Task:** Step 3 of `*fix` Bloop (`*lead review` for Linux dependency & startup fix)

## Next Steps
- `*fix` Bloop complete (`Neo → Trin → Morpheus`). Ready for user verification.
