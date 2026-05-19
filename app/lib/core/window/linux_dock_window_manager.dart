import 'package:flutter/services.dart';

class LinuxDockWindowManager {
  static const _channel = MethodChannel('linux_dock_window_manager');

  Future<bool> isDockable() async {
    final result = await _channel.invokeMethod<bool>('isDockable');
    return result ?? false;
  }

  Future<void> dock({required int height}) async {
    await _channel.invokeMethod<void>('dock', {'height': height});
  }

  Future<void> undock() async {
    await _channel.invokeMethod<void>('undock');
  }
}
