// Real-time clock tick stream.
//
// TLDR:
// Overview: Provides a 1Hz clock signal for real-time UI updates.
// Problem: Need to trigger periodic redraws of the timeline as time passes.
// Solution: Exposes a periodic Stream<DateTime> that ticks every second.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

/// Emits the current [DateTime] once per second.
class ClockService {
  Stream<DateTime> get tick => Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      );
}
