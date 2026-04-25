import 'package:happening/core/settings/settings_service.dart';
import 'package:window_manager/window_manager.dart';

import 'window_interaction_strategy.dart';

class LinuxWindowInteractionStrategy extends WindowInteractionStrategy {
  LinuxWindowInteractionStrategy({required WindowManager wm});

  @override
  WindowModeAvailability get availability => const WindowModeAvailability(
        supportsTransparent: false,
        supportsReserved: true,
      );

  @override
  Future<void> initialize(WindowMode effectiveMode) async {}

  @override
  Future<void> setFocused(bool focused) async {}

  @override
  Future<void> setPassThrough(bool enabled) async {}
}
