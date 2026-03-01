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

    // ── S4-16: isTask flag ────────────────────────────────────────────────────

    // ── BUG repro: tasks appear in primary calendar as eventType=focusTime ────
    // Real fixture from Drew 2026-02-28. The @tasks fetch was never needed —
    // tasks are already in the primary feed with eventType=="focusTime".

    // ── BUG: colorId ordering wrong (Drew 2026-02-28) ────────────────────────
    // Live API data: "stuff color tomato" has colorId=11 → must be red (#D50000)
    //                "Green" has colorId=2 → must be green (#33B679)
    // Correct GCal mapping: 1=Lavender, 2=Sage, 3=Grape, 4=Flamingo, 5=Banana,
    //   6=Tangerine, 7=Peacock, 8=Blueberry, 9=Basil, 10=Graphite, 11=Tomato

    test('colorId 11 → Tomato (#DC2127)', () {
      // GCal classic palette. Drew 2026-02-28: selecting Tomato yields colorId 11.
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '61ij4d1n6him4bb46lij8b9k6hh34bb2coqj4b9ocos68e316li32c9gcc',
        'summary': 'stuff color tomato',
        'start': {'dateTime': '2026-02-28T04:45:00.000Z'},
        'end': {'dateTime': '2026-02-28T05:45:00.000Z'},
        'eventType': 'default',
        'colorId': '11',
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
      }));
      expect(event.color, const Color(0xFFDC2127),
          reason: 'colorId 11 = Tomato');
    });

    test('colorId 2 → Sage (#7AE7BF)', () {
      // Drew 2026-02-28: "Green" event has colorId 2.
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '0nn53tfkku7o14d808b7kapt0c',
        'summary': 'Green',
        'start': {'dateTime': '2026-02-28T07:30:00.000Z'},
        'end': {'dateTime': '2026-02-28T08:30:00.000Z'},
        'eventType': 'default',
        'colorId': '2',
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
      }));
      expect(event.color, const Color(0xFF7AE7BF),
          reason: 'colorId 2 = Sage');
    });

    test('colorId 10 → Basil (#51B749)', () {
      // Drew 2026-02-28: "fiver green" event has colorId 10.
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '65i32c9ic5i3gb9lc4r3eb9k6gp32bb164omcbb470o6ap9g65j68cr664',
        'summary': 'fiver green',
        'start': {'dateTime': '2026-03-01T02:45:00.000Z'},
        'end': {'dateTime': '2026-03-01T02:50:00.000Z'},
        'eventType': 'default',
        'colorId': '10',
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
      }));
      expect(event.color, const Color(0xFF51B749),
          reason: 'colorId 10 = Basil (green)');
    });

    test('upcoming task — eventType:focusTime sets isTask:true', () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '3oeba561jrn5f2m6utrjvcj4n0',
        'summary': 'upcoming task',
        'start': {
          'dateTime': '2026-02-28T06:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'end': {
          'dateTime': '2026-02-28T07:00:00.000Z',
          'timeZone': 'America/New_York',
        },
        'eventType': 'focusTime',
        'focusTimeProperties': {'autoDeclineMode': 'declineNone'},
        'htmlLink':
            'https://www.google.com/calendar/event?eid=M29lYmE1NjFqcm41ZjJtNnV0cmp2Y2o0bjAgZHJ1c2lmZXJAbQ',
        'description':
            'Changes made to the title, description, or attachments will not be saved. To make edits, please go to: https://tasks.google.com/task/V_jIpYwDILwTFP7D',
        'transparency': 'transparent',
        'visibility': 'private',
        'status': 'confirmed',
      }));
      expect(event.isTask, isTrue);
      expect(event.title, 'upcoming task');
    });

    test('regular event — eventType:default keeps isTask:false', () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': '61ij4d1n6him4bb46lij8b9k6hh34bb2coqj4b9ocos68e316li32c9gcc',
        'summary': 'stuff color tomato',
        'start': {'dateTime': '2026-02-28T04:45:00.000Z'},
        'end': {'dateTime': '2026-02-28T05:45:00.000Z'},
        'eventType': 'default',
        'colorId': '11',
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
      }));
      expect(event.isTask, isFalse);
    });

    test('fromApiEvent — isTask defaults to false for regular event', () {
      final event = GoogleCalendarService.fromApiEvent(gcal.Event.fromJson({
        'id': 'evt-regular',
        'summary': 'Stand-up',
        'start': {'dateTime': '2026-02-28T14:00:00.000Z'},
        'end': {'dateTime': '2026-02-28T14:30:00.000Z'},
        'htmlLink': 'https://www.google.com/calendar/event?eid=abc',
      }));
      expect(event.isTask, isFalse);
    });

    test('fromApiEvent — isTask:true when called with isTask flag', () {
      final event = GoogleCalendarService.fromApiEvent(
        gcal.Event.fromJson({
          'id': 'task-1',
          'summary': 'Review PR',
          'start': {'dateTime': '2026-02-28T15:00:00.000Z'},
          'end': {'dateTime': '2026-02-28T15:30:00.000Z'},
          'htmlLink': 'https://www.google.com/calendar/event?eid=xyz',
        }),
        isTask: true,
      );
      expect(event.isTask, isTrue);
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
