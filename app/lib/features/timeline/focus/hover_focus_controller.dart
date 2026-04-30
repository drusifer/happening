import 'dart:async';

import 'package:happening/features/timeline/focus/timeline_focus_controller.dart';

// Triggers focus after a hover entry delay; clears focus on exit.
// Only active when the focus controller uses the transparent focus model.
class HoverFocusController {
  HoverFocusController({
    required TimelineFocusController focusController,
    this.hoverDelay = const Duration(milliseconds: 300),
  }) : _focusController = focusController;

  final TimelineFocusController _focusController;
  final Duration hoverDelay;
  Timer? _hoverTimer;

  void onEnter() {
    if (!_focusController.usesTransparentFocusModel) return;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(hoverDelay, () => unawaited(_focusController.focus()));
  }

  void onExit() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
    if (!_focusController.usesTransparentFocusModel) return;
    if (_focusController.isFocused) {
      unawaited(_focusController.unfocus());
    }
  }

  void dispose() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
  }
}
