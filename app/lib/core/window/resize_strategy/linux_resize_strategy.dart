import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// TLDR: Linux resize strategy. setResizable(true) on init so gtk_window_resize
/// is honoured; GTK3 ignores resize calls on non-resizable windows.
/// Expand: setMax→setSize→setMin. Collapse: setMin→setMax→setSize.
class LinuxResizeStrategy extends WindowResizeStrategy {
  LinuxResizeStrategy({
    required WindowManager wm,
    required ScreenRetriever sr,
  })  : _wm = wm,
        // ignore: unused_field
        _sr = sr;

  final WindowManager _wm;
  // ignore: unused_field
  final ScreenRetriever _sr;

  @override
  Future<void> initialize(Size initialSize, double dpr) async {
    await _wm.setResizable(true);
    await _wm.setPosition(Offset.zero);
  }

  @override
  Future<void> expand(Size targetSize) async {
    await _wm.setMaximumSize(targetSize);
    await _wm.setSize(targetSize);
    await _wm.setMinimumSize(targetSize);
  }

  @override
  Future<void> collapse(Size targetSize) async {
    await _wm.setMinimumSize(targetSize);
    await _wm.setMaximumSize(targetSize);
    await _wm.setSize(targetSize);
  }
}
