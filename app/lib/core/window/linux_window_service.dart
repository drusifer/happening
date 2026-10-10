import 'dart:async';

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/linux_window_interaction_strategy.dart';
import 'package:happening/core/window/linux_dock_window_manager.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:logging/logging.dart';

/// Linux-specific WindowService with GTK strut (work-area reservation) support.
class LinuxWindowService extends WindowService {
  static final _log = Logger('LinuxWindowService');

  LinuxWindowService({
    required super.windowManager,
    required super.screenRetriever,
    required super.displayService,
    LinuxDockWindowManager? linuxDockWindowManager,
  })  : _linuxDock = linuxDockWindowManager ?? LinuxDockWindowManager(),
        super(
          interactionStrategy:
              LinuxWindowInteractionStrategy(wm: windowManager),
        );

  final LinuxDockWindowManager _linuxDock;

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  Future<void> afterWindowShown(WindowMode mode) async {
    if (mode == WindowMode.reserved) {
      await _reserveLinuxStrut();
    }
  }

  @override
  void onDispose() => unawaited(_linuxDock.undock());

  @override
  Future<void> onWindowModeChanged(WindowMode mode) async {
    if (mode == WindowMode.reserved) {
      await _reserveLinuxStrut();
    } else {
      await _linuxDock.undock();
    }
  }

  @override
  Future<void> onDisplayChangedExtra() async {
    if (windowMode == WindowMode.reserved) {
      await _reserveLinuxStrut();
    }
  }

  @override
  Future<void> reRegisterReservation() async {
    if (windowMode != WindowMode.reserved) return;
    await _linuxDock.undock();
    await _reserveLinuxStrut();
  }

  @override
  Future<Offset?> applyReservation(StripState state) async {
    if (windowMode != WindowMode.reserved) return null;
    if (state.isShown) {
      await _reserveLinuxStrut();
    } else {
      await _linuxDock.undock();
    }
    // Always place the strip at the top we reserved from. The probe's work
    // area moves below the strip once our strut is active, so falling back to
    // it would walk the strip down the screen.
    return Offset(activeDisplay?.workAreaOrigin.dx ?? 0, _baseTop());
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  /// Strut last sent to the WM (physical px from the screen top) and the
  /// work-area top it was measured from. Kept after undock: the probe can still
  /// report the reserved work area until it refreshes.
  int? _lastStrutPx;
  double _lastStrutBaseTop = 0;

  /// Top of the active display's work area *excluding our own strut* — where
  /// the strip belongs. Non-zero when a desktop panel (e.g. GNOME's top bar)
  /// sits above the strip.
  double _baseTop() {
    final top = activeDisplay?.workAreaOrigin.dy ?? 0;
    final lastStrutPx = _lastStrutPx;
    if (lastStrutPx != null && (top * dpr).round() == lastStrutPx) {
      return _lastStrutBaseTop;
    }
    return top;
  }

  Future<void> _reserveLinuxStrut() async {
    // Struts are measured from the screen edge, so reserve down to the strip's
    // bottom edge, not just its height — otherwise a panel above the strip
    // leaves maximized windows overlapping it.
    final baseTop = _baseTop();
    final height = ((baseTop + getCollapsedHeight()) * dpr).round();
    _log.fine('LinuxWindowService._reserveLinuxStrut: height=$height '
        '(baseTop=$baseTop dpr=$dpr)');
    await _linuxDock.dock(height: height);
    _lastStrutPx = height;
    _lastStrutBaseTop = baseTop;
  }
}
