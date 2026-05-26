// Abstract sky body base class for astronomical events.
//
// TLDR:
// Overview: Abstract base class representing celestial bodies (Sun, Moon) tracking rise, set, and peak times.
// Problem:  Need unified logic to manage daylight gradients and coordinate glyph positioning across bodies.
// Solution: Defines shared mathematical interpolation routines for nightness scaling and gradient calculations.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Abstract sky body: owns gradient stops + glyph drawing for one sky event cycle.
abstract class SkyBody {
  const SkyBody();
  Color get upColor;
  Color get downColor;
  Color get twilightColor;

  DateTime? get riseBegin;
  DateTime? get riseEnd;
  DateTime? get peak;
  DateTime? get setBegin;
  DateTime? get setEnd;

  /// Gradient stops for this body. Order is arbitrary; caller sorts before use.
  ///
  /// When [riseBegin] == [riseEnd] (e.g. moonrise with no twilight zone) the
  /// same x gets two stops, producing an instant colour switch.
  List<({double x, Color c})> gradientStops(
      TimelineLayout layout, DateTime now) {
    final result = <({double x, Color c})>[];

    void add(DateTime? t, Color c) {
      if (t == null) return;
      result.add((x: layout.xForTime(t, now), c: c));
    }

    void addMid(DateTime? t1, DateTime? t2, Color c) {
      if (t1 == null || t2 == null) return;
      final x = (layout.xForTime(t1, now) + layout.xForTime(t2, now)) / 2;
      result.add((x: x, c: c));
    }

    add(riseBegin, downColor);
    if (riseBegin != riseEnd) addMid(riseBegin, riseEnd, twilightColor);
    add(riseEnd, upColor);
    add(peak, upColor);
    add(setBegin, upColor);
    if (setBegin != setEnd) addMid(setBegin, setEnd, twilightColor);
    add(setEnd, downColor);

    return result;
  }

  /// Nightness at [x]: 0.0 = full day, 1.0 = full night.
  double nightnessAt(double x, TimelineLayout layout, DateTime now) {
    final rb = riseBegin != null ? layout.xForTime(riseBegin!, now) : null;
    final re = riseEnd != null ? layout.xForTime(riseEnd!, now) : null;
    final sb = setBegin != null ? layout.xForTime(setBegin!, now) : null;
    final se = setEnd != null ? layout.xForTime(setEnd!, now) : null;

    if (rb == null) return 1.0;
    if (x <= rb) return 1.0;
    if (re != null && re > rb && x < re) return 1.0 - (x - rb) / (re - rb);
    if (sb != null && x <= sb) return 0.0;
    if (sb != null && se != null && se > sb && x <= se) {
      return (x - sb) / (se - sb);
    }
    return 1.0;
  }

  /// Returns all glyph objects for this body (visibility not filtered).
  List<AstroObject> buildGlyphs();

  /// Draws each glyph that falls within the visible strip.
  void paintGlyphs(
      Canvas canvas, Size size, TimelineLayout layout, DateTime now) {
    for (final obj in buildGlyphs()) {
      drawIfVisible(canvas, size, layout, now, obj);
    }
  }

  /// Clip helper shared by subclasses.
  void drawIfVisible(Canvas canvas, Size size, TimelineLayout layout,
      DateTime now, AstroObject obj) {
    final x = layout.xForTime(obj.time, now);
    if (x < -kAstroIconRadius || x > size.width + kAstroIconRadius) return;
    obj.draw(canvas, size, x);
  }
}
