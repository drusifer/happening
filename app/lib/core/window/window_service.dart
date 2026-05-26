import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/expansion_controller.dart'
    show ExpansionController;
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/resize_strategy/window_resize_strategy.dart';
import 'package:happening/core/window/window_service_resize_executor.dart'
    show WindowServiceResizeExecutor;
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// ── WindowService ────────────────────────────────────────────────────────────
//
// TLDR:
// Overview: Controls physical OS window dimensions via window_manager.
// Problem: Platform-specific resize sequences differ across macOS/Windows/Linux.
// Solution: [WindowResizeStrategy] isolates platform-specific resize sequences;
//           [ExpansionController] serialises expand/collapse and confirms via GTK.
//           Platform-specific window lifecycle hooks are overridden by subclasses
//           (MacOSWindowService, WindowsWindowService, LinuxWindowService).
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

class WindowService with WidgetsBindingObserver {
  static final _log = Logger('WindowService');

  WindowService({
    required WindowManager windowManager,
    required ScreenRetriever screenRetriever,
    WindowInteractionStrategy? interactionStrategy,
  })  : _wm = windowManager,
        _sr = screenRetriever,
        _interactionStrategy = interactionStrategy ??
            WindowInteractionStrategy.create(wm: windowManager),
        _strategy = WindowResizeStrategy.create(
          wm: windowManager,
          sr: screenRetriever,
        );

  final WindowManager _wm;
  final ScreenRetriever _sr;
  final WindowInteractionStrategy _interactionStrategy;
  final WindowResizeStrategy _strategy;

  double _fontSizePx = kDefaultFontSizePx;
  WindowMode _windowMode = WindowMode.reserved;

  bool _displayChangeInProgress = false;
  bool _isExpanded = false;

  double _dpr = 1.0;
  double _screenWidth = 0;

  // ── Protected accessors for subclasses ────────────────────────────────────

  @protected
  WindowManager get wm => _wm;

  @protected
  double get dpr => _dpr;

  @protected
  double get screenWidth => _screenWidth;

  @protected
  bool get isExpanded => _isExpanded;

  // ── Public API ────────────────────────────────────────────────────────────

  WindowMode get windowMode => _windowMode;

  Future<void> sendToBack() => _interactionStrategy.sendToBack();

  Future<void> restoreToFront() => _interactionStrategy.restoreToFront();

  Future<void> focus() => _wm.focus();

