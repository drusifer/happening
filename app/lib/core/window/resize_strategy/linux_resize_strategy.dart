import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

// Linux platform window resize strategy implementation.
//
// TLDR:
// Overview: Handles X11/Wayland GTK3 frameless window expansion and collapse transitions.
// Problem:  GTK3 silently ignores gtk_window_resize calls on non-resizable windows.
// Solution: Inherits the shared resizable=true init and resize order from the base.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------
class LinuxResizeStrategy extends WindowResizeStrategy {
  LinuxResizeStrategy({required WindowManager wm}) : _wm = wm;

  final WindowManager _wm;

  @override
  WindowManager get wm => _wm;

  // GTK3 silently ignores gtk_window_resize on non-resizable windows (L-001),
  // so Linux must stay resizable; the frameless DOCK window has no handles.
  @override
  bool get resizable => true;
}
