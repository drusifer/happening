import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  group('TimelineLayout', () {
    // 10:00 AM, strip 1200px wide, nowIndicator at x=200
    // window: 09:00–18:00 (9 hours = 32400 seconds)
    late DateTime now;
    late TimelineLayout layout;

    setUp(() {
      now = DateTime(2026, 2, 26, 10, 0, 0);
      layout = TimelineLayout(
        stripWidth: 1200.0,
        nowIndicatorX: 200.0,
        windowStart: now.subtract(const Duration(hours: 1)),
        windowEnd: now.add(const Duration(hours: 8)),
      );
    });

    // ── Core position formula ─────────────────────────────────────────────
    test('event starting exactly at now is at nowIndicatorX', () {
      expect(layout.xForTime(now, now), closeTo(200.0, 0.01));
    });

    test('future event is to the right of nowIndicatorX', () {
      final x = layout.xForTime(now.add(const Duration(hours: 1)), now);
      expect(x, greaterThan(200.0));
    });

    test('past event is to the left of nowIndicatorX', () {
      final x = layout.xForTime(now.subtract(const Duration(minutes: 30)), now);
      expect(x, lessThan(200.0));
    });

    // ── Proportionality ───────────────────────────────────────────────────
    test('2-hour gap is exactly twice as wide as 1-hour gap', () {
      final x0 = layout.xForTime(now, now);
      final x1 = layout.xForTime(now.add(const Duration(hours: 1)), now);
      final x2 = layout.xForTime(now.add(const Duration(hours: 2)), now);
      expect(x2 - x0, closeTo((x1 - x0) * 2, 0.01));
    });

    test('pixelsPerSecond is positive', () {
      expect(layout.pixelsPerSecond, greaterThan(0.0));
    });

    test('stripWidth divided by window seconds equals pixelsPerSecond', () {
      final windowSeconds = layout.windowStart
          .difference(layout.windowEnd)
          .abs()
          .inSeconds
          .toDouble();
      expect(layout.pixelsPerSecond, closeTo(1200.0 / windowSeconds, 0.001));
    });

    // ── Countdown ─────────────────────────────────────────────────────────
    test('countdownTo returns positive duration for future event', () {
      final future = now.add(const Duration(minutes: 38));
      expect(layout.countdownTo(future, now).inMinutes, equals(38));
    });

    test('countdownTo returns zero duration when event is now', () {
      expect(layout.countdownTo(now, now), equals(Duration.zero));
    });

    test('countdownTo returns zero for past events', () {
      final past = now.subtract(const Duration(minutes: 10));
      expect(layout.countdownTo(past, now), equals(Duration.zero));
    });

    // ── Visibility ────────────────────────────────────────────────────────
    test('isVisible returns true for event within window', () {
      final inWindow = now.add(const Duration(hours: 2));
      expect(layout.isVisible(inWindow), isTrue);
    });

    test('isVisible returns false for event beyond window end', () {
      final beyondWindow = now.add(const Duration(hours: 9));
      expect(layout.isVisible(beyondWindow), isFalse);
    });

    test('isVisible returns false for event before window start', () {
      final beforeWindow = now.subtract(const Duration(hours: 2));
      expect(layout.isVisible(beforeWindow), isFalse);
    });

    // ── Hit Testing (S3-R02) ──────────────────────────────────────────────
    group('eventAtX', () {
      final event1 = CalendarEvent(
        id: '1',
        title: 'Meeting 1',
        startTime: DateTime(2026, 2, 26, 11, 0), // 1 hour in future
        endTime: DateTime(2026, 2, 26, 12, 0),   // 2 hours in future
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      test('returns event when mouse is in the middle of it', () {
        final x = layout.xForTime(DateTime(2026, 2, 26, 11, 30), now);
        expect(layout.eventAtX(x, [event1], now), equals(event1));
      });

      test('returns event when mouse is at the very start edge', () {
        final x = layout.xForTime(event1.startTime, now);
        expect(layout.eventAtX(x, [event1], now), equals(event1));
      });

      test('returns event when mouse is at the very end edge', () {
        final x = layout.xForTime(event1.endTime, now);
        expect(layout.eventAtX(x, [event1], now), equals(event1));
      });

      test('returns null when mouse is before the event', () {
        final x = layout.xForTime(event1.startTime.subtract(const Duration(seconds: 1)), now);
        expect(layout.eventAtX(x, [event1], now), isNull);
      });

      test('returns null when mouse is after the event', () {
        final x = layout.xForTime(event1.endTime.add(const Duration(seconds: 1)), now);
        expect(layout.eventAtX(x, [event1], now), isNull);
      });

      test('returns null when list is empty', () {
        expect(layout.eventAtX(100.0, [], now), isNull);
      });
    });
  });
}
