// Headless GUI integration tests for the TimelineStrip.
//
// TLDR:
// Overview: Integration tests asserting on canvas semantics + widget UX state.
// Problem: CustomPainter output (ticks, diamonds) is invisible to find.byType/find.text.
// Solution: TimelinePainter.semanticsBuilder emits SemanticsNodes; tests traverse the tree here.
// Breaking Changes: No.
//
// Run headlessly (all tests pass without a display):
//   flutter test integration_test/
//
// Run on Linux desktop for full coverage incl. real mouse events:
//   make integration-test
//
// NOTE: Hover/mouse interaction tests live in test/features/timeline/timeline_strip_test.dart.
// Integration tests here cover what widget tests cannot: canvas semantics and pipeline state.
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/timeline_painter.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  @override
  Future<void> expand() async {}

  @override
  Future<void> collapse() async {}
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

class _FakeCalendarService implements CalendarService {
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(width: 1200, height: 200, child: child),
      ),
    );

CalendarEvent _evt({
  required String id,
  required String title,
  required DateTime start,
  required DateTime end,
  Color color = Colors.blue,
  bool isTask = false,
}) =>
    CalendarEvent(
      id: id,
      title: title,
      startTime: start,
      endTime: end,
      color: color,
      calendarEventUrl: null,
      videoCallUrl: null,
      isTask: isTask,
    );

