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

    // ── Sprint 5: Model Expansion ───────────────────────────────────────────

    test('expansion fields have correct defaults', () {
      expect(event.calendarId, equals('primary'));
      expect(event.calendarName, equals('Primary'));
      expect(event.description, isNull);
      expect(event.isCompleted, isFalse);
    });

    test('copyWith updates expansion fields', () {
      final updated = event.copyWith(
        calendarId: 'work-cal',
        calendarName: 'Work',
        description: 'Meeting notes here',
        isCompleted: true,
      );
      expect(updated.calendarId, equals('work-cal'));
      expect(updated.calendarName, equals('Work'));
      expect(updated.description, equals('Meeting notes here'));
      expect(updated.isCompleted, isTrue);
    });

    test('copyWith preserves expansion fields when not overridden', () {
      final custom = event.copyWith(calendarId: 'custom-cal', isCompleted: true);
      final copy = custom.copyWith(title: 'New Title');
      expect(copy.calendarId, equals('custom-cal'));
      expect(copy.isCompleted, isTrue);
      expect(copy.title, equals('New Title'));
    });
  });

  group('detectCollisions', () {
    final now = DateTime(2026, 3, 1, 10, 0);

    CalendarEvent _ev(String id, DateTime start, DateTime end) => CalendarEvent(
          id: id,
          title: id,
          startTime: start,
          endTime: end,
          color: Colors.blue,
          calendarEventUrl: null,
          videoCallUrl: null,
        );

    test('returns empty set for empty list', () {
      expect(detectCollisions([]), isEmpty);
    });

    test('returns empty set for non-overlapping events', () {
      final e1 = _ev('e1', now, now.add(const Duration(minutes: 30)));
      final e2 = _ev('e2', now.add(const Duration(minutes: 31)),
          now.add(const Duration(minutes: 60)));
      expect(detectCollisions([e1, e2]), isEmpty);
    });

    test('returns both IDs for overlapping events', () {
      final e1 = _ev('e1', now, now.add(const Duration(minutes: 30)));
      final e2 = _ev('e2', now.add(const Duration(minutes: 15)),
          now.add(const Duration(minutes: 45)));
      expect(detectCollisions([e1, e2]), equals({'e1', 'e2'}));
    });

    test('returns all IDs for triple overlap', () {
      final e1 = _ev('e1', now, now.add(const Duration(minutes: 30)));
      final e2 = _ev('e2', now.add(const Duration(minutes: 15)),
          now.add(const Duration(minutes: 45)));
      final e3 = _ev('e3', now.add(const Duration(minutes: 20)),
          now.add(const Duration(minutes: 25)));
      expect(detectCollisions([e1, e2, e3]), equals({'e1', 'e2', 'e3'}));
    });

    test('back-to-back events do NOT collide', () {
      final e1 = _ev('e1', now, now.add(const Duration(minutes: 30)));
      final e2 = _ev('e2', now.add(const Duration(minutes: 30)),
          now.add(const Duration(minutes: 60)));
      expect(detectCollisions([e1, e2]), isEmpty);
    });
  });
}
