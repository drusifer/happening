import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/countdown_state.dart';

CalendarEvent makeEvent(String id, DateTime start, DateTime end) =>
    CalendarEvent(
      id: id,
      title: id,
      startTime: start,
      endTime: end,
      color: Colors.blue,
      calendarEventUrl: '',
      videoCallUrl: null,
    );

void main() {
  final base = DateTime(2026, 3, 18, 10, 0);

  group('CountdownState.compute', () {
    test('no events → mode untilNext, null target, zero remaining', () {
      final s = CountdownState.compute([], base);
      expect(s.mode, CountdownMode.untilNext);
      expect(s.activeEvent, isNull);
      expect(s.targetTime, isNull);
      expect(s.remaining, Duration.zero);
    });

    test('future event → mode untilNext, target = event start', () {
      final e = makeEvent('e1', base.add(const Duration(minutes: 30)),
          base.add(const Duration(hours: 1)));
      final s = CountdownState.compute([e], base);
      expect(s.mode, CountdownMode.untilNext);
      expect(s.activeEvent, isNull);
      expect(s.targetTime, e.startTime);
      expect(s.remaining, const Duration(minutes: 30));
    });

    test('active event → mode untilEnd, target = event end', () {
      final e = makeEvent(
        'e1',
        base.subtract(const Duration(minutes: 10)),
        base.add(const Duration(minutes: 50)),
      );
      final s = CountdownState.compute([e], base);
      expect(s.mode, CountdownMode.untilEnd);
      expect(s.activeEvent?.id, 'e1');
      expect(s.targetTime, e.endTime);
      expect(s.remaining, const Duration(minutes: 50));
    });

    test('active event with overlap → target = overlap start', () {
      final active = makeEvent(
        'active',
        base.subtract(const Duration(minutes: 5)),
        base.add(const Duration(minutes: 55)),
      );
      final overlap = makeEvent(
        'overlap',
        base.add(const Duration(minutes: 20)),
        base.add(const Duration(minutes: 60)),
      );
      final s = CountdownState.compute([active, overlap], base);
      expect(s.mode, CountdownMode.untilEnd);
      expect(s.targetTime, overlap.startTime);
      expect(s.remaining, const Duration(minutes: 20));
    });

    test('past event → mode untilNext, null target when no future events', () {
      final e = makeEvent(
        'past',
        base.subtract(const Duration(hours: 2)),
        base.subtract(const Duration(hours: 1)),
      );
      final s = CountdownState.compute([e], base);
      expect(s.mode, CountdownMode.untilNext);
      expect(s.targetTime, isNull);
    });
  });
}
