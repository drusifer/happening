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

    setUp(() {
      when(mockWM.setAsFrameless()).thenAnswer((_) => Future.value());
      when(mockWM.setHasShadow(any)).thenAnswer((_) => Future.value());
      when(mockWM.setBackgroundColor(any)).thenAnswer((_) => Future.value());
    });

    test('initialize sets up the window with logical pixels', () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      await service.initialize();

      verify(mockWM.ensureInitialized()).called(1);
      verify(mockWM.setAsFrameless()).called(1);
      verify(mockWM.setBackgroundColor(const Color(0x00000000))).called(1);

      // logicalWidth = 3840 / 2.0 = 1920.0; height = 30.0 (default)
      const expectedSize = Size(1920.0, 30.0);
      verify(mockWM.setSize(expectedSize)).called(1);
      verify(mockWM.setPosition(Offset.zero)).called(1);
      verify(mockWM.setAlwaysOnTop(true)).called(1);
    });

    test('expand resizes to expanded height (setSize first, then constraints)',
        () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      await service.initialize();
      await service.expand();

      const expandedSize = Size(1920.0, 250.0);
      verify(mockWM.setSize(expandedSize)).called(1);
      verify(mockWM.setMinimumSize(expandedSize)).called(1);
      verify(mockWM.setMaximumSize(expandedSize)).called(greaterThanOrEqualTo(1));
    });

    test('expand is idempotent — second call is a no-op', () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      await service.initialize();
      await service.expand();
      await service.expand(); // second call — should not resize again

      const expandedSize = Size(1920.0, 250.0);
      verify(mockWM.setSize(expandedSize)).called(1); // only once
    });

    test('collapse resizes to strip height (constraints first, then setSize)',
        () async {
      when(mockWM.waitUntilReadyToShow(any, any))
          .thenAnswer((invocation) async {
        final callback = invocation.positionalArguments[1] as Function;
        await callback();
      });

      await service.initialize();
      await service.expand();
      await service.collapse();

      const collapsedSize = Size(1920.0, 30.0);
      verify(mockWM.setMinimumSize(collapsedSize)).called(greaterThanOrEqualTo(1));
      verify(mockWM.setMaximumSize(collapsedSize)).called(greaterThanOrEqualTo(1));
      verify(mockWM.setSize(collapsedSize)).called(greaterThanOrEqualTo(1));
    });
  });
}
