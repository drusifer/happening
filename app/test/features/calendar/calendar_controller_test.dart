// Hermetic integration tests for CalendarController (S4-12).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/calendar/calendar_service.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

class _FakeCalendarService implements CalendarService {
  List<CalendarEvent> mockEvents = [];
  bool shouldThrow = false;
  int fetchCalls = 0;

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    return fetchTodayEvents();
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async {
    fetchCalls++;
    if (shouldThrow) throw Exception('service error');
    return mockEvents;
  }
}

/// Fake that throws for specific calendar IDs, succeeds for others.
class _PerCalendarFakeService implements CalendarService {
  final Set<String> throwingIds;
  final List<CalendarEvent> eventsForGoodCals;

  _PerCalendarFakeService({
    required this.throwingIds,
    required this.eventsForGoodCals,
  });

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    if (throwingIds.contains(calendarId))
      throw Exception('cal $calendarId failed');
    return eventsForGoodCals;
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => eventsForGoodCals;
}

class _BlockingCalendarService implements CalendarService {
  final _completers = <Completer<List<CalendarEvent>>>[];
  final requestedCalendarIds = <String>[];
  int fetchCalls = 0;

  int get pendingCalls => _completers.length;

  void completeNext(List<CalendarEvent> events) {
    _completers.removeAt(0).complete(events);
  }

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) {
    fetchCalls++;
    requestedCalendarIds.add(calendarId);
    final completer = Completer<List<CalendarEvent>>();
    _completers.add(completer);
    return completer.future;
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() => fetchEvents('primary');
}

class _MappedCalendarService implements CalendarService {
  _MappedCalendarService(this.eventsByCalendarId);

  final Map<String, List<CalendarEvent>> eventsByCalendarId;
  final requestedCalendarIds = <String>[];

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async => [];

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    requestedCalendarIds.add(calendarId);
    return eventsByCalendarId[calendarId] ?? [];
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() => fetchEvents('primary');
}

// ── Fixture ───────────────────────────────────────────────────────────────────

final _now = DateTime(2026, 2, 28, 10, 0);

CalendarEvent _event(String id) => CalendarEvent(
      id: id,
      title: id,
      startTime: _now.add(const Duration(minutes: 10)),
      endTime: _now.add(const Duration(minutes: 40)),
      color: Colors.blue,
      calendarEventUrl: null,
      videoCallUrl: null,
    );

CalendarEvent _calendarEvent(String id, String calendarId) =>
    _event(id).copyWith(calendarId: calendarId, calendarName: calendarId);

