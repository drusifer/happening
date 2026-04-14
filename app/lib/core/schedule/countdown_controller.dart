import 'package:happening/core/schedule/periodic_controller.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_state.dart';

/// 1Hz [PeriodicController] that emits a [CountdownState] each second.
///
/// Provides a single injectable, testable stream to replace the duplicated
/// StreamBuilder countdown logic in TimelineStrip.
class CountdownController implements PeriodicController<CountdownState> {
  CountdownController({
    required ClockService clock,
    required List<CalendarEvent> Function() events,
  })  : _clock = clock,
        _events = events;

  final ClockService _clock;
  final List<CalendarEvent> Function() _events;

  @override
  Stream<CountdownState> get stream =>
      _clock.tick1s.map((now) => CountdownState.compute(_events(), now));

  @override
  void dispose() {}
}
