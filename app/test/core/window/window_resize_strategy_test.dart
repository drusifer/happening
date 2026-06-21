import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/window/resize_strategy/window_resize_strategy.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';

import 'window_service_test.mocks.dart';

void main() {
  late MockWindowManager mockWM;
  late MockScreenRetriever mockSR;

  setUp(() {
    mockWM = MockWindowManager();
    mockSR = MockScreenRetriever();

    when(mockSR.getPrimaryDisplay()).thenAnswer((_) async => const Display(
          id: '0',
          name: 'primary',
          size: Size(1920, 1080),
          visiblePosition: Offset.zero,
          visibleSize: Size(1920, 1080),
          scaleFactor: 1.0,
        ));
    when(mockWM.setSize(any, animate: anyNamed('animate')))
        .thenAnswer((_) => Future.value());
    when(mockWM.setMinimumSize(any)).thenAnswer((_) => Future.value());
    when(mockWM.setMaximumSize(any)).thenAnswer((_) => Future.value());
    when(mockWM.setResizable(any)).thenAnswer((_) => Future.value());
    when(mockWM.setPosition(any, animate: anyNamed('animate')))
        .thenAnswer((_) => Future.value());
    when(mockWM.setBounds(any,
            position: anyNamed('position'),
            size: anyNamed('size'),
            animate: anyNamed('animate')))
        .thenAnswer((_) => Future.value());
    when(mockWM.getSize()).thenAnswer((_) async => Size.zero);
  });

  // applySize is the single resize primitive every path routes through. The
  // bracket (min == max == size, NEVER setMaximumSize(Size.infinite)) lives in
  // the base; only the geometry call (setSize vs setBounds) is per-platform.
  group('applySize — shared min/max bracket (via MacOsResizeStrategy)', () {
    late MacOsResizeStrategy strategy;
    setUp(() => strategy = MacOsResizeStrategy(wm: mockWM, sr: mockSR));

    test('pins floor→cap→size→floor, capping max at the target (not infinite)',
        () async {
      final order = <String>[];
      final minArgs = <Size>[];
      final maxArgs = <Size>[];
      when(mockWM.setMinimumSize(any)).thenAnswer((inv) async {
        order.add('min');
        minArgs.add(inv.positionalArguments[0] as Size);
      });
      when(mockWM.setMaximumSize(any)).thenAnswer((inv) async {
        order.add('max');
        maxArgs.add(inv.positionalArguments[0] as Size);
      });
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('size'));

      await strategy.applySize(const Size(1920, 55));

      expect(order, ['min', 'max', 'size', 'min']);
      // floor first drops to zero (allow shrink), then pins up to the target.
      expect(minArgs, [Size.zero, const Size(1920, 55)]);
      // max is capped exactly to the target — never Size.infinite (L-005).
      expect(maxArgs, [const Size(1920, 55)]);
    });

    test('L-005 guard: never widens max to Size.infinite', () async {
      await strategy.applySize(const Size(268, 72), position: Offset.zero);
      verifyNever(mockWM.setMaximumSize(Size.infinite));
    });

    test('default geometry repositions via setPosition + setSize', () async {
      await strategy.applySize(const Size(268, 72),
          position: const Offset(10, 20));
      verify(mockWM.setPosition(const Offset(10, 20))).called(1);
      verify(mockWM.setSize(const Size(268, 72), animate: anyNamed('animate')))
          .called(1);
      verifyNever(mockWM.setBounds(any,
          position: anyNamed('position'),
          size: anyNamed('size'),
          animate: anyNamed('animate')));
    });

    // L-005: applySize must bracket setSize as min(0)→max(target)→size→min(target)
    // so Win32 reliably reaches the target. Every transition routes through
    // applySize (via WindowService.applyState), so this one bracket is the only
    // place it must be correct.
    test('applySize brackets setSize with min/max/size/min (L-005)', () async {
      final order = <String>[];
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('min'));
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('max'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('size'));

      await strategy.applySize(const Size(1920, 250));
      expect(order, ['min', 'max', 'size', 'min']);

      order.clear();
      await strategy.applySize(const Size(1920, 55));
      expect(order, ['min', 'max', 'size', 'min']);
    });
  });

  group('WindowsResizeStrategy — setBounds geometry', () {
    late WindowsResizeStrategy strategy;
    setUp(() => strategy = WindowsResizeStrategy(wm: mockWM, sr: mockSR));

    test('initialize: setResizable(false) + setPosition(zero)', () async {
      await strategy.initialize(const Size(1920, 55), 1.0);
      verify(mockWM.setResizable(false)).called(1);
      verify(mockWM.setPosition(Offset.zero)).called(1);
    });

    test('repositions via setPosition + setSize, never setBounds (first-show '
        'setBounds flakes to ~1px — L-005)', () async {
      await strategy.applySize(const Size(268, 72),
          position: const Offset(10, 20));
      verify(mockWM.setPosition(const Offset(10, 20))).called(1);
      verify(mockWM.setSize(const Size(268, 72), animate: anyNamed('animate')))
          .called(1);
      verifyNever(mockWM.setBounds(any,
          position: anyNamed('position'),
          size: anyNamed('size'),
          animate: anyNamed('animate')));
    });

    test('in-place resize (no position) uses setSize', () async {
      await strategy.applySize(const Size(1920, 55));
      verify(mockWM.setSize(const Size(1920, 55), animate: anyNamed('animate')))
          .called(1);
      verifyNever(mockWM.setBounds(any,
          position: anyNamed('position'),
          size: anyNamed('size'),
          animate: anyNamed('animate')));
    });

    test('L-005 guard: caps max at target, never Size.infinite', () async {
      await strategy.applySize(const Size(268, 72), position: Offset.zero);
      verify(mockWM.setMaximumSize(const Size(268, 72))).called(1);
      verifyNever(mockWM.setMaximumSize(Size.infinite));
    });
  });

  group('MacOsResizeStrategy', () {
    late MacOsResizeStrategy strategy;
    setUp(() => strategy = MacOsResizeStrategy(wm: mockWM, sr: mockSR));

    test('initialize: setResizable(false) + setPosition(zero)', () async {
      await strategy.initialize(const Size(1920, 55), 1.0);
      verify(mockWM.setResizable(false)).called(1);
      verify(mockWM.setPosition(Offset.zero)).called(1);
    });
  });
}
