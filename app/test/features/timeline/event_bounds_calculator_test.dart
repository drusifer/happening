import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/event_bounds_calculator.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  final now = DateTime(2026, 3, 18, 10, 0);

  CalendarEvent makeEvent(String id, DateTime start, DateTime end) =>
      CalendarEvent(
        id: id,
        title: id,
        startTime: start,
        endTime: end,
        color: Colors.red,
        calendarEventUrl: '',
        videoCallUrl: null,
      );

  // Layout: 10:00–18:00 window, 800px wide
  final layout = TimelineLayout(
    windowStart: DateTime(2026, 3, 18, 10, 0),
    windowEnd: DateTime(2026, 3, 18, 18, 0),
    stripWidth: 800,
    nowIndicatorX: 0,
  );

  final event = makeEvent(
    'e1',
    DateTime(2026, 3, 18, 12, 0), // 2h in → x=200
    DateTime(2026, 3, 18, 14, 0), // 4h in → x=400
  );

  group('EventBoundsCalculator.compute', () {
    test('strip zone: bounds follow event x positions', () {
      final bounds = EventBoundsCalculator.compute(
        events: [event],
        layout: layout,
        now: now,
        stripHeight: 55,
        isOverStripZone: true,
      );

      expect(bounds['e1'], isNotNull);
      final b = bounds['e1']!;
      expect(b.top, 0);
      expect(b.bottom, 55);
      expect(b.left, closeTo(200, 1));
      expect(b.right, greaterThan(b.left));
    });

    test('card zone: bounds use card layout', () {
      final bounds = EventBoundsCalculator.compute(
        events: [event],
        layout: layout,
        now: now,
        stripHeight: 55,
        isOverStripZone: false,
      );

      expect(bounds['e1'], isNotNull);
      final b = bounds['e1']!;
      expect(b.top, 55);          // starts at strip bottom
      expect(b.bottom, 175);      // fixed card zone
      expect(b.left, greaterThanOrEqualTo(4.0)); // clamped
    });

    test('returns entry for each event', () {
      final e2 = makeEvent(
        'e2',
        DateTime(2026, 3, 18, 14, 0),
        DateTime(2026, 3, 18, 15, 0),
      );
      final bounds = EventBoundsCalculator.compute(
        events: [event, e2],
        layout: layout,
        now: now,
        stripHeight: 55,
        isOverStripZone: true,
      );
      expect(bounds.keys, containsAll(['e1', 'e2']));
    });

    test('empty events returns empty map', () {
      final bounds = EventBoundsCalculator.compute(
        events: [],
        layout: layout,
        now: now,
        stripHeight: 55,
        isOverStripZone: true,
      );
      expect(bounds, isEmpty);
    });
  });
}
