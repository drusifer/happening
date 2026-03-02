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
    required this.backgroundColor,
    required this.pastOverlayColor,
    required this.nowLineColor,
    required this.tickColor,
    this.hoveredEventId,
    this.collidingIds = const {},
    this.countdownColor = Colors.white,
    this.fontSize = 11,
  });

  final List<CalendarEvent> events;
  final DateTime now;
  final double nowIndicatorX;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String? hoveredEventId;
  final Set<String> collidingIds;
  final Color countdownColor;
  final double fontSize;

  // S5-B6: Theme colors
  final Color backgroundColor;
  final Color pastOverlayColor;
  final Color nowLineColor;
  final Color tickColor;

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
      Paint()..color = backgroundColor,
    );
  }

  void _paintPastOverlay(Canvas canvas, Size size, TimelineLayout layout) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, nowIndicatorX, size.height),
      Paint()..color = pastOverlayColor,
    );
  }

  void _paintTicks(Canvas canvas, Size size, TimelineLayout layout) {
    final pixelsPerHour = layout.pixelsPerSecond * 3600;
    final tickPaint = Paint()..color = tickColor;

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
      final suppressionThreshold = (fontSize / 15.0) * 40;

      if (x >= 0 && x <= size.width) {
        // Hour ticks — full height so they aren't buried by events
        canvas.drawLine(
            Offset(x, 0), Offset(x, size.height), tickPaint..strokeWidth = 1.5);

        // Hour label (e.g., "10am")
        if ((x - nowIndicatorX).abs() > suppressionThreshold) {
          final h = current.hour;
          final label =
              '${h % 12 == 0 ? 12 : h % 12}${h < 12 || h >= 24 ? 'am' : 'pm'}';
          _paintText(canvas, label, x + 4, 1,
              fontSize: fontSize * 9 / 11, color: tickColor.withOpacity(0.7));
        }
      }

      // 30-min ticks: half height (S4-17)
      if (pixelsPerHour >= 80) {
        final tickTime = current.add(const Duration(minutes: 30));
        final tx = layout.xForTime(tickTime, now);
        if (tx >= 0 && tx <= size.width) {
          canvas.drawLine(
              Offset(tx, 0), Offset(tx, size.height * 0.5), tickPaint..strokeWidth = 0.75);
          if ((tx - nowIndicatorX).abs() > suppressionThreshold * 0.6) {
            _paintText(canvas, ':30', tx + 2, 1,
                fontSize: fontSize * 7 / 11, color: tickColor.withOpacity(0.6));
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
                Offset(tx, 0), Offset(tx, size.height * 0.25), tickPaint..strokeWidth = 0.5);
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
                Offset(tx, 0), Offset(tx, 4), tickPaint..strokeWidth = 0.5);
          }
        }
      }

      current = current.add(const Duration(hours: 1));
    }
  }

  void _paintEvents(Canvas canvas, Size size, TimelineLayout layout) {
    final blockHeight = size.height - 2;
    const top = 1.0;

    // Sort by duration descending: shorter events on top (paint last)
    final renderList = [...events]..sort((a, b) => b.duration.compareTo(a.duration));

    for (final event in renderList) {
      // S5-FIX: Allow point-events (start == end) by ensuring we render if EITHER
      // start or end is visible. (logic: skip only if BOTH are outside)
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) {
        continue;
      }

      final x = layout.xForTime(event.startTime, now);
      final endX = layout.xForTime(event.endTime, now);
      
      // For tasks with no duration, we use a fixed minimum width for the block 
      // but allow the title to render.
      final w = (endX - x).abs().clamp(event.isTask ? 0.0 : 3.0, double.infinity);

      final isHovered = event.id == hoveredEventId;
      final isColliding = collidingIds.contains(event.id);
      
      // S5-D3: Completed tasks → green
      Color color = event.isCompleted 
          ? const Color(0xFF51B749) // Basil Green
          : event.color;
      
      // Overlapping events get 50% transparency (unless hovered)
      final double targetOpacity = isHovered ? 1.0 : (isColliding ? 0.5 : 0.82);
      color = color.withOpacity(targetOpacity);

      if (event.isTask) {
        _paintTaskMarker(canvas, x, endX, top + blockHeight * 0.4, color);
      } else {
        final rect = RRect.fromLTRBR(
            x, top, x + w, top + blockHeight, const Radius.circular(4));
        canvas.drawRRect(rect, Paint()..color = color);

        // S5-D2: Collision red outline (sections only)
        if (isColliding) {
          for (final other in events) {
            if (other.id == event.id || other.isTask) continue;

            // Intersection of [event.start, event.end] and [other.start, other.end]
            final start = event.startTime.isAfter(other.startTime)
                ? event.startTime
                : other.startTime;
            final end = event.endTime.isBefore(other.endTime)
                ? event.endTime
                : other.endTime;

            if (start.isBefore(end)) {
              final ox = layout.xForTime(start, now);
              final oEndX = layout.xForTime(end, now);
              final ow = (oEndX - ox).clamp(2.0, double.infinity);

              canvas.drawRRect(
                RRect.fromLTRBR(ox, top, ox + ow, top + blockHeight,
                    const Radius.circular(4)),
                Paint()
                  ..color = Colors.red
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.0,
              );
            }
          }
        }
      }

      // Title label
      final hasDuration = event.endTime.isAfter(event.startTime);
      final titleThreshold = (fontSize / 15.0) * 36;
      
      // Always try to show title for point-tasks (start == end),
      // otherwise use the duration-based width threshold.
      if (!hasDuration || w > titleThreshold) {
        final taskDiamondWidth = fontSize * 0.5;
        final labelX = event.isTask ? x + taskDiamondWidth + 4 : x + 4;
        
        // Use full remaining strip width for point-tasks to prevent clipping.
        final labelWidth = (!hasDuration && event.isTask) 
            ? size.width - labelX - 8
            : (event.isTask ? w - taskDiamondWidth - 8 : w - 8);

        if (labelWidth > 10) {
          _paintEventLabel(
              canvas, event.title, labelX, top, labelWidth, blockHeight);
        }
      }
    }

    // S4-19: Gap duration labels between adjacent events
    for (final gap in layout.gapsBetween(events, now)) {
      final label = gap.minutes >= 60
          ? '${gap.minutes ~/ 60}h${gap.minutes % 60 > 0 ? '${gap.minutes % 60}m' : ''}'
          : '${gap.minutes}m';
      
      final labelFontSize = fontSize * 8 / 11;
      _paintText(
        canvas,
        label,
        gap.centerX,
        size.height - labelFontSize - 2.0,
        fontSize: labelFontSize,
        color: tickColor.withOpacity(0.7),
        centered: true,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    double x,
    double top, {
    required double fontSize,
    required Color color,
    bool centered = false,
  }) {
    // S5-B5: Shadows only on dark backgrounds to prevent blurriness in light mode.
    final isDarkBg = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark;
    final List<Shadow>? shadows = isDarkBg
        ? [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0.5, 0.5),
            )
          ]
        : null;

    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        shadows: shadows,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    
    final finalX = centered ? x - painter.width / 2 : x;
    painter.paint(canvas, Offset(finalX, top));
  }

  void _paintEventLabel(
    Canvas canvas,
    String title,
    double x,
    double top,
    double maxWidth,
    double height,
  ) {
    // Event labels are always white text, so they always get a shadow for
    // contrast against the event block color.
    final shadow = Shadow(
      blurRadius: 2.0,
      color: Colors.black.withOpacity(0.5),
      offset: const Offset(0.5, 0.5),
    );

    final span = TextSpan(
      text: title,
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        shadows: [shadow],
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, top + height - painter.height - 2.0));
  }

  /// Renders a task as a diamond (◇) or two diamonds connected by a line if it has duration.
  void _paintTaskMarker(Canvas canvas, double x, double endX, double cy, Color color) {
    final half = fontSize * 0.5;
    final diamondPath = Path();
    
    // Construct diamonds
    void addDiamond(double cx) {
      diamondPath.moveTo(cx, cy - half);
      diamondPath.lineTo(cx + half, cy);
      diamondPath.lineTo(cx, cy + half);
      diamondPath.lineTo(cx - half, cy);
      diamondPath.close();
    }

    addDiamond(x);
    // Draw connecting line and end diamond only if there is a real time duration
    final hasDuration = endX > x + 0.1; // Small epsilon for float comparison
    if (hasDuration) addDiamond(endX);

    final fillPaint = Paint()..color = color;
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw the connecting line first (if duration) so diamonds overlap it
    if (hasDuration) {
      final linePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      
      canvas.drawLine(Offset(x, cy), Offset(endX, cy), linePaint);
      
      // Outline for the line
      final lineOutlinePaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0; // 3px line + 1px total outline
      // Wait, simple drawLine won't work well for composite outline.
      // Let's just use a second slightly thicker line for the 'outline' behind it.
      canvas.drawLine(Offset(x, cy), Offset(endX, cy), lineOutlinePaint);
      canvas.drawLine(Offset(x, cy), Offset(endX, cy), linePaint);
    }

    canvas.drawPath(diamondPath, fillPaint);
    canvas.drawPath(diamondPath, outlinePaint);
  }

  void _paintNowIndicator(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = nowLineColor
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(nowIndicatorX, 0),
      Offset(nowIndicatorX, size.height),
      linePaint,
    );

    final triPaint = Paint()..color = nowLineColor;
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
      old.hoveredEventId != hoveredEventId ||
      old.collidingIds != collidingIds ||
      old.countdownColor != countdownColor;

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
    final blockHeight = size.height - 2;
    const top = 1.0;

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
        final cy = top + blockHeight * 0.4;
        final taskWidth = (endX - x).abs().clamp(12.0, double.infinity);
        nodes.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(x - 6, cy - 6, taskWidth, 12),
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
