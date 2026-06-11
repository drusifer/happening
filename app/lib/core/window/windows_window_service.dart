import 'dart:async';
import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/reserved_window_interaction_strategy.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:logging/logging.dart';
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

/// Windows-specific WindowService with AppBar (work-area reservation) support.
class WindowsWindowService extends WindowService with WindowListener {
  static final _log = Logger('WindowsWindowService');

  WindowsWindowService({
    required super.windowManager,
    required super.screenRetriever,
    required super.displayService,
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
  bool _firstShowHandled = false;
  Timer? _safetyNet;

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  Future<void> beforeShow(Size size, double dpr, WindowMode mode) async {
    _log.info(
        'beforeShow: size=$size dpr=$dpr mode=$mode appBarEnabled=$_enableWindowsAppBar');
    if (_enableWindowsAppBar && mode == WindowMode.reserved) {
      // Register listener BEFORE performShow runs so the first onWindowFocus
      // (emitted by wm.focus() inside performShow) is observed.
      wm.addListener(this);
      await _registerAppBar();
    }
    _log.info(
        'beforeShow: done appBarData=${_appBarData != null ? "registered" : "null"}');
  }

  @override
  void onDispose() {
    _safetyNet?.cancel();
    wm.removeListener(this);
    _disposeAppBar();
  }

  @override
  Future<void> onWindowModeChanged(WindowMode mode) async {
    _log.info(
        'onWindowModeChanged: mode=$mode appBarData=${_appBarData != null}');
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
    _log.info('onWindowModeChanged: done');
  }

  // On Windows, size/position set before ShowWindow are ignored during window
  // creation. The post-show fix-up is driven by the first onWindowFocus event
  // (emitted by performShow's wm.focus() call) instead of inline here, because
  // window_manager's waitUntilReadyToShow does not actually await its async
  // callback — so anything we do inline races with the still-pending
  // beforeShow chain (setAsFrameless, performShow). The focus event is the
  // earliest reliable signal that Win32 has actually shown the window.
  @override
  Future<void> afterReadyToShow(WindowMode mode) async {
    _log.info(
        'afterReadyToShow: mode=$mode appBarEnabled=$_enableWindowsAppBar');
    if (!_enableWindowsAppBar || mode != WindowMode.reserved) return;
    // Safety net: if onWindowFocus never fires (focus denied by Windows), run
    // the post-show fix-up anyway after 2s so the strip doesn't stay broken.
    _safetyNet = Timer(const Duration(seconds: 2), () {
      if (_firstShowHandled) return;
      _log.warning(
          'afterReadyToShow: safety-net firing — no onWindowFocus seen');
      unawaited(_handleFirstShow());
    });
  }

  @override
  void onWindowFocus() {
    _log.info('onWindowFocus fired (firstHandled=$_firstShowHandled)');
    if (_firstShowHandled) return;
    unawaited(_handleFirstShow());
  }

  // Post-show fix-up. Uses the same setMin→setMax→setSize pattern that hover
  // uses (via WindowsResizeStrategy.collapse), because that pattern is known
  // to work and setBounds alone does not. setMin/setMax only constrain future
  // resizes — they do NOT actively resize the window — so if setBounds flakes
  // on size or position (which it does on first show), min/max just freeze
  // the broken state. setSize via performResize is what forcibly snaps the
  // window to the target size; setPosition then snaps it to (0, rcTop).
  Future<void> _handleFirstShow() async {
    if (_firstShowHandled) return;
    _firstShowHandled = true;
    _safetyNet?.cancel();
    _safetyNet = null;
    if (_appBarData == null) {
      _log.info('_handleFirstShow: appBarData=null, skipping');
      return;
    }
    _log.info('_handleFirstShow: refreshing AppBar reservation');
    await _reserveCollapsedSpace();
    final rcTop = _appBarData!.ref.rcTop / dpr;
    _log.info('_handleFirstShow: setPosition(0, $rcTop)');
    await wm.setPosition(Offset(0, rcTop));
    _log.info(
        '_handleFirstShow: performResize(collapsed) — forces size via setSize');
    await performResize(ExpansionState.collapsed);
    _log.info('_handleFirstShow: done');
  }

  @override
  Future<void> onHideStrip() async {
    if (!_enableWindowsAppBar) return;
    _disposeAppBar();
  }

  @override
  Future<void> onShowStrip() async {
    if (!_enableWindowsAppBar) return;
    if (windowMode == WindowMode.reserved) {
      await _registerAppBar();
    }
  }

  @override
  Future<void> onDisplayChangedExtra() async {
    _log.info(
        'onDisplayChangedExtra: windowMode=$windowMode appBarData=${_appBarData != null}');
    if (windowMode == WindowMode.reserved && _appBarData != null) {
      await _reserveCollapsedSpace();
      final double xOffset = activeDisplay?.workAreaOrigin.dx ?? 0;
      final pos = Offset(xOffset, _appBarData!.ref.rcTop / dpr);
      _log.info(
          'onDisplayChangedExtra: setPosition $pos (rcTop=${_appBarData!.ref.rcTop} dpr=$dpr)');
      await wm.setPosition(pos);
    }
    _log.info('onDisplayChangedExtra: done');
  }

  /// Re-registers the AppBar with Windows, restoring the work area reservation.
  ///
  /// Triggers a full ABM_REMOVE → ABM_NEW → ABM_SETPOS cycle, which forces
  /// Windows to re-broadcast the updated work area to all running apps. Call
  /// this when the strip is observed overlapping other window title bars.
  @override
  Future<void> reassertAppBar() async {
    if (windowMode != WindowMode.reserved || _appBarData == null) {
      await super.reassertAppBar();
      return;
    }
    _log.info('reassertAppBar: start');
    await performResize(ExpansionState.collapsed);
    _log.info(
        'reassertAppBar: collapsed, running ABM_REMOVE → ABM_NEW → ABM_SETPOS cycle');
    _shAppBarMessage(_abmRemove, _appBarData!);
    _shAppBarMessage(_abmNew, _appBarData!);
    await _reserveCollapsedSpace();
    final double rcTop = _appBarData!.ref.rcTop / dpr;
    _log.info(
        'reassertAppBar: rcTop=$rcTop (raw=${_appBarData!.ref.rcTop} dpr=$dpr), repositioning');
    final double xOffset = activeDisplay?.workAreaOrigin.dx ?? 0;
    await wm.setPosition(Offset(xOffset, rcTop));
    await performResize(ExpansionState.collapsed);
    _log.info('reassertAppBar: done');
  }

  // ── AppBar internals ──────────────────────────────────────────────────────

  Future<void> _registerAppBar() async {
    _log.info('_registerAppBar: loading SHAppBarMessage from shell32.dll');
    _shAppBarMessage = DynamicLibrary.open('shell32.dll')
        .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final hwnd = FindWindow(PCWSTR(classNamePtr), null);
    calloc.free(classNamePtr);
    _log.info(
        '_registerAppBar: FindWindow hwnd=0x${hwnd.value.address.toRadixString(16)}');

    _appBarData = calloc<_AppBarData>();
    _appBarData!.ref.cbSize = sizeOf<_AppBarData>();
    _appBarData!.ref.hWnd = hwnd.value.address;
    _appBarData!.ref.uCallbackMessage = _uCallbackMessage;
    _log.info(
        '_registerAppBar: calling ABM_NEW cbSize=${_appBarData!.ref.cbSize} hWnd=0x${_appBarData!.ref.hWnd.toRadixString(16)}');
    _shAppBarMessage(_abmNew, _appBarData!);
    _log.info('_registerAppBar: ABM_NEW done, calling _reserveCollapsedSpace');

    await _reserveCollapsedSpace();
    _log.info('_registerAppBar: done');
  }

  Future<void> _reserveCollapsedSpace() async {
    _log.info(
        '_reserveCollapsedSpace: entry appBarBusy=$_appBarBusy isExpanded=$isExpanded screenWidth=$screenWidth dpr=$dpr collapsedHeight=${getCollapsedHeight()}');
    if (_appBarBusy) {
      _log.info('_reserveCollapsedSpace: SKIPPED (appBarBusy)');
      return;
    }
    _appBarBusy = true;
    try {
      _appBarData!.ref.uEdge = _abeTop;
      _appBarData!.ref.rcLeft = 0;
      _appBarData!.ref.rcTop = 0;
      _appBarData!.ref.rcRight = (screenWidth * dpr).round();
      final targetHeight = (getCollapsedHeight() * dpr).round();
      _appBarData!.ref.rcBottom = targetHeight;

      _log.info(
          '_reserveCollapsedSpace: before ABM_QUERYPOS rect=[${_appBarData!.ref.rcLeft},${_appBarData!.ref.rcTop},${_appBarData!.ref.rcRight},${_appBarData!.ref.rcBottom}] targetHeightPx=$targetHeight');
      _shAppBarMessage(_abmQuerypos, _appBarData!);
      _log.info(
          '_reserveCollapsedSpace: after  ABM_QUERYPOS rect=[${_appBarData!.ref.rcLeft},${_appBarData!.ref.rcTop},${_appBarData!.ref.rcRight},${_appBarData!.ref.rcBottom}]');
      _shAppBarMessage(_abmSetpos, _appBarData!);
      _log.info(
          '_reserveCollapsedSpace: after  ABM_SETPOS  rect=[${_appBarData!.ref.rcLeft},${_appBarData!.ref.rcTop},${_appBarData!.ref.rcRight},${_appBarData!.ref.rcBottom}]');

      if (!isExpanded) {
        final bounds = Rect.fromLTWH(
          0,
          _appBarData!.ref.rcTop / dpr,
          screenWidth,
          getCollapsedHeight(),
        );
        _log.info(
            '_reserveCollapsedSpace: setBounds $bounds (rcTop=${_appBarData!.ref.rcTop} dpr=$dpr)');
        await wm.setMinimumSize(Size.zero);
        await wm.setMaximumSize(Size.infinite);
        await wm.setBounds(bounds);
        _log.info('_reserveCollapsedSpace: setBounds done');
      } else {
        _log.info(
            '_reserveCollapsedSpace: skipping setBounds (isExpanded=true)');
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
