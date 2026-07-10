import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// TLDR: Windows resize strategy. Inherits the base init (resizable=false) and
/// the shared `applySize` geometry (setPosition + setSize). It deliberately does
/// NOT use `setBounds`: that primitive flakes on first show (lands the window at
/// ~1px and `setMinimumSize` can't force-grow it back), whereas `setSize` with
/// the `applySize` max-cap reliably snaps the window to the target — including
/// narrow widths (see LESSONS L-005).
class WindowsResizeStrategy extends WindowResizeStrategy {
  WindowsResizeStrategy({required WindowManager wm}) : _wm = wm;

  final WindowManager _wm;

  @override
  WindowManager get wm => _wm;
}
