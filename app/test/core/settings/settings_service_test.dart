import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';

void main() {
  group('SettingsService', () {
    late Directory tmpDir;
    late SettingsService svc;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('settings_test_');
      svc = SettingsService(directory: tmpDir);
    });

    tearDown(() {
      svc.dispose();
      tmpDir.deleteSync(recursive: true);
    });

    // ── Defaults ──────────────────────────────────────────────────────────

    test('current defaults to FontSize.medium before load', () {
      expect(svc.current.fontSize, FontSize.medium);
    });

    test('load() with no file uses default FontSize.medium', () async {
      await svc.load();
      expect(svc.current.fontSize, FontSize.medium);
    });

    // ── Load ──────────────────────────────────────────────────────────────

    test('load() reads fontSize from existing settings.json', () async {
      final file = File('${tmpDir.path}/settings.json');
      file.writeAsStringSync(jsonEncode({'fontSize': 'large'}));
      await svc.load();
      expect(svc.current.fontSize, FontSize.large);
    });

    test('load() emits settings on stream', () async {
      final emitted = <AppSettings>[];
      svc.settings.listen(emitted.add);
      await svc.load();
      expect(emitted, hasLength(1));
      expect(emitted.first.fontSize, FontSize.medium);
    });

    test('load() with corrupt JSON falls back to defaults', () async {
      File('${tmpDir.path}/settings.json').writeAsStringSync('{bad json}}}');
      await svc.load();
      expect(svc.current.fontSize, FontSize.medium);
    });

    test('load() with unknown fontSize value falls back to medium', () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSize': 'enormous'}));
      await svc.load();
      expect(svc.current.fontSize, FontSize.medium);
    });

    test('load() with missing fields uses defaults (backward compatible)',
        () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSize': 'large'}));
      await svc.load();
      expect(svc.current.fontSize, FontSize.large);
      expect(svc.current.theme, AppTheme.dark);
      expect(svc.current.timeWindowHours, 8);
      expect(svc.current.selectedCalendarIds, isEmpty);
    });

    // ── Update ────────────────────────────────────────────────────────────

    test('update() changes current immediately', () async {
      await svc.update(const AppSettings(fontSize: FontSize.small));
      expect(svc.current.fontSize, FontSize.small);
    });

    test('update() emits on stream', () async {
      final emitted = <AppSettings>[];
      svc.settings.listen(emitted.add);
      await svc.update(const AppSettings(fontSize: FontSize.large));
      expect(emitted, hasLength(1));
      expect(emitted.first.fontSize, FontSize.large);
    });

    test('update() persists all fields to settings.json', () async {
      const settings = AppSettings(
        fontSize: FontSize.small,
        theme: AppTheme.light,
        timeWindowHours: 12,
        selectedCalendarIds: ['cal-1', 'cal-2'],
      );
      await svc.update(settings);

      final raw = File('${tmpDir.path}/settings.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['fontSize'], 'small');
      expect(json['theme'], 'light');
      expect(json['timeWindowHours'], 12);
      expect(json['selectedCalendarIds'], ['cal-1', 'cal-2']);
    });

    test('reload after update returns all persisted values', () async {
      const settings = AppSettings(
        fontSize: FontSize.large,
        theme: AppTheme.system,
        timeWindowHours: 24,
        selectedCalendarIds: ['primary'],
      );
      await svc.update(settings);

      final svc2 = SettingsService(directory: tmpDir);
      addTearDown(svc2.dispose);
      await svc2.load();
      expect(svc2.current.fontSize, FontSize.large);
      expect(svc2.current.theme, AppTheme.system);
      expect(svc2.current.timeWindowHours, 24);
      expect(svc2.current.selectedCalendarIds, ['primary']);
    });

    // ── FontSize enum ─────────────────────────────────────────────────────

    test('FontSize.small px is 13', () => expect(FontSize.small.px, 13.0));
    test('FontSize.medium px is 15', () => expect(FontSize.medium.px, 15.0));
    test('FontSize.large px is 17', () => expect(FontSize.large.px, 17.0));

    test('FontSize.fromString round-trips all values', () {
      for (final size in FontSize.values) {
        expect(FontSize.fromString(size.name), size);
      }
    });

    // ── AppTheme enum ─────────────────────────────────────────────────────

    test('AppTheme.fromString round-trips all values', () {
      for (final theme in AppTheme.values) {
        expect(AppTheme.fromString(theme.name), theme);
      }
    });

    test('AppTheme.fromString defaults to dark on unknown value', () {
      expect(AppTheme.fromString('neon'), AppTheme.dark);
    });
  });
}
