import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/moon_phase_badge.dart';

AstroData _makeAstro(MoonPhase phase, double fraction) {
  final t = DateTime(2026, 5, 18, 6, 0);
  return AstroData(
    civilTwilightBegin: t,
    sunrise: t.add(const Duration(minutes: 30)),
    solarNoon: t.add(const Duration(hours: 6)),
    sunset: t.add(const Duration(hours: 14)),
    civilTwilightEnd: t.add(const Duration(hours: 14, minutes: 30)),
    phase: phase,
    illuminationFraction: fraction,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MoonPhaseBadge', () {
    testWidgets('shows illumination percentage', (tester) async {
      await tester.pumpWidget(_wrap(MoonPhaseBadge(
        astroData: _makeAstro(MoonPhase.full, 0.99),
        onTap: () {},
      )));

      expect(find.text('99%'), findsOneWidget);
    });

    testWidgets('shows 0% for new moon', (tester) async {
      await tester.pumpWidget(_wrap(MoonPhaseBadge(
        astroData: _makeAstro(MoonPhase.newMoon, 0.0),
        onTap: () {},
      )));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(MoonPhaseBadge(
        astroData: _makeAstro(MoonPhase.firstQuarter, 0.5),
        onTap: () => tapped = true,
      )));

      await tester.tap(find.byType(MoonPhaseBadge));
      expect(tapped, isTrue);
    });

    testWidgets('has tooltip with phase name and illumination', (tester) async {
      await tester.pumpWidget(_wrap(MoonPhaseBadge(
        astroData: _makeAstro(MoonPhase.waxingGibbous, 0.72),
        onTap: () {},
      )));

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('Waxing Gibbous'));
      expect(tooltip.message, contains('72%'));
    });

    testWidgets('renders all 8 moon phases without error', (tester) async {
      for (final phase in MoonPhase.values) {
        await tester.pumpWidget(_wrap(MoonPhaseBadge(
          astroData: _makeAstro(phase, 0.5),
          onTap: () {},
        )));
        expect(find.byType(MoonPhaseBadge), findsOneWidget);
      }
    });
  });
}
