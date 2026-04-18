// CustomPainter for the timeline strip.
//
// TLDR:
// Overview: Low-level canvas painting of events and indicators.
// Problem: Need a custom layout that can smoothly animate at 1Hz.
// Solution: Compositor that delegates to isolated [TimelineLayer] painters.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/painters/background_layer.dart';
import 'package:happening/features/timeline/painters/events_layer.dart';
import 'package:happening/features/timeline/painters/fetching_layer.dart';
import 'package:happening/features/timeline/painters/now_indicator_layer.dart';
import 'package:happening/features/timeline/painters/past_overlay_layer.dart';
import 'package:happening/features/timeline/painters/sign_in_layer.dart';
import 'package:happening/features/timeline/painters/tick_layer.dart';
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
    required this.alwaysUse24HourFormat,
    this.hoveredEventId,
    this.collidingIds = const {},
    this.countdownColor = Colors.white,
    this.fontSize = 11,
    this.isLoading = false,
    this.loadingTextColor = Colors.white,
    this.isSignIn = false,
    this.isSigningIn = false,
    this.signInTextColor = Colors.white,
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
  final bool alwaysUse24HourFormat;

  final bool isLoading;
  final Color loadingTextColor;
  final bool isSignIn;
  final bool isSigningIn;
  final Color signInTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    // unawaited(AppLogger.debug('TimelinePainter.paint size=$size'));
    final layout = TimelineLayout(
      stripWidth: size.width,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    final layers = [
      BackgroundLayer(color: backgroundColor),
      PastOverlayLayer(nowIndicatorX: nowIndicatorX, color: pastOverlayColor),
      TickLayer(
        layout: layout,
        now: now,
        windowStart: windowStart,
        windowEnd: windowEnd,
        nowIndicatorX: nowIndicatorX,
        tickColor: tickColor,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        alwaysUse24HourFormat: alwaysUse24HourFormat,
      ),
      EventsLayer(
        events: events,
        layout: layout,
        now: now,
        hoveredEventId: hoveredEventId,
        collidingIds: collidingIds,
        tickColor: tickColor,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
      ),
      NowIndicatorLayer(nowIndicatorX: nowIndicatorX, color: nowLineColor),
      FetchingLayer(
        isLoading: isLoading,
        backgroundColor: backgroundColor,
        textColor: loadingTextColor,
        fontSize: fontSize,
      ),
      SignInLayer(
        isSignIn: isSignIn,
        isSigningIn: isSigningIn,
        backgroundColor: backgroundColor,
        textColor: signInTextColor,
        fontSize: fontSize,
      ),
    ];

    for (final layer in layers) {
      layer.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(TimelinePainter old) =>
      old.now != now ||
      old.events != events ||
      old.hoveredEventId != hoveredEventId ||
      old.collidingIds != collidingIds ||
      old.countdownColor != countdownColor ||
      old.isLoading != isLoading ||
      old.isSignIn != isSignIn ||
      old.isSigningIn != isSigningIn ||
      old.alwaysUse24HourFormat != alwaysUse24HourFormat;

  /// Semantic nodes for canvas content — makes ticks, events, and task
  /// diamonds queryable by integration tests via find.bySemanticsLabel.
  ///
  /// Uses the SAME pixel-bounds condition as [TickLayer] / [EventsLayer]
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
            final label = formatTimelineHourTickLabel(
              current,
              alwaysUse24HourFormat: alwaysUse24HourFormat,
            );
            nodes.add(CustomPainterSemantics(
              rect: Rect.fromLTWH(x - 1, 0, 2, size.height),
              properties: SemanticsProperties(
                  label: 'tick-$label', textDirection: TextDirection.ltr),
            ));
          }

          if (pixelsPerHour >= 80) {
            final tickTime = current.add(const Duration(minutes: 30));
            final tx = layout.xForTime(tickTime, now);
            if (tx >= 0 && tx <= size.width) {
              final label = formatTimelineHalfHourTickLabel();
              nodes.add(CustomPainterSemantics(
                rect: Rect.fromLTWH(tx - 1, 0, 2, 15),
                properties: SemanticsProperties(
                    label: 'subtick-$label', textDirection: TextDirection.ltr),
              ));
            }
          }
          current = current.add(const Duration(hours: 1));
        }

        // ── Now indicator ──────────────────────────────────────────────────────
        nodes.add(CustomPainterSemantics(
          rect: Rect.fromLTWH(nowIndicatorX - 1, 0, 2, size.height),
          properties: const SemanticsProperties(
              label: 'now-indicator', textDirection: TextDirection.ltr),
        ));

        // ── Events and tasks ───────────────────────────────────────────────────
        for (final event in events) {
          if (!layout.isVisible(event.startTime) &&
              !layout.isVisible(event.endTime)) {
            continue;
          }
          final x = layout.xForTime(event.startTime, now);
          final endX = layout.xForTime(event.endTime, now);
          final w = (endX - x).clamp(3.0, double.infinity);

          if (event.isTask) {
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
