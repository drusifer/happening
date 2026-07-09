import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/reserved_window_interaction_strategy.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/core/window/windows_app_bar.dart';
import 'package:logging/logging.dart';

/// Windows-specific WindowService with AppBar (work-area reservation) support.
///
/// Init model (docs/WINDOW_STATE_REFACTOR_PLAN.md): geometry + reservation are
/// applied ONCE post-show via [applyState] (from [afterWindowShown], inside the
/// readyToShow callback's await chain — so it runs after performShow regardless
/// of whether waitUntilReadyToShow awaits its outer callback). Because
/// initialize() runs before runApp(), the first frame does not exist yet, so
/// [presentInitialFrame] is deferred to the first frame and composites it with
/// a 1px size-settle. No onWindowFocus handler, no safety-net Timer, no
/// _handleFirstShow re-resize dance.
///
/// All Win32 FFI (AppBar reservation, RedrawWindow) lives behind the
/// [WindowsAppBar] seam so this orchestration is unit-testable with a fake.
class WindowsWindowService extends WindowService {
  static final _log = Logger('WindowsWindowService');

  WindowsWindowService({
    required super.windowManager,
    required super.screenRetriever,
    required super.displayService,
    bool enableWindowsAppBar = true,
    WindowsAppBar? appBar,
  })  : _enableWindowsAppBar = enableWindowsAppBar,
        _appBar = appBar ?? Win32AppBar(),
        super(
          interactionStrategy:
              ReservedWindowInteractionStrategy(wm: windowManager),
        );

  final bool _enableWindowsAppBar;
  final WindowsAppBar _appBar;

  @override
  double toLogicalWidth(double reportedWidth, double dpr) =>
      dpr > 0 ? reportedWidth / dpr : reportedWidth;

  int get _bandWidthPx => (screenWidth * dpr).round();

  // CEIL, not round: the window is sized in logical px and window_manager rounds
  // it to physical independently. If the band rounded DOWN while the window
  // rounded UP (possible at fractional DPI), the window would be 1px taller than
  // its band and Windows would relocate it below its own strut (see L-006).
  // Ceil guarantees band >= window physical height for any rounding.
  int get _bandHeightPx => (getCollapsedHeight() * dpr).ceil();

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  void onDispose() => _appBar.dispose();

