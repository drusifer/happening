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
    this.color,
    this.fontSize = 13.0,
    this.backgroundColor,
  });

  final Duration remaining;
  final CountdownMode mode;
  final Color? color;
  final double fontSize;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgBase = backgroundColor ?? theme.scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgBase.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        _format(remaining),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color ?? _color(remaining, mode, theme),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static String _format(Duration d) {
    if (d <= Duration.zero) return 'now';
    if (d.inHours > 0) return '${d.inHours} h ${d.inMinutes.remainder(60)} min';
    if (d.inMinutes > 0) return '${d.inMinutes} min';
    return '${d.inSeconds}s';
  }

  static Color _color(Duration d, CountdownMode mode, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (mode == CountdownMode.untilEnd) {
      return isDark ? const Color(0xFFFFC107) : Colors.orange[800]!;
    }
    if (d <= Duration.zero) return Colors.redAccent;
    if (d.inMinutes < 5) return isDark ? Colors.orange : Colors.orange[900]!;
    return theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white70 : Colors.black87);
  }
}
