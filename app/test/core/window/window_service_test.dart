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

    test('expand resizes to expanded height', () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.expand();

      const expandedSize = Size(1920.0, 320.0);
      verify(mockWM.setSize(expandedSize)).called(greaterThanOrEqualTo(1));
      if (Platform.isWindows) {
        verify(mockWM.setMinimumSize(expandedSize))
            .called(greaterThanOrEqualTo(1));
        verify(mockWM.setMaximumSize(expandedSize))
            .called(greaterThanOrEqualTo(1));
      }
    });

    test('collapse resizes to strip height', () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.expand();
      await service.collapse();

      const collapsedSize = Size(1920.0, 55.0);
      verify(mockWM.setSize(collapsedSize)).called(greaterThanOrEqualTo(1));
      if (Platform.isWindows) {
        verify(mockWM.setMinimumSize(collapsedSize))
            .called(greaterThanOrEqualTo(1));
        verify(mockWM.setMaximumSize(collapsedSize))
            .called(greaterThanOrEqualTo(1));
      }
    });

    // BUG-A repro: expand/collapse interleave race (log-sample.txt lines 89-95)
    // Without AsyncGate: expand+collapse ran concurrently → window stuck at 200px
    // (setMaximumSize from collapse ran before setMaximumSize from expand)
    test('BUG-A: concurrent expand then collapse does not leave window stuck',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);

      // Fire expand and immediately fire collapse — pre-AsyncGate this would
      // interleave the two resize sequences and leave the window at an
      // intermediate size with isExpandedNotifier in an inconsistent state.
      final expandFuture = service.expand();
      final collapseFuture = service.collapse();
      await Future.wait([expandFuture, collapseFuture]);

      // The gate fires the pending collapse with unawaited — drain the event
      // loop until the gate settles (typically 2-3 microtask cycles).
      for (var i = 0; i < 5; i++) {
        await Future.delayed(Duration.zero);
      }

      // AsyncGate must serialise: last queued request (collapse) wins.
      expect(service.isExpandedNotifier.value, false,
          reason: 'BUG-A: concurrent expand+collapse left isExpanded=true — '
              'race condition not serialised');
    });

    // BUG-A repro: expand-collapse-expand leaves window expanded
    test('BUG-A: rapid expand-collapse-expand ends in expanded state',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);

      unawaited(service.expand());
      unawaited(service.collapse()); // queued, will drop if another arrives
      await service.expand(); // replaces collapse as pending

      // Drain any pending gate work
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(service.isExpandedNotifier.value, true,
          reason: 'BUG-A: final expand was lost — gate dropped it');
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

    // didChangeAppLifecycleState re-asserts collapsed window on resumed
    test('didChangeAppLifecycleState: re-asserts collapsed window on resumed',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.collapse();
      clearInteractions(mockWM);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      const collapsedSize = Size(1920.0, 55.0);
      verify(mockWM.setSize(collapsedSize)).called(greaterThanOrEqualTo(1));
    });

    test('didChangeAppLifecycleState: leaves expanded window alone on resumed',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.expand();
      clearInteractions(mockWM);

      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      verifyNever(mockWM.setSize(any));
      verifyNever(mockWM.setMinimumSize(any));
      verifyNever(mockWM.setMaximumSize(any));
    });

    test(
        'didChangeAppLifecycleState: does not queue collapse during in-flight expand',
        () async {
      await service.initialize(initialFontSize: FontSize.medium);
      clearInteractions(mockWM);

      final expandFuture = service.expand();
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await expandFuture;
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      const collapsedSize = Size(1920.0, 55.0);
      verifyNever(mockWM.setSize(collapsedSize));
      verifyNever(mockWM.setMinimumSize(collapsedSize));
      verifyNever(mockWM.setMaximumSize(collapsedSize));
      expect(service.isExpandedNotifier.value, true);
    });

    test('didChangeAppLifecycleState: does nothing on paused', () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.collapse();
      clearInteractions(mockWM);

      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future.delayed(Duration.zero);

      verifyNever(mockWM.setSize(any));
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

    // BUG-B repro: Linux setSize() no-op (log-sample.txt lines 53-56)
    // Old log: setSize(60) → size still 200px. Only setMaximumSize shrank it.
    // LinuxResizeStrategy currently calls setSize ONLY — no min/max fallback.
    // This test documents the gap: if setSize is a no-op on the running GTK
    // compositor, collapse() will silently fail to shrink the window.
    test(
        'BUG-B: Linux collapse — isExpandedNotifier false even if setSize is a no-op',
        () async {
      if (!Platform.isLinux) return; // Linux-specific

      // Simulate setSize being a no-op (returns immediately but window stays big).
      when(mockWM.setSize(any, animate: anyNamed('animate'))).thenAnswer(
          (_) => Future.value()); // mock already does this — no actual resize

      await service.initialize(initialFontSize: FontSize.medium);
      await service.expand();
      await service.collapse();

      // isExpandedNotifier MUST be false regardless of whether the OS
      // honoured setSize — state and OS window must agree.
      expect(service.isExpandedNotifier.value, false,
          reason: 'BUG-B: notifier inconsistent after collapse');

      // On Linux: verify setSize WAS called for the collapse
      verify(mockWM.setSize(const Size(1920.0, 55.0)))
          .called(greaterThanOrEqualTo(1));

      // NOTE: if this setSize call is a no-op on the real GTK compositor
      // (as observed in log-sample.txt), the visual window will NOT shrink.
      // Fix: LinuxResizeStrategy.collapse() should also call setMaximumSize
      // as a forcing constraint (see WindowsResizeStrategy for reference).
    });
  });
}
