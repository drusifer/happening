// Immutable calendar event model.
//
// TLDR:
// Overview: Represents a single event from Google Calendar.
// Problem: Need a type-safe, internal representation of events for the UI and logic.
// Solution: Defines the CalendarEvent class with start/end times, URLs, and state helpers.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Immutable representation of a single Google Calendar event.
@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.calendarEventUrl,
    required this.videoCallUrl,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? calendarEventUrl;
  final String? videoCallUrl;

  Duration get duration => endTime.difference(startTime);

  bool isNow(DateTime at) => at.isAfter(startTime) && at.isBefore(endTime);

  bool isPast(DateTime at) => at.isAfter(endTime);

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    String? calendarEventUrl,
    String? videoCallUrl,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        color: color ?? this.color,
        calendarEventUrl: calendarEventUrl ?? this.calendarEventUrl,
        videoCallUrl: videoCallUrl ?? this.videoCallUrl,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CalendarEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, start: $startTime)';
}
