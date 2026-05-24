import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  // Fixed reference: noon UTC.
  final now = DateTime.utc(2026, 5, 18, 12, 0, 0);

  // Window: 8 hours centred on now → 08:00–16:00 UTC.
  final windowStart = now.subtract(const Duration(hours: 4));
  final windowEnd = now.add(const Duration(hours: 4));

  // Solar events within the window.
  final civilBegin = now.subtract(const Duration(hours: 3, minutes: 30));
  final sunrise = now.subtract(const Duration(hours: 3));
  final solarNoon = now;
  final sunset = now.add(const Duration(hours: 3));
  final civilEnd = now.add(const Duration(hours: 3, minutes: 30));

  final astro = AstroData(
    civilTwilightBegin: civilBegin,
    sunrise: sunrise,
    solarNoon: solarNoon,
    sunset: sunset,
    civilTwilightEnd: civilEnd,
    phase: MoonPhase.waxingGibbous,
    illuminationFraction: 0.7,
  );

  const stripWidth = 1000.0;

  late TimelineLayout layout;
  late SolarBody solarBody;

  // Helper: solar sky colour at x using the same piecewise rule as ABL.
  Color solarColorAt(double x) {
    final xCtb = layout.xForTime(civilBegin, now);
    final xRise = layout.xForTime(sunrise, now);
    final xSet = layout.xForTime(sunset, now);
    final xCte = layout.xForTime(civilEnd, now);
    if (x < xCtb) return SolarBody.nightNavy;
    if (x < xRise) return SolarBody.dawnDusk;
    if (x <= xSet) return SolarBody.dayBlue;
    if (x <= xCte) return SolarBody.dawnDusk;
    return SolarBody.nightNavy;
  }

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: stripWidth / 2,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    solarBody = SolarBody(
      times: SolarDayTimes(
        civilTwilightBegin: civilBegin,
        sunrise: sunrise,
        solarNoon: solarNoon,
        sunset: sunset,
        civilTwilightEnd: civilEnd,
      ),
    );
  });

  group('solarColorAt — night zones', () {
    test('far left of civil twilight begin is night navy', () {
      final x = layout.xForTime(civilBegin, now) - 50;
      expect(solarColorAt(x), equals(const Color(0xFF05080F)));
    });

    test('far right of civil twilight end is night navy', () {
      final x = layout.xForTime(civilEnd, now) + 50;
      expect(solarColorAt(x), equals(const Color(0xFF05080F)));
    });
  });

  group('solarColorAt — dawn/dusk zones', () {
    test('at civil twilight begin is dawn amber', () {
      final x = layout.xForTime(civilBegin, now);
      expect(solarColorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('between civil twilight begin and sunrise is dawn amber', () {
      final x = (layout.xForTime(civilBegin, now) + layout.xForTime(sunrise, now)) / 2;
      expect(solarColorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('at civil twilight end is dusk amber', () {
      final x = layout.xForTime(civilEnd, now);
      expect(solarColorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('between sunset and civil twilight end is dusk amber', () {
      final x = (layout.xForTime(sunset, now) + layout.xForTime(civilEnd, now)) / 2;
      expect(solarColorAt(x), equals(const Color(0xFFE8722A)));
    });
  });

  group('solarColorAt — daytime zone', () {
    test('at sunrise is sky blue', () {
      expect(solarColorAt(layout.xForTime(sunrise, now)), equals(const Color(0xFF5BA3C9)));
    });

    test('at solar noon is sky blue', () {
      expect(solarColorAt(layout.xForTime(solarNoon, now)), equals(const Color(0xFF5BA3C9)));
    });

    test('at sunset is sky blue', () {
      expect(solarColorAt(layout.xForTime(sunset, now)), equals(const Color(0xFF5BA3C9)));
    });
  });

  group('AstronomicalBackgroundLayer construction', () {
    test('creates without error', () {
      expect(
        () => AstronomicalBackgroundLayer(
          astroData: astro,
          layout: layout,
          now: now,
        ),
        returnsNormally,
      );
    });

    test('creates with lat/lng without error', () {
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

  group('SolarBody — gradient stops and nightness', () {
    test('gradientStops produces 7 stops for a full solar day', () {
      final stops = solarBody.gradientStops(layout, now);
      expect(stops.length, 7);
    });

    test('nightness is 0 at solar noon', () {
      final x = layout.xForTime(solarNoon, now);
      expect(solarBody.nightnessAt(x, layout, now), closeTo(0.0, 0.01));
    });

    test('nightness is 1 well before civil twilight', () {
      final x = layout.xForTime(civilBegin, now) - 50;
      expect(solarBody.nightnessAt(x, layout, now), closeTo(1.0, 0.01));
    });

    test('nightness is 1 well after civil twilight end', () {
      final x = layout.xForTime(civilEnd, now) + 50;
      expect(solarBody.nightnessAt(x, layout, now), closeTo(1.0, 0.01));
    });
  });
}
