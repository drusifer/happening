import 'package:happening/core/schedule/periodic_controller.dart';
import 'package:happening/core/time/clock_service.dart';

/// 10s [PeriodicController] for timeline repaint ticks.
///
/// Thin injectable wrapper around [ClockService.tick10s].
class PaintTickController implements PeriodicController<DateTime> {
  PaintTickController({required ClockService clock}) : _clock = clock;

  final ClockService _clock;

  @override
  Stream<DateTime> get stream => _clock.tick10s;

  @override
  void dispose() {}
}
