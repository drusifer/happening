import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

void main() {
  const lat = 37.77;
  const lng = -122.42;

  final date = DateTime(2026, 5, 18);
  final now = DateTime(2026, 5, 18, 12, 0, 0);
  late SolarDayTimes times;
  late AstroData astro;
  late SolarBody body;

  setUp(() {
    times = getSolarTimes(date, lat, lng)!;
    astro = AstroData(
      civilTwilightBegin: times.civilTwilightBegin,
      sunrise: times.sunrise,
      solarNoon: times.solarNoon,
      sunset: times.sunset,
      civilTwilightEnd: times.civilTwilightEnd,
      phase: MoonPhase.full,
      illuminationFraction: 1.0,
    );
    body = SolarBody(astroData: astro);
  });

  group('getSolarTimes', () {
    test('returns non-null for mid-latitude location', () {
      expect(getSolarTimes(date, lat, lng), isNotNull);
    });

    test('sunrise < solarNoon < sunset', () {
      expect(times.sunrise.isBefore(times.solarNoon), isTrue);
      expect(times.solarNoon.isBefore(times.sunset), isTrue);
    });

    test('civilTwilightBegin < sunrise and sunset < civilTwilightEnd', () {
      expect(times.civilTwilightBegin.isBefore(times.sunrise), isTrue);
      expect(times.civilTwilightEnd.isAfter(times.sunset), isTrue);
    });
  });

  group('SolarBody.getArcs', () {
    test('emits five arcs for a single day inside the window', () {
      final ws = now.subtract(const Duration(hours: 12));
      final we = now.add(const Duration(hours: 12));
      final arcs = body.getArcs(ws, we);
      // Window covers exactly one day's civil-twilight band → 5 arcs.
      expect(arcs.length, 5);
    });

    test('arcs tile civilTwilightBegin → civilTwilightEnd contiguously', () {
      final arcs = body.getArcs(now.subtract(const Duration(hours: 12)),
          now.add(const Duration(hours: 12)))
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(times.civilTwilightBegin));
      expect(arcs.last.endTime, equals(times.civilTwilightEnd));
      for (var i = 0; i + 1 < arcs.length; i++) {
        expect(arcs[i].endTime, equals(arcs[i + 1].startTime));
      }
    });

    test('day arc is solid dayBlue', () {
      final arcs = body.getArcs(now.subtract(const Duration(hours: 12)),
          now.add(const Duration(hours: 12)));
      final day = arcs.firstWhere((a) => a.startTime == times.sunrise);
      expect(day.endTime, equals(times.sunset));
      expect(day.startColor, equals(SolarBody.dayBlue));
      expect(day.endColor, equals(SolarBody.dayBlue));
    });

    test('multi-day window yields one set per day', () {
      final ws = now.subtract(const Duration(hours: 36));
      final we = now.add(const Duration(hours: 36));
      final arcs = body.getArcs(ws, we);
      // Spans 3 days of civil-twilight bands → 15 arcs.
      expect(arcs.length, 15);
    });
  });

  group('SolarBody.getGlyphs', () {
    test('emits SunRise, Sun, SunSet for each visible day', () {
      final arcs = body.getGlyphs(now.subtract(const Duration(hours: 12)),
          now.add(const Duration(hours: 12)));
      expect(arcs.length, 3);
    });
  });

  group('isDaytime / nightnessAt', () {
    test('isDaytime is true at solar noon', () {
      expect(isDaytime(times.solarNoon, astro), isTrue);
    });

    test('isDaytime is false during civil twilight', () {
      final dawn = DateTime.fromMillisecondsSinceEpoch(
        (times.civilTwilightBegin.millisecondsSinceEpoch +
                times.sunrise.millisecondsSinceEpoch) ~/
            2,
      );
      expect(isDaytime(dawn, astro), isFalse);
    });

    test('nightnessAt is 0 at solar noon', () {
      expect(nightnessAt(times.solarNoon, astro), closeTo(0.0, 0.01));
    });

    test('nightnessAt is 1 well before civil twilight', () {
      expect(
          nightnessAt(
              times.civilTwilightBegin.subtract(const Duration(hours: 2)),
              astro),
          closeTo(1.0, 0.01));
    });

    test('nightnessAt is 1 well after civil twilight end', () {
      expect(
          nightnessAt(
              times.civilTwilightEnd.add(const Duration(hours: 2)), astro),
          closeTo(1.0, 0.01));
    });
  });
}
