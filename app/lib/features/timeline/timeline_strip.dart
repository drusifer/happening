/// Root timeline widget with interactivity and layout management.
///
/// TLDR:
/// Overview: A stateful widget that integrates the clock, the painter, and the window resizing logic.
/// Problem: Need to handle mouse hover and dynamically resize the window to show event details.
/// Solution: Uses a Stack with MouseRegion, StreamBuilder, and window_manager resizing.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:happening/features/timeline/timeline_painter.dart';
import 'package:window_manager/window_manager.dart';

const double _kNowIndicatorFraction = 0.10; // 10% from left edge
const double _kCollapsedHeight = 30.0;
const double _kExpandedHeight = 115.0;

/// Root timeline widget. Driven by [clockService] stream.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.events,
    required this.clockService,
    this.windowPast = const Duration(hours: 1),
    this.windowFuture = const Duration(hours: 8),
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final Duration windowPast;
  final Duration windowFuture;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip> {
  CalendarEvent? _hoveredEvent;

  // Updated each build — used by mouse handlers.
  TimelineLayout? _layout;
  double _stripWidth = 0;
  DateTime _now = DateTime.now();

  // ── Window resize ────────────────────────────────────────────────────────

  Future<void> _setWindowHeight(double height) async {
    try {
      final w = _stripWidth;
      await windowManager.setMinimumSize(Size(w, height));
      await windowManager.setMaximumSize(Size(w, height));
      await windowManager.setSize(Size(w, height));
    } catch (_) {
      // No-op in test environments.
    }
  }

  // ── Hit testing ──────────────────────────────────────────────────────────

  CalendarEvent? _eventAtX(double mouseX) {
    final layout = _layout;
    if (layout == null) return null;
    for (final event in widget.events) {
      final x = layout.xForTime(event.startTime, _now);
      final endX = layout.xForTime(event.endTime, _now);
      final w = (endX - x).clamp(3.0, double.infinity);
      if (mouseX >= x && mouseX <= x + w) return event;
    }
    return null;
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _onMouseMove(PointerEvent details) {
    // Ignore moves inside the card area — keep current hover state so buttons remain clickable.
    if (details.localPosition.dy >= _kCollapsedHeight) return;
    final hit = _eventAtX(details.localPosition.dx);
    if (hit?.id == _hoveredEvent?.id) return;
    setState(() => _hoveredEvent = hit);
    _setWindowHeight(hit != null ? _kExpandedHeight : _kCollapsedHeight);
  }

  void _onMouseExit(PointerEvent _) {
    if (_hoveredEvent == null) return;
    setState(() => _hoveredEvent = null);
    _setWindowHeight(_kCollapsedHeight);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<CalendarEvent> _futureEvents(DateTime now) {
    return widget.events
        .where((e) => e.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  double _cardLeft(double screenWidth) {
    const cardWidth = 260.0;
    final layout = _layout;
    final event = _hoveredEvent;
    if (layout == null || event == null) return 4.0;
    final eventX = layout.xForTime(event.startTime, _now);
    final eventEndX = layout.xForTime(event.endTime, _now);
    final eventCenterX = (eventX + eventEndX) / 2;
    return (eventCenterX - cardWidth / 2).clamp(4.0, screenWidth - cardWidth - 4);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: widget.clockService.tick,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data!;
        final future = _futureEvents(now);

        if (future.isEmpty) return const CelebrationWidget();

        return LayoutBuilder(
          builder: (context, constraints) {
            final stripWidth = constraints.maxWidth;
            final nowIndicatorX = stripWidth * _kNowIndicatorFraction;

            final layout = TimelineLayout(
              stripWidth: stripWidth,
              nowIndicatorX: nowIndicatorX,
              windowStart: now.subtract(widget.windowPast),
              windowEnd: now.add(widget.windowFuture),
            );

            _layout = layout;
            _stripWidth = stripWidth;
            _now = now;

            final nextEvent = future.first;
            final countdown = layout.countdownTo(nextEvent.startTime, now);

            return MouseRegion(
              onHover: _onMouseMove,
              onExit: _onMouseExit,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Timeline canvas — top 30px
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _kCollapsedHeight,
                    child: CustomPaint(
                      painter: TimelinePainter(
                        events: widget.events,
                        now: now,
                        nowIndicatorX: nowIndicatorX,
                        windowStart: now.subtract(widget.windowPast),
                        windowEnd: now.add(widget.windowFuture),
                        hoveredEventId: _hoveredEvent?.id,
                      ),
                    ),
                  ),

                  // Countdown label — left of the now indicator
                  Positioned(
                    right: stripWidth - nowIndicatorX + 8,
                    top: 0,
                    height: _kCollapsedHeight,
                    child: Center(
                      child: CountdownDisplay(remaining: countdown),
                    ),
                  ),

                  // Hover detail card — visible when window is expanded
                  if (_hoveredEvent != null)
                    Positioned(
                      top: _kCollapsedHeight,
                      left: _cardLeft(stripWidth),
                      child: HoverDetailOverlay(event: _hoveredEvent!),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
