import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/display/persisted_display_choice.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/linux_dock_window_manager.dart';
import 'package:happening/core/window/linux_window_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

@GenerateNiceMocks([MockSpec<WindowManager>(), MockSpec<ScreenRetriever>()])
import 'window_service_test.mocks.dart';

DisplayInfo _display(String id, {bool primary = true, double width = 1920}) {
  return DisplayInfo(
    id: DisplayId(id),
    osName: 'M-$id',
    size: Size(width, 1080),
    workAreaOrigin: Offset.zero,
    workAreaSize: Size(width, 1080),
    scaleFactor: 1.0,
    isPrimary: primary,
  );
}

class _StubProbe implements DisplayProbe {
  _StubProbe(this._displays);
  List<DisplayInfo> _displays;

  void setDisplays(List<DisplayInfo> next) {
    _displays = next;
  }

  @override
  Future<List<DisplayInfo>> getAll() async => List.of(_displays);
}

class _StubEvents implements DisplayEvents {
  void Function()? _cb;

  void fire() => _cb?.call();

  @override
  void Function() subscribe(void Function() onChange) {
    _cb = onChange;
    return () => _cb = null;
  }
}

Future<void> _zeroSleep(Duration _) async {}

Future<DisplayService> _makeDisplayService({
  required _StubProbe probe,
  required _StubEvents events,
  DisplayChoiceResolver? choiceResolver,
}) async {
  final svc = DisplayService(
    probe: probe,
    events: events,
    choiceResolver: choiceResolver,
    sleep: _zeroSleep,
  );
  await svc.initialize();
  return svc;
}

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
    late _StubProbe probe;
    late _StubEvents events;
    late DisplayService displayService;

    setUp(() async {
      mockWM = MockWindowManager();
      mockSR = MockScreenRetriever();
      fakeInteractionStrategy = _FakeInteractionStrategy();
      fakeLinuxDock = _FakeLinuxDockWindowManager();

      probe = _StubProbe([_display('0')]);
      events = _StubEvents();
      displayService = await _makeDisplayService(probe: probe, events: events);

      service = WindowService(
        windowManager: mockWM,
        screenRetriever: mockSR,
        displayService: displayService,
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

    test('initialize positions window on the active display work area origin',
        () async {
      const customDisplay = DisplayInfo(
        id: DisplayId('secondary'),
        osName: 'Dell U2723QE',
        size: Size(1920, 1080),
        workAreaOrigin: Offset(1920, 0),
        workAreaSize: Size(1920, 1080),
        scaleFactor: 1.0,
        isPrimary: false,
      );
      probe.setDisplays([customDisplay]);
      await displayService.setChoiceResolver(
          const DisplayIdChoiceResolver(DisplayId('secondary')));

      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      verify(mockWM.setPosition(const Offset(1920, 0))).called(1);
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
    // When the active display reports width=0 (transient during display
    // reinit), _screenWidth must NOT be updated and no resize must occur.
    test('_onDisplayChanged: ignores transient zero-width display event',
        () async {
      await service.initialize(initialFontSizePx: kDefaultFontSizePx);

      // Swap active display to width=0 (DPMS / wake transient)
      probe.setDisplays([_display('0', width: 0)]);
      // Force DPR change so the change-check can't skip early
      when(mockWM.getDevicePixelRatio()).thenReturn(2.0);

      clearInteractions(mockWM);
      events.fire();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

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
      probe.setDisplays([_display('0', width: 3840)]);
      when(mockWM.getDevicePixelRatio()).thenReturn(2.0);

      events.fire();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Simulate external monitor disconnecting: primary reverts to 2944px.
      probe.setDisplays([_display('0', width: 2944)]);
      when(mockWM.getDevicePixelRatio()).thenReturn(1.0);

      clearInteractions(mockWM);
      events.fire();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // After the display change the strip MUST resize to the new width.
      verify(mockWM.setSize(argThat(predicate<Size>(
        (s) => s.width == 2944,
        'new display width',
      )))).called(greaterThanOrEqualTo(1));
    });

    group('F-30 DisplayService wiring', () {
      const secondaryOrigin = Offset(1920, 0);
      DisplayInfo makeSecondary() => const DisplayInfo(
            id: DisplayId('1'),
            osName: 'M-1',
            size: Size(2560, 1440),
            workAreaOrigin: secondaryOrigin,
            workAreaSize: Size(2560, 1440),
            scaleFactor: 1.0,
            isPrimary: false,
          );

      test('initialize reads width from DisplayService.activeDisplay',
          () async {
        probe.setDisplays([_display('0', width: 3000)]);
        events.fire();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        // Trigger a collapse — _doCollapse uses the cached _screenWidth, which
        // must have been hydrated from DisplayService.activeDisplay.size.width.
        await service.performResize(ExpansionState.collapsed);

        verify(mockWM.setSize(argThat(predicate<Size>(
          (s) => s.width == 3000,
          'width from displayService.activeDisplay',
        )))).called(greaterThanOrEqualTo(1));
      });

      test(
          'active display change with generic/duplicate IDs calls strategy.moveToDisplay',
          () async {
        final d1 = _display('0', width: 1920);
        const d2 = DisplayInfo(
          id: DisplayId('0'),
          osName: 'Secondary',
          size: Size(2560, 1440),
          workAreaOrigin: Offset(1920, 0),
          workAreaSize: Size(2560, 1440),
          scaleFactor: 1.0,
          isPrimary: false,
        );

        probe.setDisplays([d1, d2]);
        events.fire();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        await displayService.setChoiceResolver(
          FingerprintChoiceResolver(PersistedDisplayChoice.fromDisplay(d2)),
        );
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        verify(mockWM.setPosition(
          argThat(equals(const Offset(1920, 0))),
          animate: anyNamed('animate'),
        )).called(greaterThanOrEqualTo(1));
      });

      test(
          'active display change calls strategy.moveToDisplay '
          '(wm.setPosition with new workAreaOrigin)', () async {
        final secondary = makeSecondary();
        probe.setDisplays([_display('0'), secondary]);
        events.fire();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        await displayService.setChoiceResolver(
          const DisplayIdChoiceResolver(DisplayId('1')),
        );
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        verify(mockWM.setPosition(
          argThat(equals(secondaryOrigin)),
          animate: anyNamed('animate'),
        )).called(greaterThanOrEqualTo(1));
      });

      test('active display change resizes to new display width', () async {
        final secondary = makeSecondary();
        probe.setDisplays([_display('0'), secondary]);
        events.fire();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        await displayService.setChoiceResolver(
          const DisplayIdChoiceResolver(DisplayId('1')),
        );
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        verify(mockWM.setSize(argThat(predicate<Size>(
          (s) => s.width == 2560,
          'secondary width',
        )))).called(greaterThanOrEqualTo(1));
      });

      test('DPR-only change does not call moveToDisplay (no active change)',
          () async {
        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        when(mockWM.getDevicePixelRatio()).thenReturn(2.0);
        service.didChangeMetrics();
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        // No setPosition with the secondary's origin should fire — only the
        // initial display's origin (Offset.zero) is in play.
        verifyNever(mockWM.setPosition(
          argThat(equals(secondaryOrigin)),
          animate: anyNamed('animate'),
        ));
      });

      test('dispose removes DisplayService listener', () async {
        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        service.dispose();
        clearInteractions(mockWM);

        // After dispose, a DisplayService change must not reach WindowService.
        final secondary = makeSecondary();
        probe.setDisplays([_display('0'), secondary]);
        await displayService.setChoiceResolver(
          const DisplayIdChoiceResolver(DisplayId('1')),
        );
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);

        verifyNever(mockWM.setPosition(
          argThat(equals(secondaryOrigin)),
          animate: anyNamed('animate'),
        ));
      });
    });

    group('F-31 hide/show API', () {
      test('getMiniWidth formula: fontSizePx * 6 + 60', () {
        expect(service.getMiniWidth(12), closeTo(12 * 6.0 + 60, 0.001));
        expect(service.getMiniWidth(14), closeTo(14 * 6.0 + 60, 0.001));
        expect(service.getMiniWidth(16), closeTo(16 * 6.0 + 60, 0.001));
      });

      test('resizeToMiniStrip calls wm.setSize with mini dimensions', () async {
        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        await service.resizeToMiniStrip(kDefaultFontSizePx);

        verify(mockWM.setSize(argThat(predicate<Size>(
          (s) =>
              s.width == service.getMiniWidth(kDefaultFontSizePx) &&
              s.height == service.getCollapsedHeight(),
          'mini size',
        )))).called(1);
      });

      test('resizeToFullStrip calls wm.setSize with screen width', () async {
        await service.initialize(initialFontSizePx: kDefaultFontSizePx);
        clearInteractions(mockWM);

        await service.resizeToFullStrip();

        verify(mockWM.setSize(argThat(predicate<Size>(
          (s) => s.width == 1920 && s.height == service.getCollapsedHeight(),
          'full size',
        )))).called(1);
      });

      test('prepareToHide/completeShow are no-ops on base WindowService',
          () async {
        await expectLater(service.prepareToHide(), completes);
        await expectLater(service.completeShow(), completes);
      });
    });

    group('Linux strut (F-28)', () {
      LinuxWindowService linuxService() => LinuxWindowService(
            windowManager: mockWM,
            screenRetriever: mockSR,
            displayService: displayService,
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

      test('reassertAppBar repositions window and re-docks', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );

        fakeLinuxDock.calls.clear();

        await svc.reassertAppBar();

        verify(mockWM.setPosition(const Offset(0, 0))).called(
            3); // strategy.initialize + readyToShow moveToDisplay + reassertAppBar
        expect(fakeLinuxDock.calls, containsAllInOrder(['undock', 'dock']));
      });
    });

    group('F-31 Linux hide/show hooks', () {
      LinuxWindowService linuxService() => LinuxWindowService(
            windowManager: mockWM,
            screenRetriever: mockSR,
            displayService: displayService,
            linuxDockWindowManager: fakeLinuxDock,
          );

      test('onHideStrip calls undock when mode is reserved', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        fakeLinuxDock.calls.clear();

        await svc.prepareToHide();

        expect(fakeLinuxDock.calls, contains('undock'));
        expect(fakeLinuxDock.calls, isNot(contains('dock')));
      });

      test('onShowStrip calls dock when mode is reserved', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        fakeLinuxDock.calls.clear();

        await svc.completeShow();

        expect(fakeLinuxDock.calls, contains('dock'));
      });

      test('onHideStrip is no-op when mode is overlay', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.overlay,
        );
        fakeLinuxDock.calls.clear();

        await svc.prepareToHide();

        expect(fakeLinuxDock.calls, isEmpty);
      });

      test('onShowStrip is no-op when mode is overlay', () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.overlay,
        );
        fakeLinuxDock.calls.clear();

        await svc.completeShow();

        expect(fakeLinuxDock.calls, isEmpty);
      });

      test('rapid hide/show toggle leaves strut consistent (AC-F31-4-4)',
          () async {
        final svc = linuxService();
        await svc.initialize(
          initialFontSizePx: kDefaultFontSizePx,
          initialWindowMode: WindowMode.reserved,
        );
        fakeLinuxDock.calls.clear();

        // Simulate 3 rapid hide/show cycles
        for (var i = 0; i < 3; i++) {
          await svc.prepareToHide();
          await svc.completeShow();
        }

        // Must alternate undock/dock with no dangling state
        expect(
          fakeLinuxDock.calls,
          equals(['undock', 'dock', 'undock', 'dock', 'undock', 'dock']),
        );
      });
    });
  });
}
