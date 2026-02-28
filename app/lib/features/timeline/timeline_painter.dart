// CustomPainter for the timeline strip.
//
// TLDR:
// Overview: Low-level canvas painting of events and indicators.
// Problem: Need a custom layout that can smoothly animate at 1Hz.
// Solution: Paints rectangles, labels, and the NowIndicator based on TimelineLayout.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Paints the proportional event timeline onto the strip canvas.
class TimelinePainter extends CustomPainter {
  TimelinePainter({
    required this.events,
    required this.now,
    required this.nowIndicatorX,
    required this.windowStart,
    required this.windowEnd,
    this.hoveredEventId,
    this.fontSize = 11,
  });

  final List<CalendarEvent> events;
  final DateTime now;
  final double nowIndicatorX;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? hoveredEventId;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TimelineLayout(
      stripWidth: size.width,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    _paintBackground(canvas, size);
    _paintPastOverlay(canvas, size, layout);
    _paintTicks(canvas, size, layout);
    _paintEvents(canvas, size, layout);
    _paintNowIndicator(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF1A1A2E),
    );
  }

  void _paintPastOverlay(Canvas canvas, Size size, TimelineLayout layout) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, nowIndicatorX, size.height),
      Paint()..color = const Color(0x33000000),
    );
  }

  void _paintTicks(Canvas canvas, Size size, TimelineLayout layout) {
    final pixelsPerHour = layout.pixelsPerSecond * 3600;
    final startHour = windowStart.hour;
    final endHour = windowEnd.hour + (windowEnd.day > windowStart.day ? 24 : 0);

    final tickPaint = Paint()..color = Colors.white24;

    for (var h = startHour; h <= endHour; h++) {
      final hourTime =
          DateTime(windowStart.year, windowStart.month, windowStart.day, h);

      // Hour ticks
      if (layout.isVisible(hourTime)) {
        final x = layout.xForTime(hourTime, now);
        canvas.drawLine(
            Offset(x, 0), Offset(x, 8), tickPaint..strokeWidth = 1.0);

        // Hour label (e.g., "10am")
        if ((x - nowIndicatorX).abs() > 30) {
          final label =
              '${h % 12 == 0 ? 12 : h % 12}${h < 12 || h >= 24 ? 'am' : 'pm'}';
          _paintText(canvas, label, x + 4, 1,
              fontSize: 9, color: Colors.white38);
        }
      }

      // 15-min ticks
      if (pixelsPerHour >= 80) {
        for (var m = 15; m < 60; m += 15) {
          final tickTime = hourTime.add(Duration(minutes: m));
          if (layout.isVisible(tickTime)) {
            final x = layout.xForTime(tickTime, now);
            canvas.drawLine(
                Offset(x, 0), Offset(x, 4), tickPaint..strokeWidth = 0.5);
          }
        }
      }

      // 5-min ticks
      if (pixelsPerHour >= 200) {
        for (var m = 5; m < 60; m += 5) {
          if (m % 15 == 0) continue;
          final tickTime = hourTime.add(Duration(minutes: m));
          if (layout.isVisible(tickTime)) {
            final x = layout.xForTime(tickTime, now);
            canvas.drawLine(
                Offset(x, 0), Offset(x, 2), tickPaint..strokeWidth = 0.5);
          }
        }
      }
    }
  }

  void _paintEvents(Canvas canvas, Size size, TimelineLayout layout) {
    const blockHeight = 28.0;
    final top = (size.height - blockHeight) / 2;

    // Track label positions to prevent overlap
    final renderedLabelX = <double>[];

    for (final event in events) {
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) {
        continue;
      }

      final x = layout.xForTime(event.startTime, now);
      final endX = layout.xForTime(event.endTime, now);
      final w = (endX - x).clamp(3.0, double.infinity);

      final isHovered = event.id == hoveredEventId;
      final color = event.color.withValues(alpha: isHovered ? 1.0 : 0.82);
      final rect = RRect.fromLTRBR(
          x, top, x + w, top + blockHeight, const Radius.circular(4));

      canvas.drawRRect(rect, Paint()..color = color);

      // Event Start Time (S3-15)
      bool timeLabeled = false;
      if (w >= 45 && (x - nowIndicatorX).abs() > 20) {
        final timeStr =
            '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';

        // Proximity dedup
        bool overlap = false;
        for (final prevX in renderedLabelX) {
          if ((x - prevX).abs() < 35) {
            overlap = true;
            break;
          }
        }

        if (!overlap) {
          _paintText(canvas, timeStr, x + 4, top + 2,
              fontSize: 8, color: Colors.white70);
          renderedLabelX.add(x);
          timeLabeled = true;
        }
      }

      // Title label
      if (w > 36) {
        final labelTop = timeLabeled ? top + 10 : top;
        final labelHeight = timeLabeled ? blockHeight - 10 : blockHeight;
        _paintEventLabel(
            canvas, event.title, x + 4, labelTop, w - 8, labelHeight);
      }
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    double x,
    double top, {
    required double fontSize,
    required Color color,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, top));
  }

  void _paintEventLabel(
    Canvas canvas,
    String title,
    double x,
    double top,
    double maxWidth,
    double height,
  ) {
    final span = TextSpan(
      text: title,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, top + (height - painter.height) / 2));
  }

  void _paintNowIndicator(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(nowIndicatorX, 0),
      Offset(nowIndicatorX, size.height),
      linePaint,
    );

    final triPaint = Paint()..color = Colors.redAccent;
    final path = Path()
      ..moveTo(nowIndicatorX - 5, 0)
      ..lineTo(nowIndicatorX + 5, 0)
      ..lineTo(nowIndicatorX, 7)
      ..close();
    canvas.drawPath(path, triPaint);
  }

  @override
  bool shouldRepaint(TimelinePainter old) =>
      old.now != now ||
      old.events != events ||
      old.hoveredEventId != hoveredEventId;
}
