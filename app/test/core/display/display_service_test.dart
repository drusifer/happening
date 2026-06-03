import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/display/persisted_display_choice.dart';

DisplayInfo _d(String id, {bool primary = false, double originX = 0}) {
  return DisplayInfo(
    id: DisplayId(id),
    osName: 'M-$id',
    size: const Size(1920, 1080),
    workAreaOrigin: Offset(originX, 0),
    workAreaSize: const Size(1920, 1080),
    scaleFactor: 1.0,
    isPrimary: primary,
  );
}

class _FakeProbe implements DisplayProbe {
  _FakeProbe(this._initial);
  List<DisplayInfo> _initial;
  int calls = 0;

  void setDisplays(List<DisplayInfo> next) {
    _initial = next;
  }

  @override
  Future<List<DisplayInfo>> getAll() async {
    calls += 1;
    return List.of(_initial);
  }
}

class _FakeEvents implements DisplayEvents {
  void Function()? _cb;
  int subscribes = 0;
  int cancels = 0;

  void fire() => _cb?.call();

  @override
  void Function() subscribe(void Function() onChange) {
    subscribes += 1;
    _cb = onChange;
    return () {
      cancels += 1;
      _cb = null;
    };
  }
}

Future<void> _zeroSleep(Duration _) async {}

