import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/timeline_strip.dart';

// Fake clock that emits a single fixed time — avoids real 1-second waits.
class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;

  @override
  Stream<DateTime> get tick => Stream.value(fixedTime);
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 1200, height: 52, child: child),
      ),
    );

void main() {
  // Use actual now so events in the future are genuinely upcoming.
  final now = DateTime.now();
  final clock = _FakeClock(now);

  group('TimelineStrip', () {
    testWidgets('shows CelebrationWidget when no future events', (tester) async {
      await tester.pumpWidget(_wrap(
        TimelineStrip(events: const [], clockService: clock),
      ));
      await tester.pump();
      expect(find.byType(CelebrationWidget), findsOneWidget);
    });

    testWidgets('shows CountdownDisplay when future events exist', (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Standup',
          startTime: now.add(const Duration(minutes: 38)),
          endTime: now.add(const Duration(minutes: 68)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      await tester.pumpWidget(_wrap(
        TimelineStrip(events: events, clockService: clock),
      ));
      await tester.pump();
      expect(find.byType(CountdownDisplay), findsOneWidget);
    });

    testWidgets('shows "38 min" countdown for event 38 min away', (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Standup',
          startTime: now.add(const Duration(minutes: 38)),
          endTime: now.add(const Duration(minutes: 68)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      await tester.pumpWidget(_wrap(
        TimelineStrip(events: events, clockService: clock),
      ));
      await tester.pump();
      expect(find.text('38 min'), findsOneWidget);
    });

    testWidgets('only counts down to next future event, not past ones',
        (tester) async {
      final events = [
        // Past event — should be ignored for countdown
        CalendarEvent(
          id: 'past',
          title: 'Past Meeting',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.subtract(const Duration(minutes: 30)),
          color: Colors.grey,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
        // Future event
        CalendarEvent(
          id: 'future',
          title: 'Upcoming',
          startTime: now.add(const Duration(minutes: 15)),
          endTime: now.add(const Duration(minutes: 45)),
          color: Colors.green,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      await tester.pumpWidget(_wrap(
        TimelineStrip(events: events, clockService: clock),
      ));
      await tester.pump();
      expect(find.text('15 min'), findsOneWidget);
    });
  });
}
