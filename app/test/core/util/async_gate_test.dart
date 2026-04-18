import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/util/async_gate.dart';

void main() {
  group('AsyncGate', () {
    test('runs action immediately when idle', () async {
      final gate = AsyncGate<bool>();
      final calls = <bool>[];

      await gate.request(true, (v) async => calls.add(v));

      expect(calls, [true]);
    });

    test('queues last value when busy, fires after current completes',
        () async {
      final gate = AsyncGate<bool>();
      final calls = <bool>[];
      final completer = Completer<void>();

      // Start a slow action
      unawaited(gate.request(true, (v) async {
        calls.add(v);
        await completer.future;
      }));

      // These arrive while busy — only last should fire
      unawaited(gate.request(false, (v) async => calls.add(v)));
      unawaited(gate.request(true, (v) async => calls.add(v)));
      unawaited(gate.request(false, (v) async => calls.add(v)));

      // Let slow action finish
      completer.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // First call fired immediately; last pending (false) fired after
      expect(calls, [true, false]);
    });

    test('pending is cleared after firing — no double fire', () async {
      final gate = AsyncGate<int>();
      final calls = <int>[];

      final c1 = Completer<void>();
      unawaited(gate.request(1, (v) async {
        calls.add(v);
        await c1.future;
      }));
      unawaited(gate.request(2, (v) async => calls.add(v)));

      c1.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(calls, [1, 2]);

      // A subsequent request should run fresh (gate is idle again)
      await gate.request(3, (v) async => calls.add(v));
      expect(calls, [1, 2, 3]);
    });

    test('dedup: same-as-inflight cancels pending reversal', () async {
      final gate = AsyncGate<bool>();
      final calls = <bool>[];
      final completer = Completer<void>();

      // Start expand (in-flight = true)
      unawaited(gate.request(true, (v) async {
        calls.add(v);
        await completer.future;
      }));

      // GTK burst: collapse queued, then expand matches inflight → cancel collapse
      unawaited(
          gate.request(false, (v) async => calls.add(v))); // pending=false
      unawaited(gate.request(true,
          (v) async => calls.add(v))); // same as inflight → cancel pending

      completer.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Expand ran; collapse was cancelled; no redundant re-run.
      expect(calls, [true]);
    });

    test('dedup: same-as-pending value is dropped', () async {
      final gate = AsyncGate<bool>();
      final calls = <bool>[];
      final completer = Completer<void>();

      unawaited(gate.request(true, (v) async {
        calls.add(v);
        await completer.future;
      }));

      // false queued as pending
      unawaited(gate.request(false, (v) async => calls.add(v)));
      // same false again → should be dropped (not re-queued)
      unawaited(gate.request(false, (v) async => calls.add(v)));

      completer.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(calls, [true, false]);
    });

    test('no pending — gate stays idle after completion', () async {
      final gate = AsyncGate<String>();
      final calls = <String>[];

      await gate.request('a', (v) async => calls.add(v));
      await gate.request('b', (v) async => calls.add(v));

      expect(calls, ['a', 'b']);
    });
  });
}
