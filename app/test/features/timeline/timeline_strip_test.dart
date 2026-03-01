import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

/// Fake WindowService that counts expand/collapse calls without touching OS.
class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  int expandCalls = 0;
  int collapseCalls = 0;

  @override
  Future<void> expand() async => expandCalls++;

  @override
  Future<void> collapse() async => collapseCalls++;
}

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

    // ── BUG-09/10/11: _isExpanded guard ─────────────────────────────────────

    testWidgets(
        'BUG-09/11: expand called once on hover; collapse called once on exit',
        (tester) async {
      final fakeWS = _FakeWindowService();
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [
            CalendarEvent(
              id: 'e1',
              title: 'Meeting',
              startTime: now.add(const Duration(minutes: 10)),
              endTime: now.add(const Duration(minutes: 40)),
              color: Colors.blue,
              calendarEventUrl: null,
              videoCallUrl: null,
            ),
          ],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: fakeWS,
        ),
      ));
      await tester.pump();

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();

      // Compute event pixel position from actual strip width (avoids hardcoding
      // a size assumption that breaks on different test surface configurations).
      final sw = tester.getSize(find.byType(TimelineStrip)).width;
      final nowX = sw * 0.10;
      final pps = sw / (9 * 3600.0); // pixels per second across 9hr window
      final evtMid = nowX + 1200 * pps; // midpoint of event: now + 20 min

      // Hover over an event to trigger expand
      await gesture.moveTo(Offset(evtMid, 10));
      await tester.pump();
      expect(fakeWS.expandCalls, equals(1));

      // Move around the event area — expand should NOT fire again
      await gesture.moveTo(Offset(evtMid - 3, 10));
      await tester.pump();
      await gesture.moveTo(Offset(evtMid + 3, 10));
      await tester.pump();
      expect(fakeWS.expandCalls, equals(1), reason: 'expand called more than once');

      // Exit the strip — collapse should fire exactly once
      // y=300 is always outside the 200px-tall SizedBox wrapper.
      await gesture.moveTo(Offset(sw / 2, 300));
      await tester.pump();
      expect(fakeWS.collapseCalls, equals(1));

      // Exit again (spurious) — collapse should NOT fire again
      await gesture.moveTo(Offset(sw / 2, 400));
      await tester.pump();
      expect(fakeWS.collapseCalls, equals(1),
          reason: 'collapse called more than once');

      await gesture.removePointer();
    });

    testWidgets('BUG-09: collapse not called when strip is already collapsed',
        (tester) async {
      final fakeWS = _FakeWindowService();
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: const [],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: fakeWS,
        ),
      ));
      await tester.pump();

      // Mouse exit on an already-collapsed strip → collapse must NOT fire
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(10, 10));
      await tester.pump();
      await gesture.moveTo(const Offset(600, 300));
      await tester.pump();

      expect(fakeWS.collapseCalls, equals(0),
          reason: 'collapse fired on already-collapsed strip');
      await gesture.removePointer();
    });

    // ── S4-20: Countdown right of now-line ───────────────────────────────────

    testWidgets('S4-20: CountdownDisplay is positioned to the right of the now-line',
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

      // nowIndicatorX = stripWidth * 0.10 — compute from actual layout
      final stripWidth = tester.getSize(find.byType(TimelineStrip)).width;
      final nowIndicatorX = stripWidth * 0.10;
      final countdownFinder = find.byType(CountdownDisplay);
      expect(countdownFinder, findsOneWidget);

      final countdownBox = tester.getRect(countdownFinder);
      expect(countdownBox.left, greaterThan(nowIndicatorX),
          reason: 'CountdownDisplay should be RIGHT of now-line');
    });

    // ── S4-16: Task events ────────────────────────────────────────────────────

    testWidgets('S4-16: strip renders without error with isTask:true event',
        (tester) async {
      // Smoke test — painter must not throw when given a task (◇ branch).
      final task = CalendarEvent(
        id: 'task-1',
        title: 'upcoming task',
        startTime: now.add(const Duration(minutes: 30)),
        endTime: now.add(const Duration(minutes: 90)),
        color: Colors.grey,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [task],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      // No exception + CountdownDisplay visible (task is a future event)
      expect(tester.takeException(), isNull);
      expect(find.byType(CountdownDisplay), findsOneWidget);
    });

    testWidgets('S4-16: task event counted as future event → shows countdown',
        (tester) async {
      final task = CalendarEvent(
        id: 'task-1',
        title: 'Review PR',
        startTime: now.add(const Duration(minutes: 45)),
        endTime: now.add(const Duration(minutes: 75)),
        color: Colors.green,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [task],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('S4-16: past task event does not prevent CelebrationWidget',
        (tester) async {
      final pastTask = CalendarEvent(
        id: 'task-old',
        title: 'Done task',
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now.subtract(const Duration(minutes: 30)),
        color: Colors.grey,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [pastTask],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();
      expect(find.byType(CelebrationWidget), findsOneWidget);
    });

    // ── Reg-02: Hover card alignment ─────────────────────────────────────────

    testWidgets('Reg-02: hover card is within strip bounds on hover',
        (tester) async {
      final fakeWS = _FakeWindowService();
      final event = CalendarEvent(
        id: 'e-hover',
        title: 'Big Meeting',
        startTime: now.add(const Duration(minutes: 60)),
        endTime: now.add(const Duration(minutes: 90)),
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [event],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: fakeWS,
        ),
      ));
      await tester.pump();

      final sw = tester.getSize(find.byType(TimelineStrip)).width;
      final nowX = sw * 0.10;
      final pps = sw / (9 * 3600.0);
      final evtStartX = nowX + 60 * 60 * pps;
      final evtEndX = nowX + 90 * 60 * pps;
      final evtMidX = (evtStartX + evtEndX) / 2;

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(Offset(evtMidX, 10));
      await tester.pump();

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      final cardRect = tester.getRect(find.byType(HoverDetailOverlay));
      // Card must not overflow the strip on either side
      expect(cardRect.left, greaterThanOrEqualTo(0.0));
      expect(cardRect.right, lessThanOrEqualTo(sw + 1)); // +1 for fp rounding
      
      // Card should be left-aligned to the event start (evtStartX)
      expect(cardRect.left, closeTo(evtStartX, 0.1),
          reason: 'card should left-align to event start (DEC-002)');

      await gesture.removePointer();
    });

    testWidgets(
        'BUG-13: hover card on long active event (start off-screen left) does not clamp to x=4',
        (tester) async {
      // Test screen is 800px by default — too narrow for the 1200px SizedBox.
      // Widen so the strip gets its full 1200px, giving nowX=120 and enough
      // room for the visible-center fix to produce a left > 4px.
      await tester.binding.setSurfaceSize(const Size(2000, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Event started 90 min ago (before the 1hr windowPast → eventX < 0).
      // ends 90 min from now → endX = nowX + 200px ≈ 320px.
      // OLD: center = (-80 + 320)/2 = 120 → cardLeft = -10 → clamp → 4px.
      // FIX: visibleStart clamped to 0 → left = 4px (clamped).
      final fakeWS = _FakeWindowService();
      final longEvent = CalendarEvent(
        id: 'long',
        title: 'Long Meeting',
        startTime: now.subtract(const Duration(minutes: 90)), // before window
        endTime: now.add(const Duration(minutes: 90)),
        color: Colors.red,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [longEvent],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: fakeWS,
        ),
      ));
      await tester.pump();

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();

      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      final cardRect = tester.getRect(find.byType(HoverDetailOverlay));

      // visibleStart = 0. left should be 4.0 (clamped).
      expect(cardRect.left, 4.0,
          reason: 'card should left-align to the event block (DEC-002)');

      await gesture.removePointer();
    });

    testWidgets('S4-35: hover card is at least 260px and matches event width',
        (tester) async {
      final now = DateTime(2026, 2, 27, 10, 0, 0);
      final event = CalendarEvent(
        id: 'wide',
        title: 'Wide Meeting',
        startTime: now.add(const Duration(hours: 1)), // x = 120 + 1*120 = 240
        endTime: now.add(const Duration(hours: 4)),   // x = 120 + 4*120 = 600 (w=360)
        color: Colors.blue,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      final clock = _FakeClock(now);
      final settings = _FakeSettingsService();
      final controller = CalendarController(_FakeCalendarService());
      final windowService = _FakeWindowService();

      // Ensure strip is wide enough for the 600px end point
      await tester.binding.setSurfaceSize(const Size(1200, 400));

      await tester.pumpWidget(
        _wrap(TimelineStrip(
          events: [event],
          clockService: clock,
          calendarController: controller,
          settingsService: settings,
          onSignOut: () {},
          windowService: windowService,
        )),
      );

      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(const Offset(300, 10)); // Hover over the event
      await tester.pump();

      final cardFinder = find.byType(HoverDetailOverlay);
      expect(cardFinder, findsOneWidget);
      final cardRect = tester.getRect(cardFinder);

      // Event is from x=240 to x=600.
      expect(cardRect.left, closeTo(240.0, 30.0),
          reason: 'card must left-align to event start (approx)');
      expect(cardRect.width, greaterThanOrEqualTo(350.0),
          reason: 'card must match wide event width (approx 360)');

      // Test with narrow event
      final narrowEvent = CalendarEvent(
        id: 'narrow',
        title: 'Short',
        startTime: now.add(const Duration(minutes: 10)), // x ≈ 140
        endTime: now.add(const Duration(minutes: 15)),   // x ≈ 150 (w=10)
        color: Colors.red,
        calendarEventUrl: null,
        videoCallUrl: null,
      );

      await tester.pumpWidget(
        _wrap(TimelineStrip(
          events: [narrowEvent],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: windowService,
        )),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(145, 10));
      await tester.pump();

      final narrowCardRect = tester.getRect(find.byType(HoverDetailOverlay));
      expect(narrowCardRect.left, closeTo(140.0, 30.0));
      expect(narrowCardRect.width, 260.0,
          reason: 'card must not be narrower than 260px');

      await gesture.removePointer();
    });

    // ── Reg-03: Task indicator — diamond not buried under labels ─────────────

    testWidgets('Reg-03: hovering over task shows HoverDetailOverlay',
        (tester) async {
      final fakeWS = _FakeWindowService();
      final task = CalendarEvent(
        id: 'task-hover',
        title: 'Review PR',
        startTime: now.add(const Duration(minutes: 60)),
        endTime: now.add(const Duration(minutes: 120)),
        color: Colors.green,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [task],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
          windowService: fakeWS,
        ),
      ));
      await tester.pump();

      final sw = tester.getSize(find.byType(TimelineStrip)).width;
      final nowX = sw * 0.10;
      final pps = sw / (9 * 3600.0);
      // Hover at the task's start position (where the diamond is)
      final taskX = nowX + 60 * 60 * pps;

      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(Offset(taskX + 5, 10));
      await tester.pump();

      // HoverDetailOverlay should appear — task event is still hit-testable
      expect(find.byType(HoverDetailOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);

      await gesture.removePointer();
    });

    testWidgets(
        'S4-13: hover → settings → font change → tap gear closes panel',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TimelineStrip(
          events: [
            CalendarEvent(
              id: 'e1',
              title: 'Meeting',
              startTime: now.add(const Duration(hours: 1)),
              endTime: now.add(const Duration(hours: 2)),
              color: Colors.blue,
              calendarEventUrl: null,
              videoCallUrl: null,
            ),
          ],
          clockService: clock,
          calendarController: realController,
          settingsService: fakeSettings,
          onSignOut: () {},
        ),
      ));
      await tester.pump();

      // Before hover: panel hidden.
      expect(find.byType(SettingsPanel), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);

      // Hover to reveal controls.
      final gesture =
          await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await tester.pump();
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Tap gear → panel opens.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      expect(find.byType(SettingsPanel), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);

      // Tap Large → fontSize updated.
      await tester.tap(find.text('Large'));
      await tester.pump();
      expect(fakeSettings.current.fontSize, FontSize.large);

      // Tap gear again → panel closes.
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pump();
      expect(find.byType(SettingsPanel), findsNothing);

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
