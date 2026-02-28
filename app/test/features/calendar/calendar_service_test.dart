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
}) {
  final e = gcal.Event()
    ..id = id
    ..summary = summary
    ..htmlLink = htmlLink
    ..hangoutLink = hangoutLink
    ..location = location
    ..description = description;

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

    test('all-day event has null start.dateTime (filter marker)', () {
      final allDay = _makeEvent(
        startDateIso: '2026-02-26',
        endDateIso: '2026-02-27',
      );
      // Callers must filter events where start.dateTime == null before
      // calling fromApiEvent. This test documents that contract.
      expect(allDay.start?.dateTime, isNull);
    });

    test(
        'event color defaults to blue (Sprint 3: F-09 will parse calendar color)',
        () {
      final apiEvent = _makeEvent(
        startDateTimeIso: '2026-02-26T10:00:00',
        endDateTimeIso: '2026-02-26T10:30:00',
      );
      expect(GoogleCalendarService.fromApiEvent(apiEvent).color,
          equals(Colors.blue));
    });
  });
}
