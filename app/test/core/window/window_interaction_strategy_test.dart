import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';

import 'window_service_test.mocks.dart';

void main() {
  late MockWindowManager mockWM;

  setUp(() {
    mockWM = MockWindowManager();
  });

  test('factory creates MacOs strategy for macOS', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.macOS,
      wm: mockWM,
    );

    expect(strategy.runtimeType.toString(), 'MacOsWindowInteractionStrategy');
    expect(strategy.availability.supportsReserved, isFalse);
  });

  test('factory creates Reserved strategy for Windows', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.windows,
      wm: mockWM,
    );

    expect(
        strategy.runtimeType.toString(), 'ReservedWindowInteractionStrategy');
    expect(strategy.availability.supportsReserved, isTrue);
  });

  test('factory creates Reserved strategy for Linux', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.linux,
      wm: mockWM,
    );

    expect(
        strategy.runtimeType.toString(), 'ReservedWindowInteractionStrategy');
    expect(strategy.availability.supportsReserved, isTrue);
  });

  test('initialize is a no-op for all strategies', () async {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      final strategy = WindowInteractionStrategy.createForPlatform(
        platform: platform,
        wm: mockWM,
      );
      // No exception thrown.
      await strategy.initialize(WindowMode.reserved);
    }
  });
}
