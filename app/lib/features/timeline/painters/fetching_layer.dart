import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';

/// TLDR: Paints a "Fetching calendars..." overlay when calendar data has not
/// yet arrived. No-ops once isLoading is false so the compositor loop is
/// unconditional.
class FetchingLayer implements TimelineLayer {
  const FetchingLayer({
    required this.isLoading,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
  });

  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isLoading) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'Fetching calendars...',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: fontSize,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }
}
