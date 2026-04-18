// Real-time clock tick streams.
//
// TLDR:
// Overview: Provides periodic clock signals for UI updates.
// Problem: 1Hz updates for the entire timeline are CPU intensive.
// Solution: Exposes separate 1s and 10s streams to allow tiered UI updates.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';

/// Emits the current [DateTime] at various intervals.
class ClockService {
  ClockService()
      : _tick1s = Stream<DateTime>.periodic(
          const Duration(seconds: 1),
          (_) => DateTime.now(),
        ).asBroadcastStream(),
        _tick10s = Stream<DateTime>.periodic(
          const Duration(seconds: 10),
          (_) => DateTime.now(),
        ).asBroadcastStream();

  final Stream<DateTime> _tick1s;
  final Stream<DateTime> _tick10s;

  DateTime get now => DateTime.now();

  /// Precise 1Hz tick for countdowns and timers.
  Stream<DateTime> get tick1s => _tick1s;

  /// Coarse 10s tick for heavy layout and painting updates.
  Stream<DateTime> get tick10s => _tick10s;
}
