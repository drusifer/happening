import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';

/// Clip tolerance shared by all astro icons.
const kAstroIconRadius = 5.5;

// ---------------------------------------------------------------------------
// Base
// ---------------------------------------------------------------------------

abstract class AstroObject {
  const AstroObject({required this.time});

  final DateTime time;

  static const _shadowBlur = 3.0;
  static const _shadowColor = Color(0x99000000);
  static const _shadowRadius = kAstroIconRadius + 3.0;
  // Light source is top-left, so shadows fall down and to the right.
  static const _shadowDx = 1.5;
  static const _shadowDy = 1.5;

  /// Vertical centre of the disc in canvas coordinates.
  double cy(double height);

  /// Draws the icon body (no shadow — handled by [draw]).
  void drawIcon(Canvas canvas, Size size, double x, double cy);

  /// Draws drop shadow then delegates to [drawIcon].
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

/// Solar noon — full disc, vertically centred.
class Sun extends AstroObject {
  const Sun({required super.time});

  static const _rayLength = 3.0;
  static const _rayCount = 8;

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

/// Sunrise — disc above the bottom strip edge.
class SunRise extends Sun {
  const SunRise({required super.time});

  @override
  Color get color => const Color(0xFFFFB347);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

/// Sunset — disc above the bottom strip edge.
class SunSet extends Sun {
  const SunSet({required super.time});

  @override
  Color get color => const Color(0xFFFF7043);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

// ---------------------------------------------------------------------------
// Lunar objects
// ---------------------------------------------------------------------------

/// Abstract base for moon markers.
abstract class Moon extends AstroObject {
  const Moon({required super.time, required this.phase});

  final MoonPhase phase;

  Color get color;

  @override
  void drawIcon(Canvas canvas, Size size, double x, double cy) {
    _drawDisc(canvas, x, cy, color, phase);
  }

  static void _drawDisc(
      Canvas canvas, double x, double cy, Color color, MoonPhase phase) {
    // Isolated layer so BlendMode.clear punches the dark side to transparency,
    // letting the sky gradient show through.
    final bounds =
        Rect.fromCircle(center: Offset(x, cy), radius: kAstroIconRadius * 2.2);
    canvas.saveLayer(bounds, Paint());

    // New moon: faint outline only (disc is essentially unlit).
    final alpha = phase == MoonPhase.newMoon ? 40 : 220;
    canvas.drawCircle(
        Offset(x, cy), kAstroIconRadius, Paint()..color = color.withAlpha(alpha));

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

/// Moonrise — disc at bottom strip edge.
class MoonRise extends Moon {
  const MoonRise({required super.time, required super.phase});

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}

/// Lunar transit — full disc centred vertically.
class MoonTransit extends Moon {
  const MoonTransit({required super.time, required super.phase});

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height * 0.5;
}

/// Moonset — disc at bottom strip edge.
class MoonSet extends Moon {
  const MoonSet({required super.time, required super.phase});

  @override
  Color get color => const Color(0xFFFFFBF0);

  @override
  double cy(double height) => height - kAstroIconRadius - 6;
}
