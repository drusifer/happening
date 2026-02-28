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

    return (response.items ?? [])
        .where((e) => e.start?.dateTime != null)
        .map(fromApiEvent)
        .toList();
  }

  /// Converts a Google Calendar API `Event` to a `CalendarEvent`.
  /// Only call this on events that have a `start.dateTime` (not all-day).
  static CalendarEvent fromApiEvent(gcal.Event e) {
    // Log raw API payload — copy from debug console to build test fixtures.
    debugPrint('[CalendarAPI] ${jsonEncode(e.toJson())}');

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
      color: Colors.blue, // calendar color parsing: Sprint 3 / F-09
      calendarEventUrl: e.htmlLink,
      videoCallUrl: VideoLinkExtractor.extract(
        hangoutLink: e.hangoutLink,
        conferenceEntryPoints: entryPoints,
        location: e.location,
        description: e.description,
      ),
    );
  }
}
