/// Pure math for positioning events on the timeline strip.
///
/// All inputs in logical pixels and [DateTime]. No Flutter dependency.
class TimelineLayout {
  TimelineLayout({
    required this.stripWidth,
    required this.nowIndicatorX,
    required this.windowStart,
    required this.windowEnd,
  }) : pixelsPerSecond =
            stripWidth / windowEnd.difference(windowStart).inSeconds.toDouble();

  final double stripWidth;
  final double nowIndicatorX;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// Pixels per second across the full strip width.
  final double pixelsPerSecond;

  /// Returns the x position (logical pixels) for a given [time],
  /// relative to [now] (defaults to [DateTime.now] if omitted).
  double xForTime(DateTime time, [DateTime? now]) {
    final reference = now ?? DateTime.now();
    final secondsFromNow = time.difference(reference).inSeconds.toDouble();
    return nowIndicatorX + secondsFromNow * pixelsPerSecond;
  }

  /// Duration remaining until [eventTime], clamped to zero if already past.
  Duration countdownTo(DateTime eventTime, DateTime now) {
    final remaining = eventTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Whether [time] falls within the visible window.
  bool isVisible(DateTime time) =>
      !time.isBefore(windowStart) && !time.isAfter(windowEnd);
}
