import 'dart:async';

import 'package:happening/core/window/physical_window_state.dart';
import 'package:happening/core/window/resize_executor.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:logging/logging.dart';

/// Serialises expand/collapse intents and emits confirmed [PhysicalWindowState].
///
/// TLDR:
/// Overview: Single authority for expand/collapse decisions. Owns a background
///           loop started via start() and a one-slot last-write queue.
/// Problem: Expand/collapse logic scattered across 6+ call sites caused timing races:
///          card rendered before GTK confirmed resize, invisible card after resume.
/// Solution: Background loop woken by Completer signal; one-slot _queued slot
///           deduped at send() time against _displayed and current queue entry;
///           PhysicalWindowState emitted after resize() returns — each platform-
///           channel call in resize() is a blocking round-trip, so the window IS
///           at the target size when resize() completes.
/// Breaking Changes: call start() after construction.

class ExpansionController {
  ExpansionController({required ResizeExecutor executor})
      : _executor = executor;

  static final _log = Logger('EC');

  final ResizeExecutor _executor;
  final _stateController = StreamController<PhysicalWindowState>.broadcast();

  /// Confirmed physical window state stream.
  ///
  /// Use `initialData: PhysicalWindowState.collapsed` on StreamBuilder — the
  /// stream emits nothing until the first resize completes.
  Stream<PhysicalWindowState> get stateStream => _stateController.stream;

  ExpansionState? _queued;    // next intent waiting to execute
  ExpansionState? _displayed; // last confirmed state

  bool _disposed = false;
  Completer<void> _signal = Completer();

  /// Starts the background loop. Must be called once after construction.
  void start() {
    unawaited(_loop());
  }

  /// Queues an expansion intent.
  ///
  /// Dropped if [intent] matches the current displayed state or is already
  /// queued. Otherwise wakes the background loop.
  void send(ExpansionState intent) {
    if (intent == _displayed || intent == _queued) return;
    _log.fine('send intent=${intent.name}');
    _queued = intent;
    if (!_signal.isCompleted) _signal.complete();
  }

  Future<void> _loop() async {
    while (!_disposed) {
      await _signal.future;
      _signal = Completer();
      while (_queued != null && !_disposed) {
        await _execute();
      }
    }
    _log.fine('loop exited');
  }

  Future<void> _execute() async {
    final intent = _queued!;
    _queued = null;
    _displayed = intent; // update eagerly so sends during the await dedup correctly

    final targetHeight = intent == ExpansionState.expanded
        ? _executor.expandedHeight
        : _executor.collapsedHeight;

    _log.fine('execute START intent=${intent.name} target=$targetHeight');
    await _executor.resize(intent);
    _log.fine('execute DONE intent=${intent.name} target=$targetHeight');

    if (!_stateController.isClosed) {
      _stateController.add(PhysicalWindowState(
        height: targetHeight,
        isExpanded: intent == ExpansionState.expanded,
      ));
    }
  }

  void dispose() {
    _disposed = true;
    if (!_signal.isCompleted) _signal.complete();
    _stateController.close();
  }
}
