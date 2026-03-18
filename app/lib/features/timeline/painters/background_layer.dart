import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';

class BackgroundLayer implements TimelineLayer {
  const BackgroundLayer({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = color,
    );
  }
}
