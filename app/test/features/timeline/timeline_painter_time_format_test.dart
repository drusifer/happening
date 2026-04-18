import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/timeline/timeline_painter.dart';

void main() {
  TimelinePainter painter({required bool alwaysUse24HourFormat}) {
    final now = DateTime(2026, 4, 17, 10);
    return TimelinePainter(
      events: const [],
      now: now,
      nowIndicatorX: 80,
      windowStart: DateTime(2026, 4, 17, 9),
      windowEnd: DateTime(2026, 4, 17, 11),
      backgroundColor: Colors.black,
      pastOverlayColor: Colors.black26,
      nowLineColor: Colors.red,
      tickColor: Colors.white,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
  }

  List<String?> semanticLabels(TimelinePainter painter) {
    return painter
        .semanticsBuilder(const Size(300, 60))
        .map((node) => node.properties.label)
        .toList();
  }

  test('timeline tick semantics use compact 12-hour labels by default', () {
    final labels = semanticLabels(painter(alwaysUse24HourFormat: false));

    expect(labels, contains('tick-10am'));
    expect(labels, contains('subtick-30'));
  });

  test('timeline tick semantics use compact 24-hour labels when requested', () {
    final labels = semanticLabels(painter(alwaysUse24HourFormat: true));

    expect(labels, contains('tick-10'));
    expect(labels, contains('subtick-30'));
  });

  test('timeline 24-hour labels are zero-padded before 10:00', () {
    final now = DateTime(2026, 4, 17, 2);
    final painter = TimelinePainter(
      events: const [],
      now: now,
      nowIndicatorX: 80,
      windowStart: DateTime(2026, 4, 17, 1),
      windowEnd: DateTime(2026, 4, 17, 3),
      backgroundColor: Colors.black,
      pastOverlayColor: Colors.black26,
      nowLineColor: Colors.red,
      tickColor: Colors.white,
      alwaysUse24HourFormat: true,
    );

    expect(semanticLabels(painter), contains('tick-02'));
  });
}
