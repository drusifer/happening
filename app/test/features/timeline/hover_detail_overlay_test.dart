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

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('HoverDetailOverlay', () {
    testWidgets('shows event title', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('Team Standup'), findsOneWidget);
    });

    testWidgets('shows formatted time range', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('10:00 – 10:30'), findsOneWidget);
    });

    testWidgets('shows Join Meeting button when videoCallUrl present',
        (tester) async {
      await tester.pumpWidget(_wrap(
          HoverDetailOverlay(event: _event(videoCallUrl: 'https://meet.google.com/abc'))));
      expect(find.text('Join Meeting'), findsOneWidget);
    });

    testWidgets('hides Join Meeting button when videoCallUrl absent',
        (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('Join Meeting'), findsNothing);
    });

    testWidgets('shows Open in Cal button when calendarEventUrl present',
        (tester) async {
      await tester.pumpWidget(_wrap(
          HoverDetailOverlay(event: _event(calendarEventUrl: 'https://calendar.google.com/e/1'))));
      expect(find.text('Open in Cal'), findsOneWidget);
    });

    testWidgets('hides Open in Cal button when calendarEventUrl absent',
        (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(event: _event())));
      expect(find.text('Open in Cal'), findsNothing);
    });

    testWidgets('shows both buttons when both URLs present', (tester) async {
      await tester.pumpWidget(_wrap(HoverDetailOverlay(
        event: _event(
          calendarEventUrl: 'https://calendar.google.com/e/1',
          videoCallUrl: 'https://meet.google.com/abc',
        ),
      )));
      expect(find.text('Open in Cal'), findsOneWidget);
      expect(find.text('Join Meeting'), findsOneWidget);
    });
  });
}
