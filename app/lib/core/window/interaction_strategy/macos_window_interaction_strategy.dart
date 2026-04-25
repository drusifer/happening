import 'package:happening/core/settings/settings_service.dart';
import 'package:window_manager/window_manager.dart';

import 'window_interaction_strategy.dart';

class MacOsWindowInteractionStrategy extends WindowInteractionStrategy {
  MacOsWindowInteractionStrategy({required WindowManager wm}) : _wm = wm;

  final WindowManager _wm;
  WindowMode _mode = WindowMode.transparent;

  @override
  WindowModeAvailability get availability => const WindowModeAvailability(
        supportsTransparent: true,
        supportsReserved: false,
      );

  @override
  Future<void> initialize(WindowMode effectiveMode) async {
    _mode = effectiveMode;
    if (_mode == WindowMode.transparent) {
      await setPassThrough(true);
    }
  }

  @override
  Future<void> setFocused(bool focused) async {
    if (_mode != WindowMode.transparent) return;
    await setPassThrough(!focused);
  }

  @override
  Future<void> setPassThrough(bool enabled) async {
    await _wm.setIgnoreMouseEvents(enabled, forward: true);
  }
}
