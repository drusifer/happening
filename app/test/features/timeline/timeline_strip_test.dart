import 'dart:async';
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
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

/// Fake WindowService that counts expand/collapse calls without touching the OS.
class _FakeWindowService extends WindowService {
  _FakeWindowService({bool initialExpanded = false})
      : _wantsExpanded = initialExpanded,
        super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  int expandCalls = 0;
  int collapseCalls = 0;
  bool _wantsExpanded = false;

  @override
  bool get isExpanded => _wantsExpanded;

  @override
  Future<void> expand({double? height}) async {
    if (_wantsExpanded) return;
    _wantsExpanded = true;
    expandCalls++;
  }

  @override
  Future<void> collapse({double? height}) async {
    if (!_wantsExpanded) return;
    _wantsExpanded = false;
    collapseCalls++;
  }
}

class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;
  @override
  DateTime get now => fixedTime;
  @override
  Stream<DateTime> get tick1s => const Stream.empty();
  @override
  Stream<DateTime> get tick10s => const Stream.empty();
}

class _FakeCalendarService extends CalendarController {
  _FakeCalendarService(super.service, {required super.settingsService});
  int fetchCalls = 0;
  @override
  Future<void> refresh() async {
    fetchCalls++;
  }
}

class _MockService implements CalendarService {
  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async => [];
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService() : super(directory: Directory.systemTemp);
  @override
  AppSettings get current => const AppSettings();
  @override
  Stream<AppSettings> get settings => const Stream.empty();
}

