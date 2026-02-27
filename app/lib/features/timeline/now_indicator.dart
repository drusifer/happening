/// Visual marker for the current moment.
///
/// TLDR:
/// Overview: A red vertical line that marks "Now" on the timeline strip.
/// Problem: Need a clear reference point for the user's current time.
/// Solution: Implements a CustomPainter with a red line and a triangle cap.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Fixed vertical marker that represents the current moment on the strip.
class NowIndicator extends StatelessWidget {
  const NowIndicator({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(2, height),
      painter: _NowIndicatorPainter(),
    );
  }
}

class _NowIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Triangle cap at top
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, 6)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
