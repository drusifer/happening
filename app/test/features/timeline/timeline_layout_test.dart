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

    // ── Exact-overlap stacking ────────────────────────────────────────────
    group('computeExactOverlapRanks', () {
      CalendarEvent evt(String id, int startHour, int endHour) => CalendarEvent(
            id: id,
            title: id,
            startTime: DateTime(2026, 2, 26, startHour),
            endTime: DateTime(2026, 2, 26, endHour),
            color: Colors.blue,
            calendarEventUrl: null,
            videoCallUrl: null,
          );

      test('returns empty map when no events overlap exactly', () {
        final ranks = layout
            .computeExactOverlapRanks([evt('a', 9, 10), evt('b', 11, 12)], now);
        expect(ranks, isEmpty);
      });

      test('returns empty map for a single event', () {
        expect(
            layout.computeExactOverlapRanks([evt('a', 9, 10)], now), isEmpty);
      });

      test(
          'assigns rank 0 and 1 to two exactly-overlapping events sorted by id',
          () {
        final ranks = layout
            .computeExactOverlapRanks([evt('b', 9, 10), evt('a', 9, 10)], now);
        expect(ranks['a'], equals((rank: 0, groupSize: 2)));
        expect(ranks['b'], equals((rank: 1, groupSize: 2)));
      });

      test('assigns ranks 0,1,2 to three exactly-overlapping events', () {
        final ranks = layout.computeExactOverlapRanks(
            [evt('c', 11, 12), evt('a', 11, 12), evt('b', 11, 12)], now);
        expect(ranks['a']?.rank, 0);
        expect(ranks['b']?.rank, 1);
        expect(ranks['c']?.rank, 2);
        for (final info in ranks.values) {
          expect(info.groupSize, 3);
        }
      });

      test('handles two separate exact-overlap groups independently', () {
        final ranks = layout.computeExactOverlapRanks([
          evt('a', 9, 10),
          evt('b', 9, 10),
          evt('x', 11, 12),
          evt('y', 11, 12),
        ], now);
        expect(ranks['a']?.groupSize, 2);
        expect(ranks['x']?.groupSize, 2);
        expect(ranks['a']?.rank, 0);
        expect(ranks['b']?.rank, 1);
        expect(ranks['x']?.rank, 0);
        expect(ranks['y']?.rank, 1);
      });

      test('partial-overlap events are not grouped', () {
        // a: 9-11, b: 10-12 — partial overlap, NOT exact match
        final ranks = layout
            .computeExactOverlapRanks([evt('a', 9, 11), evt('b', 10, 12)], now);
        expect(ranks, isEmpty);
      });

      test('tasks are excluded from overlap groups', () {
        final task = CalendarEvent(
          id: 'a',
          title: 'task',
          startTime: DateTime(2026, 2, 26, 9),
          endTime: DateTime(2026, 2, 26, 10),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
          isTask: true,
        );
        final regular = evt('a', 9, 10);
        expect(layout.computeExactOverlapRanks([task, regular], now), isEmpty);
      });
    });

    group('effectiveEndX with overlap ranks', () {
      CalendarEvent evt(String id, int startHour, int endHour) => CalendarEvent(
            id: id,
            title: id,
            startTime: DateTime(2026, 2, 26, startHour),
            endTime: DateTime(2026, 2, 26, endHour),
            color: Colors.blue,
            calendarEventUrl: null,
            videoCallUrl: null,
          );

      test('rank-0 event has same effectiveEndX as raw end', () {
        final a = evt('a', 11, 12);
        final b = evt('b', 11, 12);
        final ranks = layout.computeExactOverlapRanks([a, b], now);
        final rawEndX = layout.xForTime(a.endTime, now);
        expect(layout.effectiveEndX(a, now, ranks), closeTo(rawEndX, 0.01));
      });

      test('rank-1 event effectiveEndX is overlapStepPx less than rank-0', () {
        final a = evt('a', 11, 12);
        final b = evt('b', 11, 12);
        final ranks = layout.computeExactOverlapRanks([a, b], now);
        final endA = layout.effectiveEndX(a, now, ranks);
        final endB = layout.effectiveEndX(b, now, ranks);
        expect(endA - endB, closeTo(layout.overlapStepPx, 0.01));
      });

      test('each rank step is exactly overlapStepPx apart', () {
        final a = evt('a', 11, 12);
        final b = evt('b', 11, 12);
        final c = evt('c', 11, 12);
        final ranks = layout.computeExactOverlapRanks([a, b, c], now);
        final endA = layout.effectiveEndX(a, now, ranks);
        final endB = layout.effectiveEndX(b, now, ranks);
        final endC = layout.effectiveEndX(c, now, ranks);
        expect(endA - endB, closeTo(layout.overlapStepPx, 0.01));
        expect(endB - endC, closeTo(layout.overlapStepPx, 0.01));
      });
    });

    group('eventAtX with exact-overlap stacking', () {
      final start = DateTime(2026, 2, 26, 11, 0);
      final end = DateTime(2026, 2, 26, 12, 0);

      CalendarEvent evt(String id) => CalendarEvent(
            id: id,
            title: id,
            startTime: start,
            endTime: end,
            color: Colors.blue,
            calendarEventUrl: null,
            videoCallUrl: null,
          );

      test('in the shared overlap region, returns the top (highest-rank) event',
          () {
        final a = evt('a'); // rank 0
        final b = evt('b'); // rank 1
        // Mouse well inside both events (left of b's trimmed right edge)
        final midX = layout.xForTime(start, now) + 10;
        expect(layout.eventAtX(midX, [a, b], now), equals(b));
      });

      test('in the peeking region, returns the bottom (rank-0) event', () {
        final a = evt('a'); // rank 0 — full width
        final b = evt('b'); // rank 1 — trimmed by overlapStepPx (10px)
        final rawEndX = layout.xForTime(end, now);
        // Mouse 5px inside rank-0's end — past rank-1's trimmed edge
        final peekX = rawEndX - 5;
        expect(layout.eventAtX(peekX, [a, b], now), equals(a));
      });

      test('three stacked events: peeking regions resolve correctly', () {
        final a = evt('a'); // rank 0 — no trim
        final b = evt('b'); // rank 1 — trimmed by 10px
        final c = evt('c'); // rank 2 — trimmed by 20px
        final rawEndX = layout.xForTime(end, now);
        // Rank-0 only: mouse inside last 10px (past rank-1's edge at rawEndX-10)
        expect(layout.eventAtX(rawEndX - 5, [a, b, c], now), equals(a));
        // Rank-0 + rank-1: between 10px and 20px from end (past rank-2's edge)
        expect(layout.eventAtX(rawEndX - 15, [a, b, c], now), equals(b));
        // All three: well inside all events
        expect(layout.eventAtX(rawEndX - 25, [a, b, c], now), equals(c));
      });
    });

    // ── S4-19: Gap Labels ─────────────────────────────────────────────────
    group('gapsBetween', () {
      CalendarEvent evt(String id, int startHour, int endHour) => CalendarEvent(
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
        expect(layout.gapsBetween([evt('a', 11, 12)], now), isEmpty);
      });

      test('returns gap between two events with enough pixel space', () {
        // Event A: 11:00–12:00, Event B: 13:00–14:00 → 1hr gap
        final gaps =
            layout.gapsBetween([evt('a', 11, 12), evt('b', 13, 14)], now);
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
          evt('a', 11, 12),
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
        final backToBack = [evt('a', 11, 12), evt('b', 12, 13)];
        expect(layout.gapsBetween(backToBack, now), isEmpty);
      });

      test('returns two gaps for three spaced events', () {
        final gaps = layout.gapsBetween(
            [evt('a', 10, 11), evt('b', 12, 13), evt('c', 14, 15)], now);
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
