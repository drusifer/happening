import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  @override
  Future<void> expand({double? height}) async {
    isExpandedNotifier.value = true;
  }

  @override
  Future<void> collapse({double? height}) async {
    isExpandedNotifier.value = false;
  }
}

class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;
  @override
  DateTime get now => fixedTime;
  @override
  Stream<DateTime> get tick1s => Stream.value(fixedTime);
  @override
  Stream<DateTime> get tick10s => Stream.value(fixedTime);
}

class _FakeSettings extends SettingsService {
  _FakeSettings() : super(directory: Directory.systemTemp);
  @override
  Future<void> load() async {}
  @override
  AppSettings get current => const AppSettings();
  @override
  Stream<AppSettings> get settings => const Stream.empty();
}

class _MockCalendarService extends Mock implements CalendarService {
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];
  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async => [];
}

void main() {
  final now = DateTime(2026, 2, 27, 10, 0);
  final clock = _FakeClock(now);
  final settings = _FakeSettings();
  final calendar =
      CalendarController(_MockCalendarService(), settingsService: settings);

  group('TimelineStrip Goldens', () {
    testWidgets('S4-31: hover card follows mouse X (BUG-13 regression)',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Long Meeting',
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.add(const Duration(hours: 2)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.binding.setSurfaceSize(const Size(800, 250));

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: TimelineStrip(
            events: events,
            clockService: clock,
            calendarController: calendar,
            settingsService: settings,
            windowService: _FakeWindowService(),
            onSignOut: () {},
            enableAnimations: false, // crucial for golden tests
          ),
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      // Hover over the long event column (near the now line)
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump();

      await expectLater(
        find.byType(TimelineStrip),
        matchesGoldenFile('goldens/hover_card_alignment.png'),
      );

      await gesture.removePointer();
      await tester.binding.setSurfaceSize(null);
    });
  });
}
