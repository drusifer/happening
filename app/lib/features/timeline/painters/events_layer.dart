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
  });

  final List<CalendarEvent> events;
  final TimelineLayout layout;
  final DateTime now;
  final String? hoveredEventId;
  final Set<String> collidingIds;
  final Color tickColor;
  final Color backgroundColor;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    final blockHeight = size.height - 2.0;
    const top = 1.0;

    final renderList = [...events]
      ..sort((a, b) => b.duration.compareTo(a.duration));

    for (final event in renderList) {
      if (!layout.isVisible(event.startTime) &&
          !layout.isVisible(event.endTime)) {
        continue;
      }

      final x = layout.xForTime(event.startTime, now);
      final endX = layout.xForTime(event.endTime, now);
      final w =
          (endX - x).abs().clamp(event.isTask ? 0.0 : 12.0, double.infinity);

      final isHovered = event.id == hoveredEventId;
      final isColliding = collidingIds.contains(event.id);

      Color color = event.isCompleted ? const Color(0xFF51B749) : event.color;

      final double targetOpacity = isHovered ? 1.0 : (isColliding ? 0.5 : 0.82);
      color = color.withValues(alpha: targetOpacity);

      if (event.isTask) {
        final taskEndX = event.endTime.isAfter(event.startTime) ? endX : x;
        TimelinePaintUtils.paintTaskMarker(
          canvas,
          x,
          taskEndX,
          top + blockHeight * 0.4,
          color,
          fontSize: fontSize,
        );
      } else {
        final rect = RRect.fromLTRBR(
            x, top, x + w, top + blockHeight, const Radius.circular(4));
        if (event.isFree) {
          TimelinePaintUtils.paintHashFill(canvas, rect, color);
        } else {
          canvas.drawRRect(rect, Paint()..color = color);
        }

        if (isColliding) {
          for (final other in events) {
            if (other.id == event.id || other.isTask) continue;
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

      final hasDuration = event.endTime.isAfter(event.startTime);
      final titleThreshold = (fontSize / 15.0) * 36;

      if (!hasDuration || w > titleThreshold) {
        final taskDiamondWidth = fontSize * 0.5;
        final labelX = event.isTask ? x + taskDiamondWidth + 4 : x + 4;
        final labelWidth = (!hasDuration && event.isTask)
            ? size.width - labelX - 8
            : (event.isTask ? w - taskDiamondWidth - 8 : w - 8);

        if (labelWidth > 10) {
          TimelinePaintUtils.paintEventLabel(
            canvas,
            event.title,
            labelX,
            top,
            labelWidth,
            blockHeight,
            fontSize: fontSize,
            backgroundColor: backgroundColor,
            isTask: event.isTask,
          );
        }
      }
    }

    // Gap labels
    for (final gap in layout.gapsBetween(events, now)) {
      final label = gap.minutes >= 60
          ? '${gap.minutes ~/ 60}h${gap.minutes % 60 > 0 ? '${gap.minutes % 60}m' : ''}'
          : '${gap.minutes}m';
      final labelFontSize = fontSize * 9 / 11;
      TimelinePaintUtils.paintText(
        canvas,
        label,
        gap.centerX,
        size.height - labelFontSize - 12.0,
        fontSize: labelFontSize,
        color: tickColor.withValues(alpha: 1.0),
        backgroundColor: backgroundColor,
        centered: true,
      );
    }
  }
}
