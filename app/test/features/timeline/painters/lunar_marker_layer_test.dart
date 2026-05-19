import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/lunar_marker_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  final now = DateTime.utc(2026, 5, 18, 12, 0, 0);
  final windowStart = now.subtract(const Duration(hours: 4));
  final windowEnd = now.add(const Duration(hours: 4));

  const stripWidth = 1000.0;
  const nowIndicatorX = stripWidth / 2;

  late TimelineLayout layout;

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
  });

  group('LunarMarkerLayer x positions', () {
    test('moonrise x is within window when in-window', () {
      final moonrise = now.subtract(const Duration(hours: 1));
      final astro = AstroData(
        civilTwilightBegin: now.subtract(const Duration(hours: 3, minutes: 30)),
        sunrise: now.subtract(const Duration(hours: 3)),
        solarNoon: now,
        sunset: now.add(const Duration(hours: 3)),
        civilTwilightEnd: now.add(const Duration(hours: 3, minutes: 30)),
        moonrise: moonrise,
        phase: MoonPhase.firstQuarter,
        illuminationFraction: 0.5,
      );
      final layer = LunarMarkerLayer(astroData: astro, layout: layout, now: now);
      final x = layout.xForTime(layer.astroData.moonrise!, now);
      expect(x, greaterThanOrEqualTo(0));
      expect(x, lessThanOrEqualTo(stripWidth));
    });

    test('moonrise is null when not rising today', () {
      final astro = AstroData(
        civilTwilightBegin: now.subtract(const Duration(hours: 3, minutes: 30)),
        sunrise: now.subtract(const Duration(hours: 3)),
        solarNoon: now,
        sunset: now.add(const Duration(hours: 3)),
        civilTwilightEnd: now.add(const Duration(hours: 3, minutes: 30)),
        phase: MoonPhase.newMoon,
        illuminationFraction: 0.02,
      );
      final layer = LunarMarkerLayer(astroData: astro, layout: layout, now: now);
      expect(layer.astroData.moonrise, isNull);
    });

    test('moonrise is before moonset when both present', () {
      final moonrise = now.subtract(const Duration(hours: 2));
      final moonset = now.add(const Duration(hours: 2));
      final astro = AstroData(
        civilTwilightBegin: now.subtract(const Duration(hours: 3, minutes: 30)),
        sunrise: now.subtract(const Duration(hours: 3)),
        solarNoon: now,
        sunset: now.add(const Duration(hours: 3)),
        civilTwilightEnd: now.add(const Duration(hours: 3, minutes: 30)),
        moonrise: moonrise,
        moonset: moonset,
        phase: MoonPhase.waningGibbous,
        illuminationFraction: 0.8,
      );
      final riseX = layout.xForTime(astro.moonrise!, now);
      final setX = layout.xForTime(astro.moonset!, now);
      expect(riseX, lessThan(setX));
    });
  });
}
