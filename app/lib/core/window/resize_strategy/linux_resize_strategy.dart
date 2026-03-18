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
///           to formalise the new constraints.
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
    // Advisory — ignored by GTK when max-cap is still the collapsed height.
    await _wm.setSize(targetSize);
    // min(target) > max(collapsed) = intentionally invalid constraint.
    // GTK resolves the conflict by growing the window to targetSize.
    await _wm.setMinimumSize(targetSize);
    // Formalise: lift the max-cap now that the window has grown.
    await _wm.setMaximumSize(targetSize);
    onExpanded();
  }

  @override
  Future<void> collapse(Size targetSize) async {
    await _wm.setSize(targetSize);
    // Lower the min-floor left by a previous expand before applying max-cap.
    await _wm.setMinimumSize(targetSize);
    // setMaximumSize forces the compositor to shrink when setSize was ignored.
    await _wm.setMaximumSize(targetSize);
  }
}
