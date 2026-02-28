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

  /// Returns the [CalendarEvent] at the given [mouseX] position, or null if none.
  CalendarEvent? eventAtX(
      double mouseX, List<CalendarEvent> events, DateTime now) {
    for (final event in events) {
      final x = xForTime(event.startTime, now);
      final endX = xForTime(event.endTime, now);
      final w = (endX - x).clamp(3.0, double.infinity);
      if (mouseX >= x && mouseX <= x + w) return event;
    }
    return null;
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
}
