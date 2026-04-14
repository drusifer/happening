// Pure-logic expansion state calculation for the timeline strip.
//
// TLDR:
// Overview: Defines the ExpansionState and logic for determining hover behavior.
// Problem: Coordination between event hit-testing and mouse position is complex and error-prone.
// Solution: A stateless class with a pure function to determine the intended state.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:happening/core/util/logger.dart';

/// The intended state of the hover card/window.
enum ExpansionState {
  /// The window is expanded to show the hover card or settings.
  expanded,

  /// The window is collapsed to the 30px strip height.
  collapsed,
}

/// A representation of the 2D bounds of an event's interactive area.
class EventBounds {
  const EventBounds({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final double left;
  final double right;
  final double top;
  final double bottom;

  bool contains(double x, double y) =>
      x >= left && x <= right && y >= top && y <= bottom;

  @override
  String toString() =>
      'Rect(l:${left.toStringAsFixed(1)}, r:${right.toStringAsFixed(1)}, t:${top.toStringAsFixed(1)}, b:${bottom.toStringAsFixed(1)})';
}

/// Pure logic for expansion behavior.
///
/// This class MUST NOT depend on Flutter or any other project classes.
class ExpansionLogic {
  /// Determines the intended [ExpansionState] based on coordinates and state.
  ///
  /// [details] Current pointer event, or null when called from a lifecycle change.
  /// [eventBounds] List of 2D pixel bounds for all visible events.
  /// [stripHeight] The height of the timeline strip (e.g., 30.0).
  /// [isSettingsOpen] Whether the settings panel is currently active.
  static ExpansionState determineState({
    PointerEvent? details,
    required List<EventBounds> eventBounds,
    required double stripHeight,
    required bool isSettingsOpen,
  }) {
    // 1. Settings always forces expansion.
    if (isSettingsOpen) {
      unawaited(AppLogger.debug('ExpansionLogic -> Expanded (Settings Open)'));
      return ExpansionState.expanded;
    }

    // No pointer event means this was a lifecycle-only call; if settings is closed, we collapse.
    if (details == null) {
      return ExpansionState.collapsed;
    }

    double mouseX = details.localPosition.dx;
    double mouseY = details.localPosition.dy;
    //unawaited(AppLogger.debug('ExpansionLogic x=${mouseX.toStringAsFixed(1)} y=${mouseY.toStringAsFixed(1)} '
    //    'events=${eventBounds.length} settings=$isSettingsOpen'));

    if (details is PointerExitEvent) {
      return ExpansionState.collapsed;
    }

    // 2. Vertical Guard: If the mouse is above the strip, we are collapsed.
    if (mouseY < 0) {
      return ExpansionState.collapsed;
    }

    // 3. Rect Bounds Rule: Expansion is driven by whether the mouse is within
    // the 2D rectangle of an event's interaction zone (Column + Card).
    for (final bounds in eventBounds) {
      if (bounds.contains(mouseX, mouseY)) {
        return ExpansionState.expanded;
      }
    }

    // 4. Default: If not inside any event's interactive rectangle.
    return ExpansionState.collapsed;
  }

  /// Determines if the hover logic should prioritize the currently open card
  /// (The Latch) or allow switching to a new event.
  ///
  /// Returns true if the mouse is in the "Card Zone" (below the strip).
  /// Returns false if the mouse is in the "Strip Zone" (on the strip).
  static bool shouldPrioritizeLatch(double mouseY, double stripHeight) {
    // If we are below the strip (y >= height), we are in the card area.
    // We should LATCH (keep current event) to prevent accidental switching.
    return mouseY >= stripHeight;
  }
}
