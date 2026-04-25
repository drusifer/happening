import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:mockito/mockito.dart';
import 'package:window_manager/window_manager.dart';

import 'window_service_test.mocks.dart';

void main() {
  late MockWindowManager mockWM;

  setUp(() {
    mockWM = MockWindowManager();
    when(mockWM.setIgnoreMouseEvents(any, forward: anyNamed('forward')))
        .thenAnswer((_) => Future.value());
  });

  test('factory creates macOS interaction strategy', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.macOS,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    expect(strategy.runtimeType.toString(), 'MacOsWindowInteractionStrategy');
    expect(strategy.availability.supportsTransparent, isTrue);
    expect(strategy.availability.supportsReserved, isFalse);
  });

  test('factory creates Windows interaction strategy', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.windows,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    expect(strategy.runtimeType.toString(), 'WindowsWindowInteractionStrategy');
    expect(strategy.availability.supportsTransparent, isTrue);
    expect(strategy.availability.supportsReserved, isTrue);
  });

  test('factory creates Linux interaction strategy', () {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.linux,
      wm: mockWM,
      supportsTransparentPassThrough: false,
    );

    expect(strategy.runtimeType.toString(), 'LinuxWindowInteractionStrategy');
    expect(strategy.availability.supportsTransparent, isFalse);
    expect(strategy.availability.supportsReserved, isTrue);
  });

  test('macOS transparent initialize enables pass-through', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.macOS,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    await strategy.initialize(WindowMode.transparent);

    verify(mockWM.setIgnoreMouseEvents(true, forward: true)).called(1);
  });

  test('macOS focus toggles pass-through off then on', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.macOS,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    await strategy.initialize(WindowMode.transparent);
    clearInteractions(mockWM);

    await strategy.setFocused(true);
    await strategy.setFocused(false);

    verify(mockWM.setIgnoreMouseEvents(false, forward: true)).called(1);
    verify(mockWM.setIgnoreMouseEvents(true, forward: true)).called(1);
  });

  test('windows transparent initialize enables pass-through', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.windows,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    await strategy.initialize(WindowMode.transparent);

    verify(mockWM.setIgnoreMouseEvents(true, forward: true)).called(1);
  });

  test('windows reserved initialize does not enable pass-through', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.windows,
      wm: mockWM,
      supportsTransparentPassThrough: true,
    );

    await strategy.initialize(WindowMode.reserved);

    verifyNever(mockWM.setIgnoreMouseEvents(any, forward: anyNamed('forward')));
  });

  test('linux initialize and focus changes are no-op', () async {
    final strategy = WindowInteractionStrategy.createForPlatform(
      platform: TargetPlatform.linux,
      wm: mockWM,
      supportsTransparentPassThrough: false,
    );

    await strategy.initialize(WindowMode.reserved);
    await strategy.setFocused(true);
    await strategy.setPassThrough(true);

    verifyNever(mockWM.setIgnoreMouseEvents(any, forward: anyNamed('forward')));
  });
}
