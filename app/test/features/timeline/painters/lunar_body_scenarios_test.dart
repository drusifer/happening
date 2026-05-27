// Scenario coverage for LunarBody.nightArcsFor — drives the night-clipping
// logic with synthetic moon-arc + AstroData inputs, no lat/lng dependence.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

void main() {
  // Fixed reference day, all UTC for determinism.
  // sunrise 06:00, sunset 20:00, civil twilight ±30 min on each side.
  // duskMid = 20:15, dawnMid = 05:45.
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
  const amber = SolarBody.dawnDusk;

  // Convenience boundary times.
  final duskMid = day0.add(const Duration(hours: 20, minutes: 15));
  final nextCivilBegin = civilBegin.add(const Duration(hours: 24));
  final nextDawnMid =
      day0.add(const Duration(hours: 24 + 5, minutes: 45));

  List<Arc> arcsFor(DateTime rise, DateTime set) =>
      LunarBody.nightArcsFor(
        moonrise: rise,
        moonset: set,
        astroData: astro,
        upColor: up,
      );

  group('Daytime-only moon → no glow', () {
    test('rise and set entirely during daytime → empty', () {
      final rise = day0.add(const Duration(hours: 9));
      final set = day0.add(const Duration(hours: 15));
      expect(arcsFor(rise, set), isEmpty);
    });

    test('rise and set entirely within dusk-finish window → empty', () {
      // 20:20→20:25 — both inside (duskMid, civilEnd).
      final rise = day0.add(const Duration(hours: 20, minutes: 20));
      final set = day0.add(const Duration(hours: 20, minutes: 25));
      expect(arcsFor(rise, set), isEmpty);
    });
  });

  group('Moon rises and sets at night → standard fadeIn/hold/fadeOut', () {
    test('navy→up→up→up→navy with three arcs', () {
      // Rise 22:00, set next-day 03:00 — clean night with margin on both ends.
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 27));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.length, 3);
      expect(arcs[0].startTime, equals(rise));
      expect(arcs[0].startColor, equals(navy));
      expect(arcs[0].endColor, equals(up));
      expect(arcs[2].endTime, equals(set));
      expect(arcs[2].endColor, equals(navy));
    });

    test('arcs are contiguous: each end equals next start', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 28));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[0].endTime, equals(arcs[1].startTime));
      expect(arcs[1].endTime, equals(arcs[2].startTime));
    });

    test('hold arc is solid upColor', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 27));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(up));
    });
  });

  group('Moon up at dusk → amber→up bridge replaces dusk-finish', () {
    test('rose in afternoon, sets at night: lead-in is amber→up at [duskMid, civilEnd]',
        () {
      final rise = day0.add(const Duration(hours: 16));
      final set = day0.add(const Duration(hours: 26));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(duskMid),
          reason: 'lead-in must start at duskMid, not civilEnd');
      expect(arcs.first.endTime, equals(civilEnd));
      expect(arcs.first.startColor, equals(amber),
          reason: 'lead-in must begin in amber, not navy');
      expect(arcs.first.endColor, equals(up));
    });

    test('moonrise exactly at duskMid still triggers the amber bridge', () {
      final rise = duskMid;
      final set = day0.add(const Duration(hours: 26));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(duskMid));
      expect(arcs.first.startColor, equals(amber));
    });

    test('moonrise just after duskMid → standard fadeIn (no bridge)', () {
      final rise = day0.add(const Duration(hours: 20, minutes: 20));
      final set = day0.add(const Duration(hours: 26));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(rise));
      expect(arcs.first.startColor, equals(navy));
    });
  });

  group('Moon up at dawn → up→amber bridge replaces dawn-rise', () {
    test('rises at night, sets after sunrise: lead-out is up→amber at [civilBegin, dawnMid]',
        () {
      // Rise 22:00 (night), set next-day 09:00 (daytime → moon was up through dawn).
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 33));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.last.startTime, equals(nextCivilBegin));
      expect(arcs.last.endTime, equals(nextDawnMid),
          reason: 'lead-out must end at dawnMid, not civilBegin');
      expect(arcs.last.startColor, equals(up));
      expect(arcs.last.endColor, equals(amber),
          reason: 'lead-out must finish in amber, not navy');
    });

    test('moonset exactly at next dawnMid still triggers the amber bridge', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = nextDawnMid;
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.last.endTime, equals(nextDawnMid));
      expect(arcs.last.endColor, equals(amber));
    });

    test('moonset just before next dawnMid → standard fadeOut (no bridge)', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 24 + 5, minutes: 40));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.last.endTime, equals(set));
      expect(arcs.last.endColor, equals(navy));
    });
  });

  group('Moon up all night (both bridges)', () {
    test('rose afternoon, sets after next sunrise: amber→up...up→amber', () {
      final rise = day0.add(const Duration(hours: 14));
      final set = day0.add(const Duration(hours: 34)); // 10:00 next day
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.first.startTime, equals(duskMid));
      expect(arcs.first.startColor, equals(amber));
      expect(arcs.last.endTime, equals(nextDawnMid));
      expect(arcs.last.endColor, equals(amber));
    });
  });

  group('Short-night fallback (fades would overlap)', () {
    test('moon up only 30 min mid-night → 2 navy↔up arcs, no hold', () {
      final rise = day0.add(const Duration(hours: 22));
      final set = day0.add(const Duration(hours: 22, minutes: 30));
      final arcs = arcsFor(rise, set)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs.length, 2);
      expect(arcs[0].startColor, equals(navy));
      expect(arcs[0].endColor, equals(up));
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(navy));
      expect(arcs[0].endTime, equals(arcs[1].startTime));
    });
  });

  group('upColor scaling', () {
    test('new moon (zero illumination) yields nightNavy upColor', () {
      expect(LunarBody.upColorFor(0.0), equals(navy));
    });

    test('full moon upColor is distinguishable from nightNavy', () {
      expect(LunarBody.upColorFor(1.0), isNot(equals(navy)));
    });

    test('upColor used in hold arc matches passed-in upColor', () {
      final custom = const Color(0xFF123456);
      final arcs = LunarBody.nightArcsFor(
        moonrise: day0.add(const Duration(hours: 22)),
        moonset: day0.add(const Duration(hours: 28)),
        astroData: astro,
        upColor: custom,
      )..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[1].startColor, equals(custom));
      expect(arcs[1].endColor, equals(custom));
    });
  });
}
