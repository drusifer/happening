import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../display/display_info.dart';
import 'linux_resize_strategy.dart';
import 'macos_resize_strategy.dart';
import 'windows_resize_strategy.dart';

export 'linux_resize_strategy.dart';
export 'macos_resize_strategy.dart';
export 'windows_resize_strategy.dart';

/// TLDR: Abstract strategy for platform-specific window expand/collapse sequences.
/// Factory [create] selects the per-platform implementation at runtime.
abstract class WindowResizeStrategy {
  static WindowResizeStrategy create({
    required WindowManager wm,
    required ScreenRetriever sr,
  }) {
    if (Platform.isLinux) return LinuxResizeStrategy(wm: wm, sr: sr);
    if (Platform.isWindows) return WindowsResizeStrategy(wm: wm, sr: sr);
    return MacOsResizeStrategy(wm: wm, sr: sr);
  }

  WindowManager get wm;

  /// Whether the OS window is left user-resizable. These windows are frameless
  /// (no resize handles), so this never lets the user drag-resize. Defaults to
  /// false; Linux overrides to true because GTK3 silently ignores
  /// `gtk_window_resize` on non-resizable windows (see LESSONS L-001).
  @protected
  bool get resizable => false;

  /// Common init: apply the resizable hint and park the window at the origin.
  /// `WindowService` re-issues collapse/expand and moveToDisplay afterwards.
  Future<void> initialize(Size initialSize, double dpr) async {
    await wm.setResizable(resizable);
    await wm.setPosition(Offset.zero);
  }

  /// The single, platform-safe way to resize the OS window. Pins
  /// `min == max == [size]` so the result is well-defined on every platform.
  ///
  /// CRITICAL (Windows, see LESSONS L-005): never widen the cap with
  /// `setMaximumSize(Size.infinite)` — window_manager casts it to a garbage
  /// native max-track that makes Win32 truncate the window to its OS-minimum
  /// tracking size (~136×39), regardless of the requested bounds. So: lower the
  /// floor to zero (to permit shrinking), raise the cap only to the target, set
  /// the geometry, then pin the floor up to the target.
  ///
  /// [position] (work-area origin) repositions the window in the same step;
  /// pass null to resize in place (expand/collapse).
  ///
  /// This is the ONE resize implementation — `expand`, `collapse`, the hide/show
  /// mini/full resize, and the Windows AppBar reservation all route through it,
  /// so the min/max bracket only has to be correct here.
  Future<void> applySize(Size size, {Offset? position}) async {
    await wm.setMinimumSize(Size.zero);
    await wm.setMaximumSize(size);
    await applyGeometry(size, position);
    await wm.setMinimumSize(size);
  }

  /// Applies window geometry (size, optionally position) using `setPosition` +
  /// `setSize`. Callers go through [applySize], which brackets this with the
  /// min/max constraints so `setSize` reliably reaches the target.
  ///
  /// Deliberately `setSize`, not `setBounds`: on Windows `setBounds` flakes on
  /// first show (lands ~1px and cannot be force-grown back), while `setSize`
  /// within the [applySize] max-cap snaps cleanly. This is an override point in
  /// case a future platform genuinely needs different geometry.
  @protected
  Future<void> applyGeometry(Size size, Offset? position) async {
    if (position != null) await wm.setPosition(position);
    await wm.setSize(size);
  }

  /// Expand the window to [targetSize] in place (no reposition).
  Future<void> expand(Size targetSize) => applySize(targetSize);

  /// Collapse the window to [targetSize] in place (no reposition).
  Future<void> collapse(Size targetSize) => applySize(targetSize);

  /// Repositions the strip onto the chosen [display]. The window is moved to
  /// the top-left of the display's work area; sizing remains the caller's
  /// responsibility (WindowService re-issues collapse/expand after move). On
  /// Linux, the strut C++ plugin reads the window's current monitor via
  /// `gdk_display_get_monitor_at_window`, so no native call is needed here.
  /// On Windows, WindowService is expected to call `reassertAppBar()` after
  /// this method returns so the AppBar reservation moves with the strip.
  Future<void> moveToDisplay(DisplayInfo display) async {
    await wm.setPosition(display.workAreaOrigin);
  }

  void dispose() {
    return;
  }
}
