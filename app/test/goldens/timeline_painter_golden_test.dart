import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'golden_helper.dart';

void main() {
  testWidgets('S4-30: ticks are visible over event blocks (paint order)', (tester) async {
    // 10:00 AM. 
    // Tick for 10am will be at nowIndicatorX.
    // Tick for 11am will be to the right.
    final now = DateTime(2026, 3, 1, 10, 0, 0);
    final events = [
      CalendarEvent(
        id: '1',
        title: 'Meeting 1',
        startTime: now.subtract(const Duration(minutes: 30)), // 09:30
        endTime: now.add(const Duration(hours: 1, minutes: 30)), // 11:30
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      ),
    ];

    await pumpTimelinePainter(
      tester,
      events: events,
      now: now,
      width: 1200,
      height: 30,
    );

    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('goldens/ticks_over_events.png'),
    );
  });

  testWidgets('S4-33: Golden UAT edge cases (UAT render)', (tester) async {
    final now = DateTime(2026, 3, 1, 10, 0, 0);
    final events = [
      CalendarEvent(
        id: 'active',
        title: 'Current Event',
        startTime: now.subtract(const Duration(minutes: 45)),
        endTime: now.add(const Duration(minutes: 15)),
        color: Colors.redAccent,
        calendarEventUrl: null,
        videoCallUrl: null,
      ),
      CalendarEvent(
        id: 'task',
        title: 'Task Marker',
        startTime: now.add(const Duration(minutes: 45)),
        endTime: now.add(const Duration(minutes: 105)),
        color: Colors.green,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      ),
      CalendarEvent(
        id: 'future',
        title: 'Next Meeting',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        color: Colors.blueAccent,
        calendarEventUrl: null,
        videoCallUrl: null,
      ),
    ];

    await pumpTimelinePainter(
      tester,
      events: events,
      now: now,
      width: 1200,
      height: 30,
    );

    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('goldens/uat_edge_cases.png'),
    );
  });
}
