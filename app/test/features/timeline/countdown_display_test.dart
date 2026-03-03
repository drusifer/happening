import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/features/timeline/countdown_display.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: child),
      );

  group('CountdownDisplay', () {
    testWidgets('shows minutes when < 1 hour remaining', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(remaining: Duration(minutes: 38)),
      ));
      expect(find.text('38 min'), findsOneWidget);
    });

    testWidgets('shows hours and minutes when >= 1 hour', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(remaining: Duration(hours: 1, minutes: 12)),
      ));
      expect(find.text('1 h 12 min'), findsOneWidget);
    });

    testWidgets('shows "now" when duration is zero', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(remaining: Duration.zero),
      ));
      expect(find.text('now'), findsOneWidget);
    });

    testWidgets('shows "now" for negative duration', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(remaining: Duration(minutes: -5)),
      ));
      expect(find.text('now'), findsOneWidget);
    });

    testWidgets('shows seconds when < 1 minute', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(remaining: Duration(seconds: 45)),
      ));
      expect(find.text('45s'), findsOneWidget);
    });

    testWidgets('uses white color for untilNext mode (> 5 min)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(
          remaining: Duration(minutes: 10),
          mode: CountdownMode.untilNext,
        ),
      ));
      final theme = Theme.of(tester.element(find.byType(CountdownDisplay)));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(theme.textTheme.bodyMedium?.color));
    });

    testWidgets('uses orange color for untilNext mode (< 5 min)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(
          remaining: Duration(minutes: 3),
          mode: CountdownMode.untilNext,
        ),
      ));
      final theme = Theme.of(tester.element(find.byType(CountdownDisplay)));
      final isDark = theme.brightness == Brightness.dark;
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, isDark ? Colors.orange : Colors.orange[900]);
    });

    testWidgets('uses amber color for untilEnd mode', (tester) async {
      await tester.pumpWidget(wrap(
        const CountdownDisplay(
          remaining: Duration(minutes: 20),
          mode: CountdownMode.untilEnd,
        ),
      ));
      final theme = Theme.of(tester.element(find.byType(CountdownDisplay)));
      final isDark = theme.brightness == Brightness.dark;
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color,
          isDark ? const Color(0xFFFFC107) : Colors.orange[800]);
    });
  });
}
