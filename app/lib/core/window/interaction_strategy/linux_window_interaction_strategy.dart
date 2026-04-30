import 'package:happening/core/linux/click_through_channel.dart';
import 'package:happening/core/settings/settings_service.dart';

import 'window_interaction_strategy.dart';

class LinuxWindowInteractionStrategy extends WindowInteractionStrategy {
  LinuxWindowInteractionStrategy({
    required ClickThroughChannel channel,
    required bool supportsTransparentPassThrough,
  })  : _channel = channel,
        _supportsTransparentPassThrough = supportsTransparentPassThrough;

  final ClickThroughChannel _channel;
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
      await _channel.setPassThrough(true);
    }
  }

  @override
  Future<void> setFocused(bool focused) async {
    if (_mode != WindowMode.transparent || !_supportsTransparentPassThrough) {
      return;
    }
    await _channel.setPassThrough(!focused);
  }

  @override
  Future<void> setPassThrough(bool enabled) async {
    if (!_supportsTransparentPassThrough) return;
    await _channel.setPassThrough(enabled);
  }
}
