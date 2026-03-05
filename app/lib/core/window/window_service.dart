import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/util/logger.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:win32/win32.dart' hide Size;
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

typedef _SHNative = IntPtr Function(Uint32 dwMessage, Pointer<_AppBarData> pData);
typedef _SHDart = int Function(int dwMessage, Pointer<_AppBarData> pData);

final _shAppBarMessage = DynamicLibrary.open('shell32.dll')
    .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');

/// Window management service for resizing the app between strip and hover states.
///
/// TLDR:
/// Overview: Controls physical OS window dimensions via [window_manager].
/// Problem: High-frequency resizing causes OS flickering and race conditions.
/// Solution: Direct calls without state guards. The UI handles gating.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

class WindowService {
  WindowService({
    required WindowManager windowManager,
    required ScreenRetriever screenRetriever,
  })  : _wm = windowManager,
        _sr = screenRetriever;

  final WindowManager _wm;
  final ScreenRetriever _sr;

  double _lastWidth = 1920.0;
  double _lastHeight = 0.0;
  double _expandedHeight = 0.0;

  Pointer<_AppBarData>? _appBarData;

  /// Notifier for the window's expansion state.
  final isExpandedNotifier = ValueNotifier<bool>(false);

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    double height = 30.0,
    double expandedHeight = 250.0,
  }) async {
    await _wm.ensureInitialized();
    _lastHeight = height;
    _expandedHeight = expandedHeight;

    final display = await _sr.getPrimaryDisplay();
    _lastWidth = display.size.width;
    final size = Size(_lastWidth, height);

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
      } else {
        await _wm.setPosition(Offset.zero);
      }
      await _wm.setResizable(false);
      await _wm.show();
      await _wm.focus();
    });
  }

  void dispose() {
    if (Platform.isWindows && _appBarData != null) {
      _shAppBarMessage(_abmRemove, _appBarData!);
      calloc.free(_appBarData!);
    }
  }

  Future<void> _registerAppBar() async {
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final hwnd = FindWindow(classNamePtr, nullptr);
    calloc.free(classNamePtr);

    _appBarData = calloc<_AppBarData>();
    _appBarData!.ref.cbSize = sizeOf<_AppBarData>();
    _appBarData!.ref.hWnd = hwnd;
    _appBarData!.ref.uCallbackMessage = _uCallbackMessage;
    _shAppBarMessage(_abmNew, _appBarData!);

    await _reserveCollapsedSpace();
  }

  Future<void> _reserveCollapsedSpace() async {
    final display = await _sr.getPrimaryDisplay();
    _appBarData!.ref.uEdge = _abeTop;
    _appBarData!.ref.rcLeft = 0;
    _appBarData!.ref.rcTop = 0;
    _appBarData!.ref.rcRight = display.size.width.toInt();
    _appBarData!.ref.rcBottom = _lastHeight.toInt();
    _shAppBarMessage(_abmQuerypos, _appBarData!);
    _shAppBarMessage(_abmSetpos, _appBarData!);
    await _wm.setPosition(Offset(
      _appBarData!.ref.rcLeft.toDouble(),
      _appBarData!.ref.rcTop.toDouble(),
    ));
  }

  /// Expands the window to show the hover card area.
  Future<void> expand({double? height}) async {
    if (height != null) _expandedHeight = height;
    unawaited(AppLogger.debug('WindowService: expanding to $_expandedHeight'));
    isExpandedNotifier.value = true;
    await _doExpand();
  }

  /// Collapses the window back to the strip height.
  Future<void> collapse({double? height}) async {
    if (height != null) _lastHeight = height;
    unawaited(AppLogger.debug('WindowService: collapsing to $_lastHeight'));
    isExpandedNotifier.value = false;
    await _doCollapse();
  }

  /// GTK/Wayland resize order for expand:
  ///   setSize first  → smooth resize, cursor stays inside, no pointer-leave.
  ///   setMinimumSize → enforcement backup (setResizable=false sometimes ignores setSize).
  ///   setMaximumSize → prevent compositor from shrinking the window.
  Future<void> _doExpand() async {
    final size = Size(_lastWidth, _expandedHeight);
    if (Platform.isWindows) {
      await _wm.setMaximumSize(size);
      await _wm.setSize(size);
      await _wm.setMinimumSize(size);
    } else {
      await _wm.setSize(size);
      await _wm.setMinimumSize(size);
      await _wm.setMaximumSize(size);
    }
  }

  /// GTK/Wayland resize order for collapse:
  ///   setMinimumSize first → allow shrink below previous min.
  ///   setMaximumSize       → lock max so compositor can't re-expand.
  ///   setSize last         → resize (constraints already permit it).
  Future<void> _doCollapse() async {
    final size = Size(_lastWidth, _lastHeight);
    if (Platform.isWindows) {
      await _wm.setMinimumSize(size);
      await _wm.setMaximumSize(size);
      await _wm.setSize(size);
    } else {
      await _wm.setMinimumSize(size);
      await _wm.setMaximumSize(size);
      await _wm.setSize(size);
    }
  }
}
