import 'dart:math' as math;

import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Computes the interactive [EventBounds] for all events given mouse context.
///
/// Extracted from TimelineStrip._handleMouse to allow independent unit testing.
class EventBoundsCalculator {
  static const double _minCardWidth = 260.0;
  static const double _cardZoneBottom = 175.0;
  static const double _cardPadding = 4.0;

  static Map<String, EventBounds> compute({
    required List<CalendarEvent> events,
    required TimelineLayout layout,
    required DateTime now,
    required double stripHeight,
    required bool isOverStripZone,
  }) {
    final boundsMap = <String, EventBounds>{};
    for (final e in events) {
      if (isOverStripZone) {
        boundsMap[e.id] = EventBounds(
          left: layout.xForTime(e.startTime, now),
          right: layout.effectiveEndX(e, now),
          top: 0,
          bottom: stripHeight,
        );
      } else {
        final cardW = _cardWidth(e, layout, now, layout.stripWidth);
        final cardL = _cardLeft(e, layout, now, layout.stripWidth, cardW);
        boundsMap[e.id] = EventBounds(
          left: cardL,
          right: cardL + cardW,
          top: stripHeight,
          bottom: _cardZoneBottom,
        );
      }
    }
    return boundsMap;
  }

  static double _cardWidth(
    CalendarEvent e,
    TimelineLayout layout,
    DateTime now,
    double screenWidth,
  ) {
    final startX = layout.xForTime(e.startTime, now);
    final endX = layout.xForTime(e.endTime, now);
    return (endX - startX).abs().clamp(_minCardWidth, double.infinity);
  }

  static double _cardLeft(
    CalendarEvent e,
    TimelineLayout layout,
    DateTime now,
    double screenWidth,
    double cardWidth,
  ) {
    final startX = layout.xForTime(e.startTime, now);
    return startX.clamp(
      _cardPadding,
      math.max(_cardPadding, screenWidth - cardWidth - _cardPadding),
    );
  }
}
