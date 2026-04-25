import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/util/async_gate.dart';
import 'package:happening/core/util/logger.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
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

class WindowService with WidgetsBindingObserver {
  WindowService({
    required WindowManager windowManager,
    required ScreenRetriever screenRetriever,
    bool? supportsTransparentPassThroughForTesting,
    TargetPlatform? platformOverride,
    bool enableWindowsAppBar = true,
    WindowInteractionStrategy? interactionStrategy,
  })  : _wm = windowManager,
        _sr = screenRetriever,
        _platformOverride = platformOverride,
        _enableWindowsAppBar = enableWindowsAppBar,
        _interactionStrategy = interactionStrategy ??
            WindowInteractionStrategy.create(
              wm: windowManager,
              supportsTransparentPassThrough:
                  supportsTransparentPassThroughForTesting ?? !Platform.isLinux,
              platformOverride: platformOverride,
            ),
        _strategy = WindowResizeStrategy.create(
          wm: windowManager,
          sr: screenRetriever,
        );

  final WindowManager _wm;
  final ScreenRetriever _sr;
  final TargetPlatform? _platformOverride;
  final bool _enableWindowsAppBar;
  final WindowInteractionStrategy _interactionStrategy;
  final WindowResizeStrategy _strategy;
  final _gate = AsyncGate<bool>();

  FontSize _fontSize = FontSize.medium;
  WindowMode _windowMode = WindowMode.reserved;

  Pointer<_AppBarData>? _appBarData;
  late final _SHDart _shAppBarMessage;
  bool _appBarBusy =
      false; // guards against concurrent _reserveCollapsedSpace calls
  bool _displayChangeInProgress = false; // serialises _onDisplayChanged calls

  /// Notifier for the window's expansion state.
  final isExpandedNotifier = ValueNotifier<bool>(false);

  double _dpr = 1.0;
  double _screenWidth = 0;

  bool get _isWindows =>
      _platformOverride == TargetPlatform.windows ||
      (_platformOverride == null && Platform.isWindows);

