import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/window/interaction_strategy/macos_window_interaction_strategy.dart';
import 'package:happening/core/window/window_service.dart';

/// macOS-specific WindowService.
///
/// [performShow] defers show+focus until after the first rendered
/// frame via addPostFrameCallback. By that point Impeller has created its
/// CAMetalLayer, so MainFlutterWindow.makeKeyAndOrderFront can configure
/// it as non-opaque before it becomes visible.
class MacOSWindowService extends WindowService {
  MacOSWindowService({
    required super.windowManager,
    required super.displayService,
  }) : super(
          interactionStrategy:
              MacOsWindowInteractionStrategy(wm: windowManager),
        );

  @override
  Future<void> performShow() {
    // Defer show+focus until after the first rendered frame so that
    // Impeller's CAMetalLayer exists when makeKeyAndOrderFront fires.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await wm.show();
      await wm.focus();
    });
    return Future.value();
  }
}
