import 'package:flutter/material.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:happening/features/timeline/timeline_painter.dart';

const double _kNowIndicatorFraction = 0.2; // 20% from left edge

/// Root timeline widget. Stateless — driven by [clockService] stream.
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
  String? _hoveredEventId;

  List<CalendarEvent> _futureEvents(DateTime now) {
    return widget.events
        .where((e) => e.endTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

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
            final stripHeight = constraints.maxHeight;
            final nowIndicatorX = stripWidth * _kNowIndicatorFraction;

            final layout = TimelineLayout(
              stripWidth: stripWidth,
              nowIndicatorX: nowIndicatorX,
              windowStart: now.subtract(widget.windowPast),
              windowEnd: now.add(widget.windowFuture),
            );

            final nextEvent = future.first;
            final countdown = layout.countdownTo(nextEvent.startTime, now);

            return Stack(
              children: [
                // Timeline canvas
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: CustomPaint(
                      painter: TimelinePainter(
                        events: widget.events,
                        now: now,
                        nowIndicatorX: nowIndicatorX,
                        windowStart: now.subtract(widget.windowPast),
                        windowEnd: now.add(widget.windowFuture),
                        hoveredEventId: _hoveredEventId,
                      ),
                    ),
                  ),
                ),

                // Countdown label — sits between now indicator and next event
                Positioned(
                  left: nowIndicatorX + 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: CountdownDisplay(remaining: countdown),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