  bool get _isLinux =>
      _platformOverride == TargetPlatform.linux ||
      (_platformOverride == null && Platform.isLinux);

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    FontSize initialFontSize = FontSize.medium,
    WindowMode initialWindowMode = WindowMode.reserved,
  }) async {
    await _wm.ensureInitialized();
    _fontSize = initialFontSize;
    _windowMode = initialWindowMode;

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

    WidgetsBinding.instance.addObserver(this);

    await _wm.waitUntilReadyToShow(windowOptions, () async {
      if (_isWindows &&
          _enableWindowsAppBar &&
          _windowMode == WindowMode.reserved) {
        await _registerAppBar();
      }
      await _strategy.initialize(size, _dpr);
      await _wm.setAsFrameless();
      await _wm.show();
      await _wm.focus();
      await _interactionStrategy.initialize(_windowMode);
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _strategy.dispose();
    _disposeAppBar();
  }

  @override
  void didChangeMetrics() {
    unawaited(_onDisplayChanged());
  }

  /// Re-asserts the window size after the app resumes from background/sleep.
  ///
  /// On Linux, waking from sleep or DPMS display-off can leave the window at
  /// a corrupt size (e.g., 0px wide from a transient zero-width display event).
  /// Re-applying the correct size on resume ensures the strip is always visible.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AppLogger.debug(
          'WindowService.didChangeAppLifecycleState: resumed — re-asserting window size'));
      if (isExpandedNotifier.value) {
        unawaited(_doExpand());
      } else {
        unawaited(_doCollapse());
      }
    }
  }

  /// Whether this platform should expose transparent click-through mode.
  ///
  /// Phase A deliberately keeps Linux unavailable: an earlier real-session
  /// attempt produced an unusable black bar, and current reliable behavior is
  /// only established for macOS/Windows.
  Future<bool> supportsTransparentPassThrough() async {
    return _interactionStrategy.availability.supportsTransparent;
  }

  WindowMode get windowMode => _windowMode;

  /// Enables or disables whole-window click-through behavior.
  ///
  /// Uses `forward: true` so supported native platforms pass ignored mouse
  /// events to whatever is behind the strip instead of swallowing them.
  Future<void> setPassThroughEnabled(bool enabled) async {
    if (!_interactionStrategy.availability.supportsTransparent) {
      await AppLogger.debug(
          'WindowService.setPassThroughEnabled($enabled): unsupported platform');
      return;
    }
    await _interactionStrategy.setPassThrough(enabled);
  }

  Future<void> setInteractionFocused(bool focused) async {
    await _interactionStrategy.setFocused(focused);
  }

  Future<void> setWindowMode(WindowMode mode) async {
    if (_windowMode == mode) return;
    _windowMode = mode;

    if (_isWindows && _enableWindowsAppBar) {
      if (_windowMode == WindowMode.reserved) {
        if (_appBarData == null) {
          await _registerAppBar();
        } else {
          await reassertAppBar();
        }
      } else {
        _disposeAppBar();
      }
    }

    await _interactionStrategy.initialize(_windowMode);
  }

  Future<void> _onDisplayChanged() async {
    // Serialise: drop concurrent calls fired by GTK spurious didChangeMetrics.
    if (_displayChangeInProgress) {
      await AppLogger.debug(
          'WindowService._onDisplayChanged: already in progress, skipping');
      return;
    }
    _displayChangeInProgress = true;
    try {
      await _onDisplayChangedInner();
    } finally {
      _displayChangeInProgress = false;
    }
  }

  Future<void> _onDisplayChangedInner() async {
    final newDpr = _wm.getDevicePixelRatio();
    final display = await _sr.getPrimaryDisplay();
    final newWidth = display.size.width;

    // [DBG] Log every didChangeMetrics call to detect spurious Linux firings.
    await AppLogger.debug(
        'WindowService._onDisplayChanged: dpr=$_dpr→$newDpr width=$_screenWidth→$newWidth isExpanded=${isExpandedNotifier.value}');

    // Guard against transient zero-width from DPMS wake / display reinit.
    // If width is 0 we must not update _screenWidth or resize, as that would
    // collapse the window to 0px and make all UI invisible.
    if (newWidth <= 0) {
      await AppLogger.debug(
          'WindowService._onDisplayChanged: invalid width ($newWidth), skipping');
      return;
    }

    if (newDpr == _dpr && newWidth == _screenWidth) {
      await AppLogger.debug(
          'WindowService._onDisplayChanged: no change, skipping');
      return;
    }

    await AppLogger.debug('WindowService: display CHANGED — applying resize');
    _dpr = newDpr;
    _screenWidth = newWidth;

    if (_isWindows &&
        _windowMode == WindowMode.reserved &&
        _appBarData != null) {
      // Re-assert AppBar band with updated physical-pixel values.
      await _reserveCollapsedSpace();
      // Re-anchor window position — display change can nudge the window.
      // rcTop is trusted post-SETPOS for ABE_TOP.
      await _wm.setPosition(Offset(0, _appBarData!.ref.rcTop / _dpr));
    }

    // Resize window to match new display dimensions via the strategy.
    // _reserveCollapsedSpace alone is not sufficient — setBounds is unreliable.
    await AppLogger.debug(
        'WindowService._onDisplayChanged: triggering resize isExpanded=${isExpandedNotifier.value}');
    if (isExpandedNotifier.value) {
      await _doExpand();
    } else {
      await _doCollapse();
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

  /// Re-registers the AppBar with Windows, restoring the work area reservation.
  ///
  /// Triggers a full ABM_REMOVE → ABM_NEW → ABM_SETPOS cycle, which forces
  /// Windows to re-broadcast the updated work area to all running apps. Call
  /// this when the strip is observed overlapping other window title bars.
  /// No-op on non-Windows platforms.
  Future<void> reassertAppBar() async {
    if (!_isWindows ||
        _windowMode != WindowMode.reserved ||
        _appBarData == null) {
      return;
    }
    unawaited(AppLogger.debug('WindowService: reassertAppBar() start'));
    // Collapse first — the AppBar band equals the collapsed window height (55px).
    // Running ABM_REMOVE/NEW/SETPOS while expanded (250px) causes Windows to
    // push the window below the reserved band. Collapse before touching the
    // AppBar registration so the window fits inside the band during negotiation.
    await _doCollapse();
    unawaited(AppLogger.debug(
        'WindowService: reassertAppBar() collapsed, running ABM cycle'));
    _shAppBarMessage(_abmRemove, _appBarData!);
    _shAppBarMessage(_abmNew, _appBarData!);
    await _reserveCollapsedSpace();
    // rcTop is trusted post-SETPOS for ABE_TOP. Force window back into the
    // band in case Windows nudged it during work-area contraction.
    final double rcTop = _appBarData!.ref.rcTop / _dpr;
    unawaited(AppLogger.debug(
        'WindowService: reassertAppBar() rcTop=$rcTop, repositioning'));
    await _wm.setPosition(Offset(0, rcTop));
    await _doCollapse();
    unawaited(AppLogger.debug('WindowService: reassertAppBar() done'));
  }

  /// Updates the target heights for collapsed and expanded states.
  Future<void> updateHeights(FontSize fontSize) async {
    if (_fontSize == fontSize) return;
    _fontSize = fontSize;
    await AppLogger.debug(
        'WindowService.updateHeights: fontSize=$fontSize isExpanded=${isExpandedNotifier.value}');
    if (isExpandedNotifier.value) {
      await _doExpand();
      await AppLogger.debug('WindowService.updateHeights: _doExpand complete');
    } else {
      if (!_isWindows) {
        // NOTE: calls _doCollapse() directly, bypassing _gate — concurrent with
        // gated collapse() calls from TimelineStrip.initState(). [DBG WATCH]
        await AppLogger.debug(
            'WindowService.updateHeights: calling _doCollapse (bypass gate)');
        await _doCollapse();
        await AppLogger.debug(
            'WindowService.updateHeights: _doCollapse complete');
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
    if (_appBarBusy) return;
    _appBarBusy = true;
    try {
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
        // rcLeft and rcBottom are mutated by ABM_SETPOS — use stored values instead.
        // Only rcTop is trusted for ABE_TOP (Windows does not mutate it).
        await _wm.setBounds(Rect.fromLTWH(
          0,
          _appBarData!.ref.rcTop / _dpr,
          _screenWidth,
          getCollapsedHeight(),
        ));
      }
    } finally {
      _appBarBusy = false;
    }
  }

  void _disposeAppBar() {
    if (_isWindows && _appBarData != null) {
      _shAppBarMessage(_abmRemove, _appBarData!);
      calloc.free(_appBarData!);
      _appBarData = null;
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
    await AppLogger.debug(
        'WindowService._doExpand() target=w${size.width}×h${size.height} isExpanded=${isExpandedNotifier.value}');
    await _strategy.expand(size, () {
      isExpandedNotifier.value = true;
      unawaited(AppLogger.debug('WindowService._doExpand() onExpanded fired'));
    });
  }

  Future<void> _doCollapse() async {
    final size = Size(_screenWidth, getCollapsedHeight());
    await AppLogger.debug(
        'WindowService._doCollapse() target=w${size.width}×h${size.height} isExpanded=${isExpandedNotifier.value}');
    isExpandedNotifier.value = false;
    await _strategy.collapse(size);
    await AppLogger.debug('WindowService._doCollapse() complete');
  }
}
