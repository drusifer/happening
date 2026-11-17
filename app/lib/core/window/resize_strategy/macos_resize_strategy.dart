import 'package:happening/core/window/window_adapter.dart';

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
  MacOsResizeStrategy({required WindowAdapter wm}) : _wm = wm;

  final WindowAdapter _wm;

  @override
  WindowAdapter get wm => _wm;
}
