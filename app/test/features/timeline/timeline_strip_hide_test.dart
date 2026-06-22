import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeWindowManager extends Mock implements WindowManager {
  @override
  double getDevicePixelRatio() => 1.0;
}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _StubDisplayProbe implements DisplayProbe {
  @override
  Future<List<DisplayInfo>> getAll() async => const [];
}

class _StubDisplayEvents implements DisplayEvents {
  @override
  void Function() subscribe(void Function() onChange) => () {};
}

/// Extends the base to track applyState calls and swallow real geometry ops.
class _HideTrackingWindowService extends WindowService {
  _HideTrackingWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
          displayService: DisplayService(
            probe: _StubDisplayProbe(),
            events: _StubDisplayEvents(),
          ),
        );

  final List<StripState> appliedStates = [];

  @override
  Future<void> applyState(StripState state) async {
    appliedStates.add(state);
  }

  @override
  Future<void> setWindowMode(WindowMode mode) async {}

  @override
  Future<void> focus() async {}
}

class _FakeClock extends ClockService {
  _FakeClock(this.fixedTime);
  final DateTime fixedTime;
  @override
  DateTime get now => fixedTime;
  @override
  Stream<DateTime> get tick1s => const Stream<DateTime>.empty();
  @override
  Stream<DateTime> get tick10s => const Stream<DateTime>.empty();
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService([this._current = const AppSettings()])
      : super(directory: Directory.systemTemp);
  AppSettings _current;
  @override
  AppSettings get current => _current;
  @override
  Future<void> update(AppSettings s) async {
    _current = s;
    notifyListeners();
  }

  @override
  Stream<AppSettings> get settings => const Stream.empty();
}

class _MockCalendarService implements CalendarService {
  @override
  Future<List<CalendarEvent>> fetchEvents(String id) async => [];
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

class _FakeCalendarController extends CalendarController {
  _FakeCalendarController(super.service, {required super.settingsService});
  @override
  Future<void> refresh() async {}
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  final now = DateTime(2026, 6, 11, 10, 0);

  late _FakeClock clock;
  late _FakeSettingsService settings;
  late _FakeCalendarController calendar;

  setUp(() {
    clock = _FakeClock(now);
    settings = _FakeSettingsService();
    calendar = _FakeCalendarController(
      _MockCalendarService(),
      settingsService: settings,
    );
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(body: child),
      );

  TimelineStrip makeStrip({
    required _HideTrackingWindowService ws,
    List<CalendarEvent> events = const [],
  }) =>
      TimelineStrip(
        events: events,
        clockService: clock,
        calendarController: calendar,
        settingsService: settings,
        windowService: ws,
        onSignOut: () {},
        enableAnimations: false,
      );

  group('F-31 hide/show — state machine', () {
    testWidgets('hide button present when strip is visible', (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.arrow_left), findsOneWidget);
    });

    testWidgets('tapping hide button applies hidden state', (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      expect(ws.appliedStates, contains(StripState.hidden));
    });

    testWidgets('after hide, mini widget shows show-button (arrow_right)',
        (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_right), findsOneWidget);
      expect(find.byIcon(Icons.arrow_left), findsNothing);
    });

    testWidgets('tapping show button restores full strip', (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_right));
      await tester.pumpAndSettle();

      expect(ws.appliedStates, contains(StripState.collapsedShown));
      expect(find.byIcon(Icons.arrow_left), findsOneWidget);
      expect(find.byIcon(Icons.arrow_right), findsNothing);
    });

    testWidgets('countdown visible while strip is hidden', (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Future',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws, events: events)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      expect(find.byType(CountdownDisplay), findsOneWidget);
    });

    testWidgets('hide/show cycle repeatable 3 times (AC-F31-3-5)',
        (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.arrow_left));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.arrow_right), findsOneWidget,
            reason: 'cycle $i: should be hidden');

        await tester.tap(find.byIcon(Icons.arrow_right));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.arrow_left), findsOneWidget,
            reason: 'cycle $i: should be visible');
      }
    });

    testWidgets('hide button touch target meets 24×24 minimum (AC-F31-1-5)',
        (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      final size = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.arrow_left),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(24));
      expect(size.height, greaterThanOrEqualTo(24));
    });

    testWidgets('show button touch target meets 24×24 minimum', (tester) async {
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.arrow_right),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(24));
      expect(size.height, greaterThanOrEqualTo(24));
    });

    // AC-F31-3-2: tapping countdown area also restores strip
    testWidgets(
        'tapping countdown area while hidden triggers show (AC-F31-3-2)',
        (tester) async {
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      final ws = _HideTrackingWindowService();
      await tester.pumpWidget(wrap(makeStrip(ws: ws, events: events)));
      await tester.pump(Duration.zero);

      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      // Tap the CountdownDisplay — outer GestureDetector receives it
      await tester.tap(find.byType(CountdownDisplay), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(ws.appliedStates, contains(StripState.collapsedShown));
      expect(find.byIcon(Icons.arrow_left), findsOneWidget);
    });

    // AC-F31-3-4 / arch D3: settings closed on hide
    testWidgets('settings panel closed on hide if open', (tester) async {
      final ws = _HideTrackingWindowService();
      final events = [
        CalendarEvent(
          id: 'e1',
          title: 'Meeting',
          startTime: now.add(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        ),
      ];
      await tester.pumpWidget(wrap(makeStrip(ws: ws, events: events)));
      await tester.pump(Duration.zero);

      // Open settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPanel), findsOneWidget);

      // Hide strip — settings should close
      await tester.tap(find.byIcon(Icons.arrow_left));
      await tester.pumpAndSettle();

      // In mini mode, no settings panel
      expect(find.byType(SettingsPanel), findsNothing);
    });
  });
}
