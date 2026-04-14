import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

@GenerateNiceMocks([MockSpec<WindowManager>(), MockSpec<ScreenRetriever>()])
import 'window_service_test.mocks.dart';

void main() {
  group('WindowService', () {
    late MockWindowManager mockWM;
    late MockScreenRetriever mockSR;
    late WindowService service;

    setUp(() {
      mockWM = MockWindowManager();
      mockSR = MockScreenRetriever();
      service = WindowService(windowManager: mockWM, screenRetriever: mockSR);

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
    });

    test('initialize sets up the window with logical pixels', () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((_) => Future.value());

      await service.initialize(initialFontSize: FontSize.medium);

      verify(mockWM.ensureInitialized()).called(1);
      verify(mockWM.getDevicePixelRatio()).called(1);
      verify(mockWM.waitUntilReadyToShow(any, any)).called(1);
    });

    test('expand resizes to expanded height', () async {
      await service.initialize(initialFontSize: FontSize.medium);
      await service.expand();

      const expandedSize = Size(1920.0, 250.0);
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
    test('BUG-A: concurrent expand then collapse does not leave window stuck', () async {
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
    test('BUG-A: rapid expand-collapse-expand ends in expanded state', () async {
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

    // BUG-B repro: Linux setSize() no-op (log-sample.txt lines 53-56)
    // Old log: setSize(60) → size still 200px. Only setMaximumSize shrank it.
    // LinuxResizeStrategy currently calls setSize ONLY — no min/max fallback.
    // This test documents the gap: if setSize is a no-op on the running GTK
    // compositor, collapse() will silently fail to shrink the window.
    test('BUG-B: Linux collapse — isExpandedNotifier false even if setSize is a no-op', () async {
      if (!Platform.isLinux) return; // Linux-specific

      // Simulate setSize being a no-op (returns immediately but window stays big).
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) => Future.value()); // mock already does this — no actual resize

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
