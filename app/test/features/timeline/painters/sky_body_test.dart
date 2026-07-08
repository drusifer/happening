// Unit tests for the shared `ramp()` primitive used by both SolarBody and
// LunarBody to build their colour arcs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';

void main() {
  final from = DateTime.utc(2026, 5, 18, 20, 0);
  final to = DateTime.utc(2026, 5, 18, 20, 30);

  const navy = Color(0xFF05080F);
  const amber = Color(0xFFE8722A);
  const blue = Color(0xFF3F7189);

  group('ramp', () {
    test('N colors produce N-1 arcs', () {
      expect(ramp(from: from, to: to, colors: [navy, amber, blue]).length, 2);
      expect(ramp(from: from, to: to, colors: [navy, blue]).length, 1);
    });

    test('arcs are contiguous: each end equals next start', () {
      final arcs = ramp(from: from, to: to, colors: [navy, amber, blue]);
      for (var i = 0; i + 1 < arcs.length; i++) {
        expect(arcs[i].endTime, equals(arcs[i + 1].startTime));
      }
    });

    test('first arc starts at from, last arc ends at to', () {
      final arcs = ramp(from: from, to: to, colors: [navy, amber, blue]);
      expect(arcs.first.startTime, equals(from));
      expect(arcs.last.endTime, equals(to));
    });

    test('colors are assigned in order along the ramp', () {
      final arcs = ramp(from: from, to: to, colors: [navy, amber, blue]);
      expect(arcs[0].startColor, equals(navy));
      expect(arcs[0].endColor, equals(amber));
      expect(arcs[1].startColor, equals(amber));
      expect(arcs[1].endColor, equals(blue));
    });

    test('two identical colors produce a single flat arc', () {
      final arcs = ramp(from: from, to: to, colors: [blue, blue]);
      expect(arcs.length, 1);
      expect(arcs.single.startColor, equals(blue));
      expect(arcs.single.endColor, equals(blue));
      expect(arcs.single.startTime, equals(from));
      expect(arcs.single.endTime, equals(to));
    });

    test('two colors produce exactly one arc spanning the whole range', () {
      final arcs = ramp(from: from, to: to, colors: [navy, blue]);
      expect(arcs.single.startTime, equals(from));
      expect(arcs.single.endTime, equals(to));
      expect(arcs.single.startColor, equals(navy));
      expect(arcs.single.endColor, equals(blue));
    });

    test('intermediate breakpoints are evenly spaced in time', () {
      final arcs = ramp(from: from, to: to, colors: [navy, amber, blue]);
      // 30 min span, 2 arcs -> midpoint break at +15 min.
      expect(arcs[0].endTime, equals(from.add(const Duration(minutes: 15))));
    });
  });
}
