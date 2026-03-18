import 'dart:async';

import 'package:happening/core/schedule/periodic_controller.dart';
import 'package:happening/core/util/async_gate.dart';

/// 5-minute [PeriodicController] that triggers calendar data refreshes.
///
/// Uses [AsyncGate] to deduplicate rapid taps on the refresh button.
class CalendarRefreshController implements PeriodicController<void> {
  CalendarRefreshController({
    Duration interval = const Duration(minutes: 5),
  }) {
    _timer = Timer.periodic(interval, (_) => _controller.add(null));
  }

  final _controller = StreamController<void>.broadcast();
  final _gate = AsyncGate<void>();
  late final Timer _timer;

  @override
  Stream<void> get stream => _controller.stream;

  /// Request an immediate refresh, deduplicated by [AsyncGate].
  Future<void> requestRefresh(Future<void> Function() action) =>
      _gate.request(null, (_) => action());

  @override
  void dispose() {
    _timer.cancel();
    _controller.close();
  }
}
