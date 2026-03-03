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
import '../../core/util/logger.dart';
import 'calendar_event.dart';
import 'calendar_service.dart';

class CalendarController {
  CalendarController(CalendarService service,
      {SettingsService? settingsService})
      : _service = service,
        _settingsService = settingsService;

  final CalendarService _service;
  final SettingsService? _settingsService;
  final _eventsController = StreamController<List<CalendarEvent>>.broadcast();
  Timer? _pollTimer;
  List<CalendarEvent>? _lastEvents;

  CalendarService get service => _service;
  Stream<List<CalendarEvent>> get events => _eventsController.stream;

  /// Returns the last emitted events, or null if no fetch has completed yet.
  List<CalendarEvent>? get lastEvents => _lastEvents;

  /// Starts the polling loop.
  Future<void> start() async {
    await AppLogger.log('CalendarController.start() called.');
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
    await AppLogger.log(
        'CalendarController._fetch() started (forceRefresh: $forceRefresh)');
    try {
      final selectedIds =
          _settingsService?.current.selectedCalendarIds ?? const [];

      // Always include 'primary' to ensure we get account-wide @tasks.
      final Set<String> idsToFetch = {
        'primary',
        ...selectedIds,
      };
      await AppLogger.log('Fetching calendars: $idsToFetch');

      final List<List<CalendarEvent>> results =
          await Future.wait(idsToFetch.map((id) => _service.fetchEvents(id)));

      final allEvents = results.expand((e) => e).toList();
      final deduped = _dedup(allEvents);
      await AppLogger.log(
          'Fetch complete. Found ${allEvents.length} events (${deduped.length} deduped).');

      _lastEvents = deduped;
      _eventsController.add(deduped);
      await AppLogger.log('Emitted events to stream.');
    } catch (e) {
      // S5-FIX: If the first fetch fails, emit an empty list to unblock the UI.
      if (_lastEvents == null) {
        await AppLogger.log(
            'Initial fetch failed. Emitting empty list to unblock UI.');
        _lastEvents = [];
        _eventsController.add([]);
      }
      await AppLogger.log('Fetch failed error: $e');
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
