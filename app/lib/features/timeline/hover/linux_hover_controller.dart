import 'dart:async';

import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

import 'hover_controller.dart';

/// Linux hover controller — absorbs spurious collapses during window resize.
///
/// When the window expands under the cursor, GTK fires a synthetic pointer-enter
/// which immediately triggers a collapse. A 300ms suppression window after
/// expand absorbs this false event.
class LinuxHoverController extends HoverController {
  LinuxHoverController(this._ws);
  final WindowService _ws;

  Timer? _suppressTimer;

  @override
  void setIntent(ExpansionState state) {
    if (state == ExpansionState.expanded) {
      if (!_ws.isExpandedNotifier.value) {
        // Start suppression only on actual expand transition, not on every
        // hover-over while already expanded. GTK synthetic pointer-exit fires
        // immediately after the resize — the 300ms window absorbs only that.
        _suppressTimer?.cancel();
        _suppressTimer = Timer(
          const Duration(milliseconds: 300),
          () => _suppressTimer = null,
        );
        unawaited(_ws.expand());
      }
    } else {
      if (_suppressTimer != null) return; // drop spurious collapse
      if (_ws.isExpandedNotifier.value) unawaited(_ws.collapse());
    }
  }

  @override
  void dispose() {
    _suppressTimer?.cancel();
    _suppressTimer = null;
  }
}