  // On Windows, size/position set before ShowWindow are ignored. This hook runs
  // INSIDE the readyToShow callback's await chain, right after performShow, so
  // it is guaranteed post-show. Apply the final geometry + reservation once,
  // then force a single present so the first frame composites without a
  // mouse-over.
  @override
  Future<void> afterWindowShown(WindowMode mode) async {
    _log.fine('afterWindowShown: applyState(collapsedShown); '
        'present deferred to first frame');
    await applyState(StripState.collapsedShown);
    // initialize() runs BEFORE runApp(), so Flutter has not produced its first
    // frame yet — the log shows the first paint lands ~150ms after this. A
    // present now composites nothing (RedrawWindow cannot conjure a frame that
    // does not exist). Defer it to just after the first frame — the same
    // post-first-frame pattern macOS uses for its Metal layer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(presentInitialFrame());
    });
  }

  /// Reserves the work-area band and returns the origin the window should be
  /// placed at — `applyState` applies geometry AFTER this, so positioning
  /// happens after ABM_SETPOS (which can move the AppBar window). shown+reserved
  /// registers (if needed) + reserves the top band; hidden or overlay releases
  /// it and returns the display's top edge directly (NOT null): our own
  /// reservation shrinks `workAreaOrigin.dy` while active (Windows excludes a
  /// registered AppBar's band from `rcWork`), so once released that value no
  /// longer means "top of display" — it means "below wherever we just were".
  /// `applyState`'s work-area fallback is for platforms that never reserve
  /// (macOS/base); Windows always knows its own top edge, reserved or not, so
  /// it should never fall through to it. `workAreaOrigin.dx` is unaffected
  /// (a full-width top strut doesn't shrink the work area horizontally) and
  /// stays the source for multi-monitor X placement.
  @override
  Future<Offset?> applyReservation(StripState state) async {
    if (!_enableWindowsAppBar) return null;
    final double xOffset = activeDisplay?.workAreaOrigin.dx ?? 0;
    if (state == StripState.hidden || windowMode != WindowMode.reserved) {
      _appBar.dispose();
      return Offset(xOffset, 0);
    }
    if (!_appBar.isRegistered) _appBar.register();
    final rcTop =
        _appBar.reserveTopBand(widthPx: _bandWidthPx, heightPx: _bandHeightPx);
    final origin = Offset(xOffset, rcTop / dpr);
    _log.fine(
        'applyReservation: $state reserved → origin=$origin (rcTop=$rcTop)');
    return origin;
  }

  @override
  Future<void> presentInitialFrame() async {
    // RDW_INVALIDATE alone does NOT make the Flutter (ANGLE/D3D) engine present
    // a frame — only a metrics change does (which is exactly why a mouse-over
    // or manual resize "fixes" the sliver). Force one with a 1px size settle.
    //
    // CRITICAL: nudge DOWN, not up. Growing past the reserved band height makes
    // Windows relocate the AppBar window into the work area (below its own
    // strut) — GEO trace 2026-06-19 19:55 showed +1px stranded it at y=73.
    // Shrinking stays inside the band, so the window keeps its position.
    final h = getCollapsedHeight();
    final origin = Offset(activeDisplay?.workAreaOrigin.dx ?? 0, 0);
    _log.fine(
        'presentInitialFrame: 1px shrink-settle ${h - 1}→$h, pin=$origin');
    await strategy.applySize(Size(screenWidth, h - 1), position: origin);
    await strategy.applySize(Size(screenWidth, h), position: origin);
    _appBar.presentFrame();
    // Belt-and-suspenders: pin the strip back to the reserved top in case the
    // resize still nudged it.
    await wm.setPosition(origin);
    await logGeometry('presentInitialFrame:after');
    probeGeometryLater('presentInitialFrame');
  }

  // Show mirrors init (afterWindowShown): reserve→size via applyState, then
  // present. Needed because a re-registered AppBar window can drift below its
  // own strut without the metrics-settle in presentInitialFrame.
  @override
  Future<void> showStrip() async {
    _log.fine('showStrip: applyState(collapsedShown) + presentInitialFrame');
    await applyState(StripState.collapsedShown);
    await presentInitialFrame();
  }

  @override
  Future<void> onWindowModeChanged(WindowMode mode) async {
    _log.fine(
        'onWindowModeChanged: mode=$mode registered=${_appBar.isRegistered}');
    if (!_enableWindowsAppBar) return;
    if (mode == WindowMode.reserved) {
      if (!_appBar.isRegistered) {
        _appBar.register();
        _appBar.reserveTopBand(widthPx: _bandWidthPx, heightPx: _bandHeightPx);
      } else {
        await reassertAppBar();
      }
    } else {
      _appBar.dispose();
    }
  }

  // NOTE: no onDisplayChangedExtra override. A display/DPI change is just
  // another transition, so it converges onto the single applier like every
  // other one: WindowService._onDisplayChangedInner updates dpr/width/display,
  // then calls _reapplyCurrentState() → applyState, whose applyReservation
  // re-reserves the band (at the now-correct logical-derived _bandWidthPx) and
  // returns the origin to pin to. The old override pre-reserved + setPosition
  // here as well, double-reserving the band — at a DPI change that second
  // ABM_SETPOS stranded the strip below its own strut (build-chage-dpr.out
  // 2026-06-22 line 315: pos drifted to (0,60)).

  // After a display/DPI or font re-apply, mirror what init/show do: present.
  // applyState alone leaves the AppBar window exposed to a late (~150ms) Win32
  // re-evaluation that relocates it to the band bottom, below its own strut
  // (build-chage-dpr-fix1.out 2026-06-22 line 234: pos drifted (0,0)→(0,60)).
  // presentInitialFrame's metrics-settle re-confirms the geometry and re-pins
  // the origin — the show path runs it and stays put through +1200ms. Only the
  // collapsed shown state qualifies: presentInitialFrame settles at the
  // collapsed height (it would wrongly shrink an expanded card), and a hidden
  // mini pill reserves nothing to strand.
  @override
  Future<void> afterReapplyState(StripState state) async {
    if (state == StripState.collapsedShown &&
        windowMode == WindowMode.reserved) {
      await presentInitialFrame();
    }
  }

  /// Re-broadcasts the work-area reservation (e.g. when the strip overlaps
  /// other windows) through the SAME flow as everything else: drop the AppBar
  /// (ABM_REMOVE forces Windows to re-announce the work area), then re-apply the
  /// collapsed state via [applyState] — which re-registers (ABM_NEW), reserves,
  /// and positions in the correct reserve-then-position order. No bespoke
  /// performResize/setPosition sequence that can drift from init/hide/show.
  @override
  Future<void> reassertAppBar() async {
    if (windowMode != WindowMode.reserved || !_appBar.isRegistered) {
      await super.reassertAppBar();
      return;
    }
    _log.fine('reassertAppBar: dispose + applyState(collapsedShown)');
    _appBar.dispose(); // ABM_REMOVE → re-broadcast work area
    await applyState(StripState.collapsedShown);
  }
}
