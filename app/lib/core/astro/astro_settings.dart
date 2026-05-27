// Value objects and models for astronomical configurations and states.
//
// TLDR:
// Overview: Represents user location settings (lat, lng, city) and high-precision computed astronomical data.
// Problem:  Need structured, immutable models for storing geocoding state and plotting celestial positions.
// Solution: Declares AstroSettings (json storage), AstroData (calculated markers), and MoonPhase enum mapping.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  full,
  waningGibbous,
  lastQuarter,
  waningCrescent;

  // phase is 0.0–1.0 from getMoonIllumination(); 0 and 1 are new moon, 0.5 is full.
  static MoonPhase fromFraction(double phase) {
    if (phase < 0.0625 || phase >= 0.9375) return MoonPhase.newMoon;
    if (phase < 0.1875) return MoonPhase.waxingCrescent;
    if (phase < 0.3125) return MoonPhase.firstQuarter;
    if (phase < 0.4375) return MoonPhase.waxingGibbous;
    if (phase < 0.5625) return MoonPhase.full;
    if (phase < 0.6875) return MoonPhase.waningGibbous;
    if (phase < 0.8125) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }
}

@immutable
class AstroData {
  final DateTime civilTwilightBegin;
  final DateTime sunrise;
  final DateTime solarNoon;
  final DateTime sunset;
  final DateTime civilTwilightEnd;
  final MoonPhase phase;
  final double illuminationFraction;

  const AstroData({
    required this.civilTwilightBegin,
    required this.sunrise,
    required this.solarNoon,
    required this.sunset,
    required this.civilTwilightEnd,
    required this.phase,
    required this.illuminationFraction,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AstroData &&
          civilTwilightBegin == other.civilTwilightBegin &&
          sunrise == other.sunrise &&
          solarNoon == other.solarNoon &&
          sunset == other.sunset &&
          civilTwilightEnd == other.civilTwilightEnd &&
          phase == other.phase &&
          illuminationFraction == other.illuminationFraction;

  @override
  int get hashCode => Object.hash(
        civilTwilightBegin,
        sunrise,
        solarNoon,
        sunset,
        civilTwilightEnd,
        phase,
        illuminationFraction,
      );
}

/// Returns solar event times for the calendar day nearest to [t], by shifting
/// [astroData]'s reference day by an integer number of 24 h intervals.
///
/// Sun/moon times shift by a few minutes per day; the ±12 h snap is accurate
/// enough for background-paint purposes across the visible window.
({
  DateTime civilTwilightBegin,
  DateTime sunrise,
  DateTime solarNoon,
  DateTime sunset,
  DateTime civilTwilightEnd,
}) solarTimesNear(DateTime t, AstroData astroData) {
  final hoursFromNoon = t.difference(astroData.solarNoon).inMinutes / 60.0;
  final dayOffset = (hoursFromNoon / 24.0).round();
  final shift = Duration(hours: 24 * dayOffset);
  return (
    civilTwilightBegin: astroData.civilTwilightBegin.add(shift),
    sunrise: astroData.sunrise.add(shift),
    solarNoon: astroData.solarNoon.add(shift),
    sunset: astroData.sunset.add(shift),
    civilTwilightEnd: astroData.civilTwilightEnd.add(shift),
  );
}

/// True if [t] is between sunrise and sunset for the nearest day in
/// [astroData]. Sharp boundary — twilight is NOT daytime.
bool isDaytime(DateTime t, AstroData astroData) {
  final s = solarTimesNear(t, astroData);
  return !t.isBefore(s.sunrise) && t.isBefore(s.sunset);
}

/// Star-painting nightness at [t]: 0.0 = full day, 1.0 = full night. Smooth
/// ramp across civil twilight on either side of the day.
double nightnessAt(DateTime t, AstroData astroData) {
  final s = solarTimesNear(t, astroData);
  if (t.isBefore(s.civilTwilightBegin)) return 1.0;
  if (t.isBefore(s.sunrise)) {
    final span = s.sunrise.difference(s.civilTwilightBegin).inMicroseconds;
    if (span <= 0) return 0.0;
    return 1.0 -
        t.difference(s.civilTwilightBegin).inMicroseconds / span;
  }
  if (t.isBefore(s.sunset)) return 0.0;
  if (t.isBefore(s.civilTwilightEnd)) {
    final span = s.civilTwilightEnd.difference(s.sunset).inMicroseconds;
    if (span <= 0) return 1.0;
    return t.difference(s.sunset).inMicroseconds / span;
  }
  return 1.0;
}

@immutable
class AstroSettings {
  final double? latitude;
  final double? longitude;
  final String? cityName;

  const AstroSettings({this.latitude, this.longitude, this.cityName});

  bool get hasLocation => latitude != null && longitude != null;

  AstroSettings copyWith({
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? cityName = _sentinel,
  }) =>
      AstroSettings(
        latitude: latitude == _sentinel ? this.latitude : latitude as double?,
        longitude:
            longitude == _sentinel ? this.longitude : longitude as double?,
        cityName: cityName == _sentinel ? this.cityName : cityName as String?,
      );

  Map<String, dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (cityName != null) 'cityName': cityName,
      };

  factory AstroSettings.fromJson(Map<String, dynamic> json) => AstroSettings(
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        cityName: json['cityName'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AstroSettings &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          cityName == other.cityName;

  @override
  int get hashCode => Object.hash(latitude, longitude, cityName);
}
// Sentinel for copyWith nullable fields.

const _sentinel = Object();