  /// Re-registers any platform AppBar reservation.
  /// No-op by default; overridden by WindowsWindowService.
  Future<void> reassertAppBar() async {}

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    double initialFontSizePx = kDefaultFontSizePx,
    WindowMode initialWindowMode = WindowMode.reserved,
  }) async {
    await _wm.ensureInitialized();
    _fontSizePx = initialFontSizePx;
    _windowMode = initialWindowMode;

    final double realDpr = _wm.getDevicePixelRatio();
    _dpr = realDpr;
    final display = await _sr.getPrimaryDisplay();
    final width = display.size.width;
    _screenWidth = width;
    final targetHeight = getCollapsedHeight();
    final size = Size(width, targetHeight);

    _log.fine(
        'WindowService: init dpr=$_dpr displaySize=${display.size} '
        'collapsedHeight=$targetHeight expandedHeight=${getExpandedHeight()}');

    final windowOptions = WindowOptions(
      size: size,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    final readyToShow = _wm.waitUntilReadyToShow(windowOptions, () async {
      await beforeShow(size, _dpr, _windowMode);
      await _strategy.initialize(size, _dpr);
      await _wm.setAsFrameless();
      await performShow();
      await _interactionStrategy.initialize(_windowMode);
    });

    await awaitReadyToShow(readyToShow);

    await afterReadyToShow(_windowMode);

    // Register lifecycle observer AFTER initial setup so spurious resumed
    // events emitted during GTK window creation do not queue extra collapses
    // that race with first_frame_cb showing the window.
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _strategy.dispose();
    onDispose();
  }

  @override
  void didChangeMetrics() {
    unawaited(_onDisplayChanged());
  }

  Future<void> setWindowMode(WindowMode mode) async {
    if (_windowMode == mode) return;
    _windowMode = mode;
    await onWindowModeChanged(mode);
    await _interactionStrategy.initialize(_windowMode);
  }

  Future<void> updateHeights(double fontSizePx) async {
    if (_fontSizePx == fontSizePx) return;
    _fontSizePx = fontSizePx;
    _log.fine(
        'WindowService.updateHeights: fontSizePx=$fontSizePx isExpanded=$_isExpanded');
    if (_isExpanded) {
      await _doExpand();
      _log.fine('WindowService.updateHeights: _doExpand complete');
    } else {
      await _doCollapse();
      _log.fine('WindowService.updateHeights: _doCollapse complete');
    }
  }

  /// Returns collapsed height in logical pixels (for window_manager APIs).
  double getCollapsedHeight() => _fontSizePx * 2.5 + 17.5;

  /// Returns expanded height in logical pixels (for window_manager APIs).
  double getExpandedHeight() => _fontSizePx * 10.0 + 170.0;

  /// Executes the platform resize sequence for [intent].
  ///
  /// Called by [WindowServiceResizeExecutor] on behalf of [ExpansionController].
  Future<void> performResize(ExpansionState intent) async {
    if (intent == ExpansionState.expanded) {
      await _doExpand();
    } else {
      await _doCollapse();
    }
  }

  // ── Virtual hooks ─────────────────────────────────────────────────────────

  /// Called inside the readyToShow callback before [performShow].
  /// Subclasses override for pre-show platform setup (e.g. Windows AppBar).
  @protected
  Future<void> beforeShow(Size size, double dpr, WindowMode mode) async {}

  /// Shows and focuses the window. Subclasses override to change timing
  /// (e.g. macOS defers until after the first rendered frame).
  @protected
  Future<void> performShow() async {
    await _wm.show();
    await _wm.focus();
  }

  /// Controls whether the readyToShow future is awaited before returning
  /// from [initialize]. Default: await (correct for Windows/Linux).
  /// macOS overrides to [unawaited] so [runApp] fires first.
  @protected
  Future<void> awaitReadyToShow(Future<void> f) => f;

  /// Called after readyToShow completes (or is unawaited). Subclasses
  /// override for post-show platform setup (e.g. Linux strut reservation).
  @protected
  Future<void> afterReadyToShow(WindowMode mode) async {}

  /// Called during [dispose] for platform-specific cleanup.
  @protected
  void onDispose() {}

  /// Called when [windowMode] changes. Subclasses override to toggle
  /// platform reservations (AppBar on Windows, strut on Linux).
  @protected
  Future<void> onWindowModeChanged(WindowMode mode) async {}

  /// Called when the display geometry changes, after common state is updated.
  /// Subclasses override to re-assert platform reservations.
  @protected
  Future<void> onDisplayChangedExtra() async {}

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _onDisplayChanged() async {
    if (_displayChangeInProgress) {
      _log.fine(
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

    _log.fine(
        'WindowService._onDisplayChanged: dpr=$_dpr→$newDpr width=$_screenWidth→$newWidth isExpanded=$_isExpanded');

    if (newWidth <= 0) {
      _log.fine(
          'WindowService._onDisplayChanged: invalid width ($newWidth), skipping');
      return;
    }

    if (newDpr == _dpr && newWidth == _screenWidth) {
      _log.fine('WindowService._onDisplayChanged: no change, skipping');
      return;
    }

    _log.fine('WindowService: display CHANGED — applying resize');
    _dpr = newDpr;
    _screenWidth = newWidth;

    await onDisplayChangedExtra();

    _log.fine(
        'WindowService._onDisplayChanged: triggering resize isExpanded=$_isExpanded');
    if (_isExpanded) {
      await _doExpand();
    } else {
      await _doCollapse();
    }
  }

  Future<void> _doExpand() async {
    _isExpanded = true;
    final size = Size(_screenWidth, getExpandedHeight());
    _log.fine(
        'WindowService._doExpand() target=w${size.width}×h${size.height}');
    await _strategy.expand(size);
  }

  Future<void> _doCollapse() async {
    _isExpanded = false;
    final size = Size(_screenWidth, getCollapsedHeight());
    _log.fine(
        'WindowService._doCollapse() target=w${size.width}×h${size.height}');
    await _strategy.collapse(size);
    _log.fine('WindowService._doCollapse() complete');
  }
}
