import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/time/clock_service.dart';

void main() {
  group('ClockService', () {
    test('tick stream emits DateTime values', () async {
      final service = ClockService();
      final tick = await service.tick.first;
      expect(tick, isA<DateTime>());
    });

    test('consecutive ticks are ~1 second apart', () async {
      final service = ClockService();
      final ticks = await service.tick.take(2).toList();
      final diff = ticks[1].difference(ticks[0]);
      expect(diff.inMilliseconds, closeTo(1000, 200));
    });

    test('tick values are close to DateTime.now()', () async {
      final service = ClockService();
      final before = DateTime.now();
      final tick = await service.tick.first;
      final after = DateTime.now();
      expect(tick.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
      expect(tick.isBefore(after.add(const Duration(seconds: 2))), isTrue);
    });
  });
}
