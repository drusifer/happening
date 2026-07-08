// Scenario coverage for LunarBody.moonUpArcs — the pure moonrise/moonset ->
// arcs builder. Unlike the old dusk/dawn-bridging design this replaced, this
// function takes no solar schedule input at all: it cannot know or care what
// day it is, so the whole class of "wrong calendar day" bug is structurally
// impossible here. Daytime clipping is the compositing layer's job now (see
// astronomical_background_layer_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

void main() {
  final day0 = DateTime.utc(2026, 5, 18);
  const navy = SolarBody.nightNavy;
  final up = LunarBody.upColorFor(1.0);

  List<Arc> arcsFor(DateTime rise, DateTime set) =>
      LunarBody.moonUpArcs(moonrise: rise, moonset: set, upColor: up)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  group('Ordinary night-time moon (well over 2x fade duration)', () {
    // Rise 22:00, set next-day 03:00 — 5h up, plenty of margin.
    final rise = day0.add(const Duration(hours: 22));
    final set = day0.add(const Duration(hours: 27));

    test('produces exactly three arcs: rise, hold, set', () {
      expect(arcsFor(rise, set).length, 3);
    });

    test('arcs are contiguous and span [moonrise, moonset]', () {
      final arcs = arcsFor(rise, set);
      expect(arcs.first.startTime, equals(rise));
      expect(arcs.last.endTime, equals(set));
      for (var i = 0; i + 1 < arcs.length; i++) {
        expect(arcs[i].endTime, equals(arcs[i + 1].startTime));
      }
    });

    test('rise arc fades navy -> up, set arc fades up -> navy', () {
      final arcs = arcsFor(rise, set);
      expect(arcs.first.startColor, equals(navy));
      expect(arcs.first.endColor, equals(up));
      expect(arcs.last.startColor, equals(up));
      expect(arcs.last.endColor, equals(navy));
    });

    test('hold arc is solid up color', () {
      final arcs = arcsFor(rise, set);
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(up));
    });
  });

  group('Short moon-up interval (< 2x fade duration) clamps to a meeting point', () {
    // Up for only 30 minutes -- shorter than 2x the 25-min fade, so rise and
    // set must meet at the midpoint instead of overlapping.
    final rise = day0.add(const Duration(hours: 22));
    final set = rise.add(const Duration(minutes: 30));
    final mid = rise.add(const Duration(minutes: 15));

    test('produces exactly two arcs (no hold segment)', () {
      expect(arcsFor(rise, set).length, 2);
    });

    test('arcs meet exactly at the midpoint', () {
      final arcs = arcsFor(rise, set);
      expect(arcs[0].startTime, equals(rise));
      expect(arcs[0].endTime, equals(mid));
      expect(arcs[1].startTime, equals(mid));
      expect(arcs[1].endTime, equals(set));
    });

    test('fades navy -> up -> navy through the midpoint', () {
      final arcs = arcsFor(rise, set);
      expect(arcs[0].startColor, equals(navy));
      expect(arcs[0].endColor, equals(up));
      expect(arcs[1].startColor, equals(up));
      expect(arcs[1].endColor, equals(navy));
    });
  });

  group('Output depends only on moonrise/moonset/upColor', () {
    test('identical moonrise/moonset/upColor always produce identical arcs',
        () {
      // No AstroData, no lat/lng, no "which day is it" input exists in this
      // function's signature at all -- this is the regression guard for the
      // whole day-anchoring bug class the old nightArcsFor had.
      final rise = day0.add(const Duration(hours: 1));
      final set = day0.add(const Duration(hours: 15)); // moonset after solar
      // noon -- the exact shape that broke the old duskMid/dawnMid logic.
      final a = arcsFor(rise, set);
      final b = arcsFor(rise, set);
      expect(a, equals(b));
    });

    test('a moon rising before dawn and setting after solar noon still '
        'produces a plain three-arc rise/hold/set shape', () {
      final rise = day0.add(const Duration(hours: 1)); // 01:00
      final set = day0.add(const Duration(hours: 15)); // 15:00, next-day-ish
      final arcs = arcsFor(rise, set);
      expect(arcs.length, 3);
      expect(arcs.first.startTime, equals(rise));
      expect(arcs.last.endTime, equals(set));
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
      const custom = Color(0xFF123456);
      final arcs = LunarBody.moonUpArcs(
        moonrise: day0.add(const Duration(hours: 22)),
        moonset: day0.add(const Duration(hours: 28)),
        upColor: custom,
      )..sort((a, b) => a.startTime.compareTo(b.startTime));
      expect(arcs[1].startColor, equals(custom));
      expect(arcs[1].endColor, equals(custom));
    });
  });
}
