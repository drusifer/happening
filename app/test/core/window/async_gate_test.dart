import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/window/async_gate.dart';

void main() {
  group('AsyncGate', () {
    test('runs a single value through the handler', () async {
      final seen = <int>[];
      final gate = AsyncGate<int>((v) async => seen.add(v))..start();

      await gate.send(1);

      expect(seen, [1]);
    });

    test('runs values serially in order when not overlapping', () async {
      final seen = <int>[];
      final gate = AsyncGate<int>((v) async => seen.add(v))..start();

      await gate.send(1);
      await gate.send(2);
      await gate.send(3);

      expect(seen, [1, 2, 3]);
    });

    test('last-wins: a value queued while another runs supersedes intermediate',
        () async {
      final seen = <int>[];
      final running = Completer<void>();
      final release = Completer<void>();
      final gate = AsyncGate<int>((v) async {
        seen.add(v);
        if (v == 1) {
          running.complete();
          await release.future; // hold the first run open
        }
      })
        ..start();

      final f1 = gate.send(1);
      await running.future; // 1 is now in-flight

      // While 1 runs, queue 2 then 3 — 2 must be superseded by 3.
      final f2 = gate.send(2);
      final f3 = gate.send(3);

      release.complete();
      await Future.wait([f1, f2, f3]);

      expect(seen, [1, 3]); // 2 never ran
    });

    test('superseded request future still completes (no dangle)', () async {
      final running = Completer<void>();
      final release = Completer<void>();
      final gate = AsyncGate<int>((v) async {
        if (v == 1) {
          running.complete();
          await release.future;
        }
      })
        ..start();

      gate.send(1);
      await running.future;

      final superseded = gate.send(2);
      gate.send(3); // supersedes 2

      // The superseded future must resolve rather than hang.
      await superseded.timeout(const Duration(seconds: 1));
      release.complete();
    });

    test('identical pending value is coalesced to one run', () async {
      var runs = 0;
      final running = Completer<void>();
      final release = Completer<void>();
      final gate = AsyncGate<int>((v) async {
        runs++;
        if (runs == 1) {
          running.complete();
          await release.future;
        }
      })
        ..start();

      gate.send(1);
      await running.future;

      final a = gate.send(2);
      final b = gate.send(2); // same value → same pending slot

      release.complete();
      await Future.wait([a, b]);

      expect(runs, 2); // first(1) + one(2), not two 2-runs
    });

    test('value equal to settled with empty queue is dropped', () async {
      var runs = 0;
      final gate = AsyncGate<int>((v) async => runs++)..start();

      await gate.send(7);
      await gate.send(7); // already settled, nothing queued → dropped

      expect(runs, 1);
    });

    test('force re-runs a value equal to settled', () async {
      var runs = 0;
      final gate = AsyncGate<int>((v) async => runs++)..start();

      await gate.send(7);
      await gate.send(7, force: true);

      expect(runs, 2);
    });

    test('handler error propagates to the sender and the loop survives',
        () async {
      var attempt = 0;
      final gate = AsyncGate<int>((v) async {
        attempt++;
        if (v == 1) throw StateError('boom');
      })
        ..start();

      await expectLater(gate.send(1), throwsStateError);

      // Loop must keep working after a failed run.
      await gate.send(2);
      expect(attempt, 2);
    });

    test('send after dispose is a no-op that completes', () async {
      var runs = 0;
      final gate = AsyncGate<int>((v) async => runs++)..start();
      gate.dispose();

      await gate.send(1); // completes immediately, never runs
      expect(runs, 0);
    });
  });
}
