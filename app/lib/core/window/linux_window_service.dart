import 'dart:async';

import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/interaction_strategy/reserved_window_interaction_strategy.dart';
import 'package:happening/core/window/linux_dock_window_manager.dart';
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
              ReservedWindowInteractionStrategy(wm: windowManager),
        );

  final LinuxDockWindowManager _linuxDock;

  // ── Overrides ─────────────────────────────────────────────────────────────

  @override
  Future<void> afterReadyToShow(WindowMode mode) async {
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

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _reserveLinuxStrut() async {
    final height = (getCollapsedHeight() * dpr).round();
    _log.fine(
        'LinuxWindowService._reserveLinuxStrut: height=$height (dpr=$dpr)');
    await _linuxDock.dock(height: height);
  }
}
