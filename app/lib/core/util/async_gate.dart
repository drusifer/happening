import 'dart:async';

/// Ensures only one async [action] runs at a time.
///
/// If [request] is called while an action is running, the LAST requested
/// value is remembered and re-fired automatically when the current action
/// completes. Intermediate values are dropped.
class AsyncGate<T> {
  bool _running = false;
  T? _pending;
  bool _hasPending = false;

  Future<void> request(T value, Future<void> Function(T) action) async {
    if (_running) {
      _pending = value;
      _hasPending = true;
      return;
    }
    _running = true;
    try {
      await action(value);
    } finally {
      _running = false;
      if (_hasPending) {
        final p = _pending as T;
        _pending = null;
        _hasPending = false;
        unawaited(request(p, action));
      }
    }
  }
}
