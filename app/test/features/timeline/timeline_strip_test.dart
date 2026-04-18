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
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        ) {
    isExpandedNotifier.value = initialExpanded;
  }

  int expandCalls = 0;
  int collapseCalls = 0;

  @override
  Future<void> expand({double? height}) async {
    expandCalls++;
    isExpandedNotifier.value = true;
  }

  @override
  Future<void> collapse({double? height}) async {
    collapseCalls++;
    isExpandedNotifier.value = false;
  }
}

class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;
  @override
  DateTime get now => fixedTime;
  @override
  Stream<DateTime> get tick1s => Stream.periodic(
        const Duration(milliseconds: 1),
        (_) => fixedTime,
      );
  @override
  Stream<DateTime> get tick10s => Stream.periodic(
        const Duration(milliseconds: 1),
        (_) => fixedTime,
      );
}

class _CountingClock extends ClockService {
  _CountingClock(this.fixedTime);
  final DateTime fixedTime;
  final Stream<DateTime> _tick1s = const Stream<DateTime>.empty();
  final Stream<DateTime> _tick10s = const Stream<DateTime>.empty();
  int tick1sReads = 0;
  int tick10sReads = 0;

  @override
  DateTime get now => fixedTime;

  @override
  Stream<DateTime> get tick1s {
    tick1sReads++;
    return _tick1s;
  }

  @override
  Stream<DateTime> get tick10s {
    tick10sReads++;
    return _tick10s;
  }
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
      await tester.pump(Duration.zero);

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
      await tester.pump(Duration.zero);

