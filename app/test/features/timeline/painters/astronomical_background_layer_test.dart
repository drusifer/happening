import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
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
}
