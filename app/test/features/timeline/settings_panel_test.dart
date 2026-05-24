// Widget tests for SettingsPanel (S4-11).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/app_metadata.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/timeline/settings_panel.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

class _FakeCalendarService implements CalendarService {
  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];
  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async => [];
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => [];
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService([double initial = kDefaultFontSizePx])
      : super(directory: Directory.systemTemp) {
    _cur = AppSettings(fontSizePx: initial);
  }

  late AppSettings _cur;
  final List<AppSettings> updates = [];

  @override
  AppSettings get current => _cur;

  @override
  Future<void> update(AppSettings s) async {
    _cur = s;
    updates.add(s);
  }

  @override
  Future<void> load() async {}
}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Align(alignment: Alignment.topRight, child: child)),
    );

/// Widens the test viewport to 1600×900 for tests that add the Location column.
void _wideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('SettingsPanel', () {
    late _FakeSettingsService fakeSettings;

    setUp(() => fakeSettings = _FakeSettingsService());

    // ── Rendering ────────────────────────────────────────────────────────────

    testWidgets('renders SETTINGS header with version', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('SETTINGS  v. $appVersion'), findsOneWidget);
    });

    testWidgets('renders Font Size label', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('Font Size'), findsOneWidget);
    });

    testWidgets('renders font size slider with Smaller/Default/Larger labels',
        (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('Smaller'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Larger'), findsOneWidget);
    });

    testWidgets('renders Logout button', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('LOGOUT'), findsOneWidget);
    });

    testWidgets('renders About link', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('renders transparency slider labels', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));

      expect(find.text('Transparency'), findsOneWidget);
      expect(find.text('See-through'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Opaque'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
    });

    // ── Interactions ─────────────────────────────────────────────────────────

    testWidgets('dragging font size slider does not update settings mid-drag',
        (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      // onChanged (drag) must NOT call settingsService.update.
      sliders.first.onChanged!(19.0);
      expect(fakeSettings.updates, isEmpty);
    });

    testWidgets('releasing font size slider commits fontSizePx',
        (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      // onChangeEnd (release) commits the value.
      sliders.first.onChangeEnd!(19.0);
      await tester.pump();
      expect(fakeSettings.updates, hasLength(1));
      expect(fakeSettings.updates.first.fontSizePx, 19.0);
    });

    testWidgets('tapping Logout fires onSignOut', (tester) async {
      bool fired = false;
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () => fired = true,
      )));
      await tester.tap(find.text('LOGOUT'));
      expect(fired, isTrue);
    });

    testWidgets('Logout does NOT call settingsService.update', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.tap(find.text('LOGOUT'));
      expect(fakeSettings.updates, isEmpty);
    });

    testWidgets('moving transparency slider updates idle opacity',
        (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));

      // Transparency slider is second (font size slider is first).
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      sliders.last.onChanged!(0.75);

      expect(fakeSettings.updates.last.idleTimelineOpacity, 0.75);
    });

    testWidgets('tapping About opens project URL', (tester) async {
      Uri? openedUrl;

      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: fakeSettings,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
        launchAboutUrl: (url) async {
          openedUrl = url;
          return true;
        },
      )));

      await tester.tap(find.text('ABOUT'));
      await tester.pump();

      expect(openedUrl, Uri.parse(appAboutUrl));
    });

    // ── Slider initial value ──────────────────────────────────────────────────

    testWidgets('font size slider reflects current fontSizePx', (tester) async {
      final svc = _FakeSettingsService(19.0);
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));

      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      expect(sliders.first.value, 19.0);
    });
  });

  // ── Astronomical Location Section ─────────────────────────────────────────

  group('Astronomical location section', () {
    testWidgets('Location section not shown when theme is dark',
        (tester) async {
      final svc = _FakeSettingsService();
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      expect(find.text('Location'), findsNothing);
    });

    testWidgets('Location section shown when theme is astronomical',
        (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.pump();
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('shows no-location prompt when astronomical + no location',
        (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.pump();
      expect(find.text('Set location to see sunrise & moon times'),
          findsOneWidget);
    });

    testWidgets('shows location preview when lat/lng saved', (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(
        theme: AppTheme.astronomical,
        astroSettings: AstroSettings(
          latitude: 40.71,
          longitude: -74.0,
          cityName: 'New York',
        ),
      ));
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.pump();
      expect(find.textContaining('New York'), findsOneWidget);
    });

    testWidgets('city search no-match error shown on null resolve',
        (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));

      Future<CityResult?> alwaysNull(String q) async => null;

      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
        resolveCityName: alwaysNull,
      )));
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('city_search_field')), 'Xyzzy');
      await tester.tap(find.byKey(const Key('city_search_button')));
      await tester.pump();

      expect(find.textContaining("No results for 'Xyzzy'"), findsOneWidget);
    });

    testWidgets('city search match shows preview and confirm', (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));

      Future<CityResult?> resolveNewYork(String q) async =>
          (lat: 40.71, lng: -74.0, label: 'New York, NY');

      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
        resolveCityName: resolveNewYork,
      )));
      await tester.pump();

      await tester.enterText(
          find.byKey(const Key('city_search_field')), 'New York');
      await tester.tap(find.byKey(const Key('city_search_button')));
      await tester.pump();

      expect(find.textContaining('New York, NY'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('Advanced section hidden by default', (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.pump();
      expect(find.byKey(const Key('lat_field')), findsNothing);
    });

    testWidgets('Apply saves invalid coords shows error', (tester) async {
      _wideScreen(tester);
      final svc = _FakeSettingsService();
      await svc.update(const AppSettings(theme: AppTheme.astronomical));
      await tester.pumpWidget(_wrap(SettingsPanel(
        settingsService: svc,
        calendarController: CalendarController(_FakeCalendarService()),
        onSignOut: () {},
      )));
      await tester.pump();

      // Open Advanced.
      await tester.tap(find.text('Advanced'));
      await tester.pump();

      // Enter invalid lat.
      await tester.enterText(find.byKey(const Key('lat_field')), '999');
      await tester.tap(find.byKey(const Key('apply_coords_button')));
      await tester.pump();

      expect(find.textContaining('Invalid coordinates'), findsOneWidget);
    });
  });
}
