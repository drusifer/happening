import 'package:flutter/material.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/timeline_strip.dart';

/// Root application widget.
///
/// [HappeningApp] is the single [StatefulWidget] that owns:
///   - Auth state (unauthenticated / authenticated)
///   - Event list (refreshed every 5 minutes)
///   - Polling timer
///
/// All children are stateless; the [ClockService] stream drives redraws.
class HappeningApp extends StatefulWidget {
  const HappeningApp({super.key});

  @override
  State<HappeningApp> createState() => _HappeningAppState();
}

class _HappeningAppState extends State<HappeningApp> {
  final _clock = ClockService();
  List<CalendarEvent> _events = _mockEvents(); // replaced with real data in S2

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: TimelineStrip(
          events: _events,
          clockService: _clock,
        ),
      ),
    );
  }
}

// ── Mock data for Sprint 1 ────────────────────────────────────────────────────
List<CalendarEvent> _mockEvents() {
  final now = DateTime.now();
  return [
    CalendarEvent(
      id: 'mock-1',
      title: 'Team Standup',
      startTime: now.add(const Duration(minutes: 38)),
      endTime: now.add(const Duration(minutes: 68)),
      color: Colors.blue,
      calendarEventUrl: null,
      videoCallUrl: 'https://meet.google.com/abc-def-ghi',
    ),
    CalendarEvent(
      id: 'mock-2',
      title: 'Lunch',
      startTime: now.add(const Duration(hours: 2)),
      endTime: now.add(const Duration(hours: 3)),
      color: Colors.green,
      calendarEventUrl: null,
      videoCallUrl: null,
    ),
    CalendarEvent(
      id: 'mock-3',
      title: '1:1 with Manager',
      startTime: now.add(const Duration(hours: 4, minutes: 30)),
      endTime: now.add(const Duration(hours: 5)),
      color: Colors.purple,
      calendarEventUrl: null,
      videoCallUrl: 'https://zoom.us/j/123456789',
    ),
    CalendarEvent(
      id: 'mock-4',
      title: 'Sprint Review',
      startTime: now.add(const Duration(hours: 6)),
      endTime: now.add(const Duration(hours: 7)),
      color: Colors.orange,
      calendarEventUrl: null,
      videoCallUrl: null,
    ),
  ];
}
