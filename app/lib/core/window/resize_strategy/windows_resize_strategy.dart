import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

/// TLDR: Windows resize strategy. Inherits the base init (resizable=false) and
/// the shared `applySize` geometry (setPosition + setSize). It deliberately does
/// NOT use `setBounds`: that primitive flakes on first show (lands the window at
/// ~1px and `setMinimumSize` can't force-grow it back), whereas `setSize` with
/// the `applySize` max-cap reliably snaps the window to the target — including
/// narrow widths (see LESSONS L-005).
class WindowsResizeStrategy extends WindowResizeStrategy {
  WindowsResizeStrategy({
    required WindowManager wm,
    required ScreenRetriever sr,
  })  : _wm = wm,
        // ignore: unused_field
        _sr = sr;

  final WindowManager _wm;
  // ignore: unused_field
  final ScreenRetriever _sr;

  @override
  WindowManager get wm => _wm;
}
