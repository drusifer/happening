import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'package:happening/core/util/logger.dart';

/// Window management service for resizing the app between strip and hover states.
///
/// TLDR:
/// Overview: Controls physical OS window dimensions via [window_manager].
/// Problem: High-frequency resizing causes OS flickering and race conditions.
/// Solution: Direct calls without state guards. The UI handles gating.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

class WindowService {
  WindowService({
    required WindowManager windowManager,
    required ScreenRetriever screenRetriever,
  })  : _wm = windowManager,
        _sr = screenRetriever;

  final WindowManager _wm;
  final ScreenRetriever _sr;

  double _lastWidth = 1920.0;
  double _lastHeight = 0.0;
  double _expandedHeight = 0.0;

  // Track the last intended state to allow UI gating.
  bool _lastWantsExpanded = false;

  /// Whether the window is currently intended to be in the expanded state.
  bool get isExpanded => _lastWantsExpanded;

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize({
    double height = 30.0,
    double expandedHeight = 250.0,
  }) async {
    await _wm.ensureInitialized();
    _lastHeight = height;
    _expandedHeight = expandedHeight;

    final display = await _sr.getPrimaryDisplay();
    _lastWidth = display.size.width;

    // Initial setup: No title bar, always on top, set height.
    await _wm.setAsFrameless();
    await _wm.setAlwaysOnTop(true);
    await _wm.setBackgroundColor(Colors.transparent);

    final size = Size(_lastWidth, height);
    await _wm.setMinimumSize(size);
    await _wm.setMaximumSize(size);
    await _wm.setSize(size);

    // Position at top of screen.
    await _wm.setPosition(Offset.zero);
    await _wm.show();
  }

  /// Expands the window to show the hover card area.
  Future<void> expand({double? height}) async {
    if (height != null) _expandedHeight = height;
    unawaited(AppLogger.debug('WindowService: expanding to $_expandedHeight'));
    _lastWantsExpanded = true;
    await _doExpand();
  }

  /// Collapses the window back to the strip height.
  Future<void> collapse({double? height}) async {
    if (height != null) _lastHeight = height;
    unawaited(AppLogger.debug('WindowService: collapsing to $_lastHeight'));
    _lastWantsExpanded = false;
    await _doCollapse();
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
