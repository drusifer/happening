import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
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
    required DisplayService displayService,
    WindowInteractionStrategy? interactionStrategy,
  })  : _wm = windowManager,
        _sr = screenRetriever,
        _displayService = displayService,
        _interactionStrategy = interactionStrategy ??
            WindowInteractionStrategy.create(wm: windowManager),
        _strategy = WindowResizeStrategy.create(
          wm: windowManager,
          sr: screenRetriever,
        );

  final WindowManager _wm;
  final ScreenRetriever _sr;
  final DisplayService _displayService;
  final WindowInteractionStrategy _interactionStrategy;
  final WindowResizeStrategy _strategy;

  double _fontSizePx = kDefaultFontSizePx;
  WindowMode _windowMode = WindowMode.reserved;

  bool _displayChangeInProgress = false;
  bool _isExpanded = false;

  double _dpr = 1.0;
  double _screenWidth = 0;
  DisplayInfo? _activeDisplay;

  // ── Protected accessors for subclasses ────────────────────────────────────

  @protected
  WindowManager get wm => _wm;

  @protected
  double get dpr => _dpr;

  @protected
  double get screenWidth => _screenWidth;

  @protected
  bool get isExpanded => _isExpanded;

  @protected
  DisplayInfo? get activeDisplay => _activeDisplay;

  // ── Public API ────────────────────────────────────────────────────────────

  WindowMode get windowMode => _windowMode;

  Future<void> sendToBack() => _interactionStrategy.sendToBack();

  Future<void> restoreToFront() => _interactionStrategy.restoreToFront();

  Future<void> focus() => _wm.focus();

  /// Force-refreshes window position, size, and platform reservation by
  /// re-reading display state from [DisplayService] — bypasses the no-change
  /// guard in [_onDisplayChangedInner].
  Future<void> reassertAppBar() async {
    _log.info('WindowService.reassertAppBar: force-refreshing display state');
    final newDpr = _wm.getDevicePixelRatio();
    final nextActive = _displayService.activeDisplay;
    if (nextActive == null) return;

    _dpr = newDpr;
    _screenWidth = nextActive.size.width;
    _activeDisplay = nextActive;

    await _strategy.moveToDisplay(nextActive);
    await reRegisterReservation();
    if (_isExpanded) {
      await _doExpand();
    } else {
      await _doCollapse();
    }
  }

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
    final width = await _readActiveDisplayWidth();
    _screenWidth = width;
    final targetHeight = getCollapsedHeight();
    final size = Size(width, targetHeight);

    _log.info(
        'WindowService.initialize: dpr=$_dpr activeDisplay=$_activeDisplay '
        'size=$size collapsedHeight=$targetHeight expandedHeight=${getExpandedHeight()}');

    final windowOptions = WindowOptions(
      size: size,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    _log.info('WindowService.initialize: calling waitUntilReadyToShow');
    final readyToShow = _wm.waitUntilReadyToShow(windowOptions, () async {
      _log.info(
          'WindowService.initialize: readyToShow callback — calling strategy.initialize');
      await _strategy.initialize(size, _dpr);
      if (_activeDisplay != null) {
        _log.info(
            'WindowService.initialize: readyToShow callback — calling strategy.moveToDisplay ${_activeDisplay!.id}');
        await _strategy.moveToDisplay(_activeDisplay!);
      }
      _log.info(
          'WindowService.initialize: readyToShow callback — calling beforeShow');
      await beforeShow(size, _dpr, _windowMode);
      _log.info(
          'WindowService.initialize: readyToShow callback — calling setAsFrameless');
      await _wm.setAsFrameless();
      _log.info(
          'WindowService.initialize: readyToShow callback — calling performShow');
      await performShow();
      _log.info(
          'WindowService.initialize: readyToShow callback — calling afterWindowShown');
      await afterWindowShown(_windowMode);
      _log.info(
          'WindowService.initialize: readyToShow callback — calling interactionStrategy.initialize');
      await _interactionStrategy.initialize(_windowMode);
      _log.info('WindowService.initialize: readyToShow callback — done');
    });

    _log.info('WindowService.initialize: awaiting readyToShow');
    await awaitReadyToShow(readyToShow);
    _log.info(
        'WindowService.initialize: readyToShow complete, calling afterReadyToShow');

    await afterReadyToShow(_windowMode);
    _log.info('WindowService.initialize: afterReadyToShow complete');

    // Register lifecycle observer AFTER initial setup so spurious resumed
    // events emitted during GTK window creation do not queue extra collapses
    // that race with first_frame_cb showing the window.
    _log.info('WindowService.initialize: registering WidgetsBindingObserver');
    WidgetsBinding.instance.addObserver(this);
    _displayService.addListener(_onDisplayServiceChanged);
  }

  void dispose() {
    _displayService.removeListener(_onDisplayServiceChanged);
    WidgetsBinding.instance.removeObserver(this);
    _strategy.dispose();
    onDispose();
  }

  void _onDisplayServiceChanged() {
    unawaited(_onDisplayChanged());
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
  Future<void> beforeShow(Size size, double dpr, WindowMode mode) async {
    return;
  }

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

  /// Called inside the readyToShow callback immediately after [performShow].
  /// Override for setup that requires the window to be visible (e.g. strut).
  @protected
  Future<void> afterWindowShown(WindowMode mode) async {
    return;
  }

  /// Called after readyToShow completes (or is unawaited). Subclasses
  /// override for post-show platform setup (e.g. Linux strut reservation).
  @protected
  Future<void> afterReadyToShow(WindowMode mode) async {
    return;
  }

  /// Called during [dispose] for platform-specific cleanup.
  @protected
  void onDispose() {
    return;
  }

  /// Called when [windowMode] changes. Subclasses override to toggle
  /// platform reservations (AppBar on Windows, strut on Linux).
  @protected
  Future<void> onWindowModeChanged(WindowMode mode) async {
    return;
  }

  /// Called when the display geometry changes, after common state is updated.
  /// Subclasses override to re-assert platform reservations.
  @protected
  Future<void> onDisplayChangedExtra() async {
    return;
  }

  /// Called by [reassertAppBar] to fully cycle the platform reservation
  /// (remove then re-add). Subclasses override; base is a no-op.
  @protected
  Future<void> reRegisterReservation() async {
    return;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _onDisplayChanged() async {
    if (_displayChangeInProgress) {
      _log.info(
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
    final nextActive = _displayService.activeDisplay;
    final newWidth = nextActive?.size.width ?? 0;
    final activeChanged = _activeDisplay != nextActive;
    final previousActiveId = _activeDisplay?.id;
    final nextActiveId = nextActive?.id;

    _log.info('WindowService._onDisplayChangedInner: dpr=$_dpr→$newDpr '
        'width=$_screenWidth→$newWidth activeChanged=$activeChanged '
        '(${previousActiveId ?? "—"}→${nextActiveId ?? "—"}) '
        'isExpanded=$_isExpanded');

    if (newWidth <= 0) {
      _log.info(
          'WindowService._onDisplayChangedInner: invalid width ($newWidth), skipping');
      return;
    }

    if (newDpr == _dpr && newWidth == _screenWidth && !activeChanged) {
      _log.info('WindowService._onDisplayChangedInner: no change, skipping');
      return;
    }

    _log.info(
        'WindowService._onDisplayChangedInner: display CHANGED — applying resize');
    _dpr = newDpr;
    _screenWidth = newWidth;
    _activeDisplay = nextActive;

    if (activeChanged && nextActive != null) {
      _log.info(
          'WindowService._onDisplayChangedInner: moveToDisplay ${nextActive.id} @ ${nextActive.workAreaOrigin}');
      await _strategy.moveToDisplay(nextActive);
    }

    await onDisplayChangedExtra();

    _log.info(
        'WindowService._onDisplayChangedInner: triggering resize isExpanded=$_isExpanded');
    if (_isExpanded) {
      await _doExpand();
    } else {
      await _doCollapse();
    }
  }

  Future<double> _readActiveDisplayWidth() async {
    final active = _displayService.activeDisplay;
    if (active != null) {
      _activeDisplay = active;
      return active.size.width;
    }
    _log.warning(
        'WindowService.initialize: DisplayService.activeDisplay is null; '
        'falling back to screen_retriever.getPrimaryDisplay()');
    final display = await _sr.getPrimaryDisplay();
    return display.size.width;
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
