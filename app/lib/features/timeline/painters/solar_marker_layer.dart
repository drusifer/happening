import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Draws sunrise, sunset, and solar-noon markers on the timeline.
///
/// All icons clip to [0, stripWidth] — no icon is drawn if outside the window.
class SolarMarkerLayer implements TimelineLayer {
  static const _sunriseColor = Color(0xFFFFB347);
  static const _sunsetColor = Color(0xFFFF7043);
  static const _noonColor = Color(0xFFFFE082);
  static const _iconRadius = 6.0;
  static const _rayLength = 4.0;
  static const _rayCount = 8;

  const SolarMarkerLayer({
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

    _drawSunIcon(canvas, size, astroData.sunrise, cy, _sunriseColor);
    _drawSunIcon(canvas, size, astroData.sunset, cy, _sunsetColor);
    _drawNoonTick(canvas, size, astroData.solarNoon, cy);
  }

  void _drawSunIcon(
      Canvas canvas, Size size, DateTime time, double cy, Color color) {
    final x = layout.xForTime(time, now);
    if (x < -_iconRadius || x > size.width + _iconRadius) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Circle body.
    canvas.drawCircle(Offset(x, cy), _iconRadius, paint);

    // Radiating rays.
    final rayPaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < _rayCount; i++) {
      final angle = (2 * math.pi / _rayCount) * i;
      final inner = _iconRadius + 2;
      final outer = inner + _rayLength;
      canvas.drawLine(
        Offset(x + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(x + outer * math.cos(angle), cy + outer * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawNoonTick(Canvas canvas, Size size, DateTime time, double cy) {
    final x = layout.xForTime(time, now);
    if (x < 0 || x > size.width) return;

    final tickPaint = Paint()
      ..color = _noonColor
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(x, cy - _iconRadius),
      Offset(x, cy + _iconRadius),
      tickPaint,
    );

    // Small "12" label.
    final tp = TextPainter(
      text: const TextSpan(
        text: '☉',
        style: TextStyle(color: _noonColor, fontSize: 7),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, cy - _iconRadius - tp.height));
  }
}