/// Traverses the full [SemanticsNode] subtree rooted at the [TimelinePainter]'s
/// [CustomPaint] render object and returns true if any node carries [label].
///
/// [find.bySemanticsLabel] only checks each widget's DIRECT semantics node.
/// [CustomPainterSemantics] nodes are CHILDREN of that render object's node,
/// so a recursive walk is required.
bool _hasCanvasSemantics(WidgetTester tester, String label) {
  final painterFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
  );
  if (painterFinder.evaluate().isEmpty) return false;

  final renderObject = tester.renderObject(painterFinder.first);
  final root = renderObject.debugSemantics;
  if (root == null) return false;

  bool found = false;
  void visit(SemanticsNode node) {
    if (found) return;
    if (node.label == label) {
      found = true;
      return;
    }
    node.visitChildren((child) {
      visit(child);
      return !found;
    });
  }

  visit(root);
  return found;
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Fixed "now" = 10:00:00 — deterministic tick positions every run.
  final now = DateTime(2026, 2, 27, 10, 0, 0);
  final clock = _FakeClock(now);
  late _FakeWindowService fakeWS;
  late CalendarController controller;
  late _FakeSettingsService fakeSettings;

  setUp(() {
    fakeWS = _FakeWindowService();
    controller = CalendarController(_FakeCalendarService());
    fakeSettings = _FakeSettingsService();
  });

  // ── Canvas semantics ─────────────────────────────────────────────────────
  //
  // TimelinePainter.semanticsBuilder emits one SemanticsNode per visible hour
  // tick, event block, and task diamond.  When the painter regresses (e.g.
  // reverts to isVisible instead of pixel-bounds for ticks, or paints labels
  // over the diamond instead of skipping them for tasks), those nodes vanish
  // and these tests fail — catching the regression before it ships.

  group('canvas semantics', () {
    testWidgets('Reg-01: on-screen hour ticks emit semantic labels',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Standup',
            start: now.add(const Duration(hours: 2)),
            end: now.add(const Duration(hours: 2, minutes: 30)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // 10 am tick is at nowIndicatorX (x = 120 px for 1200 px strip) — visible.
      expect(_hasCanvasSemantics(tester, 'tick-10am'), isTrue,
          reason: 'tick-10am should be on-screen');
      expect(_hasCanvasSemantics(tester, 'tick-11am'), isTrue,
          reason: 'tick-11am should be on-screen');
      expect(_hasCanvasSemantics(tester, 'tick-12pm'), isTrue,
          reason: 'tick-12pm should be on-screen');
      // 9 am is off-screen left — absent from semantic tree.
      expect(_hasCanvasSemantics(tester, 'tick-9am'), isFalse,
          reason: 'tick-9am is off-screen left');

      handle.dispose();
    });

    testWidgets(
        'BUG-14: tick semantics survive when an event block covers the tick x-position',
        (tester) async {
      // Regression guard: ticks were painted BEFORE events, so event blocks
      // drew over them and made them invisible. Fix: paint order reversed.
      // The semanticsBuilder is independent — but both painter and semantics
      // must emit nodes even when events cover the tick position.
      final handle = tester.ensureSemantics();

      // now=10:00. 11am tick is at nowX + 1hr*pps (well inside the event block).
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'big',
            title: 'All Morning',
            start: now,                             // 10:00 — covers 10am tick
            end: now.add(const Duration(hours: 3)), // 13:00 — covers 11am+12pm
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // Ticks covered by the event block must still emit semantic nodes.
      expect(_hasCanvasSemantics(tester, 'tick-11am'), isTrue,
          reason: 'tick-11am must emit semantics even when under an event block');
      expect(_hasCanvasSemantics(tester, 'tick-12pm'), isTrue,
          reason: 'tick-12pm must emit semantics even when under an event block');

      handle.dispose();
    });

    testWidgets('Reg-01: ticks survive windowStart :00:00 boundary edge case',
        (tester) async {
      // With isVisible(), ticks at :00:00 were filtered when windowStart had
      // non-zero seconds (e.g. now=10:00:30 → windowStart=09:00:30, hourTime
      // for 10am=10:00:00 which is before windowStart by 30s → dropped).
      // Pixel-bounds check fixes this.
      final handle = tester.ensureSemantics();
      final nowWithSecs = DateTime(2026, 2, 27, 10, 0, 30);

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Meeting',
            start: nowWithSecs.add(const Duration(hours: 1)),
            end: nowWithSecs.add(const Duration(hours: 2)),
          ),
        ],
        clockService: _FakeClock(nowWithSecs),
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'tick-10am'), isTrue,
          reason: 'tick-10am must survive the isVisible :00:00 edge case');
      expect(_hasCanvasSemantics(tester, 'tick-11am'), isTrue);

      handle.dispose();
    });

    testWidgets('BUG-14: tick semantics survive Midnight/Month crossing',
        (tester) async {
      // Logic bug: windowStart=Feb 28 23:30, windowEnd=Mar 1 08:30.
      // 1 is NOT > 28, so loop was skipping hours.
      final handle = tester.ensureSemantics();
      final midnightCrossing = DateTime(2026, 3, 1, 0, 30, 0); // 12:30 am

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Late Meeting',
            start: midnightCrossing.subtract(const Duration(minutes: 15)),
            end: midnightCrossing.add(const Duration(minutes: 15)),
          ),
        ],
        clockService: _FakeClock(midnightCrossing),
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // Window is 23:30 (Feb 28) to 08:30 (Mar 1).
      // 11pm is off-screen left (-80px). 
      expect(_hasCanvasSemantics(tester, 'tick-11pm'), isFalse,
          reason: '11pm (Feb 28) tick is off-screen left');
      
      // 12am is at ~53px — visible.
      expect(_hasCanvasSemantics(tester, 'tick-12am'), isTrue,
          reason: '12am (Mar 1) tick should be visible');
      
      // 1am is at ~186px — visible.
      expect(_hasCanvasSemantics(tester, 'tick-1am'), isTrue,
          reason: '1am (Mar 1) tick should be visible');

      handle.dispose();
    });

    testWidgets('Reg-03: task emits "task:" semantic, NOT "event:"',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'task-1',
            title: 'Review PR',
            start: now.add(const Duration(hours: 1)),
            end: now.add(const Duration(hours: 2)),
            isTask: true,
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // Diamond was painted → task semantic present.
      expect(_hasCanvasSemantics(tester, 'task: Review PR'), isTrue,
          reason: 'task diamond must emit task: semantic');
      // No event block was painted for this entry.
      expect(_hasCanvasSemantics(tester, 'event: Review PR'), isFalse,
          reason: 'task must NOT emit event: semantic (labels not painted)');

      handle.dispose();
    });

    testWidgets('regular event emits "event:" semantic', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Team Standup',
            start: now.add(const Duration(minutes: 30)),
            end: now.add(const Duration(minutes: 60)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'event: Team Standup'), isTrue);
      expect(_hasCanvasSemantics(tester, 'task: Team Standup'), isFalse);

      handle.dispose();
    });

    testWidgets('mixed events: each entry gets its own semantic node',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
              id: 'e1',
              title: 'Standup',
              start: now.add(const Duration(minutes: 30)),
              end: now.add(const Duration(minutes: 60))),
          _evt(
              id: 'e2',
              title: 'Planning',
              start: now.add(const Duration(hours: 2)),
              end: now.add(const Duration(hours: 3))),
          _evt(
              id: 't1',
              title: 'Code Review',
              start: now.add(const Duration(hours: 4)),
              end: now.add(const Duration(hours: 5)),
              isTask: true),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'event: Standup'), isTrue);
      expect(_hasCanvasSemantics(tester, 'event: Planning'), isTrue);
      expect(_hasCanvasSemantics(tester, 'task: Code Review'), isTrue);

      handle.dispose();
    });
  });

  // ── Sub-ticks, now indicator, gap labels ──────────────────────────────────
  //
  // These assertions tie the semanticsBuilder to the exact same paint conditions
  // used in _paintTicks / _paintEvents.  If a future change alters a threshold
  // (e.g. pixelsPerHour check), one of the painters will produce a different
  // visual but the other won't — and these tests will catch the divergence.

  group('canvas semantics — sub-ticks, now-indicator, gaps', () {
    // Strip is 1200 px, window is 10 h → pixelsPerHour = 120 >= 80.
    // 30-min sub-ticks MUST appear; 15-min ticks are silent (no semantic node).

    testWidgets('30-min sub-ticks emit subtick-HH:30 semantics',
        (tester) async {
      final handle = tester.ensureSemantics();

      // Need at least one future event so the CustomPaint (TimelinePainter)
      // is in the widget tree — otherwise TimelineStrip shows CelebrationWidget.
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'anchor',
            title: 'Anchor',
            start: now.add(const Duration(hours: 2)),
            end: now.add(const Duration(hours: 3)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // now=10:00 → window 09:00–18:00 → 09:30 and 10:30 are on-screen.
      expect(_hasCanvasSemantics(tester, 'subtick-09:30'), isTrue,
          reason: 'subtick-09:30 must appear when pixelsPerHour >= 80');
      expect(_hasCanvasSemantics(tester, 'subtick-10:30'), isTrue,
          reason: 'subtick-10:30 must appear when pixelsPerHour >= 80');
      expect(_hasCanvasSemantics(tester, 'subtick-11:30'), isTrue);

      handle.dispose();
    });

    testWidgets('now-indicator semantic always present', (tester) async {
      final handle = tester.ensureSemantics();

      // Need a future event to mount the painter.
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'anchor',
            title: 'Anchor',
            start: now.add(const Duration(hours: 1)),
            end: now.add(const Duration(hours: 2)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'now-indicator'), isTrue,
          reason: 'NowIndicator line must always emit a semantic node');

      handle.dispose();
    });

    testWidgets('gap label emitted between two adjacent events', (tester) async {
      // Event A: 10:00–10:30 (ends at nowX+60px)
      // Event B: 11:00–11:30 (starts at nowX+120px)
      // Gap: 30 min, 60 px wide (>= 40 px minPx) → "gap: 30m"
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
              id: 'a',
              title: 'Alpha',
              start: now,
              end: now.add(const Duration(minutes: 30))),
          _evt(
              id: 'b',
              title: 'Beta',
              start: now.add(const Duration(hours: 1)),
              end: now.add(const Duration(hours: 1, minutes: 30))),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'gap: 30m'), isTrue,
          reason: '30-min gap between events must emit gap semantic');

      handle.dispose();
    });

    testWidgets('no gap label when events are adjacent (< minPx)', (tester) async {
      // Events back-to-back with ~0 gap — no gap label expected.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
              id: 'a',
              title: 'Alpha',
              start: now,
              end: now.add(const Duration(minutes: 30))),
          _evt(
              id: 'b',
              title: 'Beta',
              start: now.add(const Duration(minutes: 31)),
              end: now.add(const Duration(minutes: 61))),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      // 1-min gap at 120px/hr = 2px — below 40px minPx threshold.
      expect(_hasCanvasSemantics(tester, 'gap: 1m'), isFalse,
          reason: 'gap < minPx must NOT emit a semantic node');

      handle.dispose();
    });

    testWidgets('gap label format: >= 60 min uses hours notation', (tester) async {
      // 90-min gap → "1h30m"
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
              id: 'a',
              title: 'Alpha',
              start: now,
              end: now.add(const Duration(minutes: 30))),
          _evt(
              id: 'b',
              title: 'Beta',
              start: now.add(const Duration(hours: 2)),
              end: now.add(const Duration(hours: 3))),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(_hasCanvasSemantics(tester, 'gap: 1h30m'), isTrue,
          reason: '90-min gap must format as 1h30m');

      handle.dispose();
    });
  });

  // ── Widget-tree UX state ─────────────────────────────────────────────────
  // These run headlessly and verify the pipeline from clock → layout → widgets.

  group('widget UX state', () {
    testWidgets('no events: CelebrationWidget visible, no CountdownDisplay',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: const [],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(CelebrationWidget), findsOneWidget);
      expect(find.byType(CountdownDisplay), findsNothing);
    });

    testWidgets('future event: CountdownDisplay shows correct minutes',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Standup',
            start: now.add(const Duration(minutes: 38)),
            end: now.add(const Duration(minutes: 68)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(find.byType(CountdownDisplay), findsOneWidget);
      expect(find.text('38 min'), findsOneWidget);
    });

    testWidgets('active meeting: amber countdown, shows time-to-end',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Sprint Review',
            start: now.subtract(const Duration(minutes: 10)),
            end: now.add(const Duration(minutes: 20)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(find.text('20 min'), findsOneWidget);
      final countdownText = tester.widget<Text>(find.descendant(
        of: find.byType(CountdownDisplay),
        matching: find.byType(Text),
      ));
      expect(countdownText.style?.color, const Color(0xFFFFC107)); // Amber
    });

    testWidgets('CR-02: CountdownDisplay is right of the now-line',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Meeting',
            start: now.add(const Duration(minutes: 38)),
            end: now.add(const Duration(minutes: 68)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      final sw = tester.getSize(find.byType(TimelineStrip)).width;
      final nowIndicatorX = sw * 0.10;
      final countdownRect = tester.getRect(find.byType(CountdownDisplay));
      expect(countdownRect.left, greaterThan(nowIndicatorX));
    });

    testWidgets('task event shows CountdownDisplay (future task)',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'task-1',
            title: 'Review PR',
            start: now.add(const Duration(minutes: 45)),
            end: now.add(const Duration(minutes: 75)),
            isTask: true,
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(find.text('45 min'), findsOneWidget);
    });

    testWidgets('CustomPaint with TimelinePainter is present in widget tree',
        (tester) async {
      await tester.pumpWidget(_wrap(TimelineStrip(
        events: [
          _evt(
            id: 'e1',
            title: 'Meeting',
            start: now.add(const Duration(hours: 1)),
            end: now.add(const Duration(hours: 2)),
          ),
        ],
        clockService: clock,
        calendarController: controller,
        settingsService: fakeSettings,
        onSignOut: () {},
        windowService: fakeWS,
      )));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is TimelinePainter),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

}
