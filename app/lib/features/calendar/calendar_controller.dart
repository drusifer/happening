// Manages the calendar event polling loop and event stream.
//
// TLDR:
// Overview: A controller that periodically fetches events and exposes them via a Stream.
// Problem: Need to decouple the polling logic from the UI.
// Solution: Implements a StreamController with a 5-minute Timer loop.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'calendar_event.dart';
import 'calendar_service.dart';
import 'event_repository.dart';

class CalendarController {
  CalendarController(CalendarService service)
      : _repo = EventRepository(service);

  final EventRepository _repo;
  final _eventsController = StreamController<List<CalendarEvent>>.broadcast();
  Timer? _pollTimer;

  Stream<List<CalendarEvent>> get events => _eventsController.stream;

  /// Starts the polling loop.
  void start() {
    unawaited(_fetch());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_fetch()),
    );
  }

  /// Stops the polling loop.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually triggers a refresh of the calendar events, bypassing the cache.
  Future<void> refresh() => _fetch(forceRefresh: true);

  Future<void> _fetch({bool forceRefresh = false}) async {
    try {
      final events = await _repo.getEvents(forceRefresh: forceRefresh);
      _eventsController.add(events);
    } catch (_) {
      // Stream keeps its last emitted value if fetch fails.
    }
  }

  void dispose() {
    stop();
    unawaited(_eventsController.close());
  }
}
