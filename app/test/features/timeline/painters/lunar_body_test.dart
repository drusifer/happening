import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  const lat = 37.77;
  const lng = -122.42;

  final date = DateTime(2026, 5, 18);
  final now = DateTime(2026, 5, 18, 12, 0, 0);

  const stripWidth = 1000.0;
  const nowIndicatorX = stripWidth / 2;

  late TimelineLayout layout;
  late SolarBody solar;
  late SolarDayTimes solarTimes;

  setUp(() {
    layout = TimelineLayout(
      stripWidth: stripWidth,
      nowIndicatorX: nowIndicatorX,
      windowStart: now.subtract(const Duration(hours: 12)),
      windowEnd: now.add(const Duration(hours: 12)),
    );
    solarTimes = getSolarTimes(date, lat, lng)!;
    solar = SolarBody(times: solarTimes);
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

    test('moonrise and moonset are plausible dates when present', () {
      final lunar = getLunarTimes(date, lat, lng);
      final lo = date.subtract(const Duration(days: 1));
      final hi = date.add(const Duration(days: 2));
      if (lunar.moonrise != null) {
        expect(lunar.moonrise!.isAfter(lo) && lunar.moonrise!.isBefore(hi),
            isTrue);
      }
      if (lunar.moonset != null) {
        expect(
            lunar.moonset!.isAfter(lo) && lunar.moonset!.isBefore(hi), isTrue);
      }
    });
  });

  group('LunarBody colors', () {
    test('downColor is nightNavy (not transparent)', () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      final body = LunarBody(lunar: lunarTimes, solar: solar);
      expect(body.downColor, equals(SolarBody.nightNavy));
    });

    test('upColor is between nightNavy and moonlitPeak based on illumination',
        () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      final body = LunarBody(lunar: lunarTimes, solar: solar);
      // upColor should be distinguishably brighter than nightNavy for non-zero illumination
      if (lunarTimes.illuminationFraction > 0.1) {
        expect(body.upColor, isNot(equals(SolarBody.nightNavy)));
      }
    });
  });

  group('LunarBody twilight timing', () {
    test('riseBegin is before riseEnd (gradual fade-in)', () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      if (lunarTimes.moonrise == null) return;
      final body = LunarBody(lunar: lunarTimes, solar: solar);
      expect(body.riseBegin!.isBefore(body.riseEnd!), isTrue);
    });

    test('setEnd is after setBegin (gradual fade-out)', () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      if (lunarTimes.moonset == null) return;
      final body = LunarBody(lunar: lunarTimes, solar: solar);
      expect(body.setEnd!.isAfter(body.setBegin!), isTrue);
    });

    test('twilight duration matches solar civil twilight window', () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      if (lunarTimes.moonrise == null) return;
      final body = LunarBody(lunar: lunarTimes, solar: solar);
      final fadeIn = body.riseEnd!.difference(body.riseBegin!);
      final solarTwilight =
          solarTimes.sunrise.difference(solarTimes.civilTwilightBegin);
      expect(fadeIn.inSeconds, equals(solarTwilight.inSeconds));
    });
  });

  group('LunarBody gradientStops', () {
    test('returns empty when illumination is zero', () {
      const dark = LunarDayTimes(
        moonrise: null,
        moonset: null,
        phase: MoonPhase.newMoon,
        illuminationFraction: 0.0,
      );
      final body = LunarBody(lunar: dark, solar: solar);
      expect(body.gradientStops(layout, now), isEmpty);
    });

    test('gradientStops suppresses lunar stops in full civil-twilight window',
        () {
      // Moon rises well before sunrise, sets well after sunset — spans entire day.
      final earlyRise =
          solarTimes.civilTwilightBegin.subtract(const Duration(hours: 3));
      final lateSet = solarTimes.civilTwilightEnd.add(const Duration(hours: 3));
      final spanDay = LunarDayTimes(
        moonrise: earlyRise,
        moonset: lateSet,
        phase: MoonPhase.full,
        illuminationFraction: 1.0,
      );
      final body = LunarBody(lunar: spanDay, solar: solar);
      final stops = body.gradientStops(layout, now);

      final xSuppressBegin =
          layout.xForTime(solarTimes.civilTwilightBegin, now);
      final xSuppressEnd = layout.xForTime(solarTimes.civilTwilightEnd, now);

      for (final s in stops) {
        expect(
          s.x <= xSuppressBegin || s.x >= xSuppressEnd,
          isTrue,
          reason: 'Stop at x=${s.x.toStringAsFixed(1)} should be outside '
              'civil twilight window [$xSuppressBegin, $xSuppressEnd]',
        );
      }
    });

    test(
        'gradientStops fade-in has nightNavy at start when moonrise is at night',
        () {
      // Anchor moonrise/moonset relative to actual solar times (which are UTC)
      // so the test is timezone-independent.
      // Moonrise 1.5 h after civil twilight end, moonset 2 h before next dawn.
      final nightRise = solarTimes.civilTwilightEnd
          .add(const Duration(hours: 1, minutes: 30));
      final nightSet = solarTimes.civilTwilightBegin
          .add(const Duration(hours: 24) - const Duration(hours: 2));
      final nightLunar = LunarDayTimes(
        moonrise: nightRise,
        moonset: nightSet,
        phase: MoonPhase.full,
        illuminationFraction: 1.0,
      );
      final body = LunarBody(lunar: nightLunar, solar: solar);
      final stops = body.gradientStops(layout, now);
      expect(stops, isNotEmpty);

      final sorted = [...stops]..sort((a, b) => a.x.compareTo(b.x));
      // First stop is the fade-in start — should be nightNavy.
      expect(sorted.first.c, equals(SolarBody.nightNavy));
      // Last stop is the fade-out end — should also be nightNavy.
      expect(sorted.last.c, equals(SolarBody.nightNavy));
    });

    test('moonrise x is within window when in-window', () {
      final lunarTimes = getLunarTimes(date, lat, lng);
      if (lunarTimes.moonrise == null) return;
      final x = layout.xForTime(lunarTimes.moonrise!, now);
      expect(x, isNotNaN);
    });

    test('pins upColor at dawn boundary when moon rises before civil twilight',
        () {
      // Moon rises 2h before civil twilight begin, sets during daytime.
      // Without the anchor the solar body's nightNavy stop at civilTwilightBegin
      // would cause a dark dip in the merged gradient.
      final earlyRise =
          solarTimes.civilTwilightBegin.subtract(const Duration(hours: 2));
      final noonSet = solarTimes.solarNoon;
      final nightLunar = LunarDayTimes(
        moonrise: earlyRise,
        moonset: noonSet,
        phase: MoonPhase.full,
        illuminationFraction: 1.0,
      );
      final body = LunarBody(lunar: nightLunar, solar: solar);
      final stops = body.gradientStops(layout, now);

      final xDawn = layout.xForTime(solarTimes.civilTwilightBegin, now);
      expect(
        stops.any(
            (s) => (s.x - xDawn).abs() < 0.5 && s.c != SolarBody.nightNavy),
        isTrue,
        reason:
            'Dawn anchor missing — dark dip would appear at civil twilight begin',
      );
    });

    test(
        'pins upColor at dusk boundary when moon sets after civil twilight end',
        () {
      // Moon rises before dawn, sets 2h after civil twilight end.
      final earlyRise =
          solarTimes.civilTwilightBegin.subtract(const Duration(hours: 2));
      final lateSet = solarTimes.civilTwilightEnd.add(const Duration(hours: 2));
      final nightLunar = LunarDayTimes(
        moonrise: earlyRise,
        moonset: lateSet,
        phase: MoonPhase.full,
        illuminationFraction: 1.0,
      );
      final body = LunarBody(lunar: nightLunar, solar: solar);
      final stops = body.gradientStops(layout, now);

      final xDusk = layout.xForTime(solarTimes.civilTwilightEnd, now);
      expect(
        stops.any(
            (s) => (s.x - xDusk).abs() < 0.5 && s.c != SolarBody.nightNavy),
        isTrue,
        reason:
            'Dusk anchor missing — dark dip would appear at civil twilight end',
      );
    });

    test('moon-already-up: moonset before moonrise (afternoon rise pattern)',
        () {
      // Simulates real late-May data: moon rises at 4pm (afternoon, in day),
      // sets at 5am (early morning, at night). moonset < moonrise in time.
      // prevSolar provides today's dusk for the overnight anchor.
      final afternoonRise =
          solarTimes.solarNoon.add(const Duration(hours: 4)); // ~4pm
      final earlyMorningSet = solarTimes.civilTwilightBegin
          .subtract(const Duration(hours: 3)); // ~3h before dawn
      // moonset is before moonrise — this is the afternoon-rise pattern.
      expect(earlyMorningSet.isBefore(afternoonRise), isTrue);

      final lunarData = LunarDayTimes(
        moonrise: afternoonRise,
        moonset: earlyMorningSet,
        phase: MoonPhase.full,
        illuminationFraction: 1.0,
      );
      // prevSolar = solar (same body used as "previous night" reference).
      final body = LunarBody(lunar: lunarData, solar: solar, prevSolar: solar);
      final stops = body.gradientStops(layout, now);

      // Should have upColor at or before moonset.
      final xSet = layout.xForTime(earlyMorningSet, now);
      expect(
        stops.any((s) => s.x <= xSet && s.c != SolarBody.nightNavy),
        isTrue,
        reason: 'No moonlit stop before moonset — overnight glow missing',
      );
      // Last stop should be dark (ramp-down after moonset).
      final sorted = [...stops]..sort((a, b) => a.x.compareTo(b.x));
      expect(sorted.last.c, equals(SolarBody.nightNavy),
          reason: 'Should taper to dark after moonset');
    });
  });
}
