// Widget-level regression tests for HappeningApp auth-state → button visibility.
//
// BUG-C: Refresh and settings buttons disappeared from the strip on Linux after
// a transient DNS failure at ~18:28 (log: build/tmp).  Root cause under
// investigation; these tests lock in the expected invariants so any regression
// is caught immediately:
//
//   • When auth restore succeeds → buttons visible.
//   • When auth restore fails    → buttons hidden (sign-in prompt instead).
//   • When calendar fetch throws a network error → auth state must NOT flip to
//     unauthenticated; buttons must remain visible.
//   • Tapping refresh while authenticated must NOT cause unauthenticated state.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:happening/app.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/auth/auth_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

/// WindowService that never touches the OS.
class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  @override
  double getCollapsedHeight() => 55.0;

  @override
  double getExpandedHeight() => 250.0;

  @override
  Future<void> expand({double? height}) async {
    isExpandedNotifier.value = true;
  }

  @override
  Future<void> collapse({double? height}) async {
    isExpandedNotifier.value = false;
  }

  @override
  Future<void> reassertAppBar() async {}
}

/// ClockService with empty streams — avoids periodic timers that block pumpAndSettle.
class _FakeClockService extends ClockService {
  final DateTime fixedTime;
  _FakeClockService(this.fixedTime);

  @override
  DateTime get now => fixedTime;

  @override
  Stream<DateTime> get tick1s => const Stream.empty();

  @override
  Stream<DateTime> get tick10s => const Stream.empty();
}

/// Fake SettingsService with defaults.
class _FakeSettingsService extends SettingsService {
  _FakeSettingsService() : super(directory: Directory.systemTemp);

  @override
  AppSettings get current => const AppSettings();

  @override
  Stream<AppSettings> get settings => const Stream.empty();
}

/// Fake CalendarService — never throws, returns empty events.
class _FakeCalendarService implements CalendarService {
  bool shouldThrow = false;
  int fetchCalls = 0;

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    fetchCalls++;
    if (shouldThrow) throw Exception('network error: DNS failure');
    return [];
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

/// CalendarController backed by a controllable fake service.
class _FakeCalendarController extends CalendarController {
  _FakeCalendarController(this._fakeService)
      : super(_fakeService, settingsService: null);

  final _FakeCalendarService _fakeService;
  int refreshCalls = 0;

  bool get didThrowOnFetch => _fakeService.shouldThrow;
  set throwOnFetch(bool v) => _fakeService.shouldThrow = v;

  @override
  Future<void> refresh() async {
    refreshCalls++;
    await super.refresh();
  }
}

/// Controllable fake auth service.
class _FakeAuthService implements AuthService {
  _FakeAuthService({
    this.tryRestoreResult = true,
    this.signInResult = true,
  });

  final bool tryRestoreResult;
  final bool signInResult;
  bool _signedIn = false;
  bool cancelCalled = false;

  @override
  Future<bool> tryRestore() async {
    if (tryRestoreResult) _signedIn = true;
    return tryRestoreResult;
  }

  @override
  Future<bool> signIn() async {
    if (signInResult) _signedIn = true;
    return signInResult;
  }

  @override
  void cancelSignIn() => cancelCalled = true;

  @override
  Future<void> signOut() async => _signedIn = false;

  @override
  bool get isSignedIn => _signedIn;

  @override
  AutoRefreshingAuthClient? get client =>
      null; // not used when controller is injected
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => child; // HappeningApp is itself a MaterialApp

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSettingsService fakeSettings;
  late _FakeWindowService fakeWindowService;
  late _FakeClockService fakeClock;

  setUp(() {
    fakeSettings = _FakeSettingsService();
    fakeWindowService = _FakeWindowService();
    fakeClock = _FakeClockService(DateTime(2026, 4, 19, 10, 0));
  });

