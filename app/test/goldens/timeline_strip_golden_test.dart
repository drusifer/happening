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

// ── Minimal Fakes ─────────────────────────────────────────────────────────

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  bool _wantsExpanded = false;

  @override
  bool get isExpanded => _wantsExpanded;

  @override
  Future<void> expand({double? height}) async {
    if (_wantsExpanded) return;
    _wantsExpanded = true;
  }

  @override
  Future<void> collapse({double? height}) async {
    if (!_wantsExpanded) return;
    _wantsExpanded = false;
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
}

class _FakeCalendarService implements CalendarService {
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async => [];

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

// ──────────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('S4-31: hover card follows mouse X (BUG-13 regression)',
      (tester) async {
    final now = DateTime(2026, 3, 1, 10, 0, 0);
    final event = CalendarEvent(
      id: 'e1',
      title: 'Long Meeting',
      startTime: now.subtract(const Duration(minutes: 90)), // before window
      endTime: now.add(const Duration(hours: 3)), // endX ~570 > 500; covers x=300 and x=500
      color: Colors.red,
      calendarEventUrl: null,
      videoCallUrl: null,
    );

    final clock = _FakeClock(now);
    final settings = _FakeSettings();
    final controller = CalendarController(_FakeCalendarService());
    final windowService = _FakeWindowService();

    // Widen surface so strip gets its full layout
    await tester.binding.setSurfaceSize(const Size(1200, 300));

    await tester.pumpWidget(
      MaterialApp(
        showSemanticsDebugger: false,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TimelineStrip(
            events: [event],
            clockService: clock,
            calendarController: controller,
            settingsService: settings,
            onSignOut: () {},
            windowService: windowService,
          ),
        ),
      ),
    );

    await tester.pump();

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    // Hover at x=300 (inside the 1200px strip)
    await gesture.moveTo(const Offset(300, 10));
    await tester.pump();

    // Hover card should be centered around the visible event center, NOT 300
    await expectLater(
      find.byType(TimelineStrip),
      matchesGoldenFile('goldens/hover_card_fixed.png'),
    );

    // Move to x=500 — card should NOT follow (should stay fixed on event center)
    await gesture.moveTo(const Offset(500, 10));
    await tester.pump();

    await expectLater(
      find.byType(TimelineStrip),
      matchesGoldenFile('goldens/hover_card_fixed.png'),
    );

    await gesture.removePointer();
  });

  testWidgets('S5-E4: persistent card on tap and HTML stripping',
      (tester) async {
    final now = DateTime(2026, 3, 1, 10, 0, 0);
    final event = CalendarEvent(
      id: 'e1',
      title: 'HTML Event',
      description:
          '<b>Bold</b> and <i>Italic</i> description with <a href="#">Link</a>',
      startTime: now.add(const Duration(minutes: 10)),
      endTime: now.add(const Duration(minutes: 40)),
      color: Colors.blue,
      calendarEventUrl: null,
      videoCallUrl: null,
    );

    final clock = _FakeClock(now);
    final settings = _FakeSettings();
    final controller = CalendarController(_FakeCalendarService());
    final windowService = _FakeWindowService();

    await tester.binding.setSurfaceSize(const Size(1200, 300));

    await tester.pumpWidget(
      MaterialApp(
        showSemanticsDebugger: false,
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: TimelineStrip(
            events: [event],
            clockService: clock,
            calendarController: controller,
            settingsService: settings,
            onSignOut: () {},
            windowService: windowService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final gesture =
        await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    // 1. Hover over the event block (x=160 hit task)
    await gesture.moveTo(const Offset(160, 15));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // The card should be visible because it is hovered.
    expect(find.text('Bold and Italic description with Link'), findsOneWidget);

    await expectLater(
      find.byType(TimelineStrip),
      matchesGoldenFile('goldens/persistent_tap_card.png'),
    );

    await gesture.removePointer();
  });
}
