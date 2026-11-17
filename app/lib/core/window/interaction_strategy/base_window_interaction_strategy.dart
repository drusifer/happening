import 'package:flutter/foundation.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_adapter.dart';

import 'window_interaction_strategy.dart';

abstract class BaseWindowInteractionStrategy extends WindowInteractionStrategy {
  BaseWindowInteractionStrategy({required this.wm});

  @protected
  final WindowAdapter wm;

  @override
  Future<void> initialize(WindowMode mode) async {
    return;
  }

  @override
  Future<void> sendToBack() async {
    await wm.setAlwaysOnTop(false);
    await wm.blur();
  }

  @override
  Future<void> restoreToFront() async {
    await wm.setAlwaysOnTop(true);
  }
}
