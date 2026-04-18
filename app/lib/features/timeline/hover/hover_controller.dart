import 'dart:io';

import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

import 'default_hover_controller.dart';
import 'linux_hover_controller.dart';

export 'default_hover_controller.dart';
export 'linux_hover_controller.dart';

/// TLDR: Routes hover expand/collapse intents to [WindowService], isolated from
/// TimelineStrip pointer events. Factory selects [LinuxHoverController] (with
/// 300ms spurious-collapse suppression) or [DefaultHoverController] by platform.
abstract class HoverController {
  static HoverController create(WindowService ws) {
    if (Platform.isLinux) return LinuxHoverController(ws);
    return DefaultHoverController(ws);
  }

  /// Applies an expansion intent.
  ///
  /// Returns false when the controller intentionally suppresses the intent,
  /// such as Linux dropping a synthetic collapse during GTK resize.
  bool setIntent(ExpansionState state);
  void dispose() {}
}
