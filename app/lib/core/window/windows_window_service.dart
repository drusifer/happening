import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/reserved_window_interaction_strategy.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:logging/logging.dart';
import 'package:win32/win32.dart';

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

/// Windows-specific WindowService with AppBar (work-area reservation) support.
class WindowsWindowService extends WindowService {
  static final _log = Logger('WindowsWindowService');

  WindowsWindowService({
    required super.windowManager,
    required super.screenRetriever,
    bool enableWindowsAppBar = true,
  })  : _enableWindowsAppBar = enableWindowsAppBar,
        super(
          interactionStrategy:
              ReservedWindowInteractionStrategy(wm: windowManager),
        );

  final bool _enableWindowsAppBar;

  Pointer<_AppBarData>? _appBarData;
  late final _SHDart _shAppBarMessage;
  bool _appBarBusy = false;

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  Future<void> beforeShow(Size size, double dpr, WindowMode mode) async {
    if (_enableWindowsAppBar && mode == WindowMode.reserved) {
      await _registerAppBar();
    }
  }

  @override
  void onDispose() => _disposeAppBar();

  @override
  Future<void> onWindowModeChanged(WindowMode mode) async {
    if (!_enableWindowsAppBar) return;
    if (mode == WindowMode.reserved) {
      if (_appBarData == null) {
        await _registerAppBar();
      } else {
        await reassertAppBar();
      }
    } else {
      _disposeAppBar();
    }
  }

  @override
  Future<void> onDisplayChangedExtra() async {
    if (windowMode == WindowMode.reserved && _appBarData != null) {
      await _reserveCollapsedSpace();
      await wm.setPosition(Offset(0, _appBarData!.ref.rcTop / dpr));
    }
  }

  /// Re-registers the AppBar with Windows, restoring the work area reservation.
  ///
  /// Triggers a full ABM_REMOVE → ABM_NEW → ABM_SETPOS cycle, which forces
  /// Windows to re-broadcast the updated work area to all running apps. Call
  /// this when the strip is observed overlapping other window title bars.
  @override
  Future<void> reassertAppBar() async {
    if (windowMode != WindowMode.reserved || _appBarData == null) return;
    _log.fine('WindowsWindowService: reassertAppBar() start');
    await performResize(ExpansionState.collapsed);
    _log.fine('WindowsWindowService: reassertAppBar() collapsed, running ABM cycle');
    _shAppBarMessage(_abmRemove, _appBarData!);
    _shAppBarMessage(_abmNew, _appBarData!);
    await _reserveCollapsedSpace();
    final double rcTop = _appBarData!.ref.rcTop / dpr;
    _log.fine('WindowsWindowService: reassertAppBar() rcTop=$rcTop, repositioning');
    await wm.setPosition(Offset(0, rcTop));
    await performResize(ExpansionState.collapsed);
    _log.fine('WindowsWindowService: reassertAppBar() done');
  }

  // ── AppBar internals ──────────────────────────────────────────────────────

  Future<void> _registerAppBar() async {
    _shAppBarMessage = DynamicLibrary.open('shell32.dll')
        .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final hwnd = FindWindow(PCWSTR(classNamePtr), null);
    calloc.free(classNamePtr);

    _appBarData = calloc<_AppBarData>();
    _appBarData!.ref.cbSize = sizeOf<_AppBarData>();
    _appBarData!.ref.hWnd = hwnd.value.address;
    _appBarData!.ref.uCallbackMessage = _uCallbackMessage;
    _shAppBarMessage(_abmNew, _appBarData!);

    await _reserveCollapsedSpace();
  }

  Future<void> _reserveCollapsedSpace() async {
    if (_appBarBusy) return;
    _appBarBusy = true;
    try {
      _appBarData!.ref.uEdge = _abeTop;
      _appBarData!.ref.rcLeft = 0;
      _appBarData!.ref.rcTop = 0;
      _appBarData!.ref.rcRight = (screenWidth * dpr).round();
      final targetHeight = (getCollapsedHeight() * dpr).round();
      _appBarData!.ref.rcBottom = targetHeight;

      _log.fine('WindowsWindowService: reserved targetHeight is $targetHeight');
      _shAppBarMessage(_abmQuerypos, _appBarData!);
      _shAppBarMessage(_abmSetpos, _appBarData!);

      if (!isExpanded) {
        await wm.setMinimumSize(Size.zero);
        await wm.setMaximumSize(Size.infinite);
        await wm.setBounds(Rect.fromLTWH(
          0,
          _appBarData!.ref.rcTop / dpr,
          screenWidth,
          getCollapsedHeight(),
        ));
      }
    } finally {
      _appBarBusy = false;
    }
  }

  void _disposeAppBar() {
    if (_appBarData != null) {
      _shAppBarMessage(_abmRemove, _appBarData!);
      calloc.free(_appBarData!);
      _appBarData = null;
    }
  }
}
