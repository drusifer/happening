import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/window_interaction_strategy.dart';
import 'package:happening/core/window/resize_strategy/window_resize_strategy.dart';
import 'package:happening/core/window/strip_state.dart';
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

  /// Converts a display's OS-reported width to the LOGICAL pixels that
  /// `window_manager` (and thus [WindowResizeStrategy.applySize]) expects.
  /// Base (macOS/Linux): identity — screen_retriever already reports logical pts.
  /// Windows overrides to divide by DPR because screen_retriever reports physical
  /// pixels there (scale-invariant, so a 3840px monitor still reports 3840 at 150%).
  @protected
  double toLogicalWidth(double reportedWidth, double dpr) => reportedWidth;

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
    _screenWidth = toLogicalWidth(nextActive.size.width, newDpr);
    _activeDisplay = nextActive;

    await _strategy.moveToDisplay(nextActive);
    await reRegisterReservation();
    await _reapplyCurrentState();
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
    _screenWidth = toLogicalWidth(width, _dpr);
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
    await _reapplyCurrentState();
    _log.fine('WindowService.updateHeights: reapply complete');
  }

  /// Returns collapsed height in logical pixels (for window_manager APIs).
  double getCollapsedHeight() => _fontSizePx * 2.5 + 17.5;

  /// Returns expanded height in logical pixels (for window_manager APIs).
  double getExpandedHeight() => _fontSizePx * 10.0 + 170.0;

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

  // ── Public hide/show API ──────────────────────────────────────────────────

  /// Returns the mini strip width in logical pixels for the given font size.
  double getMiniWidth(double fontSizePx) =>
      fontSizePx * 9.0 + 12.0 + 8.0 + 24.0 + 16.0 + 10.0;

  /// Hides the strip to the mini pill via the single applier.
  /// Windows overrides to also call [presentInitialFrame] on show.
  Future<void> hideStrip() => applyState(StripState.hidden);

  /// Restores the strip from hidden to the full-width collapsed strip.
  /// Windows overrides to also call [presentInitialFrame].
  Future<void> showStrip() => applyState(StripState.collapsedShown);

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
    final newWidth = toLogicalWidth(nextActive?.size.width ?? 0, newDpr);
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
    await _reapplyCurrentState();
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

  /// Re-applies the current logical state's geometry through the single applier
  /// (reserve → size at the reserved origin). Used by the paths that change the
  /// computed geometry without changing the logical state — font-size change,
  /// display change, reassert. Mirror of `StripController.reapply()`; replaces
  /// the old `_doExpand`/`_doCollapse` (which resized in place without
  /// re-pinning to the reserved origin).
  Future<void> _reapplyCurrentState() async {
    final state =
        _isExpanded ? StripState.expandedShown : StripState.collapsedShown;
    await applyState(state);
    await afterReapplyState(state);
  }

  /// Hook invoked right after [_reapplyCurrentState]'s [applyState], for
  /// platforms that must re-present/re-pin so an asynchronous OS relocation
  /// cannot strand the window after the geometry settles. On Windows a DPI
  /// change triggers a late (~150ms) Win32 re-evaluation that drops the AppBar
  /// window to its band bottom (below its own strut); init/show survive it via
  /// [presentInitialFrame], so the re-apply paths must do the same. Base no-op
  /// (macOS/Linux have no such relocation).
  @protected
  Future<void> afterReapplyState(StripState state) async {
    return;
  }
}
