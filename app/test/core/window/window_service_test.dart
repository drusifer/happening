import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/linux_dock_window_manager.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

@GenerateNiceMocks([MockSpec<WindowManager>(), MockSpec<ScreenRetriever>()])
import 'window_service_test.mocks.dart';

class _FakeLinuxDockWindowManager extends LinuxDockWindowManager {
  final List<String> calls = [];
  int? lastDockHeight;

  @override
  Future<bool> isDockable() async => true;

  @override
  Future<void> dock({required int height}) async {
    calls.add('dock');
    lastDockHeight = height;
  }

  @override
  Future<void> undock() async {
    calls.add('undock');
  }
}

class _FakeInteractionStrategy extends WindowInteractionStrategy {
  WindowMode? initializedMode;

  @override
  WindowModeAvailability get availability =>
      const WindowModeAvailability(supportsReserved: true);

  @override
  Future<void> initialize(WindowMode effectiveMode) async {
    initializedMode = effectiveMode;
  }

  @override
  Future<void> sendToBack() async {}

  @override
  Future<void> restoreToFront() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowService', () {
    late MockWindowManager mockWM;
    late MockScreenRetriever mockSR;
    late WindowService service;
    late _FakeInteractionStrategy fakeInteractionStrategy;
    late _FakeLinuxDockWindowManager fakeLinuxDock;

    setUp(() {
      mockWM = MockWindowManager();
      mockSR = MockScreenRetriever();
      fakeInteractionStrategy = _FakeInteractionStrategy();
      fakeLinuxDock = _FakeLinuxDockWindowManager();
      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        interactionStrategy: fakeInteractionStrategy,
        linuxDockWindowManager: fakeLinuxDock,
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
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      verify(mockWM.ensureInitialized()).called(1);
      verify(mockWM.getDevicePixelRatio()).called(1);
      verify(mockWM.waitUntilReadyToShow(any, any)).called(1);
    });

    test('initialize passes initial window mode to interaction strategy',
        () async {
      await service.initialize(
        initialFontSizePx: kDefaultFontSizePx,
        initialWindowMode: WindowMode.overlay,
      );

      expect(fakeInteractionStrategy.initializedMode, WindowMode.overlay);
      expect(service.windowMode, WindowMode.overlay);
    });

    test('setWindowMode updates stored mode and reinitializes interaction',
        () async {
      await service.setWindowMode(WindowMode.overlay);

      expect(service.windowMode, WindowMode.overlay);
      expect(fakeInteractionStrategy.initializedMode, WindowMode.overlay);
    });

    // _onDisplayChanged zero-width guard (DPMS/wake regression)
    // When screen_retriever returns width=0 (transient during display reinit),
    // _screenWidth must NOT be updated and no resize must occur.
    test('_onDisplayChanged: ignores transient zero-width display event',
        () async {
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

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
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);
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
    // MacOsResizeStrategy.initialize() calls setPosition(Offset.zero) so the
    // strip is re-anchored to the primary display's top-left after each collapse.
    test('THEORY-D: Linux display change re-anchors position after collapse',
        () async {
      if (!Platform.isLinux) return;

      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

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

      // After the display change the strip MUST resize to the new width.
      verify(mockWM.setSize(argThat(predicate<Size>(
        (s) => s.width == 2944,
        'new display width',
      )))).called(greaterThanOrEqualTo(1));
    });

    group('Linux strut (F-28)', () {
      WindowService linuxService() => WindowService(
            windowManager: mockWM,
            screenRetriever: mockSR,
            platformOverride: TargetPlatform.linux,
            interactionStrategy: fakeInteractionStrategy,
            linuxDockWindowManager: fakeLinuxDock,
          );

      test('initialize reserved mode calls dock with physical pixel height',
          () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        // DPR=1.0 (mock), collapsedHeight=55 → physical=55
        expect(fakeLinuxDock.calls, contains('dock'));
        expect(fakeLinuxDock.lastDockHeight, 55);
      });

      test('initialize overlay mode does NOT call dock', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.overlay,
        );
        expect(fakeLinuxDock.calls, isNot(contains('dock')));
      });

      test('setWindowMode reserved→dock, other→undock', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.overlay,
        );
        fakeLinuxDock.calls.clear();

        await svc.setWindowMode(WindowMode.reserved);
        expect(fakeLinuxDock.calls, contains('dock'));

        fakeLinuxDock.calls.clear();
        await svc.setWindowMode(WindowMode.overlay);
        expect(fakeLinuxDock.calls, contains('undock'));
      });

      test('dispose calls undock', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        fakeLinuxDock.calls.clear();

        svc.dispose();
        await Future.delayed(Duration.zero);
        expect(fakeLinuxDock.calls, contains('undock'));
      });

      test('display change re-docks with updated height', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        fakeLinuxDock.calls.clear();

        // Simulate DPR change so _onDisplayChangedInner fires.
        when(mockWM.getDevicePixelRatio()).thenReturn(2.0);

        svc.didChangeMetrics();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // Should re-dock with dpr=2.0: collapsedHeight=55 * 2 = 110
        expect(fakeLinuxDock.calls, contains('dock'));
        expect(fakeLinuxDock.lastDockHeight, 110);
      });
    });
  });
}
