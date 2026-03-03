import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';
import 'package:happening/features/calendar/event_repository.dart';

class _FakeCalendarService implements CalendarService {
  List<CalendarEvent> events;
  int callCount = 0;

  _FakeCalendarService(this.events);

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async =>
      fetchTodayEvents();

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async {
    callCount++;
    return List.from(events);
  }
}

CalendarEvent _event(String id) => CalendarEvent(
      id: id,
      title: 'Event $id',
      startTime: DateTime(2026, 2, 26, 10, 0),
      endTime: DateTime(2026, 2, 26, 10, 30),
      color: Colors.blue,
      calendarEventUrl: null,
      videoCallUrl: null,
    );

void main() {
  group('EventRepository', () {
    test('first call fetches from service', () async {
      final service = _FakeCalendarService([_event('a'), _event('b')]);
      final repo = EventRepository(service);

      final events = await repo.getEvents();

      expect(events.length, equals(2));
      expect(service.callCount, equals(1));
    });

    test('second call within cache window uses cache (no extra fetch)',
        () async {
      final service = _FakeCalendarService([_event('a')]);
      final repo = EventRepository(service);

      await repo.getEvents();
      await repo.getEvents();

      expect(service.callCount, equals(1));
    });

    test('forceRefresh bypasses cache and re-fetches', () async {
      final service = _FakeCalendarService([_event('a')]);
      final repo = EventRepository(service);

      await repo.getEvents();
      await repo.getEvents(forceRefresh: true);

      expect(service.callCount, equals(2));
    });

    test('deduplicates events with the same id', () async {
      final service = _FakeCalendarService([_event('a'), _event('a')]);
      final repo = EventRepository(service);

      final events = await repo.getEvents();

      expect(events.length, equals(1));
      expect(events.first.id, equals('a'));
    });

    test('invalidate causes next call to re-fetch', () async {
      final service = _FakeCalendarService([_event('a')]);
      final repo = EventRepository(service);

      await repo.getEvents();
      repo.invalidate();
      await repo.getEvents();

      expect(service.callCount, equals(2));
    });

    test('forceRefresh reflects updated service data', () async {
      final service = _FakeCalendarService([_event('a')]);
      final repo = EventRepository(service);

      await repo.getEvents();
      service.events = [_event('a'), _event('b')];
      final fresh = await repo.getEvents(forceRefresh: true);

      expect(fresh.length, equals(2));
    });

    test('returns empty list when service returns no events', () async {
      final service = _FakeCalendarService([]);
      final repo = EventRepository(service);

      expect(await repo.getEvents(), isEmpty);
    });

    test('preserves event order from service', () async {
      final e1 = _event('a');
      final e2 = _event('b');
      final e3 = _event('c');
      final service = _FakeCalendarService([e1, e2, e3]);
      final repo = EventRepository(service);

      final events = await repo.getEvents();

      expect(events.map((e) => e.id).toList(), equals(['a', 'b', 'c']));
    });
  });
}
