import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const double _kStripHeightLogical = 30.0;
const double _kExpandedHeightLogical = 200.0;

// Window configuration and lifecycle service.
//
// TLDR:
/// Overview: Sets up the frameless, always-on-top strip at the screen top.
/// Problem: Need to ensure the window spans the primary display and stays on top across platforms.
/// Solution: Uses window_manager and screen_retriever with DPR-aware logical sizing.
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

  static double _lastWidth = 1920.0;

  /// Call once, before [runApp], to set up the window.
  Future<void> initialize() async {
    await _wm.ensureInitialized();

    final display = await _sr.getPrimaryDisplay();
    final dpr = display.scaleFactor?.toDouble() ?? 1.0;

    // window_manager on Linux (GTK) takes logical pixels; GTK applies the
    // system scale factor itself. Use logical units directly.
    _lastWidth = (display.visibleSize?.width ?? 1920.0) / dpr;
    final size = Size(_lastWidth, _kStripHeightLogical);

    await _wm.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: size,
        maximumSize: size,
        backgroundColor: const Color(0x00000000),
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
        windowButtonVisibility: false,
      ),
      () async {
        await _wm.setResizable(false);
        await _wm.setMinimumSize(size);
        await _wm.setMaximumSize(size);
        await _wm.show();
        await _wm.setSize(size);
        await _wm.setPosition(Offset.zero);
        await _wm.setAlwaysOnTop(true);
      },
    );
  }

  /// Expands the window height to show event details.
  Future<void> expand() async {
    final size = Size(_lastWidth, _kExpandedHeightLogical);
    await _wm.setMinimumSize(size);
    await _wm.setMaximumSize(size);
    await _wm.setSize(size);
  }

  /// Collapses the window height back to the thin strip.
  Future<void> collapse() async {
    final size = Size(_lastWidth, _kStripHeightLogical);
    await _wm.setMinimumSize(size);
    await _wm.setMaximumSize(size);
    await _wm.setSize(size);
  }
}
