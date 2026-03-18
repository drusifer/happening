// E2E repro test for BUG-B: Linux setSize() no-op
//
// Scenario (from log-sample.txt lines 53-56):
//   _doCollapse() called → setSize(60) → getSize() still reports 200px
//   Only setMaximumSize(60) actually forced the window to shrink.
//
// These tests use a realistic GTK-style WindowManager spy that honours
// ONLY setMaximumSize constraints — setSize() is advisory and ignored.
// This mirrors real GTK/Wayland compositor behaviour.
//
// Expected: Tests FAIL with current LinuxResizeStrategy (setSize only).
// Goal: Capture the bug scenario before any fix is applied.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ---------------------------------------------------------------------------
// GTK-style WindowManager spy
//
// Simulates a GTK/Wayland compositor where:
//   - setSize()        = advisory request, IGNORED (window stays same size)
//   - setMaximumSize() = hard constraint: if max < current, window shrinks
//   - setMinimumSize() = hard constraint: if min > current, window grows
//   - expand()         = advisory request, honoured here for simplicity
// ---------------------------------------------------------------------------
class _GtkStyleWindowManager extends Fake implements WindowManager {
  Size _current = const Size(1920, 55); // starts at collapsed height
  Size _maxSize = Size.infinite;
  Size _minSize = Size.zero;

  Size get reportedSize => _current;

  @override
  Future<void> ensureInitialized() async {}

  @override
  double getDevicePixelRatio() => 1.0;

  @override
  Future<void> waitUntilReadyToShow([
    WindowOptions? options,
    VoidCallback? callback,
  ]) async {
    callback?.call();
  }

  @override
  Future<void> setPosition(Offset position, {bool animate = false}) async {}

  @override
  Future<void> setAsFrameless() async {}

  @override
  Future<void> show({bool inactive = false}) async {}

  @override
  Future<void> focus() async {}

  @override
  // GTK: setSize is advisory — compositor may ignore it.
  // We always ignore it to simulate the worst-case Linux behaviour.
  Future<void> setSize(Size size, {bool animate = false}) async {
    // intentionally no-op: compositor ignores our size request
  }

  @override
  Future<Size> getSize({bool isPhysical = false}) async => _current;

  @override
  // setMaximumSize IS honoured: forces window to shrink if needed.
  Future<void> setMaximumSize(Size size) async {
    _maxSize = size;
    // If current size exceeds new max, compositor shrinks window.
    if (_current.height > _maxSize.height) {
      _current = Size(_current.width, _maxSize.height);
    }
    if (_current.width > _maxSize.width) {
      _current = Size(_maxSize.width, _current.height);
    }
  }

  @override
  // setMinimumSize IS honoured: forces window to grow if needed.
  Future<void> setMinimumSize(Size size) async {
    _minSize = size;
    if (_current.height < _minSize.height) {
      _current = Size(_current.width, _minSize.height);
    }
  }

  @override
  Future<void> setResizable(bool resizable) async {}

  @override
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {}

  @override
  Future<void> setSkipTaskbar(bool skip) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setTitleBarStyle(
    TitleBarStyle titleBarStyle, {
    bool windowButtonVisibility = true,
  }) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
Display _fakeDisplay() => Display(
      id: '0',
      name: 'primary',
      size: const Size(1920, 1080),
      visiblePosition: Offset.zero,
      visibleSize: const Size(1920, 1080),
      scaleFactor: 1.0,
    );

class _FakeScreenRetriever extends Fake implements ScreenRetriever {
  @override
  Future<Display> getPrimaryDisplay() async => _fakeDisplay();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  if (!Platform.isLinux) {
    // These tests are Linux-specific — skip on other platforms.
    return;
  }

  late _GtkStyleWindowManager gtkWM;
  late _FakeScreenRetriever fakeSR;
  late WindowService service;

  setUp(() {
    gtkWM = _GtkStyleWindowManager();
    fakeSR = _FakeScreenRetriever();
    service = WindowService(windowManager: gtkWM, screenRetriever: fakeSR);
  });

