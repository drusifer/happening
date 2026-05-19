import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/solar_marker_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  final now = DateTime.utc(2026, 5, 18, 12, 0, 0);
  final windowStart = now.subtract(const Duration(hours: 4));
  final windowEnd = now.add(const Duration(hours: 4));

  final sunrise = now.subtract(const Duration(hours: 3));
  final solarNoon = now;
  final sunset = now.add(const Duration(hours: 3));

  final astro = AstroData(
    civilTwilightBegin: now.subtract(const Duration(hours: 3, minutes: 30)),
    sunrise: sunrise,
    solarNoon: solarNoon,
    sunset: sunset,
    civilTwilightEnd: now.add(const Duration(hours: 3, minutes: 30)),
    phase: MoonPhase.full,
    illuminationFraction: 0.99,
  );

  const stripWidth = 1000.0;
  const nowIndicatorX = stripWidth / 2;

  late TimelineLayout layout;
  late SolarMarkerLayer layer;

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    layer = SolarMarkerLayer(astroData: astro, layout: layout, now: now);
  });

  group('SolarMarkerLayer x positions', () {
    test('sunrise x is left of center', () {
      final x = layout.xForTime(layer.astroData.sunrise, now);
      expect(x, lessThan(nowIndicatorX));
    });

    test('solar noon x is at center', () {
      final x = layout.xForTime(layer.astroData.solarNoon, now);
      expect(x, closeTo(nowIndicatorX, 0.1));
    });

    test('sunset x is right of center', () {
      final x = layout.xForTime(layer.astroData.sunset, now);
      expect(x, greaterThan(nowIndicatorX));
    });

    test('sunrise x is less than sunset x', () {
      final sx = layout.xForTime(layer.astroData.sunrise, now);
      final ex = layout.xForTime(layer.astroData.sunset, now);
      expect(sx, lessThan(ex));
    });
  });
}
