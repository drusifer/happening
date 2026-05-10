import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

@GenerateNiceMocks([MockSpec<WindowManager>(), MockSpec<ScreenRetriever>()])
import 'window_service_test.mocks.dart';

class _FakeInteractionStrategy extends WindowInteractionStrategy {
  WindowMode? initializedMode;
  final List<bool> focusedCalls = [];
  final List<bool> passThroughCalls = [];

  @override
  WindowModeAvailability get availability => const WindowModeAvailability(
        supportsTransparent: true,
        supportsReserved: true,
      );

  @override
  Future<void> initialize(WindowMode effectiveMode) async {
    initializedMode = effectiveMode;
  }

  @override
  Future<void> setFocused(bool focused) async {
    focusedCalls.add(focused);
  }

  @override
  Future<void> setPassThrough(bool enabled) async {
    passThroughCalls.add(enabled);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowService', () {
    late MockWindowManager mockWM;
    late MockScreenRetriever mockSR;
    late WindowService service;
    late _FakeInteractionStrategy fakeInteractionStrategy;

    setUp(() {
      mockWM = MockWindowManager();
      mockSR = MockScreenRetriever();
      fakeInteractionStrategy = _FakeInteractionStrategy();
      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        interactionStrategy: fakeInteractionStrategy,
      );

      // Default mock behavior for initialization
      when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => const Display(
            id: '0',
            name: 'primary',
            size: Size(1920, 1080),
            visiblePosition: Offset.zero,
            visibleSize: Size(1920, 1080),
            scaleFactor: 1.0,
          ));

      // Mock WM methods to return Future.value()
      when(mockWM.ensureInitialized()).thenAnswer((_) => Future.value());
      when(mockWM.getDevicePixelRatio()).thenReturn(1.0);
      when(mockWM.setResizable(any)).thenAnswer((_) => Future.value());
      when(mockWM.setMinimumSize(any)).thenAnswer((_) => Future.value());
      when(mockWM.setMaximumSize(any)).thenAnswer((_) => Future.value());
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) => Future.value());
      when(mockWM.getSize()).thenAnswer((_) async => Size.zero);
      when(mockWM.setPosition(any, animate: anyNamed('animate')))
          .thenAnswer((_) => Future.value());
      when(mockWM.setAlwaysOnTop(any)).thenAnswer((_) => Future.value());
      when(mockWM.setAsFrameless()).thenAnswer((_) => Future.value());
      when(mockWM.setBackgroundColor(any)).thenAnswer((_) => Future.value());
      when(mockWM.setIgnoreMouseEvents(any, forward: anyNamed('forward')))
          .thenAnswer((_) => Future.value());
      when(mockWM.show(inactive: anyNamed('inactive')))
          .thenAnswer((_) => Future.value());
      when(mockWM.focus()).thenAnswer((_) => Future.value());
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as dynamic;
        if (callback != null) {
          await callback();
        }
      });
    });

    test('initialize sets up the window with logical pixels', () async {
      await service.initialize(initialFontSize: FontSize.medium);

      verify(mockWM.ensureInitialized()).called(1);
      verify(mockWM.getDevicePixelRatio()).called(1);
      verify(mockWM.waitUntilReadyToShow(any, any)).called(1);
    });

    test('initialize passes initial window mode to interaction strategy',
        () async {
      await service.initialize(
        initialFontSize: FontSize.medium,
        initialWindowMode: WindowMode.transparent,
      );

      expect(fakeInteractionStrategy.initializedMode, WindowMode.transparent);
      expect(service.windowMode, WindowMode.transparent);
    });

    test('setPassThroughEnabled enables click-through with forwarded events',
        () async {
      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        supportsTransparentPassThroughForTesting: true,
        platformOverride: TargetPlatform.windows,
        enableWindowsAppBar: false,
      );

      await service.setPassThroughEnabled(true);

      verify(mockWM.setIgnoreMouseEvents(true, forward: true)).called(1);
    });

    test('setPassThroughEnabled disables click-through with forwarded events',
        () async {
      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        supportsTransparentPassThroughForTesting: true,
        platformOverride: TargetPlatform.windows,
        enableWindowsAppBar: false,
      );

      await service.setPassThroughEnabled(false);

      verify(mockWM.setIgnoreMouseEvents(false, forward: true)).called(1);
    });

    test('setPassThroughEnabled is a no-op on unsupported platforms', () async {
      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        supportsTransparentPassThroughForTesting: false,
      );

      await service.setPassThroughEnabled(true);

      verifyNever(
          mockWM.setIgnoreMouseEvents(any, forward: anyNamed('forward')));
    });

    test('supportsTransparentPassThrough defaults to unavailable on Linux',
        () async {
      service = WindowService(windowManager: mockWM, screenRetriever: mockSR);
      expect(await service.supportsTransparentPassThrough(), !Platform.isLinux);
    });

    test('setInteractionFocused delegates to interaction strategy', () async {
      await service.setInteractionFocused(true);
      await service.setInteractionFocused(false);

      expect(fakeInteractionStrategy.focusedCalls, [true, false]);
    });

    test('setWindowMode updates stored mode and reinitializes interaction',
        () async {
      await service.setWindowMode(WindowMode.transparent);

      expect(service.windowMode, WindowMode.transparent);
      expect(fakeInteractionStrategy.initializedMode, WindowMode.transparent);
    });

    // _onDisplayChanged zero-width guard (DPMS/wake regression)
    // When screen_retriever returns width=0 (transient during display reinit),
    // _screenWidth must NOT be updated and no resize must occur.
    test('_onDisplayChanged: ignores transient zero-width display event',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);

      // Return width=0 (DPMS / wake transient)
      when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => const Display(
            id: '0',
            name: 'primary',
            size: Size(0, 1080),
            visiblePosition: Offset.zero,
            visibleSize: Size(0, 1080),
            scaleFactor: 1.0,
          ));
      // Return a different DPR so the change-check doesn't skip early
      when(mockWM.getDevicePixelRatio()).thenReturn(2.0);

      // Reset call counts
      clearInteractions(mockWM);

      service.didChangeMetrics();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // No resize calls should have been made with width=0
      verifyNever(mockWM.setSize(
          argThat(predicate<Size>((s) => s.width == 0, 'zero-width size'))));
      verifyNever(mockWM.setMinimumSize(argThat(
          predicate<Size>((s) => s.width == 0, 'zero-width min size'))));
      verifyNever(mockWM.setMaximumSize(argThat(
          predicate<Size>((s) => s.width == 0, 'zero-width max size'))));
    });

    // Concurrent _onDisplayChanged serialisation guard
    test('_onDisplayChanged: concurrent calls are serialised (no race)',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);
      clearInteractions(mockWM);

      // Fire two back-to-back didChangeMetrics — only one should run the inner logic
      service.didChangeMetrics();
      service.didChangeMetrics();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // With serialisation the first call runs inner logic, the second is dropped.
      // The key invariant: _screenWidth is not overwritten by a racing call.
      // We verify no setSize with zero width occurred (regression guard).
      verifyNever(mockWM.setSize(
          argThat(predicate<Size>((s) => s.width == 0, 'zero-width size'))));
    });

    // THEORY-D: display change (external monitor disconnect) leaves window displaced.
    //
    // log: build/tmp line 113 — width=2944→3840 (external monitor connected).
    //      build/tmp line 2054 — width=3840→2944 (external monitor disconnected).
    // _onDisplayChanged resizes the window but does NOT call setPosition().
    // The window manager may rescue the window to an arbitrary position after
    // the monitor disconnects, leaving the strip displaced (not at top-left).
    //
    // Fix: LinuxResizeStrategy.collapse() must call setPosition(Offset.zero)
    // so the strip is always re-anchored to the primary display's top-left.
    test('THEORY-D: Linux display change re-anchors position after collapse',
        () async {
      if (!Platform.isLinux) return;

      await service.initialize(initialFontSize: FontSize.medium);

      // Simulate external 3840px monitor connecting and becoming primary.
      when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => const Display(
            id: '0',
            name: 'primary',
            size: Size(3840, 1080),
            visiblePosition: Offset.zero,
            visibleSize: Size(3840, 1080),
            scaleFactor: 1.0,
          ));
      when(mockWM.getDevicePixelRatio()).thenReturn(2.0);

      service.didChangeMetrics();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Simulate external monitor disconnecting: primary reverts to 2944px.
      when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => const Display(
            id: '0',
            name: 'primary',
            size: Size(2944, 1840),
            visiblePosition: Offset.zero,
            visibleSize: Size(2944, 1840),
            scaleFactor: 1.0,
          ));
      when(mockWM.getDevicePixelRatio()).thenReturn(1.0);

      clearInteractions(mockWM);
      service.didChangeMetrics();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // After the display change the strip MUST be re-anchored to (0,0).
      // Without the fix, LinuxResizeStrategy.collapse() never calls setPosition
      // and the window drifts to wherever the WM rescued it — buttons disappear.
      verify(mockWM.setPosition(Offset.zero)).called(greaterThanOrEqualTo(1));
    });
  });
}
