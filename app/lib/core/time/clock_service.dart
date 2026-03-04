// Real-time clock tick streams.
//
// TLDR:
// Overview: Provides periodic clock signals for UI updates.
// Problem: 1Hz updates for the entire timeline are CPU intensive.
// Solution: Exposes separate 1s and 10s streams to allow tiered UI updates.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

/// Emits the current [DateTime] at various intervals.
class ClockService {
  DateTime get now => DateTime.now();

  /// Precise 1Hz tick for countdowns and timers.
  Stream<DateTime> get tick1s => Stream.periodic(
        const Duration(seconds: 1),
        (_) => now,
      );

  /// Coarse 10s tick for heavy layout and painting updates.
  Stream<DateTime> get tick10s => Stream.periodic(
        const Duration(seconds: 10),
        (_) => now,
      );
}
