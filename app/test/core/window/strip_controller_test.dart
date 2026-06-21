import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/window/strip_controller.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';

// Reuse the generated mocks from the WindowService suite.
import 'window_service_test.mocks.dart';

class _StubProbe implements DisplayProbe {
  @override
  Future<List<DisplayInfo>> getAll() async => const [];
}

class _StubEvents implements DisplayEvents {
  @override
  void Function() subscribe(void Function() onChange) => () {};
}

/// WindowService whose transitions are recorded and (optionally) held open, so
/// the controller's serialisation/last-wins behaviour can be observed. The
/// controller dispatches `→hidden` to [hideStrip], `hidden→shown` to [showStrip],
/// and `shown→shown` to [applyState]; all three record their target state so the
/// observed sequence reflects the logical transitions regardless of the path.
class _FakeWindowService extends WindowService {
  _FakeWindowService({
    required super.windowManager,
    required super.screenRetriever,
    required super.displayService,
  });

  final List<StripState> applied = [];
  Completer<void>? blockOn;

  Future<void> _record(StripState state) async {
    if (blockOn != null) await blockOn!.future;
    applied.add(state);
  }

  @override
  Future<void> applyState(StripState state) => _record(state);

  @override
  Future<void> hideStrip() => _record(StripState.hidden);

  @override
  Future<void> showStrip() => _record(StripState.collapsedShown);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWindowService windowService;
  late StripController controller;

  setUp(() async {
    final displayService = DisplayService(
      probe: _StubProbe(),
      events: _StubEvents(),
      sleep: (_) async {},
    );
    await displayService.initialize();

    windowService = _FakeWindowService(
      windowManager: MockWindowManager(),
      screenRetriever: MockScreenRetriever(),
      displayService: displayService,
    );
    controller = StripController(windowService: windowService);
  });

  tearDown(() => controller.dispose());

  test('starts in collapsedShown', () {
    expect(controller.state, StripState.collapsedShown);
  });

  test('expand() applies expandedShown and updates state', () async {
    await controller.expand();

    expect(windowService.applied, [StripState.expandedShown]);
    expect(controller.state, StripState.expandedShown);
  });

  test('hide() applies hidden; show() returns to collapsedShown', () async {
    await controller.hide();
    expect(controller.state, StripState.hidden);

    await controller.show();
    expect(controller.state, StripState.collapsedShown);
    expect(
        windowService.applied, [StripState.hidden, StripState.collapsedShown]);
  });

  test('notifies listeners only when the settled state actually changes',
      () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.expand(); // collapsed → expanded : notify
    await controller.expand(); // already expanded : dropped, no notify
    await controller.collapse(); // expanded → collapsed : notify

    expect(notifications, 2);
  });

  test(
      'last-wins: intermediate transition is superseded while one is in-flight',
      () async {
    // Let the first transition run and settle.
    await controller.collapse();
    windowService.applied.clear();

    // Hold the next apply open, then fire a burst.
    final release = Completer<void>();
    windowService.blockOn = release;

    final fExpand = controller.expand(); // begins running, then blocks
    await Future.delayed(Duration.zero); // let the loop pick it up
    final fHide = controller.hide(); // queued
    final fShow = controller.show(); // supersedes hide (collapsedShown)

    windowService.blockOn = null;
    release.complete();
    await Future.wait([fExpand, fHide, fShow]);

    // expanded ran (was in-flight), hidden was superseded, collapsed ran last.
    expect(windowService.applied,
        [StripState.expandedShown, StripState.collapsedShown]);
    expect(controller.state, StripState.collapsedShown);
  });

  test('reapply() re-applies the current state even when unchanged', () async {
    await controller.expand();
    windowService.applied.clear();

    await controller.reapply();

    expect(windowService.applied, [StripState.expandedShown]);
    expect(controller.state, StripState.expandedShown);
  });
}
