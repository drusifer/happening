// Timeline glyph objects representing celestial bodies and events.
//
// TLDR:
// Overview: Declares drawable celestial glyph objects (Sun, Sunrise/set, Moon, Moonrise/set/transit) for the timeline.
// Problem:  Need highly visible, shaded, and custom-clipped icon rendering for both solar noon and phase-accurate lunar shapes.
// Solution: Uses shaped paths, elliptical terminator calculations, and circular masking with BlendMode.clear to paint exact moon shapes.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';

/// Clip tolerance shared by all astro icons.
const kAstroIconRadius = 5.5;

// ---------------------------------------------------------------------------
// Hit result
// ---------------------------------------------------------------------------

class AstroHit {
  const AstroHit({
    required this.label,
    required this.time,
    required this.glyphX,
    required this.glyphCy,
    this.fraction,
  });

  final String label;
  final DateTime time;
  final double glyphX;
  final double glyphCy;
  final double? fraction; // moon illumination 0–1; null for solar objects
}

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

abstract class AstroObject {
  const AstroObject({required this.time});

  final DateTime time;

  String get label;

  static const _shadowBlur = 3.0;
  static const _shadowColor = Color(0x99000000);
  static const _shadowRadius = kAstroIconRadius + 3.0;
  static const _shadowDx = 1.5;
  static const _shadowDy = 1.5;

  double cy(double height);
  void drawIcon(Canvas canvas, Size size, double x, double cy);

  void draw(Canvas canvas, Size size, double x) {
    final c = cy(size.height);
    canvas.drawCircle(
      Offset(x + _shadowDx, c + _shadowDy),
      _shadowRadius,
      Paint()
        ..color = _shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowBlur),
    );
    drawIcon(canvas, size, x, c);
  }
}

// ---------------------------------------------------------------------------
// Solar objects
// ---------------------------------------------------------------------------

class Sun extends AstroObject {
  const Sun({required super.time});

  static const _rayLength = 3.0;
  static const _rayCount = 8;

  @override
  String get label => 'Solar Noon';

  Color get color => const Color(0xFFFFE082);

  @override
  double cy(double height) => height * 0.5;

  @override
  void drawIcon(Canvas canvas, Size size, double x, double cy) {
    final rayPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < _rayCount; i++) {
      final angle = (2 * math.pi / _rayCount) * i;
      final inner = kAstroIconRadius + 1.5;
      final outer = inner + _rayLength;
      canvas.drawLine(
        Offset(x + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(x + outer * math.cos(angle), cy + outer * math.sin(angle)),
        rayPaint,
      );
    }

    canvas.drawCircle(Offset(x, cy), kAstroIconRadius, Paint()..color = color);
  }
}

class SunRise extends Sun {
  const SunRise({required super.time});

  @override
  String get label => 'Sunrise';

  @override
  Color get color => const Color(0xFFFFB347);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

class SunSet extends Sun {
  const SunSet({required super.time});

  @override
  String get label => 'Sunset';

  @override
  Color get color => const Color(0xFFFF7043);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

// ---------------------------------------------------------------------------
// Lunar objects
// ---------------------------------------------------------------------------

abstract class Moon extends AstroObject {
  const Moon(
      {required super.time, required this.phase, required this.fraction});

  final MoonPhase phase;
  final double fraction; // illumination 0–1

  Color get color;

  // Skip the base-class circular shadow; _drawDisc paints a shaped one.
  @override
  void draw(Canvas canvas, Size size, double x) {
    drawIcon(canvas, size, x, cy(size.height));
  }

  @override
  void drawIcon(Canvas canvas, Size size, double x, double cy) {
    _drawDisc(canvas, x, cy, color, phase, fraction);
  }

  static const _shadowColor = Color(0x99000000);
  static const _shadowBlur = 3.0;
  static const _shadowDx = 1.5;
  static const _shadowDy = 1.5;

