import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const double _kStripHeightLogical = 30.0;

/// Configures the app window as an always-on-top frameless strip.
class WindowService {
  /// Call once, before [runApp], to set up the window.
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    final display = await screenRetriever.getPrimaryDisplay();
    final dpr = display.scaleFactor?.toDouble() ?? 1.0;

    // Calculate logical pixels: physical_pixels / dpr
    // We want the strip to be exactly 30 physical pixels tall.
    final logicalWidth = (display.visibleSize?.width ?? 1920.0) / dpr;
    final logicalHeight = 30.0 / dpr;
    
    final size = Size(logicalWidth, logicalHeight);

    await windowManager.waitUntilReadyToShow(
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
        await windowManager.setResizable(false);
        await windowManager.setMinimumSize(size);
        await windowManager.setMaximumSize(size);
        await windowManager.show();
        await windowManager.setSize(size);
        await windowManager.setPosition(Offset.zero);
        await windowManager.setAlwaysOnTop(true);
      },
    );
  }
}
