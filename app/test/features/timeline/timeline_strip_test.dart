import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_strip.dart';

class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;

  @override
  Stream<DateTime> get tick => Stream.value(fixedTime);
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService() : super(directory: Directory.systemTemp);

  @override
  Future<void> load() async {}
}

// External Boundary Seam
class _FakeCalendarService implements CalendarService {
  List<CalendarEvent> mockEvents = [];
  int fetchCalls = 0;

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async {
    fetchCalls++;
    return mockEvents;
  }
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 1200, height: 200, child: child),
      ),
    );

void main() {
  final now = DateTime(2026, 2, 27, 10, 0, 0);
  final clock = _FakeClock(now);
  late _FakeCalendarService fakeService;
  late CalendarController realController;
  late _FakeSettingsService fakeSettings;

  setUp(() {
    fakeService = _FakeCalendarService();
    realController = CalendarController(fakeService);
    fakeSettings = _FakeSettingsService();
  });

  group('TimelineStrip', () {
    testWidgets('shows CelebrationWidget when no future events',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      expect(find.byType(CelebrationWidget), findsOneWidget);
    });

    testWidgets('shows CountdownDisplay when future events exist',
        (tester) async {
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
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      expect(find.byType(CountdownDisplay), findsOneWidget);
    });

    testWidgets('shows "38 min" countdown for event 38 min away',
        (tester) async {
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
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      expect(find.text('38 min'), findsOneWidget);
    });

    testWidgets('shows amber countdown when in a meeting (S3-17)',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Active Meeting',
          startTime: now.subtract(const Duration(minutes: 10)),
          endTime: now.add(const Duration(minutes: 20)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();

      final countdownText = tester.widget<Text>(find.descendant(
        of: find.byType(CountdownDisplay),
        matching: find.byType(Text),
      ));
      expect(countdownText.style?.color, const Color(0xFFFFC107)); // Amber
      expect(find.text('20 min'), findsOneWidget);
    });

    testWidgets('shows refresh and settings icons on hover (S3-09)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [
            CalendarEvent(
              id: 'e1',
              title: 'E',
              startTime: now.add(const Duration(minutes: 10)),
              endTime: now.add(const Duration(minutes: 20)),
              color: Colors.blue,
              calendarEventUrl: null,
              videoCallUrl: null,
            )
          ],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();

      // Initially icons are hidden
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);

      // Hover over the strip
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap refresh
      await tester.tap(find.byIcon(Icons.refresh));
      expect(fakeService.fetchCalls, equals(1));

      await gesture.removePointer();
    });

    testWidgets('opens settings panel when gear is tapped (S3-10)',
        (tester) async {
      bool signOutCalled = false;
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () => signOutCalled = true,
        ),
      ));
      await tester.pump(); // CelebrationWidget

      // Hover over the strip
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(find.byType(SettingsPanel), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Tap logout
      await tester.tap(find.text('Logout'));
      expect(signOutCalled, isTrue);

      await gesture.removePointer();
    });
  });
}
