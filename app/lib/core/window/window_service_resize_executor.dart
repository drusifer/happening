import 'package:flutter/material.dart';
import 'package:happening/core/window/resize_executor.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

/// Bridges [ExpansionController] to [WindowService]'s resize strategy.
///
/// TLDR:
/// Overview: Implements ResizeExecutor by delegating directly to WindowService.
/// Problem: ExpansionController must not depend directly on WindowService.
/// Solution: Thin adapter; calls performResize() which bypasses AsyncGate.
/// Breaking Changes: No.
class WindowServiceResizeExecutor implements ResizeExecutor {
  WindowServiceResizeExecutor(this._windowService);

  final WindowService _windowService;

  @override
  double get collapsedHeight => _windowService.getCollapsedHeight();

  @override
  double get expandedHeight => _windowService.getExpandedHeight();

  @override
  Future<void> resize(ExpansionState intent) =>
      _windowService.performResize(intent);
}