  group('BUG-C: auth-state → button visibility', () {
    // ── happy path ──────────────────────────────────────────────────────────

    testWidgets('buttons visible when tryRestore succeeds (authenticated)',
        (tester) async {
      final fakeAuth = _FakeAuthService(tryRestoreResult: true);
      final fakeController = _FakeCalendarController(_FakeCalendarService());

      await tester.pumpWidget(_wrap(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        authServiceOverride: fakeAuth,
        calendarControllerOverride: fakeController,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      )));

      // Let _initServices complete and setState rebuild.
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.refresh), findsOneWidget,
          reason: 'BUG-C: refresh button must be visible when authenticated');
      expect(find.byIcon(Icons.settings), findsOneWidget,
          reason: 'BUG-C: settings button must be visible when authenticated');
    });

    // ── unauthenticated path ────────────────────────────────────────────────

    testWidgets('buttons hidden when tryRestore fails (unauthenticated)',
        (tester) async {
      final fakeAuth = _FakeAuthService(tryRestoreResult: false);

      await tester.pumpWidget(_wrap(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        authServiceOverride: fakeAuth,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      )));

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.refresh), findsNothing,
          reason:
              'BUG-C: refresh button must NOT be visible when unauthenticated');
      expect(find.byIcon(Icons.settings), findsNothing,
          reason:
              'BUG-C: settings button must NOT be visible when unauthenticated');
    });

    // ── network-error regression ────────────────────────────────────────────

    testWidgets(
        'BUG-C: buttons remain visible after calendar fetch network error',
        (tester) async {
      final fakeAuth = _FakeAuthService(tryRestoreResult: true);
      final fakeService = _FakeCalendarService();
      final fakeController = _FakeCalendarController(fakeService);

      await tester.pumpWidget(_wrap(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        authServiceOverride: fakeAuth,
        calendarControllerOverride: fakeController,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      )));

      await tester.pump();
      await tester.pump(Duration.zero);

      // Confirm buttons are visible while authenticated.
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Simulate DNS failure: all fetches now throw.
      fakeService.shouldThrow = true;
      unawaited(fakeController.refresh());
      await tester.pump();
      await tester.pump(Duration.zero);

      // Auth state must NOT have changed — buttons must still be visible.
      expect(find.byIcon(Icons.refresh), findsOneWidget,
          reason: 'BUG-C: refresh button disappeared after network error — '
              'auth state was incorrectly set to unauthenticated');
      expect(find.byIcon(Icons.settings), findsOneWidget,
          reason: 'BUG-C: settings button disappeared after network error');
    });

    // ── refresh tap regression ──────────────────────────────────────────────

    testWidgets(
        'BUG-C: tapping refresh while authenticated does not change auth state',
        (tester) async {
      final fakeAuth = _FakeAuthService(tryRestoreResult: true);
      final fakeController = _FakeCalendarController(_FakeCalendarService());

      await tester.pumpWidget(_wrap(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        authServiceOverride: fakeAuth,
        calendarControllerOverride: fakeController,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      )));

      await tester.pump();
      await tester.pump(Duration.zero);

      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      await tester.pump(Duration.zero);

      // Buttons must still be visible — refresh should never sign the user out.
      expect(find.byIcon(Icons.refresh), findsOneWidget,
          reason: 'BUG-C: tap refresh caused auth state to change');
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    // ── sign-in prompt shown when unauthenticated ───────────────────────────

    testWidgets('sign-in tap-to-sign-in overlay shown when unauthenticated',
        (tester) async {
      final fakeAuth = _FakeAuthService(tryRestoreResult: false);

      await tester.pumpWidget(_wrap(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        authServiceOverride: fakeAuth,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      )));

      await tester.pump();
      await tester.pump(Duration.zero);

      // The sign-in overlay (GestureDetector covering the strip) should exist.
      // TimelinePainter renders the "tap to sign in" text — just verify buttons gone.
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(find.byIcon(Icons.settings), findsNothing);
      // Power button is always present.
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });
  });
}
