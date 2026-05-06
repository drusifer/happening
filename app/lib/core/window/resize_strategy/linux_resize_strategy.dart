import 'package:flutter/material.dart';
import 'package:happening/core/util/logger.dart';
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
///   Collapse: setSize (advisory), then setMinimumSize(target) to lower the
///             expand floor, then setMaximumSize(target) — setMaximumSize is
///             the forcing mechanism when the window is above target.
///
/// WARNING: do NOT lift setMaximumSize before setMinimumSize on expand.
/// Lifting max first means constraints are always valid → no conflict →
/// GTK has no reason to force-grow → window stays at collapsed height.
///
/// This matches the behaviour documented in pre-Sprint6 _doExpand/_doCollapse
/// (log-sample.txt lines 53-56, git history).
class LinuxResizeStrategy extends WindowResizeStrategy {
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
  Future<void> expand(Size targetSize, void Function() onExpanded) async {
    await AppLogger.debug(
        'LinuxResizeStrategy.expand() START target=w${targetSize.width}×h${targetSize.height}');
    // Advisory — ignored by GTK when max-cap is still the collapsed height.
    await _wm.setSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.expand() setSize done');
    // min(target) > max(collapsed) = intentionally invalid constraint.
    // GTK resolves the conflict by growing the window to targetSize.
    await _wm.setMinimumSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.expand() setMinimumSize done');
    // Formalise: lift the max-cap now that the window has grown.
    await _wm.setMaximumSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.expand() setMaximumSize done');
    // After the first grow, some XWayland sessions keep Flutter's layout
    // surface at the old collapsed height on subsequent expands. A final
    // setSize with valid min/max constraints forces a new size-allocate.
    await _wm.setSize(targetSize);
    await AppLogger.debug(
        'LinuxResizeStrategy.expand() final setSize done — calling onExpanded');
    onExpanded();
  }

  @override
  Future<void> collapse(Size targetSize) async {
    await AppLogger.debug(
        'LinuxResizeStrategy.collapse() START target=w${targetSize.width}×h${targetSize.height}');
    await _wm.setSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.collapse() setSize done');
    // Lower the min-floor left by a previous expand before applying max-cap.
    await _wm.setMinimumSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.collapse() setMinimumSize done');
    // setMaximumSize forces the compositor to shrink when setSize was ignored.
    await _wm.setMaximumSize(targetSize);
    await AppLogger.debug('LinuxResizeStrategy.collapse() setMaximumSize done');
    // Re-anchor to (0,0) of the primary display. On Linux the window manager
    // may rescue/move the window to an arbitrary position when a monitor is
    // disconnected (build/tmp line 2054: 3840→2944 display change). Without
    // this call the strip drifts away from the top-left corner.
    await _wm.setPosition(Offset.zero);
    await AppLogger.debug('LinuxResizeStrategy.collapse() setPosition done');
  }
}
