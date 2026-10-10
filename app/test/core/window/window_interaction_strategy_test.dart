import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/linux_window_interaction_strategy.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';

import 'package:mockito/mockito.dart';

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

  test('factory creates Linux strategy for Linux', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.linux,
      wm: mockWM,
    );

    expect(strategy, isA<LinuxWindowInteractionStrategy>());
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

  group('LinuxWindowInteractionStrategy', () {
    late LinuxWindowInteractionStrategy strategy;

    setUp(() {
      strategy = LinuxWindowInteractionStrategy(wm: mockWM);
    });

    test('sendToBack drops always-on-top, then pins the dock to the bottom',
        () async {
      await strategy.sendToBack();

      verifyInOrder([
        mockWM.setAlwaysOnTop(false),
        mockWM.blur(),
        mockWM.setAlwaysOnBottom(true),
      ]);
    });

    test('restoreToFront clears always-on-bottom before always-on-top',
        () async {
      await strategy.sendToBack();
      clearInteractions(mockWM);

      await strategy.restoreToFront();

      verifyInOrder([
        mockWM.setAlwaysOnBottom(false),
        mockWM.setAlwaysOnTop(true),
      ]);
    });
  });

  test('non-Linux send-to-back never sets always-on-bottom', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.windows,
      wm: mockWM,
    );

    await strategy.sendToBack();
    await strategy.restoreToFront();

    verifyInOrder([
      mockWM.setAlwaysOnTop(false),
      mockWM.blur(),
      mockWM.setAlwaysOnTop(true),
    ]);
    verifyNever(mockWM.setAlwaysOnBottom(any));
  });
}
