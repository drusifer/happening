import 'base_window_interaction_strategy.dart';
import 'window_interaction_strategy.dart';

class ReservedWindowInteractionStrategy extends BaseWindowInteractionStrategy {
  ReservedWindowInteractionStrategy({required super.wm});

  @override
  WindowModeAvailability get availability =>
      const WindowModeAvailability(supportsReserved: true);
}
