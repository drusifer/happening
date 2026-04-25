import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/focus/timeline_focus_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  final List<bool> focusedCalls = [];
  final List<bool> passThroughCalls = [];
  final List<WindowMode> modeCalls = [];

  @override
  Future<void> setInteractionFocused(bool focused) async {
    focusedCalls.add(focused);
  }

  @override
  Future<void> setPassThroughEnabled(bool enabled) async {
    passThroughCalls.add(enabled);
  }

  @override
  Future<void> setWindowMode(WindowMode mode) async {
    modeCalls.add(mode);
  }
}

void main() {
  group('TimelineFocusController', () {
    test('transparent mode initializes in idle pass-through state', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.transparent,
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.isFocused, isFalse);
      expect(windowService.focusedCalls, [false]);
      expect(windowService.passThroughCalls, [true]);
    });

    test('focus enters interactive mode and disables pass-through', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.transparent,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.focus();

      expect(controller.isFocused, isTrue);
      expect(windowService.focusedCalls, [false, true]);
      expect(windowService.passThroughCalls, [true, false]);
    });

    test('escape unfocuses transparent mode', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.transparent,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.focus();
      await controller.handleEscape();

      expect(controller.isFocused, isFalse);
      expect(windowService.passThroughCalls.last, isTrue);
    });

    test('interaction hold suppresses inactivity timeout', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.transparent,
        inactivityTimeout: const Duration(milliseconds: 40),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.focus();
      controller.setInteractionHold(true);

      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(controller.isFocused, isTrue);

      controller.setInteractionHold(false);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(controller.isFocused, isFalse);
    });

    test('reserved mode initializes as focused without pass-through', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.reserved,
      );
      addTearDown(controller.dispose);

      await controller.initialize();

      expect(controller.isFocused, isTrue);
      expect(windowService.focusedCalls, [true]);
      expect(windowService.passThroughCalls, [false]);
    });

    test('window mode switch to reserved keeps interactive state', () async {
      final windowService = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: windowService,
        initialWindowMode: WindowMode.transparent,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.setWindowMode(WindowMode.reserved);

      expect(windowService.modeCalls, [WindowMode.reserved]);
      expect(controller.isFocused, isTrue);
      expect(windowService.passThroughCalls.last, isFalse);
    });
  });
}
