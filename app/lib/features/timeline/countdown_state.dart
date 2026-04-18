import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_display.dart';

/// Immutable snapshot of the countdown timer's current state.
///
/// Eliminates the ~30-line duplication between the two StreamBuilders in
/// TimelineStrip that independently computed active/target/mode/remaining.
class CountdownState {
  const CountdownState({
    required this.activeEvent,
    required this.targetTime,
    required this.mode,
    required this.remaining,
  });

  final CalendarEvent? activeEvent;
  final DateTime? targetTime;
  final CountdownMode mode;
  final Duration remaining;

  /// Computes state from the current event list and wall-clock [now].
  factory CountdownState.compute(List<CalendarEvent> events, DateTime now) {
    // Find the currently active event (started, not yet ended).
    CalendarEvent? active;
    for (final e in events) {
      if (!e.startTime.isAfter(now) && e.endTime.isAfter(now)) {
        active = e;
        break;
      }
    }

    if (active != null) {
      // Active: count down to the next overlapping event's start, or this event's end.
      final overlap = (events
              .where((e) =>
                  e.startTime.isAfter(now) &&
                  e.startTime.isBefore(active!.endTime))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)))
          .firstOrNull;
      final target = overlap?.startTime ?? active.endTime;
      return CountdownState(
        activeEvent: active,
        targetTime: target,
        mode: CountdownMode.untilEnd,
        remaining: target.difference(now),
      );
    }

    // No active event: count down to next future event's start.
    final next = (events.where((e) => e.startTime.isAfter(now)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime)))
        .firstOrNull;

    return CountdownState(
      activeEvent: null,
      targetTime: next?.startTime,
      mode: CountdownMode.untilNext,
      remaining: next != null ? next.startTime.difference(now) : Duration.zero,
    );
  }
}
