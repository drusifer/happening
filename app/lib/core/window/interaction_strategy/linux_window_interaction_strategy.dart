import 'reserved_window_interaction_strategy.dart';

/// Linux (X11) interaction strategy.
///
/// The strip is a dock-type window. Mutter (GNOME) keeps docks in a layer above
/// normal windows, so dropping always-on-top and blurring does not put it
/// behind anything. A dock carrying `_NET_WM_STATE_BELOW` is moved to the
/// bottom layer instead, so send-to-back sets always-on-bottom and restore
/// clears it (see DEC-011).
class LinuxWindowInteractionStrategy extends ReservedWindowInteractionStrategy {
  LinuxWindowInteractionStrategy({required super.wm});

  @override
  Future<void> sendToBack() async {
    await super.sendToBack();
    await wm.setAlwaysOnBottom(true);
  }

  @override
  Future<void> restoreToFront() async {
    // Clear BELOW first, or the strip stays pinned to the bottom layer.
    await wm.setAlwaysOnBottom(false);
    await super.restoreToFront();
  }
}
