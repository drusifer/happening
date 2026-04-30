import 'package:flutter/services.dart';

import 'click_through_channel.dart';

class LinuxClickThroughChannel implements ClickThroughChannel {
  static const _ch = MethodChannel('com.happeningapp/click_through');

  @override
  Future<void> setPassThrough(bool enabled) =>
      _ch.invokeMethod('setIgnoreMouseEvents', {'ignore': enabled});

  @override
  Future<String> getDisplayServer() async =>
      await _ch.invokeMethod<String>('getDisplayServer') ?? 'unknown';

  @override
  Future<bool> isLayerShellAvailable() async =>
      await _ch.invokeMethod<bool>('isLayerShellAvailable') ?? false;
}
