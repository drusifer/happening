/// Event data repository and cache.
///
/// TLDR:
/// Overview: Manages the lifecycle and deduplication of calendar event data.
/// Problem: Need to prevent redundant API calls and handle duplicates.
/// Solution: Implements a 5-minute cache and ID-based deduplication for the CalendarService.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'calendar_event.dart';
import 'calendar_service.dart';

class EventRepository {
  EventRepository(this._service);
  final CalendarService _service;

  List<CalendarEvent> _cache = const [];
  DateTime? _fetchedAt;
  static const _maxAge = Duration(minutes: 5);

  Future<List<CalendarEvent>> getEvents({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _fetchedAt != null &&
        now.difference(_fetchedAt!) < _maxAge) {
      return _cache;
    }
    final fresh = await _service.fetchTodayEvents();
    _cache = _dedup(fresh);
    _fetchedAt = now;
    return _cache;
  }

  void invalidate() => _fetchedAt = null;

  static List<CalendarEvent> _dedup(List<CalendarEvent> events) {
    final seen = <String>{};
    return events.where((e) => seen.add(e.id)).toList();
  }
}
