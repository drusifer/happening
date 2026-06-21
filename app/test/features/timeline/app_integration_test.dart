import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:happening/app.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/auth/auth_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/timeline_strip.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _StubProbe implements DisplayProbe {
  _StubProbe(this._displays);
  final List<DisplayInfo> _displays;
  @override
  Future<List<DisplayInfo>> getAll() async => List.of(_displays);
}

class _StubEvents implements DisplayEvents {
  @override
  void Function() subscribe(void Function() onChange) {
    return () {};
  }
}

class _FakeWindowService extends WindowService {
  _FakeWindowService({required super.displayService})
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  @override
  Future<void> applyState(StripState state) async {
    return;
  }

  @override
  Future<void> setWindowMode(WindowMode mode) async {
    return;
  }

  @override
  Future<void> focus() async {
    return;
  }

  @override
  Future<void> sendToBack() async {
    return;
  }

  @override
  Future<void> restoreToFront() async {
    return;
  }
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService([double initial = kDefaultFontSizePx])
      : super(directory: Directory.systemTemp) {
    _cur = AppSettings(fontSizePx: initial);
  }

  late AppSettings _cur;
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  AppSettings get current => _cur;

  @override
  Future<void> update(AppSettings s) async {
    _cur = s;
    _controller.add(s);
    notifyListeners();
  }

  @override
  Future<void> load() async {
    return;
  }

  @override
  Stream<AppSettings> get settings => _controller.stream;

  @override
  void dispose() {
    unawaited(_controller.close());
    super.dispose();
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

class _MockService implements CalendarService {
  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async => [];
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

class _FakeCalendarController extends CalendarController {
  _FakeCalendarController(super.service, {super.settingsService});

  final _streamController = StreamController<List<CalendarEvent>>.broadcast();

  @override
  Stream<List<CalendarEvent>> get events => _streamController.stream;

  @override
  List<CalendarEvent>? get lastEvents => [];

  @override
  Future<void> start() async {
    return;
  }

  void emit(List<CalendarEvent> evs) {
    _streamController.add(evs);
  }

  @override
  void dispose() {
    unawaited(_streamController.close());
    super.dispose();
  }
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({required this.shouldRestore});
  final bool shouldRestore;
  bool signedIn = false;

  @override
  bool get isSignedIn => signedIn || shouldRestore;

  @override
  AutoRefreshingAuthClient? get client => null;

  @override
  Future<bool> tryRestore() async {
    return shouldRestore;
  }

  @override
  Future<bool> signIn() async {
    signedIn = true;
    return true;
  }

  @override
  void cancelSignIn() {
    return;
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }
}

void _wideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('HappeningApp Headless Integration Tests', () {
    late _FakeSettingsService fakeSettings;
    late _FakeClock fakeClock;
    late _MockService mockCalendarService;
    late _FakeCalendarController fakeCalendar;

    setUp(() {
      fakeSettings = _FakeSettingsService();
      fakeClock = _FakeClock(DateTime(2026, 6, 3, 10, 0));
      mockCalendarService = _MockService();
      fakeCalendar = _FakeCalendarController(mockCalendarService,
          settingsService: fakeSettings);
    });

    tearDown(() {
      fakeSettings.dispose();
      fakeCalendar.dispose();
    });

    DisplayInfo display(String id,
            {bool primary = false, double originX = 0}) =>
        DisplayInfo(
          id: DisplayId(id),
          osName: 'M-$id',
          size: const Size(1920, 1080),
          workAreaOrigin: Offset(originX, 0),
          workAreaSize: const Size(1920, 1080),
          scaleFactor: 1.0,
          isPrimary: primary,
        );

    Future<DisplayService> mkSvc(List<DisplayInfo> displays) async {
      final svc = DisplayService(
        probe: _StubProbe(displays),
        events: _StubEvents(),
        sleep: (_) async {},
      );
      await svc.initialize();
      return svc;
    }

    testWidgets('authenticated view shows Display section in SettingsPanel',
        (tester) async {
      _wideScreen(tester);
      final displaySvc = await mkSvc(
          [display('a', primary: true), display('b', originX: 1920)]);
      final fakeWindowService = _FakeWindowService(displayService: displaySvc);
      final fakeAuthService = _FakeAuthService(shouldRestore: true);

      await tester.pumpWidget(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        displayService: displaySvc,
        authServiceOverride: fakeAuthService,
        calendarControllerOverride: fakeCalendar,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      ));

      // Wait for auth tryRestore and state initialization
      await tester.pump();
      await tester.pumpAndSettle();

      // Open settings panel
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Verify the Display section header and individual displays are rendered
      expect(find.text('Display'), findsOneWidget);
      expect(find.textContaining('M-a'), findsOneWidget);
      expect(find.textContaining('M-b'), findsOneWidget);
    });

    testWidgets('unauthenticated view forwards displayService to TimelineStrip',
        (tester) async {
      _wideScreen(tester);
      final displaySvc = await mkSvc(
          [display('a', primary: true), display('b', originX: 1920)]);
      final fakeWindowService = _FakeWindowService(displayService: displaySvc);
      final fakeAuthService = _FakeAuthService(shouldRestore: false);

      await tester.pumpWidget(HappeningApp(
        settingsService: fakeSettings,
        windowService: fakeWindowService,
        displayService: displaySvc,
        authServiceOverride: fakeAuthService,
        calendarControllerOverride: fakeCalendar,
        clockServiceOverride: fakeClock,
        enableAnimations: false,
      ));

      // Wait for auth tryRestore and state initialization
      await tester.pump();
      await tester.pumpAndSettle();

      // Find TimelineStrip and verify displayService is forwarded correctly
      final stripFinder = find.byType(TimelineStrip);
      expect(stripFinder, findsOneWidget);
      final TimelineStrip strip = tester.widget(stripFinder);
      expect(strip.displayService, same(displaySvc));
    });
  });
}