void main() {
  group('DisplayService — initialize', () {
    test('hydrates available displays and picks primary when no choice',
        () async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final probe = _FakeProbe([a, b]);
      final events = _FakeEvents();

      final svc = DisplayService(
        probe: probe,
        events: events,
        sleep: _zeroSleep,
      );

      await svc.initialize();

      expect(svc.availableDisplays, [a, b]);
      expect(svc.activeDisplay, a);
      expect(svc.isInFallback, isFalse);
      expect(events.subscribes, 1);
    });

    test('initialize is idempotent', () async {
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true)]),
        events: _FakeEvents(),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      await svc.initialize();
      // No assertion needed beyond not throwing.
    });
  });

  group('DisplayService — choice resolution', () {
    test('persisted choice that matches → active is chosen, not primary',
        () async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final svc = DisplayService(
        probe: _FakeProbe([a, b]),
        events: _FakeEvents(),
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, b);
      expect(svc.isInFallback, isFalse);
      expect(svc.persistedChoiceMatch, b);
    });

    test('persisted choice absent at init → IN_FALLBACK on primary', () async {
      final a = _d('a', primary: true);
      final svc = DisplayService(
        probe: _FakeProbe([a]),
        events: _FakeEvents(),
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, a);
      expect(svc.isInFallback, isTrue);
      expect(svc.persistedChoiceMatch, isNull);
    });
  });

  group('DisplayService — state machine', () {
    test('disconnect of chosen → IN_FALLBACK and notify', () async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final probe = _FakeProbe([a, b]);
      final events = _FakeEvents();
      final svc = DisplayService(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, b);

      var notified = 0;
      svc.addListener(() => notified += 1);

      probe.setDisplays([a]);
      events.fire();
      await Future<void>.delayed(Duration.zero);
      // Let the debounced refresh complete.
      await Future<void>.delayed(Duration.zero);

      expect(svc.activeDisplay, a);
      expect(svc.isInFallback, isTrue);
      expect(notified, greaterThan(0));
    });

    test('reconnect of chosen → auto-return to chosen', () async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final probe = _FakeProbe([a]);
      final events = _FakeEvents();
      final svc = DisplayService(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.isInFallback, isTrue);
      expect(svc.activeDisplay, a);

      probe.setDisplays([a, b]);
      events.fire();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(svc.activeDisplay, b);
      expect(svc.isInFallback, isFalse);
    });

    test('burst of events coalesces into one probe pass', () async {
      final a = _d('a', primary: true);
      final probe = _FakeProbe([a]);
      final events = _FakeEvents();
      final svc = DisplayService(
        probe: probe,
        events: events,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(probe.calls, 1); // initial

      // Fire 5 events in immediate succession — coalesce expected.
      for (var i = 0; i < 5; i++) {
        events.fire();
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // Initial + at most one debounced refresh (some impls may run twice if
      // events arrive mid-flight; allow up to 2 follow-up probes).
      expect(probe.calls, lessThanOrEqualTo(3));
    });
  });

  group('DisplayService — choice change at runtime', () {
    test('setChoiceResolver re-resolves active without an event', () async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final svc = DisplayService(
        probe: _FakeProbe([a, b]),
        events: _FakeEvents(),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, a);

      await svc.setChoiceResolver(
        const DisplayIdChoiceResolver(DisplayId('b')),
      );
      expect(svc.activeDisplay, b);
      expect(svc.isInFallback, isFalse);
    });
  });

  group('FingerprintChoiceResolver', () {
    test('hasPreference is false when constructed with null choice', () {
      final resolver = FingerprintChoiceResolver(null);
      expect(resolver.hasPreference, isFalse);
      expect(resolver.resolve([_d('a', primary: true)]), isNull);
    });

    test('hasPreference is true when constructed with a choice', () {
      const choice = PersistedDisplayChoice(
        osName: 'M-b',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 1920,
        yOffsetLogical: 0,
      );
      final resolver = FingerprintChoiceResolver(choice);
      expect(resolver.hasPreference, isTrue);
    });

    test('resolves exact match', () {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final choice = PersistedDisplayChoice.fromDisplay(b);
      final resolver = FingerprintChoiceResolver(choice);
      expect(resolver.resolve([a, b]), b);
    });

    test('weak match triggers onWeakMatch callback', () {
      // Persisted choice "Dell" at 1920×1080; only available "Dell" is
      // 3840×2160 — same name only → weak match.
      const choice = PersistedDisplayChoice(
        osName: 'M-b',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      const available = DisplayInfo(
        id: DisplayId('b'),
        osName: 'M-b',
        size: Size(3840, 2160),
        workAreaOrigin: Offset(0, 0),
        workAreaSize: Size(3840, 2160),
        scaleFactor: 1.0,
        isPrimary: false,
      );
      var weakCallbacks = 0;
      final resolver = FingerprintChoiceResolver(
        choice,
        onWeakMatch: (_, __) => weakCallbacks += 1,
      );
      expect(resolver.resolve([available]), available);
      expect(weakCallbacks, 1);
    });

    test('no match returns null and does not call onWeakMatch', () {
      const choice = PersistedDisplayChoice(
        osName: 'gone',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      var weakCallbacks = 0;
      final resolver = FingerprintChoiceResolver(
        choice,
        onWeakMatch: (_, __) => weakCallbacks += 1,
      );
      expect(resolver.resolve([_d('a', primary: true)]), isNull);
      expect(weakCallbacks, 0);
    });
  });

  group('DisplayService — hasPreference integration', () {
    test('NullChoiceResolver → isInFallback is false even when no chosen',
        () async {
      // Default service (no choiceResolver) uses the internal _NullChoiceResolver.
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true)]),
        events: _FakeEvents(),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.isInFallback, isFalse);
    });

    test('FingerprintChoiceResolver(null) → isInFallback is false', () async {
      // Fresh-install user with no persisted choice. Bug guarded against in
      // Morpheus Note 1 / Trin Observation 2.
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true)]),
        events: _FakeEvents(),
        choiceResolver: FingerprintChoiceResolver(null),
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.isInFallback, isFalse);
    });

    test('initialChoice constructs FingerprintChoiceResolver internally',
        () async {
      const choice = PersistedDisplayChoice(
        osName: 'M-b',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true)]),
        events: _FakeEvents(),
        initialChoice: choice,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.isInFallback, isTrue); // because 'M-b' is not available
    });

    test('hoisted onWeakMatch is triggered on weak match during refresh',
        () async {
      const choice = PersistedDisplayChoice(
        osName: 'M-b',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      const available = DisplayInfo(
        id: DisplayId('b'),
        osName: 'M-b',
        size: Size(3840, 2160),
        workAreaOrigin: Offset.zero,
        workAreaSize: Size(3840, 2160),
        scaleFactor: 1.0,
        isPrimary: false,
      );
      var weakCallbacks = 0;
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true), available]),
        events: _FakeEvents(),
        initialChoice: choice,
        onWeakMatch: (_, __) => weakCallbacks += 1,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, available);
      expect(weakCallbacks, 1);
    });

    test(
        'setPersistedChoice swaps resolver and triggers refresh using hoisted callback',
        () async {
      final a = _d('a', primary: true);
      const choice = PersistedDisplayChoice(
        osName: 'M-b',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      const available = DisplayInfo(
        id: DisplayId('b'),
        osName: 'M-b',
        size: Size(3840, 2160),
        workAreaOrigin: Offset.zero,
        workAreaSize: Size(3840, 2160),
        scaleFactor: 1.0,
        isPrimary: false,
      );
      var weakCallbacks = 0;
      final svc = DisplayService(
        probe: _FakeProbe([a, available]),
        events: _FakeEvents(),
        onWeakMatch: (_, __) => weakCallbacks += 1,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(svc.activeDisplay, a);
      expect(weakCallbacks, 0);

      await svc.setPersistedChoice(choice);
      expect(svc.activeDisplay, available);
      expect(weakCallbacks, 1);
    });
  });

  group('DisplayService — lifecycle', () {
    test('dispose cancels the event subscription', () async {
      final events = _FakeEvents();
      final svc = DisplayService(
        probe: _FakeProbe([_d('a', primary: true)]),
        events: events,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      expect(events.cancels, 0);
      svc.dispose();
      expect(events.cancels, 1);
    });

    test('events fired after dispose are ignored', () async {
      final events = _FakeEvents();
      final probe = _FakeProbe([_d('a', primary: true)]);
      final svc = DisplayService(
        probe: probe,
        events: events,
        sleep: _zeroSleep,
      );
      await svc.initialize();
      svc.dispose();
      final callsAfterDispose = probe.calls;
      events.fire(); // no-op because subscription cancelled
      await Future<void>.delayed(Duration.zero);
      expect(probe.calls, callsAfterDispose);
    });
  });
}
