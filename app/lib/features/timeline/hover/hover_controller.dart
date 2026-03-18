import 'dart:io';

import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

import 'default_hover_controller.dart';
import 'linux_hover_controller.dart';

export 'default_hover_controller.dart';
export 'linux_hover_controller.dart';

/// Isolates all async window calls triggered by hover events.
abstract class HoverController {
  static HoverController create(WindowService ws) {
    if (Platform.isLinux) return LinuxHoverController(ws);
    return DefaultHoverController(ws);
  }

  void setIntent(ExpansionState state);
  void dispose() {}
}
