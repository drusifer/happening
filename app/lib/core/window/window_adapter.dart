// Production adapter from window_manager (nativeapi) to WindowAdapter.
//
// TLDR:
// Overview: Bridges the window_manager 0.7.0+ native Window API to a clean,
//           Flutter-typed interface so WindowService and strategies remain
//           decoupled from nativeapi types and unit-testable with mocks/fakes.
// Problem:  window_manager 0.6.0+ replaced the singleton WindowManager with
//           WindowManager.instance.getCurrent() returning a nativeapi Window
//           that uses native geometry/color types and FFI handles.
// Solution: WindowAdapter defines the Flutter-typed contract; NativeWindowAdapter
//           implements it over WindowManager.instance.getCurrent().
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:io';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart' as wm;

abstract class WindowAdapter {
  double getDevicePixelRatio();
  Future<void> configureInitialWindow({
    required Size size,
    required Color backgroundColor,
    required bool alwaysOnTop,
    required bool skipTaskbar,
    required bool hideTitleBar,
  });
  Future<void> setAsFrameless();
  Future<void> setBackgroundColor(Color color);
  Future<void> setResizable(bool isResizable);
  Future<void> setMinimumSize(Size size);
  Future<void> setMaximumSize(Size size);
  Future<void> setSize(Size size, {bool animate = false});
  Future<Size> getSize();
  Future<void> setPosition(Offset position, {bool animate = false});
  Future<Offset> getPosition();
  Future<void> setAlwaysOnTop(bool isAlwaysOnTop);
  Future<void> setAlwaysOnBottom(bool isAlwaysOnBottom);
  Future<void> setHasShadow(bool hasShadow);
  Future<void> show({bool inactive = false});
  Future<void> focus();
  Future<void> blur();
}

class NativeWindowAdapter implements WindowAdapter {
  NativeWindowAdapter();

  static final _log = Logger('NativeWindowAdapter');

  wm.Window? _cachedWindow;

  wm.Window get _window =>
      _cachedWindow ??= wm.WindowManager.instance.getCurrent()!;

  String _dumpWindowState(wm.Window w) {
    return 'id=${w.id} visible=${w.isVisible} frameless=${w.isFrameless} '
        'titleBar=${w.titleBarStyle} bounds=${w.bounds.toRect()} '
        'contentBounds=${w.contentBounds.toRect()} size=${w.size.toSize()} '
        'pos=${w.position.toOffset()} minSize=${w.minimumSize.toSize()} '
        'maxSize=${w.maximumSize.toSize()} alwaysOnTop=${w.isAlwaysOnTop} '
        'opacity=${w.opacity}';
  }

  @override
  double getDevicePixelRatio() {
    final views = PlatformDispatcher.instance.views;
    if (views.isNotEmpty) {
      return views.first.devicePixelRatio;
    }
    return 1.0;
  }

  @override
  Future<void> configureInitialWindow({
    required Size size,
    required Color backgroundColor,
    required bool alwaysOnTop,
    required bool skipTaskbar,
    required bool hideTitleBar,
  }) async {
    final window = _window;
    _log.fine(
        'configureInitialWindow(start): targetSize=$size state={${_dumpWindowState(window)}}');
    if (hideTitleBar) {
      final wasFrameless = window.isFrameless;
      window.titleBarStyle = wm.TitleBarStyle.hidden;
      window.isWindowControlButtonsVisible = true;
      if (Platform.isMacOS && wasFrameless) {
        window.hasShadow = true;
      }
    }
    if (window.isFullScreen) {
      window.isFullScreen = false;
    }
    if (window.isMaximized) {
      if (window.isMaximizedVertically) {
        window.setMaximizedVertically(false);
      }
      window.unmaximize();
    }
    if (window.isMinimized) {
      window.restore();
    }
    window.setSize(size.toNative(), false);
    window.isAlwaysOnTop = alwaysOnTop;
    window.backgroundColor = backgroundColor.toNative();
    window.isVisibleInTaskbar = !skipTaskbar;
    _log.fine(
        'configureInitialWindow(done): state={${_dumpWindowState(window)}}');
  }

  @override
  Future<void> setAsFrameless() async {
    final window = _window;
    window.setFrameless(true);
    if (Platform.isMacOS) {
      window.hasShadow = false;
      window.backgroundColor = const Color(0x00000000).toNative();
    }
    _log.fine('setAsFrameless: state={${_dumpWindowState(window)}}');
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    _window.backgroundColor = color.toNative();
  }

  @override
  Future<void> setResizable(bool isResizable) async {
    _window.isResizable = isResizable;
    _log.fine('setResizable($isResizable): resizable=${_window.isResizable}');
  }

  @override
  Future<void> setMinimumSize(Size size) async {
    _window.minimumSize = size.toNative();
    _log.fine('setMinimumSize($size): actual=${_window.minimumSize.toSize()}');
  }

  @override
  Future<void> setMaximumSize(Size size) async {
    _window.maximumSize = size.toNative();
    _log.fine('setMaximumSize($size): actual=${_window.maximumSize.toSize()}');
  }

  @override
  Future<void> setSize(Size size, {bool animate = false}) async {
    _window.setSize(size.toNative(), animate);
    _log.fine(
        'setSize($size, animate=$animate): state={${_dumpWindowState(_window)}}');
  }

  @override
  Future<Size> getSize() async {
    return _window.size.toSize();
  }

  @override
  Future<void> setPosition(Offset position, {bool animate = false}) async {
    final window = _window;
    final current = window.bounds.toRect();
    final target = Rect.fromLTWH(
      position.dx,
      position.dy,
      current.width,
      current.height,
    );
    if (!animate || !window.animateBounds(target.toNative())) {
      window.bounds = target.toNative();
    }
    _log.fine(
        'setPosition($position, currentBounds=$current -> target=$target): state={${_dumpWindowState(window)}}');
  }

  @override
  Future<Offset> getPosition() async {
    return _window.position.toOffset();
  }

  @override
  Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    _window.isAlwaysOnTop = isAlwaysOnTop;
  }

  @override
  Future<void> setAlwaysOnBottom(bool isAlwaysOnBottom) async {
    _window.isAlwaysOnBottom = isAlwaysOnBottom;
  }

  @override
  Future<void> setHasShadow(bool hasShadow) async {
    _window.hasShadow = hasShadow;
    _log.fine('setHasShadow($hasShadow): shadow=${_window.hasShadow}');
  }

  @override
  Future<void> show({bool inactive = false}) async {
    final window = _window;
    _log.fine(
        'show(inactive=$inactive, before): state={${_dumpWindowState(window)}}');
    if (window.isMinimized) {
      window.restore();
    }
    if (inactive) {
      window.showInactive();
    } else {
      window.show();
    }
    _log.fine(
        'show(inactive=$inactive, after): state={${_dumpWindowState(window)}}');
  }

  @override
  Future<void> focus() async {
    _window.focus();
    _log.fine('focus: state={${_dumpWindowState(_window)}}');
  }

  @override
  Future<void> blur() async {
    _window.blur();
    _log.fine('blur: state={${_dumpWindowState(_window)}}');
  }
}
