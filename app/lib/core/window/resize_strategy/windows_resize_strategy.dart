import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// TLDR: Windows resize strategy. setResizable(false) on init.
/// Expand: fires onExpanded first (Win32 is synchronous), then setMax→setSize→setMin.
/// Collapse: setMin→setMax→setSize.
class WindowsResizeStrategy extends WindowResizeStrategy {
  WindowsResizeStrategy({
    required WindowManager wm,
    required ScreenRetriever sr,
  })  : _wm = wm,
        _sr = sr;

  final WindowManager _wm;
  // ignore: unused_field
  final ScreenRetriever _sr;

  @override
  Future<void> initialize(Size initialSize, double dpr) async {
    await _wm.setResizable(false);
  }

  @override
  Future<void> expand(Size targetSize, void Function() onExpanded) async {
    onExpanded();
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
