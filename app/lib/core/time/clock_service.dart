/// Emits the current [DateTime] once per second.
class ClockService {
  Stream<DateTime> get tick => Stream.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      );
}
