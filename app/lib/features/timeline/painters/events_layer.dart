import 'package:flutter/material.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/painters/timeline_paint_utils.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// TLDR: Paints all calendar events as colored blocks (or task diamonds) on the
/// timeline strip. Handles hover highlight, collision outlines, free-time hatch,
/// event labels, and inter-event gap labels.
class EventsLayer implements TimelineLayer {
  const EventsLayer({
    required this.events,
    required this.layout,
    required this.now,
    required this.hoveredEventId,
    required this.collidingIds,
    required this.tickColor,
    required this.backgroundColor,
    required this.fontSize,
    required this.surfaceOpacity,
    this.excludeEventId,
  });

  final List<CalendarEvent> events;
  final TimelineLayout layout;
  final DateTime now;
  final String? hoveredEventId;
  final Set<String> collidingIds;
  final Color tickColor;
  final Color backgroundColor;
  final double fontSize;
  final double surfaceOpacity;
  final String? excludeEventId;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height * 0.44;
    const bottomInset = 8.0; // 1px border + 3px shadow blur + 4px bottom margin
    final blockHeight = size.height - top - bottomInset;

    final overlapRanks = layout.computeExactOverlapRanks(events, now);

    final renderList = [...events]..sort((a, b) {
        final durCmp = b.duration.compareTo(a.duration);
        if (durCmp != 0) return durCmp;
        final aRank = overlapRanks[a.id]?.rank ?? 0;
        final bRank = overlapRanks[b.id]?.rank ?? 0;
        return aRank.compareTo(bRank);
      });

    for (final event in renderList) {
      if (event.id == excludeEventId) continue;
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) {
        continue;
      }
      _paintEvent(canvas, event, overlapRanks, size, top, blockHeight);
    }

    _paintGapLabels(canvas, size);
  }

  void _paintEvent(
    Canvas canvas,
    CalendarEvent event,
    Map<String, ({int rank, int groupSize})> overlapRanks,
    Size size,
    double top,
    double blockHeight,
  ) {
    final x = layout.xForTime(event.startTime, now);
    final endX = layout.xForTime(event.endTime, now);

    final overlapInfo = overlapRanks[event.id];
    final step = layout.overlapStepPx;
    final offset = overlapInfo != null ? overlapInfo.rank * step : 0.0;
    final adjustedX = x + offset;
    final minW = overlapInfo != null
        ? TimelineLayout.kMinEventWidth +
            (overlapInfo.groupSize - 1 - overlapInfo.rank) * step
        : (event.isTask ? 0.0 : TimelineLayout.kMinEventWidth);
    final w = (endX - adjustedX).clamp(minW, double.infinity);

    final int rank = overlapInfo?.rank ?? 0;
    final baseColor = event.isCompleted ? const Color(0xFF51B749) : event.color;
    final color =
        baseColor.withValues(alpha: (rank == 0 ? 1.0 : 0.55) * surfaceOpacity);

    if (event.isTask) {
      final taskEndX =
          event.endTime.isAfter(event.startTime) ? endX : adjustedX;
      TimelinePaintUtils.paintTaskMarker(
        canvas,
        adjustedX,
        taskEndX,
        top + blockHeight * 0.4,
        color,
        fontSize: fontSize,
      );
    } else {
      final rect = RRect.fromLTRBR(adjustedX, top, adjustedX + w,
          top + blockHeight, const Radius.circular(4));
      _paintEventBlock(canvas, event, rect, color, baseColor);
    }

    _paintEventLabel(
        canvas, event, baseColor, adjustedX, w, top, blockHeight, size);
  }

  void _paintEventBlock(
    Canvas canvas,
    CalendarEvent event,
    RRect rect,
    Color color,
    Color baseColor,
  ) {
    canvas.drawRRect(
      rect.shift(const Offset(3, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
    if (event.isFree) {
      TimelinePaintUtils.paintHashFill(canvas, rect, color);
    } else {
      canvas.drawRRect(rect, Paint()..color = color);
    }
    canvas.drawRRect(
      rect,
      Paint()
        ..color = Color.lerp(baseColor, Colors.black, 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (collidingIds.contains(event.id)) {
      _paintCollisionOutlines(canvas, event, rect);
    }
  }

  void _paintCollisionOutlines(Canvas canvas, CalendarEvent event, RRect rect) {
    for (final other in events) {
      if (other.id == event.id || other.isTask) continue;
      final start = event.startTime.isAfter(other.startTime)
          ? event.startTime
          : other.startTime;
      final end =
          event.endTime.isBefore(other.endTime) ? event.endTime : other.endTime;
      if (!start.isBefore(end)) continue;
      final ox = layout.xForTime(start, now);
      final oEndX = layout.xForTime(end, now);
      final ow = (oEndX - ox).clamp(2.0, double.infinity);
      canvas.drawRRect(
        RRect.fromLTRBR(
            ox, rect.top, ox + ow, rect.bottom, const Radius.circular(4)),
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  void _paintEventLabel(Canvas canvas, CalendarEvent event, Color baseColor,
      double x, double w, double top, double blockHeight, Size size) {
    final hasDuration = event.endTime.isAfter(event.startTime);
    final titleThreshold = (fontSize / 15.0) * 36;
    if (hasDuration && w <= titleThreshold) return;

    final taskDiamondWidth = fontSize * 0.5;
    const leftPad = 8.0;
    const rightPad = 6.0;
    final labelX = event.isTask ? x + taskDiamondWidth + leftPad : x + leftPad;
    final labelWidth = (!hasDuration && event.isTask)
        ? size.width - labelX - rightPad
        : (event.isTask
            ? w - taskDiamondWidth - leftPad - rightPad
            : w - leftPad - rightPad);

    if (labelWidth <= 10) return;
    TimelinePaintUtils.paintEventLabel(
      canvas,
      event.title,
      EventLabelConfig(
        x: labelX,
        top: top,
        maxWidth: labelWidth,
        height: blockHeight,
        fontSize: fontSize,
        backgroundColor: backgroundColor,
        eventColor: baseColor,
        isTask: event.isTask,
      ),
    );
  }

  void _paintGapLabels(Canvas canvas, Size size) {
    for (final gap in layout.gapsBetween(events, now)) {
      final label = gap.minutes >= 60
          ? '${gap.minutes ~/ 60}h${gap.minutes % 60 > 0 ? '${gap.minutes % 60}m' : ''}'
          : '${gap.minutes}m';
      final labelFontSize = fontSize * 9 / 11;
      TimelinePaintUtils.paintText(
        canvas,
        label,
        TextPaintConfig(
          x: gap.centerX,
          top: size.height - labelFontSize - 12.0,
          fontSize: labelFontSize,
          color: tickColor.withValues(alpha: 1.0 * surfaceOpacity),
          backgroundColor: backgroundColor,
          centered: true,
        ),
      );
    }
  }
}
