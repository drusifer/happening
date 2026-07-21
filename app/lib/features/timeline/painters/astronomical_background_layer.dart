// Replaces BackgroundLayer when the astronomical theme is active.
//
// TLDR:
// Overview: Asks each SkyBody for its Arcs over the window, merges them by pointwise brightness, paints as one LinearGradient.
// Problem:  Need a single horizontal gradient that blends solar phases with moon glow without either body needing to know the other's schedule.
// Solution: Two SkyBody instances (Solar, Lunar). At every breakpoint the brighter body's colour wins (Color.computeLuminance) -- daytime always wins because solar colours are always brighter than any lunar colour by palette construction, and twilight blends smoothly for free. Gaps default to night navy.
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
    final solarArcs = solar.getArcs(layout.windowStart, layout.windowEnd);
    final lunarArcs = bodies
        .whereType<LunarBody>()
        .expand((b) => b.getArcs(layout.windowStart, layout.windowEnd))
        .toList();

    final arcs = mergeByBrightness(solarArcs, lunarArcs);

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

  /// Merges [solarArcs] and [lunarArcs] into one non-overlapping, chronologically
  /// sorted arc list, deciding at every breakpoint which body's colour wins by
  /// [Color.computeLuminance] alone -- no day/night cutoff is hard-coded here.
  /// This works because solar colours (`dayBlue`/`dawnDusk`) are always
  /// brighter than any colour [LunarBody] can produce, by palette
  /// construction (see the invariant test asserting exactly that): daytime
  /// wins outright, and twilight blends smoothly as each body's colour ramps
  /// through the shared breakpoints. Exposed for unit testing.
  static List<Arc> mergeByBrightness(List<Arc> solarArcs, List<Arc> lunarArcs) {
    final breakpoints = <DateTime>{
      for (final a in solarArcs) ...[a.startTime, a.endTime],
      for (final a in lunarArcs) ...[a.startTime, a.endTime],
    }.toList()
      ..sort();

    final result = <Arc>[];
    for (var i = 0; i + 1 < breakpoints.length; i++) {
      final segStart = breakpoints[i];
      final segEnd = breakpoints[i + 1];
      if (!segEnd.isAfter(segStart)) continue;

      final mid = DateTime.fromMicrosecondsSinceEpoch(
        (segStart.microsecondsSinceEpoch + segEnd.microsecondsSinceEpoch) ~/ 2,
      );
      final solarAtMid = _colorAt(mid, solarArcs);
      final lunarAtMid = _colorAt(mid, lunarArcs);
      if (solarAtMid == null && lunarAtMid == null) continue;

      result.add(Arc(
        startTime: segStart,
        endTime: segEnd,
        startColor: _brighterColor(
          _colorAt(segStart, solarArcs),
          _colorAt(segStart, lunarArcs),
        )!,
        endColor: _brighterColor(
          _colorAt(segEnd, solarArcs),
          _colorAt(segEnd, lunarArcs),
        )!,
      ));
    }
    return result;
  }

  /// The colour [arcs] defines at instant [t], linearly interpolated within
  /// whichever arc covers it, or null if no arc in [arcs] covers [t].
  static Color? _colorAt(DateTime t, List<Arc> arcs) {
    for (final a in arcs) {
      if (!t.isBefore(a.startTime) && !t.isAfter(a.endTime)) {
        final span = a.endTime.difference(a.startTime).inMicroseconds;
        if (span <= 0) return a.startColor;
        final frac = t.difference(a.startTime).inMicroseconds / span;
        return Color.lerp(a.startColor, a.endColor, frac.clamp(0.0, 1.0));
      }
    }
    return null;
  }

  static Color? _brighterColor(Color? solar, Color? lunar) {
    if (solar == null) return lunar;
    if (lunar == null) return solar;
    return solar.computeLuminance() >= lunar.computeLuminance() ? solar : lunar;
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
