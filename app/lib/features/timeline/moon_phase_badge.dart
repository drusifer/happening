import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';

/// Always-visible badge showing the current moon phase and illumination %.
///
/// Positioned left of the settings gear (8px gap). Tapping opens the location
/// section in the settings panel (caller handles via [onTap]).
class MoonPhaseBadge extends StatelessWidget {
  const MoonPhaseBadge({
    super.key,
    required this.astroData,
    required this.onTap,
    this.fontSize = 11.0,
  });

  final AstroData astroData;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phaseName = _phaseName(astroData.phase);
    final illumPct = (astroData.illuminationFraction * 100).round();
    final icon = _phaseIcon(astroData.phase);

    return Tooltip(
      message: '$phaseName · $illumPct% illuminated',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(fontSize: fontSize * 1.1),
              ),
              const SizedBox(width: 2),
              Text(
                '$illumPct%',
                style: TextStyle(
                  fontSize: fontSize * 0.85,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _phaseIcon(MoonPhase phase) => switch (phase) {
        MoonPhase.newMoon => '🌑',
        MoonPhase.waxingCrescent => '🌒',
        MoonPhase.firstQuarter => '🌓',
        MoonPhase.waxingGibbous => '🌔',
        MoonPhase.full => '🌕',
        MoonPhase.waningGibbous => '🌖',
        MoonPhase.lastQuarter => '🌗',
        MoonPhase.waningCrescent => '🌘',
      };

  static String _phaseName(MoonPhase phase) => switch (phase) {
        MoonPhase.newMoon => 'New Moon',
        MoonPhase.waxingCrescent => 'Waxing Crescent',
        MoonPhase.firstQuarter => 'First Quarter',
        MoonPhase.waxingGibbous => 'Waxing Gibbous',
        MoonPhase.full => 'Full Moon',
        MoonPhase.waningGibbous => 'Waning Gibbous',
        MoonPhase.lastQuarter => 'Last Quarter',
        MoonPhase.waningCrescent => 'Waning Crescent',
      };
}
