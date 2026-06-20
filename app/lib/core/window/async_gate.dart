import 'dart:async';

import 'package:logging/logging.dart';

/// Serialises async requests into a single background loop with last-wins
/// coalescing, so concurrent/racing requests always settle on the most
/// recently requested value.
///
/// TLDR:
/// Overview: One-slot, last-wins queue feeding a single background loop.
/// Problem: Geometry was mutated from many call sites; overlapping async
///          requests raced and the window settled on a stale state (BUG-A,
///          Sprint 6). Each requester also needs to await its own completion.
/// Solution: A generic gate (extracted from ExpansionController's inline loop):
///           [send] coalesces into one pending slot and wakes the loop; the
///           loop runs the handler one request at a time, newest pending wins.
/// Breaking Changes: call [start] once after construction.
///
/// Idempotency contract: the handler is expected to be idempotent, since the
/// gate may re-run the same value (e.g. a forced re-apply after a display
/// change that keeps the logical state but changes geometry).
class AsyncGate<T> {
  AsyncGate(this._handler);

  static final _log = Logger('AsyncGate');

  final Future<void> Function(T value) _handler;

  _PendingRequest<T>? _queued; // next value waiting to run
  T? _settled; // last value handed to the loop (set eagerly so in-flight
  // sends dedup correctly)
  bool _hasSettled = false;

  bool _started = false;
  bool _disposed = false;
  Completer<void> _signal = Completer();

  /// Starts the background loop. Must be called once after construction.
  void start() {
    if (_started) return;
    _started = true;
    unawaited(_loop());
  }

  /// Queues [value] and returns a future that completes when its handler run
  /// finishes (or completes immediately if deduped away).
  ///
  /// Dropped when [value] already matches the settled value and nothing is
  /// queued — unless [force] is set, which guarantees at least one handler run
  /// after the current one (used for geometry re-apply where the logical value
  /// is unchanged but the result must be recomputed).
  Future<void> send(T value, {bool force = false}) {
    if (_disposed) return Future.value();
    if (!force && _queued == null && _hasSettled && value == _settled) {
      return Future.value();
    }
    if (_queued != null && _queued!.value == value) {
      return _queued!.completer.future;
    }
    _log.fine('send value=$value force=$force');
    // A different value supersedes a still-pending one (last-wins). Don't leave
    // the superseded caller's future dangling — complete it; its request was
    // overtaken before it ran.
    final superseded = _queued;
    final completer = Completer<void>();
    _queued = _PendingRequest<T>(value, completer);
    if (superseded != null && !superseded.completer.isCompleted) {
      superseded.completer.complete();
    }
    if (!_signal.isCompleted) _signal.complete();
    return completer.future;
  }

  Future<void> _loop() async {
    while (!_disposed) {
      await _signal.future;
      _signal = Completer();
      while (_queued != null && !_disposed) {
        await _run();
      }
    }
    _log.fine('loop exited');
  }

  Future<void> _run() async {
    final request = _queued!;
    _queued = null;
    final value = request.value;
    _settled = value; // eager: sends during the await dedup against this
    _hasSettled = true;

    try {
      await _handler(value);
      if (!request.completer.isCompleted) request.completer.complete();
    } catch (e, st) {
      _log.severe('handler failed value=$value', e, st);
      if (!request.completer.isCompleted) {
        request.completer.completeError(e, st);
      }
    }
  }

  void dispose() {
    _disposed = true;
    if (!_signal.isCompleted) _signal.complete();
  }
}

class _PendingRequest<T> {
  _PendingRequest(this.value, this.completer);

  final T value;
  final Completer<void> completer;
}
