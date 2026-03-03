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
        endTime: DateTime(2026, 2, 26, 12, 0), // 2 hours in future
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
        final x = layout.xForTime(
            event1.startTime.subtract(const Duration(seconds: 1)), now);
        expect(layout.eventAtX(x, [event1], now), isNull);
      });

      test('returns null when mouse is after the event', () {
        final x = layout.xForTime(
            event1.endTime.add(const Duration(seconds: 1)), now);
        expect(layout.eventAtX(x, [event1], now), isNull);
      });

      test('returns null when list is empty', () {
        expect(layout.eventAtX(100.0, [], now), isNull);
      });
    });

    // ── S4-19: Gap Labels ─────────────────────────────────────────────────
    group('gapsBetween', () {
      CalendarEvent _evt(String id, int startHour, int endHour) =>
          CalendarEvent(
            id: id,
            title: id,
            startTime: DateTime(2026, 2, 26, startHour),
            endTime: DateTime(2026, 2, 26, endHour),
            color: Colors.blue,
            calendarEventUrl: null,
            videoCallUrl: null,
          );

      test('returns empty when no events', () {
        expect(layout.gapsBetween([], now), isEmpty);
      });

      test('returns empty when single event', () {
        expect(layout.gapsBetween([_evt('a', 11, 12)], now), isEmpty);
      });

      test('returns gap between two events with enough pixel space', () {
        // Event A: 11:00–12:00, Event B: 13:00–14:00 → 1hr gap
        final gaps =
            layout.gapsBetween([_evt('a', 11, 12), _evt('b', 13, 14)], now);
        expect(gaps, hasLength(1));
        expect(gaps.first.minutes, equals(60));
        // centerX should be between xForTime(12:00) and xForTime(13:00)
        final gapStart = layout.xForTime(DateTime(2026, 2, 26, 12), now);
        final gapEnd = layout.xForTime(DateTime(2026, 2, 26, 13), now);
        expect(gaps.first.centerX, closeTo((gapStart + gapEnd) / 2, 0.1));
      });

      test('suppresses gap narrower than minPx', () {
        // Events only 5 min apart — gap will be very narrow in pixels
        final close = [
          _evt('a', 11, 12),
          CalendarEvent(
            id: 'b',
            title: 'b',
            startTime: DateTime(2026, 2, 26, 12, 5),
            endTime: DateTime(2026, 2, 26, 13),
            color: Colors.blue,
            calendarEventUrl: null,
            videoCallUrl: null,
          ),
        ];
        expect(layout.gapsBetween(close, now), isEmpty);
      });

      test('no gap when events are back-to-back', () {
        final backToBack = [_evt('a', 11, 12), _evt('b', 12, 13)];
        expect(layout.gapsBetween(backToBack, now), isEmpty);
      });

      test('returns two gaps for three spaced events', () {
        final gaps = layout.gapsBetween(
            [_evt('a', 10, 11), _evt('b', 12, 13), _evt('c', 14, 15)], now);
        expect(gaps, hasLength(2));
      });
    });

    // ── Tick pixel positions (drives _paintTicks in painter) ─────────────
    group('tick pixel positions', () {
      test('9am tick is off-screen left when windowStart is 09:15', () {
        final now2 = DateTime(2026, 2, 26, 10, 15, 0);
        final l = TimelineLayout(
          stripWidth: 1200.0,
          nowIndicatorX: 120.0,
          windowStart: now2.subtract(const Duration(hours: 1)), // 09:15
          windowEnd: now2.add(const Duration(hours: 8)),
        );
        final nineAm = DateTime(2026, 2, 26, 9, 0, 0);
        // 75 min before now → ≈166px left of nowIndicatorX → off-screen
        expect(l.xForTime(nineAm, now2), lessThan(0.0));
        expect(l.isVisible(nineAm), isFalse); // both agree: not visible
      });

      test(
          '10am tick is on-screen (left of now-line) when windowStart is 09:15',
          () {
        final now2 = DateTime(2026, 2, 26, 10, 15, 0);
        final l = TimelineLayout(
          stripWidth: 1200.0,
          nowIndicatorX: 120.0,
          windowStart: now2.subtract(const Duration(hours: 1)),
          windowEnd: now2.add(const Duration(hours: 8)),
        );
        final tenAm = DateTime(2026, 2, 26, 10, 0, 0);
        final x = l.xForTime(tenAm, now2);
        // 15 min before now → ≈33px left of nowIndicatorX → on-screen
        expect(x, greaterThan(0.0));
        expect(x, lessThan(120.0)); // left of now-line
        expect(l.isVisible(tenAm), isTrue);
      });

      test('windowStart maps to negative x: on-screen range exceeds window',
          () {
        // With 10% nowIndicatorX and 1/9 past fraction, windowStart x ≈ -13px.
        // This means a tick just before windowStart is off-screen — both
        // isVisible and pixel-bounds checks agree for these typical values.
        final now2 = DateTime(2026, 2, 26, 10, 0, 0);
        final l = TimelineLayout(
          stripWidth: 1200.0,
          nowIndicatorX: 120.0,
          windowStart: now2.subtract(const Duration(hours: 1)),
          windowEnd: now2.add(const Duration(hours: 8)),
        );
        // windowStart is at x = 120 - 3600*(1200/32400) ≈ -13.3px
        expect(l.xForTime(l.windowStart, now2), lessThan(0.0));
        // windowEnd is at x = 120 + 28800*(1200/32400) ≈ 1186.7px
        expect(l.xForTime(l.windowEnd, now2), lessThan(l.stripWidth));
      });

      test('18:00 tick is on-screen for default 9-hour window', () {
        final now2 = DateTime(2026, 2, 26, 10, 0, 0);
        final l = TimelineLayout(
          stripWidth: 1200.0,
          nowIndicatorX: 120.0,
          windowStart: now2.subtract(const Duration(hours: 1)),
          windowEnd: now2.add(const Duration(hours: 8)), // windowEnd = 18:00
        );
        final tick18 = DateTime(2026, 2, 26, 18, 0, 0);
        final x = l.xForTime(tick18, now2);
        expect(x, inInclusiveRange(0.0, 1200.0));
        expect(l.isVisible(tick18), isTrue); // 18:00 == windowEnd
      });

      test('all hour ticks 10:00–17:00 are on-screen for default window', () {
        final now2 = DateTime(2026, 2, 26, 10, 0, 0);
        final l = TimelineLayout(
          stripWidth: 1200.0,
          nowIndicatorX: 120.0,
          windowStart: now2.subtract(const Duration(hours: 1)),
          windowEnd: now2.add(const Duration(hours: 8)),
        );
        for (var h = 10; h <= 17; h++) {
          final tick = DateTime(2026, 2, 26, h, 0, 0);
          final x = l.xForTime(tick, now2);
          expect(x, inInclusiveRange(0.0, 1200.0),
              reason: '${h}am tick at x=$x should be on-screen');
        }
      });
    });

    // ── In-Meeting Detection (S3-17) ──────────────────────────────────────
    group('activeEvent', () {
      final event1 = CalendarEvent(
        id: '1',
        title: 'Meeting 1',
        startTime: DateTime(2026, 2, 26, 10, 30), // 30 min in future
        endTime: DateTime(2026, 2, 26, 11, 30),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      test('returns null if no event is active right now', () {
        expect(layout.activeEvent([], now), isNull);
        expect(layout.activeEvent([event1], now), isNull);
      });

      test('returns event if current time is within its bounds', () {
        final activeNow = DateTime(2026, 2, 26, 10, 45);
        expect(layout.activeEvent([event1], activeNow), equals(event1));
      });

      test('returns event if current time is exactly at start', () {
        final activeNow = DateTime(2026, 2, 26, 10, 30);
        expect(layout.activeEvent([event1], activeNow), equals(event1));
      });

      test('returns null if current time is exactly at end (exclusive)', () {
        final activeNow = DateTime(2026, 2, 26, 11, 30);
        expect(layout.activeEvent([event1], activeNow), isNull);
      });
    });
  });
}
