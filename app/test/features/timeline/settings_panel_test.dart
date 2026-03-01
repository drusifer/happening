// Widget tests for SettingsPanel (S4-11).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/timeline/settings_panel.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService([FontSize initial = FontSize.medium])
      : super(directory: Directory.systemTemp) {
    _cur = AppSettings(fontSize: initial);
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

void main() {
  group('SettingsPanel', () {
    late _FakeSettingsService fakeSettings;

    setUp(() => fakeSettings = _FakeSettingsService());

    // ── Rendering ────────────────────────────────────────────────────────────

    testWidgets('renders SETTINGS header', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('renders Font Size label', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      expect(find.text('Font Size'), findsOneWidget);
    });

    testWidgets('renders S M L font size buttons', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('renders Logout button', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      expect(find.text('Logout'), findsOneWidget);
    });

    // ── Interactions ─────────────────────────────────────────────────────────

    testWidgets('tapping Small calls update(FontSize.small)', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      await tester.tap(find.text('Small'));
      expect(fakeSettings.updates, hasLength(1));
      expect(fakeSettings.updates.first.fontSize, FontSize.small);
    });

    testWidgets('tapping Large calls update(FontSize.large)', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      await tester.tap(find.text('Large'));
      expect(fakeSettings.updates.first.fontSize, FontSize.large);
    });

    testWidgets('tapping Logout fires onSignOut', (tester) async {
      bool fired = false;
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () => fired = true)));
      await tester.tap(find.text('Logout'));
      expect(fired, isTrue);
    });

    testWidgets('Logout does NOT call settingsService.update', (tester) async {
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));
      await tester.tap(find.text('Logout'));
      expect(fakeSettings.updates, isEmpty);
    });

    // ── Selection state ───────────────────────────────────────────────────────

    testWidgets('Medium button has blueAccent highlight when selected',
        (tester) async {
      // Default is medium.
      await tester.pumpWidget(_wrap(SettingsPanel(
          settingsService: fakeSettings, onSignOut: () {})));

      // Find the Container around "Medium" and inspect its color.
      final mediumFinder = find.ancestor(
        of: find.text('Medium'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(mediumFinder.first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blueAccent));
    });

    testWidgets('selecting Small changes highlight to Small button',
        (tester) async {
      final svc = _FakeSettingsService(FontSize.small);
      await tester.pumpWidget(_wrap(
          SettingsPanel(settingsService: svc, onSignOut: () {})));

      final smallFinder = find.ancestor(
        of: find.text('Small'),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(smallFinder.first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blueAccent));
    });
  });
}
