import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';

CalendarEvent _event({String? videoCallUrl, String? calendarEventUrl}) =>
    CalendarEvent(
      id: 'e1',
      title: 'Team Standup',
      startTime: DateTime(2026, 2, 27, 10, 0),
      endTime: DateTime(2026, 2, 27, 10, 30),
      color: Colors.blue,
      calendarEventUrl: calendarEventUrl,
      videoCallUrl: videoCallUrl,
    );

Widget _wrap(
  Widget child, {
  bool alwaysUse24HourFormat = false,
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(alwaysUse24HourFormat: alwaysUse24HourFormat),
        child: Scaffold(body: child),
      ),
    );

void main() {
  group('HoverDetailOverlay', () {
    testWidgets('shows event title', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('Team Standup'), findsOneWidget);
    });

    testWidgets('uses localized 12-hour time range by default', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('10:00 AM – 10:30 AM'), findsOneWidget);
    });

    testWidgets('uses platform 24-hour time range when requested',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HoverDetailOverlay(event: _event()),
        alwaysUse24HourFormat: true,
      ));
      expect(find.text('10:00 – 10:30'), findsOneWidget);
    });

    testWidgets('shows JOIN button when videoCallUrl present', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(
          event: _event(videoCallUrl: 'https://meet.google.com/abc'))));
      expect(find.text('JOIN'), findsOneWidget);
    });

    testWidgets('hides JOIN button when videoCallUrl absent', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('JOIN'), findsNothing);
    });

    testWidgets('shows OPEN button when calendarEventUrl present',
        (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(
          event: _event(calendarEventUrl: 'https://calendar.google.com/e/1'))));
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('hides OPEN button when calendarEventUrl absent',
        (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('OPEN'), findsNothing);
    });

    testWidgets('shows both buttons when both URLs present', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(
        event: _event(
          calendarEventUrl: 'https://calendar.google.com/e/1',
          videoCallUrl: 'https://meet.google.com/abc',
        ),
      )));
      expect(find.text('OPEN'), findsOneWidget);
      expect(find.text('JOIN'), findsOneWidget);
    });
  });
}
