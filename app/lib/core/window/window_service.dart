import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:happening/core/util/logger.dart';

// Window configuration and lifecycle service.
//
// TLDR:
/// Overview: Sets up the frameless, always-on-top strip at the screen top.
/// Problem: Need to ensure the window spans the primary display and stays on top across platforms.
/// Solution: Uses window_manager and screen_retriever with DPR-aware logical sizing.
///           Resize approach: window starts at strip height, expands to 250px on hover.
///           Race fix: single setSize() call (no setMin/setMax during resize).
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

/// Configures the app window as an always-on-top frameless strip.
class WindowService {
  WindowService({
    WindowManager? windowManager,
    ScreenRetriever? screenRetriever,
  })  : _wm = windowManager ?? WindowManager.instance,
        _sr = screenRetriever ?? ScreenRetriever.instance;

  final WindowManager _wm;
  final ScreenRetriever _sr;

  double _lastWidth = 1920.0;
  double _lastHeight = 0.0;
  double _expandedHeight = 0.0;

  // Desired expand state. Only one resize is ever in flight at a time;
  // if the desired state changes mid-flight the new state is applied after
  // the current resize completes (see _enqueueResize).
  bool _wantsExpanded = false;
  Future<void>? _inFlight;

  /// Whether the window is currently in the expanded state.
  bool get isExpanded => _wantsExpanded;

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    double height = 30.0,
    double expandedHeight = 250.0,
  }) async {
    await _wm.ensureInitialized();
    _lastHeight = height;
    _expandedHeight = expandedHeight;

    final display = await _sr.getPrimaryDisplay();
    final dpr = display.scaleFactor?.toDouble() ?? 1.0;

    // window_manager on Linux (GTK) takes logical pixels; GTK applies the
    // system scale factor itself. Use logical units directly.
    _lastWidth = (display.visibleSize?.width ?? 1920.0) / dpr;
    final size = Size(_lastWidth, _lastHeight);

    await _wm.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: Size(_lastWidth, _lastHeight),
        maximumSize: Size(_lastWidth, _expandedHeight),
        backgroundColor: const Color(0x00000000), // Transparent
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
      ),
      () async {
        await _wm.setAsFrameless();
        await _wm.setBackgroundColor(const Color(0x00000000));
        await _wm.setResizable(false);
        await _wm.setMinimumSize(size);
        await _wm.setMaximumSize(Size(_lastWidth, _expandedHeight));
        await _wm.show();
        await _wm.setSize(size);
        await _wm.setPosition(Offset.zero);
        await _wm.setAlwaysOnTop(true);
      },
    );
  }

  /// Expands the window to show the hover card area.
  /// Idempotent: multiple calls while already expanded are no-ops.
  /// Serialized: if a collapse is in flight the expand runs after it completes.
  Future<void> expand({double? height}) async {
    if (height != null) _expandedHeight = height;
    unawaited(AppLogger.debug('WindowService: expanding to  $height, $_expandedHeight'));
    _wantsExpanded = true;
    //await _enqueueResize();
    _doExpand();
  }

  /// Collapses the window back to the strip height.
  /// Idempotent and serialized — see [expand].
  Future<void> collapse({double? height}) async {
    if (height != null) _lastHeight = height;
    _wantsExpanded = false;
    unawaited(AppLogger.debug('WindowService: collapsing to  $height, $_lastHeight'));
    _doCollapse();

    //await _enqueueResize();
  }

  /// Ensures at most one resize is in flight at a time.
  ///
  /// If called while a resize is already running, updates [_wantsExpanded] and
  /// returns immediately — the running resize will re-check and apply the new
  /// state when it finishes.
  Future<void> _enqueueResize() async {
    if (_inFlight != null) return;
    bool want;
    do {
      want = _wantsExpanded;
      _inFlight = want ? _doExpand() : _doCollapse();
      try {
        await _inFlight;
      } finally {
        // Always clear _inFlight — if a platform call throws, leaving it
        // non-null permanently blocks all future collapse/expand calls.
        _inFlight = null;
      }
    } while (_wantsExpanded != want);
  }

  /// GTK/Wayland resize order for expand:
  ///   setSize first  → smooth resize, cursor stays inside, no pointer-leave.
  ///   setMinimumSize → enforcement backup (setResizable=false sometimes ignores setSize).
  ///   setMaximumSize → prevent compositor from shrinking the window.
  Future<void> _doExpand() async {
    final size = Size(_lastWidth, _expandedHeight);
    await _wm.setSize(size);
    await _wm.setMinimumSize(size);
    await _wm.setMaximumSize(size);
  }

  /// GTK/Wayland resize order for collapse:
  ///   setMinimumSize first → allow shrink below previous min.
  ///   setMaximumSize       → lock max so compositor can't re-expand.
  ///   setSize last         → resize (constraints already permit it).
  Future<void> _doCollapse() async {
    final size = Size(_lastWidth, _lastHeight);
    await _wm.setMinimumSize(size);
    await _wm.setMaximumSize(size);
    await _wm.setSize(size);
  }
}
