import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/window/interaction_strategy/macos_window_interaction_strategy.dart';
import 'package:happening/core/window/window_service.dart';

/// macOS-specific WindowService.
///
/// Two overrides address the Metal layer transparency timing problem:
///
/// 1. [awaitReadyToShow] does NOT await the readyToShow future, so
///    initialize returns immediately and runApp executes next.
///
/// 2. [performShow] defers show+focus until after the first rendered
///    frame via addPostFrameCallback. By that point Impeller has created its
///    CAMetalLayer, so MainFlutterWindow.makeKeyAndOrderFront can configure
///    it as non-opaque before it becomes visible.
class MacOSWindowService extends WindowService {
  MacOSWindowService({
    required super.windowManager,
    required super.screenRetriever,
  }) : super(
          interactionStrategy:
              MacOsWindowInteractionStrategy(wm: windowManager),
        );

  @override
  Future<void> awaitReadyToShow(Future<void> f) {
    unawaited(f);
    return Future.value();
  }

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
