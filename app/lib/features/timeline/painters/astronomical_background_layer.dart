import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Replaces [BackgroundLayer] when the astronomical theme is active.
///
/// Paints a horizontal gradient anchored to real solar event times so it
/// scrolls left with the timeline exactly like tick marks and time labels.
/// Tomorrow's dawn is estimated by adding 24 h to today's events (drift < 2
/// min/day, imperceptible) so a 24-hour view shows both transitions.
class AstronomicalBackgroundLayer implements TimelineLayer {
  static const _nightNavy = Color(0xFF05080F);
  static const _dawnDusk = Color(0xFFE8722A);
  static const _dayBlue = Color(0xFF5BA3C9);

  // Pre-generated star field: fixed seed so positions are stable across repaints.
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
  });

  final AstroData astroData;
  final TimelineLayout layout;
  final DateTime now;

  /// Returns the sky color for today's solar events only.
  /// Package-visible for unit tests.
  Color colorAtX(
    double x, {
    required double xCtb,
    required double xRise,
    required double xSet,
    required double xCte,
  }) {
    if (x < xCtb) return _nightNavy;
    if (x < xRise) return _dawnDusk;
    if (x <= xSet) return _dayBlue;
    if (x <= xCte) return _dawnDusk;
    return _nightNavy;
  }

  /// Like [colorAtX] but also covers tomorrow's dawn window.
  Color _skyColorAtX(
    double x, {
    required double xCtb,
    required double xRise,
    required double xSet,
    required double xCte,
    required double xCtbNext,
    required double xRiseNext,
  }) {
    if (x < xCtb) return _nightNavy;
    if (x < xRise) return _dawnDusk;
    if (x <= xSet) return _dayBlue;
    if (x <= xCte) return _dawnDusk;
    if (x < xCtbNext) return _nightNavy;
    if (x < xRiseNext) return _dawnDusk;
    return _dayBlue;
  }

  /// 0.0 = full day, 1.0 = full night. Used for star opacity.
  double _nightnessAt(
    double x, {
    required double xCtb,
    required double xRise,
    required double xSet,
    required double xCte,
    required double xCtbNext,
    required double xRiseNext,
  }) {
    if (x < xCtb) return 1.0;
    if (xRise > xCtb && x < xRise) return 1.0 - (x - xCtb) / (xRise - xCtb);
    if (x <= xSet) return 0.0;
    if (xCte > xSet && x <= xCte) return (x - xSet) / (xCte - xSet);
    if (x < xCtbNext) return 1.0;
    if (xRiseNext > xCtbNext && x < xRiseNext) {
      return 1.0 - (x - xCtbNext) / (xRiseNext - xCtbNext);
    }
    return 0.0;
  }

  void _paintStars(
    Canvas canvas,
    Size size, {
    required double xCtb,
    required double xRise,
    required double xSet,
    required double xCte,
    required double xCtbNext,
    required double xRiseNext,
  }) {
    final starPaint = Paint();
    for (final star in _stars) {
      final px = star.fx * size.width;
      final py = star.fy * size.height;
      final nightness = _nightnessAt(px,
          xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte,
          xCtbNext: xCtbNext, xRiseNext: xRiseNext);
      if (nightness <= 0) continue;
      final alpha = nightness * (0.45 + star.brightness * 0.55);
      final radius = 0.4 + star.brightness * 0.9;
      canvas.drawCircle(
        Offset(px, py),
        radius,
        starPaint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // Today's unclamped pixel positions.
    final xCtb = layout.xForTime(astroData.civilTwilightBegin, now);
    final xRise = layout.xForTime(astroData.sunrise, now);
    final xSet = layout.xForTime(astroData.sunset, now);
    final xCte = layout.xForTime(astroData.civilTwilightEnd, now);

    // Tomorrow's dawn: +24 h offset. Drift < 2 min/day — imperceptible.
    final xCtbNext = layout.xForTime(
        astroData.civilTwilightBegin.add(const Duration(hours: 24)), now);
    final xRiseNext = layout.xForTime(
        astroData.sunrise.add(const Duration(hours: 24)), now);

    final xMidDawn = (xCtb + xRise) / 2;
    final xMidDusk = (xSet + xCte) / 2;
    final xMidDawnNext = (xCtbNext + xRiseNext) / 2;

    // All key stops in ascending x order (today's events then tomorrow's dawn).
    final keyEvents = [
      (x: xCtb, c: _nightNavy),
      (x: xMidDawn, c: _dawnDusk),
      (x: xRise, c: _dayBlue),
      (x: xSet, c: _dayBlue),
      (x: xMidDusk, c: _dawnDusk),
      (x: xCte, c: _nightNavy),
      (x: xCtbNext, c: _nightNavy),
      (x: xMidDawnNext, c: _dawnDusk),
      (x: xRiseNext, c: _dayBlue),
    ];

    final edgeArgs = (
      xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte,
      xCtbNext: xCtbNext, xRiseNext: xRiseNext,
    );

    final colors = <Color>[_skyColorAtX(0, xCtb: edgeArgs.xCtb,
        xRise: edgeArgs.xRise, xSet: edgeArgs.xSet, xCte: edgeArgs.xCte,
        xCtbNext: edgeArgs.xCtbNext, xRiseNext: edgeArgs.xRiseNext)];
    final stops = <double>[0.0];

    for (final (:x, :c) in keyEvents) {
      if (x > 0 && x < w) {
        colors.add(c);
        stops.add(x / w);
      }
    }

    colors.add(_skyColorAtX(w, xCtb: edgeArgs.xCtb,
        xRise: edgeArgs.xRise, xSet: edgeArgs.xSet, xCte: edgeArgs.xCte,
        xCtbNext: edgeArgs.xCtbNext, xRiseNext: edgeArgs.xRiseNext));
    stops.add(1.0);

    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
      stops: stops,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    _paintStars(canvas, size,
        xCtb: xCtb, xRise: xRise, xSet: xSet, xCte: xCte,
        xCtbNext: xCtbNext, xRiseNext: xRiseNext);
  }
}
