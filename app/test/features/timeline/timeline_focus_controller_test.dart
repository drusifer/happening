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

  final List<WindowMode> modeCalls = [];
  int sendToBackCalls = 0;
  int restoreToFrontCalls = 0;

  @override
  Future<void> setWindowMode(WindowMode mode) async {
    modeCalls.add(mode);
  }

  @override
  Future<void> sendToBack() async {
    sendToBackCalls++;
  }

  @override
  Future<void> restoreToFront() async {
    restoreToFrontCalls++;
  }
}

void main() {
  group('TimelineFocusController — send-to-back', () {
    test('starts not sent-to-back', () {
      final controller =
          TimelineFocusController(windowService: _FakeWindowService());
      addTearDown(controller.dispose);
      expect(controller.isSentToBack, isFalse);
    });

    test('sendToBack sets state and calls service', () async {
      final ws = _FakeWindowService();
      final controller = TimelineFocusController(windowService: ws);
      addTearDown(controller.dispose);

      await controller.sendToBack();

      expect(controller.isSentToBack, isTrue);
      expect(ws.sendToBackCalls, 1);
    });

    test('restoreToFront clears state and calls service', () async {
      final ws = _FakeWindowService();
      final controller = TimelineFocusController(windowService: ws);
      addTearDown(controller.dispose);

      await controller.sendToBack();
      await controller.restoreToFront();

      expect(controller.isSentToBack, isFalse);
      expect(ws.restoreToFrontCalls, 1);
    });

    test('auto-restores after restoreTimeout', () async {
      final ws = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: ws,
        restoreTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(controller.dispose);

      await controller.sendToBack();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(controller.isSentToBack, isFalse);
      expect(ws.restoreToFrontCalls, 1);
    });

    test('second sendToBack resets the restore timer', () async {
      final ws = _FakeWindowService();
      final controller = TimelineFocusController(
        windowService: ws,
        restoreTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await controller.sendToBack();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await controller.sendToBack(); // reset timer
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.isSentToBack, isTrue); // not yet restored

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.isSentToBack, isFalse); // now restored
    });

    test('isSentToBackNotifier mirrors isSentToBack', () async {
      final controller =
          TimelineFocusController(windowService: _FakeWindowService());
      addTearDown(controller.dispose);

      expect(controller.isSentToBackNotifier.value, isFalse);
      await controller.sendToBack();
      expect(controller.isSentToBackNotifier.value, isTrue);
      await controller.restoreToFront();
      expect(controller.isSentToBackNotifier.value, isFalse);
    });

    test('setWindowMode delegates to WindowService', () async {
      final ws = _FakeWindowService();
      final controller = TimelineFocusController(windowService: ws);
      addTearDown(controller.dispose);

      await controller.setWindowMode(WindowMode.overlay);

      expect(ws.modeCalls, [WindowMode.overlay]);
    });
  });
}