  static void _drawDisc(Canvas canvas, double x, double cy, Color color,
      MoonPhase phase, double fraction) {
    final r = kAstroIconRadius;
    final discRect = Rect.fromCircle(center: Offset(x, cy), radius: r);

    if (fraction < 0.02) {
      // New moon: dim disc only, no shadow.
      canvas.saveLayer(discRect.inflate(1), Paint());
      canvas.drawCircle(
          Offset(x, cy), r, Paint()..color = color.withAlpha(40));
      canvas.restore();
      return;
    }

    // Build paths for shadow and glyph.
    final discPath = Path()..addOval(discRect);
    final darkPath =
        fraction > 0.98 ? null : _darkRegionPath(x, cy, r, fraction, phase);
    final litPath = darkPath != null
        ? Path.combine(PathOperation.difference, discPath, darkPath)
        : discPath;

    // Shaped drop shadow: blurred lit region, shifted down-right.
    canvas.drawPath(
      litPath.shift(const Offset(_shadowDx, _shadowDy)),
      Paint()
        ..color = _shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowBlur),
    );

    // Glyph: full disc with dark region erased via BlendMode.clear.
    canvas.saveLayer(discRect.inflate(2), Paint());
    canvas.drawCircle(
        Offset(x, cy), r, Paint()..color = color.withAlpha(220));
    if (darkPath != null) {
      canvas.drawPath(darkPath, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();
  }

  /// Builds a path covering the unlit (dark) region of the moon disc.
  ///
  /// The dark region is bounded by one half of the disc arc (on the shadow
  /// side) and the terminator arc — an ellipse with rx = |1−2f|·r sharing
  /// the disc's full height. For crescent phases (f < 0.5) the terminator
  /// opens toward the lit side; for gibbous (f > 0.5) it opens toward the
  /// dark side.
  static Path _darkRegionPath(
      double x, double cy, double r, double fraction, MoonPhase phase) {
    final bool waxing = _isWaxing(phase);
    // Terminator semi-axis: 0 at quarter, r at new/full.
    final double rxTerm = (1.0 - 2.0 * fraction).abs() * r;

    final discRect = Rect.fromCircle(center: Offset(x, cy), radius: r);
    final termRect = Rect.fromCenter(
        center: Offset(x, cy), width: 2 * rxTerm, height: 2 * r);

    final path = Path()..moveTo(x, cy - r); // top anchor (shared by disc & terminator)

    if (waxing) {
      // Dark side is LEFT — trace left arc of disc, then close via terminator.
      path.arcTo(discRect, -math.pi / 2, -math.pi, false); // CCW: top→left→bottom
      if (rxTerm >= 0.5) {
        // crescent: close via right arc of terminator (CCW through right apex).
        // gibbous: close via left arc of terminator (CW through left apex).
        path.arcTo(termRect, math.pi / 2,
            fraction < 0.5 ? -math.pi : math.pi, false);
      } else {
        path.lineTo(x, cy - r); // degenerate terminator → straight half-disc
      }
    } else {
      // Dark side is RIGHT — trace right arc of disc, then close via terminator.
      path.arcTo(discRect, -math.pi / 2, math.pi, false); // CW: top→right→bottom
      if (rxTerm >= 0.5) {
        // crescent: close via left arc of terminator (CW through left apex).
        // gibbous: close via right arc of terminator (CCW through right apex).
        path.arcTo(termRect, math.pi / 2,
            fraction < 0.5 ? math.pi : -math.pi, false);
      } else {
        path.lineTo(x, cy - r);
      }
    }

    return path..close();
  }

  static bool _isWaxing(MoonPhase phase) => switch (phase) {
        MoonPhase.newMoon ||
        MoonPhase.waxingCrescent ||
        MoonPhase.firstQuarter ||
        MoonPhase.waxingGibbous =>
          true,
        _ => false,
      };
}

class MoonRise extends Moon {
  const MoonRise(
      {required super.time, required super.phase, required super.fraction});

  @override
  String get label => 'Moonrise';

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

class MoonTransit extends Moon {
  const MoonTransit(
      {required super.time, required super.phase, required super.fraction});

  @override
  String get label => 'Lunar Transit';

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height * 0.5;
}

class MoonSet extends Moon {
  const MoonSet(
      {required super.time, required super.phase, required super.fraction});

  @override
  String get label => 'Moonset';

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}