void main() {
  group('CalendarController', () {
    late _FakeCalendarService fakeService;
    late CalendarController controller;

    setUp(() {
      fakeService = _FakeCalendarService();
      controller = CalendarController(fakeService);
    });

    tearDown(() => controller.dispose());

    // ── start() ──────────────────────────────────────────────────────────────

    test('start() triggers immediate fetch → stream emits events', () async {
      fakeService.mockEvents = [_event('e1')];
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first.map((e) => e.id), equals(['e1']));
    });

    test('start() with empty service → stream emits empty list', () async {
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(1));
      expect(emitted.first, isEmpty);
    });

    test('start() calls service exactly once immediately', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(fakeService.fetchCalls, equals(1));
    });

    // ── refresh() ────────────────────────────────────────────────────────────

    test('refresh() calls service even when cache is fresh', () async {
      fakeService.mockEvents = [_event('e1')];
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(fakeService.fetchCalls, equals(1)); // cached after start

      await controller.refresh();
      expect(fakeService.fetchCalls,
          equals(2)); // forceRefresh=true bypasses cache
    });

    test('refresh() emits updated event list on second call', () async {
      // Prime with [e1]
      fakeService.mockEvents = [_event('e1')];
      await controller.refresh();

      // Subscribe BEFORE second refresh so we capture the next emission
      fakeService.mockEvents = [_event('e1'), _event('e2')];
      final nextEmission = controller.events.first;
      await controller.refresh();
      final result = await nextEmission;

      expect(result.map((e) => e.id).toList(), equals(['e1', 'e2']));
    });

    test('refresh() deduplicates events with same id', () async {
      fakeService.mockEvents = [_event('dup'), _event('dup')];

      // Subscribe before triggering fetch
      final nextEmission = controller.events.first;
      await controller.refresh();
      final result = await nextEmission;

      expect(result, hasLength(1));
    });

    test('overlapping refresh calls are ignored and return active future',
        () async {
      final blockingService = _BlockingCalendarService();
      final ctrl = CalendarController(blockingService);
      addTearDown(ctrl.dispose);

      final firstRefresh = ctrl.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(blockingService.fetchCalls, 1);
      expect(blockingService.pendingCalls, 1);

      final secondRefresh = ctrl.refresh();
      final thirdRefresh = ctrl.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(blockingService.fetchCalls, 1);
      blockingService.completeNext([_event('e1')]);
      await Future<void>.delayed(Duration.zero);

      await Future.wait([firstRefresh, secondRefresh, thirdRefresh]);
      expect(blockingService.fetchCalls, 1);
    });

    test('selected calendars are fetched sequentially after primary', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final settingsSvc = SettingsService(directory: tmp);
      await settingsSvc.load();
      await settingsSvc
          .update(const AppSettings(selectedCalendarIds: ['secondary']));

      final blockingService = _BlockingCalendarService();
      final ctrl =
          CalendarController(blockingService, settingsService: settingsSvc);
      addTearDown(ctrl.dispose);

      final refresh = ctrl.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(blockingService.fetchCalls, 1);
      expect(blockingService.pendingCalls, 1);
      expect(blockingService.requestedCalendarIds, ['primary']);

      blockingService.completeNext([_event('primary-event')]);
      await Future<void>.delayed(Duration.zero);

      expect(blockingService.fetchCalls, 2);
      expect(blockingService.pendingCalls, 1);
      expect(blockingService.requestedCalendarIds, ['primary', 'secondary']);

      blockingService.completeNext([_event('secondary-event')]);
      await refresh;

      expect(blockingService.fetchCalls, 2);
    });

    // ── Error handling ────────────────────────────────────────────────────────

    test('service error on start → stream emits empty list to unblock UI',
        () async {
      fakeService.shouldThrow = true;
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [[]]);
      expect(controller.lastEvents, isEmpty);
    });

    test(
        'service error on refresh → stream emits empty list (per-cal isolation)',
        () async {
      // With catchError per-calendar, a failing fetch returns [] for that calendar
      // rather than propagating — so the combined result IS emitted (as []).
      fakeService.mockEvents = [_event('e1')];
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(emitted.first.map((e) => e.id), equals(['e1']));

      fakeService.shouldThrow = true;
      await controller.refresh();

      // Failing calendar returns [] via catchError → stream emits [] (not retained).
      expect(emitted, hasLength(2));
      expect(emitted.last, isEmpty);
    });

    // ── stop() / dispose() ────────────────────────────────────────────────────

    test('stop() halts polling (no additional fetches after stop)', () async {
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(fakeService.fetchCalls, equals(1));

      controller.stop();
      // No more fetches fire spontaneously after stop
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fakeService.fetchCalls, equals(1));
    });

    test('dispose() closes the events stream', () async {
      bool streamClosed = false;
      controller.events.listen(null, onDone: () => streamClosed = true);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(streamClosed, isTrue);
    });

    test('always includes primary in fetch list', () async {
      // Logic check: if we have 0 selected, it should call fetch once (for primary).
      await controller.refresh();
      expect(fakeService.fetchCalls, 1);
    });

    test('per-calendar error: failing calendar does not block successful ones',
        () async {
      // 'primary' succeeds, 'secondary' throws — stream must still emit primary events.
      final tmp = Directory.systemTemp.createTempSync();
      final settingsSvc = SettingsService(directory: tmp);
      await settingsSvc.load();
      await settingsSvc
          .update(const AppSettings(selectedCalendarIds: ['secondary']));

      final isolationService = _PerCalendarFakeService(
        throwingIds: {'secondary'},
        eventsForGoodCals: [_event('primary-event')],
      );
      final ctrl =
          CalendarController(isolationService, settingsService: settingsSvc);
      addTearDown(ctrl.dispose);

      final nextEmission = ctrl.events.first;
      await ctrl.refresh();
      final result = await nextEmission;

      // Only primary-event survives — secondary's error was swallowed.
      expect(result.map((e) => e.id).toList(), equals(['primary-event']));
    });

    test('fetches primary AND selected secondary calendars', () async {
      // Mock SettingsService with a secondary calendar
      final tmp = Directory.systemTemp.createTempSync();
      final settingsSvc = SettingsService(directory: tmp);
      await settingsSvc.load();
      await settingsSvc
          .update(const AppSettings(selectedCalendarIds: ['secondary']));

      final controller2 =
          CalendarController(fakeService, settingsService: settingsSvc);
      addTearDown(controller2.dispose);

      await controller2.refresh();
      // Should fetch 'primary' (Set default) and 'secondary' (selected)
      expect(fakeService.fetchCalls, 2);
    });

    test('dedup removes same recurring event id from selected calendars',
        () async {
      final tmp = Directory.systemTemp.createTempSync();
      final settingsSvc = SettingsService(directory: tmp);
      await settingsSvc.load();
      await settingsSvc
          .update(const AppSettings(selectedCalendarIds: ['secondary']));

      final mappedService = _MappedCalendarService({
        'primary': [_calendarEvent('same-id', 'primary')],
        'secondary': [_calendarEvent('same-id', 'secondary')],
      });
      final ctrl =
          CalendarController(mappedService, settingsService: settingsSvc);
      addTearDown(ctrl.dispose);

      final nextEmission = ctrl.events.first;
      await ctrl.refresh();
      final result = await nextEmission;

      expect(mappedService.requestedCalendarIds, ['primary', 'secondary']);
      expect(result.map((e) => '${e.calendarId}:${e.id}'), ['primary:same-id']);
    });
  });
}
