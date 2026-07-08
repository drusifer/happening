// Abstract sky body base class — owns colour arcs and glyphs for one body.
//
// TLDR:
// Overview: Each sky body (Sun, Moon) emits Arcs (timed colour segments) and glyph icons over a window.
// Problem:  ABL needs a uniform way to ask each body what it paints, without lunar/solar branching.
// Solution: SkyBody.getArcs(start, end) + getGlyphs(start, end). Arc is a simple (start, end, startColor, endColor) tuple.
// Breaking Changes: Replaces the prior gradientStops/buildGlyphs API.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';

/// A contiguous gradient segment in time. The painter linearly interpolates
/// from [startColor] at [startTime] to [endColor] at [endTime].
@immutable
class Arc {
  const Arc({
    required this.startTime,
    required this.endTime,
    required this.startColor,
    required this.endColor,
  });

  final DateTime startTime;
  final DateTime endTime;
  final Color startColor;
  final Color endColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arc &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          startColor == other.startColor &&
          endColor == other.endColor;

  @override
  int get hashCode => Object.hash(startTime, endTime, startColor, endColor);
}

/// Spreads [colors] evenly across `[from, to]` as `colors.length - 1`
/// contiguous linear arcs. Direction-agnostic: works equally for a body
/// brightening (dim→bright) or dimming (bright→dim) — the caller picks the
/// color order. Shared by SolarBody and LunarBody so both bodies build
/// their gradients through the same mechanism.
List<Arc> ramp({
  required DateTime from,
  required DateTime to,
  required List<Color> colors,
}) {
  assert(colors.length >= 2, 'ramp needs at least 2 colors');
  final totalMicros = to.difference(from).inMicroseconds;
  final steps = colors.length - 1;
  final arcs = <Arc>[];
  var stepStart = from;
  for (var i = 0; i < steps; i++) {
    final stepEnd = i == steps - 1
        ? to
        : from.add(Duration(
            microseconds: totalMicros * (i + 1) ~/ steps,
          ));
    arcs.add(Arc(
      startTime: stepStart,
      endTime: stepEnd,
      startColor: colors[i],
      endColor: colors[i + 1],
    ));
    stepStart = stepEnd;
  }
  return arcs;
}

/// One celestial body. There are exactly two instances in production: the Sun
/// and the Moon. Each is asked for all arcs and glyphs covering the visible
/// window.
abstract class SkyBody {
  const SkyBody();

  /// Colour arcs contributed by this body, intersecting [windowStart, windowEnd].
  /// May be empty. Arcs do not need to be sorted.
  List<Arc> getArcs(DateTime windowStart, DateTime windowEnd);

  /// Glyph icons (rise/transit/set markers) contributed by this body within
  /// [windowStart, windowEnd]. May be empty.
  List<AstroObject> getGlyphs(DateTime windowStart, DateTime windowEnd);
}
