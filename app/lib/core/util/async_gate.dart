import 'dart:async';

/// Ensures only one async [action] runs at a time.
///
/// If [request] is called while an action is running, the LAST requested
/// value is remembered and re-fired automatically when the current action
/// completes. Intermediate values are dropped.
///
/// Dedup: if the new value is equal to what is already in-flight OR already
/// pending, the request is silently discarded — preventing redundant re-runs
/// of the same action after spurious event bursts (e.g. GTK pointer events).
/// Requires [T] to support `==`.
class AsyncGate<T> {
  bool _running = false;
  T? _inflight;
  T? _pending;
  bool _hasPending = false;

  Future<void> request(T value, Future<void> Function(T) action) async {
    if (_running) {
      if (value == _inflight) {
        // Final intent matches in-flight — cancel any queued reversal.
        _pending = null;
        _hasPending = false;
        return;
      }
      if (_hasPending && value == _pending) return; // already queued, drop
      _pending = value;
      _hasPending = true;
      return;
    }
    _running = true;
    _inflight = value;
    try {
      await action(value);
    } finally {
      _running = false;
      _inflight = null;
      if (_hasPending) {
        final p = _pending as T;
        _pending = null;
        _hasPending = false;
        unawaited(request(p, action));
      }
    }
  }
}
