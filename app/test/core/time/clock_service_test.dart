import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/time/clock_service.dart';

void main() {
  group('ClockService', () {
    test('tick1s stream emits DateTime values', () async {
      final service = ClockService();
      final tick1s = await service.tick1s.first;
      expect(tick1s, isA<DateTime>());
    });

    test('tick streams keep stable identity across rebuild reads', () {
      final service = ClockService();

      expect(identical(service.tick1s, service.tick1s), isTrue);
      expect(identical(service.tick10s, service.tick10s), isTrue);
    });

    test('consecutive tick1ss are ~1 second apart', () async {
      final service = ClockService();
      final tick1ss = await service.tick1s.take(2).toList();
      final diff = tick1ss[1].difference(tick1ss[0]);
      expect(diff.inMilliseconds, closeTo(1000, 200));
    });

    test('tick1s values are close to DateTime.now()', () async {
      final service = ClockService();
      final before = DateTime.now();
      final tick1s = await service.tick1s.first;
      final after = DateTime.now();
      expect(
          tick1s.isAfter(before.subtract(const Duration(seconds: 2))), isTrue);
      expect(tick1s.isBefore(after.add(const Duration(seconds: 2))), isTrue);
    });
  });
}
