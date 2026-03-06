import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
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

typedef _SHNative = IntPtr Function(
    Uint32 dwMessage, Pointer<_AppBarData> pData);
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

  FontSize _fontSize = FontSize.medium;

  Pointer<_AppBarData>? _appBarData;

  /// Notifier for the window's expansion state.
  final isExpandedNotifier = ValueNotifier<bool>(false);

  double _dpr = 1.0;

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
    final targetHeight = getCollapsedHeight();
    final size = Size(width, targetHeight);

    await AppLogger.debug(
        'WindowService: initial targetHeight is $targetHeight');

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
      await _wm.setAsFrameless();
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

  /// Updates the target heights for collapsed and expanded states.
  /// On Windows, this updates the reserved screen area.
  Future<void> updateHeights(FontSize fontSize) async {
    if (_fontSize == fontSize) return;
    _fontSize = fontSize;
    await AppLogger.debug(
        "updating hights; isExpanded: $isExpandedNotifier.value");
    if (isExpandedNotifier.value) {
      await _doExpand();
      await AppLogger.debug("updating hights; window expanded");
      if (Platform.isWindows && _appBarData != null) {
        // Update OS reservation data even if window is currently expanded
        // await _reserveCollapsedSpace();
      }
    } else {
      if (Platform.isWindows && _appBarData != null) {
        //  await _reserveCollapsedSpace();
      } else {
        await _doCollapse();
        await AppLogger.debug("updating hights; window collaposed");
      }
    }
  }

  double getCollapsedHeight() {
    double baseHeight;
    switch (_fontSize) {
      case FontSize.small:
        baseHeight = 50.0;
      case FontSize.medium:
        baseHeight = 55.0;
      case FontSize.large:
        baseHeight = 60.0;
    }
    return (baseHeight * _dpr).floorToDouble();
  }

  double _getExpandedHeight() {
    switch (_fontSize) {
      case FontSize.small:
        return 240.0 * _dpr.ceilToDouble();
      case FontSize.medium:
        return 250.0 * _dpr.ceilToDouble();
      case FontSize.large:
        return 260.0 * _dpr.ceilToDouble();
    }
  }

  Future<void> _reserveCollapsedSpace() async {
    final display = await _sr.getPrimaryDisplay();
    final width = display.size.width;

    // S5-FIX: Convert logical pixels to physical pixels for the Win32 API.
    _appBarData!.ref.uEdge = _abeTop;
    _appBarData!.ref.rcLeft = 0;
    _appBarData!.ref.rcTop = 0;
    _appBarData!.ref.rcRight = (width * _dpr).round();
    final targetHeight = (getCollapsedHeight() / _dpr).ceil();
    _appBarData!.ref.rcBottom = targetHeight;

    unawaited(AppLogger.debug(
        'WindowService:  reserved targetHeight is $targetHeight'));
    _shAppBarMessage(_abmQuerypos, _appBarData!);
    _shAppBarMessage(_abmSetpos, _appBarData!);

    // S5-FIX: Only apply bounds to the window if we are currently collapsed.
    if (!isExpandedNotifier.value) {
      // Clear constraints that might be left over from expansion so we can shrink.
      await _wm.setMinimumSize(Size.zero);
      await _wm.setMaximumSize(Size.infinite);

      // Convert the physical coordinates returned by Windows back to logical
      // pixels so Flutter stays perfectly in sync with the reserved area.
      await _wm.setBounds(Rect.fromLTWH(
        _appBarData!.ref.rcLeft / _dpr,
        _appBarData!.ref.rcTop / _dpr,
        (_appBarData!.ref.rcRight - _appBarData!.ref.rcLeft) / _dpr,
        (_appBarData!.ref.rcBottom - _appBarData!.ref.rcTop) / _dpr,
      ));
    }
  }

  /// Expands the window to show the hover card area.
  Future<void> expand() async {
    unawaited(AppLogger.debug('WindowService: expanding'));
    await _doExpand();
  }

  /// Collapses the window back to the strip height.
  Future<void> collapse() async {
    unawaited(AppLogger.debug('WindowService: collapsing'));
    await _doCollapse();
  }

  /// GTK/Wayland resize order for expand:
  ///   setSize first  → smooth resize, cursor stays inside, no pointer-leave.
  ///   setMinimumSize → enforcement backup (setResizable=false sometimes ignores setSize).
  ///   setMaximumSize → prevent compositor from shrinking the window.
  Future<void> _doExpand() async {
    isExpandedNotifier.value = true;
    final display = await _sr.getPrimaryDisplay();
    final size = Size(display.size.width, _getExpandedHeight());
    await AppLogger.debug(
        'WindowService: _doExpoand() expanding to (max) height ${size.height}');
    await _wm.setMaximumSize(size);
    await _wm.setSize(size);
    await _wm.setMinimumSize(size);
  }

  /// GTK/Wayland resize order for collapse:
  ///   setMinimumSize first → allow shrink below previous min.
  ///   setMaximumSize       → lock max so compositor can't re-expand.
  ///   setSize last         → resize (constraints already permit it).
  Future<void> _doCollapse() async {
    isExpandedNotifier.value = false;
    final display = await _sr.getPrimaryDisplay();

    // S5-FIX: Match the physical pixel alignment used in _reserveCollapsedSpace.
    double targetHeight = getCollapsedHeight();
    final size = Size(display.size.width, targetHeight);

    await AppLogger.debug(
        'WindowService: _doCollapose collpsed targetHeight is $targetHeight which is ${targetHeight / _dpr} logical pixels at DPR $_dpr');
    if (Platform.isWindows) {
      await _wm.setMinimumSize(size);
      await _wm.setMaximumSize(size);
      await _wm.setSize(size);
    } else {
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 100));

      await _wm.setSize(size);
      await _wm.setMinimumSize(size);
      await _wm.setMaximumSize(size);
    }
  }
}
