import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:happening/features/timeline/hover/hover_controller.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/window/window_service_test.mocks.dart';

// ── Fake WindowService ────────────────────────────────────────────────────────

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _NoopWM(),
          screenRetriever: _NoopSR(),
        );

  final calls = <String>[];

  @override
  Future<void> expand() async => calls.add('expand');

  @override
  Future<void> collapse() async => calls.add('collapse');
}

class _NoopWM extends Mock implements WindowManager {}
class _NoopSR extends Mock implements ScreenRetriever {}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DefaultHoverController', () {
    late _FakeWindowService ws;
    late DefaultHoverController ctrl;

    setUp(() {
      ws = _FakeWindowService();
      ctrl = DefaultHoverController(ws);
    });

    test('setIntent(expanded) calls expand when collapsed', () {
      ws.isExpandedNotifier.value = false;
      ctrl.setIntent(ExpansionState.expanded);
      expect(ws.calls, ['expand']);
    });

    test('setIntent(expanded) does nothing when already expanded', () {
      ws.isExpandedNotifier.value = true;
      ctrl.setIntent(ExpansionState.expanded);
      expect(ws.calls, isEmpty);
    });

    test('setIntent(collapsed) calls collapse when expanded', () {
      ws.isExpandedNotifier.value = true;
      ctrl.setIntent(ExpansionState.collapsed);
      expect(ws.calls, ['collapse']);
    });

    test('setIntent(collapsed) does nothing when already collapsed', () {
      ws.isExpandedNotifier.value = false;
      ctrl.setIntent(ExpansionState.collapsed);
      expect(ws.calls, isEmpty);
    });
  });

  group('LinuxHoverController — focus-follows-mouse suppression', () {
    late _FakeWindowService ws;
    late LinuxHoverController ctrl;

    setUp(() {
      ws = _FakeWindowService();
      ctrl = LinuxHoverController(ws);
    });

    tearDown(() => ctrl.dispose());

    test('expand then immediate collapse is suppressed', () async {
      ws.isExpandedNotifier.value = false;
      ctrl.setIntent(ExpansionState.expanded);
      // Spurious collapse arrives before suppression window expires
      ws.isExpandedNotifier.value = true;
      ctrl.setIntent(ExpansionState.collapsed);
      expect(ws.calls, ['expand']); // collapse was suppressed
    });

    test('collapse after suppression window fires normally', () async {
      ws.isExpandedNotifier.value = false;
      ctrl.setIntent(ExpansionState.expanded);
      ws.isExpandedNotifier.value = true;

      // Wait past 300ms suppression window
      await Future<void>.delayed(const Duration(milliseconds: 350));

      ctrl.setIntent(ExpansionState.collapsed);
      expect(ws.calls, ['expand', 'collapse']);
    });

    test('double expand does not double-call expand', () {
      ws.isExpandedNotifier.value = false;
      ctrl.setIntent(ExpansionState.expanded);
      ws.isExpandedNotifier.value = true;
      ctrl.setIntent(ExpansionState.expanded); // already expanded
      expect(ws.calls, ['expand']);
    });
  });
}
