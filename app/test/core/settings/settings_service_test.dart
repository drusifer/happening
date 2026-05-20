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

    test('current defaults to kDefaultFontSizePx before load', () {
      expect(svc.current.fontSizePx, kDefaultFontSizePx);
    });

    test('load() with no file uses default fontSizePx', () async {
      await svc.load();
      expect(svc.current.fontSizePx, kDefaultFontSizePx);
    });

    // ── Load ──────────────────────────────────────────────────────────────

    test('load() reads fontSizePx from existing settings.json', () async {
      final file = File('${tmpDir.path}/settings.json');
      file.writeAsStringSync(jsonEncode({'fontSizePx': 18.0}));
      await svc.load();
      expect(svc.current.fontSizePx, 18.0);
    });

    test('load() migrates legacy fontSize string "large" to 17.0', () async {
      final file = File('${tmpDir.path}/settings.json');
      file.writeAsStringSync(jsonEncode({'fontSize': 'large'}));
      await svc.load();
      expect(svc.current.fontSizePx, 17.0);
    });

    test('load() migrates legacy fontSize string "small" to 13.0', () async {
      final file = File('${tmpDir.path}/settings.json');
      file.writeAsStringSync(jsonEncode({'fontSize': 'small'}));
      await svc.load();
      expect(svc.current.fontSizePx, 13.0);
    });

    test('load() emits settings on stream', () async {
      final emitted = <AppSettings>[];
      svc.settings.listen(emitted.add);
      await svc.load();
      expect(emitted, hasLength(1));
      expect(emitted.first.fontSizePx, kDefaultFontSizePx);
    });

    test('load() with corrupt JSON falls back to defaults', () async {
      File('${tmpDir.path}/settings.json').writeAsStringSync('{bad json}}}');
      await svc.load();
      expect(svc.current.fontSizePx, kDefaultFontSizePx);
    });

    test('load() with unknown legacy fontSize string falls back to default',
        () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSize': 'enormous'}));
      await svc.load();
      expect(svc.current.fontSizePx, kDefaultFontSizePx);
    });

    test('load() clamps fontSizePx below minimum', () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSizePx': 5.0}));
      await svc.load();
      expect(svc.current.fontSizePx, kMinFontSizePx);
    });

    test('load() clamps fontSizePx above maximum', () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSizePx': 99.0}));
      await svc.load();
      expect(svc.current.fontSizePx, kMaxFontSizePx);
    });

    test('load() with missing fields uses defaults (backward compatible)',
        () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'fontSizePx': 17.0}));
      await svc.load();
      expect(svc.current.fontSizePx, 17.0);
      expect(svc.current.theme, AppTheme.dark);
      expect(svc.current.timeWindowHours, 8);
      expect(svc.current.selectedCalendarIds, isEmpty);
      expect(svc.current.windowMode, WindowMode.reserved);
      expect(svc.current.idleTimelineOpacity, 1.0);
    });

    test('load() clamps idle opacity below supported range', () async {
      File('${tmpDir.path}/settings.json').writeAsStringSync(jsonEncode({
        'idleTimelineOpacity': 0.10,
      }));
      await svc.load();
      expect(svc.current.idleTimelineOpacity, kMinIdleTimelineOpacity);
    });

    test('load() clamps idle opacity above supported range', () async {
      File('${tmpDir.path}/settings.json').writeAsStringSync(jsonEncode({
        'idleTimelineOpacity': 1.1,
      }));
      await svc.load();
      expect(svc.current.idleTimelineOpacity, kMaxIdleTimelineOpacity);
    });

    // ── Update ────────────────────────────────────────────────────────────

    test('update() changes current immediately', () async {
      await svc.update(const AppSettings(fontSizePx: 13.0));
      expect(svc.current.fontSizePx, 13.0);
    });

    test('update() emits on stream', () async {
      final emitted = <AppSettings>[];
      svc.settings.listen(emitted.add);
      await svc.update(const AppSettings(fontSizePx: 17.0));
      expect(emitted, hasLength(1));
      expect(emitted.first.fontSizePx, 17.0);
    });

    test('update() persists all fields to settings.json', () async {
      const settings = AppSettings(
        fontSizePx: 13.0,
        theme: AppTheme.light,
        timeWindowHours: 12,
        selectedCalendarIds: ['cal-1', 'cal-2'],
        windowMode: WindowMode.overlay,
        idleTimelineOpacity: 0.70,
      );
      await svc.update(settings);

      final raw = File('${tmpDir.path}/settings.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['fontSizePx'], 13.0);
      expect(json['theme'], 'light');
      expect(json['timeWindowHours'], 12);
      expect(json['selectedCalendarIds'], ['cal-1', 'cal-2']);
      expect(json['windowMode'], 'overlay');
      expect(json['idleTimelineOpacity'], 0.70);
    });

    test('reload after update returns all persisted values', () async {
      const settings = AppSettings(
        fontSizePx: 17.0,
        theme: AppTheme.system,
        timeWindowHours: 24,
        selectedCalendarIds: ['primary'],
        windowMode: WindowMode.overlay,
        idleTimelineOpacity: 0.40,
      );
      await svc.update(settings);

      final svc2 = SettingsService(directory: tmpDir);
      addTearDown(svc2.dispose);
      await svc2.load();
      expect(svc2.current.fontSizePx, 17.0);
      expect(svc2.current.theme, AppTheme.system);
      expect(svc2.current.timeWindowHours, 24);
      expect(svc2.current.selectedCalendarIds, ['primary']);
      expect(svc2.current.windowMode, WindowMode.overlay);
      expect(svc2.current.idleTimelineOpacity, 0.40);
    });

    test('fromString migrates legacy "transparent" value to overlay', () async {
      File('${tmpDir.path}/settings.json')
          .writeAsStringSync(jsonEncode({'windowMode': 'transparent'}));
      await svc.load();
      expect(svc.current.windowMode, WindowMode.overlay);
    });

    test('effectiveWindowMode is always reserved', () {
      expect(const AppSettings().effectiveWindowMode, WindowMode.reserved);
      expect(
        const AppSettings(windowMode: WindowMode.overlay).effectiveWindowMode,
        WindowMode.reserved,
      );
    });

    // ── fontSizePx constants ──────────────────────────────────────────────

    test('kDefaultFontSizePx is 15', () => expect(kDefaultFontSizePx, 15.0));
    test('kMinFontSizePx is 11', () => expect(kMinFontSizePx, 11.0));
    test('kMaxFontSizePx is 22', () => expect(kMaxFontSizePx, 22.0));

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
