import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';

void main() {
  final t = DateTime(2026, 5, 18, 6, 0);
  final base = AstroData(
    civilTwilightBegin: t,
    sunrise: t.add(const Duration(minutes: 30)),
    solarNoon: t.add(const Duration(hours: 6)),
    sunset: t.add(const Duration(hours: 14)),
    civilTwilightEnd: t.add(const Duration(hours: 14, minutes: 30)),
    phase: MoonPhase.waxingGibbous,
    illuminationFraction: 0.72,
  );

  group('MoonPhase.fromFraction', () {
    test('new moon near 0', () {
      expect(MoonPhase.fromFraction(0.0), MoonPhase.newMoon);
      expect(MoonPhase.fromFraction(0.04), MoonPhase.newMoon);
    });

    test('new moon near 1', () {
      expect(MoonPhase.fromFraction(0.95), MoonPhase.newMoon);
      expect(MoonPhase.fromFraction(0.999), MoonPhase.newMoon);
    });

    test('waxing crescent', () {
      expect(MoonPhase.fromFraction(0.1), MoonPhase.waxingCrescent);
    });

    test('first quarter', () {
      expect(MoonPhase.fromFraction(0.25), MoonPhase.firstQuarter);
    });

    test('waxing gibbous', () {
      expect(MoonPhase.fromFraction(0.38), MoonPhase.waxingGibbous);
    });

    test('full moon', () {
      expect(MoonPhase.fromFraction(0.5), MoonPhase.full);
    });

    test('waning gibbous', () {
      expect(MoonPhase.fromFraction(0.62), MoonPhase.waningGibbous);
    });

    test('last quarter', () {
      expect(MoonPhase.fromFraction(0.75), MoonPhase.lastQuarter);
    });

    test('waning crescent', () {
      expect(MoonPhase.fromFraction(0.88), MoonPhase.waningCrescent);
    });
  });

  group('AstroData equality', () {
    test('equal when all fields match', () {
      final copy = AstroData(
        civilTwilightBegin: base.civilTwilightBegin,
        sunrise: base.sunrise,
        solarNoon: base.solarNoon,
        sunset: base.sunset,
        civilTwilightEnd: base.civilTwilightEnd,
        phase: base.phase,
        illuminationFraction: base.illuminationFraction,
      );
      expect(base, equals(copy));
      expect(base.hashCode, copy.hashCode);
    });

    test('not equal when sunrise differs', () {
      final other = AstroData(
        civilTwilightBegin: base.civilTwilightBegin,
        sunrise: base.sunrise.add(const Duration(minutes: 1)),
        solarNoon: base.solarNoon,
        sunset: base.sunset,
        civilTwilightEnd: base.civilTwilightEnd,
        phase: base.phase,
        illuminationFraction: base.illuminationFraction,
      );
      expect(base, isNot(equals(other)));
    });

    test('not equal when phase differs', () {
      final other = AstroData(
        civilTwilightBegin: base.civilTwilightBegin,
        sunrise: base.sunrise,
        solarNoon: base.solarNoon,
        sunset: base.sunset,
        civilTwilightEnd: base.civilTwilightEnd,
        phase: MoonPhase.full,
        illuminationFraction: base.illuminationFraction,
      );
      expect(base, isNot(equals(other)));
    });
  });

  group('AstroSettings', () {
    const s = AstroSettings(latitude: 40.71, longitude: -74.0, cityName: 'New York');

    test('hasLocation true when lat+lng present', () {
      expect(s.hasLocation, isTrue);
    });

    test('hasLocation false when lat null', () {
      expect(const AstroSettings().hasLocation, isFalse);
    });

    test('copyWith replaces fields', () {
      final updated = s.copyWith(cityName: 'Brooklyn');
      expect(updated.cityName, 'Brooklyn');
      expect(updated.latitude, 40.71);
    });

    test('copyWith can null a field', () {
      final cleared = s.copyWith(cityName: null);
      expect(cleared.cityName, isNull);
      expect(cleared.latitude, 40.71);
    });

    test('equality', () {
      const other = AstroSettings(latitude: 40.71, longitude: -74.0, cityName: 'New York');
      expect(s, equals(other));
      expect(s.hashCode, other.hashCode);
    });

    test('toJson / fromJson round-trip', () {
      final json = s.toJson();
      final restored = AstroSettings.fromJson(json);
      expect(restored, equals(s));
    });

    test('fromJson handles missing fields gracefully', () {
      final empty = AstroSettings.fromJson({});
      expect(empty.hasLocation, isFalse);
      expect(empty.cityName, isNull);
    });
  });
}
