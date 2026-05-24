import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/painters/timeline_paint_utils.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// TLDR: Paints hour/half/quarter/5-min tick marks and time labels on the timeline.
/// Sub-tick density scales with zoom (pixelsPerHour). Labels suppressed near now-indicator.
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
    required this.alwaysUse24HourFormat,
    required this.surfaceOpacity,
  });

  final TimelineLayout layout;
  final DateTime now;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double nowIndicatorX;
  final Color tickColor;
  final Color backgroundColor;
  final double fontSize;
  final bool alwaysUse24HourFormat;
  final double surfaceOpacity;

  String _formatHourLabel(DateTime time) {
    return formatTimelineHourTickLabel(
      time,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final pixelsPerHour = layout.pixelsPerSecond * 3600;
    final tickPaint = Paint()
      ..color = tickColor.withValues(alpha: tickColor.a * surfaceOpacity);

    // Blurred black shadow behind ticks aids contrast on dark backgrounds but
    // produces muddy blurs on light ones — skip it for light themes.
    final isLightBg = backgroundColor.computeLuminance() > 0.5;
    final tickShadowPaint = isLightBg
        ? null
        : (Paint()
          ..color = Colors.black.withValues(alpha: 0.35 * surfaceOpacity)
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));

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
        if (tickShadowPaint != null) {
          canvas.drawLine(
              Offset(x, 0), Offset(x, size.height), tickShadowPaint);
        }
        canvas.drawLine(
            Offset(x, 0), Offset(x, size.height), tickPaint..strokeWidth = 2.0);

        if ((x - nowIndicatorX).abs() > suppressionThreshold) {
          TimelinePaintUtils.paintText(
            canvas,
            _formatHourLabel(current),
            TextPaintConfig(
              x: x + 4,
              top: 5,
              fontSize: fontSize * 10 / 11,
              color: tickColor.withValues(alpha: 1.0 * surfaceOpacity),
              backgroundColor: backgroundColor,
            ),
          );
        }
      }

      if (pixelsPerHour >= 80) {
        _paintHalfAndQuarterTicks(canvas, size, current, suppressionThreshold,
            tickPaint, tickShadowPaint);
      }

      if (pixelsPerHour >= 200) {
        _paintFiveMinuteTicks(canvas, size, current, tickPaint);
      }

      current = current.add(const Duration(hours: 1));
    }
  }

  void _paintHalfAndQuarterTicks(
    Canvas canvas,
    Size size,
    DateTime hourTime,
    double suppressionThreshold,
    Paint tickPaint,
    Paint? tickShadowPaint,
  ) {
    final halfTime = hourTime.add(const Duration(minutes: 30));
    final tx = layout.xForTime(halfTime, now);
    if (tx >= 0 && tx <= size.width) {
      if (tickShadowPaint != null) {
        canvas.drawLine(Offset(tx, 0), Offset(tx, size.height * 0.5),
            tickShadowPaint..strokeWidth = 2.0);
      }
      canvas.drawLine(Offset(tx, 0), Offset(tx, size.height * 0.5),
          tickPaint..strokeWidth = 0.75);
      if ((tx - nowIndicatorX).abs() > suppressionThreshold * 0.6) {
        TimelinePaintUtils.paintText(
          canvas,
          formatTimelineHalfHourTickLabel(),
          TextPaintConfig(
            x: tx + 2,
            top: 5,
            fontSize: fontSize * 8 / 11,
            color: tickColor.withValues(alpha: 0.85 * surfaceOpacity),
            backgroundColor: backgroundColor,
          ),
        );
      }
    }

    for (final m in const [15, 45]) {
      final qTime = hourTime.add(Duration(minutes: m));
      final qx = layout.xForTime(qTime, now);
      if (qx >= 0 && qx <= size.width) {
        if (tickShadowPaint != null) {
          canvas.drawLine(Offset(qx, 0), Offset(qx, size.height * 0.25),
              tickShadowPaint..strokeWidth = 1.5);
        }
        canvas.drawLine(Offset(qx, 0), Offset(qx, size.height * 0.25),
            tickPaint..strokeWidth = 0.5);
      }
    }
  }

  void _paintFiveMinuteTicks(
      Canvas canvas, Size size, DateTime hourTime, Paint tickPaint) {
    for (var m = 5; m < 60; m += 5) {
      if (m % 15 == 0) continue;
      final tx = layout.xForTime(hourTime.add(Duration(minutes: m)), now);
      if (tx >= 0 && tx <= size.width) {
        canvas.drawLine(
            Offset(tx, 0), Offset(tx, 4), tickPaint..strokeWidth = 0.5);
      }
    }
  }
}

String formatTimelineHourTickLabel(
  DateTime time, {
  required bool alwaysUse24HourFormat,
}) {
  if (alwaysUse24HourFormat) {
    return time.hour.toString().padLeft(2, '0');
  }

  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final suffix = time.hour < 12 ? 'am' : 'pm';
  return '$hour$suffix';
}

String formatTimelineHalfHourTickLabel() => '30';
