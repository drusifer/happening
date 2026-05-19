import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Draws moonrise and moonset icons with directional arrows on the timeline.
///
/// Each icon shows the current moon phase silhouette. An upward arrow indicates
/// rise; a downward arrow indicates set. Icons clip to [0, stripWidth].
class LunarMarkerLayer implements TimelineLayer {
  static const _moonColor = Color(0xFFE8DCC8);
  static const _moonSetColor = Color(0xFF9E9278);
  static const _iconRadius = 5.5;
  static const _arrowSize = 3.5;

  const LunarMarkerLayer({
    required this.astroData,
    required this.layout,
    required this.now,
  });

  final AstroData astroData;
  final TimelineLayout layout;
  final DateTime now;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height * 0.5;

    if (astroData.moonrise != null) {
      final x = layout.xForTime(astroData.moonrise!, now);
      if (x >= -_iconRadius && x <= size.width + _iconRadius) {
        _drawMoonIcon(canvas, x, cy, _moonColor, astroData.phase);
        _drawArrow(canvas, x, cy, up: true, color: _moonColor);
      }
    }

    if (astroData.moonset != null) {
      final x = layout.xForTime(astroData.moonset!, now);
      if (x >= -_iconRadius && x <= size.width + _iconRadius) {
        _drawMoonIcon(canvas, x, cy, _moonSetColor, astroData.phase);
        _drawArrow(canvas, x, cy, up: false, color: _moonSetColor);
      }
    }
  }

  void _drawMoonIcon(
      Canvas canvas, double x, double cy, Color color, MoonPhase phase) {
    final paint = Paint()..color = color.withAlpha(220);
    final darkPaint = Paint()..color = const Color(0xFF0A0E1A).withAlpha(200);

    // Full outer circle.
    canvas.drawCircle(Offset(x, cy), _iconRadius, paint);

    // Shadow circle to create crescent / phase effect.
    final shadowOffset = _shadowOffsetForPhase(phase);
    canvas.drawCircle(
        Offset(x + shadowOffset, cy), _iconRadius * 0.95, darkPaint);
  }

  /// Returns horizontal offset of the shadow circle to create the phase silhouette.
  ///
  /// Negative = shadow left (waxing); positive = shadow right (waning).
  double _shadowOffsetForPhase(MoonPhase phase) {
    return switch (phase) {
      MoonPhase.newMoon => 0,
      MoonPhase.waxingCrescent => -_iconRadius * 1.2,
      MoonPhase.firstQuarter => -_iconRadius,
      MoonPhase.waxingGibbous => -_iconRadius * 0.5,
      MoonPhase.full => _iconRadius * 2,
      MoonPhase.waningGibbous => _iconRadius * 0.5,
      MoonPhase.lastQuarter => _iconRadius,
      MoonPhase.waningCrescent => _iconRadius * 1.2,
    };
  }

  void _drawArrow(Canvas canvas, double x, double cy,
      {required bool up, required Color color}) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final tipY = up
        ? cy - _iconRadius - 2 - _arrowSize
        : cy + _iconRadius + 2 + _arrowSize;
    final baseY = up ? cy - _iconRadius - 2 : cy + _iconRadius + 2;

    final path = Path()
      ..moveTo(x, tipY)
      ..lineTo(x - _arrowSize * 0.7, baseY)
      ..lineTo(x + _arrowSize * 0.7, baseY)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }
}
