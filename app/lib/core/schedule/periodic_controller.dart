/// Unified interface for all scheduled/timed streams.
///
/// Concrete implementations: CountdownController (1Hz),
/// PaintTickController (10s), CalendarRefreshController (5min).
abstract class PeriodicController<T> {
  Stream<T> get stream;
  void dispose();
}
