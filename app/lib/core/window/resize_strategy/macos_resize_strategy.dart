import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// macOS: setResizable(false) + position(zero) + 3-step resize sequence.
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
  Future<void> initialize(Size initialSize, double dpr) async {
    await _wm.setResizable(false);
    await _wm.setPosition(Offset.zero);
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
