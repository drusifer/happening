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
      expect(fakeService.fetchCalls, equals(2)); // forceRefresh=true bypasses cache
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

    // ── Error handling ────────────────────────────────────────────────────────

    test('service error on start → stream does not emit', () async {
      fakeService.shouldThrow = true;
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
    });

    test('service error on refresh → stream retains last value', () async {
      fakeService.mockEvents = [_event('e1')];
      final emitted = <List<CalendarEvent>>[];
      controller.events.listen(emitted.add);

      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));

      fakeService.shouldThrow = true;
      await controller.refresh();

      // No new emission — stream keeps last value
      expect(emitted, hasLength(1));
      expect(emitted.first.first.id, equals('e1'));
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

    test('fetches primary AND selected secondary calendars', () async {
      // Mock SettingsService with a secondary calendar
      final tmp = Directory.systemTemp.createTempSync();
      final settingsSvc = SettingsService(directory: tmp);
      await settingsSvc.load();
      await settingsSvc.update(const AppSettings(selectedCalendarIds: ['secondary']));
      
      final controller2 = CalendarController(fakeService, settingsService: settingsSvc);
      addTearDown(controller2.dispose);
      
      await controller2.refresh();
      // Should fetch 'primary' (Set default) and 'secondary' (selected)
      expect(fakeService.fetchCalls, 2); 
    });
  });
}
