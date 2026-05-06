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
  Future<void>? _inFlightFetch;

  CalendarService get service => _service;
  Stream<List<CalendarEvent>> get events => _eventsController.stream;

  /// Returns the last emitted events, or null if no fetch has completed yet.
  List<CalendarEvent>? get lastEvents => _lastEvents;

  /// Starts the polling loop.
  Future<void> start() async {
    await AppLogger.debug('CalendarController.start() called.');
    unawaited(_scheduleFetch());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => unawaited(_scheduleFetch()),
    );
  }

  /// Stops the polling loop.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually triggers a refresh of the calendar events, bypassing the cache.
  Future<void> refresh() => _scheduleFetch(forceRefresh: true);

  Future<void> _scheduleFetch({bool forceRefresh = false}) {
    final inFlight = _inFlightFetch;
    if (inFlight != null) {
      unawaited(AppLogger.debug(
          'CalendarController._fetch() already in flight; ignoring request forceRefresh=$forceRefresh'));
      return inFlight;
    }

    final fetch = _fetchOnce(forceRefresh: forceRefresh).whenComplete(() {
      _inFlightFetch = null;
    });
    _inFlightFetch = fetch;
    return fetch;
  }

  Future<void> _fetchOnce({bool forceRefresh = false}) async {
    await AppLogger.debug(
        'CalendarController._fetch() started (forceRefresh: $forceRefresh)');
    try {
      final selectedIds =
          _settingsService?.current.selectedCalendarIds ?? const [];

      // Always include 'primary' to ensure we get account-wide @tasks.
      final Set<String> idsToFetch = {
        'primary',
        ...selectedIds,
      };
      await AppLogger.debug(
          'Fetching ${idsToFetch.length} configured calendars');

      final results = <List<CalendarEvent>>[];
      for (final id in idsToFetch) {
        try {
          final events = await _service.fetchEvents(id);
          await AppLogger.debug(
              'Fetched configured calendar: ${events.length} events');
          results.add(events);
        } catch (_) {
          unawaited(AppLogger.warn('Configured calendar fetch failed'));
          results.add(<CalendarEvent>[]);
        }
      }

      final allEvents = results.expand((e) => e).toList();
      final deduped = _dedup(allEvents);
      await AppLogger.debug(
          'Fetch complete. Found ${allEvents.length} events (${deduped.length} deduped).');

      _lastEvents = deduped;
      _eventsController.add(deduped);
      await AppLogger.debug('Emitted events to stream.');
    } catch (_) {
      // S5-FIX: If the first fetch fails, emit an empty list to unblock the UI.
      if (_lastEvents == null) {
        await AppLogger.debug(
            'Initial fetch failed. Emitting empty list to unblock UI.');
        _lastEvents = [];
        _eventsController.add([]);
      }
      await AppLogger.debug('Fetch failed');
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
