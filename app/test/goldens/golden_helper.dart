import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/timeline_painter.dart';

/// Renders the TimelinePainter in a consistent environment for golden tests.
Future<void> pumpTimelinePainter(
  WidgetTester tester, {
  required List<CalendarEvent> events,
  required DateTime now,
  double width = 1200.0,
  double height = 30.0,
  String? hoveredEventId,
  Set<String> collidingIds = const {},
  Color countdownColor = Colors.white,
  double fontSize = 11.0,
}) async {
  // Fix the surface size for pixel-perfect comparison.
  await tester.binding.setSurfaceSize(Size(width, height));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: CustomPaint(
            size: Size(width, height),
            painter: TimelinePainter(
              events: events,
              now: now,
              nowIndicatorX: width * 0.10,
              windowStart: now.subtract(const Duration(hours: 1)),
              windowEnd: now.add(const Duration(hours: 8)),
              hoveredEventId: hoveredEventId,
              collidingIds: collidingIds,
              countdownColor: countdownColor,
              fontSize: fontSize,
              backgroundColor: const Color(0xFF1A1A2E),
              pastOverlayColor: Colors.black26,
              nowLineColor: Colors.redAccent,
              tickColor: Colors.white70,
            ),
          ),
        ),
      ),
    ),
  );

  // Wait for at least one frame to ensure painting happens.
  await tester.pump();
}
