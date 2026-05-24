import 'package:happening/core/window/expansion_controller.dart'
    show ExpansionController;
import 'package:happening/features/timeline/expansion_logic.dart';

/// Interface between [ExpansionController] and the OS window layer.
///
/// TLDR:
/// Overview: Thin seam that delegates resize commands to WindowResizeStrategy.
/// Problem: ExpansionController must not depend directly on WindowService.
/// Solution: ResizeExecutor exposes only what the controller needs; WindowService constructs it.
/// Breaking Changes: No.
abstract class ResizeExecutor {
  double get collapsedHeight;
  double get expandedHeight;

  /// Execute the platform resize sequence for [intent].
  Future<void> resize(ExpansionState intent);
}
