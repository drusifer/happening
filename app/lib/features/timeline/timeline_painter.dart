/// CustomPainter for the timeline strip.
///
/// TLDR:
/// Overview: Low-level canvas painting of events and indicators.
/// Problem: Need a custom layout that can smoothly animate at 1Hz.
/// Solution: Paints rectangles, labels, and the NowIndicator based on TimelineLayout.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

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
  });

  final List<CalendarEvent> events;
  final DateTime now;
  final double nowIndicatorX;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? hoveredEventId;

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

  void _paintEvents(Canvas canvas, Size size, TimelineLayout layout) {
    const blockHeight = 28.0;
    final top = (size.height - blockHeight) / 2;
    final rr = RRect.fromLTRBR;

    for (final event in events) {
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) continue;

      final x = layout.xForTime(event.startTime, now);
      final endX = layout.xForTime(event.endTime, now);
      final w = (endX - x).clamp(3.0, double.infinity);

      final isHovered = event.id == hoveredEventId;
      final color = event.color.withOpacity(isHovered ? 1.0 : 0.82);
      final rect = rr(x, top, x + w, top + blockHeight, const Radius.circular(4));

      canvas.drawRRect(rect, Paint()..color = color);

      if (w > 36) {
        _paintEventLabel(canvas, event.title, x + 4, top, w - 8, blockHeight);
      }
    }
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
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
