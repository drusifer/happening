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

  @override
  void drawIcon(Canvas canvas, Size size, double x, double cy) {
    _drawDisc(canvas, x, cy, color, phase);
  }

  static void _drawDisc(
      Canvas canvas, double x, double cy, Color color, MoonPhase phase) {
    final bounds =
        Rect.fromCircle(center: Offset(x, cy), radius: kAstroIconRadius * 2.2);
    canvas.saveLayer(bounds, Paint());

    final alpha = phase == MoonPhase.newMoon ? 40 : 220;
    canvas.drawCircle(Offset(x, cy), kAstroIconRadius,
        Paint()..color = color.withAlpha(alpha));

    canvas.drawCircle(
      Offset(x + _shadowOffsetForPhase(phase), cy),
      kAstroIconRadius * 0.95,
      Paint()..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  static double _shadowOffsetForPhase(MoonPhase phase) => switch (phase) {
        MoonPhase.newMoon => kAstroIconRadius * 2.5,
        MoonPhase.waxingCrescent => -kAstroIconRadius * 1.2,
        MoonPhase.firstQuarter => -kAstroIconRadius,
        MoonPhase.waxingGibbous => -kAstroIconRadius * 0.5,
        MoonPhase.full => kAstroIconRadius * 2,
        MoonPhase.waningGibbous => kAstroIconRadius * 0.5,
        MoonPhase.lastQuarter => kAstroIconRadius,
        MoonPhase.waningCrescent => kAstroIconRadius * 1.2,
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
