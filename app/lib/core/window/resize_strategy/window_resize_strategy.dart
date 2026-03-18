import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'linux_resize_strategy.dart';
import 'macos_resize_strategy.dart';
import 'windows_resize_strategy.dart';

export 'linux_resize_strategy.dart';
export 'macos_resize_strategy.dart';
export 'windows_resize_strategy.dart';

/// Platform-specific window resize behaviour.
abstract class WindowResizeStrategy {
  static WindowResizeStrategy create({
    required WindowManager wm,
    required ScreenRetriever sr,
  }) {
    if (Platform.isWindows) return WindowsResizeStrategy(wm: wm, sr: sr);
    if (Platform.isLinux) return LinuxResizeStrategy(wm: wm, sr: sr);
    return MacOsResizeStrategy(wm: wm, sr: sr);
  }

  Future<void> initialize(Size initialSize, double dpr);
  Future<void> expand(Size targetSize, void Function() onExpanded);
  Future<void> collapse(Size targetSize);
  void dispose() {}
}
