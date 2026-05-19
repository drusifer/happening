import 'dart:async';
import 'dart:math' as math;

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/settings/settings_service.dart';

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
      // getSunPosition() is confirmed correct; getTimes() returns dates ~6700
      // years in the future due to a Julian Day Number epoch bug in the package.
      // We use binary search on getSunPosition() to find the crossing times.
      //
      // Anchor search windows to the SOLAR NADIR — the moment of minimum sun
      // altitude, which is always near local midnight regardless of UTC offset.
      // Nadir UTC hour ≈ (24 − lng/15) mod 24 (equation-of-time error < 16min,
      // well inside our 2h buffer).
      //
      // Rising events live in [nadir−2h, nadir+14h].
      // Falling events live in [nadir+10h, nadir+26h].
      // These windows are guaranteed to bracket the events for any longitude
      // without depending on the machine's local timezone.
      final nowUtc = now.toUtc();
      final midnightUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      final nadirHours = (24.0 - lng / 15.0) % 24.0;
      final nadir = midnightUtc.add(Duration(minutes: (nadirHours * 60).round()));

      final risingLo = nadir.subtract(const Duration(hours: 2));
      final risingHi = nadir.add(const Duration(hours: 14));
      final fallingLo = nadir.add(const Duration(hours: 10));
      final fallingHi = nadir.add(const Duration(hours: 26));

      _log.fine('_recalculate: nadir=$nadir risingLo=$risingLo risingHi=$risingHi '
          'fallingLo=$fallingLo fallingHi=$fallingHi');

      final civilTwilightBegin = _findSunCrossing(
        lat: lat, lng: lng,
        targetDeg: -6.0, rising: true,
        lo: risingLo, hi: risingHi,
      );
      final sunrise = _findSunCrossing(
        lat: lat, lng: lng,
        targetDeg: 0.0, rising: true,
        lo: risingLo, hi: risingHi,
      );
      final sunset = _findSunCrossing(
        lat: lat, lng: lng,
        targetDeg: 0.0, rising: false,
        lo: fallingLo, hi: fallingHi,
      );
      final civilTwilightEnd = _findSunCrossing(
        lat: lat, lng: lng,
        targetDeg: -6.0, rising: false,
        lo: fallingLo, hi: fallingHi,
      );
      // Solar noon is the midpoint between sunrise and sunset — float arithmetic
      // for precision before rounding to the nearest millisecond.
      final solarNoon = sunrise != null && sunset != null
          ? DateTime.fromMillisecondsSinceEpoch(
              ((sunrise.millisecondsSinceEpoch +
                      sunset.millisecondsSinceEpoch) /
                  2.0).round())
          : nadir.add(const Duration(hours: 12));

      _log.fine('_recalculate: civilTwilightBegin=$civilTwilightBegin '
          'sunrise=$sunrise solarNoon=$solarNoon '
          'sunset=$sunset civilTwilightEnd=$civilTwilightEnd');

      if (civilTwilightBegin == null || sunrise == null ||
          sunset == null || civilTwilightEnd == null) {
        _log.warning('_recalculate: could not find one or more solar events '
            '(polar day/night?) at lat=$lat lng=$lng');
        if (_current != null) {
          _current = null;
          notifyListeners();
        }
        return;
      }

      final moonIllum = SunCalc.getMoonIllumination(now);
      final moonTimes = SunCalc.getMoonTimes(now, lat, lng);

      // getMoonTimes() may share the same JDN epoch bug as getTimes().
      // Validate that returned dates are within a plausible range before use.
      final rawMoonrise = moonTimes['rise'];
      final rawMoonset = moonTimes['set'];
      final moonrise = rawMoonrise is DateTime && _isReasonableDate(rawMoonrise)
          ? rawMoonrise
          : null;
      final moonset = rawMoonset is DateTime && _isReasonableDate(rawMoonset)
          ? rawMoonset
          : null;

      _log.fine('_recalculate: moonrise=$moonrise moonset=$moonset '
          'moonIllum=$moonIllum');

      if (_disposed) return;

      final data = AstroData(
        civilTwilightBegin: civilTwilightBegin,
        sunrise: sunrise,
        solarNoon: solarNoon,
        sunset: sunset,
        civilTwilightEnd: civilTwilightEnd,
        moonrise: moonrise,
        moonset: moonset,
        phase: MoonPhase.fromFraction(
            (moonIllum['phase'] as num).toDouble()),
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

  /// Returns the altitude of the sun in degrees at [time] for [lat]/[lng].
  double _sunAltitudeDeg(DateTime time, double lat, double lng) {
    final pos = SunCalc.getSunPosition(time, lat, lng);
    return (pos['altitude'] as num).toDouble() * 180 / math.pi;
  }

  /// Binary search for when sun altitude crosses [targetDeg] within [lo]..[hi].
  /// [rising] = true means we want the morning crossing; false = evening.
  /// Returns null if no crossing is found in the range (polar day/night).
  DateTime? _findSunCrossing({
    required double lat,
    required double lng,
    required double targetDeg,
    required bool rising,
    required DateTime lo,
    required DateTime hi,
  }) {
    final altLo = _sunAltitudeDeg(lo, lat, lng);
    final altHi = _sunAltitudeDeg(hi, lat, lng);

    // No crossing if both endpoints are on the same side of target.
    if (rising && (altLo > targetDeg || altHi < targetDeg)) return null;
    if (!rising && (altLo < targetDeg || altHi > targetDeg)) return null;

    var start = lo;
    var end = hi;
    for (var i = 0; i < 40; i++) {
      final mid = start.add(
        Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2),
      );
      final altMid = _sunAltitudeDeg(mid, lat, lng);
      if (rising) {
        if (altMid < targetDeg) { start = mid; } else { end = mid; }
      } else {
        if (altMid > targetDeg) { start = mid; } else { end = mid; }
      }
    }
    return start.add(
      Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2),
    );
  }

/// Returns true if [d] is within a plausible real-world date range.
  bool _isReasonableDate(DateTime d) => d.year >= 1900 && d.year <= 2200;

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
