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

abstract class CalendarService {
  Future<List<CalendarEvent>> fetchTodayEvents();
}

class GoogleCalendarService implements CalendarService {
  GoogleCalendarService(this._api);
  final gcal.CalendarApi _api;

  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toUtc();
    final end = DateTime(now.year, now.month, now.day + 1).toUtc();

    final response = await _api.events.list(
      'primary',
      timeMin: start,
      timeMax: end,
      singleEvents: true,
      orderBy: 'startTime',
    );

    // Append full raw API response for fixture capture (dev only).
    if (kDebugMode) {
      _appendToFixtureLog(response.toJson());
    }

    final events = (response.items ?? [])
        .where((e) => e.start?.dateTime != null)
        .map(fromApiEvent)
        .toList();

    // Also fetch timed tasks from the Calendar Tasks feed.
    try {
      final taskResponse = await _api.events.list(
        '@tasks',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        orderBy: 'startTime',
      );
      final tasks = (taskResponse.items ?? [])
          .where((e) => e.start?.dateTime != null)
          .map((e) => fromApiEvent(e, isTask: true))
          .toList();
      events.addAll(tasks);
    } catch (_) {
      // Tasks calendar may be unavailable — silently skip.
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
  /// Only call this on events that have a `start.dateTime` (not all-day).
  static CalendarEvent fromApiEvent(gcal.Event e, {bool isTask = false}) {
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

    return CalendarEvent(
      id: e.id ?? '',
      title: (e.summary?.isNotEmpty ?? false) ? e.summary! : '(No title)',
      startTime: e.start!.dateTime!.toLocal(),
      endTime: e.end!.dateTime!.toLocal(),
      color: _kEventColors[e.colorId] ?? Colors.blue, // S4-18
      calendarEventUrl: e.htmlLink,
      videoCallUrl: VideoLinkExtractor.extract(
        hangoutLink: e.hangoutLink,
        conferenceEntryPoints: entryPoints,
        location: e.location,
        description: e.description,
      ),
      isTask: isTask,
    );
  }
}
