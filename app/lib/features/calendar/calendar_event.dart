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

/// Immutable representation of a single Google Calendar event or task.
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
    this.isTask = false,
    this.calendarId = 'primary',
    this.calendarName = 'Primary',
    this.description,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? calendarEventUrl;
  final String? videoCallUrl;
  /// True when this item comes from the Google Calendar Tasks feed.
  final bool isTask;
  /// The source calendar this event belongs to.
  final String calendarId;
  /// The display name of the source calendar.
  final String calendarName;
  /// Full HTML description (will be stripped during display).
  final String? description;
  /// True for completed tasks.
  final bool isCompleted;

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
    bool? isTask,
    String? calendarId,
    String? calendarName,
    String? description,
    bool? isCompleted,
  }) =>
      CalendarEvent(
        id: id ?? this.id,
        title: title ?? this.title,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        color: color ?? this.color,
        calendarEventUrl: calendarEventUrl ?? this.calendarEventUrl,
        videoCallUrl: videoCallUrl ?? this.videoCallUrl,
        isTask: isTask ?? this.isTask,
        calendarId: calendarId ?? this.calendarId,
        calendarName: calendarName ?? this.calendarName,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CalendarEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, start: $startTime, isTask: $isTask)';
}

/// Identifies events that overlap in time (S5-D1).
/// Returns a set of event IDs that are in conflict.
Set<String> detectCollisions(List<CalendarEvent> events) {
  final collidingIds = <String>{};

  for (var i = 0; i < events.length; i++) {
    for (var j = i + 1; j < events.length; j++) {
      final a = events[i];
      final b = events[j];

      // Overlap condition: (StartA < EndB) AND (EndA > StartB)
      if (a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime)) {
        collidingIds.add(a.id);
        collidingIds.add(b.id);
      }
    }
  }

  return collidingIds;
}
