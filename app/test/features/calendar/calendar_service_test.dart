import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:happening/features/calendar/calendar_service.dart';

// Helper: build a gcal.Event from simple params.
gcal.Event _makeEvent({
  String id = 'evt-1',
  String? summary,
  String? startDateTimeIso,
  String? startDateIso, // all-day: only date, no time
  String? endDateTimeIso,
  String? endDateIso,
  String? htmlLink,
  String? hangoutLink,
  String? location,
  String? description,
  String? colorId,
}) {
  final e = gcal.Event()
    ..id = id
    ..summary = summary
    ..htmlLink = htmlLink
    ..hangoutLink = hangoutLink
    ..location = location
    ..description = description
    ..colorId = colorId;

  e.start = gcal.EventDateTime()
    ..dateTime =
        startDateTimeIso != null ? DateTime.parse(startDateTimeIso) : null
    ..date = startDateIso != null ? DateTime.parse(startDateIso) : null;

  e.end = gcal.EventDateTime()
    ..dateTime = endDateTimeIso != null ? DateTime.parse(endDateTimeIso) : null
    ..date = endDateIso != null ? DateTime.parse(endDateIso) : null;

  return e;
}

void main() {
  group('GoogleCalendarService.fromApiEvent', () {
    test('parses id, title, start, end, and htmlLink correctly', () {
      final apiEvent = _makeEvent(
        id: 'evt-1',
        summary: 'Team Standup',
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
        htmlLink: 'https://calendar.google.com/event?eid=abc',
      );

      final event = GoogleCalendarService.fromApiEvent(apiEvent);

      expect(event.id, equals('evt-1'));
      expect(event.title, equals('Team Standup'));
      expect(event.startTime,
          equals(DateTime.parse('2026-02-26T10:00:00').toLocal()));
      expect(event.endTime,
          equals(DateTime.parse('2026-02-26T10:30:00').toLocal()));
      expect(event.calendarEventUrl,
          equals('https://calendar.google.com/event?eid=abc'));
    });

    test('uses fallback title for null summary', () {
      final apiEvent = _makeEvent(
        summary: null,
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).title, '(No title)');
    });

    test('uses fallback title for empty summary', () {
      final apiEvent = _makeEvent(
        summary: '',
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).title, '(No title)');
    });

    test('extracts hangoutLink as videoCallUrl', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
        hangoutLink: 'https://meet.google.com/abc-def-ghi',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).videoCallUrl,
          equals('https://meet.google.com/abc-def-ghi'));
    });

    test('videoCallUrl is null when no video link present', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
        location: 'Conference Room B',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).videoCallUrl, isNull);
    });

    // ── S4-18: Event color from API colorId ──────────────────────────────

    test('no colorId defaults to Colors.blue', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).color,
          equals(Colors.blue));
    });

    test('colorId "1" → Lavender (#A4BDFC)', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
        colorId: '1',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).color,
          equals(const Color(0xFFA4BDFC)));
    });

    test('colorId "11" → Tomato (#DC2127)', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
        colorId: '11',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).color,
          equals(const Color(0xFFDC2127)));
    });

    // ── Sprint 5: Model Expansion ───────────────────────────────────────────

    test('populates calendarId and calendarName', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      final event = GoogleCalendarService.fromApiEvent(
        apiEvent,
        calendarId: 'work-cal',
        calendarName: 'Work',
      );
      expect(event.calendarId, equals('work-cal'));
      expect(event.calendarName, equals('Work'));
    });

    test('uses calendarColor when provided and no colorId present', () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      final event = GoogleCalendarService.fromApiEvent(
        apiEvent,
        calendarColor: Colors.red,
      );
      expect(event.color, equals(Colors.red));
    });

    test('maps status "completed" to isCompleted true', () {
      final apiEvent = gcal.Event(
        id: 'task-1',
        summary: 'Done Task',
        status: 'completed',
        start: gcal.EventDateTime(
            dateTime: DateTime.parse('2026-02-26T10:00:00Z')),
        end: gcal.EventDateTime(
            dateTime: DateTime.parse('2026-02-26T10:30:00Z')),
      );
      final event = GoogleCalendarService.fromApiEvent(apiEvent, isTask: true);
      expect(event.isCompleted, isTrue);
    });
  });

  group('CalendarMeta', () {
    test('parses colorHex correctly', () {
      const meta = CalendarMeta(
        id: 'c1',
        summary: 'Personal',
        colorHex: '#ff0000',
      );
      expect(meta.color, equals(const Color(0xFFFF0000)));
    });

    test('defaults to blue on null colorHex', () {
      const meta = CalendarMeta(
        id: 'c1',
        summary: 'Personal',
        colorHex: null,
      );
      expect(meta.color, equals(Colors.blue));
    });
  });
}
