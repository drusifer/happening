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
    this.isFree = false,
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

  /// True when the event is marked as "Free" (transparency = transparent).
  final bool isFree;

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
    bool? isFree,
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
        isFree: isFree ?? this.isFree,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CalendarEvent && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, start: $startTime, isTask: $isTask)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'color': color.toARGB32(),
        'calendarEventUrl': calendarEventUrl,
        'videoCallUrl': videoCallUrl,
        'isTask': isTask,
        'calendarId': calendarId,
        'calendarName': calendarName,
        'description': description,
        'isCompleted': isCompleted,
        'isFree': isFree,
      };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        color: Color(json['color'] as int),
        calendarEventUrl: json['calendarEventUrl'] as String?,
        videoCallUrl: json['videoCallUrl'] as String?,
        isTask: json['isTask'] as bool? ?? false,
        calendarId: json['calendarId'] as String? ?? 'primary',
        calendarName: json['calendarName'] as String? ?? 'Primary',
        description: json['description'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        isFree: json['isFree'] as bool? ?? false,
      );
}

/// Identifies events that overlap in time (S5-D1).
/// Returns a set of event IDs that are in conflict.
Set<String> detectCollisions(List<CalendarEvent> events) {
  final collidingIds = <String>{};

  for (var i = 0; i < events.length; i++) {
    for (var j = i + 1; j < events.length; j++) {
      final a = events[i];
      final b = events[j];

      // Overlap condition:
      // Traditional duration overlap: (StartA < EndB) AND (EndA > StartB)
      // PLUS Point-in-duration:
      final aIsPoint = a.startTime == a.endTime;
      final bIsPoint = b.startTime == b.endTime;

      bool overlap = false;
      if (aIsPoint && bIsPoint) {
        overlap = a.startTime == b.startTime;
      } else if (aIsPoint) {
        // Point A inside duration B
        overlap = a.startTime.isAtSameMomentAs(b.startTime) ||
            (a.startTime.isAfter(b.startTime) &&
                a.startTime.isBefore(b.endTime)) ||
            a.startTime.isAtSameMomentAs(b.endTime);
      } else if (bIsPoint) {
        // Point B inside duration A
        overlap = b.startTime.isAtSameMomentAs(a.startTime) ||
            (b.startTime.isAfter(a.startTime) &&
                b.startTime.isBefore(a.endTime)) ||
            b.startTime.isAtSameMomentAs(a.endTime);
      } else {
        // Both have duration
        overlap =
            a.startTime.isBefore(b.endTime) && a.endTime.isAfter(b.startTime);
      }

      if (overlap) {
        collidingIds.add(a.id);
        collidingIds.add(b.id);
      }
    }
  }

  return collidingIds;
}
