/// Time-until-next-event countdown text.
///
/// TLDR:
/// Overview: Formats the duration remaining until the next event starts.
/// Problem: Need a glanceable "T-minus" timer that changes color based on urgency.
/// Solution: Displays duration as "X h Y min" or "now", with orange/red warnings.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Shows time remaining until the next calendar event.
///
/// Displays as "38 min", "1 h 12 min", or "now" when ≤ 0.
class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(remaining),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _color(remaining),
        letterSpacing: 0.3,
      ),
    );
  }

  static String _format(Duration d) {
    if (d <= Duration.zero) return 'now';
    if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds}s';
  }

  static Color _color(Duration d) {
    if (d <= Duration.zero) return Colors.redAccent;
    if (d.inMinutes < 5) return Colors.orange;
    return Colors.white70;
  }
}
