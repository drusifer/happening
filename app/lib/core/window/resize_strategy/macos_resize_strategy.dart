import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

// macOS platform window resize strategy implementation.
//
// TLDR:
// Overview: Handles macOS frameless window expansion and collapse transitions.
// Problem:  Accidental user resizes and window displacement must be prevented on macOS.
// Solution: Enforces setResizable(false) on initialization, then coordinates strict order of size adjustments.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------
class MacOsResizeStrategy extends WindowResizeStrategy {
  MacOsResizeStrategy({
    required WindowManager wm,
    required ScreenRetriever sr,
  })  : _wm = wm,
        _sr = sr;

  final WindowManager _wm;
  // ignore: unused_field
  final ScreenRetriever _sr;

  @override
  WindowManager get wm => _wm;

  @override
  Future<void> initialize(Size initialSize, double dpr) async {
    await _wm.setResizable(false);
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