void main() {
  final now = DateTime(2026, 3, 2, 10, 0);
  final clock = _FakeClock(now);
  late _MockService mockService;
  late _FakeCalendarService fakeController;
  late _FakeSettingsService fakeSettings;

  setUp(() {
    mockService = _MockService();
    fakeSettings = _FakeSettingsService();
    fakeController =
        _FakeCalendarService(mockService, settingsService: fakeSettings);
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(
          body: child,
        ),
      );

  group('TimelineStrip (S3-09, S3-10, BUG-09, BUG-11)', () {
    testWidgets('shows CountdownDisplay when future events exist',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Future Meeting',
          startTime: now.add(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 60)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      expect(find.byType(CountdownDisplay), findsOneWidget);
    });

    testWidgets('shows amber countdown when in a meeting (S3-17)',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Current Meeting',
          startTime: now.subtract(const Duration(minutes: 10)),
          endTime: now.add(const Duration(minutes: 20)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      final display = tester.widget<CountdownDisplay>(
        find.byType(CountdownDisplay),
      );
      expect(display.color, equals(Colors.amber));
    });

    testWidgets('shows refresh and settings icons on hover (S3-09)',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(minutes: 10)),
          endTime: now.add(const Duration(minutes: 20)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      // 1. Initially hidden
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);

      // 2. Hover to show
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(10, 10)); // Hit strip
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap refresh
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(fakeController.fetchCalls, equals(1));

      await gesture.removePointer();
    });

    testWidgets('hover-only: hovering shows card, tap does nothing extra',
        (tester) async {
      final fakeWS = _FakeWindowService();
      final event = CalendarEvent(
        id: 'e1',
        title: 'Meeting',
        startTime: now.add(const Duration(minutes: 10)),
        endTime: now.add(const Duration(minutes: 20)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: [event],
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: fakeWS,
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover
      await gesture.moveTo(const Offset(140, 10)); // Hit event
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      expect(fakeWS.expandCalls, equals(1));

      // 2. Tap (should NOT call expand again or toggle)
      await tester.tapAt(const Offset(140, 10));
      await tester.pump();

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      expect(fakeWS.expandCalls, equals(1));

      await gesture.removePointer();
    });

    testWidgets(
        'BUG-09/11: expand called once on hover; collapse called once on exit',
        (tester) async {
      final fakeWS = _FakeWindowService();
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(minutes: 10)),
          endTime: now.add(const Duration(minutes: 20)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: fakeWS,
          onSignOut: () {},
        ),
      ));
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // Move in and jiggle
      await gesture.moveTo(const Offset(140, 10)); // Hit event
      await tester.pump(const Duration(milliseconds: 150));
      await gesture.moveTo(const Offset(145, 10)); // Jiggle inside same event
      await tester.pump();
      await gesture.moveTo(const Offset(142, 10)); // Jiggle inside same event
      await tester.pump();

      expect(fakeWS.expandCalls, equals(1),
          reason: 'expand called once despite jiggle');

      await gesture.moveTo(const Offset(400, 300)); // Exit strip + card area
      await tester.pump(const Duration(milliseconds: 150));

      expect(fakeWS.collapseCalls, equals(1),
          reason: 'collapse called once on exit');
      await gesture.removePointer();
    });

    testWidgets('BUG-09: collapse not called when strip is already collapsed',
        (tester) async {
      final fakeWS = _FakeWindowService(initialExpanded: false);

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: fakeWS,
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // Hover over empty strip
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 150));
      expect(fakeWS.collapseCalls, equals(0));

      // Exit strip
      await gesture.moveTo(const Offset(10, 100));
      await tester.pump(const Duration(milliseconds: 150));
      expect(fakeWS.collapseCalls, equals(0));

      await gesture.removePointer();
    });

    testWidgets('Reg-02: hover card is within strip bounds on hover',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Big Meeting',
          startTime: now.add(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 60)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10)); // Hit event
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      final cardRect = tester.getRect(find.byType(HoverDetailOverlay));
      expect(cardRect.top, greaterThanOrEqualTo(0.0));

      await gesture.removePointer();
    });

    testWidgets(
        'BUG-13: hover card on long active event (start off-screen left) does not clamp to x=4',
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

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: events,
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10)); // Hit event
      await tester.pump(const Duration(milliseconds: 150));

      final cardRect = tester.getRect(find.byType(HoverDetailOverlay));
      // With startX far to the left, it should clamp to the left margin (4.0).
      expect(cardRect.left, equals(4.0));

      await gesture.removePointer();
    });

    testWidgets('S4-35: hover card is at least 260px and matches event width',
        (tester) async {
      final settings = _FakeSettingsService();
      final windowService = _FakeWindowService();

      final event = CalendarEvent(
        id: 'e1',
        title: 'Wide Meeting',
        startTime: now.add(const Duration(minutes: 60)),
        endTime: now.add(const Duration(minutes: 120)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      final narrowEvent = CalendarEvent(
        id: 'e2',
        title: 'Narrow Meeting',
        startTime: now.add(const Duration(minutes: 10)),
        endTime: now.add(const Duration(minutes: 15)),
        color: Colors.red,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      await tester.pumpWidget(
        wrap(TimelineStrip(
          events: [event, narrowEvent],
          clockService: clock,
          calendarController: fakeController,
          settingsService: settings,
          onSignOut: () {},
          windowService: windowService,
        )),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Test Wide Event: should match event width
      await gesture.moveTo(const Offset(300, 10)); // Hit wide event
      await tester.pump(const Duration(milliseconds: 150));

      final wideCardRect = tester.getRect(find.byType(HoverDetailOverlay));
      expect(wideCardRect.width, 260.0);

      // 2. Test Narrow Event: should clamp to 260px
      await gesture.moveTo(const Offset(140, 10)); // Hit narrow event
      await tester.pump(const Duration(milliseconds: 150));

      final narrowCardRect = tester.getRect(find.byType(HoverDetailOverlay));
      expect(narrowCardRect.width, 260.0);

      await gesture.removePointer();
    });

    testWidgets('Reg-03: hovering over task shows HoverDetailOverlay',
        (tester) async {
      final task = CalendarEvent(
        id: 't1',
        title: 'Task',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 60)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: [task],
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10)); // Hit event
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets('S4-13: hover → settings → font change → tap gear closes panel',
        (tester) async {
      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover to show icons
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byIcon(Icons.settings), findsOneWidget);

      // 2. Tap settings
      await tester.tapAt(const Offset(45, 10));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SettingsPanel), findsOneWidget);

      // 3. Change font size (Small)
      await tester.tap(find.text('Small'));
      await tester.pump();

      // 4. Tap gear again to close
      await tester.tapAt(const Offset(45, 10));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SettingsPanel), findsNothing);

      await gesture.removePointer();
    });

    testWidgets('opens settings panel when gear is tapped (S3-10)',
        (tester) async {
      bool signOutCalled = false;

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: fakeController,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () => signOutCalled = true,
        ),
      ));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover to show gear
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byIcon(Icons.settings), findsOneWidget);

      // 2. Tap settings
      await tester.tapAt(const Offset(45, 10));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(SettingsPanel), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);

      // 3. Tap logout
      await tester.tap(find.text('LOGOUT'));
      expect(signOutCalled, isTrue);

      await gesture.removePointer();
    });

    testWidgets(
        'expansion state persists when app is unfocused if settings open',
        (tester) async {
      final settings = _FakeSettingsService();
      final windowService = _FakeWindowService();

      await tester.pumpWidget(
        wrap(TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: fakeController,
          settingsService: settings,
          onSignOut: () {},
          windowService: windowService,
        )),
      );

      // 1. Open settings
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tapAt(const Offset(45, 10));
      await tester.pump(const Duration(milliseconds: 150));

      expect(windowService.isExpanded, isTrue);

      // 2. Lose focus
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // Should STAY expanded because settings is open
      expect(windowService.isExpanded, isTrue);

      await gesture.removePointer();
    });
    group('focus/lifecycle', () {
      testWidgets('collapses when app loses focus if settings closed',
          (tester) async {
        final windowService = _FakeWindowService();

        await tester.pumpWidget(
          wrap(TimelineStrip(
            events: const [],
            clockService: clock,
            calendarController: fakeController,
            settingsService: fakeSettings,
            onSignOut: () {},
            windowService: windowService,
          )),
        );

        // 1. Expand via hover
        final event = CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(minutes: 10)),
          endTime: now.add(const Duration(minutes: 20)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        );
        // Re-pump with event
        await tester.pumpWidget(
          wrap(TimelineStrip(
            events: [event],
            clockService: clock,
            calendarController: fakeController,
            settingsService: fakeSettings,
            onSignOut: () {},
            windowService: windowService,
          )),
        );

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(const Offset(140, 10));
        await tester.pump(const Duration(milliseconds: 150));

        expect(windowService.isExpanded, isTrue);

        // 2. Lose focus
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump(const Duration(milliseconds: 150));

        // Should collapse
        expect(windowService.isExpanded, isFalse);

        await gesture.removePointer();
      });
    });
  });
}
