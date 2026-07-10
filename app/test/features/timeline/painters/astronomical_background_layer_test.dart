import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  final now = DateTime.utc(2026, 5, 18, 12, 0, 0);
  final windowStart = now.subtract(const Duration(hours: 4));
  final windowEnd = now.add(const Duration(hours: 4));

  final astro = AstroData(
    civilTwilightBegin: now.subtract(const Duration(hours: 3, minutes: 30)),
    sunrise: now.subtract(const Duration(hours: 3)),
    solarNoon: now,
    sunset: now.add(const Duration(hours: 3)),
    civilTwilightEnd: now.add(const Duration(hours: 3, minutes: 30)),
    phase: MoonPhase.waxingGibbous,
    illuminationFraction: 0.7,
  );

  const stripWidth = 1000.0;

  late TimelineLayout layout;

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: stripWidth / 2,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  });

  group('AstronomicalBackgroundLayer construction', () {
    test('creates without lat/lng', () {
      expect(
        () => AstronomicalBackgroundLayer(
          astroData: astro,
          layout: layout,
          now: now,
        ),
        returnsNormally,
      );
    });

    test('creates with lat/lng', () {
      expect(
        () => AstronomicalBackgroundLayer(
          astroData: astro,
          layout: layout,
          now: now,
          lat: 37.77,
          lng: -122.42,
        ),
        returnsNormally,
      );
    });
  });

  group('day/night helpers', () {
    test('isDaytime is true at solar noon', () {
      expect(isDaytime(now, astro), isTrue);
    });

    test('isDaytime is false during civil twilight', () {
      expect(
          isDaytime(now.subtract(const Duration(hours: 3, minutes: 15)), astro),
          isFalse);
    });

    test('isDaytime is false at midnight', () {
      expect(isDaytime(now.add(const Duration(hours: 12)), astro), isFalse);
    });

    test('nightnessAt is 0 at solar noon', () {
      expect(nightnessAt(now, astro), closeTo(0.0, 0.01));
    });

    test('nightnessAt is 1 deep at night', () {
      expect(nightnessAt(now.add(const Duration(hours: 12)), astro),
          closeTo(1.0, 0.01));
    });
  });

  // Colours reaching a sample point via a merged (already-interpolated) arc
  // vs. directly from a source arc are mathematically equal but can differ
  // by a floating-point ULP after two chained Color.lerp calls -- compare
  // with a tolerance rather than exact equality.
  Matcher approximatelyColor(Color expected) => predicate<Color>((actual) {
        const eps = 1e-6;
        return (actual.r - expected.r).abs() < eps &&
            (actual.g - expected.g).abs() < eps &&
            (actual.b - expected.b).abs() < eps &&
            (actual.a - expected.a).abs() < eps;
      }, 'is approximately $expected');

  group('mergeByBrightness — palette invariant', () {
    test('dayBlue is always brighter than any lunar color', () {
      expect(SolarBody.dayBlue.computeLuminance(),
          greaterThan(LunarBody.upColorFor(1.0).computeLuminance()));
    });

    test('dawnDusk is always brighter than any lunar color', () {
      expect(SolarBody.dawnDusk.computeLuminance(),
          greaterThan(LunarBody.upColorFor(1.0).computeLuminance()));
    });
  });

  group('mergeByBrightness — compositing behaviour', () {
    // A day fixture with sunrise/sunset ±3h of `now`, matching the file-level
    // `astro` fixture above.
    final up = LunarBody.upColorFor(1.0);

    Color? colorAt(DateTime t, List<Arc> arcs) {
      for (final a in arcs) {
        if (!t.isBefore(a.startTime) && !t.isAfter(a.endTime)) {
          final span = a.endTime.difference(a.startTime).inMicroseconds;
          if (span <= 0) return a.startColor;
          final frac = t.difference(a.startTime).inMicroseconds / span;
          return Color.lerp(a.startColor, a.endColor, frac.clamp(0.0, 1.0));
        }
      }
      return null;
    }

    test('pure daytime with the moon also up: solar wins outright', () {
      final solarArcs = SolarBody(astroData: astro).getArcs(
          windowStart.subtract(const Duration(days: 1)),
          windowEnd.add(const Duration(days: 1)));
      // Moon up across the entire solar day, including all of daylight.
      final lunarArcs = LunarBody.moonUpArcs(
        moonrise: astro.civilTwilightBegin.subtract(const Duration(hours: 2)),
        moonset: astro.civilTwilightEnd.add(const Duration(hours: 2)),
        upColor: up,
      );
      final merged =
          AstronomicalBackgroundLayer.mergeByBrightness(solarArcs, lunarArcs);
      for (final t in [
        astro.sunrise.add(const Duration(minutes: 1)),
        astro.solarNoon,
        astro.sunset.subtract(const Duration(minutes: 1)),
      ]) {
        expect(colorAt(t, merged), approximatelyColor(SolarBody.dayBlue),
            reason: 'daytime at $t must show solar dayBlue, not lunar glow');
      }
    });

    test('pure night with the moon up: lunar glow wins over flat night navy',
        () {
      final solarArcs = SolarBody(astroData: astro).getArcs(
          windowStart.subtract(const Duration(days: 1)),
          windowEnd.add(const Duration(days: 1)));
      // Moon up well inside deep night, away from any twilight ramp.
      final rise = astro.civilTwilightEnd.add(const Duration(hours: 1));
      final set = rise.add(const Duration(hours: 2));
      final lunarArcs =
          LunarBody.moonUpArcs(moonrise: rise, moonset: set, upColor: up);
      final merged =
          AstronomicalBackgroundLayer.mergeByBrightness(solarArcs, lunarArcs);
      final midNight = rise.add(const Duration(hours: 1));
      expect(colorAt(midNight, merged), equals(up));
    });

    test(
        'twilight with the moon rising concurrently: brighter body wins '
        'pointwise, no discontinuity', () {
      final solarArcs = SolarBody(astroData: astro).getArcs(
          windowStart.subtract(const Duration(days: 1)),
          windowEnd.add(const Duration(days: 1)));
      // Moon rises right at sunset, so its fade-in overlaps solar's dusk ramp.
      final rise = astro.sunset;
      final set = rise.add(const Duration(hours: 6));
      final lunarArcs =
          LunarBody.moonUpArcs(moonrise: rise, moonset: set, upColor: up);
      final merged =
          AstronomicalBackgroundLayer.mergeByBrightness(solarArcs, lunarArcs);
      for (var m = 0; m <= 60; m += 5) {
        final t = rise.add(Duration(minutes: m));
        final solarC = colorAt(t, solarArcs);
        final lunarC = colorAt(t, lunarArcs);
        final expected = (lunarC == null ||
                (solarC != null &&
                    solarC.computeLuminance() >= lunarC.computeLuminance()))
            ? solarC
            : lunarC;
        expect(colorAt(t, merged), approximatelyColor(expected!),
            reason: 'at $t');
      }
    });

    test(
        'reported bug: moonrise before dawn, moonset after solar noon never '
        'paints lunar color inside real daytime', () {
      final solarArcs = SolarBody(astroData: astro).getArcs(
          windowStart.subtract(const Duration(days: 1)),
          windowEnd.add(const Duration(days: 1)));
      // Moonrise well before dawn, moonset well after solar noon -- the
      // exact shape that broke the old duskMid/dawnMid day-anchoring.
      final rise = astro.civilTwilightBegin.subtract(const Duration(hours: 4));
      final set = astro.solarNoon.add(const Duration(hours: 2));
      final lunarArcs =
          LunarBody.moonUpArcs(moonrise: rise, moonset: set, upColor: up);
      final merged =
          AstronomicalBackgroundLayer.mergeByBrightness(solarArcs, lunarArcs);
      var t = astro.sunrise;
      while (t.isBefore(astro.sunset)) {
        expect(colorAt(t, merged), approximatelyColor(SolarBody.dayBlue),
            reason: 'daytime at $t must never show lunar color');
        t = t.add(const Duration(minutes: 10));
      }
    });

    test(
        'multi-date sweep at a real location: lunar color never appears '
        'inside real daytime, for any date', () {
      const lat = 37.77;
      const lng = -122.42;
      for (var day = 0; day < 365; day += 5) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        final times = getSolarTimes(date, lat, lng);
        if (times == null) continue; // polar edge case, skip
        final lunar = getLunarTimes(date, lat, lng);
        if (lunar.illuminationFraction <= 0) continue;
        final dayAstro = AstroData(
          civilTwilightBegin: times.civilTwilightBegin,
          sunrise: times.sunrise,
          solarNoon: times.solarNoon,
          sunset: times.sunset,
          civilTwilightEnd: times.civilTwilightEnd,
          phase: lunar.phase,
          illuminationFraction: lunar.illuminationFraction,
        );
        final solarArcs = SolarBody(astroData: dayAstro).getArcs(
            times.civilTwilightBegin.subtract(const Duration(days: 1)),
            times.civilTwilightEnd.add(const Duration(days: 1)));
        final lunarBody = LunarBody(astroData: dayAstro, lat: lat, lng: lng);
        final lunarArcs = lunarBody.getArcs(
            times.civilTwilightBegin.subtract(const Duration(days: 1)),
            times.civilTwilightEnd.add(const Duration(days: 1)));
        final merged =
            AstronomicalBackgroundLayer.mergeByBrightness(solarArcs, lunarArcs);
        var t = times.sunrise;
        while (t.isBefore(times.sunset)) {
          expect(colorAt(t, merged), approximatelyColor(SolarBody.dayBlue),
              reason: 'date $date, time $t: daytime must never show lunar '
                  'color');
          t = t.add(const Duration(minutes: 30));
        }
      }
    });
  });
}
