// Smoke tests for LunarBody using real lat/lng moon calculations.
// See lunar_body_scenarios_test.dart for the night-arc logic matrix.

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

void main() {
  const lat = 37.77;
  const lng = -122.42;

  final date = DateTime(2026, 5, 18);
  late SolarDayTimes solarTimes;
  late AstroData astroFull;

  setUp(() {
    solarTimes = getSolarTimes(date, lat, lng)!;
    astroFull = AstroData(
      civilTwilightBegin: solarTimes.civilTwilightBegin,
      sunrise: solarTimes.sunrise,
      solarNoon: solarTimes.solarNoon,
      sunset: solarTimes.sunset,
      civilTwilightEnd: solarTimes.civilTwilightEnd,
      phase: MoonPhase.full,
      illuminationFraction: 1.0,
    );
  });

  group('getLunarTimes', () {
    test('always returns a value', () {
      expect(getLunarTimes(date, lat, lng), isNotNull);
    });

    test('phase is a valid MoonPhase', () {
      final lunar = getLunarTimes(date, lat, lng);
      expect(MoonPhase.values.contains(lunar.phase), isTrue);
    });

    test('illuminationFraction is in [0, 1]', () {
      final lunar = getLunarTimes(date, lat, lng);
      expect(lunar.illuminationFraction, inInclusiveRange(0.0, 1.0));
    });
  });

  group('LunarBody.getArcs (real lat/lng smoke)', () {
    test('returns empty when illumination is zero', () {
      final dark = AstroData(
        civilTwilightBegin: astroFull.civilTwilightBegin,
        sunrise: astroFull.sunrise,
        solarNoon: astroFull.solarNoon,
        sunset: astroFull.sunset,
        civilTwilightEnd: astroFull.civilTwilightEnd,
        phase: MoonPhase.newMoon,
        illuminationFraction: 0.0,
      );
      final body = LunarBody(astroData: dark, lat: lat, lng: lng);
      expect(
          body.getArcs(solarTimes.solarNoon.subtract(const Duration(hours: 12)),
              solarTimes.solarNoon.add(const Duration(hours: 12))),
          isEmpty);
    });

    test(
        'output is independent of AstroData\'s solar fields (regression '
        'guard for the old day-anchoring bug class)', () {
      // Same illumination/phase/lat/lng/date, wildly different solar
      // schedule. LunarBody no longer reads civilTwilightBegin/sunrise/
      // solarNoon/sunset/civilTwilightEnd at all -- moonrise/moonset come
      // from getLunarTimes(date, lat, lng), independent of AstroData's solar
      // fields, so the arcs must be identical regardless.
      final shiftedSolar = AstroData(
        civilTwilightBegin: astroFull.civilTwilightBegin
            .add(const Duration(hours: 3, minutes: 17)),
        sunrise: astroFull.sunrise.add(const Duration(hours: 3, minutes: 17)),
        solarNoon:
            astroFull.solarNoon.add(const Duration(hours: 3, minutes: 17)),
        sunset: astroFull.sunset.add(const Duration(hours: 3, minutes: 17)),
        civilTwilightEnd: astroFull.civilTwilightEnd
            .add(const Duration(hours: 3, minutes: 17)),
        phase: astroFull.phase,
        illuminationFraction: astroFull.illuminationFraction,
      );
      final ws = solarTimes.solarNoon.subtract(const Duration(hours: 24));
      final we = solarTimes.solarNoon.add(const Duration(hours: 24));
      final a = LunarBody(astroData: astroFull, lat: lat, lng: lng)
          .getArcs(ws, we);
      final b = LunarBody(astroData: shiftedSolar, lat: lat, lng: lng)
          .getArcs(ws, we);
      expect(a, equals(b));
    });

    test('first/last colors are navy or amber (never dayBlue)', () {
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final arcs = body.getArcs(
          solarTimes.solarNoon.subtract(const Duration(hours: 24)),
          solarTimes.solarNoon.add(const Duration(hours: 24)))
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs, isNotEmpty);
      final boundaryColors = {SolarBody.nightNavy, SolarBody.dawnDusk};
      expect(boundaryColors.contains(arcs.first.startColor), isTrue,
          reason:
              'lead-in must start at navy or amber, got ${arcs.first.startColor}');
      expect(boundaryColors.contains(arcs.last.endColor), isTrue,
          reason:
              'lead-out must end at navy or amber, got ${arcs.last.endColor}');
    });
  });

  group('LunarBody.getGlyphs', () {
    test('emits MoonRise, MoonTransit, MoonSet per arc', () {
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final glyphs = body.getGlyphs(
          solarTimes.solarNoon.subtract(const Duration(hours: 24)),
          solarTimes.solarNoon.add(const Duration(hours: 24)));
      expect(glyphs.length, greaterThanOrEqualTo(3));
      expect(glyphs.length % 3, equals(0));
    });
  });
}
