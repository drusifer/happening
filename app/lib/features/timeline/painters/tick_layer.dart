import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/painters/timeline_paint_utils.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

class TickLayer implements TimelineLayer {
  const TickLayer({
    required this.layout,
    required this.now,
    required this.windowStart,
    required this.windowEnd,
    required this.nowIndicatorX,
    required this.tickColor,
    required this.backgroundColor,
    required this.fontSize,
  });

  final TimelineLayout layout;
  final DateTime now;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double nowIndicatorX;
  final Color tickColor;
  final Color backgroundColor;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final pixelsPerHour = layout.pixelsPerSecond * 3600;
    final tickPaint = Paint()..color = tickColor;

    var current = DateTime(
      windowStart.year,
      windowStart.month,
      windowStart.day,
      windowStart.hour,
    );

    while (!current.isAfter(windowEnd)) {
      final x = layout.xForTime(current, now);
      final suppressionThreshold = (fontSize / 15.0) * 40;

      if (x >= 0 && x <= size.width) {
        canvas.drawLine(
            Offset(x, 0), Offset(x, size.height), tickPaint..strokeWidth = 2.0);

        if ((x - nowIndicatorX).abs() > suppressionThreshold) {
          final h = current.hour;
          final label =
              '${h % 12 == 0 ? 12 : h % 12}${h < 12 || h >= 24 ? 'am' : 'pm'}';
          TimelinePaintUtils.paintText(
            canvas, label, x + 4, 1,
            fontSize: fontSize * 10 / 11,
            color: tickColor.withValues(alpha: 1.0),
            backgroundColor: backgroundColor,
          );
        }
      }

      if (pixelsPerHour >= 80) {
        final tickTime = current.add(const Duration(minutes: 30));
        final tx = layout.xForTime(tickTime, now);
        if (tx >= 0 && tx <= size.width) {
          canvas.drawLine(Offset(tx, 0), Offset(tx, size.height * 0.5),
              tickPaint..strokeWidth = 0.75);
          if ((tx - nowIndicatorX).abs() > suppressionThreshold * 0.6) {
            TimelinePaintUtils.paintText(
              canvas, ':30', tx + 2, 1,
              fontSize: fontSize * 8 / 11,
              color: tickColor.withValues(alpha: 0.85),
              backgroundColor: backgroundColor,
            );
          }
        }
      }

      if (pixelsPerHour >= 80) {
        for (final m in const [15, 45]) {
          final tickTime = current.add(Duration(minutes: m));
          final tx = layout.xForTime(tickTime, now);
          if (tx >= 0 && tx <= size.width) {
            canvas.drawLine(Offset(tx, 0), Offset(tx, size.height * 0.25),
                tickPaint..strokeWidth = 0.5);
          }
        }
      }

      if (pixelsPerHour >= 200) {
        for (var m = 5; m < 60; m += 5) {
          if (m % 15 == 0) continue;
          final tickTime = current.add(Duration(minutes: m));
          final tx = layout.xForTime(tickTime, now);
          if (tx >= 0 && tx <= size.width) {
            canvas.drawLine(
                Offset(tx, 0), Offset(tx, 4), tickPaint..strokeWidth = 0.5);
          }
        }
      }

      current = current.add(const Duration(hours: 1));
    }
  }
}
