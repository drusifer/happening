// Precise offline algorithms for solar and lunar times.
//
// TLDR:
// Overview: Implements offline formulas to find exact sunrise, sunset, solar noon, moonrise, and moonset crossings.
// Problem:  Need accurate twilight boundaries and moon elevation crossings without querying external web APIs.
// Solution: Uses binary search crossing algorithms on top of the apsl_sun_calc package positions.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:flutter/foundation.dart';
import 'package:happening/core/astro/astro_settings.dart';

/// Solar event times for a single calendar day at a given location.
@immutable
class SolarDayTimes {
  final DateTime civilTwilightBegin;
  final DateTime sunrise;
  final DateTime solarNoon;
  final DateTime sunset;
  final DateTime civilTwilightEnd;

  const SolarDayTimes({
    required this.civilTwilightBegin,
    required this.sunrise,
    required this.solarNoon,
    required this.sunset,
    required this.civilTwilightEnd,
  });
}

/// Returns solar event times for the calendar [date] (local) at [lat]/[lng].
/// Returns null if polar conditions prevent one or more crossings.
SolarDayTimes? getSolarTimes(DateTime date, double lat, double lng) {
  // Anchor to the solar nadir — the moment of minimum sun altitude near local
  // midnight. Nadir UTC hour ≈ (24 − lng/15) mod 24; equation-of-time error
  // is < 16 min, well inside the 2 h search buffer.
  final midnightUtc = DateTime.utc(date.year, date.month, date.day);
  final nadirHours = (24.0 - lng / 15.0) % 24.0;
  final nadir = midnightUtc.add(Duration(minutes: (nadirHours * 60).round()));

  final risingLo = nadir.subtract(const Duration(hours: 2));
  final risingHi = nadir.add(const Duration(hours: 14));
  final fallingLo = nadir.add(const Duration(hours: 10));
  final fallingHi = nadir.add(const Duration(hours: 26));

  final civilTwilightBegin = _findSunCrossing(
    lat: lat,
    lng: lng,
    targetDeg: -6.0,
    rising: true,
    lo: risingLo,
    hi: risingHi,
  );
  final sunrise = _findSunCrossing(
    lat: lat,
    lng: lng,
    targetDeg: 0.0,
    rising: true,
    lo: risingLo,
    hi: risingHi,
  );
  final sunset = _findSunCrossing(
    lat: lat,
    lng: lng,
    targetDeg: 0.0,
    rising: false,
    lo: fallingLo,
    hi: fallingHi,
  );
  final civilTwilightEnd = _findSunCrossing(
    lat: lat,
    lng: lng,
    targetDeg: -6.0,
    rising: false,
    lo: fallingLo,
    hi: fallingHi,
  );

  if (civilTwilightBegin == null ||
      sunrise == null ||
      sunset == null ||
      civilTwilightEnd == null) {
    return null;
  }

  final solarNoon = DateTime.fromMillisecondsSinceEpoch(
    ((sunrise.millisecondsSinceEpoch + sunset.millisecondsSinceEpoch) / 2.0)
        .round(),
  );

  return SolarDayTimes(
    civilTwilightBegin: civilTwilightBegin,
    sunrise: sunrise,
    solarNoon: solarNoon,
    sunset: sunset,
    civilTwilightEnd: civilTwilightEnd,
  );
}

double _sunAltitudeDeg(DateTime time, double lat, double lng) {
  final pos = SunCalc.getSunPosition(time, lat, lng);
  return (pos['altitude'] as num).toDouble() * 180 / math.pi;
}

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
      if (altMid < targetDeg) {
        start = mid;
      } else {
        end = mid;
      }
    } else {
      if (altMid > targetDeg) {
        start = mid;
      } else {
        end = mid;
      }
    }
  }
  return start.add(
    Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2),
  );
}

// ---------------------------------------------------------------------------
// Lunar
// ---------------------------------------------------------------------------

/// Lunar event times and phase for a single calendar day at a given location.
@immutable
class LunarDayTimes {
  final DateTime? moonrise;
  final DateTime? moonset;
  final MoonPhase phase;
  final double illuminationFraction;

  const LunarDayTimes({
    this.moonrise,
    this.moonset,
    required this.phase,
    required this.illuminationFraction,
  });
}

/// Returns lunar event times and phase for the calendar [date] (local) at
/// [lat]/[lng]. Always returns a value; moonrise/moonset may be null on days
/// where the moon does not rise or set.
LunarDayTimes getLunarTimes(DateTime date, double lat, double lng) {
  final moonTimes = SunCalc.getMoonTimes(date, lat, lng);
  final moonIllum = SunCalc.getMoonIllumination(date);

  // getMoonTimes() shares a JDN epoch bug: validate dates before use.
  final rawRise = moonTimes['rise'];
  final rawSet = moonTimes['set'];
  final moonrise =
      rawRise is DateTime && _isReasonableDate(rawRise) ? rawRise : null;
  final moonset =
      rawSet is DateTime && _isReasonableDate(rawSet) ? rawSet : null;

  return LunarDayTimes(
    moonrise: moonrise,
    moonset: moonset,
    phase: MoonPhase.fromFraction((moonIllum['phase'] as num).toDouble()),
    illuminationFraction: (moonIllum['fraction'] as num).toDouble(),
  );
}

bool _isReasonableDate(DateTime d) => d.year >= 1900 && d.year <= 2200;
