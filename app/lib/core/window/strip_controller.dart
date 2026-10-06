import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:happening/core/window/async_gate.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:logging/logging.dart';

/// Owns the strip's logical [StripState] and exposes the transition API.
///
/// TLDR:
/// Overview: The controller in a conventional Flutter MVC split — owns model
///           state (which of the 3 [StripState]s) and the transition surface
///           (`collapse/expand/hide/show`). The widget is the view; geometry is
///           applied by [WindowService.applyState] (the OS executor).
/// Problem: Hide/expand/show/init each sequenced geometry directly from the
///           widget and service, drifting into N paths to the same end state.
/// Solution: A single [ChangeNotifier] holding truth, serialising every
///           transition through an [AsyncGate] (idempotent, last-wins) and
///           delegating the OS work to [WindowService.applyState].
/// Breaking Changes: No (not wired yet — introduced ahead of callers).
class StripController extends ChangeNotifier {
  StripController({
    required WindowService windowService,
    this.hoverCollapseDelay = const Duration(milliseconds: 250),
  }) : _windowService = windowService {
    _windowService.reapplyHandler = reapply;
    _gate = AsyncGate<StripState>(_apply)..start();
  }

  static final _log = Logger('StripController');

  final WindowService _windowService;
  late final AsyncGate<StripState> _gate;

  StripState _state = StripState.collapsedShown;

  /// Grace period before a hover-driven collapse is applied. A pointer that
  /// wobbles across the strip edge would otherwise resize the window
  /// expanded → collapsed → expanded within tens of ms. That A→B→A resize
  /// pattern trips a Flutter macOS Impeller bug (back-buffer cache returns a
  /// wrong-size surface → null deref in Canvas::SetupRenderPass,
  /// flutter/flutter#192522) and visibly flickers on every platform.
  final Duration hoverCollapseDelay;

  /// Last state handed to the gate (may not have settled yet).
  StripState _requested = StripState.collapsedShown;
  Timer? _hoverCollapseTimer;
  Completer<void>? _hoverCollapseDone;

  /// The current logical state. Updated only after [WindowService.applyState]
  /// confirms, then listeners are notified.
  StripState get state => _state;

  /// Transition to the full-width collapsed strip. Ignored while hidden: only
  /// [show] leaves the hidden state, so a stray collapse (app deactivation,
  /// hover) can never inflate the mini pill to a full-width, click-eating window.
  Future<void> collapse() => _requested == StripState.hidden
      ? Future.value()
      : _request(StripState.collapsedShown);

  /// Hover-driven collapse: when leaving the expanded state, waits
  /// [hoverCollapseDelay] and is cancelled by any other transition in the
  /// meantime (e.g. the pointer re-entering a card → [expand]). From any other
  /// state it behaves exactly like [collapse].
  Future<void> collapseFromHover() {
    if (_requested != StripState.expandedShown) return collapse();
    final pending = _hoverCollapseDone;
    if (pending != null) return pending.future;
    final done = Completer<void>();
    _hoverCollapseDone = done;
    _hoverCollapseTimer = Timer(hoverCollapseDelay, () {
      _hoverCollapseTimer = null;
      _hoverCollapseDone = null;
      unawaited(_request(StripState.collapsedShown).then(
        (_) => done.complete(),
        onError: done.completeError,
      ));
    });
    return done.future;
  }

  /// Transition to the expanded (hover card / settings) strip. Ignored while
  /// hidden, like [collapse].
  Future<void> expand() => _requested == StripState.hidden
      ? Future.value()
      : _request(StripState.expandedShown);

  /// Transition to the hidden mini pill. Geometry collapses first by virtue of
  /// the mini size; there is no expanded-hidden state.
  Future<void> hide() => _request(StripState.hidden);

  /// Restore from hidden to the full-width collapsed strip.
  Future<void> show() => _request(StripState.collapsedShown, unhide: true);

  /// Re-apply the current state's geometry without changing it. Used for
  /// display/font-size changes where the logical state is unchanged but the
  /// computed geometry (width, origin, height) differs.
  Future<void> reapply() => _gate.send(_state, force: true);

  /// The single entry for every transition. Collapsed/expanded only exist while
  /// the strip is shown, so while hidden every request except an explicit
  /// [show] (`unhide`) is dropped — nothing else can inflate the mini pill to a
  /// full-width, click-eating window.
  Future<void> _request(StripState s, {bool unhide = false}) {
    if (_requested == StripState.hidden && s != StripState.hidden && !unhide) {
      _log.fine('ignoring $s while hidden');
      return Future.value();
    }
    _cancelHoverCollapse();
    _requested = s;
    return _gate.send(s);
  }

  /// Drops a pending hover collapse; its caller's future completes since the
  /// request was superseded (mirrors [AsyncGate]'s last-wins contract).
  void _cancelHoverCollapse() {
    _hoverCollapseTimer?.cancel();
    _hoverCollapseTimer = null;
    final done = _hoverCollapseDone;
    _hoverCollapseDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _apply(StripState target) async {
    _log.fine('apply $target (from $_state)');
    final wasHidden = _state == StripState.hidden;
    if (target == _state) {
      // Forced same-state apply (display/font change): re-pin the CURRENT state,
      // so a hidden pill is never re-inflated to full width.
      await _windowService.reapplyState(target);
    } else if (target == StripState.hidden) {
      // Release the strut + shrink to the mini pill (the one ABM_REMOVE).
      await _windowService.hideStrip();
    } else if (wasHidden) {
      // hidden → shown: re-register + reserve + present (the validated show
      // path that keeps the strip in its strut).
      await _windowService.showStrip();
    } else {
      // shown → shown (expand/collapse, display/font reapply): re-pin via the
      // applier; no teardown, no present needed (a frame is already composited).
      await _windowService.applyState(target);
    }
    if (_state != target) {
      _state = target;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelHoverCollapse();
    if (_windowService.reapplyHandler == reapply) {
      _windowService.reapplyHandler = null;
    }
    _gate.dispose();
    super.dispose();
  }
}
