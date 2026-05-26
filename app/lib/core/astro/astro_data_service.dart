// Service providing real-time solar and lunar events.
//
// TLDR:
// Overview: Computes and exposes offline astronomical data (sunrise, sunset, moon phases) for the timeline.
// Problem:  Need local, real-time daylight gradients and celestial markers based on user location.
// Solution: Listens to SettingsService, calculates solar/lunar times locally, and caches results.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:flutter/foundation.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:logging/logging.dart';

class AstroDataService extends ChangeNotifier {
  static final _log = Logger('AstroDataService');

  AstroDataService({required SettingsService settingsService})
      : _settings = settingsService;

  final SettingsService _settings;

  AstroData? _current;
  Timer? _midnightTimer;
  bool _disposed = false;

  ({String dateKey, double lat, double lng, AstroData data})? _cache;

  AstroData? get current => _current;

  void initialize() {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    final s = _settings.current;
    _log.fine('_onSettingsChanged: theme=${s.theme.name} '
        'hasLocation=${s.astroSettings.hasLocation} '
        'lat=${s.astroSettings.latitude} lng=${s.astroSettings.longitude}');

    if (s.theme != AppTheme.astronomical || !s.astroSettings.hasLocation) {
      _log.fine('_onSettingsChanged: skipping — theme or location not set');
      if (_current != null) {
        _current = null;
        notifyListeners();
      }
      return;
    }
    _recalculate(s.astroSettings.latitude!, s.astroSettings.longitude!);
  }

  void _recalculate(double lat, double lng) {
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month}-${now.day}';

    _log.fine('_recalculate: lat=$lat lng=$lng dateKey=$dateKey');

    if (_cache != null &&
        _cache!.dateKey == dateKey &&
        _cache!.lat == lat &&
        _cache!.lng == lng) {
      _log.fine('_recalculate: cache hit');
      if (_current != _cache!.data) {
        _current = _cache!.data;
        notifyListeners();
      }
      return;
    }

    try {
      final today = getSolarTimes(now, lat, lng);
      if (today == null) {
        _log.warning('_recalculate: could not find solar events '
            '(polar day/night?) at lat=$lat lng=$lng');
        if (_current != null) {
          _current = null;
          notifyListeners();
        }
        return;
      }

      _log.fine('_recalculate: civilTwilightBegin=${today.civilTwilightBegin} '
          'sunrise=${today.sunrise} solarNoon=${today.solarNoon} '
          'sunset=${today.sunset} civilTwilightEnd=${today.civilTwilightEnd}');

      final moonIllum = SunCalc.getMoonIllumination(now);

      _log.fine('_recalculate: moonIllum=$moonIllum');

      if (_disposed) return;

      final data = AstroData(
        civilTwilightBegin: today.civilTwilightBegin,
        sunrise: today.sunrise,
        solarNoon: today.solarNoon,
        sunset: today.sunset,
        civilTwilightEnd: today.civilTwilightEnd,
        phase: MoonPhase.fromFraction((moonIllum['phase'] as num).toDouble()),
        illuminationFraction: (moonIllum['fraction'] as num).toDouble(),
      );

      _log.fine('_recalculate: AstroData built — notifying listeners');
      _cache = (dateKey: dateKey, lat: lat, lng: lng, data: data);
      _current = data;
      notifyListeners();
      _scheduleMidnightTimer();
    } catch (e, st) {
      _log.severe('_recalculate: error', e, st);
      if (_current != null) {
        _current = null;
        notifyListeners();
      }
    }
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(midnight.difference(now), () {
      _cache = null;
      _onSettingsChanged();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _settings.removeListener(_onSettingsChanged);
    _midnightTimer?.cancel();
    super.dispose();
  }
}
