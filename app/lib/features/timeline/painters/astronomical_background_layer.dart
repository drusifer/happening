// Replaces BackgroundLayer when the astronomical theme is active.
//
// TLDR:
// Overview: Asks each SkyBody for its Arcs over the window, clips solar where lunar overlaps, paints as one LinearGradient.
// Problem:  Need a single horizontal gradient that blends solar phases with moon glow without per-pattern branching.
// Solution: Two SkyBody instances (Solar, Lunar). Lunar wins over solar where they overlap. Gaps default to night navy.
// Breaking Changes: No (callers unchanged).
//
// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/background_layer.dart'
    show BackgroundLayer;
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Replaces [BackgroundLayer] when the astronomical theme is active.
class AstronomicalBackgroundLayer implements TimelineLayer {
  static final _stars = _generateStars();
  static List<({double fx, double fy, double brightness})> _generateStars() {
    final rng = math.Random(42);
    return List.generate(
      90,
      (_) => (
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        brightness: rng.nextDouble(),
      ),
    );
  }

  const AstronomicalBackgroundLayer({
    required this.astroData,
    required this.layout,
    required this.now,
    this.lat,
    this.lng,
  });

  final AstroData astroData;
  final TimelineLayout layout;
  final DateTime now;
  final double? lat;
  final double? lng;

  List<SkyBody> get _bodies => [
        SolarBody(astroData: astroData),
        if (lat != null && lng != null)
          LunarBody(astroData: astroData, lat: lat!, lng: lng!),
      ];

  /// Returns the [AstroHit] for whichever glyph [pos] is within touch range of,
  /// or null if the pointer is not over any glyph.
  AstroHit? hitTest(Offset pos, Size size) {
    const hitR = kAstroIconRadius + 6.0;
    for (final body in _bodies) {
      for (final obj in body.getGlyphs(layout.windowStart, layout.windowEnd)) {
        final gx = layout.xForTime(obj.time, now);
        if (gx < -kAstroIconRadius || gx > size.width + kAstroIconRadius) {
          continue;
        }
        final gcy = obj.cy(size.height);
        final dx = pos.dx - gx;
        final dy = pos.dy - gcy;
        if (dx * dx + dy * dy <= hitR * hitR) {
          return AstroHit(
            label: obj.label,
            time: obj.time,
            glyphX: gx,
            glyphCy: gcy,
            fraction: obj is Moon ? obj.fraction : null,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Paint
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bodies = _bodies;

    final solar = bodies.whereType<SolarBody>().first;
    final lunarArcs = bodies
        .whereType<LunarBody>()
        .expand((b) => b.getArcs(layout.windowStart, layout.windowEnd))
        .toList();
    final solarArcs = _clipBy(
      solar.getArcs(layout.windowStart, layout.windowEnd),
      lunarArcs,
    );

    final arcs = [...solarArcs, ...lunarArcs]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()..shader = _buildShader(arcs, w, size.height),
    );

    _paintStars(canvas, size);

    for (final body in bodies) {
      for (final obj in body.getGlyphs(layout.windowStart, layout.windowEnd)) {
        final x = layout.xForTime(obj.time, now);
        if (x < -kAstroIconRadius || x > w + kAstroIconRadius) continue;
        obj.draw(canvas, size, x);
      }
    }
  }

  /// Builds a horizontal LinearGradient shader from the chronologically-sorted
  /// [arcs]. Gaps default to night navy.
  Shader _buildShader(List<Arc> arcs, double w, double h) {
    final colors = <Color>[];
    final stops = <double>[];

    void addStop(DateTime t, Color c) {
      final x = layout.xForTime(t, now).clamp(0.0, w);
      colors.add(c);
      stops.add(x / w);
    }

    var cur = layout.windowStart;
    for (final arc in arcs) {
      if (arc.startTime.isAfter(cur)) {
        addStop(cur, SolarBody.nightNavy);
        addStop(arc.startTime, SolarBody.nightNavy);
      }
      addStop(arc.startTime, arc.startColor);
      addStop(arc.endTime, arc.endColor);
      cur = arc.endTime;
    }
    if (cur.isBefore(layout.windowEnd)) {
      addStop(cur, SolarBody.nightNavy);
      addStop(layout.windowEnd, SolarBody.nightNavy);
    }
    if (colors.isEmpty) {
      colors.addAll([SolarBody.nightNavy, SolarBody.nightNavy]);
      stops.addAll([0.0, 1.0]);
    }

    return LinearGradient(colors: colors, stops: stops)
        .createShader(Rect.fromLTWH(0, 0, w, h));
  }

  /// Removes the portions of [solar] arcs that overlap with any [lunar] arc.
  /// Where overlap occurs, the solar arc is split into the leading and
  /// trailing remainders (either may be empty). Solar arcs that are fully
  /// covered by a lunar arc are dropped.
  static List<Arc> _clipBy(List<Arc> solar, List<Arc> lunar) {
    var result = solar;
    for (final la in lunar) {
      final next = <Arc>[];
      for (final sa in result) {
        if (!la.endTime.isAfter(sa.startTime) ||
            !la.startTime.isBefore(sa.endTime)) {
          next.add(sa);
          continue;
        }
        if (la.startTime.isAfter(sa.startTime)) {
          next.add(Arc(
            startTime: sa.startTime,
            endTime: la.startTime,
            startColor: sa.startColor,
            endColor: _interp(sa, la.startTime),
          ));
        }
        if (la.endTime.isBefore(sa.endTime)) {
          next.add(Arc(
            startTime: la.endTime,
            endTime: sa.endTime,
            startColor: _interp(sa, la.endTime),
            endColor: sa.endColor,
          ));
        }
      }
      result = next;
    }
    return result;
  }

  static Color _interp(Arc arc, DateTime t) {
    final span = arc.endTime.difference(arc.startTime).inMicroseconds;
    if (span <= 0) return arc.startColor;
    final pos = t.difference(arc.startTime).inMicroseconds / span;
    return Color.lerp(arc.startColor, arc.endColor, pos.clamp(0.0, 1.0))!;
  }

  void _paintStars(Canvas canvas, Size size) {
    final starPaint = Paint();
    for (final star in _stars) {
      final px = star.fx * size.width;
      final py = star.fy * size.height;
      final t = _timeForX(px);
      final n = nightnessAt(t, astroData);
      if (n <= 0) continue;
      final alpha = n * (0.45 + star.brightness * 0.55);
      final radius = 0.4 + star.brightness * 0.9;
      canvas.drawCircle(
        Offset(px, py),
        radius,
        starPaint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  DateTime _timeForX(double x) {
    final secs = (x - layout.nowIndicatorX) / layout.pixelsPerSecond;
    return now.add(Duration(milliseconds: (secs * 1000).round()));
  }
}
