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

  Future<void> initialize(Size initialSize, double dpr);
  Future<void> expand(Size targetSize);
  Future<void> collapse(Size targetSize);

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
