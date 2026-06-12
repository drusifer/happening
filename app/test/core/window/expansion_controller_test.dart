import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/window/expansion_controller.dart';
import 'package:happening/core/window/physical_window_state.dart';
import 'package:happening/core/window/resize_executor.dart';
import 'package:happening/features/timeline/expansion_logic.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

class _FakeResizeExecutor implements ResizeExecutor {
  final calls = <ExpansionState>[];

  /// When non-null, resize() blocks until completed.
  Completer<void>? resizeGate;

  @override
  double get collapsedHeight => 60;

  @override
  double get expandedHeight => 340;

  @override
  Future<void> resize(ExpansionState intent) async {
    calls.add(intent);
    final gate = resizeGate;
    if (gate != null) await gate.future;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Pump the Dart event loop [n] times to flush microtasks and async continuations.
Future<void> pump([int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpansionController', () {
    late _FakeResizeExecutor executor;
    late ExpansionController controller;
    late List<PhysicalWindowState> states;
    late StreamSubscription<PhysicalWindowState> sub;

    setUp(() {
      executor = _FakeResizeExecutor();
      controller = ExpansionController(executor: executor)..start();
      states = [];
      sub = controller.stateStream.listen(states.add);
    });

    tearDown(() async {
      await sub.cancel();
      controller.dispose();
    });

    // ── Happy path ────────────────────────────────────────────────────────

    test('expand: emits after resize() completes', () async {
      executor.resizeGate = Completer<void>();
      controller.send(ExpansionState.expanded);
      await pump();
      expect(states, isEmpty, reason: 'resize in flight');

      executor.resizeGate!.complete();
      await pump();
      expect(
          states, [const PhysicalWindowState(height: 340, isExpanded: true)]);
    });

    test('collapse: emits after resize() completes', () async {
      executor.resizeGate = Completer<void>();
      controller.send(ExpansionState.collapsed);
      await pump();
      expect(states, isEmpty, reason: 'resize in flight');

      executor.resizeGate!.complete();
      await pump();
      expect(
          states, [const PhysicalWindowState(height: 60, isExpanded: false)]);
    });

    // ── Queue semantics ───────────────────────────────────────────────────

    test('queued collapse fires after expand completes', () async {
      executor.resizeGate = Completer<void>();
      controller.send(ExpansionState.expanded);
      await pump(1);

      controller.send(ExpansionState.collapsed);

      executor.resizeGate!.complete();
      await pump(5); // expand completes, collapse starts and finishes (no gate)

      expect(
          executor.calls, [ExpansionState.expanded, ExpansionState.collapsed]);
      expect(states.last,
          const PhysicalWindowState(height: 60, isExpanded: false));
    });

    test('10x sends while busy → at most 2 resize calls', () async {
      executor.resizeGate = Completer<void>();
      controller.send(ExpansionState.expanded);
      await pump(1);

      for (var i = 0; i < 10; i++) {
        controller.send(ExpansionState.expanded);
      }

      executor.resizeGate!.complete();
      await pump(3);
      expect(executor.calls.length, lessThanOrEqualTo(2));
    });

    test('idle after queue drains — no double fire', () async {
      controller.send(ExpansionState.expanded);
      await pump();

      final beforeCount = executor.calls.length;
      await pump(5);
      expect(executor.calls.length, beforeCount);
    });

    // ── Redundancy suppression ────────────────────────────────────────────

    test('idle same-state send is skipped — no redundant resize', () async {
      controller.send(ExpansionState.collapsed);
      await pump();
      expect(states.length, 1);

      executor.calls.clear();
      controller.send(ExpansionState.collapsed);
      await pump();

      expect(executor.calls, isEmpty,
          reason: 'redundant idle send must not trigger a resize');
      expect(states.length, 1, reason: 'no new state emitted');
    });

    test('different state after confirmed executes normally', () async {
      controller.send(ExpansionState.collapsed);
      await pump();

      executor.calls.clear();
      controller.send(ExpansionState.expanded);
      await pump();

      expect(executor.calls, [ExpansionState.expanded]);
      expect(states.last,
          const PhysicalWindowState(height: 340, isExpanded: true));
    });

    // ── Stream contract ───────────────────────────────────────────────────

    test('stateStream is a broadcast stream — multiple listeners allowed',
        () async {
      final other = <PhysicalWindowState>[];
      final otherSub = controller.stateStream.listen(other.add);

      controller.send(ExpansionState.expanded);
      await pump();

      expect(states, isNotEmpty);
      expect(other, states);
      await otherSub.cancel();
    });

    test('sendAndAwait: resolves only after resize completes', () async {
      executor.resizeGate = Completer<void>();
      final future = controller.sendAndAwait(ExpansionState.expanded);

      var completed = false;
      unawaited(future.then((_) => completed = true));

      await pump();
      expect(completed, isFalse,
          reason: 'should not resolve while resize is in progress');

      executor.resizeGate!.complete();
      await future; // should resolve now
      expect(completed, isTrue);
    });
  });
}
