import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/expansion_controller.dart'
    show ExpansionController;
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/resize_strategy/window_resize_strategy.dart';
import 'package:happening/core/window/strip_state.dart';
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

  /// The platform resize strategy. Exposed to platform subclasses so they can
  /// route their own resizes (e.g. the Windows AppBar reservation) through the
  /// single [WindowResizeStrategy.applySize] implementation.
  @protected
  WindowResizeStrategy get strategy => _strategy;

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
    _log.fine('WindowService.reassertAppBar: force-refreshing display state');
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

    _log.fine(
        'WindowService.initialize: dpr=$_dpr activeDisplay=$_activeDisplay '
        'size=$size collapsedHeight=$targetHeight expandedHeight=${getExpandedHeight()}');

    final windowOptions = WindowOptions(
      size: size,
      alwaysOnTop: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    _log.fine('WindowService.initialize: calling waitUntilReadyToShow');
    final readyToShow = _wm.waitUntilReadyToShow(windowOptions, () async {
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling strategy.initialize');
      await _strategy.initialize(size, _dpr);
      if (_activeDisplay != null) {
        _log.fine(
            'WindowService.initialize: readyToShow callback — calling strategy.moveToDisplay ${_activeDisplay!.id}');
        await _strategy.moveToDisplay(_activeDisplay!);
      }
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling beforeShow');
      await beforeShow(size, _dpr, _windowMode);
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling setAsFrameless');
      await _wm.setAsFrameless();
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling performShow');
      await performShow();
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling afterWindowShown');
      await afterWindowShown(_windowMode);
      _log.fine(
          'WindowService.initialize: readyToShow callback — calling interactionStrategy.initialize');
      await _interactionStrategy.initialize(_windowMode);
      _log.fine('WindowService.initialize: readyToShow callback — done');
    });

    _log.fine('WindowService.initialize: awaiting readyToShow');
    await awaitReadyToShow(readyToShow);
    _log.fine(
        'WindowService.initialize: readyToShow complete, calling afterReadyToShow');

    await afterReadyToShow(_windowMode);
    _log.fine('WindowService.initialize: afterReadyToShow complete');

    // Register lifecycle observer AFTER initial setup so spurious resumed
    // events emitted during GTK window creation do not queue extra collapses
    // that race with first_frame_cb showing the window.
    _log.fine('WindowService.initialize: registering WidgetsBindingObserver');
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
    // Converged onto the proven applier — the same reserve→size-at-reserved-origin
    // path init/show/hide use. Unlike the old _doExpand/_doCollapse (resize in
    // place, NO reposition), applyState re-pins the strip to the reserved band
    // origin every time, so an expand/collapse cannot strand it below the strut.
    await applyState(intent == ExpansionState.expanded
        ? StripState.expandedShown
        : StripState.collapsedShown);
  }

  /// The single applier: maps a [StripState] to geometry + platform
  /// reservation, idempotently. Geometry is a pure function of state
  /// ([_sizeFor]); positioning rides the same [WindowResizeStrategy.applySize]
  /// seam every other resize uses. [applyReservation] is the platform hook
  /// (AppBar on Windows, strut on Linux, no-op on macOS).
  ///
  /// Serialised by the caller (`StripController`'s `AsyncGate`); do not call
  /// from multiple unsynchronised paths.
  Future<void> applyState(StripState state) async {
    final size = _sizeFor(state);
    // Keep the legacy expansion flag in sync while callers migrate onto
    // StripState; reservation logic still reads isExpanded.
    _isExpanded = state.isExpanded;
    // Reserve FIRST, then place the window. On Windows ABM_SETPOS can move the
    // AppBar window and reports the reserved band top, so geometry must be
    // applied AFTER reservation, at the origin it returns — otherwise the strip
    // lands below its own strut.
    final reservedOrigin = await applyReservation(state);
    final origin =
        reservedOrigin ?? _activeDisplay?.workAreaOrigin ?? Offset.zero;
    _log.fine('applyState: $state → size=$size origin=$origin '
        '(reserved=$reservedOrigin)');
    await _strategy.applySize(size, position: origin);
    await logGeometry('applyState:$state');
    probeGeometryLater('applyState:$state');
  }

  /// Logs the window's actual position + size. Diagnostic instrumentation;
  /// failures are swallowed so it is safe under test mocks.
  @protected
  Future<void> logGeometry(String label) async {
    try {
      final pos = await _wm.getPosition();
      final size = await _wm.getSize();
      _log.fine('GEO[$label]: pos=$pos size=$size '
          'workAreaOrigin=${_activeDisplay?.workAreaOrigin} dpr=$_dpr');
    } catch (e) {
      _log.warning('GEO[$label]: failed: $e');
    }
  }

  /// Samples the window geometry AFTER a delay, to catch an async OS relocation
  /// that the synchronous [logGeometry] (taken right after we set position)
  /// cannot see — e.g. Windows drifting the AppBar window a beat after we
  /// return. Diagnostic only. Disabled under `flutter test` so it leaves no
  /// pending timers.
  @protected
  void probeGeometryLater(String label) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    for (final ms in const [150, 500, 1200]) {
      Future.delayed(
        Duration(milliseconds: ms),
        () => unawaited(logGeometry('$label +${ms}ms')),
      );
    }
  }

  /// Geometry for [state] in logical pixels. Width is the full screen for the
  /// shown states and the mini-pill footprint when hidden; height tracks the
  /// collapsed/expanded font-derived heights.
  Size _sizeFor(StripState state) {
    switch (state) {
      case StripState.collapsedShown:
        return Size(_screenWidth, getCollapsedHeight());
      case StripState.expandedShown:
        return Size(_screenWidth, getExpandedHeight());
      case StripState.hidden:
        return Size(getMiniWidth(_fontSizePx), getCollapsedHeight());
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

  /// Platform reservation hook invoked by [applyState] BEFORE geometry is
  /// applied. Shown states reserve/reassert work area (Windows AppBar, Linux
  /// strut); [StripState.hidden] releases it. Returns the origin the window
  /// should be placed at (e.g. the reserved band top), or null to use the
  /// work-area origin. Base is a no-op returning null (macOS).
  ///
  /// Named (not `_`-prefixed) so subclasses in other library files can
  /// override it — Dart private members are library-scoped.
  @protected
  Future<Offset?> applyReservation(StripState state) async => null;

  /// Forces a single OS-level present of the current window contents, with no
  /// geometry change. The last init step, to composite the first frame on
  /// platforms whose compositor does not present a frameless/reserved window
  /// until a window message pumps (Windows). Base is a no-op.
  @protected
  Future<void> presentInitialFrame() async {
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

  /// Called before the hide animation starts. Subclasses override to release
  /// platform reservations (strut on Linux, AppBar on Windows).
  @protected
  Future<void> onHideStrip() async {
    return;
  }

  /// Called after the show animation completes. Subclasses override to
  /// re-acquire platform reservations.
  @protected
  Future<void> onShowStrip() async {
    return;
  }

  // ── Public hide/show API (called by _TimelineStripState) ─────────────────

  /// Returns the mini strip width in logical pixels for the given font size.
  double getMiniWidth(double fontSizePx) =>
      fontSizePx * 9.0 + 12.0 + 8.0 + 24.0 + 16.0 + 10.0;

  /// Releases platform reservation before the hide animation.
  Future<void> prepareToHide() => onHideStrip();

  /// Re-acquires platform reservation after the show animation completes.
  Future<void> completeShow() => onShowStrip();

  /// Restores the strip from hidden to the full-width collapsed strip.
  ///
  /// Default (Linux/macOS): the legacy two-step — resize to full, then re-acquire
  /// the platform reservation ([onShowStrip]). Windows overrides this to reuse
  /// the *init* sequence ([applyState] reserve→size, then [presentInitialFrame]),
  /// the one path proven to keep the strip inside its own strut. Converging show
  /// onto init removes the divergent resize-then-reserve path that stranded the
  /// re-registered AppBar window below the strut.
  Future<void> showStrip() async {
    await resizeToFullStrip();
    await completeShow();
  }

  /// Hides the strip to the mini pill.
  ///
  /// Default (Linux/macOS): the legacy two-step — release the platform
  /// reservation ([onHideStrip]), then shrink to the mini footprint. Windows
  /// overrides this to the single `applyState(StripState.hidden)` (release +
  /// size in one applier call), the mirror of [showStrip]. Geometry comes from
  /// the service's tracked font size, the same source `applyState` already uses.
  Future<void> hideStrip() async {
    await prepareToHide();
    await resizeToMiniStrip(_fontSizePx);
  }

  /// Resizes the OS window to the mini strip footprint (called at hide-animation end).
  Future<void> resizeToMiniStrip(double fontSizePx) async {
    final miniSize = Size(getMiniWidth(fontSizePx), getCollapsedHeight());
    final origin = _activeDisplay?.workAreaOrigin ?? Offset.zero;
    _log.fine('resizeToMiniStrip: target=$miniSize origin=$origin');
    await _strategy.applySize(miniSize, position: origin);
    await logGeometry('resizeToMiniStrip');
    probeGeometryLater('resizeToMiniStrip');
  }

  /// Resizes the OS window to full strip width (called at show-animation start).
  Future<void> resizeToFullStrip() async {
    final fullSize = Size(_screenWidth, getCollapsedHeight());
    final origin = _activeDisplay?.workAreaOrigin ?? Offset.zero;
    _log.fine('resizeToFullStrip: target=$fullSize origin=$origin');
    await _strategy.applySize(fullSize, position: origin);
    await logGeometry('resizeToFullStrip');
    probeGeometryLater('resizeToFullStrip');
  }

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
    final nextActive = _displayService.activeDisplay;
    final newWidth = nextActive?.size.width ?? 0;
    final activeChanged = _activeDisplay != nextActive;
    final previousActiveId = _activeDisplay?.id;
    final nextActiveId = nextActive?.id;

    _log.fine('WindowService._onDisplayChangedInner: dpr=$_dpr→$newDpr '
        'width=$_screenWidth→$newWidth activeChanged=$activeChanged '
        '(${previousActiveId ?? "—"}→${nextActiveId ?? "—"}) '
        'isExpanded=$_isExpanded');

    if (newWidth <= 0) {
      _log.fine(
          'WindowService._onDisplayChangedInner: invalid width ($newWidth), skipping');
      return;
    }

    if (newDpr == _dpr && newWidth == _screenWidth && !activeChanged) {
      _log.fine('WindowService._onDisplayChangedInner: no change, skipping');
      return;
    }

    _log.fine(
        'WindowService._onDisplayChangedInner: display CHANGED — applying resize');
    _dpr = newDpr;
    _screenWidth = newWidth;
    _activeDisplay = nextActive;

    if (activeChanged && nextActive != null) {
      _log.fine(
          'WindowService._onDisplayChangedInner: moveToDisplay ${nextActive.id} @ ${nextActive.workAreaOrigin}');
      await _strategy.moveToDisplay(nextActive);
    }

    await onDisplayChangedExtra();

    _log.fine(
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
