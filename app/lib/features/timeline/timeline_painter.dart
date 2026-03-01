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
import 'package:flutter/semantics.dart';
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
    _paintEvents(canvas, size, layout);
    _paintTicks(canvas, size, layout);   // After events so ticks aren't buried
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
    final tickPaint = Paint()..color = Colors.white70;

    // Start at the beginning of the hour containing windowStart
    var current = DateTime(
      windowStart.year,
      windowStart.month,
      windowStart.day,
      windowStart.hour,
    );

    // Loop until we pass windowEnd
    while (!current.isAfter(windowEnd)) {
      final x = layout.xForTime(current, now);

      if (x >= 0 && x <= size.width) {
        // Hour ticks — full height so they aren't buried by events
        canvas.drawLine(
            Offset(x, 0), Offset(x, size.height), tickPaint..strokeWidth = 1.5);

        // Hour label (e.g., "10am")
        if ((x - nowIndicatorX).abs() > 30) {
          final h = current.hour;
          final label =
              '${h % 12 == 0 ? 12 : h % 12}${h < 12 || h >= 24 ? 'am' : 'pm'}';
          _paintText(canvas, label, x + 4, 1,
              fontSize: fontSize * 9 / 11, color: Colors.white38);
        }
      }

      // 30-min ticks: half height (S4-17)
      if (pixelsPerHour >= 80) {
        final tickTime = current.add(const Duration(minutes: 30));
        final tx = layout.xForTime(tickTime, now);
        if (tx >= 0 && tx <= size.width) {
          canvas.drawLine(
              Offset(tx, 0), Offset(tx, 15), tickPaint..strokeWidth = 0.75);
          if ((tx - nowIndicatorX).abs() > 20) {
            _paintText(canvas, ':30', tx + 2, 1,
                fontSize: fontSize * 7 / 11, color: Colors.white24);
          }
        }
      }

      // 15-min ticks: quarter height (S4-17)
      if (pixelsPerHour >= 80) {
        for (final m in const [15, 45]) {
          final tickTime = current.add(Duration(minutes: m));
          final tx = layout.xForTime(tickTime, now);
          if (tx >= 0 && tx <= size.width) {
            canvas.drawLine(
                Offset(tx, 0), Offset(tx, 8), tickPaint..strokeWidth = 0.5);
          }
        }
      }

      // 5-min ticks
      if (pixelsPerHour >= 200) {
        for (var m = 5; m < 60; m += 5) {
          if (m % 15 == 0) continue;
          final tickTime = current.add(Duration(minutes: m));
          final tx = layout.xForTime(tickTime, now);
          if (tx >= 0 && tx <= size.width) {
            canvas.drawLine(
                Offset(tx, 0), Offset(tx, 2), tickPaint..strokeWidth = 0.5);
          }
        }
      }

      current = current.add(const Duration(hours: 1));
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

      if (event.isTask) {
        _paintTaskMarker(canvas, x, top + blockHeight / 2, color);
        continue; // ◇ is the only visual for tasks — skip time/title labels
      } else {
        final rect = RRect.fromLTRBR(
            x, top, x + w, top + blockHeight, const Radius.circular(4));
        canvas.drawRRect(rect, Paint()..color = color);
      }

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
              fontSize: fontSize * 8 / 11, color: Colors.white70);
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

    // S4-19: Gap duration labels between adjacent events
    for (final gap in layout.gapsBetween(events, now)) {
      final label = gap.minutes >= 60
          ? '${gap.minutes ~/ 60}h${gap.minutes % 60 > 0 ? '${gap.minutes % 60}m' : ''}'
          : '${gap.minutes}m';
      final span = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white38,
          fontSize: fontSize * 8 / 11,
          fontWeight: FontWeight.w400,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas,
          Offset(gap.centerX - tp.width / 2, (size.height - tp.height) / 2));
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

  /// Renders a task as a small diamond (◇) centered on the strip.
  void _paintTaskMarker(Canvas canvas, double x, double cy, Color color) {
    const half = 6.0;
    final path = Path()
      ..moveTo(x, cy - half)
      ..lineTo(x + half, cy)
      ..lineTo(x, cy + half)
      ..lineTo(x - half, cy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75);
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

  /// Semantic nodes for canvas content — makes ticks, events, and task
  /// diamonds queryable by integration tests via [find.bySemanticsLabel].
  ///
  /// Uses the SAME pixel-bounds condition as [_paintTicks] / [_paintEvents]
  /// so that a painting regression also breaks the semantics tree and the
  /// integration test fails.
  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
    final layout = TimelineLayout(
      stripWidth: size.width,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    final nodes = <CustomPainterSemantics>[];
    const blockHeight = 28.0;
    final top = (size.height - blockHeight) / 2;

    // ── Hour ticks + sub-ticks ─────────────────────────────────────────────
    // Pixel-bounds check — mirrors _paintTicks so both regress together.
    final pixelsPerHour = layout.pixelsPerSecond * 3600;
    var current = DateTime(
      windowStart.year,
      windowStart.month,
      windowStart.day,
      windowStart.hour,
    );

    while (!current.isAfter(windowEnd)) {
      final x = layout.xForTime(current, now);
      if (x >= 0 && x <= size.width) {
        final h = current.hour;
        final label =
            '${h % 12 == 0 ? 12 : h % 12}${h < 12 || h >= 24 ? 'am' : 'pm'}';
        nodes.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(x - 1, 0, 2, size.height),
          properties: SemanticsProperties(
              label: 'tick-$label', textDirection: TextDirection.ltr),
        ));
      }

      // 30-min sub-ticks — only emitted when pixelsPerHour >= 80, mirroring
      // the paint condition exactly so a threshold regression breaks both.
      if (pixelsPerHour >= 80) {
        final tickTime = current.add(const Duration(minutes: 30));
        final tx = layout.xForTime(tickTime, now);
        if (tx >= 0 && tx <= size.width) {
          final hh = current.hour.toString().padLeft(2, '0');
          nodes.add(CustomPainterSemantics(
            rect: Rect.fromLTWH(tx - 1, 0, 2, 15),
            properties: SemanticsProperties(
                label: 'subtick-$hh:30', textDirection: TextDirection.ltr),
          ));
        }
      }
      current = current.add(const Duration(hours: 1));
    }

    // ── Now indicator ──────────────────────────────────────────────────────
    nodes.add(CustomPainterSemantics(
      rect: Rect.fromLTWH(nowIndicatorX - 1, 0, 2, size.height),
      properties: SemanticsProperties(
          label: 'now-indicator', textDirection: TextDirection.ltr),
    ));

    // ── Events and tasks ───────────────────────────────────────────────────
    for (final event in events) {
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) continue;
      final x = layout.xForTime(event.startTime, now);
      final endX = layout.xForTime(event.endTime, now);
      final w = (endX - x).clamp(3.0, double.infinity);

      if (event.isTask) {
        // Task: ◇ diamond — label distinguishes it from regular event blocks.
        final cy = top + blockHeight / 2;
        nodes.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(x - 6, cy - 6, 12, 12),
          properties: SemanticsProperties(
              label: 'task: ${event.title}',
              textDirection: TextDirection.ltr),
        ));
      } else {
        nodes.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(x, top, w, blockHeight),
          properties: SemanticsProperties(
              label: 'event: ${event.title}',
              textDirection: TextDirection.ltr),
        ));
      }
    }

    // ── Gap duration labels ────────────────────────────────────────────────
    // Mirrors _paintEvents gap loop — label format must match paint output.
    for (final gap in layout.gapsBetween(events, now)) {
      final label = gap.minutes >= 60
          ? '${gap.minutes ~/ 60}h${gap.minutes % 60 > 0 ? '${gap.minutes % 60}m' : ''}'
          : '${gap.minutes}m';
      nodes.add(CustomPainterSemantics(
        rect: Rect.fromLTWH(gap.centerX - 20, 0, 40, size.height),
        properties: SemanticsProperties(
            label: 'gap: $label', textDirection: TextDirection.ltr),
      ));
    }

    return nodes;
  };
}
