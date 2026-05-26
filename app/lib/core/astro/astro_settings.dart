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
