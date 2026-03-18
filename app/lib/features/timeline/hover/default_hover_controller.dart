import 'dart:async';

import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

import 'hover_controller.dart';

/// Default hover controller for Windows/macOS.
class DefaultHoverController extends HoverController {
  DefaultHoverController(this._ws);
  final WindowService _ws;

  @override
  void setIntent(ExpansionState state) {
    if (state == ExpansionState.expanded) {
      if (!_ws.isExpandedNotifier.value) unawaited(_ws.expand());
    } else {
      if (_ws.isExpandedNotifier.value) unawaited(_ws.collapse());
    }
  }
}
