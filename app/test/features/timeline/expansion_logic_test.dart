import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

void main() {
  const stripHeight = 30.0;

  group('ExpansionLogic.determineState (2D Rect Rules - Simplified)', () {
    test('Rule 1: Settings open forces Expanded', () {
      final state = ExpansionLogic.determineState(
        details: const PointerMoveEvent(position: Offset(50, 10)),
        eventBounds: [],
        stripHeight: stripHeight,
        isSettingsOpen: true,
      );
      expect(state, ExpansionState.expanded);
    });

    test('Rule 2: Vertical Guard (above strip) is Collapsed', () {
      final state = ExpansionLogic.determineState(
        details: const PointerMoveEvent(position: Offset(50, -1)),
        eventBounds: [
          const EventBounds(left: 40, right: 60, top: 0, bottom: 190)
        ],
        stripHeight: stripHeight,
        isSettingsOpen: false,
      );
      expect(state, ExpansionState.collapsed);
    });

    test('Rule 3: Mouse inside 2D Rect is Expanded', () {
      final state = ExpansionLogic.determineState(
        details: const PointerMoveEvent(position: Offset(50, 100)), // Inside rect
        eventBounds: [
          const EventBounds(left: 40, right: 60, top: 0, bottom: 190)
        ],
        stripHeight: stripHeight,
        isSettingsOpen: false,
      );
      expect(state, ExpansionState.expanded);
    });

    test('Rule 3: Mouse below 2D Rect is Collapsed', () {
      final state = ExpansionLogic.determineState(
        details: const PointerMoveEvent(position: Offset(50, 200)), // Below rect (bottom is 190)
        eventBounds: [
          const EventBounds(left: 40, right: 60, top: 0, bottom: 190)
        ],
        stripHeight: stripHeight,
        isSettingsOpen: false,
      );
      expect(state, ExpansionState.collapsed);
    });

    test('Rule 3: Mouse outside 2D Rect X-bounds is Collapsed', () {
      final state = ExpansionLogic.determineState(
        details: const PointerMoveEvent(position: Offset(100, 100)), // Outside rect
        eventBounds: [
          const EventBounds(left: 40, right: 60, top: 0, bottom: 190)
        ],
        stripHeight: stripHeight,
        isSettingsOpen: false,
      );
      expect(state, ExpansionState.collapsed);
    });
  });
}
