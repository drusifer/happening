import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/features/timeline/display_fallback_indicator.dart';

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

class _StubProbe implements DisplayProbe {
  _StubProbe(this._displays);
  List<DisplayInfo> _displays;
  void setDisplays(List<DisplayInfo> next) => _displays = next;
  @override
  Future<List<DisplayInfo>> getAll() async => List.of(_displays);
}

class _StubEvents implements DisplayEvents {
  void Function()? _cb;
  void fire() => _cb?.call();
  @override
  void Function() subscribe(void Function() onChange) {
    _cb = onChange;
    return () => _cb = null;
  }
}

Future<void> _zeroSleep(Duration _) async {}

Future<DisplayService> _svc({
  required _StubProbe probe,
  required _StubEvents events,
  DisplayChoiceResolver? choiceResolver,
}) async {
  final s = DisplayService(
    probe: probe,
    events: events,
    choiceResolver: choiceResolver,
    sleep: _zeroSleep,
  );
  await s.initialize();
  return s;
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('DisplayFallbackIndicator', () {
    testWidgets('invisible when not in fallback', (tester) async {
      final probe = _StubProbe([_d('a', primary: true)]);
      final events = _StubEvents();
      final svc = await _svc(probe: probe, events: events);

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () {},
      )));

      expect(find.byIcon(Icons.desktop_access_disabled), findsNothing);
    });

    testWidgets('visible when isInFallback', (tester) async {
      final a = _d('a', primary: true);
      final probe = _StubProbe([a]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('missing')),
      );
      expect(svc.isInFallback, isTrue);

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () {},
      )));

      expect(find.byIcon(Icons.desktop_access_disabled), findsOneWidget);
    });

    testWidgets('icon size clamps at max=14 for tall strips', (tester) async {
      final probe = _StubProbe([_d('a', primary: true)]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('missing')),
      );

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 200,
        onTap: () {},
      )));

      final Icon icon =
          tester.widget(find.byIcon(Icons.desktop_access_disabled));
      expect(icon.size, 14);
    });

    testWidgets('icon size shrinks below max=14 for short strips',
        (tester) async {
      final probe = _StubProbe([_d('a', primary: true)]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('missing')),
      );

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 18,
        onTap: () {},
      )));

      final Icon icon =
          tester.widget(find.byIcon(Icons.desktop_access_disabled));
      // stripHeight (18) - headroom (8) = 10
      expect(icon.size, 10);
    });

    testWidgets('tap fires onTap callback', (tester) async {
      final probe = _StubProbe([_d('a', primary: true)]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('missing')),
      );

      var tapped = 0;
      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () => tapped += 1,
      )));

      await tester.tap(find.byIcon(Icons.desktop_access_disabled));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('auto-return triggers fade animation, opacity reaches 0',
        (tester) async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final probe = _StubProbe([a]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
      );
      expect(svc.isInFallback, isTrue);

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () {},
      )));

      expect(find.byIcon(Icons.desktop_access_disabled), findsOneWidget);
      final Icon iconBefore =
          tester.widget(find.byIcon(Icons.desktop_access_disabled));
      expect(iconBefore.color!.a, closeTo(1.0, 0.01));

      // Reconnect b → auto-return.
      probe.setDisplays([a, b]);
      events.fire();
      await tester.pump(); // process debounce
      await tester.pump(); // process notify
      // Animation duration is 600ms — advance well past it.
      await tester.pump(kFallbackIndicatorAnimationDuration);
      await tester.pumpAndSettle();

      // After auto-return: not in fallback and animation done → indicator hidden.
      expect(svc.isInFallback, isFalse);
      expect(find.byIcon(Icons.desktop_access_disabled), findsNothing);
    });

    testWidgets('no animation when entering IN_FALLBACK (only on exit)',
        (tester) async {
      final a = _d('a', primary: true);
      final b = _d('b', originX: 1920);
      final probe = _StubProbe([a, b]);
      final events = _StubEvents();
      final svc = await _svc(
        probe: probe,
        events: events,
        choiceResolver: const DisplayIdChoiceResolver(DisplayId('b')),
      );
      expect(svc.isInFallback, isFalse);

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () {},
      )));
      expect(find.byIcon(Icons.desktop_access_disabled), findsNothing);

      // Disconnect b → enter IN_FALLBACK.
      probe.setDisplays([a]);
      events.fire();
      await tester.pump();
      await tester.pump();

      // Indicator becomes visible immediately at full opacity — no fade-in.
      expect(svc.isInFallback, isTrue);
      expect(find.byIcon(Icons.desktop_access_disabled), findsOneWidget);
      final Icon icon =
          tester.widget(find.byIcon(Icons.desktop_access_disabled));
      expect(icon.color!.a, closeTo(1.0, 0.01));
    });

    testWidgets('dispose removes the DisplayService listener', (tester) async {
      final probe = _StubProbe([_d('a', primary: true)]);
      final events = _StubEvents();
      final svc = await _svc(probe: probe, events: events);

      await tester.pumpWidget(_wrap(DisplayFallbackIndicator(
        displayService: svc,
        stripHeight: 28,
        onTap: () {},
      )));

      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      // No exception → listener was cleanly removed.
      svc.dispose();
    });
  });
}
