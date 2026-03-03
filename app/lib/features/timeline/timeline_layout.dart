// Pure-logic timeline geometry calculations.
//
// TLDR:
// Overview: Calculates X positions for times based on logical pixels.
// Problem: Need consistent, testable positioning logic without a Flutter dependency.
// Solution: Implements a stateless class to handle time-to-pixel mapping.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:happening/features/calendar/calendar_event.dart';

/// Pure math for positioning events on the timeline strip.
///
/// All inputs in logical pixels and [DateTime]. No Flutter dependency.
class TimelineLayout {
  TimelineLayout({
    required this.stripWidth,
    required this.nowIndicatorX,
    required this.windowStart,
    required this.windowEnd,
  }) : pixelsPerSecond =
            stripWidth / windowEnd.difference(windowStart).inSeconds.toDouble();

  final double stripWidth;
  final double nowIndicatorX;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Pixels per second across the full strip width.
  final double pixelsPerSecond;

  /// Returns the x position (logical pixels) for a given [time],
  /// relative to [now] (defaults to [DateTime.now] if omitted).
  double xForTime(DateTime time, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    final secondsFromNow = time.difference(reference).inSeconds.toDouble();
    return nowIndicatorX + secondsFromNow * pixelsPerSecond;
  }

  /// Minimum rendered width for any event, used for both hit-testing and
  /// expansion bounds so the two are always in sync.
  static const double kMinEventWidth = 12.0;

  /// Returns the effective right-edge X for [event], applying [kMinEventWidth]
  /// so short/zero-duration events are still tappable.
  double effectiveEndX(CalendarEvent event, DateTime now) {
    final x = xForTime(event.startTime, now);
    final rawEndX = xForTime(event.endTime, now);
    return rawEndX < x + kMinEventWidth ? x + kMinEventWidth : rawEndX;
  }

  /// Returns the [CalendarEvent] at the given [mouseX] position, or null if none.
  /// If multiple events overlap at this point, the one with the shortest duration wins.
  CalendarEvent? eventAtX(
      double mouseX, List<CalendarEvent> events, DateTime now) {
    CalendarEvent? bestHit;
    Duration? minDuration;

    for (final event in events) {
      final x = xForTime(event.startTime, now);
      final endX = effectiveEndX(event, now); // consistent with EventBounds

      if (mouseX >= x && mouseX <= endX) {
        final duration = event.endTime.difference(event.startTime);
        if (minDuration == null || duration < minDuration) {
          bestHit = event;
          minDuration = duration;
        }
      }
    }
    return bestHit;
  }

  /// Returns the first event that is currently active (startTime <= now < endTime).
  CalendarEvent? activeEvent(List<CalendarEvent> events, DateTime now) {
    for (final event in events) {
      if (!event.startTime.isAfter(now) && event.endTime.isAfter(now)) {
        return event;
      }
    }
    return null;
  }

  /// Duration remaining until [eventTime], clamped to zero if already past.
  Duration countdownTo(DateTime eventTime, DateTime now) {
    final remaining = eventTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether [time] falls within the visible window.
  bool isVisible(DateTime time) =>
      !time.isBefore(windowStart) && !time.isAfter(windowEnd);

  /// Returns the centerX and gap duration (minutes) for each gap between
  /// adjacent events that is at least [minPx] pixels wide. (S4-19)
  List<({double centerX, int minutes})> gapsBetween(
    List<CalendarEvent> events,
    DateTime now, {
    double minPx = 40,
  }) {
    if (events.length < 2) return const [];
    final sorted = [...events]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final result = <({double centerX, int minutes})>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final a = sorted[i];
      final b = sorted[i + 1];
      if (!b.startTime.isAfter(a.endTime)) continue;
      final gapStart = xForTime(a.endTime, now);
      final gapEnd = xForTime(b.startTime, now);
      if (gapEnd - gapStart < minPx) continue;
      result.add((
        centerX: (gapStart + gapEnd) / 2,
        minutes: b.startTime.difference(a.endTime).inMinutes,
      ));
    }
    return result;
  }
}
