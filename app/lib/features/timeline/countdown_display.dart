// Time-until-next-event countdown text.
//
// TLDR:
// Overview: Formats the duration remaining until the next event starts or current event ends.
// Problem: Need a glanceable "T-minus" timer that changes color based on urgency and mode.
// Solution: Displays duration with orange/red warnings or amber for active meetings.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Countdown mode for [CountdownDisplay].
enum CountdownMode {
  /// Counting down to the start of the next event.
  untilNext,

  /// Counting down to the end of the current active event.
  untilEnd,
}

/// Shows time remaining until the next calendar event or end of current event.
///
/// Displays as "38 min", "1 h 12 min", or "now" when ≤ 0.
class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({
    super.key,
    required this.remaining,
    this.mode = CountdownMode.untilNext,
  });

  final Duration remaining;
  final CountdownMode mode;

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(remaining),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _color(remaining, mode),
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

  static Color _color(Duration d, CountdownMode mode) {
    if (mode == CountdownMode.untilEnd) return const Color(0xFFFFC107); // Amber
    if (d <= Duration.zero) return Colors.redAccent;
    if (d.inMinutes < 5) return Colors.orange;
    return Colors.white70;
  }
}