  group('ARCH-002: Linux expand() — min>max conflict forces GTK to grow', () {
    test('expand() from collapsed height: window must actually grow to target',
        () async {
      // Start at collapsed height — setSize(260) will be ignored by GTK.
      gtkWM._current = const Size(1920, 55);

      await service.initialize(initialFontSize: FontSize.large);

      // setSize(260) no-op; setMinimumSize(260) with max-cap still 55
      // → min(260) > max(55) = invalid constraint → GTK grows to 260.
      await service.expand();

      final actualHeight = gtkWM.reportedSize.height;
      expect(
        actualHeight,
        greaterThanOrEqualTo(service.getExpandedHeight()),
        reason: 'ARCH-002: window is ${actualHeight}px after expand — '
            'setSize() was ignored by GTK. '
            'LinuxResizeStrategy needs setMin before setMax (min>max conflict).',
      );
    });
  });

  group('BUG-B: Linux LinuxResizeStrategy — setSize() no-op on GTK', () {
    test(
        'collapse() after expand: window must actually shrink to collapsed height',
        () async {
      // Simulate a window that starts expanded (hover card visible).
      // The GTK compositor has the window at 260px.
      gtkWM._current = const Size(1920, 260);

      await service.initialize(initialFontSize: FontSize.large);

      // Force isExpandedNotifier to reflect expanded state.
      await service.expand();

      // User moves away — collapse is requested.
      await service.collapse();

      final actualHeight = gtkWM.reportedSize.height;

      // EXPECTED TO FAIL with current LinuxResizeStrategy:
      // setSize(55) is ignored by GTK → window stays at 260px.
      // Fix requires setMinimumSize(zero) + setMaximumSize(55) + setSize(55).
      expect(
        actualHeight,
        lessThanOrEqualTo(service.getCollapsedHeight()),
        reason: 'BUG-B: window is still ${actualHeight}px after collapse — '
            'setSize() was ignored by GTK compositor. '
            'LinuxResizeStrategy needs constraint-forcing (setMin + setMax).',
      );
    });

    test(
        'on startup, first collapse must shrink window from compositor-assigned height (reproduces log-sample.txt lines 53-56)',
        () async {
      // GTK compositor assigns an initial window height that may differ from
      // what waitUntilReadyToShow requests. In the log, the app started at
      // 200px despite requesting 60px via WindowOptions.
      // The first collapse() call (from TimelineStrip on render) must shrink it.
      gtkWM._current = const Size(1920, 200);

      await service.initialize(initialFontSize: FontSize.large);

      // TimelineStrip calls collapse() immediately on first render.
      await service.collapse();

      final actualHeight = gtkWM.reportedSize.height;

      expect(
        actualHeight,
        lessThanOrEqualTo(service.getCollapsedHeight()),
        reason: 'BUG-B startup: window is ${actualHeight}px after first '
            'collapse() — matches log-sample.txt where setSize(60) left '
            'window at 200px. setMaximumSize constraint needed.',
      );
    });

    test(
        'isExpandedNotifier is false after collapse but window is still visually expanded (state/OS mismatch)',
        () async {
      gtkWM._current = const Size(1920, 260);
      await service.initialize(initialFontSize: FontSize.large);
      await service.expand();
      await service.collapse();

      final actualHeight = gtkWM.reportedSize.height;
      final notifierSaysCollapsed = !service.isExpandedNotifier.value;

      // Notifier says collapsed (correct), but OS window is still tall.
      // This is the symptom Drew observed: hover card gone but window huge.
      expect(notifierSaysCollapsed, true,
          reason: 'isExpandedNotifier should be false after collapse');

      expect(
        actualHeight,
        lessThanOrEqualTo(service.getCollapsedHeight()),
        reason: 'BUG-B mismatch: notifier=collapsed but OS window=${actualHeight}px. '
            'State and visual are out of sync.',
      );
    });
  });
}
