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
    when(mockWM.getSize()).thenAnswer((_) async => Size.zero);
  });

  group('LinuxResizeStrategy', () {
    late LinuxResizeStrategy strategy;

    setUp(() {
      strategy = LinuxResizeStrategy(wm: mockWM, sr: mockSR);
    });

    test('initialize sets position to zero, no setResizable', () async {
      await strategy.initialize(const Size(1920, 55), 1.0);
      verify(mockWM.setPosition(Offset.zero)).called(1);
      verifyNever(mockWM.setResizable(any));
    });

    test('expand calls setSize→setMin→setMax→setSize then onExpanded',
        () async {
      final order = <String>[];
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));

      await strategy.expand(const Size(1920, 250), () => order.add('cb'));
      expect(order, ['setSize', 'setMin', 'setMax', 'setSize', 'cb']);
    });

    test('collapse calls setSize→setMin→setMax', () async {
      final order = <String>[];
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));

      await strategy.collapse(const Size(1920, 55));
      expect(order, ['setSize', 'setMin', 'setMax']);
    });
  });

  group('WindowsResizeStrategy', () {
    late WindowsResizeStrategy strategy;

    setUp(() {
      strategy = WindowsResizeStrategy(wm: mockWM, sr: mockSR);
    });

    test('initialize calls setResizable(false)', () async {
      await strategy.initialize(const Size(1920, 55), 1.0);
      verify(mockWM.setResizable(false)).called(1);
    });

    test('expand: onExpanded then setMax→setSize→setMin', () async {
      final order = <String>[];
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));

      await strategy.expand(const Size(1920, 250), () => order.add('cb'));
      expect(order, ['cb', 'setMax', 'setSize', 'setMin']);
    });

    test('collapse: setMin→setMax→setSize', () async {
      final order = <String>[];
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));

      await strategy.collapse(const Size(1920, 55));
      expect(order, ['setMin', 'setMax', 'setSize']);
    });
  });

  group('MacOsResizeStrategy', () {
    late MacOsResizeStrategy strategy;

    setUp(() {
      strategy = MacOsResizeStrategy(wm: mockWM, sr: mockSR);
    });

    test('initialize: setResizable(false) + setPosition(zero)', () async {
      await strategy.initialize(const Size(1920, 55), 1.0);
      verify(mockWM.setResizable(false)).called(1);
      verify(mockWM.setPosition(Offset.zero)).called(1);
    });

    test('expand: onExpanded then setMax→setSize→setMin', () async {
      final order = <String>[];
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));

      await strategy.expand(const Size(1920, 250), () => order.add('cb'));
      expect(order, ['cb', 'setMax', 'setSize', 'setMin']);
    });

    test('collapse: setMin→setMax→setSize', () async {
      final order = <String>[];
      when(mockWM.setMinimumSize(any))
          .thenAnswer((_) async => order.add('setMin'));
      when(mockWM.setMaximumSize(any))
          .thenAnswer((_) async => order.add('setMax'));
      when(mockWM.setSize(any, animate: anyNamed('animate')))
          .thenAnswer((_) async => order.add('setSize'));

      await strategy.collapse(const Size(1920, 55));
      expect(order, ['setMin', 'setMax', 'setSize']);
    });
  });
}
