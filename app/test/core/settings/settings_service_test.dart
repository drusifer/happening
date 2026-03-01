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

    test('update() persists to settings.json', () async {
      await svc.update(const AppSettings(fontSize: FontSize.small));
      final raw = File('${tmpDir.path}/settings.json').readAsStringSync();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(json['fontSize'], 'small');
    });

    test('reload after update returns persisted value', () async {
      await svc.update(const AppSettings(fontSize: FontSize.large));

      final svc2 = SettingsService(directory: tmpDir);
      addTearDown(svc2.dispose);
      await svc2.load();
      expect(svc2.current.fontSize, FontSize.large);
    });

    // ── FontSize enum ─────────────────────────────────────────────────────

    test('FontSize.small px is 9', () => expect(FontSize.small.px, 9.0));
    test('FontSize.medium px is 11', () => expect(FontSize.medium.px, 11.0));
    test('FontSize.large px is 13', () => expect(FontSize.large.px, 13.0));

    test('FontSize.fromString round-trips all values', () {
      for (final size in FontSize.values) {
        expect(FontSize.fromString(size.name), size);
      }
    });
  });
}
