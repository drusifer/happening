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

import '../../core/settings/settings_service.dart';
import 'calendar_event.dart';
import 'calendar_service.dart';
import 'event_repository.dart';

class CalendarController {
  CalendarController(CalendarService service, {SettingsService? settingsService})
      : _service = service,
        _settingsService = settingsService,
        _repo = EventRepository(service);

  final CalendarService _service;
  final SettingsService? _settingsService;
  final EventRepository _repo;
  final _eventsController = StreamController<List<CalendarEvent>>.broadcast();
  Timer? _pollTimer;

  CalendarService get service => _service;
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
      final selectedIds = _settingsService?.current.selectedCalendarIds ?? const [];
      
      // Always include 'primary' to ensure we get account-wide @tasks.
      final Set<String> idsToFetch = {
        'primary',
        ...selectedIds,
      };

      final List<List<CalendarEvent>> results = await Future.wait(
        idsToFetch.map((id) => _service.fetchEvents(id))
      );

      final allEvents = results.expand((e) => e).toList();
      final deduped = _dedup(allEvents);
      
      _eventsController.add(deduped);
    } catch (_) {
      // Stream keeps its last emitted value if fetch fails.
    }
  }

  static List<CalendarEvent> _dedup(List<CalendarEvent> events) {
    final seen = <String>{};
    return events.where((e) => seen.add(e.id)).toList();
  }

  void dispose() {
    stop();
    unawaited(_eventsController.close());
  }
}
