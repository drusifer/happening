import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:window_manager/window_manager.dart';

import 'linux_window_interaction_strategy.dart';
import 'macos_window_interaction_strategy.dart';
import 'windows_window_interaction_strategy.dart';

class WindowModeAvailability {
  const WindowModeAvailability({
    required this.supportsTransparent,
    required this.supportsReserved,
  });

  final bool supportsTransparent;
  final bool supportsReserved;
}

abstract class WindowInteractionStrategy {
  static WindowInteractionStrategy create({
    required WindowManager wm,
    required bool supportsTransparentPassThrough,
    TargetPlatform? platformOverride,
  }) {
    if (platformOverride != null) {
      return createForPlatform(
        platform: platformOverride,
        wm: wm,
        supportsTransparentPassThrough: supportsTransparentPassThrough,
      );
    }

    if (Platform.isWindows) {
      return WindowsWindowInteractionStrategy(
        wm: wm,
        supportsTransparentPassThrough: supportsTransparentPassThrough,
      );
    }
    if (Platform.isLinux) {
      return LinuxWindowInteractionStrategy(wm: wm);
    }
    return MacOsWindowInteractionStrategy(wm: wm);
  }

  static WindowInteractionStrategy createForPlatform({
    required TargetPlatform platform,
    required WindowManager wm,
    required bool supportsTransparentPassThrough,
  }) {
    switch (platform) {
      case TargetPlatform.macOS:
        return MacOsWindowInteractionStrategy(wm: wm);
      case TargetPlatform.windows:
        return WindowsWindowInteractionStrategy(
          wm: wm,
          supportsTransparentPassThrough: supportsTransparentPassThrough,
        );
      case TargetPlatform.linux:
        return LinuxWindowInteractionStrategy(wm: wm);
      default:
        return LinuxWindowInteractionStrategy(wm: wm);
    }
  }

  WindowModeAvailability get availability;

  Future<void> initialize(WindowMode effectiveMode);
  Future<void> setPassThrough(bool enabled);
  Future<void> setFocused(bool focused);
}
