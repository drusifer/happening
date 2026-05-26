import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

// Linux platform window resize strategy implementation.
//
// TLDR:
// Overview: Handles X11/Wayland GTK3 frameless window expansion and collapse transitions.
// Problem:  GTK3 silently ignores gtk_window_resize calls on non-resizable windows.
// Solution: Enforces setResizable(true) on initialization, then coordinates strict order of operations.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------
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