      final display = tester.widget<CountdownDisplay>(
        find.byType(CountdownDisplay),
      );
      expect(display.color, equals(Colors.amber));
    });

    testWidgets('shows refresh and settings icons always (S3-09)',
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
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap refresh via widget finder (coordinates miss due to vertical centering)
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(fakeController.fetchCalls, equals(1));
    });

    testWidgets('hover-only: hovering shows card, tap does nothing extra',
        (tester) async {
      final fakeWS = _FakeWindowService();
      final event = CalendarEvent(
        id: 'e1',
        title: 'Meeting',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 60)),
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
      await tester.pump(Duration.zero);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // 1. Hover
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 10));

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
          windowService: fakeWS,
          onSignOut: () {},
        ),
      ));
      await tester.pump(Duration.zero);

      // Record baseline after init (initState unconditionally calls collapse once)
      final baseExpand = fakeWS.expandCalls;
      final baseCollapse = fakeWS.collapseCalls;

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      // Move in and jiggle
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 10));
      await gesture.moveTo(const Offset(145, 10));
      await tester.pump();
      await gesture.moveTo(const Offset(142, 10));
      await tester.pump();

      expect(fakeWS.expandCalls - baseExpand, equals(1),
          reason: 'expand called once despite jiggle');

      await gesture
          .moveTo(const Offset(400, 10)); // Move to non-event area → collapse
      await tester.pump(const Duration(seconds: 10));

      expect(fakeWS.collapseCalls - baseCollapse, equals(1),
          reason: 'collapse called once on exit');
      await gesture.removePointer();
    });

    testWidgets('Linux: suppressed synthetic exit keeps hover card painted',
        (tester) async {
      if (!Platform.isLinux) return;

      final fakeWS = _FakeWindowService();
      final event = CalendarEvent(
        id: 'e1',
        title: 'Meeting',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 60)),
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
      await tester.pump(Duration.zero);

      final baseCollapse = fakeWS.collapseCalls;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(Duration.zero);

      expect(find.byType(HoverDetailOverlay), findsOneWidget);

      await gesture.moveTo(const Offset(400, 10));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      expect(fakeWS.collapseCalls - baseCollapse, equals(0));

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
      await tester.pump(Duration.zero);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      final cardRect = tester.getRect(find.byType(HoverDetailOverlay));
      expect(cardRect.top, greaterThanOrEqualTo(0.0));

      await gesture.removePointer();
    });

    testWidgets('S4-35: hover card is at least 260px and matches event width',
        (tester) async {
      final settings = _FakeSettingsService();
      final windowService = _FakeWindowService();

      final event = CalendarEvent(
        id: 'e1',
        title: 'Wide Meeting',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 90)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      await tester.pumpWidget(
        wrap(TimelineStrip(
          events: [event],
          clockService: clock,
          calendarController: fakeController,
          settingsService: settings,
          onSignOut: () {},
          windowService: windowService,
        )),
      );
      await tester.pump(Duration.zero);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);

      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
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
      await tester.pump(Duration.zero);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 10));

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
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
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(find.byType(SettingsPanel), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);

      // Tap logout
      await tester.tap(find.text('LOGOUT'));
      await tester.pump();
      expect(signOutCalled, isTrue);
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
      await tester.pump(Duration.zero);

      // 1. Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();

      expect(windowService.isExpandedNotifier.value, isTrue);

      // 2. Lose focus
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // Should STAY expanded because settings is open
      expect(windowService.isExpandedNotifier.value, isTrue);
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
        await tester.pump(Duration.zero);

        // 1. Expand via hover
        final event = CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 60)),
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
        await tester.pump(Duration.zero);

        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(const Offset(140, 10));
        await tester.pump(const Duration(seconds: 10));

        expect(windowService.isExpandedNotifier.value, isTrue);

        // 2. Lose focus
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();

        // Should collapse
        expect(windowService.isExpandedNotifier.value, isFalse);

        await gesture.removePointer();
      });
    });
  });

  group('Quit button (always-visible)', () {
    testWidgets('power icon is present on strip with no events',
        (tester) async {
      final windowService = _FakeWindowService();
      await tester.pumpWidget(wrap(TimelineStrip(
        events: const [],
        clockService: clock,
        calendarController: fakeController,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: windowService,
        enableAnimations: false,
      )));
      await tester.pump(Duration.zero);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('power icon is present when expanded with hover card',
        (tester) async {
      final windowService = _FakeWindowService();
      final event = CalendarEvent(
        id: 'e1',
        title: 'Meeting',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 60)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      await tester.pumpWidget(wrap(TimelineStrip(
        events: [event],
        clockService: clock,
        calendarController: fakeController,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: windowService,
        enableAnimations: false,
      )));
      await tester.pump(Duration.zero);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(140, 10));
      await tester.pump(const Duration(seconds: 1));

      expect(windowService.isExpandedNotifier.value, isTrue);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
      await gesture.removePointer();
    });
  });

  group('sign-in mode', () {
    testWidgets('onSignIn set: hides refresh, settings, and countdown icons',
        (tester) async {
      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
          onSignIn: () {},
        ),
      ));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byType(CountdownDisplay), findsNothing);
    });

    testWidgets('onSignIn set: tapping strip calls onSignIn', (tester) async {
      bool signInCalled = false;

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
          onSignIn: () => signInCalled = true,
        ),
      ));
      await tester.pump(Duration.zero);

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();

      expect(signInCalled, isTrue);
    });

    testWidgets('onCancelSignIn set: tapping calls cancel, not signIn',
        (tester) async {
      bool signInCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
          onSignIn: () => signInCalled = true,
          onCancelSignIn: () => cancelCalled = true,
        ),
      ));
      await tester.pump(Duration.zero);

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();

      expect(cancelCalled, isTrue);
      expect(signInCalled, isFalse);
    });

    testWidgets('sign-in mode: calendarController null does not crash',
        (tester) async {
      await tester.pumpWidget(wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          settingsService: fakeSettings,
          windowService: _FakeWindowService(),
          onSignOut: () {},
          onSignIn: () {},
          // calendarController intentionally omitted (nullable)
        ),
      ));
      await tester.pump(Duration.zero);

      // No crash — strip renders without a calendar controller.
      expect(find.byType(TimelineStrip), findsOneWidget);
    });
  });

  group('Clock stream subscriptions', () {
    testWidgets('does not replace clock streams on parent rebuild',
        (tester) async {
      final countingClock = _CountingClock(now);
      final windowService = _FakeWindowService();
      TimelineStrip buildTimeline() => TimelineStrip(
            events: const [],
            clockService: countingClock,
            calendarController: fakeController,
            settingsService: fakeSettings,
            windowService: windowService,
            onSignOut: () {},
            enableAnimations: false,
          );

      await tester.pumpWidget(wrap(buildTimeline()));
      await tester.pump(Duration.zero);
      expect(countingClock.tick10sReads, 1);
      expect(countingClock.tick1sReads, 1);

      await tester.pumpWidget(wrap(buildTimeline()));
      await tester.pump(Duration.zero);

      expect(countingClock.tick10sReads, 1);
      expect(countingClock.tick1sReads, 1);
    });
  });

  group('Countdown tick1s precision (event boundary)', () {
    testWidgets('countdown mode switches to untilEnd within 1s of event start',
        (tester) async {
      // Event starts at `now` — active immediately.
      final activeEvent = CalendarEvent(
        id: 'active',
        title: 'Active Meeting',
        startTime: now.subtract(const Duration(seconds: 1)),
        endTime: now.add(const Duration(hours: 1)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      final windowService = _FakeWindowService();
      await tester.pumpWidget(wrap(TimelineStrip(
        events: [activeEvent],
        clockService: clock,
        calendarController: fakeController,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: windowService,
        enableAnimations: false,
      )));
      await tester.pump(Duration.zero);

      // The countdown display should show untilEnd mode (no "in X" prefix).
      final countdownFinder = find.byType(CountdownDisplay);
      expect(countdownFinder, findsOneWidget);
      final widget = tester.widget<CountdownDisplay>(countdownFinder);
      expect(widget.mode, CountdownMode.untilEnd);
    });
  });
}
