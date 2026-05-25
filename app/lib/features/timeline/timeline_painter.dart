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
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/painters/astronomical_background_layer.dart';
import 'package:happening/features/timeline/painters/background_layer.dart';
import 'package:happening/features/timeline/painters/events_layer.dart';
import 'package:happening/features/timeline/painters/fetching_layer.dart';
import 'package:happening/features/timeline/painters/now_indicator_layer.dart';
import 'package:happening/features/timeline/painters/past_overlay_layer.dart';
import 'package:happening/features/timeline/painters/sign_in_layer.dart';
import 'package:happening/features/timeline/painters/tick_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:logging/logging.dart';

/// Paints the proportional event timeline onto the strip canvas.
class TimelinePainter extends CustomPainter {
  static final _log = Logger('TimelinePainter');
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
    this.surfaceOpacity = 1.0,
    this.emphasisOpacity = 1.0,
    this.stripOpacity = 1.0,
    this.astroData,
    this.isAstroTheme = false,
    this.astroLat,
    this.astroLng,
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
  final double surfaceOpacity;
  final double emphasisOpacity;
  final double stripOpacity;
  final AstroData? astroData;
  final bool isAstroTheme;
  final double? astroLat;
  final double? astroLng;

  static DateTime? _lastPaintDebugAt;

  @override
  void paint(Canvas canvas, Size size) {
    final nowForDebug = DateTime.now();
    final shouldLogPaint = _lastPaintDebugAt == null ||
        nowForDebug.difference(_lastPaintDebugAt!) >
            const Duration(milliseconds: 250);
    if (shouldLogPaint) {
      _lastPaintDebugAt = nowForDebug;
      _log.fine(
          'TimelinePainter.paint size=${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)} '
          'bg=#${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')} '
          'surfaceOpacity=${surfaceOpacity.toStringAsFixed(2)} '
          'emphasisOpacity=${emphasisOpacity.toStringAsFixed(2)} '
          'events=${events.length} hovered=${hoveredEventId != null} '
          'loading=$isLoading signIn=$isSignIn');
    }
    final layout = TimelineLayout(
      stripWidth: size.width,
      nowIndicatorX: nowIndicatorX,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    final useAstro = isAstroTheme && astroData != null;

    final layers = [
      if (useAstro)
        AstronomicalBackgroundLayer(
            astroData: astroData!,
            layout: layout,
            now: now,
            lat: astroLat,
            lng: astroLng)
      else
        BackgroundLayer(color: backgroundColor),
      PastOverlayLayer(
        nowIndicatorX: nowIndicatorX,
        color: pastOverlayColor.withValues(
            alpha: pastOverlayColor.a * surfaceOpacity),
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
        surfaceOpacity: surfaceOpacity,
        excludeEventId: stripOpacity < 1.0 ? hoveredEventId : null,
      ),
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
        surfaceOpacity: surfaceOpacity,
      ),
      NowIndicatorLayer(
        nowIndicatorX: nowIndicatorX,
        color: nowLineColor.withValues(alpha: nowLineColor.a * emphasisOpacity),
      ),
      FetchingLayer(
        isLoading: isLoading,
        backgroundColor: backgroundColor.withValues(
            alpha: backgroundColor.a * emphasisOpacity),
        textColor: loadingTextColor.withValues(
          alpha: loadingTextColor.a * emphasisOpacity,
        ),
        fontSize: fontSize,
      ),
      SignInLayer(
        isSignIn: isSignIn,
        isSigningIn: isSigningIn,
        backgroundColor: backgroundColor.withValues(
            alpha: backgroundColor.a * emphasisOpacity),
        textColor: signInTextColor.withValues(
          alpha: signInTextColor.a * emphasisOpacity,
        ),
        fontSize: fontSize,
      ),
    ];

    final useLayerOpacity = stripOpacity < 1.0;
    if (useLayerOpacity) {
      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    }

    for (final layer in layers) {
      layer.paint(canvas, size);
    }

    if (useLayerOpacity) {
      // Apply global opacity via DstIn: output = dst * src.alpha.
      // This is a Skia-level composite — no Flutter OpacityLayer is created,
      // so GTK keyboard focus routing is unaffected.
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..blendMode = BlendMode.dstIn
          ..color = Color.fromARGB((stripOpacity * 255).round(), 255, 255, 255),
      );
      canvas.restore();

      // Repaint the hovered event at full opacity — outside the faded layer so
      // the transparency slider doesn't dim the event the user is looking at.
      if (hoveredEventId != null) {
        final hoveredEvent =
            events.where((e) => e.id == hoveredEventId).firstOrNull;
        if (hoveredEvent != null) {
          EventsLayer(
            events: [hoveredEvent],
            layout: layout,
            now: now,
            hoveredEventId: hoveredEventId,
            collidingIds: collidingIds,
            tickColor: tickColor,
            backgroundColor: backgroundColor,
            fontSize: fontSize,
            surfaceOpacity: surfaceOpacity,
          ).paint(canvas, size);
        }
      }
    }
  }

  @override
  bool shouldRepaint(TimelinePainter old) =>
      old.now != now ||
      old.events != events ||
      old.hoveredEventId != hoveredEventId ||
      old.collidingIds != collidingIds ||
      old.countdownColor != countdownColor ||
      old.fontSize != fontSize ||
      old.backgroundColor != backgroundColor ||
      old.pastOverlayColor != pastOverlayColor ||
      old.tickColor != tickColor ||
      old.nowIndicatorX != nowIndicatorX ||
      old.isLoading != isLoading ||
      old.isSignIn != isSignIn ||
      old.isSigningIn != isSigningIn ||
      old.alwaysUse24HourFormat != alwaysUse24HourFormat ||
      old.surfaceOpacity != surfaceOpacity ||
      old.emphasisOpacity != emphasisOpacity ||
      old.stripOpacity != stripOpacity ||
      old.astroData != astroData ||
      old.isAstroTheme != isAstroTheme ||
      old.astroLat != astroLat ||
      old.astroLng != astroLng ||
      old.windowStart != windowStart ||
      old.windowEnd != windowEnd;

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
        final top = size.height * 0.5;
        final blockHeight = size.height - top - 8.0;

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
