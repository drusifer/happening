import 'base_window_interaction_strategy.dart';
import 'window_interaction_strategy.dart';

class MacOsWindowInteractionStrategy extends BaseWindowInteractionStrategy {
  MacOsWindowInteractionStrategy({required super.wm});

  @override
  WindowModeAvailability get availability =>
      const WindowModeAvailability(supportsReserved: false);
}
