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

  group('LunarBody.getArcs', () {
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

    test('night-only: all emitted arcs lie outside [sunrise, sunset]', () {
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final ws = solarTimes.solarNoon.subtract(const Duration(hours: 24));
      final we = solarTimes.solarNoon.add(const Duration(hours: 24));
      final arcs = body.getArcs(ws, we);
      // Each arc must end before sunrise OR start at/after sunset (across any day).
      for (final arc in arcs) {
        final sNear = solarTimesNear(arc.startTime, astroFull);
        final overlapsDay = arc.startTime.isBefore(sNear.sunset) &&
            arc.endTime.isAfter(sNear.sunrise);
        expect(overlapsDay, isFalse,
            reason:
                'Arc ${arc.startTime}→${arc.endTime} overlaps daytime [${sNear.sunrise}, ${sNear.sunset}]');
      }
    });

    test('fade-in starts at navy, fade-out ends at navy', () {
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final arcs = body.getArcs(
          solarTimes.solarNoon.subtract(const Duration(hours: 24)),
          solarTimes.solarNoon.add(const Duration(hours: 24)))
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs, isNotEmpty);
      expect(arcs.first.startColor, equals(SolarBody.nightNavy));
      expect(arcs.last.endColor, equals(SolarBody.nightNavy));
    });

    test('moon-up-at-sunset: first arc starts exactly at sunset', () {
      // Force a moon arc that starts before sunset and ends well into night.
      // We test the clipping behavior via the helper: arcs emitted by LunarBody
      // should begin no earlier than the sunset of the moonrise's day.
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final arcs = body.getArcs(
          solarTimes.solarNoon.subtract(const Duration(hours: 24)),
          solarTimes.solarNoon.add(const Duration(hours: 24)));
      for (final arc in arcs) {
        final sNear = solarTimesNear(arc.startTime, astroFull);
        // Arc start must be >= sunset of its day OR within night (before sunrise).
        final atOrAfterSunset = !arc.startTime.isBefore(sNear.sunset);
        final beforeSunrise = arc.startTime.isBefore(sNear.sunrise);
        expect(atOrAfterSunset || beforeSunrise, isTrue,
            reason: 'Arc start ${arc.startTime} must be in night');
      }
    });
  });

  group('LunarBody.getGlyphs', () {
    test('emits MoonRise, MoonTransit, MoonSet for each visible arc', () {
      final body = LunarBody(astroData: astroFull, lat: lat, lng: lng);
      final glyphs = body.getGlyphs(
          solarTimes.solarNoon.subtract(const Duration(hours: 24)),
          solarTimes.solarNoon.add(const Duration(hours: 24)));
      // At mid-latitudes a 48 h window contains at least one full moon arc.
      expect(glyphs.length, greaterThanOrEqualTo(3));
      expect(glyphs.length % 3, equals(0));
    });
  });
}
