// Google Calendar API service.
//
// TLDR:
// Overview: Fetches and parses today's events from the Google Calendar API.
// Problem: Need to retrieve data from Google's servers and convert to internal models.
// Solution: Implements GoogleCalendarService using the googleapis package.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

import 'calendar_event.dart';
import 'video_link_extractor.dart';

/// Metadata for a single Google Calendar.
class CalendarMeta {
  const CalendarMeta({
    required this.id,
    required this.summary,
    required this.colorHex,
  });

  final String id;
  final String summary;
  final String? colorHex;

  Color get color => colorHex != null
      ? Color(int.parse(colorHex!.replaceFirst('#', '0xFF')))
      : Colors.blue;
}

abstract class CalendarService {
  Future<List<CalendarMeta>> fetchCalendarList();
  Future<List<CalendarEvent>> fetchEvents(String calendarId);
  Future<List<CalendarEvent>> fetchTodayEvents();
}

class GoogleCalendarService implements CalendarService {
  GoogleCalendarService(this._api);
  final gcal.CalendarApi _api;

  @override
  Future<List<CalendarMeta>> fetchCalendarList() async {
    final list = await _api.calendarList.list();
    return (list.items ?? [])
        .map((e) => CalendarMeta(
              id: e.id ?? '',
              summary: e.summary ?? '(No title)',
              colorHex: e.backgroundColor,
            ))
        .toList();
  }

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() => fetchEvents('primary');

  @override
  Future<List<CalendarEvent>> fetchEvents(String calendarId) async {
    final now = DateTime.now();
    // Fetch 48 hours starting from the beginning of today
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = start.add(const Duration(days: 2));

    final response = await _api.events.list(
      calendarId,
      timeMin: start,
      timeMax: end,
      singleEvents: true,
      orderBy: 'startTime',
      eventTypes: ['default', 'focusTime', 'outOfOffice'],
    );

    // Append full raw API response for fixture capture (dev only).
    if (kDebugMode && calendarId == 'primary') {
      _appendToFixtureLog(response.toJson());
    }

    // Fetch calendar metadata to get the name
    String? calendarName;
    try {
      final meta = await _api.calendarList.get(calendarId);
      calendarName = meta.summary;
    } catch (_) {}

    final events = (response.items ?? [])
        .where((e) => e.start?.dateTime != null)
        .map((e) => fromApiEvent(
              e,
              calendarId: calendarId,
              calendarName: calendarName ?? 'Calendar',
            ))
        .toList();

    // S5-FIX: Query separate @tasks feed for point-in-time tasks.
    if (calendarId == 'primary') {
      try {
        final taskResponse = await _api.events.list(
          '@tasks',
          timeMin: start,
          timeMax: end,
          // NOTE: @tasks doesn't support eventTypes filter, returns all point tasks.
        );
        final tasks = (taskResponse.items ?? [])
            .where((e) => e.start?.dateTime != null)
            .map((e) => fromApiEvent(
                  e,
                  isTask: true,
                  calendarId: 'tasks',
                  calendarName: 'Tasks',
                ))
            .toList();
        events.addAll(tasks);
      } catch (_) {}
    }

    return events;
  }

  /// Appends [json] as one line to `test/fixtures/calendar_api_raw.jsonl`
  /// (relative to CWD — run via `flutter run` from the `app/` directory).
  /// Silently swallows errors so a log failure never crashes the app.
  static void _appendToFixtureLog(Map<String, dynamic> json) {
    try {
      final file = File(
          '${Directory.current.path}/test/fixtures/calendar_api_raw.jsonl');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${jsonEncode(json)}\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('[CalendarAPI] fixture log write failed: $e');
    }
  }

  /// Google Calendar event colorId → Flutter Color.
  /// Source: Google Calendar API v3 colors.get — "classic" palette.
  /// https://google-calendar-simple-api.readthedocs.io/en/latest/colors.html
  /// Verified against live API data (Drew 2026-02-28):
  ///   colorId 2=Sage, colorId 10=Basil, colorId 11=Tomato.
  static const _kEventColors = <String, Color>{
    '1': Color(0xFFA4BDFC), // Lavender
    '2': Color(0xFF7AE7BF), // Sage
    '3': Color(0xFFDBADFF), // Grape
    '4': Color(0xFFFF887C), // Flamingo
    '5': Color(0xFFFBD75B), // Banana
    '6': Color(0xFFFFB878), // Tangerine
    '7': Color(0xFF46D6DB), // Peacock
    '8': Color(0xFFE1E1E1), // Graphite
    '9': Color(0xFF5484ED), // Blueberry
    '10': Color(0xFF51B749), // Basil
    '11': Color(0xFFDC2127), // Tomato
  };

  /// Converts a Google Calendar API `Event` to a `CalendarEvent`.
  static CalendarEvent fromApiEvent(
    gcal.Event e, {
    bool isTask = false,
    String calendarId = 'primary',
    String calendarName = 'Primary',
  }) {
    // Log raw API payload — copy from debug console to build test fixtures.
    debugPrint('[CalendarAPI] ${jsonEncode(e.toJson())}');
    // Tasks synced from Google Tasks appear in the primary calendar feed
    // with eventType=="focusTime" rather than from a separate @tasks feed.
    if (e.eventType == 'focusTime') isTask = true;

    final entryPoints = e.conferenceData?.entryPoints
        ?.where((ep) => ep.entryPointType == 'video')
        .map((ep) => ep.uri)
        .whereType<String>()
        .toList();

    // S5-FIX: Tasks sometimes lack an end time but MUST have a start dateTime to be on the strip.
    final startTime = e.start!.dateTime!.toLocal();
    final endTime = e.end?.dateTime?.toLocal() ?? startTime;

    return CalendarEvent(
      id: e.id ?? '',
      title: (e.summary?.isNotEmpty ?? false) ? e.summary! : '(No title)',
      startTime: startTime,
      endTime: endTime,
      color: _kEventColors[e.colorId] ?? Colors.blue, // S4-18
      calendarEventUrl: e.htmlLink,
      videoCallUrl: VideoLinkExtractor.extract(
        hangoutLink: e.hangoutLink,
        conferenceEntryPoints: entryPoints,
        location: e.location,
        description: e.description,
      ),
      isTask: isTask,
      calendarId: calendarId,
      calendarName: calendarName,
      description: e.description,
      isCompleted: e.status == 'completed',
    );
  }
}
