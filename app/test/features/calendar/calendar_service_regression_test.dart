// Regression tests using real Google Calendar API payloads captured 2026-02-27.
// These fixtures come directly from debugPrint('[CalendarAPI] ...') output.
// Do NOT edit the fixture maps — they represent ground-truth API responses.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:happening/features/calendar/calendar_service.dart';

void main() {
  group('GoogleCalendarService.fromApiEvent — real API fixtures (2026-02-27)',
      () {
    // ── Event 1: Matt Lunch ──────────────────────────────────────────────────
    // Physical restaurant location; no hangoutLink, no conferenceData.
    // videoCallUrl must be null (restaurant address ≠ video URL).

    test('Matt Lunch — id, title, start, end, calendarEventUrl are correct',
        () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '6li3gd9k69ijeb9p6co36b9kcks3cbb260om4b9jccs6adb66oo32pb468',
        'summary': 'Matt Lunch',
        'start': {
          'dateTime': '2026-02-27T17:30:00.000Z',
          'timeZone': 'America/New_York',
        },
        'end': {
          'dateTime': '2026-02-27T18:30:00.000Z',
          'timeZone': 'America/New_York',
        },
        'htmlLink':
            'https://www.google.com/calendar/event?eid=NmxpM2dkOWs2OWlqZWI5cDZjbzM2YjlrY2tzM2NiYjI2MG9tNGI5amNjczZhZGI2Nm9vMzJwYjQ2OCBkcnVzaWZlckBt',
        'location':
            'Catalyst Restaurant, 300 Technology Square, Cambridge, MA 02139, USA',
        'kind': 'calendar#event',
        'status': 'confirmed',
        'eventType': 'default',
        'created': '2026-02-27T14:58:57.000Z',
        'updated': '2026-02-27T14:58:57.187Z',
        'creator': {'email': 'drusifer@gmail.com', 'self': true},
        'organizer': {'email': 'drusifer@gmail.com', 'self': true},
        'reminders': {'useDefault': true},
        'sequence': 0,
        'iCalUID':
            '6li3gd9k69ijeb9p6co36b9kcks3cbb260om4b9jccs6adb66oo32pb468@google.com',
        'etag': '"3544408674374270"',
      }));

      expect(event.id,
          '6li3gd9k69ijeb9p6co36b9kcks3cbb260om4b9jccs6adb66oo32pb468');
      expect(event.title, 'Matt Lunch');
      expect(event.startTime,
          DateTime.parse('2026-02-27T17:30:00.000Z').toLocal());
      expect(
          event.endTime, DateTime.parse('2026-02-27T18:30:00.000Z').toLocal());
      expect(
        event.calendarEventUrl,
        'https://www.google.com/calendar/event?eid=NmxpM2dkOWs2OWlqZWI5cDZjbzM2YjlrY2tzM2NiYjI2MG9tNGI5amNjczZhZGI2Nm9vMzJwYjQ2OCBkcnVzaWZlckBt',
      );
      expect(event.color, Colors.blue);
    });

    test('Matt Lunch — videoCallUrl is null (restaurant location, no video)',
        () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '6li3gd9k69ijeb9p6co36b9kcks3cbb260om4b9jccs6adb66oo32pb468',
        'summary': 'Matt Lunch',
        'start': {'dateTime': '2026-02-27T17:30:00.000Z'},
        'end': {'dateTime': '2026-02-27T18:30:00.000Z'},
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
        'location':
            'Catalyst Restaurant, 300 Technology Square, Cambridge, MA 02139, USA',
      }));

      expect(event.videoCallUrl, isNull);
    });

    // ── Event 2: hazel tourney ───────────────────────────────────────────────
    // No conferenceData, no hangoutLink, no location field.
    // videoCallUrl must be null.

    test('hazel tourney — id, title, start, end, calendarEventUrl are correct',
        () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '68rjapj2cphjab9hckoj2b9k60rm8bb270ojgbb1c4r38ob66dhjie1o6o',
        'summary': 'hazel tourney',
        'start': {
          'dateTime': '2026-02-27T21:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'end': {
          'dateTime': '2026-02-27T22:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'htmlLink':
            'https://www.google.com/calendar/event?eid=NjhyamFwajJjcGhqYWI5aGNrb2oyYjlrNjBybThiYjI3MG9qZ2JiMWM0cjM4b2I2NmRoamllMW82byBkcnVzaWZlckBt',
        'kind': 'calendar#event',
        'status': 'confirmed',
        'eventType': 'default',
        'created': '2026-02-27T20:15:41.000Z',
        'updated': '2026-02-27T20:15:41.426Z',
        'creator': {'email': 'drusifer@gmail.com', 'self': true},
        'organizer': {'email': 'drusifer@gmail.com', 'self': true},
        'reminders': {'useDefault': true},
        'sequence': 0,
        'iCalUID':
            '68rjapj2cphjab9hckoj2b9k60rm8bb270ojgbb1c4r38ob66dhjie1o6o@google.com',
        'etag': '"3544446682853822"',
      }));

      expect(event.id,
          '68rjapj2cphjab9hckoj2b9k60rm8bb270ojgbb1c4r38ob66dhjie1o6o');
      expect(event.title, 'hazel tourney');
      expect(event.startTime,
          DateTime.parse('2026-02-27T21:00:00.000Z').toLocal());
      expect(
          event.endTime, DateTime.parse('2026-02-27T22:00:00.000Z').toLocal());
      expect(
        event.calendarEventUrl,
        'https://www.google.com/calendar/event?eid=NjhyamFwajJjcGhqYWI5aGNrb2oyYjlrNjBybThiYjI3MG9qZ2JiMWM0cjM4b2I2NmRoamllMW82byBkcnVzaWZlckBt',
      );
      expect(event.videoCallUrl, isNull);
    });

    // ── Event 3: dinner (test name change) ───────────────────────────────────
    // Has both hangoutLink and conferenceData with a video entryPoint.
    // videoCallUrl must be "https://meet.google.com/kdj-gcqz-wti".

    test('dinner — extracts Google Meet URL via hangoutLink (priority 1)', () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '6grjcoj16lgjabb268rm4b9kc9gj8bb2cko34b9kc4s3aphnc9h6adhpco',
        'summary': 'dinner (test name change)',
        'start': {
          'dateTime': '2026-02-27T23:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'end': {
          'dateTime': '2026-02-28T00:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'hangoutLink': 'https://meet.google.com/kdj-gcqz-wti',
        'htmlLink':
            'https://www.google.com/calendar/event?eid=NmdyamNvajE2bGdqYWJiMjY4cm00YjlrYzlnajhiYjJja28zNGI5a2M0czNhcGhuYzloNmFkaHBjbyBkcnVzaWZlckBt',
        'conferenceData': {
          'conferenceId': 'kdj-gcqz-wti',
          'conferenceSolution': {
            'iconUri':
                'https://fonts.gstatic.com/s/i/productlogos/meet_2020q4/v6/web-512dp/logo_meet_2020q4_color_2x_web_512dp.png',
            'key': {'type': 'hangoutsMeet'},
            'name': 'Google Meet',
          },
          'entryPoints': [
            {
              'entryPointType': 'video',
              'label': 'meet.google.com/kdj-gcqz-wti',
              'uri': 'https://meet.google.com/kdj-gcqz-wti',
            },
          ],
        },
        'kind': 'calendar#event',
        'status': 'confirmed',
        'eventType': 'default',
        'created': '2026-02-27T20:15:51.000Z',
        'updated': '2026-02-27T21:03:12.687Z',
        'creator': {'email': 'drusifer@gmail.com', 'self': true},
        'organizer': {'email': 'drusifer@gmail.com', 'self': true},
        'reminders': {'useDefault': true},
        'sequence': 0,
        'iCalUID':
            '6grjcoj16lgjabb268rm4b9kc9gj8bb2cko34b9kc4s3aphnc9h6adhpco@google.com',
        'etag': '"3544452385374046"',
      }));

      expect(event.id,
          '6grjcoj16lgjabb268rm4b9kc9gj8bb2cko34b9kc4s3aphnc9h6adhpco');
      expect(event.title, 'dinner (test name change)');
      expect(event.startTime,
          DateTime.parse('2026-02-27T23:00:00.000Z').toLocal());
      expect(
          event.endTime, DateTime.parse('2026-02-28T00:00:00.000Z').toLocal());
      expect(
        event.calendarEventUrl,
        'https://www.google.com/calendar/event?eid=NmdyamNvajE2bGdqYWJiMjY4cm00YjlrYzlnajhiYjJja28zNGI5a2M0czNhcGhuYzloNmFkaHBjbyBkcnVzaWZlckBt',
      );
      expect(event.videoCallUrl, 'https://meet.google.com/kdj-gcqz-wti');
    });

    test('dinner — conferenceData entryPoint fallback also resolves Meet URL',
        () {
      // Same event but without hangoutLink — verifies the conferenceData path.
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '6grjcoj16lgjabb268rm4b9kc9gj8bb2cko34b9kc4s3aphnc9h6adhpco',
        'summary': 'dinner (test name change)',
        'start': {'dateTime': '2026-02-27T23:00:00.000Z'},
        'end': {'dateTime': '2026-02-28T00:00:00.000Z'},
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
        // hangoutLink intentionally omitted
        'conferenceData': {
          'conferenceId': 'kdj-gcqz-wti',
          'conferenceSolution': {
            'key': {'type': 'hangoutsMeet'},
            'name': 'Google Meet',
          },
          'entryPoints': [
            {
              'entryPointType': 'video',
              'label': 'meet.google.com/kdj-gcqz-wti',
              'uri': 'https://meet.google.com/kdj-gcqz-wti',
            },
          ],
        },
      }));

      // Falls back to conferenceData video entryPoint (priority 2)
      expect(event.videoCallUrl, 'https://meet.google.com/kdj-gcqz-wti');
    });
  });
}
