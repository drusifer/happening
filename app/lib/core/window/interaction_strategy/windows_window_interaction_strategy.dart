import 'package:happening/core/settings/settings_service.dart';
import 'package:window_manager/window_manager.dart';

import 'window_interaction_strategy.dart';

class WindowsWindowInteractionStrategy extends WindowInteractionStrategy {
  WindowsWindowInteractionStrategy({
    required WindowManager wm,
    required bool supportsTransparentPassThrough,
  })  : _wm = wm,
        _supportsTransparentPassThrough = supportsTransparentPassThrough;

  final WindowManager _wm;
  final bool _supportsTransparentPassThrough;
  WindowMode _mode = WindowMode.reserved;

  @override
  WindowModeAvailability get availability => WindowModeAvailability(
        supportsTransparent: _supportsTransparentPassThrough,
        supportsReserved: true,
      );

  @override
  Future<void> initialize(WindowMode effectiveMode) async {
    _mode = effectiveMode;
    if (_mode == WindowMode.transparent && _supportsTransparentPassThrough) {
      await setPassThrough(true);
    }
  }

  @override
  Future<void> setFocused(bool focused) async {
    if (_mode != WindowMode.transparent || !_supportsTransparentPassThrough) {
      return;
    }
    await setPassThrough(!focused);
  }

  @override
  Future<void> setPassThrough(bool enabled) async {
    if (!_supportsTransparentPassThrough) return;
    await _wm.setIgnoreMouseEvents(enabled, forward: true);
  }
}
