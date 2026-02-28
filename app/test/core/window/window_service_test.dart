import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
      when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => Display(
            id: 0,
            name: 'primary',
            size: const Size(3840, 2160),
            visiblePosition: Offset.zero,
            visibleSize: const Size(3840, 2160),
            scaleFactor: 2.0,
          ));

      // Mock WM methods to return Future.value()
      when(mockWM.ensureInitialized()).thenAnswer((_) => Future.value());
      when(mockWM.setResizable(any)).thenAnswer((_) => Future.value());
      when(mockWM.setMinimumSize(any)).thenAnswer((_) => Future.value());
      when(mockWM.setMaximumSize(any)).thenAnswer((_) => Future.value());
      when(mockWM.setSize(any)).thenAnswer((_) => Future.value());
      when(mockWM.setPosition(any)).thenAnswer((_) => Future.value());
      when(mockWM.setAlwaysOnTop(any)).thenAnswer((_) => Future.value());
      when(mockWM.show()).thenAnswer((_) => Future.value());
    });

    test('initialize sets up the window with logical pixels', () async {
      // Mock waitUntilReadyToShow to execute the callback
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      await service.initialize();

      verify(mockWM.ensureInitialized()).called(1);

      // logicalWidth = 3840 / 2.0 = 1920.0
      const expectedSize = Size(1920.0, 30.0);
      // setMinimumSize(30) called: 1 (callback)
      verify(mockWM.setMinimumSize(expectedSize)).called(1);
      verify(mockWM.setSize(expectedSize)).called(1);
      verify(mockWM.setPosition(Offset.zero)).called(1);
      verify(mockWM.setAlwaysOnTop(true)).called(1);
    });

    test('expand resizes the window to expanded height', () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      // First initialize to set _lastWidth
      await service.initialize();

      await service.expand();

      const expandedSize = Size(1920.0, 200.0);
      verify(mockWM.setMinimumSize(expandedSize)).called(1);
      verify(mockWM.setMaximumSize(expandedSize)).called(1);
      verify(mockWM.setSize(expandedSize)).called(1);
    });

    test('collapse resizes the window back to strip height', () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      // First initialize to set _lastWidth
      await service.initialize();

      await service.collapse();

      const collapsedSize = Size(1920.0, 30.0);
      // setMinimumSize(30) called: 1 (callback), 1 (explicit collapse) = 2
      verify(mockWM.setMinimumSize(collapsedSize)).called(2);
      verify(mockWM.setMaximumSize(collapsedSize))
          .called(2); // callback, collapse
      verify(mockWM.setSize(collapsedSize)).called(2); // callback, collapse
    });
  });
}
