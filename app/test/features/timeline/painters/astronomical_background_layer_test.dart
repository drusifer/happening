import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  // Fixed reference: noon UTC.
  final now = DateTime.utc(2026, 5, 18, 12, 0, 0);

  // Window: 8 hours centred on now → 08:00–16:00 UTC.
  final windowStart = now.subtract(const Duration(hours: 4));
  final windowEnd = now.add(const Duration(hours: 4));

  // Solar events within the window.
  final civilBegin = now.subtract(const Duration(hours: 3, minutes: 30)); // 08:30
  final sunrise = now.subtract(const Duration(hours: 3));                  // 09:00
  final solarNoon = now;                                                    // 12:00
  final sunset = now.add(const Duration(hours: 3));                        // 15:00
  final civilEnd = now.add(const Duration(hours: 3, minutes: 30));         // 15:30

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
  late AstronomicalBackgroundLayer layer;

  // Helpers for colorAtX calls.
  double xFor(DateTime t) => layout.xForTime(t, now);

  Color colorAt(double x) => layer.colorAtX(
        x,
        xCtb: xFor(civilBegin),
        xRise: xFor(sunrise),
        xSet: xFor(sunset),
        xCte: xFor(civilEnd),
      );

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: stripWidth / 2,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    layer = AstronomicalBackgroundLayer(
      astroData: astro,
      layout: layout,
      now: now,
    );
  });

  group('colorAtX — night zones', () {
    test('far left of civil twilight begin is night navy', () {
      // x well before civilBegin
      final x = xFor(civilBegin) - 50;
      expect(colorAt(x), equals(const Color(0xFF05080F)));
    });

    test('far right of civil twilight end is night navy', () {
      final x = xFor(civilEnd) + 50;
      expect(colorAt(x), equals(const Color(0xFF05080F)));
    });
  });

  group('colorAtX — dawn/dusk zones', () {
    test('at civil twilight begin is dawn amber', () {
      // exactly at xCtb: x < xRise so returns _dawnDusk
      final x = xFor(civilBegin);
      expect(colorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('between civil twilight begin and sunrise is dawn amber', () {
      final x = (xFor(civilBegin) + xFor(sunrise)) / 2;
      expect(colorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('at civil twilight end is dusk amber', () {
      final x = xFor(civilEnd);
      expect(colorAt(x), equals(const Color(0xFFE8722A)));
    });

    test('between sunset and civil twilight end is dusk amber', () {
      final x = (xFor(sunset) + xFor(civilEnd)) / 2;
      expect(colorAt(x), equals(const Color(0xFFE8722A)));
    });
  });

  group('colorAtX — daytime zone', () {
    test('at sunrise is sky blue', () {
      final x = xFor(sunrise);
      expect(colorAt(x), equals(const Color(0xFF5BA3C9)));
    });

    test('at solar noon is sky blue', () {
      final x = xFor(solarNoon);
      expect(colorAt(x), equals(const Color(0xFF5BA3C9)));
    });

    test('at sunset is sky blue', () {
      final x = xFor(sunset);
      expect(colorAt(x), equals(const Color(0xFF5BA3C9)));
    });
  });

  group('colorAtX — all events off-screen (mid-day)', () {
    // Narrow window so all twilight events are outside.
    late AstronomicalBackgroundLayer narrowLayer;

    setUp(() {
      final narrowLayout = TimelineLayout(
        stripWidth: stripWidth,
        nowIndicatorX: stripWidth / 2,
        windowStart: now.subtract(const Duration(hours: 1)),
        windowEnd: now.add(const Duration(hours: 1)),
      );
      narrowLayer = AstronomicalBackgroundLayer(
        astroData: astro,
        layout: narrowLayout,
        now: now,
      );
    });

    test('entire strip is daytime — both edges are sky blue', () {
      final xCtb = narrowLayer.layout.xForTime(civilBegin, now);
      final xRise = narrowLayer.layout.xForTime(sunrise, now);
      final xSet = narrowLayer.layout.xForTime(sunset, now);
      final xCte = narrowLayer.layout.xForTime(civilEnd, now);

      final left = narrowLayer.colorAtX(0,
          xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte);
      final right = narrowLayer.colorAtX(stripWidth,
          xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte);

      expect(left, equals(const Color(0xFF5BA3C9)));
      expect(right, equals(const Color(0xFF5BA3C9)));
    });
  });

  group('colorAtX — all events off-screen (night)', () {
    late AstronomicalBackgroundLayer nightLayer;

    setUp(() {
      // Reference time: 2 AM — all solar events many hours away.
      final nightNow = DateTime.utc(2026, 5, 18, 2, 0, 0);
      final nightLayout = TimelineLayout(
        stripWidth: stripWidth,
        nowIndicatorX: stripWidth / 2,
        windowStart: nightNow.subtract(const Duration(hours: 1)),
        windowEnd: nightNow.add(const Duration(hours: 1)),
      );
      nightLayer = AstronomicalBackgroundLayer(
        astroData: astro,
        layout: nightLayout,
        now: nightNow,
      );
    });

    test('entire strip is night — both edges are night navy', () {
      final xCtb = nightLayer.layout.xForTime(civilBegin, nightLayer.now);
      final xRise = nightLayer.layout.xForTime(sunrise, nightLayer.now);
      final xSet = nightLayer.layout.xForTime(sunset, nightLayer.now);
      final xCte = nightLayer.layout.xForTime(civilEnd, nightLayer.now);

      final left = nightLayer.colorAtX(0,
          xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte);
      final right = nightLayer.colorAtX(stripWidth,
          xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte);

      expect(left, equals(const Color(0xFF05080F)));
      expect(right, equals(const Color(0xFF05080F)));
    });
  });
}
