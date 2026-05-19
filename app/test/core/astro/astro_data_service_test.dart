import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_data_service.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/settings/settings_service.dart';

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService(AppSettings initial)
      : _current = initial,
        super(directory: Directory(Directory.systemTemp.path));

  AppSettings _current;

  @override
  AppSettings get current => _current;

  void emit(AppSettings s) {
    _current = s;
    notifyListeners();
  }
}

const _nyLat = 40.7128;
const _nyLng = -74.0060;

AppSettings _astroSettings({
  double? lat = _nyLat,
  double? lng = _nyLng,
  String? city = 'New York',
}) =>
    AppSettings(
      theme: AppTheme.astronomical,
      astroSettings: AstroSettings(latitude: lat, longitude: lng, cityName: city),
    );

void main() {
  group('AstroDataService', () {
    test('current is null with default (non-astronomical) settings', () {
      final settings = _FakeSettingsService(const AppSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      expect(svc.current, isNull);
      svc.dispose();
      settings.dispose();
    });

    test('current is null when theme is astronomical but no location', () {
      final settings = _FakeSettingsService(
        const AppSettings(theme: AppTheme.astronomical),
      );
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      expect(svc.current, isNull);
      svc.dispose();
      settings.dispose();
    });

    test('current becomes null when settings change to non-astronomical', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      // Wait for async calculation.
      await Future.delayed(const Duration(milliseconds: 100));
      expect(svc.current, isNotNull);

      settings.emit(const AppSettings(theme: AppTheme.dark));
      expect(svc.current, isNull);

      svc.dispose();
      settings.dispose();
    });

    test('calculates solar times with correct ordering', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      await Future.delayed(const Duration(milliseconds: 100));

      final data = svc.current;
      expect(data, isNotNull);
      // Civil twilight begins before sunrise.
      expect(data!.civilTwilightBegin.isBefore(data.sunrise), isTrue);
      // Sunrise before solar noon.
      expect(data.sunrise.isBefore(data.solarNoon), isTrue);
      // Solar noon before sunset.
      expect(data.solarNoon.isBefore(data.sunset), isTrue);
      // Sunset before civil twilight end.
      expect(data.sunset.isBefore(data.civilTwilightEnd), isTrue);

      svc.dispose();
      settings.dispose();
    });

    test('illuminationFraction is in [0, 1]', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      await Future.delayed(const Duration(milliseconds: 100));

      final data = svc.current!;
      expect(data.illuminationFraction, inInclusiveRange(0.0, 1.0));

      svc.dispose();
      settings.dispose();
    });

    test('phase is a valid MoonPhase value', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(MoonPhase.values, contains(svc.current!.phase));

      svc.dispose();
      settings.dispose();
    });

    test('cache hit: notifyListeners not called again for same params', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      await Future.delayed(const Duration(milliseconds: 100));
      final first = svc.current;

      int notifyCount = 0;
      svc.addListener(() => notifyCount++);

      // Trigger settings change with identical astro location.
      settings.emit(_astroSettings());
      await Future.delayed(const Duration(milliseconds: 50));

      // Cache hit → no additional notify.
      expect(notifyCount, 0);
      expect(svc.current, same(first));

      svc.dispose();
      settings.dispose();
    });

    test('recalculates when location changes', () async {
      final settings = _FakeSettingsService(_astroSettings());
      final svc = AstroDataService(settingsService: settings);
      svc.initialize();

      await Future.delayed(const Duration(milliseconds: 100));
      final first = svc.current;

      // Change location to London.
      settings.emit(_astroSettings(lat: 51.5074, lng: -0.1278, city: 'London'));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(svc.current, isNotNull);
      expect(svc.current, isNot(same(first)));

      svc.dispose();
      settings.dispose();
    });
  });
}
