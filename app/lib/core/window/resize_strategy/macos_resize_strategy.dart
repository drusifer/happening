import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'window_resize_strategy.dart';

// macOS platform window resize strategy implementation.
//
// TLDR:
// Overview: Handles macOS frameless window expansion and collapse transitions.
// Problem:  Accidental user resizes and window displacement must be prevented on macOS.
// Solution: Inherits the base defaults (resizable=false, since macOS honors
//           setSize regardless) and the shared resize order.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------
class MacOsResizeStrategy extends WindowResizeStrategy {
  MacOsResizeStrategy({
    required WindowManager wm,
    required ScreenRetriever sr,
  }) : _wm = wm;

  final WindowManager _wm;

  @override
  WindowManager get wm => _wm;
}
