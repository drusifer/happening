import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// Linux/GTK resize strategy.
///
/// GTK/Wayland compositors treat setSize() as advisory and may ignore it,
/// especially when existing min/max constraints pin the window. The reliable
/// mechanism is constraint-forcing via an intentionally invalid constraint:
///
///   Expand: setSize (advisory, ignored — max-cap still 55), then
///           setMinimumSize(target) — min(260) > max(55) is INVALID, GTK
///           resolves by growing the window to target — then setMaximumSize
///           to formalise the new constraints. Finally setSize(target) again
///           to force a fresh size-allocation after constraints are valid.
///
///   Collapse: setMinimumSize(target) first to lower the expand floor (when
///             min=expanded, setSize is clamped and ignored). Then
///             setMaximumSize(target) — now constraints are valid at target.
///             Finally setSize(target) to force GTK to apply the shrink.
///
/// WARNING: do NOT lift setMaximumSize before setMinimumSize on expand.
/// Lifting max first means constraints are always valid → no conflict →
/// GTK has no reason to force-grow → window stays at collapsed height.
class LinuxResizeStrategy extends WindowResizeStrategy {
  static final _log = Logger('LinuxResizeStrategy');
  LinuxResizeStrategy({required WindowManager wm, required ScreenRetriever sr})
      : _wm = wm,
        _sr = sr;

  final WindowManager _wm;
  // ignore: unused_field
  final ScreenRetriever _sr;

  @override
  Future<void> initialize(Size initialSize, double dpr) async {
    await _wm.setPosition(Offset.zero);
  }

  @override
  Future<void> expand(Size targetSize) async {
    _log.fine(
        'LinuxResizeStrategy.expand() START target=w${targetSize.width}×h${targetSize.height}');
    // Advisory — ignored by GTK when max-cap is still the collapsed height.
    await _wm.setSize(targetSize);
    _log.fine('LinuxResizeStrategy.expand() setSize done');
    // min(target) > max(collapsed) = intentionally invalid constraint.
    // GTK resolves the conflict by growing the window to targetSize.
    await _wm.setMinimumSize(targetSize);
    _log.fine('LinuxResizeStrategy.expand() setMinimumSize done');
    // Formalise: lift the max-cap now that the window has grown.
    await _wm.setMaximumSize(targetSize);
    _log.fine('LinuxResizeStrategy.expand() setMaximumSize done');
    // After the first grow, some XWayland sessions keep Flutter's layout
    // surface at the old collapsed height on subsequent expands. A final
    // setSize with valid min/max constraints forces a new size-allocate.
    await _wm.setSize(targetSize);
    _log.fine('LinuxResizeStrategy.expand() done');
  }

  @override
  Future<void> collapse(Size targetSize) async {
    _log.fine(
        'LinuxResizeStrategy.collapse() START target=w${targetSize.width}×h${targetSize.height}');
    // Lower the min-floor left by a previous expand first. With min still at
    // the expanded height, any setSize(target) is clamped to min and ignored.
    await _wm.setMinimumSize(targetSize);
    _log.fine('LinuxResizeStrategy.collapse() setMinimumSize done');
    // Cap the ceiling. Now min=target, max=target — constraints are valid and
    // below the current window size, so GTK must accept the following setSize.
    await _wm.setMaximumSize(targetSize);
    _log.fine('LinuxResizeStrategy.collapse() setMaximumSize done');
    // Force the resize now that constraints allow it.
    await _wm.setSize(targetSize);
    _log.fine('LinuxResizeStrategy.collapse() setSize done');
    // Re-anchor to (0,0). On Linux the WM may drift the window after a
    // monitor change (build/tmp line 2054: 3840→2944 display change).
    await _wm.setPosition(Offset.zero);
    _log.fine('LinuxResizeStrategy.collapse() setPosition done');
  }
}
