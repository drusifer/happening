import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/util/async_gate.dart';
import 'package:happening/core/util/logger.dart';
import 'package:happening/core/window/resize_strategy/window_resize_strategy.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const int _uCallbackMessage = 0x0400 + 100; // WM_USER + 100
const int _abmNew = 0;
const int _abmRemove = 1;
const int _abmQuerypos = 2;
const int _abmSetpos = 3;
const int _abeTop = 1;

// Flutter Windows runner class name — used to find the HWND.
const String _flutterWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

// ── APPBARDATA FFI struct ────────────────────────────────────────────────────

final class _AppBarData extends Struct {
  @Uint32()
  external int cbSize;
  @IntPtr()
  external int hWnd;
  @Uint32()
  external int uCallbackMessage;
  @Uint32()
  external int uEdge;
  @Int32()
  external int rcLeft;
  @Int32()
  external int rcTop;
  @Int32()
  external int rcRight;
  @Int32()
  external int rcBottom;
  @IntPtr()
  external int lParam;
}

// ── SHAppBarMessage via shell32.dll ──────────────────────────────────────────

typedef _SHNative = IntPtr Function(
    Uint32 dwMessage, Pointer<_AppBarData> pData);
typedef _SHDart = int Function(int dwMessage, Pointer<_AppBarData> pData);

/// Window management service for resizing the app between strip and hover states.
///
/// TLDR:
/// Overview: Controls physical OS window dimensions via window_manager.
/// Problem: High-frequency resizing causes OS flickering and race conditions.
/// Solution: [AsyncGate] serialises expand/collapse; [WindowResizeStrategy]
///           isolates platform-specific resize sequences.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

class WindowService {
  WindowService({
    required WindowManager windowManager,
    required ScreenRetriever screenRetriever,
  })  : _wm = windowManager,
        _sr = screenRetriever,
        _strategy = WindowResizeStrategy.create(
          wm: windowManager,
          sr: screenRetriever,
        );

  final WindowManager _wm;
  final ScreenRetriever _sr;
  final WindowResizeStrategy _strategy;
  final _gate = AsyncGate<bool>();

  FontSize _fontSize = FontSize.medium;

  Pointer<_AppBarData>? _appBarData;
  late final _SHDart _shAppBarMessage;

  /// Notifier for the window's expansion state.
  final isExpandedNotifier = ValueNotifier<bool>(false);

  double _dpr = 1.0;
  double _screenWidth = 0;

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    FontSize initialFontSize = FontSize.medium,
  }) async {
    await _wm.ensureInitialized();
    _fontSize = initialFontSize;

    final double realDpr = _wm.getDevicePixelRatio();
    _dpr = realDpr;
    final display = await _sr.getPrimaryDisplay();
    final width = display.size.width;
    _screenWidth = width;
    final targetHeight = getCollapsedHeight();
    final size = Size(width, targetHeight);

    await AppLogger.debug(
        'WindowService: init dpr=$_dpr displaySize=${display.size} collapsedHeight=$targetHeight expandedHeight=${getExpandedHeight()}');

    final windowOptions = WindowOptions(
      size: size,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await _wm.waitUntilReadyToShow(windowOptions, () async {
      if (Platform.isWindows) {
        await _registerAppBar();
      }
      await _strategy.initialize(size, _dpr);
      await _wm.setAsFrameless();
      await _wm.show();
      await _wm.focus();
    });
  }

  void dispose() {
    _strategy.dispose();
    if (Platform.isWindows && _appBarData != null) {
      _shAppBarMessage(_abmRemove, _appBarData!);
      calloc.free(_appBarData!);
    }
  }

  Future<void> _registerAppBar() async {
    _shAppBarMessage = DynamicLibrary.open('shell32.dll')
        .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final res = FindWindow(PCWSTR(classNamePtr), PCWSTR(nullptr));
    final hwnd = res.value;
    calloc.free(classNamePtr);

    _appBarData = calloc<_AppBarData>();
    _appBarData!.ref.cbSize = sizeOf<_AppBarData>();
    _appBarData!.ref.hWnd = hwnd.address;
    _appBarData!.ref.uCallbackMessage = _uCallbackMessage;
    _shAppBarMessage(_abmNew, _appBarData!);

    await _reserveCollapsedSpace();
  }

  /// Updates the target heights for collapsed and expanded states.
  Future<void> updateHeights(FontSize fontSize) async {
    if (_fontSize == fontSize) return;
    _fontSize = fontSize;
    await AppLogger.debug(
        "updating hights; isExpanded: $isExpandedNotifier.value");
    if (isExpandedNotifier.value) {
      await _doExpand();
      await AppLogger.debug("updating hights; window expanded");
    } else {
      if (!Platform.isWindows) {
        await _doCollapse();
        await AppLogger.debug("updating hights; window collaposed");
      }
    }
  }

  /// Returns collapsed height in logical pixels (for window_manager APIs).
  double getCollapsedHeight() {
    switch (_fontSize) {
      case FontSize.small:
        return 50.0;
      case FontSize.medium:
        return 55.0;
      case FontSize.large:
        return 60.0;
    }
  }

  /// Returns expanded height in logical pixels (for window_manager APIs).
  double getExpandedHeight() {
    switch (_fontSize) {
      case FontSize.small:
        return 240.0;
      case FontSize.medium:
        return 250.0;
      case FontSize.large:
        return 260.0;
    }
  }

  Future<void> _reserveCollapsedSpace() async {
    _appBarData!.ref.uEdge = _abeTop;
    _appBarData!.ref.rcLeft = 0;
    _appBarData!.ref.rcTop = 0;
    _appBarData!.ref.rcRight = (_screenWidth * _dpr).round();
    final targetHeight = (getCollapsedHeight() * _dpr).round();
    _appBarData!.ref.rcBottom = targetHeight;

    unawaited(AppLogger.debug(
        'WindowService:  reserved targetHeight is $targetHeight'));
    _shAppBarMessage(_abmQuerypos, _appBarData!);
    _shAppBarMessage(_abmSetpos, _appBarData!);

    if (!isExpandedNotifier.value) {
      await _wm.setMinimumSize(Size.zero);
      await _wm.setMaximumSize(Size.infinite);
      await _wm.setBounds(Rect.fromLTWH(
        _appBarData!.ref.rcLeft / _dpr,
        _appBarData!.ref.rcTop / _dpr,
        _screenWidth,
        (_appBarData!.ref.rcBottom - _appBarData!.ref.rcTop) / _dpr,
      ));
    }
  }

  /// Expands the window to show the hover card area.
  Future<void> expand() async {
    unawaited(AppLogger.debug('WindowService: expand requested'));
    await _gate.request(true, _doResize);
  }

  /// Collapses the window back to the strip height.
  Future<void> collapse() async {
    unawaited(AppLogger.debug('WindowService: collapse requested'));
    await _gate.request(false, _doResize);
  }

  Future<void> _doResize(bool wantsExpanded) async {
    if (wantsExpanded) {
      await _doExpand();
    } else {
      await _doCollapse();
    }
  }

  Future<void> _doExpand() async {
    final size = Size(_screenWidth, getExpandedHeight());
    await AppLogger.debug('WindowService: _doExpand() target=${size.height}');
    await _strategy.expand(size, () => isExpandedNotifier.value = true);
  }

  Future<void> _doCollapse() async {
    final size = Size(_screenWidth, getCollapsedHeight());
    await AppLogger.debug('WindowService: _doCollapse() target=${size.height}');
    isExpandedNotifier.value = false;
    await _strategy.collapse(size);
  }
}
