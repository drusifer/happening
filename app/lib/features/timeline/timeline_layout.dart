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

  /// Pixels by which each stacked-overlap rank trims its right edge.
  ///
  /// Scales with zoom (2 minutes in pixels) so the peeking sliver stays
  /// proportional to event width, with a 10px floor for reliable hover access.
  double get overlapStepPx =>
      (2.0 * 60 * pixelsPerSecond).clamp(10.0, double.infinity);

  /// Groups non-task events whose rendered start AND end positions land on the
  /// same integer pixel — i.e. visually indistinguishable at the current zoom.
  ///
  /// Returns a map from event ID → (rank, groupSize). rank=0 is the bottom
  /// card (widest, no trim); rank=N−1 is the top card (most trimmed). Events
  /// not in any same-pixel group are absent from the map.
  Map<String, ({int rank, int groupSize})> computeExactOverlapRanks(
      List<CalendarEvent> events, DateTime now) {
    final groups = <String, List<CalendarEvent>>{};
    for (final e in events) {
      if (e.isTask) continue;
      final startPx = xForTime(e.startTime, now).round();
      final endPx = xForTime(e.endTime, now).round();
      final key = '${startPx}_${endPx}';
      groups.putIfAbsent(key, () => []).add(e);
    }

    final result = <String, ({int rank, int groupSize})>{};
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final sorted = [...group]..sort((a, b) => a.id.compareTo(b.id));
      for (var i = 0; i < sorted.length; i++) {
        result[sorted[i].id] = (rank: i, groupSize: sorted.length);
      }
    }
    return result;
  }

  /// Returns the effective right-edge X for [event], applying [kMinEventWidth]
  /// and any exact-overlap stacking offset so hit-testing matches rendering.
  double effectiveEndX(CalendarEvent event, DateTime now,
      [Map<String, ({int rank, int groupSize})>? overlapRanks]) {
    final x = xForTime(event.startTime, now);
    final rawEndX = xForTime(event.endTime, now);
    final info = overlapRanks?[event.id];
    final step = overlapStepPx;
    final offset = info != null ? info.rank * step : 0.0;
    final minW = info != null
        ? kMinEventWidth + (info.groupSize - 1 - info.rank) * step
        : kMinEventWidth;
    final adjustedEndX = rawEndX - offset;
    return adjustedEndX < x + minW ? x + minW : adjustedEndX;
  }

  /// Returns the [CalendarEvent] at the given [mouseX] position, or null if none.
  ///
  /// Among hits: shortest duration wins. For equal-duration events (exact-overlap
  /// groups), the highest rank (topmost card) wins except in the peeking region
  /// where only the bottom card's wider effective end reaches.
  CalendarEvent? eventAtX(
      double mouseX, List<CalendarEvent> events, DateTime now) {
    final overlapRanks = computeExactOverlapRanks(events, now);
    CalendarEvent? bestHit;
    Duration? minDuration;
    int bestRank = -1;

    for (final event in events) {
      final x = xForTime(event.startTime, now);
      final endX = effectiveEndX(event, now, overlapRanks);

      if (mouseX >= x && mouseX <= endX) {
        final duration = event.endTime.difference(event.startTime);
        final rank = overlapRanks[event.id]?.rank ?? -1;
        if (minDuration == null ||
            duration < minDuration ||
            (duration == minDuration && rank > bestRank)) {
          bestHit = event;
          minDuration = duration;
          bestRank = rank;
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
