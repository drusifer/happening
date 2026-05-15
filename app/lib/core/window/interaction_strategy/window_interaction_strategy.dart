import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:window_manager/window_manager.dart';

import 'macos_window_interaction_strategy.dart';
import 'reserved_window_interaction_strategy.dart';

class WindowModeAvailability {
  const WindowModeAvailability({
    required this.supportsReserved,
  });

  final bool supportsReserved;
}

abstract class WindowInteractionStrategy {
  static WindowInteractionStrategy create({
    required WindowManager wm,
    TargetPlatform? platformOverride,
  }) {
    if (platformOverride != null) {
      return createForPlatform(platform: platformOverride, wm: wm);
    }
    if (Platform.isMacOS) return MacOsWindowInteractionStrategy(wm: wm);
    return ReservedWindowInteractionStrategy(wm: wm);
  }

  static WindowInteractionStrategy createForPlatform({
    required TargetPlatform platform,
    required WindowManager wm,
  }) {
    switch (platform) {
      case TargetPlatform.macOS:
        return MacOsWindowInteractionStrategy(wm: wm);
      default:
        return ReservedWindowInteractionStrategy(wm: wm);
    }
  }

  WindowModeAvailability get availability;

  Future<void> initialize(WindowMode mode);
  Future<void> sendToBack();
  Future<void> restoreToFront();
}
