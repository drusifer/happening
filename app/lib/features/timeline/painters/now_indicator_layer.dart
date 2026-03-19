import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';

/// TLDR: Paints the vertical "now" line with shadow and top/bottom triangle markers.
class NowIndicatorLayer implements TimelineLayer {
  const NowIndicatorLayer({
    required this.nowIndicatorX,
    required this.color,
  });

  final double nowIndicatorX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Shadow
    canvas.drawLine(
      Offset(nowIndicatorX, 0),
      Offset(nowIndicatorX, size.height),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // Line
    canvas.drawLine(
      Offset(nowIndicatorX, 0),
      Offset(nowIndicatorX, size.height),
      Paint()
        ..color = color
        ..strokeWidth = 2.5,
    );

    final triPaint = Paint()..color = color;

    // Top triangle
    canvas.drawPath(
      Path()
        ..moveTo(nowIndicatorX - 6, 0)
        ..lineTo(nowIndicatorX + 6, 0)
        ..lineTo(nowIndicatorX, 8)
        ..close(),
      triPaint,
    );

    // Bottom triangle
    canvas.drawPath(
      Path()
        ..moveTo(nowIndicatorX - 6, size.height)
        ..lineTo(nowIndicatorX + 6, size.height)
        ..lineTo(nowIndicatorX, size.height - 8)
        ..close(),
      triPaint,
    );
  }
}
