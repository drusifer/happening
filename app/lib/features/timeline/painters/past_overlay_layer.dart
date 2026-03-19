import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';

/// TLDR: Draws a semi-transparent overlay left of the now-indicator to shade past time.
class PastOverlayLayer implements TimelineLayer {
  const PastOverlayLayer({required this.nowIndicatorX, required this.color});
  final double nowIndicatorX;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, nowIndicatorX, size.height),
      Paint()..color = color,
    );
  }
}
