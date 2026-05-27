// Scenario coverage for LunarBody.nightArcsFor — drives the night-clipping
// logic with synthetic moon-arc + AstroData inputs, no lat/lng dependence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

void main() {
  // Fixed reference day. All times UTC for determinism.
  // sunrise 06:00, sunset 20:00, civil twilight ±30 min on each side.
  final day0 = DateTime.utc(2026, 5, 18);
  final civilBegin = day0.add(const Duration(hours: 5, minutes: 30));
  final sunrise = day0.add(const Duration(hours: 6));
  final solarNoon = day0.add(const Duration(hours: 13));
  final sunset = day0.add(const Duration(hours: 20));
  final civilEnd = day0.add(const Duration(hours: 20, minutes: 30));

  final astro = AstroData(
    civilTwilightBegin: civilBegin,
    sunrise: sunrise,
    solarNoon: solarNoon,
    sunset: sunset,
    civilTwilightEnd: civilEnd,
    phase: MoonPhase.full,
    illuminationFraction: 1.0,
  );

  final up = LunarBody.upColorFor(1.0);
  const navy = SolarBody.nightNavy;

  // Convenience: next-day boundaries.
  final nextCivilBegin = civilBegin.add(const Duration(hours: 24));
  final nextSunrise = sunrise.add(const Duration(hours: 24));

  List<Arc> arcsFor(DateTime rise, DateTime set) =>
      LunarBody.nightArcsFor(
        moonrise: rise,
        moonset: set,
        astroData: astro,
        upColor: up,
      );

  group('LunarBody.nightArcsFor scenarios', () {
    // -------------------------------------------------------------------
    // Daytime-only moon → no glow at all
    // -------------------------------------------------------------------
    test('moon rises and sets entirely during daytime → empty', () {
      // Rise 09:00, set 15:00 — both inside [sunrise, sunset].
      final rise = day0.add(const Duration(hours: 9));
      final set = day0.add(const Duration(hours: 15));
      expect(arcsFor(rise, set), isEmpty);
    });

    test('moon rises and sets during dusk twilight (before civilEnd) → empty',
        () {
      // Rise 20:05, set 20:25 — both inside [sunset, civilEnd].
      final rise = day0.add(const Duration(hours: 20, minutes: 5));
      final set = day0.add(const Duration(hours: 20, minutes: 25));
      expect(arcsFor(rise, set), isEmpty);
    });

    // -------------------------------------------------------------------
    // Moon rises at night, sets at night — fully inside one night
    // -------------------------------------------------------------------
    test('moon rises after civilEnd, sets before next civilBegin → full glow',
        () {
      // Rise 22:00, set next-day 03:00.
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 27)); // 03:00 next day
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.length, 3);
      expect(arcs.first.startTime, equals(rise));
      expect(arcs.first.startColor, equals(navy));
      expect(arcs.last.endTime, equals(set));
      expect(arcs.last.endColor, equals(navy));
    });

    // -------------------------------------------------------------------
    // Moon up at sunset — rose during day, sets at night
    // -------------------------------------------------------------------
    test('moon rose in afternoon, up at sunset → glow starts at civilEnd', () {
      // Rise 16:00 (in daytime), set next-day 02:00.
      final rise = day0.add(const Duration(hours: 16));
      final set = day0.add(const Duration(hours: 26));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(civilEnd));
      expect(arcs.first.startColor, equals(navy));
      expect(arcs.last.endTime, equals(set));
    });

    // -------------------------------------------------------------------
    // Moon sets after sunrise — was up overnight through dawn
    // -------------------------------------------------------------------
    test('moon sets after next sunrise → glow ends at next civilBegin', () {
      // Rise 22:00 (at night), set next-day 09:00 (in daytime).
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 33)); // 09:00 next day
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(rise));
      expect(arcs.last.endTime, equals(nextCivilBegin));
      expect(arcs.last.endColor, equals(navy));
    });

    // -------------------------------------------------------------------
    // Moon up all night — rose during prev day, sets during next day
    // -------------------------------------------------------------------
    test('moon up through entire night → glow spans full civilEnd→civilBegin',
        () {
      // Rise 14:00 (in daytime), set next-day 10:00 (in daytime).
      final rise = day0.add(const Duration(hours: 14));
      final set = day0.add(const Duration(hours: 34)); // 10:00 next day
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(civilEnd));
      expect(arcs.last.endTime, equals(nextCivilBegin));
    });

    // -------------------------------------------------------------------
    // Boundary cases — rise/set exactly on civil twilight edges
    // -------------------------------------------------------------------
    test('moonrise exactly at civilEnd → glow starts at civilEnd', () {
      final set = day0.add(const Duration(hours: 26)); // 02:00 next day
      final arcs = arcsFor(civilEnd, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(civilEnd));
    });

    test('moonset exactly at next civilBegin → glow ends at civilBegin', () {
      final rise = day0.add(const Duration(hours: 22));
      final arcs = arcsFor(rise, nextCivilBegin)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.last.endTime, equals(nextCivilBegin));
    });

    // -------------------------------------------------------------------
    // Short night gap — fade clamping so fades don't overlap
    // -------------------------------------------------------------------
    test('night portion shorter than 2×fade → no hold arc; fades stay separate',
        () {
      // Rise 22:00, set 22:20 → 20-minute night portion.
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 22, minutes: 20));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.length, 2); // fadeIn + fadeOut, no hold
      expect(arcs[0].endTime, equals(arcs[1].startTime));
    });

    // -------------------------------------------------------------------
    // Inverted / degenerate — moon only up during day-and-twilight
    // -------------------------------------------------------------------
    test('rise mid-morning, set early-evening (still in dusk) → empty', () {
      final rise = day0.add(const Duration(hours: 10));
      final set = day0.add(const Duration(hours: 20, minutes: 15));
      expect(arcsFor(rise, set), isEmpty);
    });

    // -------------------------------------------------------------------
    // upColor scaling
    // -------------------------------------------------------------------
    test('hold arc uses upColor derived from illumination', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 27));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(up));
    });

    test('new moon (zero illumination) yields nightNavy upColor', () {
      expect(LunarBody.upColorFor(0.0), equals(navy));
    });

    test('full moon upColor is distinct from nightNavy', () {
      expect(LunarBody.upColorFor(1.0), isNot(equals(navy)));
    });
  });

  group('LunarBody.nightArcsFor — arc continuity', () {
    test('fadeIn ends where hold begins; hold ends where fadeOut begins', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 28)); // 04:00 next day
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.length, 3);
      expect(arcs[0].endTime, equals(arcs[1].startTime));
      expect(arcs[1].endTime, equals(arcs[2].startTime));
    });

    test('fade colors are navy → up → up → up → up → navy', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 28));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[0].startColor, equals(navy));
      expect(arcs[0].endColor, equals(up));
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(up));
      expect(arcs[2].startColor, equals(up));
      expect(arcs[2].endColor, equals(navy));
    });
  });

  group('astro reference — sanity', () {
    test('nextSunrise is exactly 24h after sunrise (synthetic data)', () {
      expect(nextSunrise.difference(sunrise), const Duration(hours: 24));
    });

    test('upColor is a Color value', () {
      expect(up, isA<Color>());
    });
  });
}
