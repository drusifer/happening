import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';

void main() {
  group('CalendarEvent', () {
    final start = DateTime(2026, 2, 26, 10, 0);
    final end = DateTime(2026, 2, 26, 10, 30);

    final event = CalendarEvent(
      id: 'evt-1',
      title: 'Team Standup',
      startTime: start,
      endTime: end,
      color: Colors.blue,
      calendarEventUrl: 'https://calendar.google.com/event?eid=abc',
      videoCallUrl: 'https://meet.google.com/abc-def-ghi',
    );

    test('duration returns correct value', () {
      expect(event.duration, equals(const Duration(minutes: 30)));
    });

    test('isNow returns true when current time is within event', () {
      final duringEvent = start.add(const Duration(minutes: 15));
      expect(event.isNow(duringEvent), isTrue);
    });

    test('isNow returns false before event starts', () {
      final before = start.subtract(const Duration(minutes: 1));
      expect(event.isNow(before), isFalse);
    });

    test('isNow returns false after event ends', () {
      final after = end.add(const Duration(minutes: 1));
      expect(event.isNow(after), isFalse);
    });

    test('isPast returns true after event ends', () {
      final after = end.add(const Duration(minutes: 1));
      expect(event.isPast(after), isTrue);
    });

    test('isPast returns false before event ends', () {
      expect(event.isPast(start), isFalse);
    });

    test('equality is based on id', () {
      final sameId = CalendarEvent(
        id: 'evt-1',
        title: 'Different Title',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        color: Colors.red,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      expect(event, equals(sameId));
    });

    test('hashCode is based on id', () {
      final sameId = CalendarEvent(
        id: 'evt-1',
        title: 'Other',
        startTime: DateTime(2026, 1, 1),
        endTime: DateTime(2026, 1, 1, 1),
        color: Colors.green,
        calendarEventUrl: null,
        videoCallUrl: null,
      );
      expect(event.hashCode, equals(sameId.hashCode));
    });

    test('copyWith returns updated event', () {
      final updated = event.copyWith(title: 'Updated Standup');
      expect(updated.title, equals('Updated Standup'));
      expect(updated.id, equals(event.id));
      expect(updated.startTime, equals(event.startTime));
    });

    // ── S4-16: isTask ─────────────────────────────────────────────────────────

    test('isTask defaults to false for regular events', () {
      expect(event.isTask, isFalse);
    });

    test('isTask can be set to true via constructor', () {
      final task = CalendarEvent(
        id: 'task-1',
        title: 'Review PR',
        startTime: start,
        endTime: end,
        color: Colors.green,
        calendarEventUrl: null,
        videoCallUrl: null,
        isTask: true,
      );
      expect(task.isTask, isTrue);
    });

    test('copyWith preserves isTask when not overridden', () {
      final task = event.copyWith(isTask: true);
      final copy = task.copyWith(title: 'Same task, new title');
      expect(copy.isTask, isTrue);
    });

    test('copyWith can toggle isTask', () {
      final task = event.copyWith(isTask: true);
      final demoted = task.copyWith(isTask: false);
      expect(demoted.isTask, isFalse);
    });

    test('toString includes isTask', () {
      final task = event.copyWith(isTask: true);
      expect(task.toString(), contains('isTask: true'));
    });
  });
}
